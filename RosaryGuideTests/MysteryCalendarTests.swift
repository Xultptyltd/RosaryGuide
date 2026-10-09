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
