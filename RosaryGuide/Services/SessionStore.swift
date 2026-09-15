import Foundation
import Observation

@Observable
final class SessionStore {
    private let key = "session.prayer"

    var session: PrayerSession? {
        didSet { persist() }
    }

    var resumableSession: PrayerSession? {
        guard let session, session.isFresh, session.stepIndex > 0 else { return nil }
        return session
    }

    init() {
        session = Self.load(key: key)
        if let session, !session.isFresh {
            self.session = nil
        }
    }

    func start(set: MysterySetKind, includeSaintMichael: Bool, language: PrayerLanguage) {
        let now = Date()
        session = PrayerSession(
            mysterySet: set,
            stepIndex: 0,
            startedAt: now,
            updatedAt: now,
            includeSaintMichael: includeSaintMichael,
            language: language
        )
    }

    func updateStep(_ index: Int) {
        guard var current = session else { return }
        current.stepIndex = index
        current.updatedAt = Date()
        session = current
    }

    func complete() {
        session = nil
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
