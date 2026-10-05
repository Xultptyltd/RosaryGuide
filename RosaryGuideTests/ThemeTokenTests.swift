import XCTest
import SwiftUI
import UIKit
@testable import RosaryGuide

final class ThemeTokenTests: XCTestCase {
    func testHomeTitleSizeMatchesWebsiteClamp() {
        XCTAssertEqual(AppTheme.homeTitleSize(width: 320), 38.4, accuracy: 0.05)
        XCTAssertEqual(AppTheme.homeTitleSize(width: 390), 390 * 0.115, accuracy: 0.05)
        XCTAssertEqual(AppTheme.homeTitleSize(width: 430), min(430 * 0.115, 56), accuracy: 0.05)
        XCTAssertEqual(AppTheme.homeTitleSize(width: 800), 56, accuracy: 0.05)
    }

    func testSectionTitleGapIsTwentyFour() {
        XCTAssertEqual(AppTheme.sectionTitleGap, 24)
        XCTAssertEqual(AppTheme.sectionTitleGap, AppTheme.Space.xl)
    }

    func testGutterIsSixteenEverywhere() {
        XCTAssertEqual(AppTheme.gutter, 16)
        XCTAssertEqual(AppTheme.gutterCompact, 16)
        XCTAssertEqual(AppTheme.Space.lg, 16)
        XCTAssertEqual(AppTheme.gutter(for: 320), 16)
        XCTAssertEqual(AppTheme.gutter(for: 376), 16)
        XCTAssertEqual(AppTheme.gutter(for: 390), 16)
    }

    func testHeroHeightClampedToWebsiteBand() {
        XCTAssertEqual(AppTheme.heroHeight(viewport: 200), 384)
        XCTAssertEqual(AppTheme.heroHeight(viewport: 2000), 544)
        XCTAssertEqual(AppTheme.heroHeight(viewport: 700), 392, accuracy: 0.5)
    }

    func testSheetOverlapMatchesWebsite() {
        XCTAssertEqual(AppTheme.sheetOverlap, 56)
        XCTAssertEqual(AppTheme.gutter, AppTheme.Space.lg)
    }

    func testGroupedSurfaceAliasesUseSingleToken() {
        let palette = ThemePalette(scheme: .light)

        XCTAssertEqual(UIColor(palette.surface), UIColor(palette.panel))
        XCTAssertEqual(UIColor(palette.surface), UIColor(palette.card))
        XCTAssertEqual(UIColor(palette.surface), UIColor(palette.card2))
    }

    func testSurfaceAndButtonColorTokens() {
        let light = ThemePalette(scheme: .light)
        let dark = ThemePalette(scheme: .dark)

        XCTAssertEqual(UIColor(light.surface), UIColor(Color(hex: 0xF0F1F4)))
        XCTAssertEqual(UIColor(dark.surface), UIColor(Color(hex: 0x1E2024)))
        XCTAssertEqual(UIColor(light.bg), UIColor(Color(hex: 0xFEFEFE)))
        XCTAssertEqual(UIColor(dark.bg), UIColor(Color(hex: 0x090A0C)))
        XCTAssertEqual(UIColor(light.prayBg), UIColor(light.bg))
        XCTAssertEqual(UIColor(dark.prayBg), UIColor(dark.bg))

        XCTAssertEqual(UIColor(light.primaryButtonFill), UIColor(Color(hex: 0x0054FF)))
        XCTAssertEqual(UIColor(dark.primaryButtonFill), UIColor(Color(hex: 0x0054FF)))

        XCTAssertEqual(UIColor(light.secondaryButtonFill), UIColor(Color.black))
        XCTAssertEqual(UIColor(dark.secondaryButtonFill), UIColor(Color.white))
        XCTAssertEqual(UIColor(light.secondaryButtonText), UIColor(Color.white))
        XCTAssertEqual(UIColor(dark.secondaryButtonText), UIColor(Color.black))
        XCTAssertEqual(UIColor(light.learnMoreButtonFill), UIColor(light.secondaryButtonFill))
        XCTAssertEqual(UIColor(dark.learnMoreButtonFill), UIColor(dark.secondaryButtonFill))
        XCTAssertEqual(UIColor(light.learnMoreButtonText), UIColor(light.secondaryButtonText))
        XCTAssertEqual(UIColor(dark.learnMoreButtonText), UIColor(dark.secondaryButtonText))
        XCTAssertEqual(UIColor(light.tertiaryButtonFill), UIColor(light.surface))
        XCTAssertEqual(UIColor(dark.tertiaryButtonFill), UIColor(dark.surface))
        XCTAssertEqual(UIColor(light.buttonTertiaryFill), UIColor(light.surface))
        XCTAssertEqual(UIColor(dark.buttonTertiaryFill), UIColor(dark.surface))
    }


    func testCoreComponentMeasurementsStayOnGrid() {
        let measurements: [CGFloat] = [
            AppTheme.gutter,
            AppTheme.Space.xs,
            AppTheme.Space.sm,
            AppTheme.Space.md,
            AppTheme.Space.lg,
            AppTheme.Space.xl,
            AppTheme.Space.xxl,
            AppTheme.containerRadius,
            AppTheme.nestedRadius,
            AppTheme.Component.pillHeight,
            AppTheme.Component.segmentedControlHeight,
            AppTheme.Component.profileRowHeight,
            AppTheme.Accessibility.minHitTarget
        ]

        for measurement in measurements {
            XCTAssertEqual(measurement.truncatingRemainder(dividingBy: 4), 0, "\(measurement) is off the 4pt grid")
        }
    }

    func testTouchTargetsMeetAppleMinimum() {
        XCTAssertGreaterThanOrEqual(AppTheme.Accessibility.minHitTarget, 44)
        XCTAssertGreaterThanOrEqual(AppTheme.Component.pillHeight, AppTheme.Accessibility.minHitTarget)
        XCTAssertGreaterThanOrEqual(AppTheme.Component.profileRowHeight, AppTheme.Accessibility.minHitTarget)
    }

    func testMysterySetLetterIconsAndColourMapping() {
        XCTAssertEqual(MysterySetKind.joyful.letter, "J")
        XCTAssertEqual(MysterySetKind.luminous.letter, "L")
        XCTAssertEqual(MysterySetKind.sorrowful.letter, "S")
        XCTAssertEqual(MysterySetKind.glorious.letter, "G")

        // Documented mapping: Joyful→green, Luminous→blue, Sorrowful→purple, Glorious→peach.
        XCTAssertEqual(UIColor(MysterySetKind.joyful.letterFill), UIColor(AppTheme.intentionMintGreen))
        XCTAssertEqual(UIColor(MysterySetKind.luminous.letterFill), UIColor(AppTheme.intentionSkyBlue))
        XCTAssertEqual(UIColor(MysterySetKind.sorrowful.letterFill), UIColor(AppTheme.intentionPurple))
        XCTAssertEqual(UIColor(MysterySetKind.glorious.letterFill), UIColor(AppTheme.intentionPeach))
        XCTAssertEqual(UIColor(MysterySetKind.joyful.letterOn), UIColor(AppTheme.intentionMintGreenOn))
        XCTAssertEqual(UIColor(MysterySetKind.luminous.letterOn), UIColor(AppTheme.intentionSkyBlueOn))
        XCTAssertEqual(UIColor(MysterySetKind.sorrowful.letterOn), UIColor(AppTheme.intentionPurpleOn))
        XCTAssertEqual(UIColor(MysterySetKind.glorious.letterOn), UIColor(AppTheme.intentionPeachOn))
    }
}

/// Circle-to-button control on scrolling prayers.
final class ScrollMorphTests: XCTestCase {
    func testShortOverflowCollapsesWhenScrolledBackUp() {
        // A 60pt scroll range could never collapse with a fixed 112pt gap.
        let atBottom = ScrollMorph.resolve(locked: false, armed: false, y: 60, maxOffset: 60)
        XCTAssertTrue(atBottom.locked)
        let backUp = ScrollMorph.resolve(locked: true, armed: false, y: 0, maxOffset: 60)
        XCTAssertFalse(backUp.locked)
    }

    func testTapScrollIsNotCancelledOnTheWayDown() {
        let midway = ScrollMorph.resolve(locked: true, armed: true, y: 100, maxOffset: 600)
        XCTAssertTrue(midway.locked)
        XCTAssertTrue(midway.armed)
        let arrived = ScrollMorph.resolve(locked: true, armed: true, y: 600, maxOffset: 600)
        XCTAssertTrue(arrived.locked)
        XCTAssertFalse(arrived.armed)
    }

    func testFullCycleRepeats() {
        var state = (locked: false, armed: false)
        for _ in 0..<3 {
            state = ScrollMorph.resolve(locked: state.locked, armed: state.armed, y: 400, maxOffset: 400)
            XCTAssertTrue(state.locked)
            state = ScrollMorph.resolve(locked: state.locked, armed: state.armed, y: 50, maxOffset: 400)
            XCTAssertFalse(state.locked)
        }
    }

    func testTopOfLongPrayerStaysACircle() {
        let top = ScrollMorph.resolve(locked: false, armed: false, y: 0, maxOffset: 900)
        XCTAssertFalse(top.locked)
    }
}

final class VersicleLineTests: XCTestCase {
    func testResponseStartsItsOwnLine() {
        let english = PrayerCatalog.versicle.text.english
        XCTAssertEqual(
            BilingualStack.joinedLines(english),
            "V. Pray for us, O holy Mother of God.\nR. That we may be made worthy of the promises of Christ."
        )
        let latin = PrayerCatalog.versicle.text.latin
        XCTAssertTrue(BilingualStack.joinedLines(latin).contains("Genetrix.\nR. Ut digni"))
    }

    func testOrdinaryLinesStillJoin() {
        XCTAssertEqual(BilingualStack.joinedLines("Hail Mary,\nfull of grace"), "Hail Mary, full of grace")
    }
}
