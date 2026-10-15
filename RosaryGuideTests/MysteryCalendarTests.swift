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

    func testHomeDefaultsToTheFeastSetAndCanSwitch() {
        let christmas = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 12, day: 25)!)
        XCTAssertEqual(christmas.set, .sorrowful) // the calendar keeps the weekday set
        XCTAssertEqual(christmas.defaultSet(prefersWeekday: false), .joyful)
        XCTAssertEqual(christmas.defaultSet(prefersWeekday: true), .sorrowful)
        XCTAssertEqual(christmas.shownSet(manual: nil, prefersWeekday: false), .joyful)
        XCTAssertEqual(christmas.shownSet(manual: .luminous, prefersWeekday: false), .luminous)
        XCTAssertEqual(christmas.shownSet(manual: .luminous, prefersWeekday: true), .luminous)
        XCTAssertEqual(christmas.feastRecommendationCaption, "The Nativity of the Lord recommends the Joyful Mysteries")
        XCTAssertEqual(christmas.weekdaySetButtonTitle, "Pray today's Sorrowful Mysteries instead")
        XCTAssertEqual(christmas.feastSetButtonTitle, "Pray the Joyful Mysteries for the Nativity of the Lord")
        for text in [christmas.feastRecommendationCaption!, christmas.weekdaySetButtonTitle, christmas.feastSetButtonTitle!] {
            XCTAssertFalse(text.hasSuffix("."))
        }
    }

    func testHomeKeepsWeekdaySetWhenFeastAgreesOrNoFeast() {
        // Assumption 2027 is a Sunday: Glorious either way, so no suggestion or caption.
        let assumption = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2027, month: 8, day: 15)!)
        XCTAssertNotNil(assumption.feast)
        XCTAssertNil(assumption.feastSuggestion)
        XCTAssertNil(assumption.feastRecommendationCaption)
        XCTAssertEqual(assumption.defaultSet(prefersWeekday: false), .glorious)
        // An ordinary Thursday with no feast.
        let plain = MysteryCalendar.assignment(on: LiturgicalCalendar.date(year: 2026, month: 9, day: 17)!)
        XCTAssertEqual(plain.defaultSet(prefersWeekday: false), .luminous)
        XCTAssertNil(plain.feastSetButtonTitle)
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
        XCTAssertEqual(partial.translation, .rsv2ce)
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
