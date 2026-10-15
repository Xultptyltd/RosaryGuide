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
        /// Intentions deleted on this device and when, so an older copy from another device
        /// or a late snapshot does not bring them back. Cleared once the server confirms the delete.
        static func deletedIDs(_ uid: String) -> String { "offer.deletedIDs." + uid }
    }

    private let defaults: UserDefaults
    private let repository: IntentionRepository
    private var listener: ListenerRegistration?
    private var userID: String?
    private var isApplyingRemoteSnapshot = false
    /// True while swapping accounts, so the list is not written to the wrong account's copy.
    private var isSwitchingAccount = false
    private(set) var syncErrorMessage: String?
    /// True while writing edit times back into `intentions` from its own observer.
    private var isStampingEdits = false
    /// The clock used for edit times. Tests replace it.
    @ObservationIgnored var now: () -> Date = { Date() }

    var intentions: [OfferIntention] {
        didSet {
            guard !isStampingEdits else { return }
            let previous = oldValue
            if !isApplyingRemoteSnapshot {
                let stamped = IntentionMerge.stampingEdits(intentions, previous: previous, now: now())
                if stamped != intentions {
                    isStampingEdits = true
                    intentions = stamped
                    isStampingEdits = false
                }
            }
            persistIntentions()
            syncLocalChangeIfNeeded(oldValue: previous)
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
            defaults.removeObject(forKey: Keys.deletedIDs(deletedUID))
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
        PapalIntention.isPapal(sourceId) || canAddIntention
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

    /// The account copy is deleted by `syncLocalChangeIfNeeded`, like every other removal.
    func delete(id: UUID) {
        intentions.removeAll { $0.id == id }
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

    private func deletedIDs(uid: String) -> [UUID: Date] {
        let raw = defaults.dictionary(forKey: Keys.deletedIDs(uid)) as? [String: Double] ?? [:]
        var result: [UUID: Date] = [:]
        for (key, value) in raw {
            if let id = UUID(uuidString: key) { result[id] = Date(timeIntervalSince1970: value) }
        }
        return result
    }

    private func setDeletedIDs(_ ids: [UUID: Date], uid: String) {
        if ids.isEmpty {
            defaults.removeObject(forKey: Keys.deletedIDs(uid))
        } else {
            let raw = Dictionary(uniqueKeysWithValues: ids.map { ($0.key.uuidString, $0.value.timeIntervalSince1970) })
            defaults.set(raw, forKey: Keys.deletedIDs(uid))
        }
    }

    /// Merges a listener event into the device copy (see `IntentionMerge.merge`).
    private func applySnapshot(_ snapshot: IntentionSnapshot, uid: String) {
        let result = IntentionMerge.merge(
            local: intentions,
            remote: snapshot.intentions,
            deleted: deletedIDs(uid: uid),
            previouslySynced: syncedIDs(uid: uid),
            isFromCache: snapshot.isFromCache
        )
        if !snapshot.isFromCache {
            setSyncedIDs(snapshot.confirmedIDs, uid: uid)
        }
        setDeletedIDs(result.deleted, uid: uid)

        isApplyingRemoteSnapshot = true
        intentions = result.intentions
        isApplyingRemoteSnapshot = false

        for intention in result.toUpload {
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
        for id in result.toDelete {
            Task {
                try? await repository.delete(id: id, uid: uid)
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
        if !removed.isEmpty {
            var deleted = deletedIDs(uid: userID)
            let deletedAt = now().syncRounded
            for id in removed { deleted[id] = deletedAt }
            setDeletedIDs(deleted, uid: userID)
        }

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

/// Pure merge rules for intentions, kept apart from Firestore so they can be tested.
enum IntentionMerge {
    struct Result: Equatable {
        var intentions: [OfferIntention]
        /// Device copies that are newer than the account's, or not in it yet.
        var toUpload: [OfferIntention]
        /// Account documents this device deleted after their last edit.
        var toDelete: [UUID]
        /// Deletions still waiting for the server to confirm them.
        var deleted: [UUID: Date]
    }

    /// Gives each added or edited intention a fresh edit time.
    static func stampingEdits(_ values: [OfferIntention], previous: [OfferIntention], now: Date) -> [OfferIntention] {
        let before = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let stamp = now.syncRounded
        return values.map { value in
            var comparable = value
            if let old = before[value.id] {
                comparable.updatedAt = old.updatedAt
                if comparable == old { return value }
            }
            var edited = value
            edited.updatedAt = stamp
            return edited
        }
    }

    /// Merges the account copy into the device copy by edit time.
    ///
    /// - For an id in both, the newer edit wins; ties and device copies without an edit time
    ///   go to the account. A newer device copy is uploaded again (server snapshots only).
    /// - An account document deleted here at or after its last edit stays deleted and is
    ///   deleted again. One edited elsewhere after the delete comes back.
    /// - A device intention missing from the account is kept and uploaded unless the server had
    ///   confirmed it before (then another device deleted it).
    /// - Cache-only events (offline, backend unreachable) never drop anything and upload nothing.
    static func merge(
        local: [OfferIntention],
        remote: [OfferIntention],
        deleted: [UUID: Date],
        previouslySynced: Set<UUID>,
        isFromCache: Bool
    ) -> Result {
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteIDs = Set(remote.map(\.id))
        var deleted = deleted
        var merged: [OfferIntention] = []
        var toUpload: [OfferIntention] = []
        var toDelete: [UUID] = []

        for item in remote {
            let remoteEdit = item.updatedAt ?? .distantPast
            if let deletedAt = deleted[item.id] {
                if remoteEdit <= deletedAt {
                    toDelete.append(item.id)
                    continue
                }
                deleted[item.id] = nil
            }
            if let mine = localByID[item.id], let localEdit = mine.updatedAt, localEdit > remoteEdit {
                merged.append(mine)
                if !isFromCache { toUpload.append(mine) }
            } else {
                merged.append(item)
            }
        }

        var localOnly = local.filter { !remoteIDs.contains($0.id) && deleted[$0.id] == nil }
        if !isFromCache {
            localOnly = localOnly.filter { !previouslySynced.contains($0.id) }
            toUpload += localOnly.filter { !$0.isExpired }
            // The server no longer has these, so the deletes are done.
            deleted = deleted.filter { remoteIDs.contains($0.key) }
        }
        return Result(intentions: merged + localOnly, toUpload: toUpload, toDelete: toDelete, deleted: deleted)
    }
}
