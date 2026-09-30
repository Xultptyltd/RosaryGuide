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

    func testEpiphanyIsSundayOnOrAfterJanuary2() {
        // US transferred Epiphany
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2026)), (1, 4))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2027)), (1, 3))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2028)), (1, 2))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2029)), (1, 7))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2030)), (1, 6))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2034)), (1, 8))
        XCTAssertEqual(monthDay(LiturgicalCalendar.epiphany(year: 2035)), (1, 7))
    }

    func testBaptismOfTheLordFollowsAppEpiphanyRule() {
        // Sunday after Epiphany; Monday when Epiphany falls on Jan 7 or 8.
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2026)), (1, 11))
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2027)), (1, 10))
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2028)), (1, 9))
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2029)), (1, 8))  // Mon after Epiphany Jan 7
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2030)), (1, 13))
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2034)), (1, 9))  // Mon after Epiphany Jan 8
        XCTAssertEqual(monthDay(LiturgicalCalendar.baptismOfTheLord(year: 2035)), (1, 8))  // Mon after Epiphany Jan 7

        for year in 2026...2036 {
            let epiphany = LiturgicalCalendar.epiphany(year: year)!
            let baptism = LiturgicalCalendar.baptismOfTheLord(year: year)!
            XCTAssertGreaterThanOrEqual(
                baptism,
                epiphany,
                "Baptism must not precede Epiphany in \(year)"
            )
        }
    }

    func testMotherOfTheChurchIsMondayAfterPentecost() {
        // Easter + 50.
        XCTAssertEqual(monthDay(motherOfTheChurch(year: 2026)), (5, 25))
        XCTAssertEqual(monthDay(motherOfTheChurch(year: 2027)), (5, 17))
        XCTAssertEqual(monthDay(motherOfTheChurch(year: 2028)), (6, 5))

        for year in 2026...2036 {
            let easter = LiturgicalCalendar.easter(year: year)!
            let mother = motherOfTheChurch(year: year)!
            let days = calendar.dateComponents([.day], from: easter, to: mother).day
            XCTAssertEqual(days, 50, "Mother of the Church should be Easter+50 in \(year)")
            XCTAssertEqual(calendar.component(.weekday, from: mother), 2, "Should be Monday in \(year)")
        }
    }

    private func motherOfTheChurch(year: Int) -> Date? {
        FeastCatalog.all.first(where: { $0.id == "mother-of-the-church" })?.dateProvider(year)
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
