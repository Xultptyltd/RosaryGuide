import XCTest
import SwiftUI
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

    func testSundaysAreAlwaysGlorious() {
        XCTAssertEqual(setOn(2026, 11, 29), .glorious) // Advent
        XCTAssertEqual(setOn(2026, 12, 27), .glorious) // Christmastide
        XCTAssertEqual(setOn(2026, 3, 1), .glorious)   // Lent
        XCTAssertEqual(setOn(2026, 3, 29), .glorious)  // Palm Sunday
        XCTAssertEqual(setOn(2026, 4, 12), .glorious)  // Easter
        XCTAssertEqual(MysterySetKind.glorious.days(in: .lent), "Wednesdays and Sundays")
        XCTAssertEqual(MysterySetKind.joyful.days(in: .advent), "Mondays and Saturdays")
    }

    func testRosaryEndsWithTheSignOfTheCross() {
        for config in [RosaryConfig.default, { var c = RosaryConfig(); c.closingPrayers = false; c.memorare = true; return c }()] {
            let steps = RosarySequenceBuilder.build(set: .joyful, config: config)
            let prayers = steps.filter { $0.kind != .completion }
            XCTAssertEqual(prayers.first?.kind, .signOfTheCross)
            XCTAssertEqual(prayers.last?.kind, .signOfTheCross)
            XCTAssertEqual(prayers.last?.stage, .closing)
            XCTAssertTrue(prayers.last?.isLastPrayer == true)
            XCTAssertEqual(steps.filter(\.isLastPrayer).count, 1)
            XCTAssertEqual(steps.last?.kind, .completion)
            XCTAssertEqual(prayers.last?.body, PrayerCatalog.signOfTheCross.text)
            XCTAssertTrue(prayers.last?.body.hasDistinctLatin == true)
        }
        // Default: 1 + 1 + 1 + 3 + 1 opening, 5 × 14 decades, 3 closing, final Sign of the Cross.
        XCTAssertEqual(RosarySequenceBuilder.build(set: .joyful).filter { $0.kind != .completion }.count, 81)
    }

    func testFeastsDoNotOverrideWeekdaySet() {
        XCTAssertEqual(setOn(2026, 12, 25), .sorrowful) // Friday Christmas
        XCTAssertEqual(setOn(2026, 8, 15), .joyful)     // Saturday Assumption
        let christmas = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 12, day: 25)!)
        XCTAssertEqual(christmas.feastSuggestion, .joyful)
        let assumption = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 8, day: 15)!)
        XCTAssertEqual(assumption.feastSuggestion, .glorious)
    }

    func testHomeDefaultsToTheFeastSetAndCanSwitch() throws {
        let christmas = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 12, day: 25)!)
        XCTAssertEqual(christmas.set, .sorrowful) // the calendar keeps the weekday set
        XCTAssertEqual(christmas.defaultSet(prefersWeekday: false), .joyful)
        XCTAssertEqual(christmas.defaultSet(prefersWeekday: true), .sorrowful)
        XCTAssertEqual(christmas.shownSet(manual: nil, prefersWeekday: false), .joyful)
        // The picker dot marks the weekday set whatever is showing.
        XCTAssertEqual(christmas.pickerDotSet, .sorrowful)
        XCTAssertEqual(christmas.shownSet(manual: .luminous, prefersWeekday: false), .luminous)
        XCTAssertEqual(christmas.shownSet(manual: .luminous, prefersWeekday: true), .luminous)
        let line = try XCTUnwrap(christmas.feastLine)
        XCTAssertEqual(line.text, "Today we celebrate the birth of our Lord. Many pray the Joyful Mysteries at Christmas.")
        XCTAssertEqual(line.setName, "Joyful Mysteries")
        XCTAssertEqual(FeastLine.backToTodayTitle, "Back to today")
    }

    func testOnlyMajorFeastsRecommendASetOnHome() {
        let ids: Set<String> = ["christmas", "annunciation", "immaculate-conception", "ash-wednesday", "good-friday",
                                "holy-thursday", "baptism-movable", "corpus-christi", "easter", "assumption", "pentecost"]
        XCTAssertEqual(Set(FeastCatalog.all.filter(\.recommendsOnHome).map(\.id)), ids)
        XCTAssertEqual(Set(FeastCatalog.celebrations.keys), ids)
        // Assumption 2026 (Saturday) recommends Glorious; Guadalupe 2026 (Saturday, Joyful anyway)
        // and Lourdes 2026 (Wednesday) follow the weekday.
        XCTAssertEqual(setDefault(2026, 8, 15), .glorious)
        XCTAssertEqual(setDefault(2026, 2, 11), .glorious)
        XCTAssertNil(MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 2, day: 11)!).feastLine)
        // Our Lady of Sorrows 2026 is a Tuesday; Guardian Angels 2026 is a Friday: weekday set, no line.
        XCTAssertEqual(setDefault(2026, 10, 2), .sorrowful)
        XCTAssertNil(MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 10, day: 2)!).feastLine)
        // Good Friday 2026 is Sorrowful anyway; Pentecost is a Sunday. Corpus Christi 2026 (Thursday) agrees.
        // Immaculate Conception 2026 is a Tuesday: Joyful instead of Sorrowful.
        XCTAssertEqual(setDefault(2026, 12, 8), .joyful)
        // The Feasts screen keeps every feast's own suggested set.
        XCTAssertEqual(FeastCatalog.all.first { $0.id == "guadalupe" }?.suggestedMysterySet, .joyful)
        for id in ids {
            let line = FeastCatalog.celebrations[id]!
            XCTAssertTrue(line.today.hasPrefix("Today "), id)
            XCTAssertTrue(line.today.hasSuffix("."), id)
            XCTAssertFalse(line.occasion.hasSuffix("."), id)
            XCTAssertTrue(line.occasion.hasPrefix("on ") || line.occasion.hasPrefix("at "), id)
        }
    }

    func testHomeKeepsWeekdaySetWhenFeastAgreesOrNoFeast() {
        // Assumption 2027 is a Sunday: Glorious either way, so no suggestion or caption.
        let assumption = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2027, month: 8, day: 15)!)
        XCTAssertNotNil(assumption.feast)
        XCTAssertNil(assumption.feastSuggestion)
        XCTAssertNil(assumption.feastLine)
        XCTAssertEqual(assumption.defaultSet(prefersWeekday: false), .glorious)
        // An ordinary Thursday with no feast.
        let plain = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 9, day: 17)!)
        XCTAssertEqual(plain.defaultSet(prefersWeekday: false), .luminous)
        XCTAssertNil(plain.feastLine)
    }

    @MainActor
    func testWeekdayChoiceResetsAtDayRollover() {
        let start = LiturgicalCalendar.date(year: 2026, month: 12, day: 25)!
        let clock = DayClock(now: start.addingTimeInterval(12 * 3600))
        clock.prefersWeekdaySet = true
        clock.refresh(now: start.addingTimeInterval(20 * 3600))
        XCTAssertTrue(clock.prefersWeekdaySet) // same day keeps the choice
        clock.refresh(now: start.addingTimeInterval(36 * 3600))
        XCTAssertFalse(clock.prefersWeekdaySet)
    }

    func testCatalogHasTwentyMysteriesWithArtSlugs() {
        XCTAssertEqual(MysteryCatalog.all.count, 20)
        for set in MysterySetKind.allCases {
            let items = MysteryCatalog.mysteries(for: set)
            XCTAssertEqual(items.count, 5)
            XCTAssertTrue(items.allSatisfy { !$0.artSlug.isEmpty })
        }
    }

    private func setDefault(_ y: Int, _ m: Int, _ d: Int) -> MysterySetKind {
        MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: y, month: m, day: d)!).defaultSet(prefersWeekday: false)
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

final class MysteryPrayerLaunchTests: XCTestCase {
    func testEachMysteryLaunchesAtItsOwnAnnouncement() {
        for set in MysterySetKind.allCases {
            let steps = RosarySequenceBuilder.build(set: set)
            for number in 1...5 {
                let intention = UUID()
                let launch = PrayLaunch.fresh(set, intentionId: intention, startingDecade: number)
                let step = steps[launch.startIndex(in: steps)]
                XCTAssertEqual(step.kind, .mysteryAnnouncement)
                XCTAssertEqual(step.decadeNumber, number)
                XCTAssertEqual(launch.intentionId, intention)
                XCTAssertEqual(launch.mysterySet, set)
                XCTAssertNotEqual(launch.id, PrayLaunch.fresh(set, intentionId: intention).id)
            }
            XCTAssertEqual(PrayLaunch.fresh(set).startIndex(in: steps), 0)
        }
    }
}

final class RosaryChainHighlightTests: XCTestCase {
    func testRotatedChainMarkersStayCenteredAndKeepTheirLength() {
        let center = CGPoint(x: 173, y: 42)
        for angle in [CGFloat.zero, .pi / 4, .pi / 2, .pi, .pi * 1.5, .pi * 1.75] {
            let bounds = RosaryBeadMapView.chainHighlightPath(at: center, tangent: angle).boundingRect
            XCTAssertEqual(bounds.midX, center.x, accuracy: 0.0001)
            XCTAssertEqual(bounds.midY, center.y, accuracy: 0.0001)
            XCTAssertEqual(hypot(bounds.width, bounds.height), 6.8, accuracy: 0.0001)
        }
    }

    func testEveryGloryBeAndFatimaPrayerUsesItsCorrectChainSpace() {
        for set in MysterySetKind.allCases {
            let steps = RosarySequenceBuilder.build(set: set)
            XCTAssertEqual(steps.filter { $0.kind == .gloryBe }.count, 6)
            XCTAssertEqual(steps.first { $0.kind == .gloryBe }?.bead, .openingGlory)
            for decade in 1...5 {
                XCTAssertEqual(steps.first { $0.kind == .gloryBe && $0.decadeNumber == decade }?.bead, .decadeGlory(decade))
                XCTAssertEqual(steps.first { $0.kind == .fatima && $0.decadeNumber == decade }?.bead, .decadeFatima(decade))
            }
        }
    }
}

final class RosarySpacingTests: XCTestCase {
    private let layout = RosaryGeometry.shared

    private func bead(_ locus: BeadLocus) throws -> RosaryBead {
        try XCTUnwrap(layout.beads.first { $0.locus == locus })
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    func testEachDecadeHasExactlyTenSmallPearlsAndOneChainSpace() {
        for decade in 1...5 {
            let first: BeadLocus = decade == 1 ? .decadeHail(1, 1) : .decadeOurFather(decade)
            let start = layout.beads.firstIndex { $0.locus == first }!
            let group = Array(layout.beads[start..<(start + (decade == 1 ? 11 : 12))])
            XCTAssertEqual(group[0].large, decade != 1)
            let smallPearls = group.filter { !$0.large && !$0.isSpace }
            XCTAssertEqual(smallPearls.map(\.locus), (1...10).map { .decadeHail(decade, $0) })
            XCTAssertEqual(group.filter(\.isSpace).map(\.locus), [.decadeGlory(decade)])
        }
    }

    func testAllHailMaryRunsMatchPendantSpacingIncludingCurves() throws {
        let pendantGap = distance(try bead(.openingHail(1)).point, try bead(.openingHail(2)).point)
        for decade in 1...5 {
            for number in 1..<10 {
                let actual = distance(try bead(.decadeHail(decade, number)).point, try bead(.decadeHail(decade, number + 1)).point)
                XCTAssertEqual(actual, pendantGap, accuracy: 0.05, "Decade \(decade), bead \(number)")
            }
        }
    }

    func testLargeBeadGapsMatchOnPendantAndEveryDecade() throws {
        let pendantGap = distance(try bead(.openingOurFather).point, try bead(.openingHail(1)).point)
        for decade in 2...5 {
            let actual = distance(try bead(.decadeOurFather(decade)).point, try bead(.decadeHail(decade, 1)).point)
            XCTAssertEqual(actual, pendantGap, accuracy: 0.3)
        }
    }

    func testNoExtraLargeBeadAfterMedalAndLargeBeadsHaveBalancedGaps() throws {
        XCTAssertNil(layout.beads.first { $0.locus == .decadeOurFather(1) })
        XCTAssertEqual(layout.beads.filter(\.large).count, 5) // Four on loop, one on pendant.
        for decade in 2...5 {
            let big = try bead(.decadeOurFather(decade)).point
            let before = distance(try bead(.decadeHail(decade - 1, 10)).point, big)
            let after = distance(big, try bead(.decadeHail(decade, 1)).point)
            XCTAssertEqual(before, after, accuracy: 0.3)
        }
    }

    func testEveryBeadAndChainMarkerHasClearanceAndFitsInsideTheMap() {
        func radius(_ bead: RosaryBead) -> CGFloat { bead.isSpace ? 3.4 : (bead.large ? 3.45 : 2.25) }
        for (index, bead) in layout.beads.enumerated() {
            XCTAssertGreaterThanOrEqual(bead.point.x - radius(bead), 0)
            XCTAssertLessThanOrEqual(bead.point.x + radius(bead), layout.viewW)
            XCTAssertGreaterThanOrEqual(bead.point.y - radius(bead), 0)
            XCTAssertLessThanOrEqual(bead.point.y + radius(bead), layout.viewH)
            XCTAssertGreaterThan(distance(bead.point, layout.medal), radius(bead) + 9.3)
            for other in layout.beads.dropFirst(index + 1) {
                XCTAssertGreaterThan(distance(bead.point, other.point), radius(bead) + radius(other), "\(bead.locus) overlaps \(other.locus)")
            }
        }
    }
}

final class RosaryConfigTests: XCTestCase {
    private func count(_ edit: (inout RosaryConfig) -> Void) -> Int {
        var config = RosaryConfig.default
        edit(&config)
        return RosarySequenceBuilder.build(set: .joyful, config: config).count
    }

    func testStepCountsPerCombination() {
        // Includes the closing Sign of the Cross and the finis step.
        XCTAssertEqual(RosarySequenceBuilder.build(set: .joyful).count, 82)
        XCTAssertEqual(count { _ in }, 82)
        XCTAssertEqual(count { $0.fatimaPrayer = false }, 77)
        XCTAssertEqual(count { $0.oSacrament = true }, 87)
        XCTAssertEqual(count { $0.closingPrayers = false }, 79)
        XCTAssertEqual(count { $0.memorare = true }, 83)
        XCTAssertEqual(count { $0.saintMichael = true }, 83)
        XCTAssertEqual(count { $0.memorare = true; $0.saintMichael = true; $0.oSacrament = true }, 89)
        XCTAssertEqual(count { $0.fatimaPrayer = false; $0.closingPrayers = false }, 74)
    }

    func testDecadeEndsAndLastPrayerFollowConfig() {
        for config in [RosaryConfig.default, { var c = RosaryConfig(); c.fatimaPrayer = false; c.closingPrayers = false; return c }(),
                       { var c = RosaryConfig(); c.oSacrament = true; c.memorare = true; c.saintMichael = true; return c }()] {
            let steps = RosarySequenceBuilder.build(set: .sorrowful, config: config)
            XCTAssertEqual(steps.filter(\.closesDecade).map(\.decadeNumber), [1, 2, 3, 4, 5])
            XCTAssertEqual(steps.filter(\.isLastPrayer).count, 1)
            XCTAssertEqual(steps.firstIndex(where: \.isLastPrayer), steps.count - 2)
            XCTAssertEqual(steps.last?.kind, .completion)
            XCTAssertEqual(Set(steps.map(\.stage)).count, 7)
        }
        var extras = RosaryConfig()
        extras.memorare = true
        extras.saintMichael = true
        let closing = RosarySequenceBuilder.build(set: .glorious, config: extras).suffix(7).map(\.kind)
        XCTAssertEqual(closing, [.hailHolyQueen, .versicle, .concludingPrayer, .memorare, .saintMichael, .signOfTheCross, .completion])
    }

    func testScriptureTranslationAndOpeningLines() {
        var config = RosaryConfig()
        config.translation = .douayRheims
        var plate = RosarySequenceBuilder.build(set: .joyful, config: config).first { $0.isPlate }
        XCTAssertTrue(plate?.body.english.hasPrefix("And in the sixth month, the angel Gabriel") == true)
        config.translation = .vulgate
        plate = RosarySequenceBuilder.build(set: .joyful, config: config).first { $0.isPlate }
        XCTAssertTrue(plate?.body.english.hasPrefix("In mense autem sexto") == true)
        XCTAssertEqual(plate?.scriptureReference, "Luke 1:26-27")
        // Old stored configs with showScripture still decode.
        let old = try? JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"showScripture":false,"memorare":true}"#.utf8))
        XCTAssertEqual(old?.memorare, true)
        for mystery in MysteryCatalog.all {
            XCTAssertNotNil(MysteryScripture.douayRheims[mystery.id], mystery.id)
            XCTAssertNotNil(MysteryScripture.vulgate[mystery.id], mystery.id)
        }
        // Opening lines are always shown; an old stored "off" is ignored.
        let oldLines = try? JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"openingIntentionLines":false}"#.utf8))
        let opening = RosarySequenceBuilder.build(set: .joyful, config: oldLines ?? .default).filter { $0.stage == .opening && $0.kind == .hailMary }
        XCTAssertEqual(opening.map(\.subtitle), PrayerCatalog.openingIntentions)
    }

    func testResumeUsesSavedConfig() throws {
        var config = RosaryConfig()
        config.closingPrayers = false
        config.memorare = true
        let session = PrayerSession(mysterySet: .luminous, stepIndex: 77, startedAt: Date(), updatedAt: Date(),
                                    includeSaintMichael: false, language: .english, intentionId: nil, intentionTitle: nil,
                                    rosaryConfig: config)
        let decoded = try JSONDecoder().decode(PrayerSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(decoded.rosaryConfig, config)
        let steps = RosarySequenceBuilder.build(set: decoded.mysterySet, config: decoded.rosaryConfig)
        XCTAssertEqual(steps.count, 80)
        XCTAssertEqual(steps[decoded.stepIndex].kind, .memorare)
    }

    func testOldSessionDecodesToDefaultConfig() throws {
        let session = PrayerSession(mysterySet: .joyful, stepIndex: 12, startedAt: Date(), updatedAt: Date(),
                                    includeSaintMichael: false, language: .english, intentionId: nil, intentionTitle: nil)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        object.removeValue(forKey: "rosaryConfig")
        let decoded = try JSONDecoder().decode(PrayerSession.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.rosaryConfig, .default)
        XCTAssertEqual(RosarySequenceBuilder.build(set: .joyful, config: decoded.rosaryConfig).count, 82)
        // Partial configs (future/older fields) fall back per field.
        let partial = try JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"memorare":true}"#.utf8))
        XCTAssertTrue(partial.memorare)
        XCTAssertTrue(partial.fatimaPrayer)
        XCTAssertEqual(partial.translation, .webCatholic)
    }
}

final class RosaryRemapTests: XCTestCase {
    private func config(_ edit: (inout RosaryConfig) -> Void) -> RosaryConfig {
        var c = RosaryConfig()
        edit(&c)
        return c
    }

    func testFatimaOffMidDecadeKeepsSameStep() {
        let old = RosarySequenceBuilder.build(set: .joyful)
        let new = RosarySequenceBuilder.build(set: .joyful, config: config { $0.fatimaPrayer = false })
        let index = old.firstIndex { $0.decadeNumber == 2 && $0.kind == .hailMary && $0.hailMaryNumber == 5 }!
        let mapped = RosarySequenceBuilder.remap(index: index, from: old, to: new)
        XCTAssertEqual(new[mapped].identity, old[index].identity)
        XCTAssertEqual(mapped, index - 1) // decade 1 lost its Fatima prayer
        XCTAssertTrue(new.firstIndex { $0.decadeNumber == 2 && $0.kind == .gloryBe }.map { new[$0].closesDecade } == true)
    }

    func testMemorareOnNearEndComesNext() {
        let old = RosarySequenceBuilder.build(set: .glorious)
        let new = RosarySequenceBuilder.build(set: .glorious, config: config { $0.memorare = true })
        let index = old.firstIndex { $0.kind == .concludingPrayer }!
        let mapped = RosarySequenceBuilder.remap(index: index, from: old, to: new)
        XCTAssertEqual(new[mapped].kind, .concludingPrayer)
        XCTAssertEqual(new[mapped + 1].kind, .memorare)
        XCTAssertEqual(new[mapped + 2].kind, .signOfTheCross)
        XCTAssertTrue(new[mapped + 2].isLastPrayer)
        XCTAssertFalse(new[mapped + 1].isLastPrayer)
    }

    func testRemovedCurrentStepMovesToNextSurvivor() {
        let old = RosarySequenceBuilder.build(set: .sorrowful)
        let fatimaOff = RosarySequenceBuilder.build(set: .sorrowful, config: config { $0.fatimaPrayer = false })
        let fatima2 = old.firstIndex { $0.kind == .fatima && $0.decadeNumber == 2 }!
        let mapped = RosarySequenceBuilder.remap(index: fatima2, from: old, to: fatimaOff)
        XCTAssertEqual(fatimaOff[mapped].kind, .mysteryAnnouncement)
        XCTAssertEqual(fatimaOff[mapped].decadeNumber, 3)

        // Closing group removed while on the versicle: Memorare (still on) comes next.
        let withMemorare = config { $0.memorare = true }
        let before = RosarySequenceBuilder.build(set: .sorrowful, config: withMemorare)
        let after = RosarySequenceBuilder.build(set: .sorrowful, config: config { $0.memorare = true; $0.closingPrayers = false })
        let versicle = before.firstIndex { $0.kind == .versicle }!
        XCTAssertEqual(after[RosarySequenceBuilder.remap(index: versicle, from: before, to: after)].kind, .memorare)

        // No other closing prayer left: lands on the closing Sign of the Cross.
        let bare = RosarySequenceBuilder.build(set: .sorrowful, config: config { $0.closingPrayers = false })
        let landed = bare[RosarySequenceBuilder.remap(index: old.firstIndex { $0.kind == .versicle }!, from: old, to: bare)]
        XCTAssertEqual(landed.kind, .signOfTheCross)
        XCTAssertEqual(landed.stage, .closing)
    }

    func testTranslationChangeKeepsPositionAndSwapsScripture() {
        let old = RosarySequenceBuilder.build(set: .joyful)
        let new = RosarySequenceBuilder.build(set: .joyful, config: config { $0.translation = .douayRheims })
        let plate = old.firstIndex { $0.isPlate }!
        let mapped = RosarySequenceBuilder.remap(index: plate, from: old, to: new)
        XCTAssertEqual(mapped, plate)
        XCTAssertTrue(new[mapped].body.english.hasPrefix("And in the sixth month, the angel Gabriel"))
    }
}

/// The modern translation is the World English Bible, Catholic Edition (public domain).
final class WebCatholicScriptureTests: XCTestCase {
    /// Phrases only the previous translation used, never the WEB Catholic text.
    private let previousTranslationPhrases = [
        "handmaid of the Lord", "Hail, full of grace", "swaddling cloths",
        "close of the age", "Truly, I say to you", "Fear not",
    ]

    private func allScripture() -> [String] {
        var texts = MysteryCatalog.all.map(\.scriptureExcerpt.english)
        for id in FeastScriptures.coveredIds {
            texts += FeastScriptures.passages(for: id).map(\.excerpt)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for offset in 0..<(366 * 2) {
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            let verse = LiturgicalVerseCatalog.verse(for: day, calendar: calendar)
            texts += [verse.homeExcerpt, verse.fullText]
        }
        return texts
    }

    func testNoPreviousTranslationWording() {
        for text in allScripture() {
            for phrase in previousTranslationPhrases {
                XCTAssertFalse(text.localizedCaseInsensitiveContains(phrase), "\(phrase): \(text)")
            }
        }
    }

    func testScriptureIsWebCatholic() {
        let joyful = MysteryCatalog.all.first { $0.id == "joyful-1" }!
        XCTAssertTrue(joyful.scriptureExcerpt.english.hasPrefix("Now in the sixth month, the angel Gabriel was sent from God"))
        XCTAssertEqual(RosaryConfig().translation, .webCatholic)
        let plate = RosarySequenceBuilder.build(set: .joyful, config: .default).first { $0.isPlate }
        XCTAssertTrue(plate?.body.english.hasPrefix("Now in the sixth month") == true)
        let resurrection = MysteryCatalog.all.first { $0.id == "glorious-1" }!
        XCTAssertEqual(resurrection.scriptureReference, "Luke 24:5-6")
        XCTAssertEqual(resurrection.scriptureExcerpt.english, "Why do you seek the living among the dead? He isn’t here, but is risen.")
        let annunciation = FeastScriptures.passages(for: "annunciation").map(\.excerpt).joined()
        XCTAssertTrue(annunciation.contains("Behold, the servant of the Lord; let it be done to me according to your word."), annunciation)
        for text in allScripture() {
            XCTAssertFalse(text.isEmpty)
            XCTAssertEqual(text.filter { $0 == "“" }.count, text.filter { $0 == "”" }.count, text)
        }
    }

    func testOldTranslationSettingBecomesWebCatholic() throws {
        let stored = try JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"translation":"rsv2ce","memorare":true}"#.utf8))
        XCTAssertEqual(stored.translation, .webCatholic)
        XCTAssertTrue(stored.memorare)
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(stored)) as? [String: Any])
        XCTAssertEqual(encoded["translation"] as? String, "webc")
        XCTAssertEqual(try JSONDecoder().decode(RosaryConfig.self, from: JSONEncoder().encode(stored)), stored)
        let unknown = try JSONDecoder().decode(RosaryConfig.self, from: Data(#"{"translation":"kjv"}"#.utf8))
        XCTAssertEqual(unknown.translation, .webCatholic)
    }

    func testFirestoreKeepsTokenTheDeployedRulesAllow() {
        XCTAssertEqual(RosaryConfig(firestore: ["translation": "rsv2ce"]).translation, .webCatholic)
        XCTAssertEqual(RosaryConfig(firestore: ["translation": "webc"]).translation, .webCatholic)
        XCTAssertEqual(RosaryConfig(firestore: ["translation": "vulgate"]).translation, .vulgate)
        let allowed: Set<String> = ["rsv2ce", "douayRheims", "vulgate"]
        for translation in BibleTranslation.allCases {
            var config = RosaryConfig()
            config.translation = translation
            let token = config.firestoreData()["translation"] as? String
            XCTAssertTrue(token.map(allowed.contains) == true, "\(translation)")
            XCTAssertEqual(RosaryConfig(firestore: config.firestoreData()).translation, translation)
        }
    }
}

final class LearnAndHistoryDetailTests: XCTestCase {
    /// Learn captions name exactly the weekdays the calendar assigns, in ordinary time,
    /// Advent and Lent (the app keeps one weekly pattern; Sundays are always Glorious).
    func testWeekdayCaptionsMatchCalendar() {
        let weeks = [(2026, 9, 14), (2026, 11, 30), (2026, 3, 2)] // ordinary, Advent, Lent (Mondays)
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        for (y, m, d) in weeks {
            var days: [MysterySetKind: [String]] = [:]
            for offset in 0..<7 {
                let date = LiturgicalCalendar.date(year: y, month: m, day: d + offset)!
                let weekday = LiturgicalCalendar.gregorian.component(.weekday, from: date)
                days[MysteryCalendar.assignment(on: date).set, default: []].append(names[weekday - 1])
            }
            for set in MysterySetKind.allCases {
                XCTAssertEqual(Set(set.weekdayCaption.components(separatedBy: " · ")), Set(days[set] ?? []), "\(set) \(y)-\(m)")
            }
        }
    }

    func testDetailFactsHandleOldRecords() {
        let end = Date(timeIntervalSince1970: 1_800_000_000)
        let legacy = JourneyPrayerDetailFacts(mystery: nil, decade: nil, completedAt: end, startedAt: nil, duration: nil)
        XCTAssertEqual(legacy.title, "Rosary prayed")
        XCTAssertEqual(legacy.facts.first { $0.label == "Duration" }?.value, "Not recorded")
        XCTAssertEqual(legacy.facts.first { $0.label == "Started" }?.value, "Not recorded")

        let decade = JourneyPrayerDetailFacts(mystery: .sorrowful, decade: 3, completedAt: end, startedAt: nil, duration: 240)
        XCTAssertEqual(decade.title, "Sorrowful Mysteries")
        XCTAssertNotEqual(decade.facts.first { $0.label == "Duration" }?.value, "Not recorded")
        XCTAssertTrue(decade.facts.first { $0.label == "Decade" }?.value.hasPrefix("III") == true)
    }
}
