import Foundation
import SwiftUI

enum PrayerLanguage: String, CaseIterable, Codable, Identifiable {
    case english
    case latin
    case bilingual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English"
        case .latin: "Latin"
        case .bilingual: "English + Latin"
        }
    }

    var shortTitle: String {
        switch self {
        case .english: "EN"
        case .latin: "LA"
        case .bilingual: "EN/LA"
        }
    }
}

enum AppearancePreference: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct BilingualText: Hashable, Codable, Sendable {
    var english: String
    var latin: String

    func resolved(for language: PrayerLanguage) -> String {
        switch language {
        case .english: english
        case .latin: latin
        case .bilingual: "\(english)\n\n\(latin)"
        }
    }

    func primary(for language: PrayerLanguage) -> String {
        language == .latin ? latin : english
    }

    func secondary(for language: PrayerLanguage) -> String? {
        switch language {
        case .english, .latin: nil
        case .bilingual: latin
        }
    }
}

enum MysterySetKind: String, CaseIterable, Codable, Identifiable {
    case joyful
    case sorrowful
    case glorious
    case luminous

    var id: String { rawValue }

    var name: BilingualText {
        switch self {
        case .joyful: BilingualText(english: "Joyful Mysteries", latin: "Mysteria Gaudiosa")
        case .sorrowful: BilingualText(english: "Sorrowful Mysteries", latin: "Mysteria Dolorosa")
        case .glorious: BilingualText(english: "Glorious Mysteries", latin: "Mysteria Gloriosa")
        case .luminous: BilingualText(english: "Luminous Mysteries", latin: "Mysteria Luminosa")
        }
    }

    var weekdayNames: String {
        switch self {
        case .joyful: "Mondays, Saturdays, and Sundays of Advent and Christmas"
        case .sorrowful: "Tuesdays, Fridays, and Sundays of Lent"
        case .glorious: "Wednesdays and Sundays of Ordinary Time and Easter"
        case .luminous: "Thursdays"
        }
    }

    var ordinalAdjective: BilingualText {
        switch self {
        case .joyful: BilingualText(english: "Joyful", latin: "Gaudiosum")
        case .sorrowful: BilingualText(english: "Sorrowful", latin: "Dolorosum")
        case .glorious: BilingualText(english: "Glorious", latin: "Gloriosum")
        case .luminous: BilingualText(english: "Luminous", latin: "Luminosum")
        }
    }
}

enum LiturgicalSeason: String, Codable, CaseIterable, Identifiable {
    case advent
    case christmas
    case ordinary
    case lent
    case easter
    case triduum

    var id: String { rawValue }

    var name: BilingualText {
        switch self {
        case .advent: BilingualText(english: "Advent", latin: "Adventus")
        case .christmas: BilingualText(english: "Christmas", latin: "Nativitas")
        case .ordinary: BilingualText(english: "Ordinary Time", latin: "Tempus per annum")
        case .lent: BilingualText(english: "Lent", latin: "Quadragesima")
        case .easter: BilingualText(english: "Easter", latin: "Tempus Paschale")
        case .triduum: BilingualText(english: "Paschal Triduum", latin: "Sacrum Triduum Paschale")
        }
    }

    var liturgicalColorName: String {
        switch self {
        case .advent, .lent: "Violet"
        case .christmas, .easter: "White"
        case .ordinary: "Green"
        case .triduum: "Red / White"
        }
    }
}

struct Mystery: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var set: MysterySetKind
    var number: Int
    var title: BilingualText
    var fruit: BilingualText
    var scriptureReference: String
    var scriptureExcerpt: BilingualText
    var meditation: BilingualText
}

struct Prayer: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var title: BilingualText
    var text: BilingualText
    var leaderPrompt: BilingualText?
}

struct Feast: Identifiable, Hashable, Sendable {
    var id: String
    var name: BilingualText
    var summary: String
    var suggestedMysterySet: MysterySetKind?
    var isMarian: Bool
    var rank: FeastRank
    var dateProvider: @Sendable (Int) -> Date?

    static func == (lhs: Feast, rhs: Feast) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum FeastRank: String, Codable {
    case solemnity
    case feast
    case memorial
    case optionalMemorial
    case seasonal

    var title: String {
        switch self {
        case .solemnity: "Solemnity"
        case .feast: "Feast"
        case .memorial: "Memorial"
        case .optionalMemorial: "Optional Memorial"
        case .seasonal: "Seasonal"
        }
    }
}

struct DatedFeast: Identifiable, Hashable {
    var feast: Feast
    var date: Date
    var id: String { "\(feast.id)-\(date.timeIntervalSince1970)" }
}

struct CompletionQuote: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var text: String
    var attribution: String
}

struct PrayerSession: Codable, Equatable, Hashable, Sendable {
    var mysterySet: MysterySetKind
    var stepIndex: Int
    var startedAt: Date
    var updatedAt: Date
    var includeSaintMichael: Bool
    var language: PrayerLanguage

    var isFresh: Bool {
        Date().timeIntervalSince(updatedAt) < 36 * 60 * 60
    }
}

enum HapticKind: Equatable {
    case light
    case medium
    case heavy
    case success
    case warning
}

struct HowToPrayStep: Identifiable, Hashable {
    var id: Int
    var title: BilingualText
    var body: String
}

enum OrdinalWord {
    static func english(_ n: Int) -> String {
        ["First", "Second", "Third", "Fourth", "Fifth"][n - 1]
    }

    static func latin(_ n: Int) -> String {
        ["Primum", "Secundum", "Tertium", "Quartum", "Quintum"][n - 1]
    }
}
