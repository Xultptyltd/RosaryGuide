import Foundation
import FirebaseFirestore
import Observation

@Observable
@MainActor
final class OfferStore {
    private enum Keys {
        static let intentions = "offer.intentions"
        static let migrationPrefix = "offer.firestoreMigrated."
    }

    private let defaults: UserDefaults
    private let repository: IntentionRepository
    private var listener: ListenerRegistration?
    private var userID: String?
    private var isApplyingRemoteSnapshot = false
    private(set) var syncErrorMessage: String?

    var intentions: [OfferIntention] {
        didSet {
            persistIntentions()
            syncLocalChangeIfNeeded(oldValue: oldValue)
        }
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

    init(defaults: UserDefaults = .standard, repository: IntentionRepository = IntentionRepositoryFactory.make()) {
        self.defaults = defaults
        self.repository = repository
        intentions = Self.loadIntentions(defaults: defaults)
        pruneExpired()
    }

    func configureSync(for uid: String?) {
        if uid == userID && listener != nil { return }

        listener?.remove()
        listener = nil
        userID = uid

        guard let uid else {
            intentions = []
            defaults.removeObject(forKey: Keys.intentions)
            Task { [weak self] in
                do {
                    try await self?.repository.clearLocalCache()
                } catch {
                    await MainActor.run {
                        self?.syncErrorMessage = "Private local cache could not be cleared."
                    }
                }
            }
            return
        }

        let localBeforeSync = intentions
        Task { [weak self] in
            await self?.migrateIfNeeded(localIntentions: localBeforeSync, uid: uid)
            self?.startListening(uid: uid)
        }
    }

    func deleteCloudDataForCurrentUser() async throws {
        guard let userID else { return }
        listener?.remove()
        listener = nil
        try await repository.deleteAll(uid: userID)
        try await repository.clearLocalCache()
    }

    func reconnectSync() {
        guard let userID else { return }
        listener?.remove()
        listener = nil
        Task { [weak self] in
            self?.startListening(uid: userID)
        }
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
        guard let userID else { return }
        Task {
            do {
                try await repository.delete(id: id, uid: userID)
            } catch {
                await MainActor.run {
                    self.syncErrorMessage = "This intention could not be deleted from your account."
                }
            }
        }
    }

    /// Removes every saved intention (Settings wipe).
    func clearAll() {
        intentions = []
        defaults.removeObject(forKey: Keys.intentions)
    }

    /// Pin as the sole current intention, or unpin if already pinned.
    /// Pinning is exclusive (same as `setCurrent`); unpin clears only this row.
    func togglePin(id: UUID) {
        guard let idx = intentions.firstIndex(where: { $0.id == id }) else { return }
        var next = intentions
        if next[idx].isPinned {
            next[idx].isPinned = false
        } else {
            for i in next.indices {
                next[i].isPinned = next[i].id == id
            }
        }
        intentions = next
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

    @MainActor
    private func startListening(uid: String) {
        guard uid == userID else { return }
        listener = repository.listen(uid: uid) { [weak self] result in
            Task { @MainActor in
                guard let self, uid == self.userID else { return }
                switch result {
                case .success(let remoteIntentions):
                    self.syncErrorMessage = nil
                    self.isApplyingRemoteSnapshot = true
                    self.intentions = remoteIntentions
                    self.isApplyingRemoteSnapshot = false
                case .failure:
                    self.syncErrorMessage = "Intentions could not sync. Your local copy is still available."
                }
            }
        }
    }

    private func migrateIfNeeded(localIntentions: [OfferIntention], uid: String) async {
        let migrationKey = Keys.migrationPrefix + uid
        if defaults.bool(forKey: migrationKey) { return }

        do {
            let remote = try await repository.fetchAll(uid: uid)
            let remoteIds = Set(remote.map(\.id))
            for intention in localIntentions where !remoteIds.contains(intention.id) {
                try await repository.upsert(intention, uid: uid)
            }
            defaults.set(true, forKey: migrationKey)
        } catch {
            await MainActor.run {
                self.syncErrorMessage = "Existing intentions could not finish syncing yet."
            }
            // Leave the migration marker unset so the next authenticated launch retries safely.
        }
    }

    private func syncLocalChangeIfNeeded(oldValue: [OfferIntention]) {
        guard !isApplyingRemoteSnapshot, let userID else { return }

        let previous = Dictionary(uniqueKeysWithValues: oldValue.map { ($0.id, $0) })
        let current = Dictionary(uniqueKeysWithValues: intentions.map { ($0.id, $0) })
        let removed = Set(previous.keys).subtracting(current.keys)

        for intention in intentions where previous[intention.id] != intention {
            Task {
                do {
                    try await repository.upsert(intention, uid: userID)
                } catch {
                    await MainActor.run {
                        self.syncErrorMessage = "This intention could not sync to your account."
                    }
                }
            }
        }

        for id in removed {
            Task {
                do {
                    try await repository.delete(id: id, uid: userID)
                } catch {
                    await MainActor.run {
                        self.syncErrorMessage = "An intention could not be deleted from your account."
                    }
                }
            }
        }
    }
}
