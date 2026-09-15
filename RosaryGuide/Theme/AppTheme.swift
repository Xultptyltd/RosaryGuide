import SwiftUI

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
    static let darkBg = Color(hex: 0x0C0D0F)
    static let darkInk = Color(hex: 0xEEF1F4)
    static let darkDim = Color(hex: 0x8E939A)
    static let darkFaint = Color(hex: 0x7F848B)
    static let darkCard = Color(hex: 0x17181A)
    static let darkCard2 = Color(hex: 0x1E2024)
    static let darkHair = Color.white.opacity(0.075)
    static let darkAccent = Color(hex: 0xDDE3EA)
    static let darkOnAccent = Color(hex: 0x121316)

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("InstrumentSans-Regular", size: size).weight(weight)
    }

    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        Font.custom(italic ? "Newsreader16pt-Italic" : "Newsreader16pt-Regular", size: size)
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
    var glassFill: Color { scheme == .light ? Color.white.opacity(0.34) : Color.white.opacity(0.14) }
    var glassInk: Color { scheme == .light ? Color(hex: 0x171512) : AppTheme.darkInk }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette(scheme: .dark)
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
    }
}
