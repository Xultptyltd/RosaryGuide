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

final class JourneyMilestoneTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Australia/Perth")!
        return value
    }
    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: 12))!
    }
    private func snapshot(_ rosaries: [Date] = [], _ decades: [Date] = [], _ sets: [String: Date] = [:]) -> JourneyMilestones {
        JourneyMilestones(rosaryDates: rosaries, prayerDates: rosaries + decades, mysteryDates: sets, calendar: calendar)
    }
    private func item(_ model: JourneyMilestones, _ id: String) -> JourneyMilestones.Item {
        model.items.first { $0.id == id }!
    }
    func testEmptyHistory() {
        let value = snapshot()
        XCTAssertEqual(value.earnedCount, 0)
        XCTAssertEqual(value.items.count, 13)
        XCTAssertEqual(value.preview.count, 3)
        XCTAssertTrue(value.items.allSatisfy { $0.progress == 0 && $0.earnedAt == nil })
    }
    func testSameDayPrayersAndDecadesCountSeparately() {
        let value = snapshot(Array(repeating: date(1), count: 10), [date(1)])
        XCTAssertTrue(item(value, "Rosaries-10").completed)
        XCTAssertFalse(value.items.contains { $0.id.hasPrefix("Separate decades") })
        XCTAssertEqual(item(value, "days-7").count, 1)
        XCTAssertTrue(value.preview.allSatisfy { !$0.completed })
    }
    func testEarnedDatesUseChronologicalThreshold() {
        let dates = (1...12).map(date)
        let value = snapshot(Array(dates.reversed()))
        XCTAssertEqual(item(value, "Rosaries-10").earnedAt, dates[9])
        XCTAssertEqual(item(value, "days-7").earnedAt, calendar.startOfDay(for: dates[6]))
    }
    func testNonconsecutiveDecadesCountAsPrayerDays() {
        let value = snapshot([], [1, 3, 6, 10, 15, 20, 28].map(date))
        XCTAssertTrue(item(value, "days-7").completed)
        XCTAssertFalse(item(value, "Rosaries-1").completed)
    }
    func testMarianFeastAcceptsDecadesAndCountsEachDayOnce() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!
        let value = snapshot([day, day], [day])
        XCTAssertEqual(item(value, "marian-feasts-1").earnedAt, day)
        XCTAssertEqual(item(value, "marian-feasts-1").count, 1)
        XCTAssertTrue(item(value, "marian-feasts-1").description.contains("Rosary"))
        XCTAssertTrue(item(snapshot([], [day]), "marian-feasts-1").completed)
        XCTAssertFalse(item(snapshot([], [date(3)]), "marian-feasts-1").completed)
    }
    func testOurLadyOfTheRosaryRequiresAFullRosary() {
        let feast = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!
        XCTAssertFalse(item(snapshot([], [feast]), "our-lady-of-the-rosary").completed)
        XCTAssertEqual(item(snapshot([feast]), "our-lady-of-the-rosary").earnedAt, feast)
        XCTAssertFalse(item(snapshot([date(1)]), "our-lady-of-the-rosary").completed)
    }
    func testOfferingMilestonesRequireKnownIntentionType() {
        let model = JourneyMilestones(rosaryDates: [date(1)], prayerDates: [date(1)], mysteryDates: [:],
                                      offeringDates: ["someone": date(1), "world": date(2)], calendar: calendar)
        XCTAssertEqual(item(model, "rosary-for-another").earnedAt, date(1))
        XCTAssertEqual(item(model, "rosary-for-church").earnedAt, date(2))
        XCTAssertFalse(item(snapshot([date(1)]), "rosary-for-another").completed)
        XCTAssertFalse(item(snapshot([date(1)]), "rosary-for-church").completed)
        XCTAssertFalse(model.items.contains { $0.id == "Rosaries-25" || $0.id == "marian-feasts-3" })
    }
    func testSavedAwardsSurviveMissingHistoryAndKeepOriginalDate() {
        let award = JourneyMilestones.Award(date: date(1), detail: "Reached on Our Lady of the Rosary.")
        let model = JourneyMilestones(rosaryDates: [], prayerDates: [], mysteryDates: [:],
                                      awards: ["marian-feasts-1": award, "Rosaries-10": .init(date: date(2), detail: "Completed Rosaries")], calendar: calendar)
        XCTAssertEqual(item(model, "marian-feasts-1").earnedAt, date(1))
        XCTAssertEqual(item(model, "marian-feasts-1").description, award.detail)
        XCTAssertEqual(item(model, "Rosaries-10").progress, 1)
    }
    func testPreviewExcludesCompletedAndOffersEasiestRemaining() {
        let value = JourneyMilestones(rosaryDates: [date(1)], prayerDates: [date(1)], mysteryDates: [:],
                                      offeringDates: ["someone": date(2)], calendar: calendar)
        XCTAssertEqual(value.preview.count, 3)
        XCTAssertTrue(value.preview.allSatisfy { !$0.completed })
        XCTAssertEqual(value.preview.map(\.id), ["rosary-for-church", "rosary-for-pope", "all-mysteries"])
    }
    func testPreviewUsesThreeProgressStagesWhenAvailable() {
        let value = snapshot(Array(repeating: date(1), count: 5), [date(1)],
                             ["joyful": date(1), "luminous": date(1), "sorrowful": date(1)])
        XCTAssertEqual(value.preview.map(\.id), ["days-7", "Rosaries-10", "all-mysteries"])
        XCTAssertTrue(value.preview.allSatisfy { !$0.completed })
    }
    func testAllCompletedHasNoPreviewAndCategoryOrderIsStable() {
        let base = snapshot()
        let awards = Dictionary(uniqueKeysWithValues: base.items.map {
            ($0.id, JourneyMilestones.Award(date: date(1), detail: "Completed"))
        })
        let value = JourneyMilestones(rosaryDates: [], prayerDates: [], mysteryDates: [:], awards: awards, calendar: calendar)
        XCTAssertTrue(value.preview.isEmpty)
        XCTAssertEqual(value.orderedCategories, JourneyMilestones.categoryOrder)
    }
    func testCompletedCategoriesMoveAfterUnfinishedCategories() {
        let value = JourneyMilestones(rosaryDates: [], prayerDates: [], mysteryDates: [:],
                                      offeringDates: ["someone": date(1), "world": date(1), "papal": date(1)], calendar: calendar)
        XCTAssertEqual(value.orderedCategories, [.rosaries, .mysteries, .days, .feasts, .offerings])
        XCTAssertTrue(value.isCategoryCompleted(.offerings))
    }
    func testFiftyFourPrayerDaysThreshold() {
        let dates = (0..<54).map { calendar.date(byAdding: .day, value: $0 * 2, to: date(1))! }
        let value = snapshot([], dates)
        XCTAssertTrue(item(value, "days-54").completed)
        XCTAssertEqual(item(value, "days-54").earnedAt, calendar.startOfDay(for: dates.last!))
        XCTAssertFalse(item(snapshot([], Array(dates.prefix(53))), "days-54").completed)
        XCTAssertFalse(value.items.contains { $0.id == "days-100" })
        XCTAssertTrue(value.items.contains { $0.id == "Rosaries-100" })
    }
    func testExistingHundredDayAwardCarriesToFiftyFour() {
        let award = JourneyMilestones.Award(date: date(1), detail: "Days with a Rosary or a separate decade.")
        let value = JourneyMilestones(rosaryDates: [], prayerDates: [], mysteryDates: [:], awards: ["days-100": award], calendar: calendar)
        XCTAssertEqual(item(value, "days-54").earnedAt, award.date)
        XCTAssertEqual(item(value, "days-54").progress, 1)
    }
    func testOnlyKnownMysterySetsUnlockCoverage() {
        var sets = ["joyful": date(1), "luminous": date(2), "sorrowful": date(3), "unknown": date(4)]
        XCTAssertFalse(item(snapshot([], [], sets), "all-mysteries").completed)
        sets["glorious"] = date(5)
        XCTAssertEqual(item(snapshot([], [], sets), "all-mysteries").earnedAt, date(5))
    }
}


final class MilestonePersistenceTests: XCTestCase {
    private func isolated(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "RosaryGuide.MilestoneTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }
    func testMigrationSavesAwardsBeforeHistoryExpires() throws {
        try isolated { defaults in
            let old = Date().addingTimeInterval(-500 * 24 * 60 * 60)
            let records = (0..<10).map { index in
                CompletedPrayerSession(id: UUID(), mysterySet: .joyful, startedAt: old,
                                       completedAt: old.addingTimeInterval(Double(index)), duration: 60,
                                       intentionId: nil, intentionTitle: nil, intentionCategory: .world)
            }
            defaults.set(try JSONEncoder().encode(records), forKey: "session.completedPrayerSessions")
            let store = SessionStore(defaults: defaults)
            XCTAssertTrue(store.completedSessions.isEmpty)
            XCTAssertNotNil(store.earnedMilestones["Rosaries-10"])
            XCTAssertNotNil(store.earnedMilestones["rosary-for-church"])
            let relaunched = SessionStore(defaults: defaults)
            XCTAssertEqual(relaunched.earnedMilestones, store.earnedMilestones)
            XCTAssertEqual(relaunched.journeyMilestones.items.first { $0.id == "Rosaries-10" }?.progress, 1)
        }
    }
    func testOfferingSnapshotAndLocalDeletion() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Someone", intentionCategory: .someone)
            store.complete()
            XCTAssertEqual(store.completedSessions.first?.intentionCategory, .someone)
            XCTAssertNotNil(store.earnedMilestones["rosary-for-another"])
            XCTAssertNil(store.earnedMilestones["rosary-for-church"])
            store.clearHistoryAndData()
            XCTAssertTrue(SessionStore(defaults: defaults).earnedMilestones.isEmpty)
        }
    }
    func testAccountSwitchKeepsAwardsAndRecordsSeparate() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.activateMilestoneOwner("A")
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Church", intentionCategory: .world)
            store.complete()
            let progressA = store.syncedProgress
            store.activateMilestoneOwner("B")
            store.applySynced(.empty)
            XCTAssertTrue(store.earnedMilestones.isEmpty)
            XCTAssertTrue(store.completedSessions.isEmpty)
            store.start(set: .luminous, language: .english, intentionId: UUID(), intentionTitle: "Someone", intentionCategory: .someone)
            store.complete()
            XCTAssertNotNil(store.earnedMilestones["rosary-for-another"])
            store.activateMilestoneOwner("A")
            store.applySynced(progressA)
            XCTAssertNotNil(store.earnedMilestones["rosary-for-church"])
            XCTAssertNil(store.earnedMilestones["rosary-for-another"])
            XCTAssertEqual(store.completedSessions.first?.intentionCategory, .world)
            store.clearForAccountDeletion()
            store.activateMilestoneOwner("A")
            store.applySynced(.empty)
            XCTAssertTrue(store.earnedMilestones.isEmpty)
        }
    }
    func testRemoteDeletionClearsSavedAwards() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: nil, intentionTitle: nil)
            store.complete()
            XCTAssertFalse(store.earnedMilestones.isEmpty)
            var wiped = SyncedProgress.empty
            wiped.historyResetAt = Date().addingTimeInterval(1)
            store.applySynced(wiped)
            XCTAssertTrue(store.earnedMilestones.isEmpty)
            XCTAssertTrue(SessionStore(defaults: defaults).earnedMilestones.isEmpty)
        }
    }
    func testLegacyCompletionDecodesWithoutGuessingIntentionType() throws {
        let record = CompletedPrayerSession(id: UUID(), mysterySet: .joyful, startedAt: Date(), completedAt: Date(), duration: 60, intentionId: UUID(), intentionTitle: "Legacy")
        let data = try JSONEncoder().encode(record)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "intentionCategory")
        json.removeValue(forKey: "intentionSourceId")
        let decoded = try JSONDecoder().decode(CompletedPrayerSession.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.intentionCategory)
        XCTAssertNil(decoded.intentionSourceId)
    }
    func testPapalCompletionUsesSourceSnapshotAndSurvivesRelaunch() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Pope", intentionCategory: .world, intentionSourceId: "pope-2026-10")
            store.recordCompletedDecadeIfNeeded(1)
            XCTAssertNil(store.earnedMilestones["rosary-for-pope"])
            store.complete()
            XCTAssertNotNil(store.earnedMilestones["rosary-for-pope"])
            XCTAssertNotNil(store.earnedMilestones["rosary-for-church"])
            XCTAssertEqual(store.completedSessions.first?.intentionSourceId, "pope-2026-10")
            XCTAssertNotNil(SessionStore(defaults: defaults).earnedMilestones["rosary-for-pope"])
        }
    }
    func testGenericChurchIntentionDoesNotUnlockPapalMilestone() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Church", intentionCategory: .world)
            store.complete()
            XCTAssertNil(store.earnedMilestones["rosary-for-pope"])
        }
    }
    func testChangingFromPapalToPersonalClearsSourceSnapshot() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Pope", intentionCategory: .world, intentionSourceId: "pope-2026-10")
            store.updateIntention(id: UUID(), title: "Personal", category: .personal)
            store.complete()
            XCTAssertNil(store.earnedMilestones["rosary-for-pope"])
            XCTAssertNil(store.completedSessions.first?.intentionSourceId)
        }
    }
    func testCategorySnapshotSurvivesSameSessionFromSync() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            store.start(set: .joyful, language: .english, intentionId: UUID(), intentionTitle: "Church", intentionCategory: .world, intentionSourceId: "pope-2026-10")
            let id = store.session!.id
            var remote = store.syncedProgress
            remote.session?.id = UUID() // Cloud decoder does not preserve the local UUID.
            remote.session?.intentionCategory = nil
            remote.session?.intentionSourceId = nil
            store.applySynced(remote)
            XCTAssertEqual(store.session?.id, id)
            XCTAssertEqual(store.session?.intentionCategory, .world)
            XCTAssertEqual(store.session?.intentionSourceId, "pope-2026-10")
        }
    }
}
