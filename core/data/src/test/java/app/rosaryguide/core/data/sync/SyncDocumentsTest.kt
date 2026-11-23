package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.session.CompletedPrayerSession
import app.rosaryguide.core.data.session.IntentionCategory
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.PrayerSession
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerTextSize
import app.rosaryguide.core.model.RosaryConfig
import java.time.ZoneId
import java.util.Date
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SyncDocumentsTest {
    private val zone = ZoneId.of("Australia/Perth")
    private val now = 1_795_000_000_000L // 2026-11-17

    @Test
    fun preferencesDocumentMatchesRules() {
        val data = SyncedPreferences(rosaryConfig = RosaryConfig(translation = BibleTranslation.WebCatholic))
            .stamped(now).firestoreData()
        assertTrue(data.keys.containsAll(RulesShape.preferencesFields))
        assertTrue((RulesShape.preferencesFields + RulesShape.preferencesOptional).containsAll(data.keys))
        @Suppress("UNCHECKED_CAST")
        val config = data["rosaryConfig"] as Map<String, Any>
        assertTrue(RulesShape.rosaryConfigKeys.containsAll(config.keys))
        assertEquals("rsv2ce", config["translation"])
        assertEquals("blue", data["appIcon"])
        assertEquals("system", data["appearance"])
        assertTrue(data["updatedAt"] is Date)
        assertTrue(data["dailyReminderMinutes"] is Int)
    }

    @Test
    fun preferencesSchemaStepsDropNewerKeys() {
        val value = SyncedPreferences(rosaryConfig = RosaryConfig()).stamped(now)
        assertFalse("fieldUpdatedAt" in value.firestoreData(SyncedPreferences.Schema.WithoutFieldTimes))
        val oldest = value.firestoreData(SyncedPreferences.Schema.WithoutRosaryConfig)
        assertEquals(RulesShape.preferencesFields, oldest.keys)
    }

    @Test
    fun preferencesRoundTripThroughFirestoreShape() {
        val value = SyncedPreferences(
            appearance = AppearancePreference.Dark,
            textSize = PrayerTextSize.Large,
            appIcon = AppIconOption.White,
            dailyReminderMinutes = 7 * 60,
            rosaryConfig = RosaryConfig(memorare = true, translation = BibleTranslation.Vulgate),
        ).stamped(now)
        assertEquals(value, SyncedPreferences.fromFirestore(value.firestoreData()))
    }

    @Test
    fun preferencesFromOlderDocumentDefaultsFeastTime() {
        val data = SyncedPreferences().stamped(now).firestoreData(SyncedPreferences.Schema.WithoutRosaryConfig) - "feastAlertMinutes"
        val parsed = SyncedPreferences.fromFirestore(data)!!
        assertEquals(9 * 60, parsed.feastAlertMinutes)
        assertNull(parsed.rosaryConfig)
        assertNull(SyncedPreferences.fromFirestore(data - "appearance"))
    }

    @Test
    fun preferencesMergeIsPerField() {
        val base = SyncedPreferences().stamped(100)
        val local = base.copy(
            textSize = PrayerTextSize.Large,
            fieldUpdatedAt = base.fieldUpdatedAt + ("textSize" to 300L),
            updatedAt = 300,
        )
        val remote = base.copy(
            dailyReminderMinutes = 6 * 60,
            fieldUpdatedAt = base.fieldUpdatedAt + ("dailyReminderMinutes" to 400L),
            updatedAt = 400,
        )
        val merged = SyncedPreferences.merge(local, remote, now)
        assertEquals(PrayerTextSize.Large, merged.textSize)
        assertEquals(6 * 60, merged.dailyReminderMinutes)
        assertEquals(400L, merged.updatedAt)
    }

    @Test
    fun preferencesTiesGoToAccountAndFutureClocksAreCapped() {
        val local = SyncedPreferences(appearance = AppearancePreference.Light).stamped(now + 10_000_000)
        val remote = SyncedPreferences(appearance = AppearancePreference.Dark).stamped(now)
        assertEquals(AppearancePreference.Dark, SyncedPreferences.merge(local, remote, now).appearance)
    }

    @Test
    fun preferencesKeepDeviceRosaryConfigWhenAccountHasNone() {
        val local = SyncedPreferences(rosaryConfig = RosaryConfig(memorare = true)).stamped(100)
        val remote = SyncedPreferences(rosaryConfig = null).stamped(200)
        assertEquals(true, SyncedPreferences.merge(local, remote, now).rosaryConfig?.memorare)
    }

    private fun session(start: Long, ids: List<String> = emptyList()) = PrayerSession.create(
        mysterySet = MysterySetKind.Glorious,
        stepIndex = 12,
        startedAtEpochMs = start,
        updatedAtEpochMs = start + 60_000,
        intentionIds = ids,
        intentionTitles = ids.map { "t-$it" },
    )

    @Test
    fun progressDocumentMatchesRulesAndUppercasesIds() {
        val lower = "0f8fad5b-d9cb-469f-a165-70867728950e"
        val record = CompletedPrayerSession(
            id = lower,
            mysterySet = MysterySetKind.Joyful,
            startedAtEpochMs = now - 3_600_000,
            completedAtEpochMs = now - 1_800_000,
            duration = 1200.0,
            intentionIds = listOf(lower, "pope-2026-11"),
        )
        val progress = SyncedProgress(
            completedDays = setOf("2026-11-16", "bad-key"),
            session = session(now - 120_000, listOf(lower, "pope-2026-11")),
            sessionChangedAt = now,
            historyResetAt = now - 86_400_000L * 30,
            rosaries = listOf(record),
        )
        val data = progress.firestoreData(SyncedProgress.Schema.Full, now, zone)
        assertTrue(data.keys.containsAll(RulesShape.progressRequired))
        assertTrue(RulesShape.progressAllowed.containsAll(data.keys))
        assertEquals(listOf("2026-11-16"), data["completedDays"])
        @Suppress("UNCHECKED_CAST")
        val s = data["session"] as Map<String, Any>
        assertTrue(s.keys.containsAll(RulesShape.sessionRequired))
        assertTrue(RulesShape.sessionAllowed.containsAll(s.keys))
        // Non-UUID ids (papal intentions) are not allowed by the rules; UUIDs go upper case like iOS.
        assertEquals(listOf(lower.uppercase()), s["intentionIds"])
        assertEquals(lower.uppercase(), s["intentionId"])
        @Suppress("UNCHECKED_CAST")
        val rosaries = data["rosaries"] as Map<String, Map<String, Any>>
        assertEquals(setOf(lower.uppercase()), rosaries.keys)
        assertEquals(listOf(lower.uppercase()), rosaries.values.single()["intentionIds"])
    }

    @Test
    fun progressRoundTripsAndSchemaStepsDown() {
        val progress = SyncedProgress(
            completedDays = setOf("2026-11-15"),
            session = session(now - 60_000),
            sessionChangedAt = now - 60_000,
            rosaries = listOf(
                CompletedPrayerSession(id = SyncIds.newId(), mysterySet = MysterySetKind.Sorrowful, startedAtEpochMs = now - 90_000_000, completedAtEpochMs = now - 89_000_000, duration = 900.5),
            ),
        )
        val parsed = SyncedProgress.fromFirestore(progress.firestoreData(SyncedProgress.Schema.Full, now, zone), now, zone)
        assertNotNull(parsed)
        assertEquals(
            progress.comparable(SyncedProgress.Schema.Full, now, zone),
            parsed!!.comparable(SyncedProgress.Schema.Full, now, zone),
        )
        val old = progress.firestoreData(SyncedProgress.Schema.WithoutSessionExtras, now, zone)
        assertFalse("rosaries" in old)
        @Suppress("UNCHECKED_CAST")
        assertFalse("rosaryConfig" in (old["session"] as Map<String, Any>))
    }

    @Test
    fun progressMergeUnionsDaysAndHonoursNewestReset() {
        val reset = SyncedProgress.dayKey(now - 86_400_000L * 5, zone)
        val local = SyncedProgress(completedDays = setOf("2026-11-01", "2026-11-16"), sessionChangedAt = 10)
        val remote = SyncedProgress(
            completedDays = setOf("2026-11-15"),
            historyResetAt = now - 86_400_000L * 5,
            sessionChangedAt = 20,
        )
        val merged = SyncedProgress.merge(local, remote, now, zone)
        assertEquals(setOf("2026-11-15", "2026-11-16"), merged.completedDays)
        assertTrue(merged.completedDays.all { it > reset })
    }

    @Test
    fun progressMergeTakesNewerSessionAndDropsStaleOnes() {
        val local = SyncedProgress(session = session(now - 60_000), sessionChangedAt = 50)
        val remote = SyncedProgress(session = null, sessionChangedAt = 60)
        assertNull(SyncedProgress.merge(local, remote, now, zone).session)
        val stale = SyncedProgress(session = session(now - 86_400_000L * 3), sessionChangedAt = 70)
        assertNull(SyncedProgress.merge(local, stale, now, zone).session)
        val newerLocal = local.copy(sessionChangedAt = 80)
        assertNotNull(SyncedProgress.merge(newerLocal, remote, now, zone).session)
    }

    @Test
    fun intentionDocumentMatchesRules() {
        val item = OfferIntention(
            id = SyncIds.newId(),
            title = "  Peace  ",
            category = IntentionCategory.World,
            createdAtEpochMs = now - 1000,
            archivedAtEpochMs = now,
            suggestOn = listOf("Joyful", "nope"),
        )
        val data = IntentionDocuments.firestoreData(item, now)
        assertTrue(data.keys.containsAll(RulesShape.intentionRequired))
        assertTrue(RulesShape.intentionAllowed.containsAll(data.keys))
        assertEquals("Peace", data["title"])
        assertEquals("world", data["category"])
        assertEquals(listOf("joyful"), data["suggestOn"])
        val back = IntentionDocuments.fromFirestore(item.id.lowercase(), data)!!
        assertEquals(item.id, back.id)
        assertEquals(now, back.archivedAtEpochMs)
        assertNull(IntentionDocuments.fromFirestore("not-a-uuid", data))
    }

    private fun intention(id: String, edit: Long?) =
        OfferIntention(id = id, title = id, createdAtEpochMs = 1, updatedAtEpochMs = edit)

    @Test
    fun intentionMergeNewestEditWinsAndDeletesStick() {
        val a = SyncIds.newId(); val b = SyncIds.newId(); val c = SyncIds.newId(); val d = SyncIds.newId()
        val result = IntentionMerge.merge(
            local = listOf(intention(a, 500).copy(title = "mine"), intention(c, 10), intention(d, 10)),
            remote = listOf(intention(a, 400), intention(b, 100)),
            deleted = mapOf(b to 200L),
            previouslySynced = setOf(d),
            isFromCache = false,
            now = now,
        )
        assertEquals(listOf("mine", c), result.intentions.map { it.title })
        assertEquals(listOf(a, c), result.toUpload.map { it.id })
        assertEquals(listOf(b), result.toDelete)
        // Still waiting for the server to confirm the delete.
        assertEquals(mapOf(b to 200L), result.deleted)
    }

    @Test
    fun intentionMergeFromCacheNeverDropsOrUploads() {
        val a = SyncIds.newId()
        val result = IntentionMerge.merge(listOf(intention(a, 5)), emptyList(), emptyMap(), setOf(a), isFromCache = true, now = now)
        assertEquals(listOf(a), result.intentions.map { it.id })
        assertTrue(result.toUpload.isEmpty())
    }

    @Test
    fun stampingEditsOnlyTouchesChangedRows() {
        val a = intention("A", 1); val b = intention("B", 1)
        val stamped = IntentionMerge.stampingEdits(listOf(a, b.copy(title = "B2")), listOf(a, b), 99)
        assertEquals(1L, stamped[0].updatedAtEpochMs)
        assertEquals(99L, stamped[1].updatedAtEpochMs)
    }
}
