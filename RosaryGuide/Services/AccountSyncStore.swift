import Foundation
import FirebaseFirestore
import Observation
import OSLog
import UIKit

// MARK: - Synced models

extension Date {
    /// Firestore timestamps and UserDefaults doubles do not round-trip every bit of a `Date`,
    /// so every synced date is kept to whole milliseconds. That keeps "has this changed?"
    /// comparisons stable and stops a write from bouncing back as a fresh change.
    var syncRounded: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1000).rounded() / 1000)
    }

    static let syncNever = Date(timeIntervalSince1970: 0)
}

/// User-facing preferences that follow the account between devices.
/// Device-only state (onboarding seen, notification permission, caches) is not included.
struct SyncedPreferences: Codable, Equatable {
    var appearance: AppearancePreference
    var prayerLanguage: PrayerLanguage
    var rosaryLanguage: PrayerLanguage
    var textSize: PrayerTextSize
    var includeSaintMichael: Bool
    var hideIntentionText: Bool
    var dailyReminderEnabled: Bool
    var dailyReminderMinutes: Int
    var feastAlertsEnabled: Bool
    /// Feast day alert time as minutes after local midnight (default 8:00 am).
    var feastAlertMinutes: Int
    var appIcon: AppIconOption
    /// When the user last changed any of these. `.syncNever` means never (defaults or values
    /// from before sync existed), so any copy in the account wins.
    var updatedAt: Date

    static let defaults = SyncedPreferences(
        appearance: .system,
        prayerLanguage: .english,
        rosaryLanguage: .english,
        textSize: .medium,
        includeSaintMichael: false,
        hideIntentionText: false,
        dailyReminderEnabled: false,
        dailyReminderMinutes: 19 * 60,
        feastAlertsEnabled: false,
        feastAlertMinutes: SyncedPreferences.defaultFeastAlertMinutes,
        appIcon: .black,
        updatedAt: .syncNever
    )

    static let defaultFeastAlertMinutes = 8 * 60

    private enum CodingKeys: String, CodingKey {
        case appearance, prayerLanguage, rosaryLanguage, textSize, includeSaintMichael, hideIntentionText
        case dailyReminderEnabled, dailyReminderMinutes, feastAlertsEnabled, feastAlertMinutes, appIcon, updatedAt
    }

    var normalized: SyncedPreferences {
        var copy = self
        copy.updatedAt = updatedAt.syncRounded
        copy.dailyReminderMinutes = max(0, min(24 * 60 - 1, dailyReminderMinutes))
        copy.feastAlertMinutes = max(0, min(24 * 60 - 1, feastAlertMinutes))
        return copy
    }

    /// Last write wins for the whole set. Ties go to the account copy.
    static func merge(local: SyncedPreferences, remote: SyncedPreferences) -> SyncedPreferences {
        remote.updatedAt >= local.updatedAt ? remote : local
    }
}

extension SyncedPreferences {
    /// Device copies saved before `feastAlertMinutes` existed decode with the 8:00 am default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            appearance: try c.decode(AppearancePreference.self, forKey: .appearance),
            prayerLanguage: try c.decode(PrayerLanguage.self, forKey: .prayerLanguage),
            rosaryLanguage: try c.decode(PrayerLanguage.self, forKey: .rosaryLanguage),
            textSize: try c.decode(PrayerTextSize.self, forKey: .textSize),
            includeSaintMichael: try c.decode(Bool.self, forKey: .includeSaintMichael),
            hideIntentionText: try c.decode(Bool.self, forKey: .hideIntentionText),
            dailyReminderEnabled: try c.decode(Bool.self, forKey: .dailyReminderEnabled),
            dailyReminderMinutes: try c.decode(Int.self, forKey: .dailyReminderMinutes),
            feastAlertsEnabled: try c.decode(Bool.self, forKey: .feastAlertsEnabled),
            feastAlertMinutes: try c.decodeIfPresent(Int.self, forKey: .feastAlertMinutes) ?? Self.defaultFeastAlertMinutes,
            appIcon: try c.decode(AppIconOption.self, forKey: .appIcon),
            updatedAt: try c.decode(Date.self, forKey: .updatedAt)
        )
    }
}

/// Prayer progress that follows the account: prayed days and the in-progress rosary.
struct SyncedProgress: Codable, Equatable {
    /// Local calendar days ("yyyy-MM-dd") on which a rosary was finished.
    var completedDays: Set<String>
    var session: PrayerSession?
    /// When the in-progress rosary was last started, advanced, finished or discarded.
    var sessionChangedAt: Date
    /// Set by "Delete local data"; days from before it are not merged back in.
    var historyResetAt: Date?

    static let empty = SyncedProgress(completedDays: [], session: nil, sessionChangedAt: .syncNever, historyResetAt: nil)

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(forDayKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nil
        }
        return calendar.startOfDay(for: date)
    }

    static func cutoffDayKey(now: Date = .now, calendar: Calendar = .current) -> String {
        let cutoff = calendar.date(byAdding: .day, value: -SessionStore.historyWindowDays, to: now) ?? now
        return dayKey(for: cutoff, calendar: calendar)
    }

    var normalized: SyncedProgress {
        var copy = self
        copy.sessionChangedAt = sessionChangedAt.syncRounded
        copy.historyResetAt = historyResetAt?.syncRounded
        if var session = copy.session {
            session.startedAt = session.startedAt.syncRounded
            session.updatedAt = session.updatedAt.syncRounded
            if let title = session.intentionTitle, title.count > 160 {
                session.intentionTitle = String(title.prefix(160))
            }
            copy.session = session
        }
        let cutoff = Self.cutoffDayKey()
        copy.completedDays = completedDays.filter { Self.date(forDayKey: $0) != nil && $0 >= cutoff }
        return copy
    }

    /// Prayed days are a union (minus anything wiped by the newest "Delete local data").
    /// The in-progress rosary is last write wins; ties go to the account copy.
    static func merge(local: SyncedProgress, remote: SyncedProgress) -> SyncedProgress {
        let reset = [local.historyResetAt, remote.historyResetAt].compactMap { $0 }.max()

        func contribution(_ progress: SyncedProgress) -> Set<String> {
            guard let reset, (progress.historyResetAt ?? .distantPast) < reset else {
                return progress.completedDays
            }
            // This side has not seen the newest wipe: only days after it still count.
            let resetDay = dayKey(for: reset)
            return progress.completedDays.filter { $0 > resetDay }
        }

        let newer = remote.sessionChangedAt >= local.sessionChangedAt ? remote : local
        var session = newer.session
        if let current = session, !current.isSameCalendarDay {
            session = nil
        }
        return SyncedProgress(
            completedDays: contribution(local).union(contribution(remote)),
            session: session,
            sessionChangedAt: newer.sessionChangedAt,
            historyResetAt: reset
        ).normalized
    }
}

// MARK: - Firestore mapping

private extension SyncedPreferences {
    init?(firestore data: [String: Any]) {
        guard
            let appearance = (data["appearance"] as? String).flatMap(AppearancePreference.init(rawValue:)),
            let prayerLanguage = (data["prayerLanguage"] as? String).flatMap(PrayerLanguage.init(rawValue:)),
            let rosaryLanguage = (data["rosaryLanguage"] as? String).flatMap(PrayerLanguage.init(rawValue:)),
            let textSize = (data["textSize"] as? String).flatMap(PrayerTextSize.init(rawValue:)),
            let includeSaintMichael = data["includeSaintMichael"] as? Bool,
            let hideIntentionText = data["hideIntentionText"] as? Bool,
            let dailyReminderEnabled = data["dailyReminderEnabled"] as? Bool,
            let dailyReminderMinutes = data["dailyReminderMinutes"] as? Int,
            let feastAlertsEnabled = data["feastAlertsEnabled"] as? Bool,
            let appIcon = (data["appIcon"] as? String).flatMap(AppIconOption.init(rawValue:)),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.init(
            appearance: appearance,
            prayerLanguage: prayerLanguage,
            rosaryLanguage: rosaryLanguage,
            textSize: textSize,
            includeSaintMichael: includeSaintMichael,
            hideIntentionText: hideIntentionText,
            dailyReminderEnabled: dailyReminderEnabled,
            dailyReminderMinutes: dailyReminderMinutes,
            feastAlertsEnabled: feastAlertsEnabled,
            // Documents written before this field existed get the 8:00 am default.
            feastAlertMinutes: data["feastAlertMinutes"] as? Int ?? Self.defaultFeastAlertMinutes,
            appIcon: appIcon,
            updatedAt: updatedAt
        )
        self = normalized
    }

    func firestoreData() -> [String: Any] {
        [
            "schemaVersion": 1,
            "appearance": appearance.rawValue,
            "prayerLanguage": prayerLanguage.rawValue,
            "rosaryLanguage": rosaryLanguage.rawValue,
            "textSize": textSize.rawValue,
            "includeSaintMichael": includeSaintMichael,
            "hideIntentionText": hideIntentionText,
            "dailyReminderEnabled": dailyReminderEnabled,
            "dailyReminderMinutes": max(0, min(24 * 60 - 1, dailyReminderMinutes)),
            "feastAlertsEnabled": feastAlertsEnabled,
            "feastAlertMinutes": max(0, min(24 * 60 - 1, feastAlertMinutes)),
            "appIcon": appIcon.rawValue,
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}

private extension SyncedProgress {
    init?(firestore data: [String: Any]) {
        guard
            let days = data["completedDays"] as? [String],
            let sessionChangedAt = (data["sessionChangedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        var session: PrayerSession?
        if let map = data["session"] as? [String: Any],
           let set = (map["mysterySet"] as? String).flatMap(MysterySetKind.init(rawValue:)),
           let stepIndex = map["stepIndex"] as? Int,
           let startedAt = (map["startedAt"] as? Timestamp)?.dateValue(),
           let updatedAt = (map["updatedAt"] as? Timestamp)?.dateValue(),
           let includeSaintMichael = map["includeSaintMichael"] as? Bool,
           let language = (map["language"] as? String).flatMap(PrayerLanguage.init(rawValue:)) {
            session = PrayerSession(
                mysterySet: set,
                stepIndex: stepIndex,
                startedAt: startedAt,
                updatedAt: updatedAt,
                includeSaintMichael: includeSaintMichael,
                language: language,
                intentionId: (map["intentionId"] as? String).flatMap(UUID.init(uuidString:)),
                intentionTitle: map["intentionTitle"] as? String
            )
        }

        self.init(
            completedDays: Set(days),
            session: session,
            sessionChangedAt: sessionChangedAt,
            historyResetAt: (data["historyResetAt"] as? Timestamp)?.dateValue()
        )
        self = normalized
    }

    func firestoreData() -> [String: Any] {
        let value = normalized
        var data: [String: Any] = [
            "schemaVersion": 1,
            "completedDays": value.completedDays.sorted(),
            "sessionChangedAt": Timestamp(date: value.sessionChangedAt),
            "updatedAt": Timestamp(date: Date())
        ]
        if let reset = value.historyResetAt {
            data["historyResetAt"] = Timestamp(date: reset)
        }
        if let session = value.session {
            var map: [String: Any] = [
                "mysterySet": session.mysterySet.rawValue,
                "stepIndex": max(0, min(500, session.stepIndex)),
                "startedAt": Timestamp(date: session.startedAt),
                "updatedAt": Timestamp(date: session.updatedAt),
                "includeSaintMichael": session.includeSaintMichael,
                "language": session.language.rawValue
            ]
            if let id = session.intentionId {
                map["intentionId"] = id.uuidString
            }
            if let title = session.intentionTitle {
                map["intentionTitle"] = title
            }
            data["session"] = map
        }
        return data
    }
}

// MARK: - Repository

struct AccountDocumentSnapshot {
    var data: [String: Any]?
    var isFromCache: Bool
}

/// `/users/{uid}/meta/preferences` and `/users/{uid}/meta/progress`.
/// Uses `Firestore.firestore()` on every call: account deletion terminates the shared instance,
/// and a fresh call returns a working one afterwards.
private final class AccountDataRepository {
    enum Document: String, CaseIterable {
        case preferences
        case progress
    }

    func listen(_ document: Document, uid: String, onChange: @escaping (Result<AccountDocumentSnapshot, Error>) -> Void) -> ListenerRegistration {
        reference(document, uid: uid).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot else { return }
            onChange(.success(AccountDocumentSnapshot(
                data: snapshot.exists ? snapshot.data() : nil,
                isFromCache: snapshot.metadata.isFromCache
            )))
        }
    }

    /// Queues the write in Firestore's offline store at once; the completion runs when the
    /// server accepts or rejects it.
    func write(_ data: [String: Any], to document: Document, uid: String, completion: @escaping (Error?) -> Void) {
        reference(document, uid: uid).setData(data, merge: false, completion: completion)
    }

    func deleteAll(uid: String) async throws {
        for document in Document.allCases {
            try await reference(document, uid: uid).delete()
        }
    }

    private func reference(_ document: Document, uid: String) -> DocumentReference {
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("meta").document(document.rawValue)
    }
}

// MARK: - Store

/// Keeps preferences and prayer progress in step with the signed-in account.
///
/// Local first: the app always reads and writes `SettingsStore` and `SessionStore`, which work
/// offline and signed out. Each account also has its own copy on this device, so switching
/// accounts never mixes data. While signed in, changes are uploaded after a short pause, and
/// account changes from other devices are merged in (preferences: last write wins by
/// `updatedAt`; prayed days: union).
@Observable
@MainActor
final class AccountSyncStore {
    private enum Keys {
        /// The account whose data `SettingsStore` and `SessionStore` currently hold.
        static let activeOwner = "sync.activeOwner"
        static func preferences(_ uid: String) -> String { "sync.preferences." + uid }
        static func progress(_ uid: String) -> String { "sync.progress." + uid }
    }

    private static let preferencesDelay: Duration = .seconds(2)
    private static let progressDelay: Duration = .seconds(3)

    private let defaults: UserDefaults
    private let settings: SettingsStore
    private let session: SessionStore
    private let appIcon: AppIconService
    private let repository = AccountDataRepository()
    private let log = Logger(subsystem: "com.shasasmith.RosaryGuide", category: "AccountSync")

    private var userID: String?
    private var preferencesListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?
    private var preferencesUpload: Task<Void, Never>?
    private var progressUpload: Task<Void, Never>?
    /// Bead-by-bead progress is not uploaded on every step (Spark quota); it goes up with the
    /// next significant change or when the app leaves the foreground.
    private var progressNeedsUpload = false
    /// A listener that failed (offline start, rules not published yet) is dead; it is restarted
    /// the next time the app comes to the foreground.
    private var listenerFailed = false
    private(set) var syncErrorMessage: String?

    init(settings: SettingsStore, session: SessionStore, appIcon: AppIconService, defaults: UserDefaults = .standard) {
        self.settings = settings
        self.session = session
        self.appIcon = appIcon
        self.defaults = defaults

        if !settings.hasStoredAppIconChoice {
            settings.applySyncedAppIconChoice(appIcon.current)
        }
        settings.onUserChange = { [weak self] in
            Task { @MainActor in self?.preferencesChangedLocally() }
        }
        session.onUserChange = { [weak self] significant in
            Task { @MainActor in self?.progressChangedLocally(significant: significant) }
        }
        appIcon.onUserSelect = { [weak settings] option in
            settings?.appIconChoice = option
        }
    }

    private var activeOwner: String? {
        get { defaults.string(forKey: Keys.activeOwner) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.activeOwner)
            } else {
                defaults.removeObject(forKey: Keys.activeOwner)
            }
        }
    }

    // MARK: Account switching

    /// Switches to the signed-in account's data (signed out keeps the current data on device).
    func configureSync(for uid: String?) {
        if uid == userID && (uid == nil || preferencesListener != nil) { return }

        stopListening()
        cancelPendingUploads()
        userID = uid
        syncErrorMessage = nil

        guard let uid else { return }
        activateLocalData(for: uid)
        startListening(uid: uid)
    }

    private func activateLocalData(for uid: String) {
        switch activeOwner {
        case uid:
            break // Already this account's data, including any changes made while signed out.
        case nil:
            // No account owns the data on this device (first run with sync, or after a deleted
            // account). Use this account's device copy if there is one; otherwise the account
            // adopts what is here, the way older builds' intentions are adopted.
            if let preferences = loadPreferences(uid) { applyPreferences(preferences) }
            if let progress = loadProgress(uid) { session.applySynced(progress) }
        case let other?:
            saveLocalCopies(for: other)
            applyPreferences(loadPreferences(uid) ?? .defaultsKeepingIcon(appIcon.current))
            session.applySynced(loadProgress(uid) ?? .empty)
        }
        activeOwner = uid
        saveLocalCopies(for: uid)
    }

    // MARK: Listening and merging

    private func startListening(uid: String) {
        listenerFailed = false
        preferencesListener = repository.listen(.preferences, uid: uid) { [weak self] result in
            Task { @MainActor in self?.handlePreferences(result, uid: uid) }
        }
        progressListener = repository.listen(.progress, uid: uid) { [weak self] result in
            Task { @MainActor in self?.handleProgress(result, uid: uid) }
        }
    }

    private func stopListening() {
        preferencesListener?.remove()
        preferencesListener = nil
        progressListener?.remove()
        progressListener = nil
    }

    private func handlePreferences(_ result: Result<AccountDocumentSnapshot, Error>, uid: String) {
        guard uid == userID else { return }
        switch result {
        case .failure(let error):
            listenerFailed = true
            report(error, while: "listening to preferences")
        case .success(let snapshot):
            let local = settings.syncedPreferences.normalized
            guard let data = snapshot.data, let remote = SyncedPreferences(firestore: data) else {
                // Nothing in the account yet. Only a server-confirmed answer means that.
                if !snapshot.isFromCache { uploadPreferencesNow() }
                return
            }
            if !snapshot.isFromCache { syncErrorMessage = nil }
            let merged = SyncedPreferences.merge(local: local, remote: remote)
            if merged != local {
                applyPreferences(merged)
                saveLocalCopies(for: uid)
            }
            if merged != remote {
                schedulePreferencesUpload(after: .zero)
            }
        }
    }

    private func handleProgress(_ result: Result<AccountDocumentSnapshot, Error>, uid: String) {
        guard uid == userID else { return }
        switch result {
        case .failure(let error):
            listenerFailed = true
            report(error, while: "listening to progress")
        case .success(let snapshot):
            let local = session.syncedProgress.normalized
            guard let data = snapshot.data, let remote = SyncedProgress(firestore: data) else {
                if !snapshot.isFromCache { uploadProgressNow() }
                return
            }
            if !snapshot.isFromCache { syncErrorMessage = nil }
            let merged = SyncedProgress.merge(local: local, remote: remote)
            if merged != local {
                session.applySynced(merged)
                saveLocalCopies(for: uid)
            }
            if merged != remote {
                scheduleProgressUpload(after: .zero)
            }
        }
    }

    /// Applies preferences without counting them as a user change, then brings notifications
    /// and the app icon in line. Notifications are only rescheduled through
    /// `NotificationService.reschedule`, which never asks for permission and schedules nothing
    /// unless it was already granted.
    private func applyPreferences(_ preferences: SyncedPreferences) {
        let oldPlan = settings.notificationPlan
        settings.applySynced(preferences)
        let plan = settings.notificationPlan
        if plan != oldPlan {
            Task { await NotificationService.reschedule(plan) }
        }
        appIcon.applySynced(preferences.appIcon)
    }

    // MARK: Local changes and uploads

    private func preferencesChangedLocally() {
        if let owner = activeOwner {
            savePreferencesCopy(for: owner)
        }
        schedulePreferencesUpload(after: Self.preferencesDelay)
    }

    private func progressChangedLocally(significant: Bool) {
        if let owner = activeOwner {
            saveProgressCopy(for: owner)
        }
        guard userID != nil else { return }
        progressNeedsUpload = true
        if significant {
            scheduleProgressUpload(after: Self.progressDelay)
        }
    }

    private func schedulePreferencesUpload(after delay: Duration) {
        guard userID != nil else { return }
        preferencesUpload?.cancel()
        preferencesUpload = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            self?.uploadPreferencesNow()
        }
    }

    private func scheduleProgressUpload(after delay: Duration) {
        guard userID != nil else { return }
        progressNeedsUpload = true
        progressUpload?.cancel()
        progressUpload = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            self?.uploadProgressNow()
        }
    }

    private func uploadPreferencesNow() {
        preferencesUpload?.cancel()
        preferencesUpload = nil
        guard let uid = userID else { return }
        if settings.preferencesUpdatedAt == .syncNever {
            // First upload of values that were never stamped (defaults or pre-sync settings).
            settings.stampPreferences()
            savePreferencesCopy(for: uid)
        }
        let data = settings.syncedPreferences.normalized.firestoreData()
        repository.write(data, to: .preferences, uid: uid) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.report(error, while: "saving preferences") }
        }
    }

    private func uploadProgressNow() {
        progressUpload?.cancel()
        progressUpload = nil
        progressNeedsUpload = false
        guard let uid = userID else { return }
        let data = session.syncedProgress.firestoreData()
        repository.write(data, to: .progress, uid: uid) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.report(error, while: "saving progress") }
        }
    }

    private func cancelPendingUploads() {
        preferencesUpload?.cancel()
        preferencesUpload = nil
        progressUpload?.cancel()
        progressUpload = nil
        progressNeedsUpload = false
    }

    // MARK: App lifecycle

    func sceneBecameActive() {
        appIcon.applyPendingSyncedIcon()
        if listenerFailed, let uid = userID {
            stopListening()
            startListening(uid: uid)
        }
    }

    /// Hands anything still waiting to Firestore, which keeps it on disk until it reaches the
    /// server, even if the app is closed.
    func sceneWillLeaveForeground() {
        guard userID != nil else { return }
        if preferencesUpload != nil { uploadPreferencesNow() }
        if progressUpload != nil || progressNeedsUpload { uploadProgressNow() }
    }

    // MARK: Account deletion

    /// Deletes this account's preferences and progress documents. Call while still signed in.
    func deleteCloudDataForCurrentUser() async throws {
        guard let uid = userID else { return }
        stopListening()
        cancelPendingUploads()
        try await repository.deleteAll(uid: uid)
    }

    /// Account deletion stopped part way: put the device copy back in the account.
    func restoreCloudDataAfterFailedDeletion() {
        guard let uid = userID else { return }
        stopListening()
        uploadPreferencesNow()
        uploadProgressNow()
        startListening(uid: uid)
    }

    /// After the Auth account is gone: remove this account's device copies and reset the
    /// synced preferences and progress on this device.
    func finishAccountDeletion(uid: String?) {
        let deletedUID = uid ?? userID
        stopListening()
        cancelPendingUploads()
        userID = nil
        if let deletedUID {
            defaults.removeObject(forKey: Keys.preferences(deletedUID))
            defaults.removeObject(forKey: Keys.progress(deletedUID))
        }
        activeOwner = nil
        applyPreferences(.defaultsKeepingIcon(appIcon.current))
        session.clearForAccountDeletion()
        syncErrorMessage = nil
    }

    // MARK: Device copies

    private func saveLocalCopies(for uid: String) {
        savePreferencesCopy(for: uid)
        saveProgressCopy(for: uid)
    }

    private func savePreferencesCopy(for uid: String) {
        if let data = try? JSONEncoder().encode(settings.syncedPreferences.normalized) {
            defaults.set(data, forKey: Keys.preferences(uid))
        }
    }

    private func saveProgressCopy(for uid: String) {
        if let data = try? JSONEncoder().encode(session.syncedProgress.normalized) {
            defaults.set(data, forKey: Keys.progress(uid))
        }
    }

    private func loadPreferences(_ uid: String) -> SyncedPreferences? {
        guard let data = defaults.data(forKey: Keys.preferences(uid)) else { return nil }
        return try? JSONDecoder().decode(SyncedPreferences.self, from: data)
    }

    private func loadProgress(_ uid: String) -> SyncedProgress? {
        guard let data = defaults.data(forKey: Keys.progress(uid)) else { return nil }
        return try? JSONDecoder().decode(SyncedProgress.self, from: data)
    }

    private func report(_ error: Error, while action: String) {
        let nsError = error as NSError
        log.error("Account sync failed while \(action, privacy: .public): \(nsError.domain, privacy: .public) \(nsError.code) \(nsError.localizedDescription, privacy: .public)")
        #if DEBUG
        print("[AccountSync] failed while \(action): \(nsError.domain) \(nsError.code) \(nsError.localizedDescription)")
        #endif
        syncErrorMessage = "Your settings and prayer history could not sync. They are still on this device."
    }
}

private extension SyncedPreferences {
    /// Defaults for a fresh account, keeping the icon already on the Home Screen
    /// (changing it shows a system alert, so it only changes when the user's choice says so).
    static func defaultsKeepingIcon(_ icon: AppIconOption) -> SyncedPreferences {
        var value = SyncedPreferences.defaults
        value.appIcon = icon
        return value
    }
}
