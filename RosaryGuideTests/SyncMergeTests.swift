import XCTest
import UIKit
import FirebaseFirestore
@testable import RosaryGuide

/// Merge and conflict rules for data that follows the account between devices.
final class IntentionMergeTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_790_000_000)

    private func intention(_ id: UUID, _ title: String, editedAt offset: TimeInterval?) -> OfferIntention {
        OfferIntention(id: id, title: title, createdAt: t0, updatedAt: offset.map { t0.addingTimeInterval($0) })
    }

    func testNewerDeviceEditWinsAndIsUploadedAgain() {
        let id = UUID()
        let mine = intention(id, "Mine", editedAt: 20)
        let theirs = intention(id, "Theirs", editedAt: 10)
        let result = IntentionMerge.merge(local: [mine], remote: [theirs], deleted: [:], previouslySynced: [id], isFromCache: false)
        XCTAssertEqual(result.intentions, [mine])
        XCTAssertEqual(result.toUpload, [mine])
    }

    func testOlderOfflineEditDoesNotOverwriteNewerAccountEdit() {
        let id = UUID()
        let mine = intention(id, "Old offline edit", editedAt: 10)
        let theirs = intention(id, "Newer edit", editedAt: 20)
        let result = IntentionMerge.merge(local: [mine], remote: [theirs], deleted: [:], previouslySynced: [id], isFromCache: false)
        XCTAssertEqual(result.intentions, [theirs])
        XCTAssertTrue(result.toUpload.isEmpty)
    }

    func testTieAndMissingEditTimeGoToTheAccount() {
        let id = UUID()
        let theirs = intention(id, "Theirs", editedAt: 10)
        for mine in [intention(id, "Mine", editedAt: 10), intention(id, "Legacy", editedAt: nil)] {
            let result = IntentionMerge.merge(local: [mine], remote: [theirs], deleted: [:], previouslySynced: [], isFromCache: false)
            XCTAssertEqual(result.intentions, [theirs])
            XCTAssertTrue(result.toUpload.isEmpty)
        }
    }

    func testCacheSnapshotKeepsNewerDeviceCopyWithoutUploading() {
        let id = UUID()
        let mine = intention(id, "Mine", editedAt: 20)
        let result = IntentionMerge.merge(local: [mine], remote: [intention(id, "Theirs", editedAt: 10)],
                                          deleted: [:], previouslySynced: [id], isFromCache: true)
        XCTAssertEqual(result.intentions, [mine])
        XCTAssertTrue(result.toUpload.isEmpty)
    }

    func testDeleteAfterLastEditStaysDeletedAndIsRepeated() {
        let id = UUID()
        let theirs = intention(id, "Theirs", editedAt: 10)
        let deleted = [id: t0.addingTimeInterval(15)]
        let result = IntentionMerge.merge(local: [], remote: [theirs], deleted: deleted, previouslySynced: [id], isFromCache: false)
        XCTAssertTrue(result.intentions.isEmpty)
        XCTAssertEqual(result.toDelete, [id])
        XCTAssertEqual(result.deleted, deleted, "Kept until the server confirms the delete")
    }

    func testEditAfterDeleteOnAnotherDeviceBringsItBack() {
        let id = UUID()
        let theirs = intention(id, "Edited later", editedAt: 30)
        let result = IntentionMerge.merge(local: [], remote: [theirs], deleted: [id: t0.addingTimeInterval(15)],
                                          previouslySynced: [id], isFromCache: false)
        XCTAssertEqual(result.intentions, [theirs])
        XCTAssertTrue(result.toDelete.isEmpty)
        XCTAssertTrue(result.deleted.isEmpty)
    }

    func testConfirmedDeleteClearsTheRecord() {
        let id = UUID()
        let result = IntentionMerge.merge(local: [], remote: [], deleted: [id: t0], previouslySynced: [id], isFromCache: false)
        XCTAssertTrue(result.deleted.isEmpty)
        let cached = IntentionMerge.merge(local: [], remote: [], deleted: [id: t0], previouslySynced: [id], isFromCache: true)
        XCTAssertEqual(cached.deleted, [id: t0], "A cache snapshot proves nothing")
    }

    func testLocalOnlyIntentionsUploadOrDropAsBefore() {
        let new = intention(UUID(), "New here", editedAt: 5)
        let goneElsewhere = intention(UUID(), "Deleted elsewhere", editedAt: 5)
        let result = IntentionMerge.merge(local: [new, goneElsewhere], remote: [], deleted: [:],
                                          previouslySynced: [goneElsewhere.id], isFromCache: false)
        XCTAssertEqual(result.intentions, [new])
        XCTAssertEqual(result.toUpload, [new])
        let offline = IntentionMerge.merge(local: [new, goneElsewhere], remote: [], deleted: [:],
                                           previouslySynced: [goneElsewhere.id], isFromCache: true)
        XCTAssertEqual(offline.intentions, [new, goneElsewhere])
        XCTAssertTrue(offline.toUpload.isEmpty)
    }

    func testStampingMarksOnlyAddedAndEditedIntentions() {
        let kept = intention(UUID(), "Kept", editedAt: 1)
        var edited = intention(UUID(), "Before", editedAt: 1)
        let previous = [kept, edited]
        edited.title = "After"
        let added = intention(UUID(), "Added", editedAt: nil)
        let now = t0.addingTimeInterval(100)
        let stamped = IntentionMerge.stampingEdits([kept, edited, added], previous: previous, now: now)
        XCTAssertEqual(stamped[0], kept)
        XCTAssertEqual(stamped[1].updatedAt, now)
        XCTAssertEqual(stamped[2].updatedAt, now)
    }
}

final class PreferencesMergeTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_790_000_000)
    private var now: Date { t0.addingTimeInterval(1_000) }

    private func prefs(updatedAt offset: TimeInterval, fields: [SyncedPreferences.Field: TimeInterval] = [:],
                       _ change: (inout SyncedPreferences) -> Void = { _ in }) -> SyncedPreferences {
        var value = SyncedPreferences.defaults
        value.updatedAt = t0.addingTimeInterval(offset)
        value.fieldUpdatedAt = Dictionary(uniqueKeysWithValues: fields.map { ($0.key.rawValue, t0.addingTimeInterval($0.value)) })
        if !fields.isEmpty {
            // Current devices hold a time for every field; untouched ones are old.
            for field in SyncedPreferences.Field.allCases where value.fieldUpdatedAt[field.rawValue] == nil {
                value.fieldUpdatedAt[field.rawValue] = t0
            }
        }
        change(&value)
        return value
    }

    func testDifferentFieldsChangedOnTwoDevicesBothSurvive() {
        let local = prefs(updatedAt: 20, fields: [.textSize: 20]) { $0.textSize = .large }
        let remote = prefs(updatedAt: 30, fields: [.dailyReminderEnabled: 30]) { $0.dailyReminderEnabled = true }
        let merged = SyncedPreferences.merge(local: local, remote: remote, now: now)
        XCTAssertEqual(merged.textSize, .large)
        XCTAssertTrue(merged.dailyReminderEnabled)
        XCTAssertEqual(merged.updatedAt, t0.addingTimeInterval(30))
        XCTAssertEqual(merged.changedAt(.textSize), t0.addingTimeInterval(20))
    }

    func testSameFieldNewerChangeWinsAndTiesGoToTheAccount() {
        let local = prefs(updatedAt: 40, fields: [.appearance: 40]) { $0.appearance = .dark }
        let remote = prefs(updatedAt: 30, fields: [.appearance: 30]) { $0.appearance = .light }
        XCTAssertEqual(SyncedPreferences.merge(local: local, remote: remote, now: now).appearance, .dark)
        let tie = prefs(updatedAt: 40, fields: [.appearance: 40]) { $0.appearance = .light }
        XCTAssertEqual(SyncedPreferences.merge(local: local, remote: tie, now: now).appearance, .light)
    }

    func testDocumentsWithoutFieldTimesMergeAsBefore() {
        let local = prefs(updatedAt: 10) { $0.textSize = .small; $0.appIcon = .white }
        let remote = prefs(updatedAt: 20) { $0.textSize = .large }
        let merged = SyncedPreferences.merge(local: local, remote: remote, now: now)
        XCTAssertEqual(merged.textSize, .large)
        XCTAssertEqual(merged.appIcon, .black, "The newer document wins every field it has no time for")
        XCTAssertEqual(merged.changedAt(.appIcon), t0.addingTimeInterval(20))
    }

    func testOlderOfflineChangeLosesToNewerOneForThatFieldOnly() {
        // Device A changed text size offline at 10; device B later changed it at 50 and the reminder at 50.
        let local = prefs(updatedAt: 60, fields: [.textSize: 10, .appearance: 60]) { $0.textSize = .small; $0.appearance = .dark }
        let remote = prefs(updatedAt: 50, fields: [.textSize: 50]) { $0.textSize = .large }
        let merged = SyncedPreferences.merge(local: local, remote: remote, now: now)
        XCTAssertEqual(merged.textSize, .large)
        XCTAssertEqual(merged.appearance, .dark)
    }

    func testClockAheadCannotWinForEver() {
        let local = prefs(updatedAt: 900, fields: [.textSize: 900]) { $0.textSize = .small }
        let remote = prefs(updatedAt: 99_999, fields: [.textSize: 99_999]) { $0.textSize = .large }
        // Both count as "now" or earlier; the local change at 900 is still older than now, so remote wins the tie-break only if not older.
        XCTAssertEqual(SyncedPreferences.merge(local: local, remote: remote, now: now).textSize, .large)
        let later = prefs(updatedAt: 1_000, fields: [.textSize: 1_000]) { $0.textSize = .small }
        XCTAssertEqual(SyncedPreferences.merge(local: later, remote: remote, now: now).textSize, .large, "Ties at now go to the account")
    }

    func testMissingRosaryConfigKeepsTheOtherSide() {
        var config = RosaryConfig.default
        config.memorare.toggle()
        let local = prefs(updatedAt: 10, fields: [.rosaryConfig: 10]) { $0.rosaryConfig = config }
        let remote = prefs(updatedAt: 50)
        XCTAssertEqual(SyncedPreferences.merge(local: local, remote: remote, now: now).rosaryConfig, config)
    }

    func testStoredShapeDropsWhatOldRulesReject() {
        let value = prefs(updatedAt: 20, fields: [.textSize: 10]) { $0.rosaryConfig = .default }
        XCTAssertFalse(value.stored(as: .full).fieldUpdatedAt.isEmpty)
        XCTAssertTrue(value.stored(as: .withoutFieldTimes).fieldUpdatedAt.isEmpty)
        XCTAssertNotNil(value.stored(as: .withoutFieldTimes).rosaryConfig)
        XCTAssertNil(value.stored(as: .withoutRosaryConfig).rosaryConfig)
    }

    func testOldDeviceCopyDecodesWithoutFieldTimes() throws {
        var old = try JSONSerialization.jsonObject(with: JSONEncoder().encode(prefs(updatedAt: 5))) as! [String: Any]
        old["fieldUpdatedAt"] = nil
        let decoded = try JSONDecoder().decode(SyncedPreferences.self, from: JSONSerialization.data(withJSONObject: old))
        XCTAssertTrue(decoded.fieldUpdatedAt.isEmpty)
        XCTAssertEqual(decoded.changedAt(.appIcon), t0.addingTimeInterval(5))
    }
}

final class RosaryHistoryMergeTests: XCTestCase {
    private let now = Date()

    private func rosary(_ id: UUID = UUID(), daysAgo: Double, title: String? = nil) -> CompletedPrayerSession {
        let completedAt = now.addingTimeInterval(-daysAgo * 86_400)
        return CompletedPrayerSession(id: id, sessionId: nil, mysterySet: .joyful,
                                      startedAt: completedAt.addingTimeInterval(-1_200), completedAt: completedAt,
                                      duration: 1_200, intentionId: nil, intentionTitle: title)
    }

    private func progress(_ rosaries: [CompletedPrayerSession]?, reset: Date? = nil) -> SyncedProgress {
        var value = SyncedProgress.empty
        value.rosaries = rosaries
        value.historyResetAt = reset
        value.completedDays = Set((rosaries ?? []).map { SessionStore.creditedDayKey(startedAt: $0.startedAt, completedAt: $0.completedAt) })
        return value
    }

    func testUnionByIdNeverCountsTwice() {
        let shared = rosary(daysAgo: 3)
        let mine = rosary(daysAgo: 2)
        let theirs = rosary(daysAgo: 1)
        let merged = SyncedProgress.merge(local: progress([shared, mine]), remote: progress([theirs, shared]))
        XCTAssertEqual(merged.rosaries?.count, 3)
        XCTAssertEqual(Set(merged.rosaries!.map(\.id)), [shared.id, mine.id, theirs.id])
        // Merging again changes nothing.
        XCTAssertEqual(SyncedProgress.merge(local: merged, remote: merged), merged)
    }

    func testFirstSyncUploadsExistingDeviceHistory() {
        let history = [rosary(daysAgo: 10), rosary(daysAgo: 5)]
        let accountFromOlderBuild = progress(nil)
        let merged = SyncedProgress.merge(local: progress(history), remote: accountFromOlderBuild)
        XCTAssertEqual(merged.rosaries?.count, 2)
        XCTAssertNotEqual(merged.stored(as: .full), accountFromOlderBuild.stored(as: .full), "Needs an upload")
    }

    func testMissingHistoryNeverRemovesAny() {
        let history = [rosary(daysAgo: 1)]
        XCTAssertEqual(SyncedProgress.merge(local: progress(nil), remote: progress(history)).rosaries?.count, 1)
        XCTAssertNil(SyncedProgress.merge(local: progress(nil), remote: progress(nil)).rosaries)
    }

    func testWipeRemovesOlderRosariesFromBothSides() {
        let old = rosary(daysAgo: 4)
        let after = rosary(daysAgo: 1)
        let reset = now.addingTimeInterval(-2 * 86_400)
        let merged = SyncedProgress.merge(local: progress([old]), remote: progress([after], reset: reset))
        XCTAssertEqual(merged.rosaries?.map(\.id), [after.id])
    }

    func testOutsideTheWindowIsDropped() {
        let ancient = rosary(daysAgo: Double(SessionStore.historyWindowDays + 5))
        XCTAssertEqual(progress([ancient]).normalized.rosaries?.count, 0)
    }

    func testOldRulesShapeIgnoresHistoryWhenComparing() {
        let local = progress([rosary(daysAgo: 1)])
        var remote = local
        remote.rosaries = nil
        XCTAssertEqual(local.stored(as: .withoutRosaries), remote.stored(as: .withoutRosaries))
    }

    func testDeviceCopyFromOlderBuildDecodes() throws {
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(progress([]))) as! [String: Any]
        json["rosaries"] = nil
        let decoded = try JSONDecoder().decode(SyncedProgress.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.rosaries)
    }

    func testSessionStoreAddsSyncedRosariesWithoutDuplicates() {
        let defaults = UserDefaults(suiteName: "RosaryHistoryMergeTests.\(UUID())")!
        let store = SessionStore(defaults: defaults)
        let a = rosary(daysAgo: 2)
        let b = rosary(daysAgo: 1)
        store.applySynced(progress([a]))
        store.applySynced(progress([a, b]))
        XCTAssertEqual(store.completedSessions.map(\.id), [b.id, a.id])
        store.applySynced(progress(nil).with(days: progress([a, b]).completedDays))
        XCTAssertEqual(store.completedSessions.count, 2, "A copy without history removes nothing")
    }
}

private extension SyncedProgress {
    func with(days: Set<String>) -> SyncedProgress {
        var copy = self
        copy.completedDays = days
        return copy
    }
}

/// Sign-in is optional: guests keep everything on the device, and an account only adds sync.
final class LaunchGateTests: XCTestCase {
    func testGuestsReachTheAppOnceOnboardingIsDone() {
        XCTAssertTrue(LaunchGate.showsApp(didCompleteOnboarding: true, isSignedIn: false))
        XCTAssertTrue(LaunchGate.showsApp(didCompleteOnboarding: true, isSignedIn: true))
        XCTAssertTrue(LaunchGate.showsApp(didCompleteOnboarding: false, isSignedIn: true), "Existing accounts skip onboarding")
        XCTAssertFalse(LaunchGate.showsApp(didCompleteOnboarding: false, isSignedIn: false))
    }
}

@MainActor
final class GuestIntentionTests: XCTestCase {
    private final class FakeListener: NSObject, ListenerRegistration {
        func remove() {}
    }

    /// Records uploads and lets a test deliver a server snapshot.
    private final class FakeRepository: IntentionRepository {
        var onChange: ((Result<IntentionSnapshot, Error>) -> Void)?
        var uploaded: [UUID] = []
        var deleted: [UUID] = []

        func listen(uid: String, onChange: @escaping (Result<IntentionSnapshot, Error>) -> Void) -> ListenerRegistration {
            self.onChange = onChange
            return FakeListener()
        }
        func upsert(_ intention: OfferIntention, uid: String) async throws { uploaded.append(intention.id) }
        func delete(id: UUID, uid: String) async throws { deleted.append(id) }
        func fetchAll(uid: String) async throws -> [OfferIntention] { [] }
        func deleteAll(uid: String) async throws {}
        func clearLocalCache() async throws {}

        func deliverServer(_ intentions: [OfferIntention]) {
            onChange?(.success(IntentionSnapshot(intentions: intentions, confirmedIDs: Set(intentions.map(\.id)), isFromCache: false)))
        }
    }

    private func settle() async throws {
        try await Task.sleep(nanoseconds: 80_000_000)
    }

    /// Waits (up to 3 s) for listener events and uploads, which hop through tasks.
    private func eventually(_ condition: () -> Bool) async throws {
        for _ in 0..<60 where !condition() {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "GuestIntentionTests.\(UUID())")!
    }

    func testGuestIntentionsStayOnDeviceWithoutSyncing() {
        let defaults = freshDefaults()
        let repository = FakeRepository()
        let store = OfferStore(defaults: defaults, repository: repository)
        store.configureSync(for: nil)
        let added = store.add(title: "For my family")
        XCTAssertTrue(repository.uploaded.isEmpty)
        XCTAssertNil(repository.onChange, "A guest never listens to Firestore")

        let relaunched = OfferStore(defaults: defaults, repository: FakeRepository())
        XCTAssertEqual(relaunched.intentions.map(\.id), [added.id])
    }

    func testSigningInMergesAndUploadsGuestIntentions() async throws {
        let defaults = freshDefaults()
        let repository = FakeRepository()
        let store = OfferStore(defaults: defaults, repository: repository)
        let mine = store.add(title: "Made as a guest")
        let cloud = OfferIntention(title: "Already in the account", createdAt: Date(), updatedAt: Date().syncRounded)

        store.configureSync(for: "user-a")
        repository.deliverServer([cloud])
        try await eventually { store.intentions.count == 2 && repository.uploaded.contains(mine.id) }

        XCTAssertEqual(Set(store.intentions.map(\.id)), [mine.id, cloud.id], "Nothing is lost on sign-in")
        XCTAssertTrue(repository.uploaded.contains(mine.id), "Guest intentions go up to the account")
    }

    func testSignOutKeepsIntentionsAndRemembersDeletions() async throws {
        let defaults = freshDefaults()
        let repository = FakeRepository()
        let store = OfferStore(defaults: defaults, repository: repository)
        store.configureSync(for: "user-a")
        let kept = store.add(title: "Kept")
        let removed = store.add(title: "Removed later")
        repository.deliverServer(store.intentions)
        try await eventually { repository.uploaded.count >= 2 }
        try await settle()

        store.configureSync(for: nil)
        XCTAssertEqual(Set(store.intentions.map(\.id)), [kept.id, removed.id], "Sign-out keeps the list")
        store.delete(id: removed.id)
        let added = store.add(title: "Added while signed out")
        repository.uploaded.removeAll()

        let relaunched = OfferStore(defaults: defaults, repository: repository)
        XCTAssertEqual(Set(relaunched.intentions.map(\.id)), [kept.id, added.id])

        relaunched.configureSync(for: "user-a")
        repository.deliverServer(store.intentions.filter { $0.id != added.id } + [
            OfferIntention(id: removed.id, title: "Removed later", createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 1))
        ])
        try await eventually { repository.uploaded.contains(added.id) && repository.deleted.contains(removed.id) }
        XCTAssertEqual(Set(relaunched.intentions.map(\.id)), [kept.id, added.id], "A delete made while signed out sticks")
        XCTAssertTrue(repository.uploaded.contains(added.id))
        XCTAssertTrue(repository.deleted.contains(removed.id))
    }

    func testAnotherAccountDoesNotSeeTheSignedOutList() {
        let defaults = freshDefaults()
        let store = OfferStore(defaults: defaults, repository: FakeRepository())
        store.configureSync(for: "user-a")
        store.add(title: "A's intention")
        store.configureSync(for: nil)
        store.configureSync(for: "user-b")
        XCTAssertTrue(store.intentions.isEmpty, "Accounts never mix")
        store.configureSync(for: "user-a")
        XCTAssertEqual(store.intentions.map(\.title), ["A's intention"])
    }
}

final class ReviewPromptGateTests: XCTestCase {
    private func gate(version: String) -> (ReviewPromptGate, UserDefaults) {
        let suite = "ReviewPromptGateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return (ReviewPromptGate(defaults: defaults, currentVersion: version), defaults)
    }

    func testNotBeforeTheThirdCompletedRosary() {
        let (gate, _) = gate(version: "1.0")
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 0))
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 1))
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 2))
        XCTAssertTrue(gate.shouldPrompt(completedRosaries: 3))
        XCTAssertTrue(gate.shouldPrompt(completedRosaries: 12))
    }

    func testAtMostOncePerAppVersion() {
        let (gate, defaults) = gate(version: "1.0")
        gate.markPrompted()
        XCTAssertEqual(defaults.string(forKey: ReviewPromptGate.lastPromptedVersionKey), "1.0")
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 3))
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 50))

        let nextVersion = ReviewPromptGate(defaults: defaults, currentVersion: "1.1")
        XCTAssertTrue(nextVersion.shouldPrompt(completedRosaries: 4), "A new version may ask again")
        nextVersion.markPrompted()
        XCTAssertFalse(nextVersion.shouldPrompt(completedRosaries: 5))
    }

    func testUnknownVersionNeverPrompts() {
        let (gate, _) = gate(version: "")
        XCTAssertFalse(gate.shouldPrompt(completedRosaries: 10))
    }

    func testAppStoreLinksUseTheAppleID() {
        XCTAssertEqual(AppStoreLinks.appID, "6814299309")
        XCTAssertEqual(AppStoreLinks.productPage?.absoluteString, "https://apps.apple.com/app/id6814299309")
        XCTAssertEqual(AppStoreLinks.writeReview?.absoluteString, "https://apps.apple.com/app/id6814299309?action=write-review")
    }
}

/// Dynamic Type: every role scales, capped roles stop at their cap, and the default size is unchanged.
final class DynamicTypeScalingTests: XCTestCase {
    private let base = UIFont.systemFont(ofSize: 16)

    func testDefaultSizeIsTheDesignSize() {
        let body = FontRegistrar.scale(base, textStyle: .body, maxPointSize: nil, category: .large)
        let capped = FontRegistrar.scale(base, textStyle: .callout, maxPointSize: AppTheme.TypeRole.Cap.pillLabel, category: .large)
        XCTAssertEqual(body.pointSize, 16, accuracy: 0.01)
        XCTAssertEqual(capped.pointSize, 16, accuracy: 0.01, "A cap never changes the default size")
    }

    func testReadingTextScalesWithoutLimit() {
        let ax5 = FontRegistrar.scale(base, textStyle: .body, maxPointSize: nil, category: .accessibilityExtraExtraExtraLarge)
        XCTAssertGreaterThan(ax5.pointSize, 40)
        let xl = FontRegistrar.scale(base, textStyle: .body, maxPointSize: nil, category: .extraLarge)
        XCTAssertGreaterThan(xl.pointSize, 16)
    }

    func testCappedRolesStopAtTheirCap() {
        let pill = FontRegistrar.scale(base, textStyle: .callout, maxPointSize: AppTheme.TypeRole.Cap.pillLabel, category: .accessibilityExtraExtraExtraLarge)
        XCTAssertEqual(pill.pointSize, AppTheme.TypeRole.Cap.pillLabel, accuracy: 0.01)
        let title = UIFont.systemFont(ofSize: 44)
        let h1 = FontRegistrar.scale(title, textStyle: .largeTitle, maxPointSize: (44 * AppTheme.TypeRole.Cap.displayScale).rounded(), category: .accessibilityExtraExtraExtraLarge)
        XCTAssertEqual(h1.pointSize, 57, accuracy: 0.01)
    }
}

/// VoiceOver strings for the bead flow.
final class SpokenProgressTests: XCTestCase {
    func testBeadDescriptions() {
        XCTAssertEqual(BeadLocus.decadeHail(1, 3).spokenDescription, "Hail Mary 3 of 10, first decade")
        XCTAssertEqual(BeadLocus.openingHail(2).spokenDescription, "Hail Mary 2 of 3, opening prayers")
        XCTAssertEqual(BeadLocus.decadeOurFather(5).spokenDescription, "Our Father, fifth decade")
        XCTAssertEqual(BeadLocus.decadeGlory(2).spokenDescription, "Glory Be, second decade")
        XCTAssertEqual(PrayTrackStage.third.spokenName, "Third decade")
        XCTAssertEqual(PrayTrackStage.closing.spokenName, "Closing prayers")
    }

    func testEveryStepHasASpokenHeading() {
        let steps = RosarySequenceBuilder.build(set: .joyful, config: RosaryConfig())
        XCTAssertFalse(steps.isEmpty)
        for step in steps {
            XCTAssertFalse(step.spokenProgress.isEmpty)
        }
        let third = steps.first { $0.kind == .hailMary && $0.decadeNumber == 1 && $0.hailMaryNumber == 3 }
        XCTAssertEqual(third?.spokenProgress, "Hail Mary 3 of 10, first decade")
        let plate = steps.first { $0.isPlate && $0.decadeNumber == 1 }
        XCTAssertEqual(plate?.spokenProgress, "First Joyful Mystery, The Annunciation")
        let opening = steps.first { $0.kind == .hailMary && $0.decadeNumber == nil && $0.hailMaryNumber == 1 }
        XCTAssertEqual(opening?.spokenProgress, "Hail Mary 1 of 3, opening prayers")
    }
}
