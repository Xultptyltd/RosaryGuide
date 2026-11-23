package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.config.RosaryJson
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.prefs.UserSettings
import app.rosaryguide.core.data.session.LocalJourneyArchive
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.data.session.SessionSyncListener
import app.rosaryguide.core.model.AppIconOption
import java.time.ZoneId
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer

/**
 * Keeps preferences, prayer progress and intentions in step with the signed-in account.
 * Port of iOS `AccountSyncStore` + the sync half of `OfferStore`.
 *
 * Local first: the app always reads and writes [SettingsStore] and [SessionStore], which work
 * offline and signed out. Each account has its own copy on this device, so switching accounts
 * never mixes data. Signed in, changes upload after a short pause and changes from other
 * devices merge in (preferences: last write wins per field; prayed days: union; intentions:
 * newest edit wins per intention).
 */
class AccountSync(
    private val settings: SettingsStore,
    private val session: SessionStore,
    private val store: KeyValueStore,
    private val remote: AccountRemote,
    private val scope: CoroutineScope,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val zone: ZoneId = ZoneId.systemDefault(),
    /** Synced settings were applied (reschedule reminders, swap the launcher icon). */
    private val onPreferencesApplied: (previous: UserSettings, current: UserSettings) -> Unit = { _, _ -> },
) : SessionSyncListener {
    private object Keys {
        const val ACTIVE_OWNER = "sync.activeOwner"
        const val DEVICE_PREFERENCES = "sync.devicePreferences"
        fun preferences(uid: String) = "sync.preferences.$uid"
        fun progress(uid: String) = "sync.progress.$uid"
        fun journey(uid: String) = "session.localJourney.$uid"
        const val OFFER_OWNER = "offer.activeOwner"
        fun intentions(uid: String) = "offer.intentions.$uid"
        fun syncedIds(uid: String) = "offer.syncedIDs.$uid"
        fun deletedIds(uid: String) = "offer.deletedIDs.$uid"
    }

    private var userId: String? = null
    private var preferencesListener: Registration? = null
    private var progressListener: Registration? = null
    private var intentionsListener: Registration? = null
    private var preferencesUpload: Job? = null
    private var progressUpload: Job? = null
    private var progressNeedsUpload = false
    private var listenerFailed = false
    private var preferencesSchema = SyncedPreferences.Schema.Full
    private var progressSchema = SyncedProgress.Schema.Full

    private val _syncError = MutableStateFlow<String?>(null)
    val syncErrorMessage: StateFlow<String?> = _syncError.asStateFlow()

    /** Values and change times of every synced preference on this device. */
    private var devicePreferences: SyncedPreferences =
        store.get(Keys.DEVICE_PREFERENCES)?.let(::decodePreferences) ?: overlay(SyncedPreferences())

    init {
        settings.onUserChange = { _, _ -> preferencesChangedLocally() }
        session.syncListener = this
    }

    val currentUserId: String? get() = userId

    // MARK: Account switching

    /** Switches to the signed-in account's data. Signed out keeps the current data on device. */
    fun configureSync(uid: String?) {
        if (uid == userId && (uid == null || preferencesListener != null)) return
        stopListening()
        cancelPendingUploads()
        userId = uid
        _syncError.value = null
        if (uid == null) return
        session.canonicalizeIds()
        activateLocalData(uid)
        activateIntentions(uid)
        startListening(uid)
    }

    private fun activateLocalData(uid: String) {
        when (val owner = store.get(Keys.ACTIVE_OWNER)) {
            uid -> Unit // Already this account's data, including changes made while signed out.
            null -> {
                // No account owns the data here: use this account's device copy if there is one;
                // otherwise the account adopts what is on the device.
                loadPreferences(uid)?.let(::applyPreferences)
                loadProgress(uid)?.let { session.applySynced(it, clock()) }
            }
            else -> {
                saveLocalCopies(owner)
                store.set(Keys.journey(owner), RosaryJson.encodeToString(LocalJourneyArchive.serializer(), session.localJourneyArchive()))
                applyPreferences(loadPreferences(uid) ?: defaultsKeepingIcon(settings.current.appIcon))
                session.restoreLocalJourney(
                    store.get(Keys.journey(uid))?.let {
                        runCatching { RosaryJson.decodeFromString(LocalJourneyArchive.serializer(), it) }.getOrNull()
                    },
                )
                session.applySynced(loadProgress(uid) ?: SyncedProgress(), clock())
            }
        }
        store.set(Keys.ACTIVE_OWNER, uid)
        saveLocalCopies(uid)
    }

    /**
     * A guest's intentions belong to whoever signs in first. Sign-out keeps the list on screen
     * (still recording deletions for that account); another account starts from its own copy.
     */
    private fun activateIntentions(uid: String) {
        val owner = store.get(Keys.OFFER_OWNER)
        val now = clock()
        val local: List<OfferIntention> = when (owner) {
            uid -> session.intentions.value
            null -> {
                val mine = loadIntentions(uid)
                val known = mine.map { it.id }.toSet()
                mine + session.intentions.value.filter { it.id !in known }
            }
            else -> {
                saveIntentionsCopy(owner, session.intentions.value)
                loadIntentions(uid)
            }
        }
        session.replaceIntentionsFromSync(local.filter { !it.isExpired(now) })
        store.set(Keys.OFFER_OWNER, uid)
        saveIntentionsCopy(uid, session.intentions.value)
    }

    // MARK: Listening and merging

    private fun startListening(uid: String) {
        listenerFailed = false
        preferencesListener = remote.listen(uid, MetaDocument.Preferences) { handlePreferences(it, uid) }
        progressListener = remote.listen(uid, MetaDocument.Progress) { handleProgress(it, uid) }
        intentionsListener = remote.listenIntentions(uid) { handleIntentions(it, uid) }
    }

    private fun stopListening() {
        preferencesListener?.remove(); preferencesListener = null
        progressListener?.remove(); progressListener = null
        intentionsListener?.remove(); intentionsListener = null
    }

    private fun handlePreferences(result: Result<RemoteDocument>, uid: String) {
        if (uid != userId) return
        val snapshot = result.getOrElse {
            listenerFailed = true
            report(it, "listening to preferences")
            return
        }
        val local = currentPreferences()
        val data = snapshot.data
        val remotePrefs = data?.let { SyncedPreferences.fromFirestore(it) }
        if (remotePrefs == null) {
            // Nothing in the account yet. Only a server-confirmed answer means that.
            if (!snapshot.isFromCache) uploadPreferencesNow()
            return
        }
        if (!snapshot.isFromCache) _syncError.value = null
        val merged = SyncedPreferences.merge(local, remotePrefs, clock())
        if (merged != local) {
            applyPreferences(merged)
            saveLocalCopies(uid)
        }
        if (currentPreferences().stored(preferencesSchema) != remotePrefs.stored(preferencesSchema)) {
            schedulePreferencesUpload(0)
        }
    }

    private fun handleProgress(result: Result<RemoteDocument>, uid: String) {
        if (uid != userId) return
        val snapshot = result.getOrElse {
            listenerFailed = true
            report(it, "listening to progress")
            return
        }
        val now = clock()
        val local = session.syncedProgress().normalized(now, zone)
        val data = snapshot.data
        val remoteProgress = data?.let { SyncedProgress.fromFirestore(it, now, zone) }
        if (data == null || remoteProgress == null) {
            if (!snapshot.isFromCache) uploadProgressNow()
            return
        }
        if (!snapshot.isFromCache) _syncError.value = null
        val filled = remoteProgress.fillingSessionFields(data, local.session, now, zone)
        val merged = SyncedProgress.merge(local, filled, now, zone)
        if (merged.comparable(SyncedProgress.Schema.Full, now, zone) != local.comparable(SyncedProgress.Schema.Full, now, zone)) {
            session.applySynced(merged, now)
            saveLocalCopies(uid)
        }
        val after = session.syncedProgress()
        if (after.comparable(progressSchema, now, zone) != remoteProgress.comparable(progressSchema, now, zone)) {
            scheduleProgressUpload(0)
        }
    }

    private fun handleIntentions(result: Result<RemoteIntentions>, uid: String) {
        if (uid != userId) return
        val snapshot = result.getOrElse {
            _syncError.value = "Intentions could not sync, your copy on this device is safe"
            return
        }
        if (!snapshot.isFromCache) _syncError.value = null
        val now = clock()
        val remoteValues = snapshot.documents.mapNotNull { (id, data) -> IntentionDocuments.fromFirestore(id, data) }
        val merge = IntentionMerge.merge(
            local = session.intentions.value,
            remote = remoteValues,
            deleted = deletedIds(uid),
            previouslySynced = syncedIds(uid),
            isFromCache = snapshot.isFromCache,
            now = now,
        )
        if (!snapshot.isFromCache) setSyncedIds(uid, snapshot.confirmedIds.map(SyncIds::canonical).toSet())
        setDeletedIds(uid, merge.deleted)
        if (merge.intentions != session.intentions.value) session.replaceIntentionsFromSync(merge.intentions)
        saveIntentionsCopy(uid, merge.intentions)
        for (item in merge.toUpload) upsert(uid, item, "Some intentions are still only on this device and have not synced yet")
        for (id in merge.toDelete) scope.launch { runCatching { remote.deleteIntention(uid, id) } }
    }

    // MARK: Local changes

    private fun preferencesChangedLocally() {
        val next = overlay(devicePreferences)
        val now = clock()
        val changed = SyncedPreferences.Field.entries.filter { valueOf(next, it) != valueOf(devicePreferences, it) }
        if (changed.isEmpty()) return
        devicePreferences = next.copy(
            updatedAt = now,
            fieldUpdatedAt = next.fieldUpdatedAt + changed.associate { it.key to now },
        )
        saveDevicePreferences()
        store.get(Keys.ACTIVE_OWNER)?.let { savePreferencesCopy(it) }
        schedulePreferencesUpload(PREFERENCES_DELAY_MS)
    }

    override fun hideIntentionTextChanged(hidden: Boolean) = preferencesChangedLocally()

    override fun progressChanged(significant: Boolean) {
        if (significant) store.get(Keys.ACTIVE_OWNER)?.let { saveProgressCopy(it) }
        if (userId == null) return
        progressNeedsUpload = true
        if (significant) scheduleProgressUpload(PROGRESS_DELAY_MS)
    }

    override fun intentionsChanged(previous: List<OfferIntention>, current: List<OfferIntention>) {
        val owner = store.get(Keys.OFFER_OWNER)
        val before = previous.associateBy { it.id }
        val now = current.associateBy { it.id }
        val removed = before.keys - now.keys
        if (owner != null) {
            saveIntentionsCopy(owner, current)
            // Recorded even signed out, so the account copy cannot bring them back at next sign-in.
            if (removed.isNotEmpty()) setDeletedIds(owner, deletedIds(owner) + removed.associateWith { clock() })
        }
        val uid = userId ?: return
        for (item in current) if (before[item.id] != item) upsert(uid, item, "This intention could not sync to your account")
        for (id in removed) {
            scope.launch {
                runCatching { remote.deleteIntention(uid, id) }
                    .onFailure { _syncError.value = "An intention could not be deleted from your account" }
            }
        }
    }

    private fun upsert(uid: String, item: OfferIntention, failure: String) {
        val data = IntentionDocuments.firestoreData(item, clock())
        scope.launch {
            runCatching { remote.upsertIntention(uid, SyncIds.canonical(item.id), data) }
                .onFailure { if (!isConnectivity(it)) _syncError.value = failure }
        }
    }

    // MARK: Uploads

    private fun schedulePreferencesUpload(delayMs: Long) {
        if (userId == null) return
        preferencesUpload?.cancel()
        preferencesUpload = scope.launch {
            if (delayMs > 0) delay(delayMs)
            uploadPreferencesNow()
        }
    }

    private fun scheduleProgressUpload(delayMs: Long) {
        if (userId == null) return
        progressNeedsUpload = true
        progressUpload?.cancel()
        progressUpload = scope.launch {
            if (delayMs > 0) delay(delayMs)
            uploadProgressNow()
        }
    }

    private fun uploadPreferencesNow() {
        preferencesUpload = null
        val uid = userId ?: return
        if (devicePreferences.updatedAt == SyncedPreferences.NEVER) {
            // First upload of values that were never stamped (defaults or pre-sync settings).
            devicePreferences = overlay(devicePreferences).stamped(clock())
            saveDevicePreferences()
            savePreferencesCopy(uid)
        }
        val schema = preferencesSchema
        remote.write(uid, MetaDocument.Preferences, currentPreferences().firestoreData(schema)) { error ->
            if (uid != userId) return@write
            val next = SyncedPreferences.Schema.entries.getOrNull(schema.ordinal + 1)
            if (error.kind == RemoteError.Kind.PermissionDenied && next != null) {
                // Rules older than this build reject newer fields; step down and keep syncing.
                if (preferencesSchema <= schema) {
                    preferencesSchema = next
                    uploadPreferencesNow()
                }
            } else {
                report(error, "saving preferences")
            }
        }
    }

    private fun uploadProgressNow() {
        progressUpload = null
        progressNeedsUpload = false
        val uid = userId ?: return
        val schema = progressSchema
        val data = session.syncedProgress().firestoreData(schema, clock(), zone)
        remote.write(uid, MetaDocument.Progress, data) { error ->
            if (uid != userId) return@write
            val next = SyncedProgress.Schema.entries.getOrNull(schema.ordinal + 1)
            if (error.kind == RemoteError.Kind.PermissionDenied && next != null) {
                if (progressSchema <= schema) {
                    progressSchema = next
                    uploadProgressNow()
                }
            } else {
                report(error, "saving progress")
            }
        }
    }

    private fun cancelPendingUploads() {
        preferencesUpload?.cancel(); preferencesUpload = null
        progressUpload?.cancel(); progressUpload = null
        progressNeedsUpload = false
    }

    // MARK: App lifecycle

    fun onForeground() {
        val uid = userId ?: return
        if (listenerFailed) {
            stopListening()
            startListening(uid)
        }
    }

    /** Hands anything still waiting to Firestore, which keeps it on disk until it is sent. */
    fun onBackground() {
        store.get(Keys.ACTIVE_OWNER)?.let { saveProgressCopy(it) }
        if (userId == null) return
        if (preferencesUpload != null) uploadPreferencesNow()
        if (progressUpload != null || progressNeedsUpload) uploadProgressNow()
    }

    // MARK: Account deletion

    /** Deletes this account's preferences, progress and intentions. Call while still signed in. */
    suspend fun deleteCloudDataForCurrentUser() {
        val uid = userId ?: return
        stopListening()
        cancelPendingUploads()
        remote.delete(uid, MetaDocument.Preferences)
        remote.delete(uid, MetaDocument.Progress)
        remote.deleteAllIntentions(uid)
        remote.clearLocalCache()
    }

    /** Deletion stopped part way: put the device copy back in the account and listen again. */
    fun restoreCloudDataAfterFailedDeletion() {
        val uid = userId ?: return
        stopListening()
        uploadPreferencesNow()
        uploadProgressNow()
        // The cloud copy may be gone, so nothing counts as confirmed any more.
        store.set(Keys.syncedIds(uid), null)
        val local = session.intentions.value
        scope.launch {
            runCatching {
                for (item in local) remote.upsertIntention(uid, SyncIds.canonical(item.id), IntentionDocuments.firestoreData(item, clock()))
            }.onFailure {
                _syncError.value = "Some intentions are still only on this device and will be restored to your account later"
            }
            if (uid == userId) startListening(uid)
        }
    }

    /** After the Auth account is gone: drop its device copies and reset this device. */
    fun finishAccountDeletion(uid: String?) {
        val deleted = uid ?: userId
        stopListening()
        cancelPendingUploads()
        userId = null
        if (deleted != null) {
            listOf(
                Keys.preferences(deleted), Keys.progress(deleted), Keys.journey(deleted),
                Keys.intentions(deleted), Keys.syncedIds(deleted), Keys.deletedIds(deleted),
            ).forEach { store.set(it, null) }
        }
        store.set(Keys.ACTIVE_OWNER, null)
        store.set(Keys.OFFER_OWNER, null)
        session.clearForAccountDeletion()
        applyPreferences(defaultsKeepingIcon(settings.current.appIcon))
        _syncError.value = null
        scope.launch { runCatching { remote.clearLocalCache() } }
    }

    // MARK: Preferences on this device

    /** The synced preferences as this device holds them now. */
    fun currentPreferences(): SyncedPreferences = overlay(devicePreferences)

    /** [base] with every value Android shows taken from the live stores. */
    private fun overlay(base: SyncedPreferences): SyncedPreferences {
        val s = settings.current
        return base.copy(
            appearance = s.appearance,
            includeSaintMichael = s.rosaryConfig.saintMichael,
            hideIntentionText = session.hideIntentionText,
            dailyReminderEnabled = s.dailyReminderEnabled,
            dailyReminderMinutes = s.dailyReminderMinutes,
            feastAlertsEnabled = s.feastAlertsEnabled,
            feastAlertMinutes = s.feastAlertMinutes,
            appIcon = s.appIcon,
            rosaryConfig = s.rosaryConfig,
        ).normalized()
    }

    /** Applies preferences without counting them as a user change. */
    private fun applyPreferences(value: SyncedPreferences) {
        val previous = settings.current
        settings.applySynced {
            val config = value.rosaryConfig ?: it.rosaryConfig.copy(saintMichael = value.includeSaintMichael)
            it.copy(
                appearance = value.appearance,
                rosaryConfig = config,
                dailyReminderEnabled = value.dailyReminderEnabled,
                dailyReminderMinutes = value.dailyReminderMinutes,
                feastAlertsEnabled = value.feastAlertsEnabled,
                feastAlertMinutes = value.feastAlertMinutes,
                appIcon = value.appIcon,
            )
        }
        session.applySyncedHideIntentionText(value.hideIntentionText)
        devicePreferences = overlay(value)
        saveDevicePreferences()
        val current = settings.current
        if (current != previous) onPreferencesApplied(previous, current)
    }

    private fun valueOf(p: SyncedPreferences, field: SyncedPreferences.Field): Any? = when (field) {
        SyncedPreferences.Field.Appearance -> p.appearance
        SyncedPreferences.Field.PrayerLanguageField -> p.prayerLanguage
        SyncedPreferences.Field.RosaryLanguage -> p.rosaryLanguage
        SyncedPreferences.Field.TextSize -> p.textSize
        SyncedPreferences.Field.IncludeSaintMichael -> p.includeSaintMichael
        SyncedPreferences.Field.HideIntentionText -> p.hideIntentionText
        SyncedPreferences.Field.DailyReminderEnabled -> p.dailyReminderEnabled
        SyncedPreferences.Field.DailyReminderMinutes -> p.dailyReminderMinutes
        SyncedPreferences.Field.FeastAlertsEnabled -> p.feastAlertsEnabled
        SyncedPreferences.Field.FeastAlertMinutes -> p.feastAlertMinutes
        SyncedPreferences.Field.AppIcon -> p.appIcon
        SyncedPreferences.Field.RosaryConfigField -> p.rosaryConfig
    }

    // MARK: Device copies

    private fun saveLocalCopies(uid: String) {
        savePreferencesCopy(uid)
        saveProgressCopy(uid)
    }

    private fun saveDevicePreferences() =
        store.set(Keys.DEVICE_PREFERENCES, RosaryJson.encodeToString(SyncedPreferences.serializer(), devicePreferences))

    private fun savePreferencesCopy(uid: String) =
        store.set(Keys.preferences(uid), RosaryJson.encodeToString(SyncedPreferences.serializer(), currentPreferences()))

    private fun saveProgressCopy(uid: String) =
        store.set(Keys.progress(uid), RosaryJson.encodeToString(SyncedProgress.serializer(), session.syncedProgress().normalized(clock(), zone)))

    private fun loadPreferences(uid: String): SyncedPreferences? = store.get(Keys.preferences(uid))?.let(::decodePreferences)

    private fun loadProgress(uid: String): SyncedProgress? = store.get(Keys.progress(uid))?.let {
        runCatching { RosaryJson.decodeFromString(SyncedProgress.serializer(), it) }.getOrNull()
    }

    private fun loadIntentions(uid: String): List<OfferIntention> = store.get(Keys.intentions(uid))?.let {
        runCatching { RosaryJson.decodeFromString(ListSerializer(OfferIntention.serializer()), it) }.getOrNull()
    } ?: emptyList()

    private fun saveIntentionsCopy(uid: String, values: List<OfferIntention>) =
        store.set(Keys.intentions(uid), RosaryJson.encodeToString(ListSerializer(OfferIntention.serializer()), values))

    private fun syncedIds(uid: String): Set<String> = store.get(Keys.syncedIds(uid))?.let {
        runCatching { RosaryJson.decodeFromString(ListSerializer(String.serializer()), it) }.getOrNull()
    }?.toSet() ?: emptySet()

    private fun setSyncedIds(uid: String, ids: Set<String>) =
        store.set(Keys.syncedIds(uid), RosaryJson.encodeToString(ListSerializer(String.serializer()), ids.sorted()))

    private fun deletedIds(uid: String): Map<String, Long> = store.get(Keys.deletedIds(uid))?.let {
        runCatching { RosaryJson.decodeFromString(idTimes, it) }.getOrNull()
    } ?: emptyMap()

    private fun setDeletedIds(uid: String, ids: Map<String, Long>) =
        store.set(Keys.deletedIds(uid), if (ids.isEmpty()) null else RosaryJson.encodeToString(idTimes, ids))

    /** Quiet notice for real failures only; offline writes wait in Firestore's queue. */
    private fun report(error: Throwable, action: String) {
        if (isConnectivity(error)) return
        _syncError.value = "Settings and prayer history are saved on this device but could not sync"
    }

    private fun isConnectivity(error: Throwable): Boolean =
        (error as? RemoteError)?.kind == RemoteError.Kind.Connectivity

    companion object {
        const val PREFERENCES_DELAY_MS = 2_000L
        const val PROGRESS_DELAY_MS = 3_000L
        private val idTimes = MapSerializer(String.serializer(), Long.serializer())

        private fun decodePreferences(raw: String): SyncedPreferences? =
            runCatching { RosaryJson.decodeFromString(SyncedPreferences.serializer(), raw) }.getOrNull()

        /** Defaults for a fresh account, keeping the icon already on the launcher. */
        fun defaultsKeepingIcon(icon: AppIconOption): SyncedPreferences =
            SyncedPreferences(appIcon = icon, rosaryConfig = null)
    }
}
