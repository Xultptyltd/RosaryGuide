import XCTest
@testable import RosaryGuide

final class MysteryCalendarTests: XCTestCase {
    func testWeekdayAssignmentsInOrdinaryTime() {
        XCTAssertEqual(setOn(2026, 9, 14), .joyful)
        XCTAssertEqual(setOn(2026, 9, 15), .sorrowful)
        XCTAssertEqual(setOn(2026, 9, 16), .glorious)
        XCTAssertEqual(setOn(2026, 9, 17), .luminous)
        XCTAssertEqual(setOn(2026, 9, 18), .sorrowful)
        XCTAssertEqual(setOn(2026, 9, 19), .joyful)
        XCTAssertEqual(setOn(2026, 9, 20), .glorious)
    }

    func testSeasonalSundays() {
        XCTAssertEqual(setOn(2026, 11, 29), .joyful)
        XCTAssertEqual(setOn(2026, 12, 27), .joyful)
        XCTAssertEqual(setOn(2026, 3, 1), .sorrowful)
        XCTAssertEqual(setOn(2026, 4, 12), .glorious)
    }

    func testFeastsDoNotOverrideWeekdaySet() {
        XCTAssertEqual(setOn(2026, 12, 25), .sorrowful) // Friday Christmas
        XCTAssertEqual(setOn(2026, 8, 15), .joyful)     // Saturday Assumption
        let christmas = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 12, day: 25)!)
        XCTAssertEqual(christmas.feastSuggestion, .joyful)
        let assumption = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 8, day: 15)!)
        XCTAssertEqual(assumption.feastSuggestion, .glorious)
    }

    func testCatalogHasTwentyMysteriesWithArtSlugs() {
        XCTAssertEqual(MysteryCatalog.all.count, 20)
        for set in MysterySetKind.allCases {
            let items = MysteryCatalog.mysteries(for: set)
            XCTAssertEqual(items.count, 5)
            XCTAssertTrue(items.allSatisfy { !$0.artSlug.isEmpty })
        }
    }

    private func setOn(_ y: Int, _ m: Int, _ d: Int) -> MysterySetKind {
        let date = LiturgicalCalendar.date(year: y, month: m, day: d)!
        return MysteryCalendar.assignment(on: date).set
    }
}

final class RosarySequenceTests: XCTestCase {
    func testSevenStageSequenceOmitsSaintMichael() {
        let steps = RosarySequenceBuilder.build(set: .joyful)
        XCTAssertFalse(steps.contains { $0.kind == .saintMichael })
        XCTAssertEqual(steps.filter { $0.kind == .hailMary }.count, 53)
        XCTAssertEqual(steps.filter { $0.kind == .mysteryAnnouncement }.count, 5)
        XCTAssertEqual(steps.last?.kind, .completion)
        XCTAssertEqual(Set(steps.map(\.stage)).count, 7)
        XCTAssertEqual(MysteryCatalog.joyful.first?.scriptureReference, "Luke 1:26-27")
    }

    func testAllSetsBuild() {
        for set in MysterySetKind.allCases {
            let steps = RosarySequenceBuilder.build(set: set)
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
