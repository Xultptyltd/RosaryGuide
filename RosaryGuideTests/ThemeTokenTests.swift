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

    func testSectionTitleGapIsTwenty() {
        XCTAssertEqual(AppTheme.sectionTitleGap, 20)
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

        XCTAssertEqual(UIColor(light.surface), UIColor(Color(hex: 0xEBEBED)))
        XCTAssertEqual(UIColor(dark.surface), UIColor(Color(hex: 0x1C1C1E)))
        XCTAssertEqual(UIColor(light.bg), UIColor(Color(hex: 0xFFFFFF)))
        XCTAssertEqual(UIColor(light.groupedBackground), UIColor(Color(hex: 0xF8F8FA)))
        XCTAssertEqual(UIColor(dark.groupedBackground), UIColor(dark.bg))
        XCTAssertEqual(UIColor(light.cardSurface(on: .grouped)), UIColor(Color.white))
        XCTAssertEqual(UIColor(light.cardSurface(on: .plain)), UIColor(Color(hex: 0xF2F3F7)))
        XCTAssertEqual(UIColor(dark.cardSurface(on: .plain)), UIColor(dark.surface))
        XCTAssertEqual(UIColor(dark.cardSurface(on: .grouped)), UIColor(dark.surface))
        XCTAssertEqual(UIColor(dark.sectionDivider), UIColor(dark.surface))
        XCTAssertEqual(UIColor(dark.bg), UIColor(Color(hex: 0x000000)))
        // Dark cards: solid #1C1C1E with a faint white rim on the black page.
        XCTAssertEqual(UIColor(dark.cardSurfaceStroke), UIColor(Color.white.opacity(0.07)))
        XCTAssertEqual(UIColor(light.cardSurfaceStroke), UIColor(Color.black.opacity(0.08)))
        // Mystery icons: white glyph on solid Marian blue in both schemes.
        XCTAssertEqual(UIColor(light.mysteryIconFill), UIColor(Color(hex: 0x0054FF)))
        XCTAssertEqual(UIColor(dark.mysteryIconFill), UIColor(Color(hex: 0x0054FF)))
        // Emphasised pickers: white thumb with ink text in light; dark unchanged (ink thumb).
        XCTAssertEqual(UIColor(light.emphasisSegmentThumb), UIColor(Color.white))
        XCTAssertEqual(UIColor(light.emphasisSegmentTitle), UIColor(light.ink))
        XCTAssertEqual(UIColor(dark.emphasisSegmentThumb), UIColor(dark.ink))
        XCTAssertEqual(UIColor(dark.emphasisSegmentTitle), UIColor(dark.bg))
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
        XCTAssertEqual(UIColor(dark.tertiaryButtonFill), UIColor(Color(hex: 0x2C2C2E)))
        XCTAssertEqual(UIColor(light.buttonTertiaryFill), UIColor(light.surface))
        XCTAssertEqual(UIColor(dark.buttonTertiaryFill), UIColor(dark.tertiaryButtonFill))
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

        // Every mystery icon uses the Joyful fill; the glyph letter identifies the set.
        for set in MysterySetKind.allCases {
            XCTAssertEqual(UIColor(set.letterFill), UIColor(AppTheme.mysteryJoyful))
            XCTAssertEqual(UIColor(set.letterOn), UIColor(AppTheme.mysteryOn))
        }
    }

    func testIntentionCategoryAvatarColours() {
        // mintGreen = Personal, skyBlue = Someone else, purple = Church & world.
        XCTAssertEqual(UIColor(IntentionAccent.mintGreen.color), UIColor(AppTheme.intentionPersonal))
        XCTAssertEqual(UIColor(IntentionAccent.skyBlue.color), UIColor(AppTheme.intentionSomeoneElse))
        XCTAssertEqual(UIColor(IntentionAccent.purple.color), UIColor(AppTheme.intentionChurch))
        XCTAssertEqual(UIColor(IntentionAccent.mintGreen.onColor), UIColor(AppTheme.intentionPersonalOn))
        XCTAssertEqual(UIColor(IntentionAccent.skyBlue.onColor), UIColor(AppTheme.intentionSomeoneElseOn))
        XCTAssertEqual(UIColor(IntentionAccent.purple.onColor), UIColor(AppTheme.intentionChurchOn))
    }

}

/// WCAG 2.x contrast for the colour tokens: text 4.5:1, icons 3:1.
final class ContrastTokenTests: XCTestCase {
    private func rgba(_ color: Color, over background: Color? = nil) -> (Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        guard a < 1, let background else { return (Double(r), Double(g), Double(b)) }
        let under = rgba(background)
        return (Double(r * a) + under.0 * Double(1 - a), Double(g * a) + under.1 * Double(1 - a), Double(b * a) + under.2 * Double(1 - a))
    }

    private func luminance(_ c: (Double, Double, Double)) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
    }

    private func ratio(_ fg: Color, _ bg: Color, under: Color? = nil) -> Double {
        let back = rgba(bg, over: under)
        let front = rgba(fg, over: nil)
        let la = luminance(front), lb = luminance(back)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private let palettes: [ThemePalette] = [
        ThemePalette(scheme: .light), ThemePalette(scheme: .dark),
        ThemePalette(scheme: .light, contrast: .increased), ThemePalette(scheme: .dark, contrast: .increased)
    ]

    func testCompletionFollowsPrayerAppearance() {
        for palette in palettes {
            XCTAssertEqual(UIColor(palette.completionBackground), UIColor(palette.prayBg))
            XCTAssertEqual(UIColor(palette.completionTitle), UIColor(palette.textPrimary))
            XCTAssertGreaterThanOrEqual(ratio(palette.completionLabel, palette.completionBackground), 4.5)
            XCTAssertGreaterThanOrEqual(ratio(palette.completionMetaValue, palette.surface), 4.5)
        }
        XCTAssertNotEqual(
            UIColor(ThemePalette(scheme: .light).completionBackground),
            UIColor(ThemePalette(scheme: .dark).completionBackground)
        )
    }

    func testTextTokensReachFourAndAHalf() {
        for p in palettes {
            for bg in [p.bg, p.groupedBackground, p.surface] {
                let where_ = "\(p.scheme) \(p.contrast)"
                XCTAssertGreaterThanOrEqual(ratio(p.ink, bg), 4.5, where_)
                XCTAssertGreaterThanOrEqual(ratio(p.textSecondary, bg), 4.5, "secondary \(where_)")
                XCTAssertGreaterThanOrEqual(ratio(p.accentText, bg), 4.5, "accent text \(where_)")
                XCTAssertGreaterThanOrEqual(ratio(p.destructive, bg), 4.5, "destructive \(where_)")
            }
            XCTAssertGreaterThanOrEqual(ratio(p.onAccent, p.accent), 4.5, "button text")
            for page in [p.bg, p.groupedBackground, p.cardSurface(on: .grouped), p.cardSurface(on: .plain)] {
                XCTAssertGreaterThanOrEqual(ratio(p.stepNumberText, p.stepNumberFill, under: page), 4.5, "step number")
            }
            XCTAssertGreaterThanOrEqual(ratio(p.tertiaryButtonText, p.tertiaryButtonFill), 4.5, "tertiary button")
            XCTAssertGreaterThanOrEqual(ratio(p.completionMeta, p.completionBackground), 4.5, "completion meta")
        }
    }

    func testIconTokensReachThree() {
        for p in palettes {
            for bg in [p.bg, p.surface] {
                XCTAssertGreaterThanOrEqual(ratio(p.feastIndicator, bg), 3, "crown \(p.scheme)")
                XCTAssertGreaterThanOrEqual(ratio(p.accentText, p.accentTint, under: bg), 3, "glyph on tint \(p.scheme)")
                XCTAssertGreaterThanOrEqual(ratio(p.mysteryIconGlyph, p.mysteryIconFill, under: bg), 3, "mystery icon \(p.scheme)")
            }
        }
    }

    /// Apple: black button on light pages, white on dark. Google: its light and dark themes.
    func testSignInButtonsFollowProviderBranding() {
        let light = ThemePalette(scheme: .light)
        let dark = ThemePalette(scheme: .dark)
        XCTAssertEqual(UIColor(light.appleButtonFill), UIColor(Color.black))
        XCTAssertEqual(UIColor(light.appleButtonText), UIColor(Color.white))
        XCTAssertEqual(UIColor(dark.appleButtonFill), UIColor(Color.white))
        XCTAssertEqual(UIColor(dark.appleButtonText), UIColor(Color.black))
        XCTAssertEqual(UIColor(light.googleButtonFill), UIColor(Color.white))
        XCTAssertEqual(UIColor(light.googleButtonStroke), UIColor(Color(hex: 0x747775)))
        XCTAssertEqual(UIColor(light.googleButtonText), UIColor(Color(hex: 0x1F1F1F)))
        XCTAssertEqual(UIColor(dark.googleButtonFill), UIColor(Color(hex: 0x131314)))
        XCTAssertEqual(UIColor(dark.googleButtonStroke), UIColor(Color(hex: 0x8E918F)))
        XCTAssertEqual(UIColor(dark.googleButtonText), UIColor(Color(hex: 0xE3E3E3)))
        for palette in [light, dark] {
            XCTAssertGreaterThanOrEqual(ratio(palette.googleButtonText, palette.googleButtonFill), 4.5)
            XCTAssertGreaterThanOrEqual(ratio(palette.appleButtonText, palette.appleButtonFill), 4.5)
            // Legal links and footnote on the sign-in page.
            XCTAssertGreaterThanOrEqual(ratio(palette.dim, palette.bg), 4.5)
        }
    }

    func testDarkSelectedTabLabelOnGlassPill() {
        // #3D3E3F: the selected glass pill measured from a dark-mode screenshot.
        XCTAssertGreaterThanOrEqual(ratio(ThemePalette(scheme: .dark).tabSelected, Color(hex: 0x3D3E3F)), 4.5)
    }

    func testFillsKeepMarianBlue() {
        XCTAssertEqual(UIColor(ThemePalette(scheme: .dark).accent), UIColor(Color(hex: 0x0054FF)))
        XCTAssertEqual(UIColor(ThemePalette(scheme: .dark).accentText), UIColor(Color(hex: 0x3D7DFF)))
        XCTAssertEqual(UIColor(ThemePalette(scheme: .light).accentText), UIColor(Color(hex: 0x0054FF)))
        XCTAssertEqual(UIColor(ThemePalette(scheme: .light).textSecondary), UIColor(Color(hex: 0x6A6A6A)))
        XCTAssertEqual(UIColor(ThemePalette(scheme: .light).destructive), UIColor(Color(hex: 0xC92E25)))
    }
}

final class QuoteCatalogTests: XCTestCase {
    func testEveryCompletionQuoteIsShown() {
        XCTAssertEqual(QuoteCatalog.all.count, 14)
        XCTAssertEqual(QuoteCatalog.all.first?.id, "montfort-treasure")
        XCTAssertEqual(QuoteCatalog.shortQuotes.count, QuoteCatalog.all.count)
        XCTAssertEqual(QuoteCatalog.maxCompletionCharacters, QuoteCatalog.all.map(\.text.count).max())
        XCTAssertEqual(Set(QuoteCatalog.all.map(\.id)).count, QuoteCatalog.all.count)
    }

    func testCompletionQuotesCycleThroughAllBeforeRepeating() {
        let defaults = UserDefaults(suiteName: "QuoteCatalogTests")!
        defaults.removePersistentDomain(forName: "QuoteCatalogTests")
        let count = QuoteCatalog.all.count
        let firstRound = (0..<count).map { _ in QuoteCatalog.freshCompletionQuote(defaults: defaults).id }
        XCTAssertEqual(Set(firstRound).count, count)
        let secondRound = (0..<count).map { _ in QuoteCatalog.freshCompletionQuote(defaults: defaults).id }
        XCTAssertEqual(secondRound, firstRound)
    }

    func testSelectingWithoutRememberingDoesNotAdvance() {
        let defaults = UserDefaults(suiteName: "QuoteCatalogTests.select")!
        defaults.removePersistentDomain(forName: "QuoteCatalogTests.select")
        let a = QuoteCatalog.selectCompletionQuote(defaults: defaults)
        XCTAssertEqual(QuoteCatalog.selectCompletionQuote(defaults: defaults).id, a.id)
    }

    func testMigratesFromLastShownQuote() {
        let defaults = UserDefaults(suiteName: "QuoteCatalogTests.migrate")!
        defaults.removePersistentDomain(forName: "QuoteCatalogTests.migrate")
        defaults.set(QuoteCatalog.all[3].id, forKey: "rosary.completion.lastQuoteId")
        XCTAssertEqual(QuoteCatalog.selectCompletionQuote(defaults: defaults).id, QuoteCatalog.all[4].id)
        defaults.set("removed-quote", forKey: "rosary.completion.lastQuoteId")
        XCTAssertEqual(QuoteCatalog.selectCompletionQuote(defaults: defaults).id, QuoteCatalog.all[0].id)
    }
}

/// Circle-to-button control on scrolling prayers.
final class ScrollMorphTests: XCTestCase {
    /// Measured on the simulator: Creed under the 172pt header bar.
    func testPositionUnderHeaderBarReachesTheBottom() {
        let top = ScrollMorph.position(offsetY: -172, insetTop: 172, contentHeight: 1349.7, containerHeight: 668)
        XCTAssertEqual(top.y, 0, accuracy: 0.01)
        XCTAssertEqual(top.maxOffset, 681.7, accuracy: 0.01)
        let bottom = ScrollMorph.position(offsetY: 509.7, insetTop: 172, contentHeight: 1349.7, containerHeight: 668)
        XCTAssertEqual(bottom.y, bottom.maxOffset, accuracy: 0.01)
        XCTAssertTrue(ScrollMorph.resolve(locked: false, armed: false, y: bottom.y, maxOffset: bottom.maxOffset).locked)
    }

    /// Walkthrough page that fits: a top inset must not invent a scroll range.
    func testShortContentHasNoRange() {
        let fits = ScrollMorph.position(offsetY: -62, insetTop: 62, contentHeight: 812, containerHeight: 812)
        XCTAssertEqual(fits.maxOffset, 0)
        XCTAssertEqual(fits.y, 0)
        // No range: state is left alone (callers show the full button).
        XCTAssertFalse(ScrollMorph.resolve(locked: false, armed: false, y: 0, maxOffset: 0).locked)
    }

    func testRubberBandIsClamped() {
        let overBottom = ScrollMorph.position(offsetY: 700, insetTop: 0, contentHeight: 1000, containerHeight: 600)
        XCTAssertEqual(overBottom.y, 400)
        let overTop = ScrollMorph.position(offsetY: -90, insetTop: 0, contentHeight: 1000, containerHeight: 600)
        XCTAssertEqual(overTop.y, 0)
    }

    func testThresholdAndHysteresis() {
        let maxOffset: CGFloat = 400
        let expandAt = maxOffset - ScrollMorph.expandGap(maxOffset)
        XCTAssertTrue(ScrollMorph.resolve(locked: false, armed: false, y: expandAt, maxOffset: maxOffset).locked)
        XCTAssertFalse(ScrollMorph.resolve(locked: false, armed: false, y: expandAt - 1, maxOffset: maxOffset).locked)
        // Between the lines nothing changes either way: no oscillation.
        let between = expandAt - 20
        XCTAssertTrue(ScrollMorph.resolve(locked: true, armed: false, y: between, maxOffset: maxOffset).locked)
        XCTAssertFalse(ScrollMorph.resolve(locked: false, armed: false, y: between, maxOffset: maxOffset).locked)
        // Collapses once well back up.
        let collapseAt = maxOffset - ScrollMorph.collapseGap(maxOffset)
        XCTAssertFalse(ScrollMorph.resolve(locked: true, armed: false, y: collapseAt - 1, maxOffset: maxOffset).locked)
    }

    func testTinyRangeIsIgnored() {
        XCTAssertFalse(ScrollMorph.resolve(locked: false, armed: false, y: 6, maxOffset: ScrollMorph.minimumOffset).locked)
    }

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

final class LicenseTextTests: XCTestCase {
    func testJoinsHardWrappedLinesButKeepsTitlesAndListItems() {
        let raw = """
                                 Apache License
                           Version 2.0, January 2004

        Permission is hereby granted, free of charge, to any person obtaining a copy of
        this software and associated documentation files (the "Software"), to deal in
        the Software without restriction.

        1. The origin of this software must not be misrepresented; you must not claim
           that you wrote the original software.
        2. Altered source versions must be plainly marked as such, and must not be
           misrepresented as being the original software.

        ================================================================================
        """
        let text = LicenseText.reflow(raw)
        XCTAssertTrue(text.hasPrefix("Apache License\nVersion 2.0, January 2004\n\n"))
        XCTAssertTrue(text.contains("obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction."))
        XCTAssertTrue(text.contains("must not claim that you wrote the original software.\n2. Altered"))
        XCTAssertTrue(text.hasSuffix("\n\n================================================================================"))
    }

    func testBundledLicencesAreSortedAndNonEmpty() {
        let names = LicenseCatalog.all.map(\.name)
        XCTAssertEqual(names, names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        XCTAssertTrue(LicenseCatalog.all.allSatisfy { !$0.license.isEmpty })
    }
}

final class CompletionScreenTests: XCTestCase {
    /// The Complete screen never repeats Home's hero: every day of the year, every set,
    /// both themes, the plate path differs from the hero path and the file exists in the set.
    func testCompletionArtNeverMatchesHomeHero() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Australia/Perth")!
        let start = cal.date(from: DateComponents(year: 2028, month: 1, day: 1))!
        for offset in 0..<366 {
            let date = cal.date(byAdding: .day, value: offset, to: start)!
            for set in MysterySetKind.allCases {
                let plate = ArtCatalog.completionPlate(set: set, date: date, calendar: cal)
                XCTAssertTrue(ArtCatalog.plateSlugs(set: set).contains(plate.slug))
                for scheme in [ColorScheme.light, .dark] {
                    let hero = ArtCatalog.heroPath(set: set, scheme: scheme, tall: true)
                    let art = ArtCatalog.platePath(set: set, slug: plate.slug, scheme: scheme, wide: false)
                    XCTAssertNotEqual("\(hero.directory)/\(hero.name)", "\(art.directory)/\(art.name)")
                }
            }
        }
    }

    func testCompletionPlatesExistInBundle() {
        for set in MysterySetKind.allCases {
            for slug in ArtCatalog.plateSlugs(set: set) {
                let path = ArtCatalog.platePath(set: set, slug: slug, scheme: .dark, wide: false)
                XCTAssertNotNil(BundleRasterImage.load(directory: path.directory, name: path.name, ext: "jpg"), slug)
            }
        }
    }

    func testOfferedLabelAndVoiceOver() {
        XCTAssertEqual(CompletionCopy.offeredLabel, "Offered for")
        XCTAssertTrue(CompletionCopy.showsQuote(intentionCount: 0))
        XCTAssertFalse(CompletionCopy.showsQuote(intentionCount: 1))
        XCTAssertFalse(CompletionCopy.showsQuote(intentionCount: 5))
        XCTAssertEqual(CompletionCopy.cardLabel(index: 1, count: 3, title: "Mum"), "Intention 2 of 3: Mum")
        XCTAssertEqual(CompletionCopy.cardLabel(index: 0, count: 1, title: "Mum"), "Offered for Mum")
    }
}

final class FeastHeroFramingTests: XCTestCase {
    /// Home feast card (height 176): the whole file fits, pinned to the top.
    /// Side slack is centered. A narrow subject does not zoom.
    func testHomeCardFitsTheWholeFileFromTheTop() {
        let image = CGSize(width: 1280, height: 720)
        let frame = CGSize(width: 358, height: 176)
        let cover = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 480, y: 0, width: 300, height: 720),
            focusX: 630
        )
        assertFitsWholeFile(cover: cover, image: image, frame: frame)
        XCTAssertEqual(cover.scale, frame.height / image.height, accuracy: 0.0001)
        XCTAssertGreaterThan(cover.offset.width, 0)
        XCTAssertLessThan(cover.scale, frame.width / 300)
    }

    /// Detail banner is taller than the 16:9 file. Width fits, the full height
    /// stays inside the frame, and the image stays pinned to the top.
    func testTallBannerFitsTheWholeFileFromTheTop() {
        let image = CGSize(width: 1280, height: 720)
        let frame = CGSize(width: 393, height: 330)
        let cover = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 12, y: 144, width: 1256, height: 540),
            focusX: 314
        )
        assertFitsWholeFile(cover: cover, image: image, frame: frame)
        XCTAssertEqual(cover.scale, frame.width / image.width, accuracy: 0.0001)
        XCTAssertEqual(cover.offset.width, 0, accuracy: 0.01)
        XCTAssertLessThan(image.height * cover.scale, frame.height - 1)
    }

    func testSecondaryBannerFitsTheWholeFile() {
        let image = CGSize(width: 1280, height: 720)
        let frame = CGSize(width: 393, height: 238)
        let cover = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 0, y: 0, width: 1280, height: 720),
            focusX: 640
        )
        assertFitsWholeFile(cover: cover, image: image, frame: frame)
        XCTAssertEqual(cover.scale, frame.width / image.width, accuracy: 0.0001)
    }

    /// Subject bounds and focus never tighten the scale or slide the file into a crop.
    func testSubjectAndFocusDoNotZoomOrCrop() {
        let image = CGSize(width: 1280, height: 720)
        let frame = CGSize(width: 200, height: 400)
        let wide = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 0, y: 0, width: 1280, height: 720),
            focusX: 640
        )
        let tight = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 240, y: 100, width: 200, height: 400),
            focusX: 80
        )
        let side = ArtCatalog.feastCover(
            imageSize: image,
            frame: frame,
            subject: CGRect(x: 900, y: 40, width: 360, height: 640),
            focusX: 1200
        )
        XCTAssertEqual(wide, tight)
        XCTAssertEqual(wide, side)
        assertFitsWholeFile(cover: wide, image: image, frame: frame)
        XCTAssertEqual(wide.scale, frame.width / image.width, accuracy: 0.0001)
        XCTAssertLessThan(wide.scale, frame.width / 200)
    }

    /// Scale is the fit ratio. The placed image is the entire file, inside the frame, top-pinned.
    private func assertFitsWholeFile(cover: ArtCatalog.FeastCover, image: CGSize, frame: CGSize, file: StaticString = #filePath, line: UInt = #line) {
        let scale = min(frame.width / image.width, frame.height / image.height)
        XCTAssertEqual(cover.scale, scale, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(cover.offset.height, 0, accuracy: 0.0001, file: file, line: line)
        let fittedW = image.width * cover.scale
        let fittedH = image.height * cover.scale
        XCTAssertLessThanOrEqual(fittedW, frame.width + 0.01, file: file, line: line)
        XCTAssertLessThanOrEqual(fittedH, frame.height + 0.01, file: file, line: line)
        XCTAssertTrue(
            abs(fittedW - frame.width) < 0.01 || abs(fittedH - frame.height) < 0.01,
            "fit meets the frame on width or height",
            file: file,
            line: line
        )
        let expectedX = max(0, (frame.width - fittedW) / 2)
        XCTAssertEqual(cover.offset.width, expectedX, accuracy: 0.01, file: file, line: line)
        let placed = CGRect(x: cover.offset.width, y: cover.offset.height, width: fittedW, height: fittedH)
        XCTAssertGreaterThanOrEqual(placed.minX, -0.01, file: file, line: line)
        XCTAssertEqual(placed.minY, 0, accuracy: 0.0001, file: file, line: line)
        XCTAssertLessThanOrEqual(placed.maxX, frame.width + 0.01, file: file, line: line)
        XCTAssertLessThanOrEqual(placed.maxY, frame.height + 0.01, file: file, line: line)
    }

    func testDetectorFindsAMarkAtTheTopNotTheBottom() {
        let mark = CGRect(x: 16, y: 10, width: 40, height: 36)
        let image = raster(size: CGSize(width: 320, height: 180), fill: .white, marks: [(mark, .black)])
        let subject = ArtCatalog.feastSubject(of: image)
        XCTAssertLessThan(subject.bounds.minY, 30, "the mark is at the top of the image")
        XCTAssertGreaterThan(subject.bounds.maxY, mark.maxY - 8)
        XCTAssertLessThan(subject.bounds.maxY, 80)
        XCTAssertGreaterThan(subject.bounds.minX, 4)
        XCTAssertLessThan(subject.bounds.maxX, 80)
        XCTAssertEqual(subject.focusX, mark.midX, accuracy: 12)
    }

    func testDetectorFindsALightFigureOnBlack() {
        let mark = CGRect(x: 200, y: 20, width: 48, height: 140)
        let image = raster(size: CGSize(width: 320, height: 180), fill: .black, marks: [(mark, .white)])
        let subject = ArtCatalog.feastSubject(of: image)
        XCTAssertGreaterThan(subject.bounds.minX, 170)
        XCTAssertLessThan(subject.bounds.maxX, 270)
        XCTAssertLessThan(subject.bounds.minY, 36)
        XCTAssertGreaterThan(subject.bounds.maxY, 140)
    }

    func testUpperBandFocusFollowsTheHead() {
        let head = CGRect(x: 48, y: 24, width: 36, height: 50)
        let body = CGRect(x: 30, y: 70, width: 250, height: 100)
        let image = raster(
            size: CGSize(width: 320, height: 180),
            fill: .white,
            marks: [(body, .black), (head, .black)]
        )
        let subject = ArtCatalog.feastSubject(of: image)
        XCTAssertLessThan(subject.focusX, 140)
        XCTAssertGreaterThan(subject.focusX, 40)
    }

    private func raster(size: CGSize, fill: UIColor, marks: [(CGRect, UIColor)]) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            fill.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for (rect, color) in marks {
                color.setFill()
                ctx.fill(rect)
            }
        }
    }
}
