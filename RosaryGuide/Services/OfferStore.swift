import Foundation
import Observation

@Observable
final class OfferStore {
    private enum Keys {
        static let intentions = "offer.intentions"
    }

    private let defaults: UserDefaults

    var intentions: [OfferIntention] {
        didSet { persistIntentions() }
    }

    /// Active intentions only. Pinned first, then ones suggested for today's mystery, then recent.
    var sortedIntentions: [OfferIntention] {
        let todaySet = MysteryCalendar.assignment(on: Date()).set
        return intentions
            .filter { !$0.isExpired }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
                let aToday = a.isSuggested(on: todaySet)
                let bToday = b.isSuggested(on: todaySet)
                if aToday != bToday { return aToday && !bToday }
                let aDate = a.lastCarriedAt ?? a.createdAt
                let bDate = b.lastCarriedAt ?? b.createdAt
                if aDate != bDate { return aDate > bDate }
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        intentions = Self.loadIntentions(defaults: defaults)
        pruneExpired()
    }

    @discardableResult
    func add(
        title: String,
        note: String? = nil,
        pin: Bool = false,
        expiresAt: Date? = nil,
        sourceId: String? = nil,
        category: IntentionCategory = .personal,
        accent: IntentionAccent = .skyBlue,
        emoji: String? = nil,
        suggestOn: [MysterySetKind] = []
    ) -> OfferIntention {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmoji = (trimmedEmoji?.isEmpty == false) ? trimmedEmoji : "🙏"
        let intention = OfferIntention(
            title: trimmed.isEmpty ? "Untitled intention" : trimmed,
            note: (cleanNote?.isEmpty == false) ? cleanNote : nil,
            isPinned: pin,
            expiresAt: expiresAt,
            sourceId: sourceId,
            category: category,
            accent: accent,
            emoji: cleanEmoji,
            suggestOn: suggestOn
        )
        if pin {
            // Exclusive pin in one write: unpin everyone else, then append as current.
            var next = intentions
            for index in next.indices {
                next[index].isPinned = false
            }
            next.append(intention)
            intentions = next
        } else {
            // Leave existing current/pin untouched.
            intentions.append(intention)
        }
        return intention
    }

    /// Makes `id` the sole pinned/current intention. No-op if missing.
    func setCurrent(id: UUID) {
        guard intentions.contains(where: { $0.id == id }) else { return }
        var next = intentions
        for index in next.indices {
            next[index].isPinned = next[index].id == id
        }
        intentions = next
    }

    func update(_ intention: OfferIntention) {
        guard let idx = intentions.firstIndex(where: { $0.id == intention.id }) else { return }
        var next = intention
        next.title = next.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if next.title.isEmpty { next.title = "Untitled intention" }
        if let note = next.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            next.note = note
        } else {
            next.note = nil
        }
        if let emoji = next.emoji?.trimmingCharacters(in: .whitespacesAndNewlines), !emoji.isEmpty {
            next.emoji = emoji
        } else {
            next.emoji = "🙏"
        }
        intentions[idx] = next
    }

    func delete(id: UUID) {
        intentions.removeAll { $0.id == id }
    }

    /// Removes every saved intention (Settings wipe).
    func clearAll() {
        intentions = []
        defaults.removeObject(forKey: Keys.intentions)
    }

    func togglePin(id: UUID) {
        guard let idx = intentions.firstIndex(where: { $0.id == id }) else { return }
        intentions[idx].isPinned.toggle()
    }

    func recordCarry(id: UUID) {
        guard let idx = intentions.firstIndex(where: { $0.id == id }), !intentions[idx].isExpired else { return }
        intentions[idx].timesCarried += 1
        intentions[idx].lastCarriedAt = Date()
    }

    func intention(id: UUID) -> OfferIntention? {
        intentions.first { $0.id == id && !$0.isExpired }
    }


    /// Prefer intentions tagged for this mystery set (e.g. the Rosary just started).
    func sortedIntentions(for set: MysterySetKind) -> [OfferIntention] {
        intentions
            .filter { !$0.isExpired }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
                let aMatch = a.isSuggested(on: set)
                let bMatch = b.isSuggested(on: set)
                if aMatch != bMatch { return aMatch && !bMatch }
                let aDate = a.lastCarriedAt ?? a.createdAt
                let bDate = b.lastCarriedAt ?? b.createdAt
                if aDate != bDate { return aDate > bDate }
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
    }

    func quickPicks(limit: Int = 8) -> [OfferIntention] {
        Array(sortedIntentions.prefix(limit))
    }

    func pruneExpired() {
        intentions.removeAll { $0.isExpired }
    }

    private func persistIntentions() {
        if let data = try? JSONEncoder().encode(intentions) {
            defaults.set(data, forKey: Keys.intentions)
        }
    }

    private static func loadIntentions(defaults: UserDefaults) -> [OfferIntention] {
        guard let data = defaults.data(forKey: Keys.intentions) else { return [] }
        return (try? JSONDecoder().decode([OfferIntention].self, from: data)) ?? []
    }
}
