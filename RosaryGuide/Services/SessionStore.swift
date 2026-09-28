import Foundation
import Observation

@Observable
final class SessionStore {
    private let key = "session.prayer"
    private let historyKey = "session.completedDays"

    var session: PrayerSession? {
        didSet { persist() }
    }

    /// Day-start timestamps (timeIntervalSince1970) for rosaries finished this week.
    private(set) var completedDayStarts: Set<TimeInterval> = []

    var resumableSession: PrayerSession? {
        guard let session, session.isSameCalendarDay, session.stepIndex > 0 else { return nil }
        return session
    }

    init() {
        session = Self.load(key: key)
        if let session, !session.isSameCalendarDay {
            self.session = nil
        }
        completedDayStarts = Self.loadHistory(key: historyKey)
        pruneHistory()
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
        completedDayStarts.insert(start)
        persistHistory()
        session = nil
    }

    func prayed(on day: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: day).timeIntervalSince1970
        return completedDayStarts.contains(start)
    }

    private func pruneHistory() {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -8, to: Date()) else { return }
        let cutoff = cal.startOfDay(for: weekAgo).timeIntervalSince1970
        let pruned = completedDayStarts.filter { $0 >= cutoff }
        if pruned.count != completedDayStarts.count {
            completedDayStarts = pruned
            persistHistory()
        }
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
