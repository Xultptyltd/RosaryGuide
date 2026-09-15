import XCTest
@testable import RosaryGuide

final class LiturgicalCalendarTests: XCTestCase {
    private let calendar = LiturgicalCalendar.gregorian

    func testEasterDates() {
        XCTAssertEqual(monthDay(LiturgicalCalendar.easter(year: 2024)), (3, 31))
        XCTAssertEqual(monthDay(LiturgicalCalendar.easter(year: 2025)), (4, 20))
        XCTAssertEqual(monthDay(LiturgicalCalendar.easter(year: 2026)), (4, 5))
        XCTAssertEqual(monthDay(LiturgicalCalendar.easter(year: 2027)), (3, 28))
        XCTAssertEqual(monthDay(LiturgicalCalendar.easter(year: 2028)), (4, 16))
    }

    func testAshWednesdayIsFortySixDaysBeforeEaster() {
        let easter = LiturgicalCalendar.easter(year: 2026)!
        let ash = LiturgicalCalendar.ashWednesday(year: 2026)!
        let days = calendar.dateComponents([.day], from: ash, to: easter).day
        XCTAssertEqual(days, 46)
        XCTAssertEqual(monthDay(ash), (2, 18))
    }

    func testAdvent2026StartsNovember29() {
        XCTAssertEqual(monthDay(LiturgicalCalendar.firstSundayOfAdvent(year: 2026)), (11, 29))
    }

    func testSeasonAroundEaster2026() {
        XCTAssertEqual(season(2026, 2, 17), .ordinary)
        XCTAssertEqual(season(2026, 2, 18), .lent)
        XCTAssertEqual(season(2026, 4, 2), .triduum)
        XCTAssertEqual(season(2026, 4, 5), .easter)
        XCTAssertEqual(season(2026, 5, 24), .easter)
        XCTAssertEqual(season(2026, 5, 25), .ordinary)
        XCTAssertEqual(season(2026, 12, 1), .advent)
        XCTAssertEqual(season(2026, 12, 25), .christmas)
        XCTAssertEqual(season(2027, 1, 6), .christmas)
    }

    private func season(_ y: Int, _ m: Int, _ d: Int) -> LiturgicalSeason {
        LiturgicalCalendar.season(on: LiturgicalCalendar.date(year: y, month: m, day: d)!, calendar: calendar)
    }

    private func monthDay(_ date: Date?) -> (Int, Int) {
        guard let date else { return (0, 0) }
        return (
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }
}
