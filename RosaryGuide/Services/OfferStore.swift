import Foundation
import FirebaseFirestore
import Observation

@Observable
@MainActor
final class OfferStore {
    private enum Keys {
        /// Pre-account copy from older builds. Adopted by the first account that signs in.
        static let legacyIntentions = "offer.intentions"
        /// Old one-shot migration marker; no longer used, removed on account deletion.
        static let migrationPrefix = "offer.firestoreMigrated."
        /// This device's copy of one account's intentions. Kept on sign-out so nothing is lost.
        static func intentions(_ uid: String) -> String { "offer.intentions." + uid }
        /// Intention ids the server has confirmed for an account. Lets a later server snapshot
        /// tell "deleted on another device" (was confirmed, now gone) from "never uploaded".
        static func syncedIDs(_ uid: String) -> String { "offer.syncedIDs." + uid }
    }

    private let defaults: UserDefaults
    private let repository: IntentionRepository
    private var listener: ListenerRegistration?
    private var userID: String?
    private var isApplyingRemoteSnapshot = false
    /// True while swapping accounts, so the list is not written to the wrong account's copy.
    private var isSwitchingAccount = false
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
        intentions = Self.loadIntentions(defaults: defaults, key: Keys.legacyIntentions)
        pruneExpired()
    }

    /// Switches to the signed-in account's intentions (or none when signed out).
    ///
    /// Sign-out keeps each account's copy on this device and keeps Firestore's offline cache,
    /// which still holds any writes that have not reached the server yet. Signing back in
    /// shows the device copy at once, then merges it with the cloud copy. Accounts never mix:
    /// each has its own device copy.
    func configureSync(for uid: String?) {
        if uid == userID && (listener != nil || uid == nil) { return }

        listener?.remove()
        listener = nil
        userID = uid

        guard let uid else {
            replaceWithoutSyncing([])
            syncErrorMessage = nil
            return
        }

        var local = Self.loadIntentions(defaults: defaults, key: Keys.intentions(uid))
        let legacy = Self.loadIntentions(defaults: defaults, key: Keys.legacyIntentions)
        if !legacy.isEmpty {
            // Intentions made before accounts existed belong to whoever signs in first.
            let known = Set(local.map(\.id))
            local += legacy.filter { !known.contains($0.id) }
        }
        defaults.removeObject(forKey: Keys.legacyIntentions)
        replaceWithoutSyncing(local.filter { !$0.isExpired })
        persistIntentions()
        syncErrorMessage = nil
        startListening(uid: uid)
    }

    func deleteCloudDataForCurrentUser() async throws {
        guard let userID else { return }
        listener?.remove()
        listener = nil
        try await repository.deleteAll(uid: userID)
        try await repository.clearLocalCache()
    }

    /// Called after the Auth account is deleted. Stops sync first so clearing the list
    /// does not try to delete documents for an account that no longer exists.
    func finishAccountDeletion(uid: String?) {
        let deletedUID = uid ?? userID
        listener?.remove()
        listener = nil
        userID = nil
        replaceWithoutSyncing([])
        defaults.removeObject(forKey: Keys.legacyIntentions)
        if let deletedUID {
            defaults.removeObject(forKey: Keys.intentions(deletedUID))
            defaults.removeObject(forKey: Keys.syncedIDs(deletedUID))
            defaults.removeObject(forKey: Keys.migrationPrefix + deletedUID)
        }
        syncErrorMessage = nil
        Task { [weak self] in
            try? await self?.repository.clearLocalCache()
        }
    }

    /// Account deletion stopped after cloud intentions were (possibly partly) deleted.
    /// Re-uploads the copy still on this device before listening again, so a failed
    /// deletion never loses intentions.
    func restoreCloudDataAfterFailedDeletion() {
        guard let userID else { return }
        listener?.remove()
        listener = nil
        let local = intentions
        // The cloud copy may be gone, so nothing counts as confirmed any more. The next server
        // snapshot then re-uploads every device intention instead of treating it as deleted.
        defaults.removeObject(forKey: Keys.syncedIDs(userID))
        Task { [weak self] in
            guard let self else { return }
            do {
                for intention in local {
                    try await self.repository.upsert(intention, uid: userID)
                }
                self.startListening(uid: userID)
            } catch {
                // The device copy stays; the next launch or sign-in uploads it again.
                self.syncErrorMessage = "Some intentions could not be restored to your account yet. They are still on this device."
            }
        }
    }

    func reconnectSync() {
        guard let userID else { return }
        listener?.remove()
        listener = nil
        Task { [weak self] in
            self?.startListening(uid: userID)
        }
    }

    /// Active intentions that count toward the free limit (papal ones don't).
    var limitedIntentionCount: Int {
        intentions.filter { !$0.isExpired && !$0.isPapal }.count
    }

    /// Whether a new non-papal intention can be added on the current tier.
    var canAddIntention: Bool {
        PremiumStatus.isPremium || limitedIntentionCount < PremiumStatus.freeIntentionLimit
    }

    /// Papal (`pope-…`) intentions are always allowed; anything else needs `canAddIntention`.
    func canAdd(sourceId: String?) -> Bool {
        sourceId?.hasPrefix("pope-") == true || canAddIntention
    }

    /// Returns nil (and adds nothing) when a free user is at the intention limit.
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
    ) -> OfferIntention? {
        guard canAdd(sourceId: sourceId) else { return nil }
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
        guard !isSwitchingAccount else { return }
        let key = userID.map(Keys.intentions) ?? Keys.legacyIntentions
        if let data = try? JSONEncoder().encode(intentions) {
            defaults.set(data, forKey: key)
        }
    }

    /// Replaces the in-memory list without writing it to any account's copy or the cloud.
    private func replaceWithoutSyncing(_ values: [OfferIntention]) {
        isSwitchingAccount = true
        isApplyingRemoteSnapshot = true
        intentions = values
        isApplyingRemoteSnapshot = false
        isSwitchingAccount = false
    }

    private static func loadIntentions(defaults: UserDefaults, key: String) -> [OfferIntention] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([OfferIntention].self, from: data)) ?? []
    }

    private func syncedIDs(uid: String) -> Set<UUID> {
        let raw = defaults.stringArray(forKey: Keys.syncedIDs(uid)) ?? []
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    private func setSyncedIDs(_ ids: Set<UUID>, uid: String) {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: Keys.syncedIDs(uid))
    }

    /// Merges a listener event into the device copy.
    ///
    /// - Cloud documents always win for ids they contain.
    /// - A device intention missing from the cloud is kept and uploaded unless the server had
    ///   confirmed it before (then it was deleted on another device and is dropped).
    /// - Cache-only events (offline, backend unreachable) never drop anything.
    private func applySnapshot(_ snapshot: IntentionSnapshot, uid: String) {
        let remoteIDs = Set(snapshot.intentions.map(\.id))
        let previouslySynced = syncedIDs(uid: uid)
        let localOnly = intentions.filter { !remoteIDs.contains($0.id) }

        let kept: [OfferIntention]
        var toUpload: [OfferIntention] = []
        if snapshot.isFromCache {
            kept = localOnly
        } else {
            kept = localOnly.filter { !previouslySynced.contains($0.id) }
            toUpload = kept.filter { !$0.isExpired }
            setSyncedIDs(snapshot.confirmedIDs, uid: uid)
        }

        isApplyingRemoteSnapshot = true
        intentions = snapshot.intentions + kept
        isApplyingRemoteSnapshot = false

        for intention in toUpload {
            Task {
                do {
                    try await repository.upsert(intention, uid: uid)
                } catch {
                    await MainActor.run {
                        self.syncErrorMessage = "Some intentions have not synced to your account yet. They are still on this device."
                    }
                }
            }
        }
    }

    @MainActor
    private func startListening(uid: String) {
        guard uid == userID else { return }
        listener = repository.listen(uid: uid) { [weak self] result in
            Task { @MainActor in
                guard let self, uid == self.userID else { return }
                switch result {
                case .success(let snapshot):
                    if !snapshot.isFromCache { self.syncErrorMessage = nil }
                    self.applySnapshot(snapshot, uid: uid)
                case .failure:
                    self.syncErrorMessage = "Intentions could not sync. Your local copy is still available."
                }
            }
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
