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
        XCTAssertEqual(r.accessibilityLabel, "Your prayer, 3 weeks. Becoming a habit. Prayed 1 day in October.")
        XCTAssertEqual(rhythm([0, -1, -2]).accessibilityLabel, "Your prayer, 3 days. Three days in a row. Prayed 3 days in October.")
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

    // MARK: - Multiple intentions

    func testLegacySingleIntentionSessionMigratesToArrays() throws {
        let id = UUID()
        let legacy = PrayerSession(mysterySet: .joyful, stepIndex: 3, startedAt: Date(), updatedAt: Date(),
                                   includeSaintMichael: false, language: .english,
                                   intentionId: id, intentionTitle: "Family")
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        json.removeValue(forKey: "intentionIds")
        json.removeValue(forKey: "intentionTitles")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(PrayerSession.self, from: data)
        XCTAssertEqual(decoded.intentionIds, [id])
        XCTAssertEqual(decoded.intentionTitles, ["Family"])
    }

    func testMultipleIntentionsRoundTripAndKeepLegacyKeys() throws {
        let ids = [UUID(), UUID(), UUID()]
        let session = PrayerSession(mysterySet: .sorrowful, stepIndex: 1, startedAt: Date(), updatedAt: Date(),
                                    includeSaintMichael: false, language: .english,
                                    intentionId: nil, intentionTitle: nil,
                                    intentionIds: ids, intentionTitles: ["A", "B", "C"])
        let data = try JSONEncoder().encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["intentionId"] as? String, ids[0].uuidString)
        XCTAssertEqual(json["intentionTitle"] as? String, "A")
        let decoded = try JSONDecoder().decode(PrayerSession.self, from: data)
        XCTAssertEqual(decoded.intentionIds, ids)
        XCTAssertEqual(decoded.intentionTitles, ["A", "B", "C"])
    }

    func testIntentionsAreCappedAtFive() {
        let session = PrayerSession(mysterySet: .glorious, stepIndex: 0, startedAt: Date(), updatedAt: Date(),
                                    includeSaintMichael: false, language: .english,
                                    intentionId: nil, intentionTitle: nil,
                                    intentionIds: (0..<6).map { _ in UUID() }, intentionTitles: nil)
        XCTAssertEqual(session.intentionIds.count, 5)
    }

    func testCompletedRosaryKeepsAllIntentionsAndOldRecordsFallBack() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            let ids = [UUID(), UUID()]
            store.start(set: .joyful, language: .english, intentionIds: ids, intentionTitles: ["Mum", "Peace"])
            store.complete()
            XCTAssertEqual(store.completedSessions.first?.intentionIds, ids)
            XCTAssertEqual(store.completedSessions.first?.allIntentionTitles, ["Mum", "Peace"])
        }
        let old = CompletedPrayerSession(id: UUID(), mysterySet: .joyful, startedAt: Date(), completedAt: Date(),
                                         duration: 60, intentionId: UUID(), intentionTitle: "Church")
        XCTAssertEqual(old.allIntentionTitles, ["Church"])
    }

    func testSyncedIntentionsAndSettingsApplyToSameRosary() {
        isolated { defaults in
            let store = SessionStore(defaults: defaults)
            let ids = [UUID(), UUID(), UUID()]
            store.start(set: .joyful, language: .english, intentionIds: ids, intentionTitles: ["A", "B", "C"],
                        intentionCategory: .someone, intentionSourceId: "source")
            let localId = store.session?.id
            var config = RosaryConfig()
            config.memorare = true
            var remote = store.syncedProgress
            remote.session?.id = UUID()
            remote.session?.intentionIds = [ids[0], ids[2]] // edited on another device
            remote.session?.intentionTitles = ["A", "C"]
            remote.session?.rosaryConfig = config
            remote.session?.intentionCategory = nil // not in the account schema
            remote.session?.intentionSourceId = nil
            store.applySynced(remote)
            XCTAssertEqual(store.session?.intentionIds, [ids[0], ids[2]])
            XCTAssertEqual(store.session?.intentionTitles, ["A", "C"])
            XCTAssertEqual(store.session?.rosaryConfig, config)
            XCTAssertEqual(store.session?.id, localId)
            XCTAssertEqual(store.session?.intentionCategory, .someone)
            XCTAssertEqual(store.session?.intentionSourceId, "source")
        }
    }

    func testOfferedIntentionsSummary() {
        XCTAssertNil(OfferedIntentions.summary([]))
        XCTAssertEqual(OfferedIntentions.summary(["A"]), "A")
        XCTAssertEqual(OfferedIntentions.summary(["A", "B"]), "A and B")
        XCTAssertEqual(OfferedIntentions.summary(["A", "B", "C"]), "A, B and C")
    }

    // MARK: - Rosary count caption

    func testRosaryCaptionSpellsCountAtSentenceStart() {
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(1), "One Rosary offered this week")
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(2), "Two Rosaries offered this week")
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(7), "Seven Rosaries offered this week")
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(0), "Zero Rosaries offered this week")
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(20), "Twenty Rosaries offered this week")
        XCTAssertEqual(CountWords.rosariesOfferedThisWeek(21), "21 Rosaries offered this week")
    }
}

/// Prayed days are calendar day keys, so they survive time-zone changes and midnight.
final class PrayedDayKeyTests: XCTestCase {
    private func calendar(_ zone: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    func testLegacyDayStartsMigrateToTheirCalendarDay() {
        let perth = calendar("Australia/Perth")
        let midnight = perth.date(from: DateComponents(year: 2026, month: 10, day: 14))!
        // Read back in Perth, Tokyo or London (within 12 hours): always 14 October.
        for zone in ["Australia/Perth", "Asia/Tokyo", "Europe/London"] {
            let keys = SessionStore.migratedDayKeys(fromLegacyDayStarts: [midnight.timeIntervalSince1970], calendar: calendar(zone))
            XCTAssertEqual(keys, ["2026-10-14"], zone)
        }
    }

    func testDayKeyMapsToLocalMidnightAfterTimeZoneChange() {
        let london = calendar("Europe/London")
        let start = SyncedProgress.date(forDayKey: "2026-10-14", calendar: london)!
        XCTAssertEqual(SyncedProgress.dayKey(for: start, calendar: london), "2026-10-14")
        let rhythm = PrayerRhythm(
            prayedDayStarts: [start.timeIntervalSince1970],
            now: london.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 9))!,
            calendar: london
        )
        XCTAssertTrue(rhythm.prayedToday)
    }

    func testStoreMigratesLegacyHistoryOnce() {
        let suite = "PrayedDayKeyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let today = Calendar.current.startOfDay(for: Date())
        defaults.set([today.timeIntervalSince1970], forKey: "session.completedDays")
        let store = SessionStore(defaults: defaults)
        XCTAssertTrue(store.prayed(on: Date()))
        XCTAssertNil(defaults.array(forKey: "session.completedDays"))
        XCTAssertEqual(defaults.stringArray(forKey: "session.completedDayKeys"), [SyncedProgress.dayKey(for: today)])
    }

    func testFinishedSetFollowsTheCreditedDayAcrossMidnight() {
        let suite = "PrayedDayKeyTests.sets.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let calendar = Calendar.current
        let started = calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 23, minute: 50))!
        let finished = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 0, minute: 10))!
        let store = SessionStore(defaults: defaults)
        store.start(set: .joyful, language: .english, at: started)
        store.complete(at: finished)

        XCTAssertTrue(store.prayed(on: started))
        XCTAssertFalse(store.prayed(on: finished))
        XCTAssertTrue(store.completedToday(.joyful, now: started))
        XCTAssertFalse(store.completedToday(.joyful, now: finished), "The new morning is not already prayed")

        store.applySynced(store.syncedProgress)
        XCTAssertTrue(store.completedToday(.joyful, now: started), "The account echo must not clear the credited day")
    }

    func testRosaryAcrossMidnightCreditsTheDayItStarted() {
        let perth = calendar("Australia/Perth")
        let started = perth.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 23, minute: 50))!
        let finished = perth.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 0, minute: 20))!
        XCTAssertEqual(SessionStore.creditedDayKey(startedAt: started, completedAt: finished, calendar: perth), "2026-10-14")
        XCTAssertEqual(SessionStore.creditedDayKey(startedAt: nil, completedAt: finished, calendar: perth), "2026-10-15")
    }

    func testRosaryStaysResumableJustAfterMidnight() {
        let perth = calendar("Australia/Perth")
        let started = perth.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 23, minute: 50))!
        let lastBead = perth.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 23, minute: 58))!
        let session = PrayerSession(
            mysterySet: .joyful, stepIndex: 20, startedAt: started, updatedAt: lastBead,
            includeSaintMichael: false, language: .english, intentionId: nil, intentionTitle: nil
        )
        let afterMidnight = perth.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 0, minute: 30))!
        XCTAssertTrue(session.isResumable(now: afterMidnight, calendar: perth))
        let nextMorning = perth.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 9))!
        XCTAssertFalse(session.isResumable(now: nextMorning, calendar: perth))
        let twoDaysLater = perth.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 0, minute: 10))!
        XCTAssertFalse(session.isResumable(now: twoDaysLater, calendar: perth))
    }

    @MainActor
    func testDayClockRollsOverAtMidnight() {
        let cal = Calendar.current
        let evening = cal.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 23, minute: 59))!
        let clock = DayClock(now: evening)
        XCTAssertEqual(clock.today, cal.startOfDay(for: evening))
        clock.refresh(now: evening.addingTimeInterval(30))
        XCTAssertEqual(clock.today, cal.startOfDay(for: evening))
        let monday = evening.addingTimeInterval(120)
        clock.refresh(now: monday)
        XCTAssertEqual(clock.today, cal.startOfDay(for: monday))
        XCTAssertEqual(MysteryCalendar.assignment(on: clock.today).set, .joyful)
    }
}

/// Latin and Both never show English in the Latin slot.
final class LatinTextTests: XCTestCase {
    func testMissingLatinFallsBackOnce() {
        let text = BilingualText(english: "Offer this Rosary", latin: "")
        XCTAssertEqual(text.resolved(for: .latin), "Offer this Rosary")
        XCTAssertEqual(text.resolved(for: .bilingual), "Offer this Rosary")
        XCTAssertNil(text.secondary(for: .bilingual))
    }

    func testMysteryAnnouncementUsesTheVulgateForLatin() {
        let steps = RosarySequenceBuilder.build(set: .joyful)
        let announcement = steps.first { $0.kind == .mysteryAnnouncement }!
        XCTAssertTrue(announcement.body.hasDistinctLatin)
        XCTAssertTrue(announcement.body.latin.contains("Gabriel"))
        XCTAssertNotEqual(announcement.body.latin, announcement.body.english)
    }
}

/// The UI and the free-tier cap agree on what the Pope's intention is.
final class PapalIntentionTests: XCTestCase {
    func testOneRuleForSuggestionsAndSavedIntentions() {
        let papal = SuggestedIntention(id: "pope-2026-10", title: "For…", sourceLabel: "Holy Father’s Intention")
        let labelOnly = SuggestedIntention(id: "feast-1", title: "For the Pope", sourceLabel: "Pope visit")
        XCTAssertTrue(papal.isPapal)
        XCTAssertFalse(labelOnly.isPapal)
        XCTAssertTrue(PapalIntention.isPapal("pope-2026-10"))
        XCTAssertFalse(PapalIntention.isPapal(nil))
    }

    func testPickerOmitsPopeIntentionUntilItIsAdded() {
        let suggestion = SuggestedIntention(
            id: "pope-2026-11",
            title: "For the proper use of wealth",
            sourceLabel: "Holy Father’s Intention",
            monthLabel: "November 2026"
        )
        let personal = OfferIntention(title: "For Grandma’s recovery")

        XCTAssertFalse(PapalIntention.isAdded(suggestion, among: [personal]))
        let before = PapalIntention.pickerIntentions(saved: [personal])
        XCTAssertEqual(before.map(\.title), [personal.title])
        XCTAssertFalse(before.contains(where: \.isPapal))

        let added = OfferIntention(
            title: suggestion.title,
            sourceId: suggestion.id,
            category: .world,
            accent: .purple,
            emoji: "✝️"
        )
        XCTAssertTrue(PapalIntention.isAdded(suggestion, among: [personal, added]))
        let after = PapalIntention.pickerIntentions(saved: [personal, added])
        XCTAssertEqual(after.filter(\.isPapal).count, 1)
        XCTAssertEqual(after.first(where: \.isPapal)?.sourceId, "pope-2026-11")
    }

    func testHandTypedTitleCountsAsAddedButEarlierMonthDoesNot() {
        let november = SuggestedIntention(
            id: "pope-2026-11",
            title: "For the proper use of wealth",
            sourceLabel: "Holy Father’s Intention"
        )
        let typed = OfferIntention(title: "for the proper use of wealth")
        XCTAssertTrue(PapalIntention.isAdded(november, among: [typed]))
        XCTAssertTrue(PapalIntention.pickerIntentions(saved: [typed]).contains { $0.id == typed.id })

        let october = OfferIntention(
            title: "For the proper use of wealth",
            sourceId: "pope-2026-10",
            category: .world
        )
        XCTAssertFalse(PapalIntention.isAdded(november, among: [october]))
        // October's saved Holy Father intention still appears, because the user added it.
        let rows = PapalIntention.pickerIntentions(saved: [october])
        XCTAssertEqual(rows.map(\.sourceId), ["pope-2026-10"])
    }
}

final class IntentionNoteTests: XCTestCase {
    func testInfoButtonRequiresANonEmptyNote() {
        let withNote = OfferIntention(title: "For Mum’s recovery", note: "Please keep her in your prayers.")
        let blank = OfferIntention(title: "For our parish", note: "   ")
        let none = OfferIntention(title: "For our parish")

        XCTAssertTrue(IntentionNote.showsInfoButton(for: withNote, hideText: false))
        XCTAssertEqual(IntentionNote.displayNote(for: withNote, hideText: false), "Please keep her in your prayers.")
        XCTAssertFalse(IntentionNote.showsInfoButton(for: blank, hideText: false))
        XCTAssertFalse(IntentionNote.showsInfoButton(for: none, hideText: false))
        XCTAssertNil(IntentionNote.displayNote(for: blank, hideText: false))
        XCTAssertNil(IntentionNote.displayNote(for: none, hideText: false))
    }

    func testHiddenPersonalIntentionHidesTheNoteAndInfoButton() {
        let personal = OfferIntention(title: "For Mum’s recovery", note: "Please keep her in your prayers.", category: .personal)
        XCTAssertFalse(IntentionNote.showsInfoButton(for: personal, hideText: true))
        XCTAssertNil(IntentionNote.displayNote(for: personal, hideText: true))
        // The title stays readable when the privacy toggle is off.
        XCTAssertTrue(IntentionNote.showsInfoButton(for: personal, hideText: false))
    }

    func testHiddenPapalIntentionStillShowsItsNote() {
        let papal = OfferIntention(
            title: "For the proper use of wealth",
            note: "That we may use goods justly.",
            sourceId: "pope-2026-11",
            category: .world
        )
        XCTAssertTrue(IntentionNote.showsInfoButton(for: papal, hideText: true))
        XCTAssertEqual(IntentionNote.displayNote(for: papal, hideText: true), "That we may use goods justly.")
    }
}

/// Sundays are always Glorious, so the repeating Sunday reminder can name the set.
final class ReminderCopyTests: XCTestCase {
    func testSundayCopyNamesGlorious() {
        let adventSunday = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 29, hour: 12))!
        XCTAssertTrue(NotificationService.dailyBody(weekday: 1, day: adventSunday).contains("Glorious"))
        let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        XCTAssertTrue(NotificationService.dailyBody(weekday: 2, day: monday).contains("Joyful"))
    }

    func testDailyCopyIsOneSentenceNamingTheSet() {
        let sunday = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        XCTAssertEqual(NotificationService.dailyBody(weekday: 1, day: sunday),
                       "Time to pray the Glorious Mysteries. Take a few quiet minutes for the Rosary.")
    }

    private func feast(_ name: String, _ rank: FeastRank) -> Feast {
        Feast(id: name, name: BilingualText(english: name, latin: name), summary: "", suggestedMysterySet: nil,
              isMarian: false, rank: rank, dateProvider: { _ in nil })
    }

    func testFeastCopyUsesRankAndReadsNaturally() {
        XCTAssertEqual(NotificationService.feastBody([feast("All Saints", .solemnity)]),
                       "Today is the solemnity of All Saints")
        XCTAssertEqual(NotificationService.feastBody([feast("Saint Charles Borromeo", .memorial)]),
                       "Today is the memorial of Saint Charles Borromeo")
        XCTAssertEqual(NotificationService.feastBody([feast("The Assumption of the Blessed Virgin Mary", .solemnity)]),
                       "Today is the solemnity of the Assumption of the Blessed Virgin Mary")
        XCTAssertEqual(NotificationService.feastBody([feast("Our Lady of Lourdes", .optionalMemorial)]),
                       "Today is the memorial of Our Lady of Lourdes")
        XCTAssertEqual(NotificationService.feastBody([feast("Presentation of the Lord", .feast)]),
                       "Today is the feast of the Presentation of the Lord")
    }

    func testEveryCatalogFeastReadsAsASentence() {
        for feast in FeastCatalog.all {
            let body = NotificationService.feastBody([feast])
            print("FEASTCOPY \(body)")
            XCTAssertTrue(body.hasPrefix("Today is "), body)
            XCTAssertFalse(body.contains(" The "), body)
            XCTAssertFalse(body.contains("the the "), body)
        }
    }

    func testSeasonalDaysAndSharedDays() {
        XCTAssertEqual(NotificationService.feastBody([feast("Ash Wednesday", .seasonal)]), "Today is Ash Wednesday")
        XCTAssertEqual(NotificationService.feastBody([feast("First Sunday of Advent", .seasonal)]),
                       "Today is the First Sunday of Advent")
        XCTAssertEqual(NotificationService.feastBody([feast("The Commemoration of All the Faithful Departed", .seasonal)]),
                       "Today is the Commemoration of All the Faithful Departed")
        XCTAssertEqual(NotificationService.feastBody([feast("Our Lady of the Rosary", .memorial), feast("Saints Peter and Paul", .solemnity)]),
                       "Today is the memorial of Our Lady of the Rosary and the solemnity of Saints Peter and Paul")
    }
}

/// The Home week strip starts on the same weekday as the rhythm card.
final class WeekStripTests: XCTestCase {
    func testWeekFollowsFirstWeekday() {
        let cal = LiturgicalCalendar.gregorian
        let sunday = cal.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 9))!
        let monday = MysteryCalendar.week(containing: sunday, firstWeekday: 2)
        XCTAssertEqual(cal.component(.weekday, from: monday.first!.0), 2)
        XCTAssertEqual(cal.component(.day, from: monday.first!.0), 12)
        let sundayStart = MysteryCalendar.week(containing: sunday, firstWeekday: 1)
        XCTAssertEqual(cal.component(.day, from: sundayStart.first!.0), 18)
        XCTAssertEqual(sundayStart.count, 7)
    }
}

/// Rosary settings follow the account with the other preferences.
final class RosaryConfigSyncTests: XCTestCase {
    func testFirestoreRoundTrip() {
        var config = RosaryConfig()
        config.translation = .douayRheims
        config.fatimaPrayer = false
        config.memorare = true
        XCTAssertEqual(RosaryConfig(firestore: config.firestoreData()), config)
    }

    func testOlderPreferencesWithoutRosaryConfigDecode() throws {
        var prefs = SyncedPreferences.defaults
        prefs.rosaryConfig = nil
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(SyncedPreferences.self, from: data)
        XCTAssertNil(decoded.rosaryConfig)
    }

    func testSettingsChangeReachesSyncedPreferences() {
        let suite = "RosaryConfigSyncTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        var changed = false
        settings.onUserChange = { changed = true }
        settings.rosaryConfig.fatimaPrayer = false
        XCTAssertTrue(changed)
        XCTAssertEqual(settings.syncedPreferences.rosaryConfig?.fatimaPrayer, false)

        var incoming = settings.syncedPreferences
        incoming.rosaryConfig?.oSacrament = true
        settings.applySynced(incoming)
        XCTAssertTrue(settings.rosaryConfig.oSacrament)
    }
}


/// Rosary timing: only foreground, interacted-with time counts toward a Rosary's duration.
final class ActivePrayerClockTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func testLockAndBackgroundKeepCounting() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        // Decade 1 prayed, then the screen locks (background checkpoint keeps running).
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(240), keepRunning: true), 240)
        XCTAssertTrue(clock.isRunning, "Lock or background must not pause the clock")
        // Four more minutes praying with the screen locked, then the next bead tap.
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(480), keepRunning: true), 240)
    }

    func testTwentyFiveMinuteRosaryWithLocksBetweenDecades() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        var total: TimeInterval = 0
        // Five decades of five minutes each; the phone locks mid-decade every time.
        for decade in 0..<5 {
            let base = TimeInterval(decade) * 300
            total += clock.take(at: t0.addingTimeInterval(base + 30), keepRunning: true) // lock
            total += clock.take(at: t0.addingTimeInterval(base + 300), keepRunning: true) // tap
            clock.touch(at: t0.addingTimeInterval(base + 300))
        }
        total += clock.take(at: t0.addingTimeInterval(1_500), keepRunning: false)
        XCTAssertEqual(total, 1_500)
    }

    func testRelaunchRestoresTheClockFromStoredTimestamps() throws {
        let suite = "RosaryTimingTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let store = SessionStore(defaults: defaults)
        store.start(set: .sorrowful, language: .english)
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        clock.touch(at: t0.addingTimeInterval(120))
        store.addActivePrayerTime(clock.take(at: t0.addingTimeInterval(120), keepRunning: true))
        store.updateTimingClock(clock)
        // App killed; a fresh store reads the saved session.
        let relaunched = SessionStore(defaults: defaults)
        var restored = relaunched.savedTimingClock
        XCTAssertTrue(restored.isRunning)
        XCTAssertEqual(restored.take(at: t0.addingTimeInterval(420), keepRunning: true), 300)
        XCTAssertEqual(relaunched.session?.activeDuration, 120)
    }

    func testAbandonedGapIsCappedAtTenMinutes() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        // Autosaves and a lock during a two-hour gap still credit only the cap.
        var total: TimeInterval = 0
        total += clock.take(at: t0.addingTimeInterval(60), keepRunning: true)
        total += clock.take(at: t0.addingTimeInterval(3_000), keepRunning: true)
        total += clock.take(at: t0.addingTimeInterval(7_200), keepRunning: true)
        XCTAssertEqual(total, ActivePrayerClock.idleLimit)
        XCTAssertEqual(ActivePrayerClock.idleLimit, 600)
        // The next tap starts a fresh allowance.
        clock.touch(at: t0.addingTimeInterval(7_200))
        clock = ActivePrayerClock(runningSince: t0.addingTimeInterval(7_200), lastInteraction: t0.addingTimeInterval(7_200))
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(7_260), keepRunning: false), 60)
    }

    func testLeavingTheFlowPauses() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(300), keepRunning: false), 300)
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(7_500), keepRunning: false), 0)
    }

    func testEightyStepTwentyFiveMinuteRosaryCountsInFull() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        var total: TimeInterval = 0
        // A tap every 18.75 s with the screen on, plus the 10 s autosave in between.
        for step in 1...80 {
            let tap = t0.addingTimeInterval(TimeInterval(step) * 18.75)
            total += clock.take(at: tap.addingTimeInterval(-8.75), keepRunning: true)
            total += clock.step(at: tap)
            XCTAssertTrue(clock.isRunning, "A step change must not pause the clock")
        }
        total += clock.take(at: t0.addingTimeInterval(1_500), keepRunning: false)
        XCTAssertEqual(total, 1_500, accuracy: 0.001)
    }

    func testIdleGapBetweenStepsIsCappedAtTenMinutes() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        var total = clock.step(at: t0.addingTimeInterval(60))
        // Thirty minutes on one step, autosaving every so often, then the next tap.
        total += clock.take(at: t0.addingTimeInterval(900), keepRunning: true)
        total += clock.step(at: t0.addingTimeInterval(1_860))
        // Praying resumes normally after the tap.
        total += clock.step(at: t0.addingTimeInterval(1_920))
        total += clock.take(at: t0.addingTimeInterval(1_980), keepRunning: false)
        XCTAssertEqual(total, 60 + ActivePrayerClock.idleLimit + 60 + 60)
    }

    func testStepOnAPausedClockStaysPaused() {
        var clock = ActivePrayerClock()
        XCTAssertEqual(clock.step(at: t0), 0)
        XCTAssertFalse(clock.isRunning)
    }

    func testCheckpointsDoNotDoubleCount() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        let first = clock.take(at: t0.addingTimeInterval(10), keepRunning: true)
        let second = clock.take(at: t0.addingTimeInterval(25), keepRunning: true)
        let last = clock.take(at: t0.addingTimeInterval(30), keepRunning: false)
        XCTAssertEqual(first + second + last, 30)
    }

    func testResumeWhileRunningKeepsTheStart() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        clock.resume(at: t0.addingTimeInterval(60))
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(90), keepRunning: false), 90)
    }

    func testIdleStepIsCapped() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        // Phone left on a table with the screen awake for three hours.
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(3 * 3600), keepRunning: false), ActivePrayerClock.idleLimit)
    }

    func testInteractionExtendsTheAllowance() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        clock.touch(at: t0.addingTimeInterval(8 * 60))
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(16 * 60), keepRunning: false), 16 * 60)
    }

    func testClockMovingBackwardsCreditsNothing() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(-600), keepRunning: true), 0)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(60), keepRunning: false), 60)
    }

    func testPausedClockTakesNothing() {
        var clock = ActivePrayerClock()
        XCTAssertEqual(clock.take(at: t0, keepRunning: false), 0)
    }

    func testSyncEchoKeepsActiveTimeOfTheSameRosary() throws {
        let store = SessionStore(defaults: UserDefaults(suiteName: "RosaryTimingTests.\(UUID())")!)
        store.start(set: .joyful, language: .english)
        store.addActivePrayerTime(420)
        store.recordCompletedDecadeIfNeeded(1)
        var echo = try XCTUnwrap(store.session)
        echo.id = UUID()
        echo.activeDuration = 0
        echo.completedDecades = []
        echo.lastCompletedDecadeActiveDuration = 0
        store.applySynced(SyncedProgress(completedDays: [], session: echo, sessionChangedAt: Date()))
        let session = try XCTUnwrap(store.session)
        XCTAssertEqual(session.activeDuration, 420)
        XCTAssertEqual(session.completedDecades, [1])
        store.recordCompletedDecadeIfNeeded(1)
        XCTAssertEqual(store.completedDecades.count, 1, "An echo must not let a decade be recorded twice")
    }
}

/// Rhythm calendar day detail and duration display.
final class JourneyDayDetailTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return cal
    }

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func rosary(_ set: MysterySetKind, start: Date, minutes: Double, duration: TimeInterval, titles: [String]? = nil) -> CompletedPrayerSession {
        CompletedPrayerSession(id: UUID(), sessionId: UUID(), mysterySet: set, startedAt: start,
                               completedAt: start.addingTimeInterval(minutes * 60), duration: duration,
                               intentionId: nil, intentionTitle: nil, intentionTitles: titles)
    }

    private func decade(_ number: Int, at date: Date, duration: TimeInterval, session: UUID = UUID()) -> CompletedDecadeSession {
        CompletedDecadeSession(id: UUID(), sessionId: session, mysterySet: .sorrowful, decadeNumber: number,
                               completedAt: date, duration: duration, intentionId: nil, intentionTitle: nil)
    }

    func testDurationTextAndLegacySanitising() {
        XCTAssertNil(JourneyDuration.reliable(0), "Old records saved no duration")
        XCTAssertNil(JourneyDuration.reliable(10 * 3600), "Wall-clock spans are not prayer time")
        XCTAssertNil(JourneyDuration.reliable(.nan))
        XCTAssertNil(JourneyDuration.reliable(nil))
        XCTAssertEqual(JourneyDuration.reliable(1_080), 1_080)
        XCTAssertEqual(JourneyDuration.text(20), "Under a minute")
        XCTAssertEqual(JourneyDuration.text(60), "1 min")
        XCTAssertEqual(JourneyDuration.text(18 * 60), "18 mins")
        XCTAssertEqual(JourneyDuration.text(3600), "1 hr")
        XCTAssertEqual(JourneyDuration.text(3600 + 300), "1 hr 5 mins")
        XCTAssertEqual(JourneyDuration.dayTotal(40 * 3600), JourneyDuration.longestDay)
        XCTAssertEqual(JourneyDuration.dayTotal(-5), 0)
    }

    func testSeveralPrayersOnOneDayOldestFirst() {
        let evening = rosary(.glorious, start: at(27, 19), minutes: 22, duration: 20 * 60, titles: ["Mum"])
        let morning = rosary(.joyful, start: at(27, 7), minutes: 18, duration: 17 * 60)
        let otherDay = rosary(.luminous, start: at(26, 9), minutes: 20, duration: 19 * 60)
        let lone = decade(3, at: at(27, 12), duration: 4 * 60)
        let entries = JourneyDayDetail.entries(dayKey: "2026-10-27", sessions: [evening, otherDay, morning],
                                               decades: [lone], prayedDayKeys: ["2026-10-26", "2026-10-27"], calendar: calendar)
        XCTAssertEqual(entries.map(\.kind), [.rosary, .decade(3), .rosary])
        XCTAssertEqual(entries.map(\.mysterySet), [.joyful, .sorrowful, .glorious])
        XCTAssertEqual(entries.last?.intentionTitles, ["Mum"])
        XCTAssertEqual(JourneyDayDetail.totalDuration(entries), (17 + 4 + 20) * 60)
    }

    func testDecadesOfAFinishedRosaryFoldIntoIt() {
        let finished = rosary(.sorrowful, start: at(27, 8), minutes: 20, duration: 19 * 60)
        let parts = (1...5).map { decade($0, at: at(27, 8, $0 * 3), duration: 180, session: finished.sessionId!) }
        let entries = JourneyDayDetail.entries(dayKey: "2026-10-27", sessions: [finished], decades: parts,
                                               prayedDayKeys: ["2026-10-27"], calendar: calendar)
        XCTAssertEqual(entries.map(\.kind), [.rosary])
    }

    func testRosaryCrossingMidnightBelongsToItsStartDay() {
        let late = rosary(.joyful, start: at(26, 23, 50), minutes: 20, duration: 19 * 60)
        XCTAssertEqual(JourneyDayDetail.entries(dayKey: "2026-10-26", sessions: [late], decades: [], prayedDayKeys: ["2026-10-26"], calendar: calendar).count, 1)
        XCTAssertTrue(JourneyDayDetail.entries(dayKey: "2026-10-27", sessions: [late], decades: [], prayedDayKeys: [], calendar: calendar).isEmpty)
    }

    func testLegacyDayAndUntimedRecords() {
        let legacy = JourneyDayDetail.entries(dayKey: "2026-10-20", sessions: [], decades: [], prayedDayKeys: ["2026-10-20"], calendar: calendar)
        XCTAssertEqual(legacy.map(\.kind), [.recordedDay])
        XCTAssertNil(JourneyDayDetail.totalDuration(legacy))
        let untimed = rosary(.joyful, start: at(21, 9), minutes: 600, duration: 0)
        let entries = JourneyDayDetail.entries(dayKey: "2026-10-21", sessions: [untimed], decades: [], prayedDayKeys: ["2026-10-21"], calendar: calendar)
        XCTAssertEqual(entries.map(\.kind), [.rosary])
        XCTAssertNil(entries.first?.duration)
        XCTAssertTrue(JourneyDayDetail.entries(dayKey: "2026-10-22", sessions: [], decades: [], prayedDayKeys: [], calendar: calendar).isEmpty)
    }
}

@MainActor
final class SignInMessageTests: XCTestCase {
    func testOfflineIsFriendly() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(AuthStore.signInMessage(for: error), "You appear to be offline, connect to the internet and try again")
    }

    func testWrappedOfflineIsFriendly() {
        let inner = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let error = NSError(domain: "com.example.sdk", code: 1, userInfo: [NSUnderlyingErrorKey: inner])
        XCTAssertEqual(AuthStore.signInMessage(for: error), "You appear to be offline, connect to the internet and try again")
    }

    func testUnknownErrorHasNoFullStopOrSDKText() {
        let error = NSError(domain: "com.example.sdk", code: 42, userInfo: [NSLocalizedDescriptionKey: "Internal SDK failure."])
        let message = AuthStore.signInMessage(for: error)
        XCTAssertEqual(message, "Sign-in did not finish, please try again")
        XCTAssertFalse(message.hasSuffix("."))
    }
}

final class RosaryHapticsTests: XCTestCase {
    private let steps = RosarySequenceBuilder.build(set: .joyful)

    func testBeadRhythm() {
        for step in steps {
            switch step.kind {
            case .hailMary: XCTAssertEqual(step.haptic, .soft)
            case .mysteryAnnouncement: XCTAssertEqual(step.haptic, .medium)
            default: XCTAssertEqual(step.haptic, .light, "\(step.kind)")
            }
        }
        XCTAssertFalse(steps.contains { $0.haptic == .heavy || $0.haptic == .success })
    }

    func testDecadeCompletionIsTheOnlySuccess() throws {
        let closing = try XCTUnwrap(steps.firstIndex { $0.closesDecade })
        let next = steps[closing + 1]
        XCTAssertEqual(RosaryHaptics.arrival(at: next, from: steps[closing]).kind, .success)
        // Stepping back onto a decade's closing prayer is not a completion.
        XCTAssertEqual(RosaryHaptics.arrival(at: steps[closing], from: next).kind, steps[closing].haptic)
        let hail = try XCTUnwrap(steps.firstIndex { $0.kind == .hailMary && $0.decadeNumber == 1 })
        XCTAssertEqual(RosaryHaptics.arrival(at: steps[hail + 1], from: steps[hail]).kind, .soft)
        XCTAssertEqual(RosaryHaptics.arrival(at: steps[hail + 1], from: steps[hail], viaCompleteDecade: true).kind, .success)
    }

    func testCompleteDecadeCelebratesOnce() throws {
        let hail = try XCTUnwrap(steps.firstIndex { $0.kind == .hailMary && $0.decadeNumber == 1 })
        let skip = RosaryHaptics.arrival(at: steps[hail + 1], from: steps[hail], viaCompleteDecade: true)
        XCTAssertEqual(skip.kind, .success)
        XCTAssertEqual(skip.celebratedDecade, 1)
        // Leaving decade one's closing prayer (e.g. after Fatima) stays quiet.
        let closing = try XCTUnwrap(steps.firstIndex { $0.closesDecade && $0.decadeNumber == 1 })
        let leave = RosaryHaptics.arrival(at: steps[closing + 1], from: steps[closing], celebrated: [1])
        XCTAssertEqual(leave.kind, steps[closing + 1].haptic)
        XCTAssertNil(leave.celebratedDecade)
    }
}

/// Chunk 2: the in-Rosary settings sheet and the Saint Michael step.
final class RosarySettingsSheetTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    private func freshDefaults() -> UserDefaults {
        let name = "RosarySettingsSheetTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testSaintMichaelDefaultsOff() {
        XCTAssertFalse(RosaryConfig.default.saintMichael)
        XCTAssertFalse(SettingsStore(defaults: freshDefaults()).currentRosaryConfig.saintMichael)
    }

    func testSaintMichaelToggleReachesNewRosary() {
        let settings = SettingsStore(defaults: freshDefaults())
        settings.rosaryConfig.saintMichael = true
        XCTAssertTrue(settings.currentRosaryConfig.saintMichael)
    }

    func testShowBeadsDefaultsOnIncludingOldSavedData() throws {
        XCTAssertTrue(RosaryConfig.default.showBeads)
        let old = try JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"memorare":true}"#.utf8))
        XCTAssertTrue(old.showBeads)
        XCTAssertTrue(old.memorare)
        XCTAssertTrue(RosaryConfig(firestore: ["memorare": true]).showBeads)
    }

    func testShowBeadsEncodeDecodeAndFirestoreRoundTrip() throws {
        var config = RosaryConfig()
        config.showBeads = false
        let json = try JSONDecoder().decode(RosaryConfig.self, from: JSONEncoder().encode(config))
        XCTAssertFalse(json.showBeads)
        XCTAssertEqual(config.firestoreData()["showBeads"] as? Bool, false)
        XCTAssertEqual(RosaryConfig(firestore: config.firestoreData()), config)
    }

    func testShowBeadsPersistsAndResetTurnsItBackOn() {
        let defaults = freshDefaults()
        let settings = SettingsStore(defaults: defaults)
        settings.rosaryConfig.showBeads = false
        XCTAssertFalse(SettingsStore(defaults: defaults).currentRosaryConfig.showBeads)
        settings.rosaryConfig = .default
        XCTAssertTrue(settings.currentRosaryConfig.showBeads)
    }

    func testShowBeadsDoesNotChangeTheSteps() {
        var config = RosaryConfig()
        config.showBeads = false
        XCTAssertEqual(RosarySequenceBuilder.build(set: .joyful, config: config).map(\.kind),
                       RosarySequenceBuilder.build(set: .joyful, config: RosaryConfig()).map(\.kind))
    }

    func testSaintMichaelSitsAfterClosingPrayersBeforeFinalSignOfTheCross() {
        var config = RosaryConfig()
        config.saintMichael = true
        let kinds = RosarySequenceBuilder.build(set: .joyful, config: config).map(\.kind)
        let michael = try! XCTUnwrap(kinds.lastIndex(of: .saintMichael))
        XCTAssertEqual(kinds[michael - 1], .concludingPrayer)
        XCTAssertEqual(kinds[michael + 1], .signOfTheCross)
        XCTAssertEqual(kinds[michael + 2], .completion)
    }

    func testTogglingSaintMichaelMidRosaryKeepsPlace() {
        let off = RosarySequenceBuilder.build(set: .joyful, config: RosaryConfig())
        var config = RosaryConfig()
        config.saintMichael = true
        let on = RosarySequenceBuilder.build(set: .joyful, config: config)
        let place = 20
        let mapped = RosarySequenceBuilder.remap(index: place, from: off, to: on)
        XCTAssertEqual(on[mapped].kind, off[place].kind)
        XCTAssertEqual(on[mapped].decadeNumber, off[place].decadeNumber)
        XCTAssertEqual(on[mapped].hailMaryNumber, off[place].hailMaryNumber)
    }

    /// The sheet sits over the Rosary while the app stays active, so time keeps counting.
    func testOpeningSettingsSheetKeepsTiming() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        clock.touch(at: t0.addingTimeInterval(60))
        // Two minutes in the sheet, then back to praying (no pause, no reset).
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(180), keepRunning: true), 180)
        XCTAssertTrue(clock.isRunning)
    }

    /// Closing the Rosary (header ✕) banks the time and pauses.
    func testClosingPausesAndBanksTime() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(300), keepRunning: false), 300)
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(900), keepRunning: false), 0)
    }

    /// A sheet left open past the idle allowance only credits up to the 10-minute cap.
    func testSheetLeftOpenIsCapped() {
        var clock = ActivePrayerClock()
        clock.resume(at: t0)
        XCTAssertEqual(clock.take(at: t0.addingTimeInterval(3_600), keepRunning: true), ActivePrayerClock.idleLimit)
    }
}

/// Rosary timing scenarios, end to end: `RosaryFlow` makes the same timing calls as PrayView
/// (appear, step taps, the 10 s autosave, lock/background, return, relaunch, close, Complete)
/// against a real SessionStore, on a simulated wall clock.
final class RosaryTimingScenarioTests: XCTestCase {
    private struct RosaryFlow {
        let defaults: UserDefaults
        var store: SessionStore
        var clock = ActivePrayerClock()
        var now: Date
        var onCompleteScreen = false

        init(at start: Date) {
            defaults = UserDefaults(suiteName: "RosaryTimingScenario.\(UUID())")!
            store = SessionStore(defaults: defaults)
            now = start
        }

        var recorded: TimeInterval { store.session?.activeDuration ?? 0 }
        var dayTotal: TimeInterval { store.prayerTimeByDay.values.reduce(0, +) }

        /// Opens a fresh Rosary (configure / onAppear).
        mutating func open() {
            onCompleteScreen = false
            store.start(set: .joyful, language: .english, at: now)
            clock = ActivePrayerClock()
            clock.resume(at: now)
            store.updateTimingClock(clock)
        }

        /// Opens the saved Rosary: carries on its persisted clock, a return counts as a tap.
        mutating func resumeSaved() {
            onCompleteScreen = false
            clock = store.savedTimingClock
            tap()
        }

        /// Waits on the current step with the screen on; the autosave fires every 10 s.
        mutating func read(_ seconds: TimeInterval) {
            var left = seconds
            while left >= 10 {
                now += 10
                left -= 10
                if clock.isRunning { credit(clock.take(at: now, keepRunning: true)) }
            }
            now += left
        }

        /// Next, Back, Complete decade or a jump: `move(to:)`.
        mutating func tap() {
            guard !onCompleteScreen else { return }
            if clock.isRunning { credit(clock.step(at: now)) } else { clock.resume(at: now) }
            store.updateTimingClock(clock)
        }

        /// Steady praying: `steps` taps spread over `seconds`.
        mutating func pray(_ seconds: TimeInterval, steps: Int) {
            for _ in 0..<steps {
                read(seconds / Double(steps))
                tap()
            }
        }

        /// Lock, the app switcher or another app (scene inactive/background): keeps running.
        mutating func leaveApp(for seconds: TimeInterval) {
            if clock.isRunning { credit(clock.take(at: now, keepRunning: true)) }
            now += seconds
        }

        /// Scene active again.
        mutating func returnToApp() { tap() }

        /// The app is killed in the background and relaunched onto the saved Rosary.
        mutating func killAndRelaunch(after seconds: TimeInterval) {
            leaveApp(for: seconds)
            store = SessionStore(defaults: defaults)
            resumeSaved()
        }

        /// Close (X) or leaving the flow: pauses.
        mutating func close() {
            if clock.isRunning { credit(clock.take(at: now, keepRunning: false)) }
            store.updateTimingClock(clock)
        }

        mutating func finishDecade(_ number: Int) {
            tap()
            store.recordCompletedDecadeIfNeeded(number, completedAt: now)
        }

        /// The Complete screen: timing stops and the Rosary is recorded.
        mutating func complete() {
            close()
            onCompleteScreen = true
            store.complete(at: now)
        }

        private mutating func credit(_ duration: TimeInterval) {
            store.addActivePrayerTime(duration, at: now)
            store.updateTimingClock(clock)
        }
    }

    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    private func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testSteadyTwentyFiveMinuteRosary() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(1_500, steps: 80)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_500, accuracy: 0.001)
        XCTAssertEqual(flow.dayTotal, 1_500, accuracy: 0.001)
    }

    func testThreeMinuteLockMidStepCountsInFull() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(300, steps: 15)
        flow.read(30)
        flow.leaveApp(for: 180)
        flow.returnToApp()
        flow.read(30)
        flow.tap()
        XCTAssertEqual(flow.recorded, 540, accuracy: 0.001)
    }

    func testFifteenMinuteLockIsCappedAtTenAndTimingCarriesOnAfterReturning() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(300, steps: 15)
        flow.read(30)
        flow.leaveApp(for: 900)
        flow.returnToApp()
        flow.read(120)
        flow.tap()
        // 30 s + 14.5 min away counts only to 10 min after the last tap; the 2 min after
        // returning count in full.
        XCTAssertEqual(flow.recorded, 300 + 600 + 120, accuracy: 0.001)
    }

    func testAnotherAppAndBackCounts() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.read(60)
        flow.leaveApp(for: 240)
        flow.returnToApp()
        flow.pray(60, steps: 3)
        XCTAssertEqual(flow.recorded, 360, accuracy: 0.001)
    }

    func testKilledAndRelaunchedMidRosaryCarriesOn() {
        // A relaunch keeps only a Rosary resumable today, so this one runs on the real clock.
        var flow = RosaryFlow(at: Date())
        flow.open()
        flow.pray(600, steps: 30)
        flow.read(20)
        flow.killAndRelaunch(after: 120)
        XCTAssertEqual(flow.recorded, 740, accuracy: 0.001, "Time up to the kill and the 2 min away count")
        flow.pray(600, steps: 30)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_340, accuracy: 0.001)
    }

    func testClosedThenResumedAfterMidnightContinues() throws {
        var flow = RosaryFlow(at: at(10, 22, 30))
        flow.open()
        flow.pray(600, steps: 30)
        flow.close()
        XCTAssertFalse(flow.store.savedTimingClock.isRunning, "Closing pauses the saved clock")
        flow.now = at(11, 2, 0)
        XCTAssertNotNil(try XCTUnwrap(flow.store.session).isResumable(now: flow.now) ? flow.store.session : nil)
        flow.resumeSaved()
        flow.pray(600, steps: 30)
        flow.complete()
        // The 3 h 20 min closed overnight is not counted.
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_200, accuracy: 0.001)
        XCTAssertTrue(flow.store.prayed(on: at(10, 12)), "Credited to the evening it began")
    }

    func testSavedRosaryNotResumableNextMorning() throws {
        var flow = RosaryFlow(at: at(10, 21, 0))
        flow.open()
        flow.pray(600, steps: 30)
        flow.close()
        XCTAssertFalse(try XCTUnwrap(flow.store.session).isResumable(now: at(11, 7, 0)))
    }

    func testLongReadingOnOneStep() {
        var nine = RosaryFlow(at: t0)
        nine.open()
        nine.read(540)
        nine.tap()
        XCTAssertEqual(nine.recorded, 540, accuracy: 0.001)

        var eleven = RosaryFlow(at: t0)
        eleven.open()
        eleven.read(660)
        eleven.tap()
        XCTAssertEqual(eleven.recorded, 600, accuracy: 0.001)
    }

    func testRapidTaps() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(6, steps: 20)
        XCTAssertEqual(flow.recorded, 6, accuracy: 0.001)
    }

    func testGoingBackStepsKeepsTiming() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(120, steps: 6)
        flow.pray(60, steps: 3) // Back, Back, Back
        flow.pray(120, steps: 6)
        XCTAssertEqual(flow.recorded, 300, accuracy: 0.001)
    }

    func testDecadeDurations() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(120, steps: 7) // opening prayers
        for decade in 1...5 {
            flow.pray(290, steps: 12)
            flow.read(10)
            flow.finishDecade(decade)
        }
        let durations = flow.store.completedDecades.sorted { $0.decadeNumber < $1.decadeNumber }.map(\.duration)
        XCTAssertEqual(durations.count, 5)
        XCTAssertEqual(durations[0], 420, accuracy: 0.001, "Decade one includes the opening prayers")
        for later in durations.dropFirst() { XCTAssertEqual(later, 300, accuracy: 0.001) }
    }

    func testClosedWithoutFinishingThenStartedFresh() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(300, steps: 15)
        flow.close()
        flow.now += 3_600
        flow.open()
        XCTAssertEqual(flow.recorded, 0, "A fresh Rosary starts from zero")
        flow.pray(1_200, steps: 60)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.count, 1)
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_200, accuracy: 0.001)
        // The unfinished Rosary's minutes still count toward time in prayer.
        XCTAssertEqual(flow.dayTotal, 1_500, accuracy: 0.001)
    }

    func testCompleteScreenIdleIsNotCounted() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(1_500, steps: 80)
        flow.complete()
        flow.read(1_200)
        flow.leaveApp(for: 600)
        flow.returnToApp()
        flow.read(300)
        flow.close()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_500, accuracy: 0.001)
        XCTAssertEqual(flow.dayTotal, 1_500, accuracy: 0.001)
    }

    func testCrossingMidnight() {
        var flow = RosaryFlow(at: at(10, 23, 50))
        flow.open()
        flow.pray(1_200, steps: 60)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_200, accuracy: 0.001)
        XCTAssertTrue(flow.store.prayed(on: at(10, 12)))
        XCTAssertFalse(flow.store.prayed(on: at(11, 12)))
        // Time in prayer is filed under the day it was banked (to the 10 s autosave): about
        // 10 min each side of midnight, 20 min in all.
        XCTAssertEqual(flow.store.prayerTimeByDay[SyncedProgress.dayKey(for: at(10, 12))] ?? 0, 600, accuracy: 10)
        XCTAssertEqual(flow.store.prayerTimeByDay[SyncedProgress.dayKey(for: at(11, 12))] ?? 0, 600, accuracy: 10)
        XCTAssertEqual(flow.dayTotal, 1_200, accuracy: 0.001)
    }

    func testTimeZoneChangeMidRosaryDoesNotChangeTheDuration() {
        // Timing works on absolute instants, so moving zones (Perth to Sydney) changes nothing.
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(600, steps: 30)
        flow.pray(900, steps: 50)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_500, accuracy: 0.001)
        var perth = Calendar(identifier: .gregorian)
        perth.timeZone = TimeZone(identifier: "Australia/Perth")!
        var sydney = perth
        sydney.timeZone = TimeZone(identifier: "Australia/Sydney")!
        let start = Date(timeIntervalSince1970: 1_793_976_000) // 22:40 in Perth, 01:40 next day in Sydney
        XCTAssertNotEqual(SessionStore.creditedDayKey(startedAt: start, completedAt: start, calendar: perth),
                          SessionStore.creditedDayKey(startedAt: start, completedAt: start, calendar: sydney),
                          "The credited day follows the zone the phone is in")
    }

    func testDeviceClockJumpingBackwardsCreditsNothingThenCarriesOn() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(300, steps: 15)
        flow.now -= 3_600
        flow.tap()
        XCTAssertEqual(flow.recorded, 300, accuracy: 0.001)
        flow.pray(120, steps: 6)
        XCTAssertEqual(flow.recorded, 420, accuracy: 0.001, "Timing resumes from the corrected clock")
    }

    func testDeviceClockJumpingForwardIsCapped() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.pray(300, steps: 15)
        flow.now += 7_200
        flow.tap()
        XCTAssertEqual(flow.recorded, 900, accuracy: 0.001)
    }

    func testAutosaveAloneDoesNotDoubleCount() {
        var flow = RosaryFlow(at: t0)
        flow.open()
        flow.read(300)
        XCTAssertEqual(flow.recorded, 300, accuracy: 0.001)
        flow.tap()
        flow.tap()
        XCTAssertEqual(flow.recorded, 300, accuracy: 0.001)
        XCTAssertEqual(flow.dayTotal, 300, accuracy: 0.001)
    }

    func testSyncedCopyOfTheSameRosaryNeitherInflatesNorResets() throws {
        // A synced in-progress Rosary must be resumable today, so this one runs on the real clock.
        var flow = RosaryFlow(at: Date())
        flow.open()
        flow.pray(600, steps: 30)
        // The account copy has no active time or clock.
        var echo = try XCTUnwrap(flow.store.session)
        echo.id = UUID()
        echo.activeDuration = 0
        echo.timingRunningSince = nil
        echo.timingLastInteraction = nil
        flow.store.applySynced(SyncedProgress(completedDays: [], session: echo, sessionChangedAt: flow.now))
        XCTAssertEqual(flow.recorded, 600, accuracy: 0.001)
        XCTAssertTrue(flow.store.savedTimingClock.isRunning, "The local clock survives the echo")
        flow.pray(600, steps: 30)
        flow.complete()
        XCTAssertEqual(flow.store.completedSessions.first?.duration ?? 0, 1_200, accuracy: 0.001)
        XCTAssertEqual(flow.dayTotal, 1_200, accuracy: 0.001)
    }

    func testDurationDisplayThresholds() {
        XCTAssertEqual(JourneyDuration.text(29), "Under a minute")
        XCTAssertEqual(JourneyDuration.text(30), "1 min")
        XCTAssertEqual(JourneyDuration.text(89), "1 min")
        XCTAssertEqual(JourneyDuration.text(90), "2 mins")
        XCTAssertEqual(JourneyDuration.text(1_500), "25 mins")
        XCTAssertEqual(JourneyDuration.text(3_600), "1 hr")
        XCTAssertEqual(JourneyDuration.text(3_930), "1 hr 6 mins")
        XCTAssertNil(JourneyDuration.reliable(0.5))
        XCTAssertEqual(JourneyDuration.reliable(1), 1)
        XCTAssertEqual(JourneyDuration.reliable(10_800), 10_800)
        XCTAssertNil(JourneyDuration.reliable(10_801), "Over 3 h shows as not recorded")
    }
}

final class JourneyHistoryPagingTests: XCTestCase {
    func testCutoffCountsWholeMonthsIncludingThisOne() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Perth")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 9))!
        XCTAssertEqual(JourneyHistoryPaging.cutoff(monthsShown: 3, now: now, calendar: calendar),
                       calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        XCTAssertEqual(JourneyHistoryPaging.cutoff(monthsShown: 6, now: now, calendar: calendar),
                       calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        XCTAssertEqual(JourneyHistoryPaging.cutoff(monthsShown: 12, now: now, calendar: calendar),
                       calendar.date(from: DateComponents(year: 2025, month: 12, day: 1)))
    }
}

final class IntentionTextLimitTests: XCTestCase {
    func testLimitsStayWithinFirestoreRules() {
        XCTAssertLessThanOrEqual(IntentionTextLimit.title, 160)
        XCTAssertLessThanOrEqual(IntentionTextLimit.note, 2000)
    }

    func testOverLimitIsAnErrorNotAClamp() {
        let atLimit = String(repeating: "a", count: IntentionTextLimit.title)
        let pasted = atLimit + "bc"
        XCTAssertFalse(IntentionTextLimit.isOver(atLimit, limit: IntentionTextLimit.title))
        XCTAssertTrue(IntentionTextLimit.isOver(pasted, limit: IntentionTextLimit.title))
        XCTAssertTrue(IntentionTextLimit.fits(title: atLimit, note: nil))
        XCTAssertFalse(IntentionTextLimit.fits(title: pasted, note: nil))
        XCTAssertFalse(IntentionTextLimit.fits(title: "Peace", note: String(repeating: "n", count: IntentionTextLimit.note + 1)))
        XCTAssertEqual(IntentionTextLimit.errorMessage(limit: 100), "Keep it to 100 characters or fewer.")
    }

    func testSurroundingWhitespaceDoesNotCount() {
        let padded = "  " + String(repeating: "a", count: IntentionTextLimit.title) + "\n "
        XCTAssertEqual(IntentionTextLimit.count(padded), IntentionTextLimit.title)
        XCTAssertFalse(IntentionTextLimit.isOver(padded, limit: IntentionTextLimit.title))
    }

    func testCounterAppearsNearTheLimit() {
        XCTAssertFalse(IntentionTextLimit.showsCounter(String(repeating: "a", count: 79), limit: 100))
        XCTAssertTrue(IntentionTextLimit.showsCounter(String(repeating: "a", count: 80), limit: 100))
    }
}
