import SwiftUI

enum AppTheme {
    static let marianBlue = Color(red: 0.12, green: 0.24, blue: 0.42)
    static let deepNavy = Color(red: 0.07, green: 0.13, blue: 0.24)
    static let gold = Color(red: 0.78, green: 0.62, blue: 0.28)
    static let ivory = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let rose = Color(red: 0.72, green: 0.38, blue: 0.42)
    static let wine = Color(red: 0.48, green: 0.16, blue: 0.20)
    static let olive = Color(red: 0.28, green: 0.42, blue: 0.30)

    static func color(for set: MysterySetKind) -> Color {
        switch set {
        case .joyful: rose
        case .sorrowful: wine
        case .glorious: gold
        case .luminous: Color(red: 0.85, green: 0.70, blue: 0.32)
        }
    }

    static func color(for season: LiturgicalSeason) -> Color {
        switch season {
        case .advent, .lent: Color(red: 0.42, green: 0.28, blue: 0.55)
        case .christmas, .easter: Color(red: 0.92, green: 0.90, blue: 0.82)
        case .ordinary: olive
        case .triduum: wine
        }
    }

    static func symbol(for set: MysterySetKind) -> String {
        switch set {
        case .joyful: "sparkle"
        case .sorrowful: "cross"
        case .glorious: "crown"
        case .luminous: "sun.max.fill"
        }
    }
}

extension MysterySetKind {
    var tint: Color { AppTheme.color(for: self) }
    var symbolName: String { AppTheme.symbol(for: self) }
}
