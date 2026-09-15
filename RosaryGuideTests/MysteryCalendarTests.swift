import XCTest
@testable import RosaryGuide

final class MysteryCalendarTests: XCTestCase {
    func testWeekdayAssignmentsInOrdinaryTime() {
        XCTAssertEqual(setOn(2026, 9, 14), .joyful)    // Monday
        XCTAssertEqual(setOn(2026, 9, 15), .sorrowful) // Tuesday
        XCTAssertEqual(setOn(2026, 9, 16), .glorious)  // Wednesday
        XCTAssertEqual(setOn(2026, 9, 17), .luminous)  // Thursday
        XCTAssertEqual(setOn(2026, 9, 18), .sorrowful) // Friday
        XCTAssertEqual(setOn(2026, 9, 19), .joyful)    // Saturday
        XCTAssertEqual(setOn(2026, 9, 20), .glorious)  // Sunday Ordinary Time
    }

    func testSeasonalSundays() {
        XCTAssertEqual(setOn(2026, 11, 29), .joyful)    // First Sunday of Advent
        XCTAssertEqual(setOn(2026, 12, 27), .joyful)    // Sunday in Christmas
        XCTAssertEqual(setOn(2026, 3, 1), .sorrowful)   // Sunday of Lent
        XCTAssertEqual(setOn(2026, 4, 12), .glorious)   // Sunday of Easter
    }

    func testMajorFeastOverrides() {
        XCTAssertEqual(setOn(2026, 4, 5), .glorious)    // Easter
        XCTAssertEqual(setOn(2026, 4, 3), .sorrowful)   // Good Friday
        XCTAssertEqual(setOn(2026, 12, 25), .joyful)    // Christmas
        XCTAssertEqual(setOn(2026, 8, 15), .glorious)   // Assumption
        XCTAssertEqual(setOn(2026, 10, 7), .glorious)   // Our Lady of the Rosary
    }

    func testCatalogHasTwentyMysteries() {
        XCTAssertEqual(MysteryCatalog.all.count, 20)
        for set in MysterySetKind.allCases {
            XCTAssertEqual(MysteryCatalog.mysteries(for: set).count, 5)
        }
    }

    private func setOn(_ y: Int, _ m: Int, _ d: Int) -> MysterySetKind {
        let date = LiturgicalCalendar.date(year: y, month: m, day: d)!
        return MysteryCalendar.assignment(on: date).set
    }
}

final class RosarySequenceTests: XCTestCase {
    func testStepCountsIncludeSaintMichael() {
        let withMichael = RosarySequenceBuilder.build(set: .joyful, includeSaintMichael: true)
        let without = RosarySequenceBuilder.build(set: .sorrowful, includeSaintMichael: false)
        XCTAssertEqual(withMichael.count, without.count + 1)
        XCTAssertTrue(withMichael.contains { $0.kind == .saintMichael })
        XCTAssertFalse(without.contains { $0.kind == .saintMichael })
        XCTAssertEqual(withMichael.filter { $0.kind == .hailMary }.count, 53)
        XCTAssertEqual(withMichael.filter { $0.kind == .mysteryAnnouncement }.count, 5)
        XCTAssertEqual(withMichael.last?.kind, .completion)
    }

    func testAllSetsBuild() {
        for set in MysterySetKind.allCases {
            let steps = RosarySequenceBuilder.build(set: set, includeSaintMichael: true)
            XCTAssertGreaterThan(steps.count, 70)
            XCTAssertEqual(steps.first?.kind, .signOfTheCross)
        }
    }

    func testPrayersHaveEnglishAndLatin() {
        XCTAssertFalse(PrayerCatalog.hailMary.text.english.isEmpty)
        XCTAssertFalse(PrayerCatalog.hailMary.text.latin.isEmpty)
        XCTAssertFalse(PrayerCatalog.saintMichael.text.latin.isEmpty)
    }
}
