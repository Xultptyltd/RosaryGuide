import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Editorial utility design tokens.
enum AppTheme {
    /// The app's one explicit brand color. Everything else routes through
    /// Apple semantic colors so Light/Dark, contrast, and accessibility modes
    /// can do their work at the system layer.
    static let marianBlue = Color(hex: 0x0054FF)
    static let marianBlueHighContrast = Color(hex: 0x0054FF)
    static let marianBlueDark = marianBlue
    static let marianBlueDarkHighContrast = marianBlueHighContrast
    static let brandAccent = marianBlue
    static let brandAccentHighContrast = marianBlueHighContrast
    static let brandAccentDark = marianBlueDark
    static let brandAccentDarkHighContrast = marianBlueDarkHighContrast
    static let destructiveMenuRed = Color(hex: 0xFF3B30)
    /// Marian blue as text or a glyph (WCAG 4.5:1 text, 3:1 icons). #0054FF stays the fill
    /// and button colour; on dark backgrounds it is too dark to read as text (3.0:1).
    static let marianBlueDarkText = Color(hex: 0x3D7DFF)
    /// Increase Contrast text blues: ≥ 6:1 on the background and surface in each scheme.
    static let marianBlueTextHighContrast = Color(hex: 0x0040C8)
    static let marianBlueDarkTextHighContrast = Color(hex: 0x7DA8FF)
    /// Selected tab label on the dark glass tab bar: 4.5:1 on the selected pill (#3D3E3F).
    static let tabSelectedDark = Color(hex: 0x7DA8FF)
    /// Destructive text: 4.5:1 on background and surface (system red is 3.1:1 in light).
    static let destructiveLight = Color(hex: 0xCF3027)
    static let destructiveLightHighContrast = Color(hex: 0xD70015)
    static let destructiveDark = Color(hex: 0xFF453A)
    static let destructiveDarkHighContrast = Color(hex: 0xFF6961)
    /// Intention category avatar fills (same in light and dark).
    static let intentionPersonal = Color(hex: 0xA8DCCB)
    static let intentionSomeoneElse = Color(hex: 0xC9B6EF)
    static let intentionChurch = Color(hex: 0xADCFF0)
    /// Category-specific dark glyphs on the solid pastel intention fills.
    static let intentionPersonalOn = Color(hex: 0x183E35)
    static let intentionSomeoneElseOn = Color(hex: 0x38264F)
    static let intentionChurchOn = Color(hex: 0x203C57)

    /// Mystery-set colours (trial palette, same in light and dark). Separate from the
    /// intention avatar colours so intentions are unaffected.
    static let mysteryJoyful = Color(hex: 0x48A6FF)
    static let mysteryLuminous = Color(hex: 0x83C6FF)
    static let mysterySorrowful = Color(hex: 0xB5DBFF)
    static let mysteryGlorious = Color(hex: 0xD6EAFF)
    /// Glyph colour on every mystery fill: dark navy (6:1 on Joyful, higher on the rest).
    static let mysteryOn = Color(hex: 0x0A2540)

    /// Milestone category circles (same in light and dark), strongest to palest.
    /// Hexes shared with the mystery scale point at those tokens.
    static let milestoneRosaries = Color(hex: 0x1E83FF)
    static let milestonePrayerForOthers = mysteryJoyful
    static let milestoneMysterySets = mysteryLuminous
    static let milestoneDaysInPrayer = mysterySorrowful
    static let milestoneMarianFeasts = mysteryGlorious
    /// Navy glyph on every milestone circle (same as the mysteries).
    static let milestoneOn = mysteryOn

    /// Canonical page-edge horizontal inset. Matches `Space.lg` (16pt).
    /// Prefer `AppTheme.gutter` over literals at screen edges.
    static let gutter: CGFloat = 16
    /// Same as `gutter` — kept for call-site compatibility; no narrower phone override.
    static let gutterCompact: CGFloat = 16
    /// `.sheet { margin-top: -3.5rem }`
    static let sheetOverlap: CGFloat = 56
    /// `.hero` `clamp(24rem, 56svh, 34rem)` — 56svh leaves room for the native tab bar.
    static let heroMin: CGFloat = 384
    static let heroMax: CGFloat = 544
    static let titleLineHeight: CGFloat = 1.02
    static let sectionGap: CGFloat = 44
    /// Gap between a section title (GuideSectionLabel `.strong`) and the content directly below it.
    static let sectionTitleGap: CGFloat = 20
    static let containerRadius: CGFloat = 20
    /// Site `--r-feature` — Home mystery rail cards.
    static let featureRadius: CGFloat = 24
    static let nestedRadius: CGFloat = 12
    static var capsule: Capsule { Capsule(style: .continuous) }
    static let controlSize: CGFloat = 40
    /// Reserved bottom clearance for content behind the liquid tab bar.
    static let tabBarContentClearance: CGFloat = 108

    static func gutter(for width: CGFloat) -> CGFloat {
        // Single source of truth: always `gutter` (16pt), including compact widths.
        _ = width
        return gutter
    }

    static func heroHeight(viewport: CGFloat) -> CGFloat {
        min(max(heroMin, viewport * 0.56), heroMax)
    }

    /// Home has a selector + primary CTA above the fold, so its hero reserves
    /// more vertical space for controls above the tab bar. HomeView may add a
    /// small measured adjustment per device to place the CTA precisely.
    static func homeHeroHeight(viewport: CGFloat) -> CGFloat {
        min(max(320, viewport * 0.46), 464)
    }

    /// Mystery artwork extends beyond the screen midpoint before scripture begins.
    static let rosaryMysteryArtworkTopInset: CGFloat = 104
    static let rosaryMysteryArtworkBottomFraction: CGFloat = 0.58

    enum RosaryFlow {
        static let readingBottomPadding: CGFloat = 28
        static let prayerTitleBodyGap: CGFloat = 22
        static let announcementSpacing: CGFloat = 10
        static let eyebrowTracking: CGFloat = 2
        static let fruitTracking: CGFloat = 0.8
        static let resurrectionArtworkScale: CGFloat = 1.08
    }

    static func grid(_ value: CGFloat, minimum: CGFloat = 4) -> CGFloat {
        max(minimum, (value / 4).rounded() * 4)
    }

    /// `h1.title { font-size: clamp(2.7rem, 11.5vw, 3.5rem) }` with the 23.5rem small-phone override.
    static func homeTitleSize(width: CGFloat) -> CGFloat {
        if width <= 376 { return 38.4 }
        let vw = width * 0.115
        return min(max(43.2, vw), 56)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body, maxPointSize: CGFloat? = nil) -> Font {
        FontRegistrar.sans(size, weight: weight, relativeTo: textStyle, maxPointSize: maxPointSize)
    }

    static func serif(_ size: CGFloat, italic: Bool = false, opticalSize: CGFloat? = nil, relativeTo textStyle: Font.TextStyle = .body, maxPointSize: CGFloat? = nil) -> Font {
        FontRegistrar.serif(size, italic: italic, opticalSize: opticalSize, relativeTo: textStyle, maxPointSize: maxPointSize)
    }

    static func color(for season: LiturgicalSeason) -> Color {
        switch season {
        case .advent, .lent: Color(hex: 0x6B5B7A)
        case .christmas, .easter: Color(hex: 0xE8E4D8)
        case .ordinary: Color(hex: 0x5C6B58)
        case .triduum: Color(hex: 0x8A4A44)
        }
    }

}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// Adaptive sRGB colour that flips with light/dark interface style.
    init(light: UInt32, dark: UInt32, alpha: Double = 1) {
#if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: alpha
            )
        })
#else
        self.init(hex: light, alpha: alpha)
#endif
    }
}

struct ThemePalette {
    var scheme: ColorScheme
    var contrast: ColorSchemeContrast = .standard

    // MARK: Canonical foundation

    var background: Color {
        scheme == .light
            ? Color(hex: 0xFEFEFE)
            : Color(hex: 0x090A0C)
    }

    /// Resolved from the palette's own scheme, not `.primary`. `.primary` follows the
    /// hosting controller's trait, which can stay on the old scheme inside covers
    /// after switching Light/Dark -> System, while every other token follows
    /// `scheme`, leaving ink nearly the same colour as the background.
    var textPrimary: Color {
        scheme == .light ? Color(hex: 0x000000) : Color(hex: 0xFFFFFF)
    }
    /// The app's single secondary grey. Use this for all supporting,
    /// disabled-looking, metadata, and explanatory copy.
    var textSecondary: Color {
        // #6E6E6E: 4.5:1 on the light surface (#757575 was 4.1:1).
        scheme == .light ? Color(hex: 0x6E6E6E) : Color(hex: 0xAEAEAE)
    }

    /// The app's single grouped/elevated surface color.
    ///
    /// Keep cards, accordions, grouped rows, sheets, and compact panels on this
    /// token so the app does not accumulate slightly different cream/black
    /// surfaces across screens.
    var surface: Color {
        scheme == .light
            ? Color(hex: 0xF0F1F4)
            : Color(hex: 0x191B1E)
    }

    var accent: Color {
        switch (scheme, contrast) {
        case (.light, .increased): AppTheme.brandAccentHighContrast
        case (.dark, .increased): AppTheme.brandAccentDarkHighContrast
        case (.dark, _): AppTheme.brandAccentDark
        default: AppTheme.brandAccent
        }
    }
    var onAccent: Color { Color.white }
    /// Marian blue for text and glyphs. Fills, buttons and progress bars keep `accent`.
    var accentText: Color {
        switch (scheme, contrast) {
        case (.light, .increased): AppTheme.marianBlueTextHighContrast
        case (.dark, .increased): AppTheme.marianBlueDarkTextHighContrast
        case (.dark, _): AppTheme.marianBlueDarkText
        default: AppTheme.marianBlue
        }
    }
    /// Numbered step badges: text on a soft accent circle.
    var stepNumberText: Color {
        switch (scheme, contrast) {
        case (_, .increased): accentText
        case (.dark, _): Color(hex: 0x4A86FF)
        default: AppTheme.marianBlue
        }
    }
    var stepNumberFill: Color { accent.opacity(scheme == .dark ? 0.15 : 0.12) }
    /// Selected tab bar item (icon and label).
    var tabSelected: Color {
        switch (scheme, contrast) {
        case (.dark, _): AppTheme.tabSelectedDark
        case (.light, .increased): AppTheme.marianBlueTextHighContrast
        default: accent
        }
    }
    var destructive: Color {
        switch (scheme, contrast) {
        case (.light, .increased): AppTheme.destructiveLightHighContrast
        case (.dark, .increased): AppTheme.destructiveDarkHighContrast
        case (.dark, _): AppTheme.destructiveDark
        default: AppTheme.destructiveLight
        }
    }

    var buttonPrimaryFill: Color { accent }
    var buttonPrimaryText: Color { onAccent }
    var buttonSecondaryFill: Color { scheme == .dark ? Color.white : Color.black }
    var buttonSecondaryText: Color { scheme == .dark ? Color.black : Color.white }
    /// Quiet third action. Same fill as cards and grouped rows, not a new hue.
    var buttonTertiaryFill: Color { surface }
    var buttonTertiaryText: Color { scheme == .dark ? Color.white.opacity(0.96) : Color.black }
    var todayPillFill: Color { Color.white }
    var todayPillText: Color { Color.black }

    var strokeSubtle: Color { textPrimary.opacity(scheme == .light ? 0.07 : 0.12) }
    var strokeRegular: Color { textPrimary.opacity(scheme == .light ? 0.12 : 0.22) }
    var strokeStrong: Color { textPrimary.opacity(0.28) }
    var strokeSelected: Color { textPrimary.opacity(0.85) }

    var scrim: Color { Color.black }

    // MARK: Special domains

    var prayerBackground: Color { background }
    var artworkFallbackBackground: Color { Color(hex: 0x17181A) }
    /// Feast crown glyph: 3:1 on background and surface in both schemes.
    var feastIndicator: Color { scheme == .light ? Color(hex: 0xB08328) : Color(hex: 0xE2B75A) }
    var accentTint: Color {
        scheme == .dark
            ? accent.opacity(0.20)
            : accent.opacity(0.12)
    }
    /// Unselected segmented-control track. Keep this on the shared surface
    /// pathway so UIKit and custom segmented controls render the same surface.
    var segmentedControlTrack: Color { surface }
    var selectedControlFill: Color { Color(uiColor: .systemBackground) }
    var selectedShadow: Color { accent.opacity(0.28) }

    var ceremonyBackground: Color { Color(hex: 0x000000) }
    var ceremonyTextPrimary: Color { Color.white.opacity(0.96) }
    var ceremonyTextSecondary: Color { Color.white.opacity(0.48) }
    /// 46 %: 4.5:1 on the black ceremony background.
    var ceremonyTextTertiary: Color { Color.white.opacity(0.46) }

    var beadHighlight: Color { Color.white }
    var beadPulseFill: Color {
        scheme == .light
            ? accent.opacity(0.30)
            : accent.opacity(0.36)
    }
    var beadPulseStroke: Color {
        scheme == .light
            ? accent.opacity(0.68)
            : accent.opacity(0.78)
    }
    var beadMedalRim: Color {
        scheme == .light
            ? Color(hex: 0xC7C2B3)
            : Color(hex: 0x8C8C8C)
    }
    var beadMedalRimFuture: Color {
        scheme == .light
            ? beadMedalRim
            : Color(hex: 0x525252)
    }
    var beadMedalField: Color {
        scheme == .light
            ? Color(hex: 0x332E29)
            : Color(hex: 0x252525)
    }
    var beadMedalGlyph: Color {
        Color.white.opacity(scheme == .light ? 0.55 : 0.70)
    }
    var feastArtworkFallbackGradient: [Color] {
        scheme == .light
            ? [Color(hex: 0xE8E2D6), Color(hex: 0xD4CBB8)]
            : [Color(hex: 0x2A2620), Color(hex: 0x1A1713)]
    }

    // MARK: Compatibility aliases
    // Keep existing screen code readable while routing it through the smaller
    // design system above. New code should prefer the canonical names.

    var bg: Color { background }
    var prayBg: Color { prayerBackground }
    var ink: Color { textPrimary }
    var dim: Color { textSecondary }
    var secondaryText: Color { textSecondary }
    var faint: Color { textSecondary }
    var card: Color { surface }
    var card2: Color { surface }
    var panel: Color { surface }
    var hair: Color { Color(uiColor: .separator) }
    var primaryButtonFill: Color { buttonPrimaryFill }
    var primaryButtonText: Color { buttonPrimaryText }
    var secondaryButtonFill: Color { buttonSecondaryFill }
    var secondaryButtonText: Color { buttonSecondaryText }
    var tertiaryButtonFill: Color { buttonTertiaryFill }
    var tertiaryButtonText: Color { buttonTertiaryText }
    var learnMoreButtonFill: Color { buttonSecondaryFill }
    var learnMoreButtonText: Color { buttonSecondaryText }
    var fieldStroke: Color { strokeRegular }
    var selectionStroke: Color { strokeSubtle }
    var cardStroke: Color { strokeSubtle }
    var subtleStroke: Color { strokeSubtle }
    var strongStroke: Color { strokeStrong }
    var selectedSwatchStroke: Color { strokeSelected }
    var controlStroke: Color { Color(uiColor: .separator).opacity(0.55) }
    var completionBackground: Color { ceremonyBackground }
    var completionLabel: Color { ceremonyTextSecondary }
    var completionTitle: Color { ceremonyTextPrimary }
    var completionMeta: Color { ceremonyTextTertiary }
    var completionMetaValue: Color { ceremonyTextPrimary.opacity(0.94) }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette(scheme: .light, contrast: .standard)
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

struct ThemedRoot<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    var content: () -> Content

    var body: some View {
        let palette = ThemePalette(scheme: colorScheme, contrast: colorSchemeContrast)
        content()
            .environment(\.palette, palette)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.bg.ignoresSafeArea())
            .onAppear {
                GuideChrome.apply(palette)
            }
            .onChange(of: colorScheme) { _, newScheme in
                GuideChrome.apply(ThemePalette(scheme: newScheme, contrast: colorSchemeContrast))
            }
            .onChange(of: colorSchemeContrast) { _, newContrast in
                GuideChrome.apply(ThemePalette(scheme: colorScheme, contrast: newContrast))
            }
    }
}

/// Mirrors the Color theme onto every window's UIKit style. SwiftUI's
/// preferredColorScheme(nil) does not always clear a previous explicit override
/// (notably in presented covers), so System could keep the old scheme.
enum AppearanceWindowStyle {
    static func apply(_ appearance: AppearancePreference) {
        #if canImport(UIKit)
        let style: UIUserInterfaceStyle = switch appearance {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
        #endif
    }
}

/// iOS 26 SwiftUI navigation bars don't pick up `UINavigationBar.appearance()` title fonts
/// (the large title rendered as `.SFUI-Bold`), so set the H1 font on the hosting bar itself.
#if canImport(UIKit)
private struct GuideH1NavigationFont: UIViewControllerRepresentable {
    final class Probe: UIViewController {
        override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); apply() }
        override func didMove(toParent parent: UIViewController?) { super.didMove(toParent: parent); apply() }
        func apply() {
            guard let bar = navigationController?.navigationBar else { return }
            let font = AppTheme.TypeRole.h1UIFont(AppTheme.TypeRole.h1NavigationSize)
            func fix(_ a: UINavigationBarAppearance?) -> UINavigationBarAppearance? {
                guard let a = a?.copy() else { return nil }
                a.largeTitleTextAttributes[.font] = font
                return a
            }
            bar.standardAppearance = fix(bar.standardAppearance) ?? bar.standardAppearance
            bar.scrollEdgeAppearance = fix(bar.scrollEdgeAppearance)
            for item in [parent?.navigationItem, navigationController?.topViewController?.navigationItem].compactMap({ $0 }) {
                item.standardAppearance = fix(item.standardAppearance ?? bar.standardAppearance)
                item.scrollEdgeAppearance = fix(item.scrollEdgeAppearance ?? bar.scrollEdgeAppearance ?? bar.standardAppearance)
            }
        }
    }
    func makeUIViewController(context: Context) -> Probe { Probe() }
    func updateUIViewController(_ vc: Probe, context: Context) { vc.apply() }
}
#endif

extension View {
    /// Routes the UIKit large navigation title through the shared H1 token.
    func guideH1NavigationTitleFont() -> some View {
        #if canImport(UIKit)
        background(GuideH1NavigationFont().frame(width: 0, height: 0).accessibilityHidden(true))
        #else
        self
        #endif
    }
}

/// Tab-root H1: the same view and token as Home's mystery title (Instrument Sans regular),
/// placed in the system large-title slot so UIKit keeps the collapse and compact title.
struct GuidePageTitle: View {
    @Environment(\.palette) private var palette
    let text: String

    var body: some View {
        GuideDisplayTitle(text: text, size: AppTheme.TypeRole.h1NavigationSize, color: palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Replaces the system bold large title with `GuidePageTitle`; the nav title stays
    /// set so the compact bar title still appears on scroll.
    func guidePageTitle(_ text: String) -> some View {
        toolbar {
            ToolbarItem(placement: .largeTitle) { GuidePageTitle(text: text) }
        }
    }
}

enum GuideChrome {
    /// Run once at launch, before any navigation bar exists: appearance proxies only
    /// reach bars created afterwards, so tab roots would otherwise miss the title fonts.
    static func applyAtLaunch() {
        #if canImport(UIKit)
        let dark = UITraitCollection.current.userInterfaceStyle == .dark
        apply(ThemePalette(scheme: dark ? .dark : .light, contrast: .standard))
        #endif
    }

    #if canImport(UIKit)
    /// A trait-resolving UIColor for a palette token. Appearance proxies only style a control
    /// when it is created, so a colour resolved for one scheme stays on screen after a
    /// Light/Dark (or Increase Contrast) switch. Dynamic colours re-resolve on every trait change.
    static func dynamic(_ token: @escaping (ThemePalette) -> Color) -> UIColor {
        UIColor { traits in
            let palette = ThemePalette(
                scheme: traits.userInterfaceStyle == .dark ? .dark : .light,
                contrast: traits.accessibilityContrast == .high ? .increased : .standard
            )
            return UIColor(token(palette)).resolvedColor(with: traits)
        }
    }
    #endif

    /// Styles UIKit chrome with dynamic colours, so the palette argument only matters for
    /// callers; every bar and segmented control follows the current traits by itself.
    static func apply(_ palette: ThemePalette) {
        #if canImport(UIKit)
        let ink = dynamic(\.ink)
        let dim = dynamic(\.dim)
        let tabSelected = dynamic(\.tabSelected)

        // Use the system nav bar material (liquid glass on iOS 26) so scrolled
        // content can show through. An opaque backgroundColor cancels that.
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        // Keep app ink while letting UIKit own title fonts, sizing and bar material.
        nav.titleTextAttributes = [.foregroundColor: ink]
        nav.largeTitleTextAttributes = [
            .foregroundColor: ink,
            // H1 token: same face as Home's mystery title.
            .font: AppTheme.TypeRole.h1UIFont(AppTheme.TypeRole.h1NavigationSize)
        ]
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = nav
        // At rest (large title showing) UIKit uses the scroll-edge appearance; give it the
        // same title fonts on a transparent bar so the H1 token applies there too.
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        edge.titleTextAttributes = nav.titleTextAttributes
        edge.largeTitleTextAttributes = nav.largeTitleTextAttributes
        navBar.scrollEdgeAppearance = edge
        navBar.compactAppearance = nil
        navBar.tintColor = ink

        // Use the system tab bar material (liquid glass on iOS 26) so scrolled
        // content can show through. An opaque backgroundColor cancels that.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.shadowColor = .clear
        tabAppearance.stackedLayoutAppearance.selected.iconColor = tabSelected
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: tabSelected]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = dim
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: dim]

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = tabSelected
        tabBar.unselectedItemTintColor = dim

        // SwiftUI's segmented picker is backed by UISegmentedControl. Keep
        // its unselected track on the same surface token as the rest of the
        // app instead of UIKit's default system fill.
        let segmentedControl = UISegmentedControl.appearance()
        segmentedControl.backgroundColor = dynamic(\.segmentedControlTrack)
        segmentedControl.selectedSegmentTintColor = dynamic(\.selectedControlFill)
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: dim,
                .font: AppTheme.TypeRole.segmentedControlUIFont
            ],
            for: .normal
        )
        segmentedControl.setTitleTextAttributes(
            [
                .foregroundColor: ink,
                .font: AppTheme.TypeRole.segmentedControlUIFont
            ],
            for: .selected
        )
        #endif
    }
}

struct GuidePageChrome: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .background(palette.bg)
            // Leave nav bar material to the system (liquid glass on iOS 26).
            // A solid toolbarBackground fill cancels translucency.
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
    }
}

extension View {
    func guidePageChrome() -> some View {
        modifier(GuidePageChrome())
    }
}

/// Standard system large-title navigation for tab roots.
/// UIKit owns the collapse, safe areas, material and toolbar placement.
struct GuideRootChrome: ViewModifier {
    static let contentTop = AppTheme.Space.xl
    let title: String

    func body(content: Content) -> some View {
        content
            .guidePageChrome()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .guidePageTitle(title)
            .toolbar(.visible, for: .navigationBar)
    }
}

extension View {
    func guideRootChrome(_ title: String) -> some View {
        modifier(GuideRootChrome(title: title))
    }
}

/// The one chrome for pushed level-2+ screens: small centred inline title, native
/// back button and edge swipe. Tab roots and the Settings root keep the large
/// collapsing title instead. Start scroll content `contentTop` under the bar.
struct GuideDetailChrome: ViewModifier {
    /// Gap from the bar to the first content element on level-2+ screens.
    static let contentTop: CGFloat = AppTheme.Space.lg

    let title: String

    func body(content: Content) -> some View {
        content
            .guidePageChrome()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            // System automatic material — do not force a solid fill.
    }
}

extension View {
    /// Standard chrome for pushed level-2+ screens.
    /// Keeps the native NavigationStack back button, which preserves iOS edge-swipe back.
    func guideDetailChrome(_ title: String) -> some View {
        modifier(GuideDetailChrome(title: title))
    }
}

/// Custom sticky-header blur with the app's page-colour tint.
struct GuideChromeBar: ViewModifier {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.palette) private var palette
    /// 0 at rest, 1 when scrolled.
    var progress: CGFloat
    var prayerBackground = false

    static let tintOpacity: Double = 0.78

    func body(content: Content) -> some View {
        content.background(alignment: .top) {
            GuideBlurView()
                .overlay {
                    (prayerBackground ? palette.prayBg : palette.bg)
                        .opacity(Self.tintOpacity)
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(uiColor: .separator))
                        .frame(height: 1 / max(displayScale, 1))
                }
                .ignoresSafeArea(edges: .top)
                .opacity(min(1, max(0, progress)))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    func guideChromeBar(progress: CGFloat, prayerBackground: Bool = false) -> some View {
        modifier(GuideChromeBar(progress: progress, prayerBackground: prayerBackground))
    }

    func guideChromeBar(visible: Bool, prayerBackground: Bool = false) -> some View {
        guideChromeBar(progress: visible ? 1 : 0, prayerBackground: prayerBackground)
            .animation(.easeOut(duration: 0.18), value: visible)
    }
}

/// Soft backdrop for buttons that float over scrolling content (prayer steps, intention
/// step, guides, sheet footers). A fade of the page colour, not a bar: text scrolling
/// underneath dims out before it reaches the buttons. Mirrors the mystery plate's top
/// scrim. With Reduce Transparency it is the solid page colour.
struct GuideFooterBackdrop: ViewModifier {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var prayerBackground = false
    var visible = true

    /// How far the fade reaches above the footer's own top edge.
    static let fadeReach: CGFloat = AppTheme.Space.xl

    func body(content: Content) -> some View {
        content.background(alignment: .bottom) {
            let page = prayerBackground ? palette.prayBg : palette.bg
            Group {
                if reduceTransparency {
                    page
                } else {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: page.opacity(colorScheme == .light ? 0.55 : 0.50), location: 0.22),
                            .init(color: page.opacity(colorScheme == .light ? 0.86 : 0.82), location: 0.48),
                            .init(color: page.opacity(colorScheme == .light ? 0.94 : 0.92), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .padding(.top, -Self.fadeReach)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

extension View {
    /// See `GuideFooterBackdrop`.
    func guideFooterBackdrop(prayerBackground: Bool = false, visible: Bool = true) -> some View {
        modifier(GuideFooterBackdrop(prayerBackground: prayerBackground, visible: visible))
    }
}

private struct GuideBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {}
}

/// Display serif with website `h1.title` tracking and 1.02 line-height.

// MARK: - Collapsing large title (tab H1 → inline nav title)

/// Scroll → collapse progress. Never change safe-area inset *height* from this
/// value (that feedback-loops and freezes scrolling). Only morph visuals.
enum CollapsingTitleMetrics {
    /// How far you scroll before the title is fully inline.
    static let distance: CGFloat = 76
    static let toolbarRowHeight: CGFloat = 40
    /// Spacer height reserved in scroll content under the morphing H1.
    static let largeTitleBlockHeight: CGFloat = 92
    static let largeSize: CGFloat = 54
    static let smallSize: CGFloat = 17
    /// Bottom of the expanded H1's text frame, measured from the top of the scroll
    /// content (title centre 31pt + half the 54pt Instrument Sans line height).
    static let largeTitleBottom: CGFloat = 64
    /// Tab roots add 8pt above their content; reserve the remainder here.
    static let firstComponentGap: CGFloat = AppTheme.Space.xxl
    static var firstComponentSpacerHeight: CGFloat {
        spacerHeight(gapBelowTitle: firstComponentGap) - AppTheme.Space.sm
    }

    /// `CollapsingTitleSpacer` height that starts the next element `gap` below the expanded H1.
    static func spacerHeight(gapBelowTitle gap: CGFloat) -> CGFloat {
        largeTitleBottom + gap
    }

    static func progress(forScrollOffset y: CGFloat) -> CGFloat {
        let linear = min(1, max(0, y / distance))
        // Smoothstep — eases in and out so the morph feels continuous.
        return linear * linear * (3 - 2 * linear)
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

extension View {
    /// How far the scroll view has moved past its top inset (0 at rest).
    func onCollapsingTitleScrollOffset(_ offset: Binding<CGFloat>) -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top
        } action: { _, newValue in
            let y = max(0, newValue)
            if abs(y - offset.wrappedValue) >= 0.5 {
                offset.wrappedValue = y
            }
        }
    }
}

/// Single title that morphs from large/leading → small/centered.
/// Drawn as an overlay (may extend below the toolbar); does not affect inset height.
private struct MorphingTitleWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Single title that morphs from large/leading → small/centered.
/// Drawn as a page overlay (may extend below the toolbar); does not affect inset height.
struct MorphingNavTitle: View {
    @Environment(\.palette) private var palette

    let title: String
    var progress: CGFloat

    @State private var titleWidth: CGFloat = 0

    private var t: CGFloat { min(1, max(0, progress)) }

    var body: some View {
        let size = CollapsingTitleMetrics.lerp(
            CollapsingTitleMetrics.largeSize,
            CollapsingTitleMetrics.smallSize,
            t
        )
        // Match page content inset (`AppTheme.gutter` == Space.lg).
        let gutter = AppTheme.gutter

        GeometryReader { geo in
            let y = CollapsingTitleMetrics.lerp(
                CollapsingTitleMetrics.toolbarRowHeight + 4 + size * 0.5,
                CollapsingTitleMetrics.toolbarRowHeight * 0.5 + 2,
                t
            )
            let measured = titleWidth > 0 ? titleWidth : size * CGFloat(title.count) * 0.55
            // Long titles shrink to fit between the gutters (short titles stay at 1).
            let available = max(1, geo.size.width - gutter * 2)
            let fit = min(1, available / max(measured, 1))
            let xLeading = gutter + measured * fit * 0.5
            let xCenter = geo.size.width * 0.5
            let x = CollapsingTitleMetrics.lerp(xLeading, xCenter, t)

            Text(title)
                .font(AppTheme.TypeRole.h1(size))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .fixedSize()
                .background(
                    GeometryReader { tg in
                        Color.clear.preference(key: MorphingTitleWidthKey.self, value: tg.size.width)
                    }
                )
                .onPreferenceChange(MorphingTitleWidthKey.self) { titleWidth = $0 }
                .scaleEffect(fit)
                .position(x: x, y: y)
        }
        // Tall enough for the expanded H1 under the toolbar; overlay only — no inset growth.
        .frame(height: CollapsingTitleMetrics.toolbarRowHeight + CollapsingTitleMetrics.largeTitleBlockHeight)
        .allowsHitTesting(false)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Fixed-height top chrome + morphing title overlay.
/// Large-title space in the scroll view is a clear spacer (`CollapsingTitleSpacer`).
struct CollapsingPageHeader<Leading: View, Trailing: View, Accessory: View>: View {
    @Environment(\.palette) private var palette

    let title: String
    var progress: CGFloat
    /// When false (e.g. empty Offer), keep the large title expanded.
    var morphEnabled: Bool = true
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var accessory: () -> Accessory

    private var t: CGFloat {
        morphEnabled ? min(1, max(0, progress)) : 0
    }

    var body: some View {
        // Layout height is only the toolbar (+ accessory). The morphing title
        // is an overlay that can draw below without expanding the inset.
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                leading()
                Spacer(minLength: 0)
                trailing()
            }
            .frame(height: CollapsingTitleMetrics.toolbarRowHeight)
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.top, AppTheme.Space.xs)

            accessory()
        }
        .frame(maxWidth: .infinity)
        .background(palette.bg)
        .overlay(alignment: .top) {
            MorphingNavTitle(title: title, progress: t)
        }
    }
}

/// Invisible scroll-space under the morphing H1 (same footprint as the large title).
struct CollapsingTitleSpacer: View {
    /// Defaults to the full large-title block; pass a smaller height to tuck
    /// the next control (e.g. Feasts segmented picker) up under the H1.
    var height: CGFloat = CollapsingTitleMetrics.largeTitleBlockHeight

    var body: some View {
        Color.clear
            .frame(height: height)
            .accessibilityHidden(true)
    }
}

extension CollapsingPageHeader where Accessory == EmptyView {
    init(
        title: String,
        progress: CGFloat,
        morphEnabled: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.progress = progress
        self.morphEnabled = morphEnabled
        self.leading = leading
        self.trailing = trailing
        self.accessory = { EmptyView() }
    }
}

extension CollapsingPageHeader where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        progress: CGFloat,
        morphEnabled: Bool = true,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.progress = progress
        self.morphEnabled = morphEnabled
        self.leading = { EmptyView() }
        self.trailing = { EmptyView() }
        self.accessory = accessory
    }
}

extension CollapsingPageHeader where Leading == EmptyView, Trailing == EmptyView, Accessory == EmptyView {
    init(title: String, progress: CGFloat, morphEnabled: Bool = true) {
        self.title = title
        self.progress = progress
        self.morphEnabled = morphEnabled
        self.leading = { EmptyView() }
        self.trailing = { EmptyView() }
        self.accessory = { EmptyView() }
    }
}



/// Applies collapsing title chrome without letting the morph expand/clip the inset.
/// Toolbar (+ optional accessory) stays in a fixed top inset; the H1 morphs in a
/// page-level overlay so it can sit large below the toolbar and ease into center.
struct CollapsingTitleChrome<ToolbarLeading: View, ToolbarTrailing: View, ToolbarAccessory: View>: ViewModifier {
    @Environment(\.palette) private var palette

    let title: String
    @Binding var scrollOffset: CGFloat
    var morphEnabled: Bool = true
    @ViewBuilder var leading: () -> ToolbarLeading
    @ViewBuilder var trailing: () -> ToolbarTrailing
    @ViewBuilder var accessory: () -> ToolbarAccessory

    private var progress: CGFloat {
        guard morphEnabled else { return 0 }
        return CollapsingTitleMetrics.progress(forScrollOffset: scrollOffset)
    }

    func body(content: Content) -> some View {
        content
            .onCollapsingTitleScrollOffset($scrollOffset)
            // Content scrolls under the bar; once scrolled the bar is the standard
            // frosted navigation bar material with a hairline (see `guideChromeBar`).
            .safeAreaBar(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        leading()
                        Spacer(minLength: 0)
                        trailing()
                    }
                    .frame(height: CollapsingTitleMetrics.toolbarRowHeight)
                    .padding(.horizontal, AppTheme.Space.lg)
                    .padding(.top, AppTheme.Space.xs)

                    accessory()
                }
                .frame(maxWidth: .infinity)
                .guideChromeBar(progress: progress)
            }
            // The frosted bar replaces the system edge effect (no double blur).
            .scrollEdgeEffectHidden(true, for: .top)
            .overlay(alignment: .top) {
                // Drawn in the page overlay (not inside the inset) so the large
                // title is not clipped and cannot expand the inset.
                MorphingNavTitle(title: title, progress: progress)
                    .padding(.top, AppTheme.Space.xs)
            }
    }
}

extension View {
    func collapsingTitleChrome<L: View, T: View, A: View>(
        _ title: String,
        scrollOffset: Binding<CGFloat>,
        morphEnabled: Bool = true,
        @ViewBuilder leading: @escaping () -> L,
        @ViewBuilder trailing: @escaping () -> T,
        @ViewBuilder accessory: @escaping () -> A
    ) -> some View {
        modifier(CollapsingTitleChrome(
            title: title,
            scrollOffset: scrollOffset,
            morphEnabled: morphEnabled,
            leading: leading,
            trailing: trailing,
            accessory: accessory
        ))
    }

    func collapsingTitleChrome<L: View, T: View>(
        _ title: String,
        scrollOffset: Binding<CGFloat>,
        morphEnabled: Bool = true,
        @ViewBuilder leading: @escaping () -> L,
        @ViewBuilder trailing: @escaping () -> T
    ) -> some View {
        collapsingTitleChrome(
            title,
            scrollOffset: scrollOffset,
            morphEnabled: morphEnabled,
            leading: leading,
            trailing: trailing,
            accessory: { EmptyView() }
        )
    }

    func collapsingTitleChrome(
        _ title: String,
        scrollOffset: Binding<CGFloat>,
        morphEnabled: Bool = true
    ) -> some View {
        collapsingTitleChrome(
            title,
            scrollOffset: scrollOffset,
            morphEnabled: morphEnabled,
            leading: { EmptyView() },
            trailing: { EmptyView() },
            accessory: { EmptyView() }
        )
    }

    func collapsingTitleChrome<A: View>(
        _ title: String,
        scrollOffset: Binding<CGFloat>,
        morphEnabled: Bool = true,
        @ViewBuilder accessory: @escaping () -> A
    ) -> some View {
        collapsingTitleChrome(
            title,
            scrollOffset: scrollOffset,
            morphEnabled: morphEnabled,
            leading: { EmptyView() },
            trailing: { EmptyView() },
            accessory: accessory
        )
    }
}



struct GuideDisplayTitle: View {
    var text: String
    var size: CGFloat
    var color: Color

    var body: some View {
        #if canImport(UIKit)
        uiKitTitle
        #else
        Text(text)
            .font(AppTheme.TypeRole.h1(size))
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
        #endif
    }

    #if canImport(UIKit)
    private var uiKitTitle: some View {
        let ui = AppTheme.TypeRole.h1UIFont(size)
        let extra = (size * AppTheme.titleLineHeight) - ui.lineHeight
        return Text(text)
            .font(Font(ui))
            .lineSpacing(extra)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    #endif
}

struct GuideSectionLabel: View {
    enum Prominence {
        case quiet
        case strong
    }

    @Environment(\.palette) private var palette
    var text: String
    var color: Color?
    var prominence: Prominence = .quiet
    /// Optional SF Symbol before the heading, in the heading's font and colour.
    var icon: String? = nil

    var body: some View {
        if let icon {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                Image(systemName: icon)
                    .font(font)
                    .foregroundStyle(color ?? defaultColor)
                    .accessibilityHidden(true)
                label
            }
        } else {
            label
        }
    }

    private var label: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color ?? defaultColor)
    }

    private var font: Font {
        switch prominence {
        case .quiet:
            AppTheme.TypeRole.sectionLabel
        case .strong:
            AppTheme.TypeRole.callout(weight: .semibold)
        }
    }

    private var defaultColor: Color {
        switch prominence {
        case .quiet:
            palette.textSecondary
        case .strong:
            palette.textPrimary
        }
    }
}

/// Shared secondary copy style for Home mystery themes and papal intention captions.
struct GuideThemeSummaryStyle: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .font(AppTheme.TypeRole.themeSummary)
            .foregroundStyle(palette.dim)
            .lineSpacing(5)
    }
}

extension View {
    func guideThemeSummaryStyle() -> some View {
        modifier(GuideThemeSummaryStyle())
    }
}


// MARK: - Motion (SmoothUI / Amicro-inspired, native SwiftUI)

/// Spring and duration tokens — GPU-friendly transform/opacity only; always honor Reduce Motion.
enum MotionTokens {
    static let walkthroughFadeOut = Animation.easeInOut(duration: 0.30)
    static let walkthroughFadeIn = Animation.easeInOut(duration: 0.50)
    static let accordion = Animation.easeInOut(duration: 0.18)
    static let accordionTransition = AnyTransition.identity
    static let calendarReturn = Animation.easeInOut(duration: 0.45)
    static let press = Animation.spring(response: 0.28, dampingFraction: 0.72)
    static let selection = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let reveal = Animation.spring(response: 0.52, dampingFraction: 0.86)
    static let soft = Animation.easeOut(duration: 0.22)
    static let pressScale: CGFloat = 0.97
}

/// Scope expansion animation to its row so unrelated page text does not crossfade.
struct GuideAccordionMotion: ViewModifier {
    let isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .contentTransition(.identity)
            .animation(reduceMotion ? nil : MotionTokens.accordion, value: isExpanded)
    }
}

extension View {
    func guideAccordion(isExpanded: Bool) -> some View {
        modifier(GuideAccordionMotion(isExpanded: isExpanded))
    }
}

struct GuidePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? MotionTokens.pressScale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : MotionTokens.press, value: configuration.isPressed)
    }
}

struct GuideSoftShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var elevated: Bool = true

    func body(content: Content) -> some View {
        content.shadow(
            color: colorScheme == .light && elevated && !reduceTransparency
                ? Color.primary.opacity(0.035)
                : .clear,
            radius: elevated ? 8 : 0,
            y: elevated ? 3 : 0
        )
    }
}

struct GuideReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var delay: Double = 0
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 12)
            .blur(radius: shown || reduceMotion ? 0 : 4)
            .onAppear {
                guard !reduceMotion else {
                    shown = true
                    return
                }
                withAnimation(MotionTokens.reveal.delay(delay)) {
                    shown = true
                }
            }
    }
}

private struct GuideFloatingGlassModifier<GlassShape: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: GlassShape
    let palette: ThemePalette

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(palette.surface, in: shape)
                .overlay {
                    shape.stroke(palette.controlStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
                }
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.stroke(palette.controlStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
                }
        }
    }
}

extension View {
    /// Floating control material only. Use for controls layered above content
    /// (nav affordances, overlay buttons), not for content cards.
    func guideFloatingGlass<GlassShape: Shape>(
        in shape: GlassShape,
        palette: ThemePalette
    ) -> some View {
        modifier(GuideFloatingGlassModifier(shape: shape, palette: palette))
    }
}

struct GuideCardChrome: ViewModifier {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var radius: CGFloat = AppTheme.containerRadius
    var fill: Color?
    var stroke: Bool = false
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(fill ?? palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if stroke {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            reduceTransparency
                                ? palette.hair
                                : palette.ink.opacity(colorScheme == .light ? 0.07 : 0.12),
                            lineWidth: AppTheme.Component.panelStrokeWidth
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .guideSoftShadow(elevated: elevated && colorScheme == .light)
    }
}

struct GuideRowGroupChrome: ViewModifier {
    @Environment(\.palette) private var palette
    var radius: CGFloat = AppTheme.containerRadius

    func body(content: Content) -> some View {
        content
            .background(palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Shared segmented-picker chrome used by the prayer language selector and Feasts scope filter.
struct GuideSegmentedControl: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .controlSize(.large)
            .font(AppTheme.TypeRole.segmentedControl)
            .frame(height: AppTheme.Component.segmentedControlHeight)
            .labelsHidden()
            #if canImport(UIKit)
            .background(SegmentedControlSchemeSync(dark: palette.scheme == .dark))
            #endif
    }
}

#if canImport(UIKit)
/// Pins the backing UISegmentedControl's interface style to the app palette. Its colours are
/// dynamic (`GuideChrome.dynamic`), but they resolve against the control's own traits, and a
/// hosting controller (notably a sheet) can keep the previous Light/Dark style after the app
/// switches, leaving a light track and wrong label colours on a dark page.
private struct SegmentedControlSchemeSync: UIViewRepresentable {
    let dark: Bool

    func makeUIView(context: Context) -> Probe { Probe() }

    func updateUIView(_ view: Probe, context: Context) {
        view.dark = dark
        view.sync()
    }

    final class Probe: UIView {
        var dark = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            sync()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            sync()
        }

        func sync() {
            guard let control = overlappingSegmentedControl() else { return }
            let style: UIUserInterfaceStyle = dark ? .dark : .light
            if control.overrideUserInterfaceStyle != style { control.overrideUserInterfaceStyle = style }
        }

        /// The segmented control drawn over this probe (same frame), so a screen with
        /// several pickers never restyles the wrong one.
        private func overlappingSegmentedControl() -> UISegmentedControl? {
            guard window != nil else { return nil }
            let mine = convert(bounds, to: nil)
            var ancestor = superview
            var depth = 0
            while let current = ancestor, depth < 6 {
                var stack: [UIView] = [current]
                while let view = stack.popLast() {
                    if let control = view as? UISegmentedControl,
                       control.convert(control.bounds, to: nil).intersects(mine) {
                        return control
                    }
                    stack.append(contentsOf: view.subviews)
                }
                ancestor = current.superview
                depth += 1
            }
            return nil
        }
    }
}
#endif

extension View {
    func guideSegmentedControl() -> some View {
        modifier(GuideSegmentedControl())
    }

    func guidePressable() -> some View {
        buttonStyle(GuidePressStyle())
    }

    func guideSoftShadow(elevated: Bool = true) -> some View {
        modifier(GuideSoftShadow(elevated: elevated))
    }

    func guideReveal(delay: Double = 0) -> some View {
        modifier(GuideReveal(delay: delay))
    }

    func guideCard(radius: CGFloat = AppTheme.containerRadius, fill: Color? = nil, stroke: Bool = false, elevated: Bool = false) -> some View {
        modifier(GuideCardChrome(radius: radius, fill: fill, stroke: stroke, elevated: elevated))
    }

    func guideRowGroup(radius: CGFloat = AppTheme.containerRadius) -> some View {
        modifier(GuideRowGroupChrome(radius: radius))
    }

    /// Chevron nav rows: no card chrome. Cancels any page gutter so content sits
    /// `AppTheme.gutter` / `Space.lg` (16pt) from the screen edge.
    /// When `pageGutter` already equals `gutter`, this is a no-op.
    func guideNavList(pageGutter: CGFloat) -> some View {
        padding(.horizontal, AppTheme.gutter - pageGutter)
    }

    func guideSymbol(size: CGFloat = 17, weight: Font.Weight = .medium, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        font(AppTheme.sans(size, weight: weight, relativeTo: textStyle))
            .symbolRenderingMode(.monochrome)
            .imageScale(.medium)
    }

    func guideHitTarget() -> some View {
        frame(minWidth: AppTheme.Accessibility.minHitTarget, minHeight: AppTheme.Accessibility.minHitTarget)
            .contentShape(Rectangle())
    }
}

// MARK: - Design token scale (consistency layer)

extension AppTheme {
    /// Spacing scale — prefer these over one-off paddings (14, 18, 22…).
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        /// Major block rhythm (same value as `sectionGap`).
        static let section: CGFloat = 44
    }

    /// Type roles — product style guide scale, with Instrument Sans / Newsreader pairing.
    /// Every role scales with Dynamic Type. Display type and labels inside fixed-size
    /// controls are capped (`Cap`) so very large sizes stay legible without breaking layout;
    /// body and reading text is never capped. At the default Large size no cap applies.
    enum TypeRole {
        /// Upper bounds for capped roles, as a multiple of the design size or in points.
        enum Cap {
            /// Large page and hero titles grow at most 30%.
            static let displayScale: CGFloat = 1.3
            /// Pill buttons keep their 52pt height; labels stop at 22pt and may wrap or shrink.
            static let pillLabel: CGFloat = 22
            /// Segmented controls keep their 44pt height; iOS offers the Large Content Viewer.
            static let segmentedControl: CGFloat = 17
            /// Text inside fixed 44pt day circles and the date column.
            static let calendarDay: CGFloat = 22
            static let calendarCaption: CGFloat = 15
            /// Section headings (title-sized) inside cards.
            static let heading: CGFloat = 44
        }

        /// Label inside a fixed-height pill button.
        static func pillLabel(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .callout, maxPointSize: Cap.pillLabel)
        }

        static var display: Font { headingPrimary }
        /// H1: Home's mystery title face (Instrument Sans regular, scales with Large Title).
        /// Every large page title uses this; the size is chosen per place.
        static func h1(_ size: CGFloat) -> Font {
            AppTheme.sans(size, weight: .regular, relativeTo: .largeTitle, maxPointSize: (size * Cap.displayScale).rounded())
        }
        #if canImport(UIKit)
        static func h1UIFont(_ size: CGFloat) -> UIFont {
            FontRegistrar.sansUI(size, weight: .regular, textStyle: .largeTitle, maxPointSize: (size * Cap.displayScale).rounded())
        }
        /// Size for UIKit large navigation titles (system large-title size).
        static let h1NavigationSize: CGFloat = 44
        #endif
        static var title: Font { headingPrimary }
        static var title2: Font { headingPrimary }
        static var title3: Font { headingSecondary }
        static var headline: Font { headingSecondary }
        static var headingPrimary: Font { AppTheme.sans(32, weight: .regular, relativeTo: .largeTitle, maxPointSize: Cap.heading) }
        static var headingSecondary: Font { AppTheme.sans(22, weight: .regular, relativeTo: .title2) }
        static func headline(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(22, weight: regularized(weight), relativeTo: .title2)
        }
        static var body: Font { AppTheme.sans(16, relativeTo: .body) }
        static func body(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .body)
        }
        static var buttonTertiary: Font { body }
        static var callout: Font { body }
        static func callout(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .callout)
        }
        static var supportingLabel: Font { AppTheme.sans(15, relativeTo: .subheadline) }
        static var rhythmSummary: Font { AppTheme.sans(32, relativeTo: .title, maxPointSize: Cap.heading) }
        static func rhythmCaption(compact: Bool = false) -> Font {
            AppTheme.sans(compact ? 13 : 14, relativeTo: .subheadline)
        }
        static var completionQuote: Font {
            AppTheme.serif(18, italic: true, opticalSize: 18, relativeTo: .body)
        }
        static var caption: Font { AppTheme.sans(12, weight: .regular, relativeTo: .caption) }
        static func caption(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(12, weight: regularized(weight), relativeTo: .caption)
        }
        static var serifBody: Font { AppTheme.serif(20, opticalSize: 20, relativeTo: .body) }
        static var serifItalicBody: Font { AppTheme.serif(16, italic: true, opticalSize: 16, relativeTo: .body) }
        static var serifTitle: Font { AppTheme.serif(24, opticalSize: 28, relativeTo: .title3) }
        static var serifDisplay: Font { AppTheme.serif(40, opticalSize: 44, relativeTo: .largeTitle, maxPointSize: (40 * Cap.displayScale).rounded()) }
        /// Reference size for the shared prayer paragraph line-height calculation.
        static func prayerLineHeightReference(scale: CGFloat) -> CGFloat { 21 * scale }
        static func scriptureReference(isMystery: Bool) -> Font {
            AppTheme.sans(isMystery ? 11 : 12, relativeTo: .caption)
        }
        static func prayerFruitLabel(isMystery: Bool) -> Font {
            AppTheme.sans(isMystery ? 12 : 14, weight: .medium, relativeTo: .caption)
        }
        static func prayerText(scale: CGFloat) -> Font {
            AppTheme.sans(max(16, 18 * scale), relativeTo: .body)
        }
        #if canImport(UIKit)
        static func prayerTextUIFont(scale: CGFloat) -> UIFont {
            FontRegistrar.sansUI(max(16, 18 * scale), textStyle: .body)
        }
        #endif

        // Compatibility aliases. New code should use the simpler scale above.
        static var screenTitle: Font { title2 }
        static var modalTitle: Font { title3 }
        static var sectionTitle: Font { title3 }
        static var titleSmall: Font { headline }
        static var cardTitle: Font { headline }
        static func titleSmall(weight: Font.Weight = .regular) -> Font { headline(weight: weight) }
        static var bodySmall: Font { callout }
        static func bodySmall(weight: Font.Weight = .regular) -> Font { callout(weight: weight) }
        static var themeSummary: Font { callout }
        static var label: Font { caption }
        static func label(weight: Font.Weight = .regular) -> Font { caption(weight: weight) }
        static var segmentedControl: Font { AppTheme.sans(14, weight: .medium, relativeTo: .callout, maxPointSize: Cap.segmentedControl) }
#if canImport(UIKit)
        static var segmentedControlUIFont: UIFont { FontRegistrar.sansUI(14, weight: .medium, maxPointSize: Cap.segmentedControl) }
#endif
        /// Day number in the fixed 44pt calendar circle.
        static func calendarDay(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .callout, maxPointSize: Cap.calendarDay)
        }
        static var calendarCaption: Font { AppTheme.sans(12, relativeTo: .caption, maxPointSize: Cap.calendarCaption) }
        static var calendarCaptionMedium: Font { AppTheme.sans(12, weight: .medium, relativeTo: .caption, maxPointSize: Cap.calendarCaption) }
        static var calendarDateNumber: Font { AppTheme.sans(22, relativeTo: .title2, maxPointSize: 28) }
        static var sectionLabel: Font { caption }
        static var quoteAttribution: Font { caption }
        static var settingsRow: Font { body }
        static func settingsRow(weight: Font.Weight = .regular) -> Font {
            body(weight: weight)
        }
        static var settingsMeta: Font { caption }

        #if canImport(UIKit)
        // UIKit twins of the roles above (the same cached UIFont), for `WordSafeText`.
        static func bodyUIFont(weight: Font.Weight = .regular) -> UIFont {
            FontRegistrar.sansUI(16, weight: regularized(weight), textStyle: .body)
        }
        static func calloutUIFont(weight: Font.Weight = .regular) -> UIFont {
            FontRegistrar.sansUI(16, weight: regularized(weight), textStyle: .callout)
        }
        static func captionUIFont(weight: Font.Weight = .regular) -> UIFont {
            FontRegistrar.sansUI(12, weight: regularized(weight), textStyle: .caption1)
        }
        static var headingSecondaryUIFont: UIFont { FontRegistrar.sansUI(22, weight: .regular, textStyle: .title2) }
        static var serifBodyUIFont: UIFont { FontRegistrar.serifUI(20, opticalSize: 20, textStyle: .body) }
        static var settingsRowUIFont: UIFont { bodyUIFont() }
        static var settingsMetaUIFont: UIFont { captionUIFont() }
        #endif

        private static func regularized(_ weight: Font.Weight) -> Font.Weight {
            if weight == .semibold || weight == .bold || weight == .heavy || weight == .black {
                return .regular
            }
            return weight
        }
    }

    /// Shared chrome measurements.
    enum Component {
        /// Reading content clearance above the expanded floating action.
        static let readingContentToActionGap: CGFloat = 76
        static let prayerReadingContentToActionGap: CGFloat = 48
        /// Distance from the scroll viewport bottom to the top of Next/Done.
        static var prayerReadingActionClearance: CGFloat {
            pillHeight + prayerFooterControlGap + segmentedControlHeight + Space.lg
        }
        /// Clear the floating footer without counting existing content padding twice.
        static func readingScrollTail(actionClearance: CGFloat, contentBottomPadding: CGFloat, anchorHeight: CGFloat = 0) -> CGFloat {
            max(0, actionClearance + prayerReadingContentToActionGap - contentBottomPadding - anchorHeight)
        }
        static var prayerReadingScrollTail: CGFloat {
            readingScrollTail(actionClearance: prayerReadingActionClearance, contentBottomPadding: Space.lg, anchorHeight: 1)
        }
        static let calendarHandleWidth: CGFloat = 36
        static let calendarHandleHeight: CGFloat = 4
        static let calendarHandleDividerGap: CGFloat = 2
        static let calendarHandleDotGap: CGFloat = 12
        static let calendarSnapThreshold: CGFloat = 24
        static let calendarWeekdayHeaderHeight: CGFloat = 20
        static let feastCalendarDayHeight: CGFloat = 52
        static let feastCalendarWeekCount = 5
        static let feastPreviewTextPadding: CGFloat = AppTheme.Space.xl + 2
        /// CSS `--btn-h: 3.3rem` ≈ 52pt.
        static let pillHeight: CGFloat = 52
        static let textButtonVerticalPadding: CGFloat = 10
        static let sectionDividerHeight: CGFloat = 8
        static let sectionDividerEndpointWidth: CGFloat = 16
        static let sectionDividerEndpointHeight: CGFloat = 40
        static let panelStrokeWidth: CGFloat = 1
        /// Shared height for segmented controls; matches Apple minimum touch target.
        static let segmentedControlHeight: CGFloat = Accessibility.minHitTarget
        /// Home mystery selector keeps the larger, hero-control proportion.
        static let mysterySelectorHeight: CGFloat = 52
        static let segmentedControlInset: CGFloat = Space.xs
        static var mysterySelectorInnerHeight: CGFloat {
            mysterySelectorHeight - segmentedControlInset * 2
        }
        static let prayerFooterControlGap: CGFloat = Space.lg
        static let prayerFooterButtonGap: CGFloat = Space.md
        static let mysteryPlateActionCircle: CGFloat = 52
        static let beadPulseCycle: TimeInterval = 1.12
        static let beadPulseOpacity: Double = 0.72
        static let beadPulseFillOpacity: Double = 0.44
        static let profileRowHeight: CGFloat = 56
        static let profileDividerOpacity: Double = 0.72
        static let profileTitleMinimumScale: CGFloat = 0.82
        static let profileValueMinimumScale: CGFloat = 0.78
        /// Matches `GuideSectionLabel` tracking.
        static let sectionLabelTracking: CGFloat = 0
        static let hairline: CGFloat = 1 / 3
    }

    enum Accessibility {
        static let minHitTarget: CGFloat = 44
    }
}


extension AppTheme {
    /// Canonical mystery icon paths and drawing tokens, shared by every screen.
    enum MysteryIcon {
        static let circleSize: CGFloat = 44
        static let glyphSize: CGFloat = circleSize * LineIcon.glyphRatio
        static let pathGridSize = LineIcon.pathGridSize
        static var strokeStyle: StrokeStyle { LineIcon.strokeStyle }

        static func path(for set: MysterySetKind, in rect: CGRect) -> Path {
            var path = Path()
            func move(_ x: CGFloat, _ y: CGFloat) {
                path.move(to: CGPoint(x: x, y: y))
            }
            func line(_ x: CGFloat, _ y: CGFloat) {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            func curve(_ x: CGFloat, _ y: CGFloat, _ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat) {
                path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: c1x, y: c1y), control2: CGPoint(x: c2x, y: c2y))
            }

            switch set {
            case .joyful:
                // Three lily petals above a gently curved stem and a single leaf.
                move(12, 12)
                curve(12, 2.5, 9, 9, 10, 5)
                curve(12, 12, 14, 5, 15, 9)
                move(12, 12)
                curve(4, 5.5, 7.5, 12, 4.5, 9)
                curve(12, 12, 8, 5.5, 11, 8)
                move(12, 12)
                curve(20, 5.5, 16.5, 12, 19.5, 9)
                curve(12, 12, 16, 5.5, 13, 8)
                move(12, 12)
                curve(11, 21.5, 13, 15, 10, 18)
                move(11.4, 18)
                curve(17.5, 14, 12, 15, 14.5, 14)
                curve(11.4, 18, 17, 17, 14, 19)
            case .luminous:
                path.addEllipse(in: CGRect(x: 7.5, y: 7.5, width: 9, height: 9))
                for index in 0..<8 {
                    let angle = CGFloat(index) * .pi / 4
                    move(12 + cos(angle) * 7.5, 12 + sin(angle) * 7.5)
                    line(12 + cos(angle) * 10, 12 + sin(angle) * 10)
                }
            case .sorrowful:
                // Latin proportions distinguish this from a generic plus symbol.
                move(10.3, 2.5)
                line(13.7, 2.5)
                line(13.7, 8)
                line(19, 8)
                line(19, 11.4)
                line(13.7, 11.4)
                line(13.7, 21.5)
                line(10.3, 21.5)
                line(10.3, 11.4)
                line(5, 11.4)
                line(5, 8)
                line(10.3, 8)
                path.closeSubpath()
            case .glorious:
                // Open, three-point crown with a quiet double band.
                move(5, 16.5)
                line(3, 6.5)
                line(8.5, 11)
                line(12, 3.5)
                line(15.5, 11)
                line(21, 6.5)
                line(19, 16.5)
                path.closeSubpath()
                move(5, 19.5)
                line(19, 19.5)
            }

            return path.applying(CGAffineTransform(scaleX: rect.width / pathGridSize, y: rect.height / pathGridSize))
                .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
        }
    }
}


extension AppTheme {
    /// Shared drawing language for mystery and intention vector icons.
    enum LineIcon {
        static let pathGridSize: CGFloat = 24
        static let glyphRatio: CGFloat = 0.5
        static let lineWidth: CGFloat = 1.25
        static var strokeStyle: StrokeStyle {
            StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        }
    }

    enum IntentionIcon {
        enum Glyph: CaseIterable {
            case hands, people, church, cross, heart, dove
        }

        static func glyph(for emoji: String, accent: IntentionAccent) -> Glyph {
            switch emoji {
            case "🙏": return .heart
            case "👥": return .people
            case "🌍", "🌎", "🌏": return .church
            case "✝️", "✝", "†": return .cross
            case "❤️", "❤", "♥️", "♥": return .heart
            case "🕊️", "🕊": return .dove
            default:
                switch accent {
                case .mintGreen: return .heart
                case .skyBlue: return .people
                case .purple: return .church
                }
            }
        }

        static func path(for glyph: Glyph, in rect: CGRect) -> Path {
            if glyph == .cross { return MysteryIcon.path(for: .sorrowful, in: rect) }
            var path = Path()
            func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
            func line(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: CGPoint(x: x, y: y)) }
            func curve(_ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) {
                path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: a, y: b), control2: CGPoint(x: c, y: d))
            }
            switch glyph {
            case .hands:
                // Two raised palms meet at the fingertips; sleeves anchor the silhouette.
                move(4, 19)
                line(7, 14)
                line(9, 4)
                curve(12, 4, 9.3, 2, 12, 2)
                line(12, 12)
                curve(9, 18, 12, 15, 10.5, 17)
                line(7, 21)
                path.closeSubpath()
                move(20, 19)
                line(17, 14)
                line(15, 4)
                curve(12, 4, 14.7, 2, 12, 2)
                move(12, 12)
                curve(15, 18, 12, 15, 13.5, 17)
                line(17, 21)
                line(20, 19)
                move(5.5, 16.5)
                line(9, 19)
                move(18.5, 16.5)
                line(15, 19)
            case .people:
                path.addEllipse(in: CGRect(x: 4.5, y: 3.5, width: 6, height: 6))
                path.addEllipse(in: CGRect(x: 13.5, y: 3.5, width: 6, height: 6))
                move(2, 20)
                line(2, 17)
                curve(13, 17, 2, 11, 13, 11)
                line(13, 20)
                line(2, 20)
                move(15, 20)
                line(22, 20)
                line(22, 17)
                curve(15, 12.5, 22, 13, 18, 11.5)
            case .church:
                move(12, 2)
                line(12, 6)
                move(10, 3.5)
                line(14, 3.5)
                move(7, 11)
                line(12, 6)
                line(17, 11)
                line(17, 21)
                line(7, 21)
                path.closeSubpath()
                move(7, 12)
                line(3, 15)
                line(3, 21)
                line(21, 21)
                line(21, 15)
                line(17, 12)
                move(10, 21)
                line(10, 17)
                curve(14, 17, 10, 14.5, 14, 14.5)
                line(14, 21)
                path.addEllipse(in: CGRect(x: 10.7, y: 10, width: 2.6, height: 2.6))
            case .heart:
                move(12, 21)
                curve(3, 7, 9, 18, 1, 12)
                curve(12, 6, 5, 2, 10, 3)
                curve(21, 7, 14, 3, 19, 2)
                curve(12, 21, 23, 12, 15, 18)
                path.closeSubpath()
            case .dove:
                move(4, 19)
                curve(10, 11, 8, 18, 10, 15)
                curve(7, 3, 8, 9, 7, 6)
                curve(16, 10, 12, 4, 14, 7)
                curve(20, 10, 17, 7, 20, 7)
                line(22, 11)
                line(19.5, 12)
                curve(10, 18, 18, 16, 14, 18)
                line(4, 19)
                path.closeSubpath()
                move(10, 18)
                line(6, 21)
            case .cross: break
            }
            return path.applying(CGAffineTransform(scaleX: rect.width / LineIcon.pathGridSize, y: rect.height / LineIcon.pathGridSize))
                .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
        }
    }
}


extension AppTheme {
    /// Canonical milestone icon mapping and vector paths.
    enum MilestoneIcon {
        enum Glyph: String, CaseIterable {
            case rosary, calendar, lily, crown, mysterySets, people, church, papalKeys
        }
        static func glyph(for id: String) -> Glyph {
            switch id {
            case "marian-feasts-1": return .lily
            case "our-lady-of-the-rosary": return .crown
            case "all-mysteries": return .mysterySets
            case "rosary-for-another": return .people
            case "rosary-for-church": return .church
            case "rosary-for-pope": return .papalKeys
            default: return id.hasPrefix("days-") ? .calendar : .rosary
            }
        }
        static func path(for glyph: Glyph, in rect: CGRect) -> Path {
            switch glyph {
            case .lily: return MysteryIcon.path(for: .joyful, in: rect)
            case .crown: return MysteryIcon.path(for: .glorious, in: rect)
            case .people: return IntentionIcon.path(for: .people, in: rect)
            case .church: return IntentionIcon.path(for: .church, in: rect)
            default: break
            }
            var path = Path()
            func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
            func line(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: CGPoint(x: x, y: y)) }
            switch glyph {
            case .rosary:
                // A loop of beads and a suspended Latin cross.
                for index in 0..<12 {
                    let angle = CGFloat(index) * .pi / 6
                    let x = 12 + cos(angle) * 7.5
                    let y = 9.5 + sin(angle) * 6.5
                    path.addEllipse(in: CGRect(x: x - 0.9, y: y - 0.9, width: 1.8, height: 1.8))
                }
                move(12, 17)
                line(12, 22)
                move(9.5, 19)
                line(14.5, 19)
            case .calendar:
                path.addRoundedRect(in: CGRect(x: 3, y: 5, width: 18, height: 16), cornerSize: CGSize(width: 2, height: 2))
                move(7, 2.5); line(7, 7)
                move(17, 2.5); line(17, 7)
                move(3, 10); line(21, 10)
                for y in [CGFloat(14), CGFloat(17.5)] {
                    for x in [CGFloat(7), CGFloat(12), CGFloat(17)] {
                        move(x - 0.5, y); line(x + 0.5, y)
                    }
                }
            case .mysterySets:
                // Four equal, joined circles represent the four mystery sets.
                for origin in [CGPoint(x: 3.5, y: 3.5), CGPoint(x: 12.5, y: 3.5), CGPoint(x: 3.5, y: 12.5), CGPoint(x: 12.5, y: 12.5)] {
                    path.addEllipse(in: CGRect(origin: origin, size: CGSize(width: 8, height: 8)))
                }
            case .papalKeys:
                // Crossed keys, the traditional emblem of Saint Peter's office.
                path.addEllipse(in: CGRect(x: 3, y: 3, width: 6, height: 6))
                path.addEllipse(in: CGRect(x: 15, y: 3, width: 6, height: 6))
                move(8, 8); line(19, 19)
                line(17, 21); line(15, 19)
                move(16, 8); line(5, 19)
                line(7, 21); line(9, 19)
                move(16, 16); line(18, 14)
                move(8, 16); line(6, 14)
            default: break
            }
            return path.applying(CGAffineTransform(scaleX: rect.width / LineIcon.pathGridSize, y: rect.height / LineIcon.pathGridSize))
                .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
        }
    }
}

#if canImport(UIKit)
/// Text that wraps only between words. At accessibility sizes, if the longest word is wider
/// than the space, the whole label steps down in size (to `minimumScale`) instead of breaking
/// inside the word ("Notification / s"). Below accessibility sizes it is exactly
/// `Text(text).font(Font(font))`.
struct WordSafeText: View {
    let text: String
    let font: UIFont
    var minimumScale: CGFloat = 0.5
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ text: String, font: UIFont, minimumScale: CGFloat = 0.5) {
        self.text = text
        self.font = font
        self.minimumScale = minimumScale
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // ViewThatFits takes the first size whose longest word fits the width.
            ViewThatFits(in: .horizontal) {
                ForEach(Self.scales(down: minimumScale), id: \.self) { scale in
                    let sized = scale == 1 ? font : font.withSize(font.pointSize * scale)
                    LongestWordWidth(width: Self.longestWordWidth(text, font: sized)) {
                        Text(text).font(Font(sized))
                    }
                }
            }
        } else {
            Text(text).font(Font(font))
        }
    }

    static func scales(down minimum: CGFloat) -> [CGFloat] {
        var out: [CGFloat] = [1]
        var next: CGFloat = 0.94
        while next > minimum {
            out.append(next)
            next -= 0.06
        }
        out.append(minimum)
        return out
    }

    static func words(in text: String) -> [String] {
        text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-\u{2010}\u{2013}\u{2014}/")))
            .filter { !$0.isEmpty }
    }

    static func longestWordWidth(_ text: String, font: UIFont) -> CGFloat {
        let widest = words(in: text)
            .map { ($0 as NSString).size(withAttributes: [.font: font]).width }
            .max() ?? 0
        return ceil(widest) + 1
    }
}

/// Reports `width` as its ideal width (what ViewThatFits compares) and otherwise lays out
/// its one child unchanged.
private struct LongestWordWidth: Layout {
    let width: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        if proposal.width == nil {
            let size = child.sizeThatFits(ProposedViewSize(width: width, height: proposal.height))
            return CGSize(width: width, height: size.height)
        }
        return child.sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}
#endif
