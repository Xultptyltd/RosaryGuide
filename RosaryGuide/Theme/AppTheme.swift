import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Editorial utility design tokens.
enum AppTheme {
    /// The app's one explicit brand color. Everything else routes through
    /// Apple semantic colors so Light/Dark, contrast, and accessibility modes
    /// can do their work at the system layer.
    static let brandAccent = Color(hex: 0x0A66C2)
    static let brandAccentHighContrast = Color(hex: 0x0057B8)
    static let brandAccentDark = Color(hex: 0x69A7FF)
    static let brandAccentDarkHighContrast = Color(hex: 0x8FC0FF)

    /// CSS `--gut: 1.5rem` at the 16px rem the type scale is authored against.
    static let gutter: CGFloat = 24
    static let gutterCompact: CGFloat = 18
    /// `.sheet { margin-top: -3.5rem }`
    static let sheetOverlap: CGFloat = 56
    /// `.hero` `clamp(24rem, 56svh, 34rem)` — 56svh leaves room for the native tab bar.
    static let heroMin: CGFloat = 384
    static let heroMax: CGFloat = 544
    static let titleLineHeight: CGFloat = 1.02
    static let titleTrackingEm: CGFloat = -0.022
    static let sectionGap: CGFloat = 44
    static let decadesGap: CGFloat = 32
    static let containerRadius: CGFloat = 20
    /// Site `--r-feature` — Home mystery rail cards.
    static let featureRadius: CGFloat = 26
    static let nestedRadius: CGFloat = 12
    static var capsule: Capsule { Capsule(style: .continuous) }
    static let controlSize: CGFloat = 40

    static func gutter(for width: CGFloat) -> CGFloat {
        width <= 376 ? gutterCompact : gutter
    }

    static func heroHeight(viewport: CGFloat) -> CGFloat {
        min(max(heroMin, viewport * 0.56), heroMax)
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
}

struct ThemePalette {
    var scheme: ColorScheme
    var contrast: ColorSchemeContrast = .standard

    var bg: Color { Color(uiColor: .systemBackground) }
    var prayBg: Color { Color(uiColor: .systemBackground) }
    /// Header + stage track on mystery plates only; body below keeps `prayBg`.
    var plateChrome: Color { Color(uiColor: .secondarySystemBackground) }
    var ink: Color { .primary }
    var dim: Color { .secondary }
    var faint: Color { Color(uiColor: .tertiaryLabel) }
    var card: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    var card2: Color { Color(uiColor: .tertiarySystemGroupedBackground) }
    var hair: Color { Color(uiColor: .separator) }
    var accent: Color {
        switch (scheme, contrast) {
        case (.light, .increased): AppTheme.brandAccentHighContrast
        case (.dark, .increased): AppTheme.brandAccentDarkHighContrast
        case (.dark, _): AppTheme.brandAccentDark
        default: AppTheme.brandAccent
        }
    }
    var onAccent: Color { scheme == .dark ? Color.black : Color.white }
    var panel: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    var accentTint: Color { accent.opacity(scheme == .dark ? 0.22 : 0.12) }
    var glassFill: Color { Color(uiColor: .secondarySystemBackground).opacity(0.92) }
    var glassInk: Color { ink }
    var glassEdge: Color { hair }
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
        let bg = UIColor(palette.bg)
        let ink = UIColor(palette.ink)
        let dim = UIColor(palette.dim)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = bg
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

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(palette.bg)
        tabAppearance.shadowColor = UIColor(palette.hair)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(palette.accent)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(palette.accent)]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(palette.dim)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(palette.dim)]

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = UIColor(palette.accent)
        tabBar.unselectedItemTintColor = dim
        #endif
    }
}

struct GuidePageChrome: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .background(palette.bg)
            .toolbarBackground(palette.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
    }
}

extension View {
    func guidePageChrome() -> some View {
        modifier(GuidePageChrome())
    }
}

struct GuideDetailChrome: ViewModifier {
    @Environment(\.palette) private var palette
    let title: String

    func body(content: Content) -> some View {
        content
            .guidePageChrome()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(palette.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
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
        // Match page content inset (`AppTheme.gutter`), not Space.lg.
        let gutter = AppTheme.gutter

        GeometryReader { geo in
            let y = CollapsingTitleMetrics.lerp(
                CollapsingTitleMetrics.toolbarRowHeight + 4 + size * 0.5,
                CollapsingTitleMetrics.toolbarRowHeight * 0.5 + 2,
                t
            )
            let measured = titleWidth > 0 ? titleWidth : size * CGFloat(title.count) * 0.55
            let xLeading = gutter + measured * 0.5
            let xCenter = geo.size.width * 0.5
            let x = CollapsingTitleMetrics.lerp(xLeading, xCenter, t)

            Text(title)
                .font(AppTheme.sans(size, weight: .regular))
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
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(AppTheme.TypeRole.sectionLabel)
            .foregroundStyle(color)
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
    static let press = Animation.spring(response: 0.28, dampingFraction: 0.72)
    static let selection = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let reveal = Animation.spring(response: 0.52, dampingFraction: 0.86)
    static let soft = Animation.easeOut(duration: 0.22)
    static let pressScale: CGFloat = 0.97
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
            .background(fill ?? palette.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var radius: CGFloat = AppTheme.containerRadius

    func body(content: Content) -> some View {
        content
            .background(
                (reduceTransparency ? palette.panel : palette.card.opacity(0.52)),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Shared segmented-picker chrome used by the prayer language selector and Feasts scope filter.
struct GuideSegmentedControl: ViewModifier {
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .controlSize(.large)
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

    /// Chevron nav rows: no card chrome. Cancels the page gutter so content sits
    /// `AppTheme.Space.lg` (16pt) from the screen edge.
    func guideNavList(pageGutter: CGFloat) -> some View {
        padding(.horizontal, AppTheme.Space.lg - pageGutter)
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

    /// Type roles — Instrument Sans / Newsreader pairing from the site.
    enum TypeRole {
        static var display: Font { AppTheme.sans(54, weight: .regular, relativeTo: .largeTitle) }
        static var title: Font { AppTheme.sans(40, weight: .regular, relativeTo: .title) }
        static var titleSmall: Font { AppTheme.sans(24, weight: .semibold, relativeTo: .title3) }
        static var body: Font { AppTheme.sans(19, relativeTo: .body) }
        static var bodySmall: Font { AppTheme.sans(17, relativeTo: .body) }
        static var themeSummary: Font { AppTheme.sans(15, relativeTo: .body) }
        static var callout: Font { AppTheme.sans(16, relativeTo: .callout) }
        static var label: Font { AppTheme.sans(13, weight: .medium, relativeTo: .subheadline) }
        static var caption: Font { AppTheme.sans(12, weight: .regular, relativeTo: .caption) }
        static var sectionLabel: Font { AppTheme.sans(12, weight: .medium, relativeTo: .caption) }
    }

    /// Shared chrome measurements.
    enum Component {
        /// CSS `--btn-h: 3.3rem` ≈ 52pt.
        static let pillHeight: CGFloat = 52
        static let chipPaddingV: CGFloat = Space.sm
        static let chipPaddingH: CGFloat = Space.md
        static let panelStrokeWidth: CGFloat = 1
        static let panelStrokeOpacity: Double = 0.11
        /// Shared height for compact segmented controls.
        static let segmentedControlHeight: CGFloat = 40
        /// Matches `GuideSectionLabel` tracking.
        static let sectionLabelTracking: CGFloat = 0
        static let hairline: CGFloat = 1 / 3
    }

    enum Accessibility {
        static let minHitTarget: CGFloat = 44
    }
}
