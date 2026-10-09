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
    /// Soft avatar fills — light/dark pairs from the product colour table.
    /// Shared by intention avatars and mystery-set icons.
    /// Green → Personal / Joyful; Marian Blue → Someone else / Luminous;
    /// Purple → Church & world / Sorrowful; Peach → Glorious (fourth).
    static let intentionMintGreen = Color(light: 0xC3EDE6, dark: 0x0C615A)
    static let intentionSkyBlue = Color(light: 0xC0EAF7, dark: 0x005F78)
    static let intentionPurple = Color(light: 0xDADFFF, dark: 0x4B49A5)
    static let intentionPeach = Color(light: 0xFEDBC9, dark: 0x933600)
    /// Glyph colour on the avatar fill (opposite variant of the fill pair).
    static let intentionMintGreenOn = Color(light: 0x0C615A, dark: 0xC3EDE6)
    static let intentionSkyBlueOn = Color(light: 0x005F78, dark: 0xC0EAF7)
    static let intentionPurpleOn = Color(light: 0x4B49A5, dark: 0xDADFFF)
    static let intentionPeachOn = Color(light: 0x933600, dark: 0xFEDBC9)
    /// Legacy single ink used where a non-paired accent text is still needed.
    static let intentionAccentText = Color(red: 0.10, green: 0.20, blue: 0.22)

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
    static let titleTrackingEm: CGFloat = -0.022
    static let sectionGap: CGFloat = 44
    /// Gap between a section title (GuideSectionLabel `.strong`) and the content directly below it.
    static let sectionTitleGap: CGFloat = 20
    static let decadesGap: CGFloat = 32
    static let containerRadius: CGFloat = 20
    /// Site `--r-feature` — Home mystery rail cards.
    static let featureRadius: CGFloat = 24
    static let nestedRadius: CGFloat = 12
    static let thumbnailRadius: CGFloat = 12
    static let appIconRadius: CGFloat = 16
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

    static func grid(_ value: CGFloat, minimum: CGFloat = 4) -> CGFloat {
        max(minimum, (value / 4).rounded() * 4)
    }

    /// `h1.title { font-size: clamp(2.7rem, 11.5vw, 3.5rem) }` with the 23.5rem small-phone override.
    static func homeTitleSize(width: CGFloat) -> CGFloat {
        if width <= 376 { return 38.4 }
        let vw = width * 0.115
        return min(max(43.2, vw), 56)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        FontRegistrar.sans(size, weight: weight, relativeTo: textStyle)
    }

    static func serif(_ size: CGFloat, italic: Bool = false, opticalSize: CGFloat? = nil, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        FontRegistrar.serif(size, italic: italic, opticalSize: opticalSize, relativeTo: textStyle)
    }

    static func color(for season: LiturgicalSeason) -> Color {
        switch season {
        case .advent, .lent: Color(hex: 0x6B5B7A)
        case .christmas, .easter: Color(hex: 0xE8E4D8)
        case .ordinary: Color(hex: 0x5C6B58)
        case .triduum: Color(hex: 0x8A4A44)
        }
    }

    static func mysteryIndicatorColor(for set: MysterySetKind) -> Color {
        switch set {
        case .joyful: Color(hex: 0x1E1A15)
        case .luminous: Color(hex: 0xEDC68D)
        case .sorrowful: Color(hex: 0xDFA05D)
        case .glorious: Color(hex: 0xD19A12)
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

    var textPrimary: Color { .primary }
    /// The app's single secondary grey. Use this for all supporting,
    /// disabled-looking, metadata, and explanatory copy.
    var textSecondary: Color {
        scheme == .light ? Color(hex: 0x757575) : Color(hex: 0xAEAEAE)
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
    var destructive: Color { Color(uiColor: .systemRed) }

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

    /// Header + stage track on mystery plates only; body below keeps `prayerBackground`.
    var plateChrome: Color { Color(uiColor: .secondarySystemBackground) }
    var prayerBackground: Color { background }
    var feastIndicator: Color { scheme == .light ? Color(hex: 0xC4922C) : Color(hex: 0xE2B75A) }
    var accentTint: Color {
        scheme == .dark
            ? accent.opacity(0.20)
            : accent.opacity(0.12)
    }
    var inverseIcon: Color { scheme == .dark ? Color.black : Color.white }
    var onImage: Color { Color.white }
    /// Unselected segmented-control track. Keep this on the shared surface
    /// pathway so UIKit and custom segmented controls render the same surface.
    var segmentedControlTrack: Color { surface }
    var selectedControlFill: Color { Color(uiColor: .systemBackground) }
    var selectedShadow: Color { accent.opacity(0.28) }

    var ceremonyBackground: Color { Color(hex: 0x000000) }
    var ceremonyTextPrimary: Color { Color.white.opacity(0.96) }
    var ceremonyTextSecondary: Color { Color.white.opacity(0.48) }
    var ceremonyTextTertiary: Color { Color.white.opacity(0.42) }

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
    var onImageSecondary: Color { Color.white.opacity(0.72) }
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
            .tint(palette.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.bg.ignoresSafeArea())
            .onAppear {
                FontRegistrar.register()
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

enum GuideChrome {
    static func apply(_ palette: ThemePalette) {
        #if canImport(UIKit)
        let ink = UIColor(palette.ink)
        let dim = UIColor(palette.dim)

        // Use the system nav bar material (liquid glass on iOS 26) so scrolled
        // content can show through. An opaque backgroundColor cancels that.
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.shadowColor = .clear
        nav.titleTextAttributes = [
            .foregroundColor: ink,
            .font: FontRegistrar.sansUI(17, weight: .medium)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: ink,
            .font: FontRegistrar.serifUI(34, opticalSize: 34)
        ]
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = nav
        navBar.scrollEdgeAppearance = nav
        navBar.compactAppearance = nav
        navBar.tintColor = ink

        // Use the system tab bar material (liquid glass on iOS 26) so scrolled
        // content can show through. An opaque backgroundColor cancels that.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.shadowColor = .clear
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(palette.accent)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(palette.accent)]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(palette.dim)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(palette.dim)]

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = UIColor(palette.accent)
        tabBar.unselectedItemTintColor = dim

        // SwiftUI's segmented picker is backed by UISegmentedControl. Keep
        // its unselected track on the same surface token as the rest of the
        // app instead of UIKit's default system fill.
        let segmentedControl = UISegmentedControl.appearance()
        segmentedControl.backgroundColor = UIColor(palette.segmentedControlTrack)
        segmentedControl.selectedSegmentTintColor = UIColor(palette.selectedControlFill)
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
                .font(AppTheme.sans(size, weight: .regular, relativeTo: .largeTitle))
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
            .safeAreaInset(edge: .top, spacing: 0) {
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
            }
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
            .font(AppTheme.sans(size, weight: .regular, relativeTo: .largeTitle))
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
        #endif
    }

    #if canImport(UIKit)
    private var uiKitTitle: some View {
        let ui = FontRegistrar.sansUI(size, weight: .regular, textStyle: .largeTitle)
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

    var body: some View {
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
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .controlSize(.large)
            .font(AppTheme.TypeRole.segmentedControl)
            .frame(height: AppTheme.Component.segmentedControlHeight)
            .labelsHidden()
    }
}

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
    enum TypeRole {
        static let headingPrimaryLineHeight: CGFloat = 40
        static let headingSecondaryLineHeight: CGFloat = 28
        static let bodyLineHeight: CGFloat = 24
        static let captionLineHeight: CGFloat = 16

        static var display: Font { headingPrimary }
        static var title: Font { headingPrimary }
        static var title2: Font { headingPrimary }
        static var title3: Font { headingSecondary }
        static var headline: Font { headingSecondary }
        static var headingPrimary: Font { AppTheme.sans(32, weight: .regular, relativeTo: .largeTitle) }
        static var headingSecondary: Font { AppTheme.sans(22, weight: .regular, relativeTo: .title2) }
        static var headingSecondaryBold: Font { headingSecondary }
        static func headline(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(22, weight: regularized(weight), relativeTo: .title2)
        }
        static var body: Font { AppTheme.sans(16, relativeTo: .body) }
        static func body(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .body)
        }
        static var bodyBold: Font { body }
        static var buttonTertiary: Font { body }
        static var callout: Font { body }
        static func callout(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(16, weight: regularized(weight), relativeTo: .callout)
        }
        static var caption: Font { AppTheme.sans(12, weight: .regular, relativeTo: .caption) }
        static func caption(weight: Font.Weight = .regular) -> Font {
            AppTheme.sans(12, weight: regularized(weight), relativeTo: .caption)
        }
        static var serifSmall: Font { AppTheme.serif(16, opticalSize: 16, relativeTo: .body) }
        static var serifBody: Font { AppTheme.serif(20, opticalSize: 20, relativeTo: .body) }
        static var serifItalicBody: Font { AppTheme.serif(16, italic: true, opticalSize: 16, relativeTo: .body) }
        static var serifTitle: Font { AppTheme.serif(24, opticalSize: 28, relativeTo: .title3) }
        static var serifDisplay: Font { AppTheme.serif(40, opticalSize: 44, relativeTo: .largeTitle) }
        static func avatarLetter(for size: CGFloat) -> Font {
            AppTheme.sans(AppTheme.grid(size * 0.42, minimum: 12), weight: .semibold, relativeTo: .body)
        }
        static func prayerText(scale: CGFloat) -> Font {
            AppTheme.sans(max(16, 18 * scale), relativeTo: .body)
        }

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
        static var segmentedControl: Font { AppTheme.sans(14, weight: .medium, relativeTo: .callout) }
#if canImport(UIKit)
        static var segmentedControlUIFont: UIFont { FontRegistrar.sansUI(14, weight: .medium) }
#endif
        static var sectionLabel: Font { caption }
        static var quoteAttribution: Font { caption }
        static var settingsTitle: Font { headingPrimary }
        static var settingsCardTitle: Font { headingSecondaryBold }
        static var settingsRow: Font { body }
        static func settingsRow(weight: Font.Weight = .regular) -> Font {
            body(weight: weight)
        }
        static var settingsMeta: Font { caption }

        private static func regularized(_ weight: Font.Weight) -> Font.Weight {
            if weight == .semibold || weight == .bold || weight == .heavy || weight == .black {
                return .regular
            }
            return weight
        }
    }

    /// Shared chrome measurements.
    enum Component {
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
        static let chipPaddingV: CGFloat = Space.sm
        static let chipPaddingH: CGFloat = Space.md
        static let panelStrokeWidth: CGFloat = 1
        static let panelStrokeOpacity: Double = 0.11
        /// Tracking for uppercase quote attributions.
        static let quoteAttributionTracking: CGFloat = 1.3
        /// Shared height for segmented controls; matches Apple minimum touch target.
        static let segmentedControlHeight: CGFloat = Accessibility.minHitTarget
        /// The system large segmented control draws its track past its frame on each
        /// side (measured 49.3pt tall in a 44pt frame on iOS 26). Add this to a layout
        /// gap when the visible gap to the track must be exact.
        static let segmentedControlVisualOverflow: CGFloat = 8.0 / 3.0
        /// Home mystery selector keeps the larger, hero-control proportion.
        static let mysterySelectorHeight: CGFloat = 52
        static let segmentedControlInset: CGFloat = Space.xs
        static var segmentedControlInnerHeight: CGFloat {
            segmentedControlHeight - segmentedControlInset * 2
        }
        static var mysterySelectorInnerHeight: CGFloat {
            mysterySelectorHeight - segmentedControlInset * 2
        }
        static let prayerFooterControlGap: CGFloat = Space.lg
        static let prayerFooterButtonGap: CGFloat = Space.md
        static let mysteryPlateActionCircle: CGFloat = 52
        static let beadPulseCycle: TimeInterval = 1.12
        static let beadPulseOpacity: Double = 0.72
        static let beadPulseFillOpacity: Double = 0.44
        static let largeIconButton: CGFloat = 42
        static let profileRowHeight: CGFloat = 56
        static let profileHeroSymbolSize: CGFloat = 84
        static let profileHeroSymbolReserve: CGFloat = 92
        static let profileChevronSize: CGFloat = 16
        static let profileExternalLinkSymbol = "arrow.up.right"
        static let profileExternalLinkSize: CGFloat = 16
        static let profileSectionTracking: CGFloat = 3.6
        static let profileBackgroundSymbolOpacity: Double = 0.12
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
