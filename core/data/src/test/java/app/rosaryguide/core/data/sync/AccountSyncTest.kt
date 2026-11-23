package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.auth.AuthResult
import app.rosaryguide.core.data.auth.AuthStore
import app.rosaryguide.core.data.auth.AuthUser
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerTextSize
import java.time.ZoneId
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AccountSyncTest {
    private val zone = ZoneId.of("Australia/Perth")
    private var now = 1_795_000_000_000L

    private class Harness(
        val settings: SettingsStore,
        val session: SessionStore,
        val store: InMemoryKeyValueStore,
        val remote: FakeAccountRemote,
        val sync: AccountSync,
    )

    private fun TestScope.harness(
        store: InMemoryKeyValueStore = InMemoryKeyValueStore(),
        remote: FakeAccountRemote = FakeAccountRemote(),
    ): Harness {
        val settings = SettingsStore()
        val session = SessionStore(zone = zone, clock = { now })
        val sync = AccountSync(settings, session, store, remote, backgroundScope, clock = { now }, zone = zone)
        return Harness(settings, session, store, remote, sync)
    }

    @Test
    fun firstSignInAdoptsGuestDataAndUploadsAllThreeDocuments() = runTest {
        val h = harness()
        h.settings.setAppearance(AppearancePreference.Dark)
        val intention = h.session.addIntention("For Mum")
        h.session.start(MysterySetKind.Joyful, nowEpochMs = now)
        h.session.complete(now + 60_000)

        h.sync.configureSync("uid-a")
        runCurrent()

        val prefs = h.remote.docs["users/uid-a/meta/preferences"]!!
        assertEquals("dark", prefs["appearance"])
        val progress = h.remote.docs["users/uid-a/meta/progress"]!!
        assertEquals(listOf(SyncedProgress.dayKey(now, zone)), progress["completedDays"])
        assertTrue(h.remote.docs.containsKey("users/uid-a/intentions/${intention.id}"))
        assertEquals(intention.id.uppercase(), intention.id)
    }

    @Test
    fun accountValuesMergeIntoTheDeviceWithoutBouncingBack() = runTest {
        val remote = FakeAccountRemote()
        val iphone = SyncedPreferences(
            appearance = AppearancePreference.Light,
            textSize = PrayerTextSize.Large,
            rosaryConfig = app.rosaryguide.core.model.RosaryConfig(),
        ).stamped(now - 1000)
        remote.docs["users/uid-a/meta/preferences"] = iphone.firestoreData()
        val h = harness(remote = remote)

        h.sync.configureSync("uid-a")
        runCurrent()

        assertEquals(AppearancePreference.Light, h.settings.current.appearance)
        // Android has no text-size control yet; the iPhone's choice is kept, not reset.
        assertEquals(PrayerTextSize.Large, h.sync.currentPreferences().textSize)
        assertTrue(h.remote.writes.none { it.first.endsWith("meta/preferences") })
    }

    @Test
    fun localChangeUploadsAfterThePauseWithItsFieldTime() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        val before = h.remote.writes.size
        now += 5_000
        h.settings.setDailyReminderMinutes(7 * 60)
        advanceTimeBy(1_000); runCurrent()
        assertEquals(before, h.remote.writes.size)
        advanceTimeBy(1_500); runCurrent()
        val doc = h.remote.docs["users/uid-a/meta/preferences"]!!
        assertEquals(7 * 60, doc["dailyReminderMinutes"])
        @Suppress("UNCHECKED_CAST")
        val times = doc["fieldUpdatedAt"] as Map<String, java.util.Date>
        assertEquals(now, times["dailyReminderMinutes"]!!.time)
    }

    @Test
    fun anotherDeviceChangeIsApplied() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        val other = h.sync.currentPreferences().copy(appearance = AppearancePreference.Dark)
            .let { it.copy(updatedAt = now + 10, fieldUpdatedAt = it.fieldUpdatedAt + ("appearance" to now + 10)) }
        now += 20
        h.remote.pushDoc("uid-a", MetaDocument.Preferences, other.firestoreData())
        assertEquals(AppearancePreference.Dark, h.settings.current.appearance)
    }

    @Test
    fun permissionDeniedStepsDownTheSchema() = runTest {
        val remote = FakeAccountRemote()
        remote.rejectWrites = { path, data ->
            if (path.endsWith("preferences") && ("fieldUpdatedAt" in data || "rosaryConfig" in data)) {
                RemoteError(RemoteError.Kind.PermissionDenied)
            } else {
                null
            }
        }
        val h = harness(remote = remote)
        h.sync.configureSync("uid-a")
        runCurrent()
        assertEquals(RulesShape.preferencesFields, remote.docs["users/uid-a/meta/preferences"]!!.keys)
        assertNull(h.sync.syncErrorMessage.value)
    }

    @Test
    fun intentionEditsAndDeletesReachTheAccount() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        val item = h.session.addIntention("Peace")
        runCurrent()
        val path = "users/uid-a/intentions/${item.id}"
        assertEquals("Peace", h.remote.docs[path]!!["title"])
        h.session.removeIntention(item.id)
        runCurrent()
        assertFalse(h.remote.docs.containsKey(path))
    }

    @Test
    fun intentionDeletedOnAnotherDeviceIsRemovedHere() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        val item = h.session.addIntention("Peace")
        runCurrent()
        h.remote.pushIntentions("uid-a") // server confirms it
        h.remote.docs.remove("users/uid-a/intentions/${item.id}")
        h.remote.pushIntentions("uid-a")
        assertTrue(h.session.intentions.value.isEmpty())
    }

    @Test
    fun signOutKeepsDataAndAnotherAccountStartsFromItsOwnCopy() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        h.session.addIntention("A's intention")
        now += 1_000
        h.settings.setAppearance(AppearancePreference.Dark)
        runCurrent()

        h.sync.configureSync(null)
        assertEquals(1, h.session.intentions.value.size)

        h.sync.configureSync("uid-b")
        runCurrent()
        assertTrue(h.session.intentions.value.isEmpty())
        assertEquals(AppearancePreference.System, h.settings.current.appearance)
        assertTrue(h.remote.docs.keys.none { it.startsWith("users/uid-b/intentions/") })

        h.sync.configureSync("uid-a")
        runCurrent()
        assertEquals(listOf("A's intention"), h.session.intentions.value.map { it.title })
        assertEquals(AppearancePreference.Dark, h.settings.current.appearance)
    }

    @Test
    fun accountDeletionRemovesCloudDataThenAuthUserThenLocalData() = runTest {
        val h = harness()
        val backend = FakeAuthBackend()
        val auth = AuthStore(backend, backgroundScope)
        auth.signInWithGoogle(); runCurrent()
        h.sync.configureSync(auth.userId)
        runCurrent()
        h.session.addIntention("Peace")
        h.session.start(MysterySetKind.Joyful, nowEpochMs = now)
        h.session.complete(now + 1_000)
        advanceTimeBy(5_000); runCurrent()
        assertTrue(h.remote.docs.keys.any { it.startsWith("users/uid-a/") })

        val outcome = AccountDeletion(auth, h.sync).run()

        assertEquals(AccountDeletion.Outcome.Deleted, outcome)
        assertTrue(h.remote.docs.keys.none { it.startsWith("users/uid-a/") })
        assertTrue("users/uid-a/meta/preferences" in h.remote.deletes)
        assertTrue("users/uid-a/meta/progress" in h.remote.deletes)
        assertNull(backend.currentUser)
        assertFalse(auth.isSignedIn)
        assertTrue(h.session.intentions.value.isEmpty())
        assertTrue(h.session.completedDayKeys.value.isEmpty())
        assertTrue(h.store.values.keys.none { it.endsWith("uid-a") })
        assertTrue(h.remote.cacheCleared > 0)
    }

    @Test
    fun failedCloudDeletionKeepsTheAccountAndRestoresIt() = runTest {
        val h = harness()
        val backend = FakeAuthBackend()
        val auth = AuthStore(backend, backgroundScope)
        auth.signInWithGoogle(); runCurrent()
        h.sync.configureSync(auth.userId)
        runCurrent()
        h.remote.failDeletes = true

        val outcome = AccountDeletion(auth, h.sync).run()
        runCurrent()

        assertEquals(AccountDeletion.Outcome.Failed(AccountDeletion.CLOUD_FAILED), outcome)
        assertTrue(auth.isSignedIn)
        assertTrue(h.remote.docs.containsKey("users/uid-a/meta/preferences"))
    }

    @Test
    fun failedAuthDeletionRestoresCloudCopyAndExplains() = runTest {
        val h = harness()
        val backend = FakeAuthBackend()
        val auth = AuthStore(backend, backgroundScope)
        auth.signInWithGoogle(); runCurrent()
        h.sync.configureSync(auth.userId)
        runCurrent()
        val item = h.session.addIntention("Keep me")
        runCurrent()
        backend.nextDelete = AuthResult.Failure("For your security, confirm your sign-in again, then try Delete account once more")

        val outcome = AccountDeletion(auth, h.sync).run()
        runCurrent()

        assertEquals(
            AccountDeletion.Outcome.Failed("For your security, confirm your sign-in again, then try Delete account once more"),
            outcome,
        )
        assertTrue(h.remote.docs.containsKey("users/uid-a/intentions/${item.id}"))
        assertTrue(h.remote.docs.containsKey("users/uid-a/meta/progress"))
        assertEquals(1, h.session.intentions.value.size)
    }

    @Test
    fun cancelledReauthenticationChangesNothing() = runTest {
        val h = harness()
        val backend = FakeAuthBackend()
        val auth = AuthStore(backend, backgroundScope)
        auth.signInWithGoogle(); runCurrent()
        h.sync.configureSync(auth.userId)
        runCurrent()
        backend.nextReauth = AuthResult.Cancelled
        assertEquals(AccountDeletion.Outcome.Cancelled, AccountDeletion(auth, h.sync).run())
        assertTrue(h.remote.deletes.isEmpty())
        assertTrue(auth.isSignedIn)
        assertNull(auth.state.value.errorMessage)
    }

    @Test
    fun clearAppHistoryStampsAResetOtherDevicesHonour() = runTest {
        val h = harness()
        h.sync.configureSync("uid-a")
        runCurrent()
        h.session.start(MysterySetKind.Joyful, nowEpochMs = now)
        h.session.complete(now + 1_000)
        advanceTimeBy(5_000); runCurrent()
        now += 10_000
        h.session.clearHistoryAndData()
        advanceTimeBy(5_000); runCurrent()
        val doc = h.remote.docs["users/uid-a/meta/progress"]!!
        assertEquals(emptyList<String>(), doc["completedDays"])
        assertTrue(doc["historyResetAt"] is java.util.Date)
    }

    @Test
    fun authStoreSignInCountsInteractiveAndFailureShowsMessage() = runTest {
        val backend = FakeAuthBackend()
        val auth = AuthStore(backend, backgroundScope)
        var result: Boolean? = null
        backend.nextSignIn = AuthResult.Cancelled
        auth.signInWithGoogle { result = it }; runCurrent()
        assertEquals(false, result)
        assertNull(auth.state.value.errorMessage)
        backend.nextSignIn = AuthResult.Failure("You appear to be offline, connect to the internet and try again")
        auth.signInWithGoogle { result = it }; runCurrent()
        assertEquals("You appear to be offline, connect to the internet and try again", auth.state.value.errorMessage)
        backend.nextSignIn = AuthResult.Success(AuthUser("uid-z", "google.com", " Zed "))
        auth.signInWithGoogle { result = it }; runCurrent()
        assertEquals(true, result)
        assertTrue(auth.isSignedIn)
        assertEquals("uid-z", auth.userId)
        assertEquals("Zed", auth.state.value.displayName)
        assertEquals(1, auth.interactiveSignIns)
        assertFalse(auth.state.value.isSigningInWithGoogle)
    }

    @Test
    fun authStoreGuestIsLocalAndRestoredSessionIsNotInteractive() = runTest {
        val backend = FakeAuthBackend().apply { currentUser = AuthUser("uid-r", "google.com", null) }
        val restored = AuthStore(backend, backgroundScope)
        assertTrue(restored.isSignedIn)
        assertEquals(0, restored.interactiveSignIns)
        restored.signOut(); runCurrent()
        assertFalse(restored.isSignedIn)
        assertEquals(1, backend.signOuts)

        val guest = AuthStore(FakeAuthBackend(), backgroundScope)
        guest.continueAsGuest()
        assertFalse(guest.isSignedIn)
        assertNull(guest.userId)
        assertEquals(1, guest.interactiveSignIns)
    }
}
