import XCTest
@testable import RosaryGuide

private func XCTAssertEqual(
    _ expression1: @autoclosure () throws -> (Int, Int),
    _ expression2: @autoclosure () throws -> (Int, Int),
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let lhs = try expression1()
        let rhs = try expression2()
        XCTAssertEqual(lhs.0, rhs.0, message(), file: file, line: line)
        XCTAssertEqual(lhs.1, rhs.1, message(), file: file, line: line)
    } catch {
        XCTFail("Thrown error: \(error)", file: file, line: line)
    }
}

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


final class FeastAgendaTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 2
        return value
    }
    private func day(_ month: Int, _ day: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
    private func feast(_ date: Date, index: Int = 0) -> DatedFeast {
        DatedFeast(feast: FeastCatalog.all[index], date: date)
    }
    func testAgendaPartitionsDatesWithoutRepeatingFocus() {
        let anchor = day(10, 9)
        let dates = [anchor, day(10, 10), day(10, 15), day(11, 1), day(12, 1), day(1, 31, year: 2027), day(12, 31, year: 2027)]
        let input = dates.map { feast($0) } + [feast(day(1, 1, year: 2028))]
        let value = FeastAgenda(items: input, selectedDay: anchor, today: anchor, calendar: calendar)
        XCTAssertEqual(value.sections.map(\.title), ["Today", "This week", "This month", "Next month", "Later this year", "Next year"])
        let all = value.sections.flatMap(\.items)
        XCTAssertEqual(all.map(\.date), dates)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
    }
    func testEmptyDayShowsAllFeastsOnNextDateOnlyOnce() {
        let anchor = day(10, 9)
        let next = day(10, 10)
        let value = FeastAgenda(items: [feast(next), feast(next, index: 1), feast(day(10, 15))],
                               selectedDay: anchor, today: anchor, calendar: calendar)
        XCTAssertEqual(value.sections.map(\.title), ["Next", "This month"])
        XCTAssertEqual(value.sections[0].items.count, 2)
        XCTAssertEqual(value.sections.flatMap(\.items).count, 3)
    }
    func testEmptyAgendaAndPastDates() {
        let anchor = day(10, 9)
        XCTAssertTrue(FeastAgenda(items: [], selectedDay: anchor, calendar: calendar).sections.isEmpty)
        XCTAssertTrue(FeastAgenda(items: [feast(day(10, 8))], selectedDay: anchor, calendar: calendar).sections.isEmpty)
    }
    func testSelectedFutureDayUsesItsDateAndYearBoundary() {
        let anchor = day(12, 31)
        let value = FeastAgenda(items: [feast(anchor), feast(day(1, 1, year: 2027)), feast(day(3, 31, year: 2027)),
                                      feast(day(4, 1, year: 2027))],
                               selectedDay: anchor, today: day(10, 9), calendar: calendar)
        XCTAssertEqual(value.sections.first?.title, "")
        XCTAssertEqual(value.sections.map(\.title), ["", "Next month", "Next year"])
        XCTAssertEqual(value.sections.flatMap(\.items).count, 4)
    }
}


extension FeastAgendaTests {
    func testDecemberNextMonthDoesNotRepeatInNextYear() {
        let anchor = day(12, 10)
        let value = FeastAgenda(items: [feast(day(12, 11)), feast(day(1, 15, year: 2027)), feast(day(2, 1, year: 2027))],
                               selectedDay: anchor, today: anchor, calendar: calendar)
        XCTAssertEqual(value.sections.map(\.title), ["Next", "Next month", "Next year"])
        XCTAssertEqual(value.sections[1].items.map(\.date), [day(1, 15, year: 2027)])
        XCTAssertEqual(value.sections[2].items.map(\.date), [day(2, 1, year: 2027)])
    }
}

final class FeastMonthLayoutTests: XCTestCase {
    func testMonthAlignmentAndLeapDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for (year, month, count, leading, rows) in [(2024, 2, 29, 3, 5), (2021, 2, 28, 0, 4), (2026, 8, 31, 5, 6)] {
            let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let layout = FeastMonthLayout(month: date, calendar: calendar)
            XCTAssertEqual(layout.cells.compactMap { $0 }.count, count)
            XCTAssertEqual(layout.cells.prefix(while: { $0 == nil }).count, leading)
            XCTAssertEqual(layout.rows, rows)
            XCTAssertEqual(calendar.component(.day, from: layout.cells.compactMap { $0 }.last!), count)
        }
        calendar.firstWeekday = 1
        let october = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        XCTAssertEqual(FeastMonthLayout(month: october, calendar: calendar).cells.prefix(while: { $0 == nil }).count, 4)
    }
}

extension FeastAgendaTests {
    func testNoRemainingFeastsThisMonthKeepsNextFeastInNextMonth() {
        let anchor = day(10, 31)
        let dates = [day(11, 1), day(11, 2), day(12, 8)]
        let value = FeastAgenda(items: dates.map { feast($0) }, selectedDay: anchor,
                               today: anchor, calendar: calendar)
        XCTAssertEqual(value.sections.map(\.title), ["Next month", "Later this year"])
        XCTAssertEqual(value.sections[0].items.map(\.date), Array(dates.prefix(2)))
        XCTAssertEqual(value.sections.flatMap(\.items).map(\.date), dates)
    }
    func testNoRemainingDecemberFeastsUsesNextMonthForJanuary() {
        let anchor = day(12, 31)
        let value = FeastAgenda(items: [feast(day(1, 1, year: 2027))], selectedDay: anchor,
                               today: anchor, calendar: calendar)
        XCTAssertEqual(value.sections.map(\.title), ["Next month"])
    }
}
