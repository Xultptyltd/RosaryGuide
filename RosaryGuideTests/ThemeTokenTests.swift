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

        XCTAssertEqual(UIColor(light.surface), UIColor(Color(hex: 0xF4F5F7)))
        XCTAssertEqual(UIColor(dark.surface), UIColor(Color(hex: 0x191B1E)))
        XCTAssertEqual(UIColor(light.bg), UIColor(Color(hex: 0xFEFEFE)))
        XCTAssertEqual(UIColor(dark.bg), UIColor(Color(hex: 0x090A0C)))
        XCTAssertEqual(UIColor(light.prayBg), UIColor(light.bg))
        XCTAssertEqual(UIColor(dark.prayBg), UIColor(dark.bg))

        XCTAssertEqual(UIColor(light.primaryButtonFill), UIColor(Color(hex: 0x0054FF)))
        XCTAssertEqual(UIColor(dark.primaryButtonFill), UIColor(Color(hex: 0x568AF8)))

        XCTAssertEqual(UIColor(light.secondaryButtonFill), UIColor(Color.black))
        XCTAssertEqual(UIColor(dark.secondaryButtonFill), UIColor(Color.white))
        XCTAssertEqual(UIColor(light.secondaryButtonText), UIColor(Color.white))
        XCTAssertEqual(UIColor(dark.secondaryButtonText), UIColor(Color.black))
        XCTAssertEqual(UIColor(light.learnMoreButtonFill), UIColor(light.secondaryButtonFill))
        XCTAssertEqual(UIColor(dark.learnMoreButtonFill), UIColor(dark.secondaryButtonFill))
        XCTAssertEqual(UIColor(light.learnMoreButtonText), UIColor(light.secondaryButtonText))
        XCTAssertEqual(UIColor(dark.learnMoreButtonText), UIColor(dark.secondaryButtonText))
    }
}
