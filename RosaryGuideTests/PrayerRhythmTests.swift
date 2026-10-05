import XCTest
@testable import RosaryGuide

/// Rule table for the prayer rhythm card's big number and caption.
/// "Today" is Wednesday 7 Oct 2026; weeks start Monday unless stated.
final class PrayerRhythmTests: XCTestCase {
    private func calendar(firstWeekday: Int = 2) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Australia/Perth")!
        cal.locale = Locale(identifier: "en_AU")
        cal.firstWeekday = firstWeekday
        return cal
    }

    private func rhythm(_ offsets: [Int], firstWeekday: Int = 2) -> PrayerRhythm {
        let cal = calendar(firstWeekday: firstWeekday)
        let now = cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!
        let today = cal.startOfDay(for: now)
        let days = Set(offsets.map { cal.date(byAdding: .day, value: $0, to: today)!.timeIntervalSince1970 })
        return PrayerRhythm(prayedDayStarts: days, now: now, calendar: cal)
    }

    private func assertCard(_ r: PrayerRhythm, _ big: String, _ caption: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(r.streakText, big, file: file, line: line)
        XCTAssertEqual(r.caption, caption, file: file, line: line)
    }

    func testNeverPrayed() {
        let r = rhythm([])
        assertCard(r, "0 days", "Start your rhythm this week")
        XCTAssertFalse(r.hasPrayed)
    }

    // MARK: Daily mode

    func testThreeInARow() {
        let r = rhythm([0, -1, -2])
        assertCard(r, "3 days", "Three days in a row")
        XCTAssertTrue(r.isMilestone)
    }
    func testNonMilestoneNotFlagged() {
        XCTAssertFalse(rhythm([0]).isMilestone)
        XCTAssertFalse(rhythm([0, -1, -2, -3]).isMilestone) // 4 days, "See you tomorrow"
    }
    func testFourInARowPrayedToday() { assertCard(rhythm([0, -1, -2, -3]), "4 days", "See you tomorrow") }
    func testFourInARowNotYetToday() { assertCard(rhythm([-1, -2, -3, -4]), "4 days", "Pray today to keep it") }
    func testMilestoneOnlyOnTheDayReached() { assertCard(rhythm([-1, -2, -3]), "3 days", "Pray today to keep it") }
    func testFive() { assertCard(rhythm(Array(-4...0)), "5 days", "Finding your rhythm") }
    func testSeven() { assertCard(rhythm(Array(-6...0)), "7 days", "Every day this week") }
    func testTen() { assertCard(rhythm(Array(-9...0)), "10 days", "Every day since 28 Sep") }
    func testFourteen() { assertCard(rhythm(Array(-13...0)), "14 days", "A fortnight of prayer") }
    func testThirty() { assertCard(rhythm(Array(-29...0)), "30 days", "Every day since September") }
    func testForty() { assertCard(rhythm(Array(-39...0)), "40 days", "Forty days, like Lent") }
    func testFiftyFour() { assertCard(rhythm(Array(-53...0)), "54 days", "A full novena") }
    func testSixty() { assertCard(rhythm(Array(-59...0)), "60 days", "Every day since August") }
    func testNinety() { assertCard(rhythm(Array(-89...0)), "90 days", "A whole season") }
    func testHundred() { assertCard(rhythm(Array(-99...0)), "100 days", "Every day since June") }

    // MARK: Week mode

    func testFirstDayEver() { assertCard(rhythm([0]), "1 day", "Once this week") }
    func testTwoDaysThisWeek() { assertCard(rhythm([0, -2]), "1 week", "Twice this week") }

    func testWelcomeBack() {
        let r = rhythm([0, -21])
        assertCard(r, "1 week", "Welcome back")
        XCTAssertTrue(r.isWelcomeBack)
    }

    func testTwoWeeksRunning() { assertCard(rhythm([0, -5]), "2 weeks", "Two weeks running") }

    func testFirstWeekdayDecidesTheWeek() {
        // Sunday 4 Oct + today: last week when weeks start Monday, same week when they start Sunday.
        assertCard(rhythm([0, -3], firstWeekday: 2), "2 weeks", "Two weeks running")
        assertCard(rhythm([0, -3], firstWeekday: 1), "1 week", "Twice this week")
    }

    /// Mondays only: 5 Oct, 28 Sep, 21 Sep, 14 Sep, 7 Sep.
    func testWeekRunPrayedThisWeek() { assertCard(rhythm([-2, -9, -16, -23, -30]), "5 weeks", "See you next week") }

    /// Mondays 28 Sep, 21 Sep, 14 Sep (nothing yet this week).
    func testWeekRunNotYetThisWeek() { assertCard(rhythm([-9, -16, -23]), "3 weeks", "Pray this week to keep it") }

    /// Mondays from 17 Aug through 5 Oct.
    func testEightWeeks() { assertCard(rhythm(stride(from: -2, through: -51, by: -7).map { $0 }), "8 weeks", "Every week since August") }

    func testLapsed() { assertCard(rhythm([-21]), "0 weeks", "Start your rhythm this week") }

    func testAccessibilityLabel() {
        // Mondays 5 Oct, 28 Sep, 21 Sep: weekRun 3; only 5 Oct is in October.
        let r = rhythm([-2, -9, -16])
        XCTAssertEqual(r.accessibilityLabel, "Prayer rhythm, 3 week streak, prayed 1 day in October. Becoming a habit.")
        XCTAssertEqual(rhythm([0, -1, -2]).accessibilityLabel, "Prayer rhythm, 3 day streak, prayed 3 days in October. Three days in a row.")
    }
}
