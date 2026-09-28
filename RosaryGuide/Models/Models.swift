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

    /// Medium matches site `--ps: 1.3125rem` (~21pt). Small/Large step ±~10–15%.
    var scale: CGFloat {
        switch self {
        case .small: 0.9
        case .medium: 1.0
        case .large: 1.15
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

    /// One-line theme for Home (and similar) under today's mystery set.
    var themeSummary: String {
        switch self {
        case .joyful: "The Incarnation and hidden life of Jesus."
        case .luminous: "The public ministry of Christ."
        case .sorrowful: "The Passion and sacrifice of Jesus."
        case .glorious: "The Resurrection and heavenly glory."
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

    /// Compact list label (matches rosaryguide.app home wording).
    var shortTitle: String {
        switch id {
        case "mary-mother-of-god": "Mary, Mother of God"
        case "presentation": "Presentation of the Lord"
        case "lourdes": "Our Lady of Lourdes"
        case "annunciation": "Annunciation"
        case "fatima": "Our Lady of Fatima"
        case "visitation": "Visitation"
        case "carmel": "Our Lady of Mount Carmel"
        case "assumption": "Assumption"
        case "queenship": "Queenship of Mary"
        case "nativity-mary": "Nativity of Mary"
        case "holy-name-mary": "Holy Name of Mary"
        case "sorrows": "Our Lady of Sorrows"
        case "rosary": "Our Lady of the Rosary"
        case "presentation-mary": "Presentation of Mary"
        case "immaculate-conception": "Immaculate Conception"
        case "immaculate-heart": "Immaculate Heart of Mary"
        case "guadalupe": "Our Lady of Guadalupe"
        case "christmas": "Christmas"
        default: name.english
        }
    }

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
    var intentionId: UUID?
    var intentionTitle: String?

    var continueCTATitle: String {
        let steps = RosarySequenceBuilder.build(set: mysterySet)
        let idx = min(max(stepIndex, 0), max(steps.count - 1, 0))
        if steps.indices.contains(idx) {
            return "Continue — \(steps[idx].stage.continuePhrase)"
        }
        return "Continue"
    }

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

    /// Web-style resume phrase: "Continue — first mystery"
    var continuePhrase: String {
        [
            "the opening prayers",
            "first mystery",
            "second mystery",
            "third mystery",
            "fourth mystery",
            "fifth mystery",
            "the closing prayers",
        ][rawValue]
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
