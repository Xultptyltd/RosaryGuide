import Foundation
import SwiftUI

enum PrayerLanguage: String, CaseIterable, Codable, Identifiable {
    case english
    case latin
    case bilingual

    var id: String { rawValue }

    var chip: String {
        switch self {
        case .english: "Eng"
        case .latin: "Lat"
        case .bilingual: "Both"
        }
    }

    var title: String {
        switch self {
        case .english: "English"
        case .latin: "Latin"
        case .bilingual: "English + Latin"
        }
    }

    var shortTitle: String { chip }
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

    func resolved(systemIsDark: Bool) -> ColorScheme {
        switch self {
        case .system: systemIsDark ? .dark : .light
        case .light: .light
        case .dark: .dark
        }
    }
}

enum PrayerTextSize: String, CaseIterable, Codable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .small: 1.0
        case .medium: 1.18
        case .large: 1.36
        }
    }

    var next: PrayerTextSize {
        switch self {
        case .small: .medium
        case .medium: .large
        case .large: .small
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
        language == .bilingual ? latin : nil
    }
}

enum MysterySetKind: String, CaseIterable, Codable, Identifiable {
    case joyful
    case sorrowful
    case glorious
    case luminous

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .joyful: "Joyful"
        case .sorrowful: "Sorrowful"
        case .glorious: "Glorious"
        case .luminous: "Luminous"
        }
    }

    var name: BilingualText {
        switch self {
        case .joyful: BilingualText(english: "Joyful Mysteries", latin: "Mysteria Gaudiosa")
        case .sorrowful: BilingualText(english: "Sorrowful Mysteries", latin: "Mysteria Dolorosa")
        case .glorious: BilingualText(english: "Glorious Mysteries", latin: "Mysteria Gloriosa")
        case .luminous: BilingualText(english: "Luminous Mysteries", latin: "Mysteria Luminosa")
        }
    }

    var weekdayNames: String { days(in: .ordinary) }

    func days(in season: LiturgicalSeason) -> String {
        switch self {
        case .joyful:
            switch season {
            case .advent: "Mondays, Saturdays and Sundays in Advent"
            case .christmas: "Mondays, Saturdays and Sundays in Christmastide"
            default: "Mondays and Saturdays"
            }
        case .luminous:
            "Thursdays"
        case .sorrowful:
            switch season {
            case .lent, .triduum: "Tuesdays, Fridays and Sundays in Lent"
            default: "Tuesdays and Fridays"
            }
        case .glorious:
            switch season {
            case .advent: "Wednesdays, and Sundays outside Advent"
            case .christmas: "Wednesdays, and Sundays outside Christmastide"
            case .lent, .triduum: "Wednesdays, and Sundays outside Lent"
            default: "Wednesdays and Sundays"
            }
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

    static var displayOrder: [MysterySetKind] { [.joyful, .luminous, .sorrowful, .glorious] }
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
    var artSlug: String
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

    var isSameCalendarDay: Bool {
        Calendar.current.isDateInToday(startedAt)
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

    static func roman(_ n: Int) -> String {
        ["I", "II", "III", "IV", "V"][n - 1]
    }
}

enum PrayTrackStage: Int, CaseIterable, Hashable, Codable {
    case opening = 0
    case first
    case second
    case third
    case fourth
    case fifth
    case closing

    var label: String {
        ["Opening", "I", "II", "III", "IV", "V", "Close"][rawValue]
    }

    static func decade(_ n: Int) -> PrayTrackStage {
        PrayTrackStage(rawValue: n) ?? .first
    }
}

enum BeadLocus: Hashable, Codable {
    case crucifix
    case openingOurFather
    case openingHail(Int)
    case openingGlory
    case decadeOurFather(Int)
    case decadeHail(Int, Int)
    case decadeGlory(Int)
    case decadeFatima(Int)
    case closing
}
