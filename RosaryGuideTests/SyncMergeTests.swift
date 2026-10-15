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
