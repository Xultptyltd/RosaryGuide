import XCTest
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
