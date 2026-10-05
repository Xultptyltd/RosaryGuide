import Foundation
import Observation

@Observable
final class SessionStore {
    private let key = "session.prayer"
    private let historyKey = "session.completedDays"
    private let changedAtKey = "session.changedAt"
    private let historyResetKey = "session.historyResetAt"
    private let completedSetsKey = "session.completedSetsToday"

    /// How far back prayed-day history is kept (on device and in the account).
    static let historyWindowDays = 366

    var session: PrayerSession? {
        didSet {
            persist()
            if !isApplyingSynced {
                sessionChangedAt = Date().syncRounded
                // Advancing a bead is frequent; starting, finishing, discarding or changing the
                // intention is what other devices need to hear about promptly.
                let significant = oldValue?.startedAt != session?.startedAt
                    || oldValue?.intentionId != session?.intentionId
                    || oldValue?.intentionTitle != session?.intentionTitle
                onUserChange?(significant)
            }
        }
    }

    /// Day-start timestamps (timeIntervalSince1970) of days a rosary was finished.
    private(set) var completedDayStarts: Set<TimeInterval> = []

    /// Mystery sets finished on `completedSetsDay` (yyyy-MM-dd). Device-only: synced progress
    /// records prayed days, not sets, and its Firestore rules allow no extra field.
    private(set) var completedSets: Set<MysterySetKind> = []
    private(set) var completedSetsDay: String = ""

    /// When the in-progress rosary was last started, advanced, finished or discarded.
    /// Used for last-write-wins between devices.
    private(set) var sessionChangedAt: Date {
        didSet { UserDefaults.standard.set(sessionChangedAt.timeIntervalSince1970, forKey: changedAtKey) }
    }

    /// Set by "Delete local data". Older history from another device is not merged back in.
    private(set) var historyResetAt: Date? {
        didSet {
            if let historyResetAt {
                UserDefaults.standard.set(historyResetAt.timeIntervalSince1970, forKey: historyResetKey)
            } else {
                UserDefaults.standard.removeObject(forKey: historyResetKey)
            }
        }
    }

    /// Called after the user changes progress or history (not when synced data is applied).
    /// The flag is false for bead-by-bead progress, which does not need an immediate upload.
    @ObservationIgnored var onUserChange: ((Bool) -> Void)?
    @ObservationIgnored private var isApplyingSynced = false

    var resumableSession: PrayerSession? {
        guard let session, session.isSameCalendarDay, session.stepIndex > 0 else { return nil }
        return session
    }

    init() {
        let defaults = UserDefaults.standard
        sessionChangedAt = Date(timeIntervalSince1970: defaults.double(forKey: changedAtKey))
        let reset = defaults.double(forKey: historyResetKey)
        historyResetAt = reset > 0 ? Date(timeIntervalSince1970: reset) : nil
        isApplyingSynced = true
        session = Self.load(key: key)
        if let session, !session.isSameCalendarDay {
            self.session = nil
        }
        isApplyingSynced = false
        completedDayStarts = Self.loadHistory(key: historyKey)
        pruneHistory()
        if let stored = defaults.dictionary(forKey: completedSetsKey),
           let day = stored["day"] as? String,
           let sets = stored["sets"] as? [String] {
            completedSetsDay = day
            completedSets = Set(sets.compactMap(MysterySetKind.init(rawValue:)))
        }
    }

    /// True when this mystery set was finished today on this device. Resets the next day.
    func completedToday(_ set: MysterySetKind, now: Date = .now) -> Bool {
        completedSetsDay == SyncedProgress.dayKey(for: now) && completedSets.contains(set)
    }

    private func recordCompletedSet(_ set: MysterySetKind) {
        let today = SyncedProgress.dayKey(for: Date())
        if completedSetsDay != today {
            completedSetsDay = today
            completedSets = []
        }
        completedSets.insert(set)
        persistCompletedSets()
    }

    private func clearCompletedSets() {
        completedSets = []
        completedSetsDay = ""
        persistCompletedSets()
    }

    private func persistCompletedSets() {
        if completedSets.isEmpty {
            UserDefaults.standard.removeObject(forKey: completedSetsKey)
        } else {
            UserDefaults.standard.set(
                ["day": completedSetsDay, "sets": completedSets.map(\.rawValue).sorted()],
                forKey: completedSetsKey
            )
        }
    }

    func start(set: MysterySetKind, language: PrayerLanguage, intentionId: UUID? = nil, intentionTitle: String? = nil) {
        let now = Date()
        session = PrayerSession(
            mysterySet: set,
            stepIndex: 0,
            startedAt: now,
            updatedAt: now,
            includeSaintMichael: false,
            language: language,
            intentionId: intentionId,
            intentionTitle: intentionTitle
        )
    }

    func updateIntention(id: UUID?, title: String?) {
        guard var current = session else { return }
        current.intentionId = id
        current.intentionTitle = title
        current.updatedAt = Date()
        session = current
    }

    func updateStep(_ index: Int) {
        guard var current = session else { return }
        current.stepIndex = index
        current.updatedAt = Date()
        session = current
    }

    func complete() {
        let start = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        if let set = session?.mysterySet {
            recordCompletedSet(set)
        }
        completedDayStarts.insert(start)
        persistHistory()
        session = nil
        onUserChange?(true)
    }

    func prayed(on day: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: day).timeIntervalSince1970
        return completedDayStarts.contains(start)
    }

    private func pruneHistory() {
        let pruned = Self.pruned(completedDayStarts)
        if pruned.count != completedDayStarts.count {
            completedDayStarts = pruned
            persistHistory()
        }
    }

    private static func pruned(_ days: Set<TimeInterval>) -> Set<TimeInterval> {
        let cal = Calendar.current
        guard let cutoffDate = cal.date(byAdding: .day, value: -historyWindowDays, to: Date()) else { return days }
        let cutoff = cal.startOfDay(for: cutoffDate).timeIntervalSince1970
        return days.filter { $0 >= cutoff }
    }

    private func persistHistory() {
        UserDefaults.standard.set(Array(completedDayStarts), forKey: historyKey)
    }

    private static func loadHistory(key: String) -> Set<TimeInterval> {
        let values = UserDefaults.standard.array(forKey: key) as? [Double] ?? []
        return Set(values)
    }

    func discard() {
        session = nil
    }

    /// Clears the in-progress rosary and prayer history (Settings wipe). When signed in,
    /// the reset also reaches the account so other devices don't merge old days back.
    func clearHistoryAndData() {
        completedDayStarts = []
        persistHistory()
        clearCompletedSets()
        historyResetAt = Date().syncRounded
        session = nil
        onUserChange?(true)
    }

    // MARK: - Sync

    /// Progress as it is stored in the account.
    var syncedProgress: SyncedProgress {
        SyncedProgress(
            completedDays: Set(completedDayStarts.map { SyncedProgress.dayKey(for: Date(timeIntervalSince1970: $0)) }),
            session: session,
            sessionChangedAt: sessionChangedAt,
            historyResetAt: historyResetAt
        )
    }

    /// Replaces local progress with synced progress without reporting a user change.
    func applySynced(_ progress: SyncedProgress) {
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        let days = Set(progress.completedDays.compactMap { SyncedProgress.date(forDayKey: $0)?.timeIntervalSince1970 })
        completedDayStarts = Self.pruned(days)
        persistHistory()
        // Another account's data, or history wiped elsewhere: today's sets no longer apply.
        if !progress.completedDays.contains(SyncedProgress.dayKey(for: Date())) {
            clearCompletedSets()
        }
        historyResetAt = progress.historyResetAt
        sessionChangedAt = progress.sessionChangedAt
        if let incoming = progress.session, incoming.isSameCalendarDay {
            session = incoming
        } else {
            session = nil
        }
    }

    /// Delete account: wipe everything, including sync timestamps.
    func clearForAccountDeletion() {
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        completedDayStarts = []
        persistHistory()
        clearCompletedSets()
        session = nil
        sessionChangedAt = .syncNever
        historyResetAt = nil
    }

    private func persist() {
        if let session, let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func load(key: String) -> PrayerSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PrayerSession.self, from: data)
    }
}
