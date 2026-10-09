import Foundation
import Observation

struct CompletedPrayerSession: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: UUID
    var sessionId: UUID?
    var mysterySet: MysterySetKind
    var startedAt: Date
    var completedAt: Date
    var duration: TimeInterval
    var intentionId: UUID?
    var intentionTitle: String?
    var intentionCategory: IntentionCategory? = nil
    var intentionSourceId: String? = nil
}

struct CompletedDecadeSession: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: UUID
    var sessionId: UUID
    var mysterySet: MysterySetKind
    var decadeNumber: Int
    var completedAt: Date
    var duration: TimeInterval
    var intentionId: UUID?
    var intentionTitle: String?
}

@Observable
final class SessionStore {
    @ObservationIgnored private let defaults: UserDefaults
    private let milestoneKey = "session.earnedMilestones"
    private let milestoneOwnerKey = "session.milestoneOwner"
    private(set) var earnedMilestones: [String: JourneyMilestones.Award] = [:]
    private var milestoneOwner: String?

    private let key = "session.prayer"
    private let historyKey = "session.completedDays"
    private let changedAtKey = "session.changedAt"
    private let historyResetKey = "session.historyResetAt"
    private let completedSetsKey = "session.completedSetsToday"
    private let completedSessionsKey = "session.completedPrayerSessions"
    private let completedDecadesKey = "session.completedDecades"
    private let prayerTimeKey = "session.prayerTimeByDay"

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

    /// Completed Rosary sessions with set and duration. This powers local Journey counters.
    /// Older app versions only stored `completedDayStarts`, so date-only history remains valid.
    private(set) var completedSessions: [CompletedPrayerSession] = []

    /// Completed decades that did not yet become a finished Rosary. Device-local for Journey partial prayer.
    private(set) var completedDecades: [CompletedDecadeSession] = []

    /// Active time spent inside the Rosary flow, keyed by yyyy-MM-dd. Local Journey ledger.
    private(set) var prayerTimeByDay: [String: TimeInterval] = [:]

    /// Mystery sets finished on `completedSetsDay` (yyyy-MM-dd). Device-only: synced progress
    /// records prayed days, not sets, and its Firestore rules allow no extra field.
    private(set) var completedSets: Set<MysterySetKind> = []
    private(set) var completedSetsDay: String = ""

    /// When the in-progress rosary was last started, advanced, finished or discarded.
    /// Used for last-write-wins between devices.
    private(set) var sessionChangedAt: Date {
        didSet { defaults.set(sessionChangedAt.timeIntervalSince1970, forKey: changedAtKey) }
    }

    /// Set by "Delete local data". Older history from another device is not merged back in.
    private(set) var historyResetAt: Date? {
        didSet {
            if let historyResetAt {
                defaults.set(historyResetAt.timeIntervalSince1970, forKey: historyResetKey)
            } else {
                defaults.removeObject(forKey: historyResetKey)
            }
        }
    }

    /// Called after the user changes progress or history (not when synced data is applied).
    /// The flag is false for bead-by-bead progress, which does not need an immediate upload.
    @ObservationIgnored var onUserChange: ((Bool) -> Void)?
    @ObservationIgnored private var isApplyingSynced = false

    var resumableSession: PrayerSession? {
        guard let session, session.isSameCalendarDay else { return nil }
        guard session.stepIndex > 0 || session.activeDuration > 0 || !session.completedDecades.isEmpty else { return nil }
        return session
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        milestoneOwner = defaults.string(forKey: milestoneOwnerKey)
        if let data = defaults.data(forKey: milestoneKey),
           let awards = try? JSONDecoder().decode([String: JourneyMilestones.Award].self, from: data) {
            earnedMilestones = awards
        }
        sessionChangedAt = Date(timeIntervalSince1970: defaults.double(forKey: changedAtKey))
        let reset = defaults.double(forKey: historyResetKey)
        historyResetAt = reset > 0 ? Date(timeIntervalSince1970: reset) : nil
        isApplyingSynced = true
        session = Self.load(key: key, defaults: defaults)
        if let session, !session.isSameCalendarDay {
            self.session = nil
        }
        isApplyingSynced = false
        completedDayStarts = Self.loadHistory(key: historyKey, defaults: defaults)
        completedSessions = Self.loadCompletedSessions(key: completedSessionsKey, defaults: defaults)
        completedDecades = Self.loadCompletedDecades(key: completedDecadesKey, defaults: defaults)
        prayerTimeByDay = Self.loadPrayerTime(key: prayerTimeKey, defaults: defaults)
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
            defaults.removeObject(forKey: completedSetsKey)
        } else {
            defaults.set(
                ["day": completedSetsDay, "sets": completedSets.map(\.rawValue).sorted()],
                forKey: completedSetsKey
            )
        }
    }

    func start(set: MysterySetKind, language: PrayerLanguage, intentionId: UUID? = nil, intentionTitle: String? = nil, intentionCategory: IntentionCategory? = nil, intentionSourceId: String? = nil) {
        let now = Date()
        session = PrayerSession(
            mysterySet: set,
            stepIndex: 0,
            startedAt: now,
            updatedAt: now,
            activeDuration: 0,
            includeSaintMichael: false,
            language: language,
            intentionId: intentionId,
            intentionTitle: intentionTitle,
            intentionCategory: intentionCategory,
            intentionSourceId: intentionSourceId
        )
    }

    func updateIntention(id: UUID?, title: String?, category: IntentionCategory? = nil, sourceId: String? = nil) {
        guard var current = session else { return }
        current.intentionId = id
        current.intentionTitle = title
        current.intentionCategory = category
        current.intentionSourceId = sourceId
        current.updatedAt = Date()
        session = current
    }

    func updateStep(_ index: Int) {
        guard var current = session else { return }
        current.stepIndex = index
        current.updatedAt = Date()
        session = current
    }

    func addActivePrayerTime(_ duration: TimeInterval) {
        let clamped = max(0, duration)
        guard clamped > 0, var current = session else { return }
        let now = Date()
        current.activeDuration += clamped
        current.updatedAt = now
        recordPrayerTime(clamped, at: now)
        session = current
    }

    func recordCompletedDecadeIfNeeded(_ decadeNumber: Int, completedAt: Date = Date()) {
        guard (1...5).contains(decadeNumber), var current = session else { return }
        guard !current.completedDecades.contains(decadeNumber) else { return }
        current.completedDecades.insert(decadeNumber)
        let duration = max(0, current.activeDuration - current.lastCompletedDecadeActiveDuration)
        current.lastCompletedDecadeActiveDuration = current.activeDuration
        current.updatedAt = completedAt
        let record = CompletedDecadeSession(
            id: UUID(),
            sessionId: current.id,
            mysterySet: current.mysterySet,
            decadeNumber: decadeNumber,
            completedAt: completedAt,
            duration: duration,
            intentionId: current.intentionId,
            intentionTitle: current.intentionTitle
        )
        completedDecades.append(record)
        completedDecades.sort { $0.completedAt > $1.completedAt }
        session = current
        pruneHistory()
        persistCompletedDecades()
    }

    func complete() {
        let completedAt = Date()
        let start = Calendar.current.startOfDay(for: completedAt).timeIntervalSince1970
        if let session {
            recordCompletedSet(session.mysterySet)
            removePartialDecades(for: session.id)
            recordCompletedSession(from: session, completedAt: completedAt)
        }
        completedDayStarts.insert(start)
        preserveMilestones()
        persistHistory()
        session = nil
        onUserChange?(true)
    }

    func prayed(on day: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: day).timeIntervalSince1970
        return completedDayStarts.contains(start)
    }

    private func pruneHistory() {
        preserveMilestones()
        let pruned = Self.pruned(completedDayStarts)
        if pruned.count != completedDayStarts.count {
            completedDayStarts = pruned
            persistHistory()
        }
        let cutoff = Self.historyCutoff()
        let prunedSessions = completedSessions.filter { $0.completedAt >= cutoff }
        if prunedSessions.count != completedSessions.count {
            completedSessions = prunedSessions
            persistCompletedSessions()
        }
        let prunedDecades = completedDecades.filter { $0.completedAt >= cutoff }
        if prunedDecades.count != completedDecades.count {
            completedDecades = prunedDecades
            persistCompletedDecades()
        }
        let cutoffKey = SyncedProgress.dayKey(for: cutoff)
        let prunedPrayerTime = prayerTimeByDay.filter { $0.key >= cutoffKey }
        if prunedPrayerTime.count != prayerTimeByDay.count {
            prayerTimeByDay = prunedPrayerTime
            persistPrayerTime()
        }
    }

    private static func historyCutoff() -> Date {
        let cal = Calendar.current
        guard let cutoffDate = cal.date(byAdding: .day, value: -historyWindowDays, to: Date()) else { return .distantPast }
        return cal.startOfDay(for: cutoffDate)
    }

    private static func pruned(_ days: Set<TimeInterval>) -> Set<TimeInterval> {
        let cutoff = historyCutoff().timeIntervalSince1970
        return days.filter { $0 >= cutoff }
    }

    private func persistHistory() {
        defaults.set(Array(completedDayStarts), forKey: historyKey)
    }

    private static func loadHistory(key: String, defaults: UserDefaults) -> Set<TimeInterval> {
        let values = defaults.array(forKey: key) as? [Double] ?? []
        return Set(values)
    }

    private func recordCompletedSession(from session: PrayerSession, completedAt: Date) {
        let duration = max(0, session.activeDuration)
        let record = CompletedPrayerSession(
            id: UUID(),
            sessionId: session.id,
            mysterySet: session.mysterySet,
            startedAt: session.startedAt,
            completedAt: completedAt,
            duration: duration,
            intentionId: session.intentionId,
            intentionTitle: session.intentionTitle,
            intentionCategory: session.intentionCategory,
            intentionSourceId: session.intentionSourceId
        )
        completedSessions.append(record)
        completedSessions.sort { $0.completedAt > $1.completedAt }
        pruneHistory()
        persistCompletedSessions()
    }

    private func persistCompletedSessions() {
        if completedSessions.isEmpty {
            defaults.removeObject(forKey: completedSessionsKey)
        } else if let data = try? JSONEncoder().encode(completedSessions) {
            defaults.set(data, forKey: completedSessionsKey)
        }
    }

    private func persistCompletedDecades() {
        if completedDecades.isEmpty {
            defaults.removeObject(forKey: completedDecadesKey)
        } else if let data = try? JSONEncoder().encode(completedDecades) {
            defaults.set(data, forKey: completedDecadesKey)
        }
    }

    private func recordPrayerTime(_ duration: TimeInterval, at date: Date) {
        let key = SyncedProgress.dayKey(for: date)
        prayerTimeByDay[key, default: 0] += max(0, duration)
        persistPrayerTime()
    }

    private func persistPrayerTime() {
        if prayerTimeByDay.isEmpty {
            defaults.removeObject(forKey: prayerTimeKey)
        } else {
            defaults.set(prayerTimeByDay, forKey: prayerTimeKey)
        }
    }

    private func removePartialDecades(for sessionId: UUID) {
        let before = completedDecades.count
        completedDecades.removeAll { $0.sessionId == sessionId }
        if completedDecades.count != before {
            persistCompletedDecades()
        }
    }

    private static func loadCompletedSessions(key: String, defaults: UserDefaults) -> [CompletedPrayerSession] {
        guard let data = defaults.data(forKey: key),
              let sessions = try? JSONDecoder().decode([CompletedPrayerSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.completedAt > $1.completedAt }
    }

    private static func loadCompletedDecades(key: String, defaults: UserDefaults) -> [CompletedDecadeSession] {
        guard let data = defaults.data(forKey: key),
              let decades = try? JSONDecoder().decode([CompletedDecadeSession].self, from: data) else {
            return []
        }
        return decades.sorted { $0.completedAt > $1.completedAt }
    }

    private static func loadPrayerTime(key: String, defaults: UserDefaults) -> [String: TimeInterval] {
        defaults.dictionary(forKey: key) as? [String: TimeInterval] ?? [:]
    }

    func discard() {
        session = nil
    }

    /// Clears the in-progress rosary and prayer history (Settings wipe). When signed in,
    /// the reset also reaches the account so other devices don't merge old days back.
    func clearHistoryAndData() {
        clearMilestones()
        completedDayStarts = []
        completedSessions = []
        completedDecades = []
        prayerTimeByDay = [:]
        persistHistory()
        persistCompletedSessions()
        persistCompletedDecades()
        persistPrayerTime()
        clearCompletedSets()
        historyResetAt = Date().syncRounded
        session = nil
        onUserChange?(true)
    }

    /// Completed milestones survive history pruning. The archive contains no intention titles.
    var journeyMilestones: JourneyMilestones {
        let calendar = Calendar.current
        let recordedDays = Set(completedSessions.map { calendar.startOfDay(for: $0.completedAt).timeIntervalSince1970 })
        let legacy = completedDayStarts.subtracting(recordedDays).map { Date(timeIntervalSince1970: $0) }
        let rosaryDates = completedSessions.map(\.completedAt) + legacy
        var mysteryDates: [String: Date] = [:]
        var offeringDates: [String: Date] = [:]
        for record in completedSessions {
            let key = record.mysterySet.rawValue
            mysteryDates[key] = min(mysteryDates[key] ?? record.completedAt, record.completedAt)
            if record.intentionSourceId?.hasPrefix("pope-") == true {
                offeringDates["papal"] = min(offeringDates["papal"] ?? record.completedAt, record.completedAt)
            }
            if let category = record.intentionCategory {
                offeringDates[category.rawValue] = min(offeringDates[category.rawValue] ?? record.completedAt, record.completedAt)
            }
        }
        return JourneyMilestones(rosaryDates: rosaryDates,
                                 prayerDates: rosaryDates + completedDecades.map(\.completedAt),
                                 mysteryDates: mysteryDates, offeringDates: offeringDates, awards: earnedMilestones)
    }

    private func preserveMilestones() {
        let calculated = journeyMilestones
        var updated = earnedMilestones
        for item in calculated.items {
            guard let date = item.earnedAt else { continue }
            if updated[item.id] == nil || date < updated[item.id]!.date {
                updated[item.id] = JourneyMilestones.Award(date: date, detail: item.description)
            }
        }
        guard updated != earnedMilestones else { return }
        earnedMilestones = updated
        persistMilestones()
    }

    private func persistMilestones() {
        guard let data = try? JSONEncoder().encode(earnedMilestones) else { return }
        defaults.set(data, forKey: milestoneKey)
        if let milestoneOwner { defaults.set(data, forKey: "\(milestoneKey).\(milestoneOwner)") }
    }

    private func clearMilestones() {
        earnedMilestones = [:]
        defaults.removeObject(forKey: milestoneKey)
        if let milestoneOwner { defaults.removeObject(forKey: "\(milestoneKey).\(milestoneOwner)") }
    }

    private struct LocalJourneyArchive: Codable {
        var sessions: [CompletedPrayerSession]
        var decades: [CompletedDecadeSession]
        var prayerTime: [String: TimeInterval]
        var resetAt: Date?
    }

    /// Switch before applying another account's prayer record. First sign-in adopts device awards.
    func activateMilestoneOwner(_ uid: String) {
        guard milestoneOwner != uid else { return }
        let previous = milestoneOwner
        persistMilestones()
        if let previous {
            let archive = LocalJourneyArchive(sessions: completedSessions, decades: completedDecades,
                                              prayerTime: prayerTimeByDay, resetAt: historyResetAt)
            if let data = try? JSONEncoder().encode(archive) {
                defaults.set(data, forKey: "session.localJourney.\(previous)")
            }
        }
        let archiveKey = "\(milestoneKey).\(uid)"
        if let data = defaults.data(forKey: archiveKey),
           let awards = try? JSONDecoder().decode([String: JourneyMilestones.Award].self, from: data) {
            earnedMilestones = awards
        } else if previous != nil {
            earnedMilestones = [:]
        }
        if let data = defaults.data(forKey: "session.localJourney.\(uid)"),
           let archive = try? JSONDecoder().decode(LocalJourneyArchive.self, from: data) {
            completedSessions = archive.sessions
            completedDecades = archive.decades
            prayerTimeByDay = archive.prayerTime
            historyResetAt = archive.resetAt
        } else if previous != nil {
            completedSessions = []
            completedDecades = []
            prayerTimeByDay = [:]
            historyResetAt = nil
        }
        milestoneOwner = uid
        defaults.set(uid, forKey: milestoneOwnerKey)
        persistMilestones()
        persistCompletedSessions()
        persistCompletedDecades()
        persistPrayerTime()
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
        if let reset = progress.historyResetAt, reset > (historyResetAt ?? .distantPast) {
            clearMilestones()
            completedSessions.removeAll { $0.completedAt <= reset }
            completedDecades.removeAll { $0.completedAt <= reset }
        }
        let days = Set(progress.completedDays.compactMap { SyncedProgress.date(forDayKey: $0)?.timeIntervalSince1970 })
        completedDayStarts = Self.pruned(days)
        completedSessions = completedSessions.filter { completedDayStarts.contains(Calendar.current.startOfDay(for: $0.completedAt).timeIntervalSince1970) }
        persistHistory()
        persistCompletedSessions()
        persistCompletedDecades()
        persistPrayerTime()
        // Another account's data, or history wiped elsewhere: today's sets no longer apply.
        if !progress.completedDays.contains(SyncedProgress.dayKey(for: Date())) {
            clearCompletedSets()
        }
        preserveMilestones()
        historyResetAt = progress.historyResetAt
        sessionChangedAt = progress.sessionChangedAt
        if var incoming = progress.session, incoming.isSameCalendarDay {
            // The deployed account schema has no intention-category field. Preserve the
            // local snapshot when the same in-progress session comes back from sync.
            if incoming.startedAt.syncRounded == session?.startedAt.syncRounded,
               incoming.mysterySet == session?.mysterySet,
               incoming.intentionId == session?.intentionId {
                incoming.id = session?.id ?? incoming.id
                incoming.intentionCategory = incoming.intentionCategory ?? session?.intentionCategory
                incoming.intentionSourceId = incoming.intentionSourceId ?? session?.intentionSourceId
            }
            session = incoming
        } else {
            session = nil
        }
    }

    /// Delete account: wipe everything, including sync timestamps.
    func clearForAccountDeletion() {
        if let milestoneOwner { defaults.removeObject(forKey: "session.localJourney.\(milestoneOwner)") }
        clearMilestones()
        milestoneOwner = nil
        defaults.removeObject(forKey: milestoneOwnerKey)
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        completedDayStarts = []
        completedSessions = []
        completedDecades = []
        prayerTimeByDay = [:]
        persistHistory()
        persistCompletedSessions()
        persistCompletedDecades()
        persistPrayerTime()
        clearCompletedSets()
        session = nil
        sessionChangedAt = .syncNever
        historyResetAt = nil
    }

    private func persist() {
        if let session, let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private static func load(key: String, defaults: UserDefaults) -> PrayerSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PrayerSession.self, from: data)
    }
}

/// Milestones calculated from the retained prayer record, independent of the visible month.
struct JourneyMilestones {
    enum Category: String, CaseIterable, Identifiable {
        case rosaries = "Rosaries"
        case feasts = "Marian feast days"
        case days = "Days in prayer"
        case mysteries = "Mystery sets"
        case offerings = "Prayer for others"
        var id: String { rawValue }
    }

    struct Award: Codable, Equatable {
        let date: Date
        let detail: String
    }

    struct Item: Identifiable {
        let id: String
        let category: Category
        let title: String
        let description: String
        let symbol: String
        let count: Int
        let target: Int
        let earnedAt: Date?
        var completed: Bool { earnedAt != nil }
        var progress: Double { min(1, Double(count) / Double(target)) }
        var progressText: String { "\(min(count, target)) of \(target)" }
    }

    let items: [Item]
    var earnedCount: Int { items.filter(\.completed).count }
    /// Introductory prayer first, then broader practice and date-specific observances.
    static let categoryOrder: [Category] = [.rosaries, .offerings, .mysteries, .days, .feasts]

    var orderedCategories: [Category] {
        Self.categoryOrder.filter { !isCategoryCompleted($0) }
            + Self.categoryOrder.filter { isCategoryCompleted($0) }
    }

    func isCategoryCompleted(_ category: Category) -> Bool {
        let categoryItems = items.filter { $0.category == category }
        return !categoryItems.isEmpty && categoryItems.allSatisfy(\.completed)
    }

    var preview: [Item] {
        let remaining = items.enumerated().filter { !$0.element.completed }
        func easier(_ lhs: (offset: Int, element: Item), _ rhs: (offset: Int, element: Item)) -> Bool {
            // Feast milestones need a calendar opportunity, rather than only another prayer.
            if (lhs.element.category == .feasts) != (rhs.element.category == .feasts) {
                return lhs.element.category != .feasts
            }
            let left = max(0, lhs.element.target - lhs.element.count)
            let right = max(0, rhs.element.target - rhs.element.count)
            if left != right { return left < right }
            let leftCategory = Self.categoryOrder.firstIndex(of: lhs.element.category)!
            let rightCategory = Self.categoryOrder.firstIndex(of: rhs.element.category)!
            if leftCategory != rightCategory { return leftCategory < rightCategory }
            return lhs.offset < rhs.offset
        }
        let stages: [Range<Double>] = [0..<1.0 / 3, 1.0 / 3..<2.0 / 3, 2.0 / 3..<1]
        let staged = stages.compactMap { stage in
            remaining.filter { $0.element.count > 0 && stage.contains($0.element.progress) }
                .sorted(by: easier).first?.element
        }
        if staged.count == 3 { return staged }
        return remaining.sorted(by: easier).prefix(3).map(\.element)
    }

    init(rosaryDates: [Date], prayerDates: [Date], mysteryDates: [String: Date], offeringDates: [String: Date] = [:], awards: [String: Award] = [:], calendar: Calendar = .current) {
        var result: [Item] = []
        func append(category: Category, dates: [Date], targets: [Int], unit: String, symbol: String, description: String) {
            let ordered = dates.sorted()
            for target in targets {
                let title = target == 1 ? "First \(unit)" : "\(target) \(unit == "Rosary" ? "Rosaries" : "decades")"
                result.append(Item(id: "\(category.id)-\(target)", category: category, title: title,
                                   description: description, symbol: symbol, count: ordered.count, target: target,
                                   earnedAt: ordered.count >= target ? ordered[target - 1] : nil))
            }
        }
        append(category: .rosaries, dates: rosaryDates, targets: [1, 10, 50, 100], unit: "Rosary", symbol: "circle.dotted", description: "Completed Rosaries recorded in your journey.")
        let days = Set(prayerDates.map { calendar.startOfDay(for: $0) }).sorted()
        for target in [7, 30, 54] {
            result.append(Item(id: "days-\(target)", category: .days, title: "\(target) days in prayer",
                               description: "Days with a Rosary or a separate decade. They do not need to be consecutive.",
                               symbol: "calendar", count: days.count, target: target,
                               earnedAt: days.count >= target ? days[target - 1] : nil))
        }
        // Resolve the app's dated feast calendar once per recorded year, including transfers.
        let years = Set(prayerDates.map { calendar.component(.year, from: $0) })
        var marianDayNames: [Date: String] = [:]
        var rosaryFeastDays: Set<Date> = []
        for year in years {
            for feast in FeastCatalog.dated(in: year, calendar: calendar) where feast.feast.isMarian {
                let day = calendar.startOfDay(for: feast.date)
                marianDayNames[day] = feast.feast.name.english
                if feast.feast.id == "rosary" { rosaryFeastDays.insert(day) }
            }
        }
        var firstPrayerByFeastDay: [Date: Date] = [:]
        for date in prayerDates {
            let day = calendar.startOfDay(for: date)
            guard marianDayNames[day] != nil else { continue }
            firstPrayerByFeastDay[day] = min(firstPrayerByFeastDay[day] ?? date, date)
        }
        let feastPrayers = firstPrayerByFeastDay.values.sorted()
        let firstFeastPrayer = feastPrayers.first
        let firstFeastName = firstFeastPrayer.flatMap { marianDayNames[calendar.startOfDay(for: $0)] }
        result.append(Item(id: "marian-feasts-1", category: .feasts, title: "Prayer on a Marian feast",
                           description: firstFeastName.map { "Reached on \($0)." } ?? "Pray a Rosary or a decade on a Marian feast day.",
                           symbol: "leaf", count: feastPrayers.count, target: 1, earnedAt: firstFeastPrayer))
        let feastRosary = rosaryDates.filter { rosaryFeastDays.contains(calendar.startOfDay(for: $0)) }.min()
        result.append(Item(id: "our-lady-of-the-rosary", category: .feasts, title: "Our Lady of the Rosary",
                           description: "Complete a Rosary on the feast of Our Lady of the Rosary.",
                           symbol: "leaf", count: feastRosary == nil ? 0 : 1, target: 1, earnedAt: feastRosary))
        let sets = ["joyful", "luminous", "sorrowful", "glorious"].compactMap { mysteryDates[$0] }
        result.append(Item(id: "all-mysteries", category: .mysteries, title: "All four mystery sets",
                           description: "Complete a Rosary with each of the Joyful, Luminous, Sorrowful and Glorious Mysteries.",
                           symbol: "sparkles", count: sets.count, target: 4,
                           earnedAt: sets.count == 4 ? sets.max() : nil))
        for (category, id, title, detail, symbol) in [
            ("someone", "rosary-for-another", "A Rosary for someone else", "Complete a Rosary offered for a Someone else intention.", "person.2"),
            ("world", "rosary-for-church", "A Rosary for the Church", "Complete a Rosary offered for a Church & world intention.", "building"),
            ("papal", "rosary-for-pope", "A Rosary for the Pope’s intention", "Complete a Rosary offered for the Holy Father’s monthly intention.", "cross")
        ] {
            let date = offeringDates[category]
            result.append(Item(id: id, category: .offerings, title: title, description: detail,
                               symbol: symbol, count: date == nil ? 0 : 1, target: 1, earnedAt: date))
        }
        items = result.map { item in
            // A saved 100-day award proves the new 54-day threshold was already reached.
            let savedAward = awards[item.id] ?? (item.id == "days-54" ? awards["days-100"] : nil)
            guard let award = savedAward, item.earnedAt == nil || award.date <= item.earnedAt! else { return item }
            return Item(id: item.id, category: item.category, title: item.title, description: award.detail,
                        symbol: item.symbol, count: max(item.count, item.target), target: item.target, earnedAt: award.date)
        }
    }
}
