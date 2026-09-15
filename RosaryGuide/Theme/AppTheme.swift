import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Colour, type, and spacing tokens taken from `WebsiteReference/app.css`.
enum AppTheme {
    static let lightBg = Color(hex: 0xF4F1EB)
    static let lightInk = Color(hex: 0x191713)
    static let lightDim = Color(hex: 0x635D54)
    static let lightFaint = Color(hex: 0x6E675B)
    static let lightCard = Color(hex: 0xFFFEFA)
    static let lightCard2 = Color(hex: 0xE8E2D8)
    static let lightHair = Color(hex: 0x171512).opacity(0.11)
    static let lightAccent = Color(hex: 0x1B1917)
    static let lightOnAccent = Color(hex: 0xFAF8F5)
    static let lightPray = Color.white
    static let lightPanel = Color(hex: 0xF7F5EF)
    static let darkBg = Color(hex: 0x0C0D0F)
    static let darkInk = Color(hex: 0xEEF1F4)
    static let darkDim = Color(hex: 0x8E939A)
    static let darkFaint = Color(hex: 0x7F848B)
    static let darkCard = Color(hex: 0x17181A)
    static let darkCard2 = Color(hex: 0x1E2024)
    static let darkHair = Color.white.opacity(0.075)
    static let darkAccent = Color(hex: 0xDDE3EA)
    static let darkOnAccent = Color(hex: 0x121316)

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
    static let sectionGap: CGFloat = 52
    static let decadesGap: CGFloat = 36
    static let featureRadius: CGFloat = 26
    static let panelRadius: CGFloat = 16
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

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontRegistrar.sans(size, weight: weight)
    }

    static func serif(_ size: CGFloat, italic: Bool = false, opticalSize: CGFloat? = nil) -> Font {
        FontRegistrar.serif(size, italic: italic, opticalSize: opticalSize)
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

    var bg: Color { scheme == .light ? AppTheme.lightBg : AppTheme.darkBg }
    var prayBg: Color { scheme == .light ? AppTheme.lightPray : AppTheme.darkBg }
    var ink: Color { scheme == .light ? AppTheme.lightInk : AppTheme.darkInk }
    var dim: Color { scheme == .light ? AppTheme.lightDim : AppTheme.darkDim }
    var faint: Color { scheme == .light ? AppTheme.lightFaint : AppTheme.darkFaint }
    var card: Color { scheme == .light ? AppTheme.lightCard : AppTheme.darkCard }
    var card2: Color { scheme == .light ? AppTheme.lightCard2 : AppTheme.darkCard2 }
    var hair: Color { scheme == .light ? AppTheme.lightHair : AppTheme.darkHair }
    var accent: Color { scheme == .light ? AppTheme.lightAccent : AppTheme.darkAccent }
    var onAccent: Color { scheme == .light ? AppTheme.lightOnAccent : AppTheme.darkOnAccent }
    var panel: Color { scheme == .light ? AppTheme.lightPanel : AppTheme.darkCard }
    var glassFill: Color { scheme == .light ? Color.white.opacity(0.34) : Color.white.opacity(0.14) }
    var glassInk: Color { scheme == .light ? Color(hex: 0x171512) : AppTheme.darkInk }
    var glassEdge: Color { Color.white.opacity(scheme == .light ? 0.5 : 0.36) }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette(scheme: .light)
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

struct ThemedRoot<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var content: () -> Content

    var body: some View {
        let palette = ThemePalette(scheme: colorScheme)
        content()
            .environment(\.palette, palette)
            .tint(palette.accent)
            .background(palette.bg.ignoresSafeArea())
            .onAppear {
                FontRegistrar.register()
                GuideChrome.apply(palette)
            }
            .onChange(of: colorScheme) { _, newScheme in
                GuideChrome.apply(ThemePalette(scheme: newScheme))
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

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = bg
        tab.shadowColor = UIColor(palette.hair)
        let item = UITabBarItemAppearance()
        item.normal.iconColor = dim
        item.normal.titleTextAttributes = [.foregroundColor: dim]
        item.selected.iconColor = ink
        item.selected.titleTextAttributes = [.foregroundColor: ink]
        tab.stackedLayoutAppearance = item
        tab.inlineLayoutAppearance = item
        tab.compactInlineLayoutAppearance = item
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        tabBar.scrollEdgeAppearance = tab
        tabBar.tintColor = ink
        tabBar.unselectedItemTintColor = dim
        tabBar.isTranslucent = false
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

/// Display serif with website `h1.title` tracking and 1.02 line-height.
struct GuideDisplayTitle: View {
    var text: String
    var size: CGFloat
    var color: Color

    var body: some View {
        #if canImport(UIKit)
        uiKitTitle
        #else
        Text(text)
            .font(AppTheme.serif(size, opticalSize: 72))
            .tracking(size * AppTheme.titleTrackingEm)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
        #endif
    }

    #if canImport(UIKit)
    private var uiKitTitle: some View {
        let ui = FontRegistrar.serifUI(size, opticalSize: 72)
        let extra = (size * AppTheme.titleLineHeight) - ui.lineHeight
        return Text(text)
            .font(Font(ui))
            .tracking(size * AppTheme.titleTrackingEm)
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
            .font(AppTheme.sans(12, weight: .medium))
            .tracking(1.68)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
