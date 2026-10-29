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

    /// The Latin text, or the English when there is no Latin version.
    var latinOrEnglish: String { latin.isEmpty ? english : latin }

    /// Whether a separate Latin text exists to show beside the English.
    var hasDistinctLatin: Bool { !latin.isEmpty && latin != english }

    func resolved(for language: PrayerLanguage) -> String {
        switch language {
        case .english: english
        case .latin: latinOrEnglish
        case .bilingual: hasDistinctLatin ? "\(english)\n\n\(latin)" : english
        }
    }

    func primary(for language: PrayerLanguage) -> String {
        language == .latin ? latinOrEnglish : english
    }

    func secondary(for language: PrayerLanguage) -> String? {
        language == .bilingual && hasDistinctLatin ? latin : nil
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

    /// Single-letter mark for Learn list circle icons (and similar compact chrome).
    var letter: String {
        switch self {
        case .joyful: "J"
        case .luminous: "L"
        case .sorrowful: "S"
        case .glorious: "G"
        }
    }

    /// Fill for mystery-set icons: blue scale from Joyful (strongest) to Glorious (palest).
    var letterFill: Color {
        switch self {
        case .joyful: AppTheme.mysteryJoyful
        case .luminous: AppTheme.mysteryLuminous
        case .sorrowful: AppTheme.mysterySorrowful
        case .glorious: AppTheme.mysteryGlorious
        }
    }

    /// Glyph colour on `letterFill`: one dark navy, readable on all four fills in both modes.
    var letterOn: Color { AppTheme.mysteryOn }

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
        // The weekly pattern is the same in every season; Sundays are always Glorious.
        switch self {
        case .joyful: "Mondays and Saturdays"
        case .luminous: "Thursdays"
        case .sorrowful: "Tuesdays and Fridays"
        case .glorious: "Wednesdays and Sundays"
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
        case "mother-of-the-church": "Mother of the Church"
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
    var id: UUID
    var mysterySet: MysterySetKind
    var stepIndex: Int
    var startedAt: Date
    var updatedAt: Date
    var activeDuration: TimeInterval
    var completedDecades: Set<Int>
    var lastCompletedDecadeActiveDuration: TimeInterval
    var includeSaintMichael: Bool
    var language: PrayerLanguage
    /// Intentions offered for this Rosary (up to `PrayerSession.maxIntentions`), in pick order.
    var intentionIds: [UUID]
    /// Display titles frozen when chosen; parallel to `intentionIds` where possible.
    var intentionTitles: [String]
    /// Frozen intention type (first intention) for offering milestones; older sessions decode as unknown.
    var intentionCategory: IntentionCategory?
    var intentionSourceId: String?
    /// Steps this Rosary was built with; older sessions decode as `.default`.
    var rosaryConfig: RosaryConfig


    enum CodingKeys: String, CodingKey {
        case id
        case mysterySet
        case stepIndex
        case startedAt
        case updatedAt
        case activeDuration
        case completedDecades
        case lastCompletedDecadeActiveDuration
        case includeSaintMichael
        case language
        case intentionId
        case intentionTitle
        case intentionIds
        case intentionTitles
        case intentionCategory
        case intentionSourceId
        case rosaryConfig
    }

    static let maxIntentions = 4

    /// First offered intention. Kept for older call sites and the legacy single-value schema.
    var intentionId: UUID? {
        get { intentionIds.first }
        set { intentionIds = newValue.map { [$0] } ?? [] }
    }

    /// First offered intention title. Setting it replaces the list with a single title.
    var intentionTitle: String? {
        get { intentionTitles.first }
        set { intentionTitles = newValue.map { [$0] } ?? [] }
    }

    init(
        id: UUID = UUID(),
        mysterySet: MysterySetKind,
        stepIndex: Int,
        startedAt: Date,
        updatedAt: Date,
        activeDuration: TimeInterval = 0,
        completedDecades: Set<Int> = [],
        lastCompletedDecadeActiveDuration: TimeInterval = 0,
        includeSaintMichael: Bool,
        language: PrayerLanguage,
        intentionId: UUID?,
        intentionTitle: String?,
        intentionIds: [UUID]? = nil,
        intentionTitles: [String]? = nil,
        intentionCategory: IntentionCategory? = nil,
        intentionSourceId: String? = nil,
        rosaryConfig: RosaryConfig = .default
    ) {
        self.id = id
        self.mysterySet = mysterySet
        self.stepIndex = stepIndex
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.activeDuration = activeDuration
        self.completedDecades = completedDecades
        self.lastCompletedDecadeActiveDuration = lastCompletedDecadeActiveDuration
        self.includeSaintMichael = includeSaintMichael
        self.language = language
        self.intentionIds = Array((intentionIds ?? intentionId.map { [$0] } ?? []).prefix(Self.maxIntentions))
        self.intentionTitles = Array((intentionTitles ?? intentionTitle.map { [$0] } ?? []).prefix(Self.maxIntentions))
        self.intentionCategory = intentionCategory
        self.intentionSourceId = intentionSourceId
        self.rosaryConfig = rosaryConfig
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        mysterySet = try container.decode(MysterySetKind.self, forKey: .mysterySet)
        stepIndex = try container.decode(Int.self, forKey: .stepIndex)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        activeDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .activeDuration) ?? 0
        completedDecades = try container.decodeIfPresent(Set<Int>.self, forKey: .completedDecades) ?? []
        lastCompletedDecadeActiveDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .lastCompletedDecadeActiveDuration) ?? 0
        includeSaintMichael = try container.decode(Bool.self, forKey: .includeSaintMichael)
        language = try container.decode(PrayerLanguage.self, forKey: .language)
        // Migration: sessions saved before multi-intention only carry the single keys.
        let legacyId = try container.decodeIfPresent(UUID.self, forKey: .intentionId)
        let legacyTitle = try container.decodeIfPresent(String.self, forKey: .intentionTitle)
        intentionIds = try container.decodeIfPresent([UUID].self, forKey: .intentionIds)
            ?? legacyId.map { [$0] } ?? []
        intentionTitles = try container.decodeIfPresent([String].self, forKey: .intentionTitles)
            ?? legacyTitle.map { [$0] } ?? []
        intentionCategory = try container.decodeIfPresent(IntentionCategory.self, forKey: .intentionCategory)
        intentionSourceId = try container.decodeIfPresent(String.self, forKey: .intentionSourceId)
        rosaryConfig = (try? container.decodeIfPresent(RosaryConfig.self, forKey: .rosaryConfig)) ?? .default
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mysterySet, forKey: .mysterySet)
        try container.encode(stepIndex, forKey: .stepIndex)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(activeDuration, forKey: .activeDuration)
        try container.encode(completedDecades, forKey: .completedDecades)
        try container.encode(lastCompletedDecadeActiveDuration, forKey: .lastCompletedDecadeActiveDuration)
        try container.encode(includeSaintMichael, forKey: .includeSaintMichael)
        try container.encode(language, forKey: .language)
        // Single keys stay so an older build can still resume the first intention.
        try container.encodeIfPresent(intentionId, forKey: .intentionId)
        try container.encodeIfPresent(intentionTitle, forKey: .intentionTitle)
        try container.encode(intentionIds, forKey: .intentionIds)
        try container.encode(intentionTitles, forKey: .intentionTitles)
        try container.encodeIfPresent(intentionCategory, forKey: .intentionCategory)
        try container.encodeIfPresent(intentionSourceId, forKey: .intentionSourceId)
        try container.encode(rosaryConfig, forKey: .rosaryConfig)
    }

    var continueCTATitle: String {
        let steps = RosarySequenceBuilder.build(set: mysterySet, config: rosaryConfig)
        let idx = min(max(stepIndex, 0), max(steps.count - 1, 0))
        if steps.indices.contains(idx) {
            return "Continue — \(steps[idx].stage.continuePhrase)"
        }
        return "Continue"
    }

    /// How long after its last bead a Rosary started yesterday can still be resumed.
    static let overnightResumeWindow: TimeInterval = 6 * 60 * 60

    /// A Rosary can be resumed on the day it was started, and after midnight while it is
    /// still fresh, so praying across midnight keeps its place.
    var isResumable: Bool { isResumable(now: Date()) }

    func isResumable(now: Date, calendar: Calendar = .current) -> Bool {
        if calendar.isDate(startedAt, inSameDayAs: now) { return true }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              calendar.isDate(startedAt, inSameDayAs: yesterday) else { return false }
        return now.timeIntervalSince(updatedAt) < Self.overnightResumeWindow
    }
}

enum HapticKind: Equatable {
    /// Softest tap: one per Hail Mary bead.
    case soft
    case light
    case medium
    case heavy
    case success
    case warning
}

/// One calm rhythm for the Rosary: a soft tap per Hail Mary, a slightly firmer tap on the
/// larger beads and prayers, a medium tap as each mystery is announced, and a gentle
/// success only when a decade is completed. One haptic per step, never stacked.
enum RosaryHaptics {
    static func kind(for step: RosaryStepKind) -> HapticKind {
        switch step {
        case .hailMary: return .soft
        case .mysteryAnnouncement: return .medium
        default: return .light
        }
    }

    /// Haptic for arriving on a step. Finishing a decade (by Complete decade, or by moving
    /// on from its closing prayer) is the one success moment.
    static func arrival(at step: RosaryStep, from previous: RosaryStep?, viaCompleteDecade: Bool = false) -> HapticKind {
        if viaCompleteDecade { return .success }
        if let previous, previous.closesDecade, step.id > previous.id { return .success }
        return step.haptic
    }
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

/// Bible translation for the mystery scripture on each decade's announcement.
/// Catholic editions only, all public domain: the World English Bible, Catholic Edition
/// (eBible.org), Douay-Rheims (Challoner, 1899 American ed.) and the Clementine Vulgate.
enum BibleTranslation: String, CaseIterable, Codable, Identifiable, Sendable {
    case webCatholic = "webc"
    case douayRheims
    case vulgate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .webCatholic: "World English Bible (Catholic)"
        case .douayRheims: "Douay-Rheims"
        case .vulgate: "Latin Vulgate"
        }
    }

    /// Value saved by builds up to 1.589 (5) for the app's original modern translation,
    /// which the World English Bible (Catholic) replaced. Still read from device storage
    /// and Firestore, and still written to Firestore (see `firestoreValue`).
    static let legacyModernRawValue = "rsv2ce"

    /// Reads current and legacy raw values; the old modern translation becomes WEB Catholic.
    init?(storedValue raw: String) {
        if raw == Self.legacyModernRawValue {
            self = .webCatholic
        } else {
            self.init(rawValue: raw)
        }
    }

    /// Token for `rosaryConfig.translation` in Firestore. The deployed rules only allow
    /// 'rsv2ce', 'douayRheims' and 'vulgate', so the default modern translation keeps the
    /// legacy token there; every build reads it back as the app's modern translation.
    var firestoreValue: String {
        self == .webCatholic ? Self.legacyModernRawValue : rawValue
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let value = BibleTranslation(storedValue: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown Bible translation \(raw)"
            ))
        }
        self = value
    }
}

/// How the user prays the Rosary. Saved on each `PrayerSession` so a resumed
/// Rosary rebuilds the same steps (and `stepIndex` keeps its meaning) even if
/// Settings changed meanwhile. Syncs with the in-progress Rosary (`session.rosaryConfig`).
struct RosaryConfig: Codable, Equatable, Hashable, Sendable {
    var translation: BibleTranslation = .webCatholic
    var fatimaPrayer = true
    /// O Sacrament most holy, after the Fatima prayer in each decade.
    var oSacrament = false
    /// Hail, holy Queen + versicle + closing prayer, as one group.
    var closingPrayers = true
    var memorare = false
    var saintMichael = false
    /// The "Offer this Rosary for" step after the Sign of the Cross.
    var intentionsStep = true

    /// Matches the fixed sequence from before this setting existed.
    static let `default` = RosaryConfig()

    init() {}

    enum CodingKeys: String, CodingKey {
        // A stored `showScripture` from 2c2662c is ignored; scripture is always shown.
        case translation, fatimaPrayer, oSacrament, closingPrayers
        case memorare, saintMichael, intentionsStep
        // A stored `openingIntentionLines` is ignored; the lines are always shown.
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = RosaryConfig()
        func bool(_ key: CodingKeys, _ fallback: Bool) -> Bool {
            (try? c.decodeIfPresent(Bool.self, forKey: key)) ?? fallback
        }
        translation = (try? c.decodeIfPresent(BibleTranslation.self, forKey: .translation)) ?? d.translation
        fatimaPrayer = bool(.fatimaPrayer, d.fatimaPrayer)
        oSacrament = bool(.oSacrament, d.oSacrament)
        closingPrayers = bool(.closingPrayers, d.closingPrayers)
        memorare = bool(.memorare, d.memorare)
        saintMichael = bool(.saintMichael, d.saintMichael)
        intentionsStep = bool(.intentionsStep, d.intentionsStep)
    }
}

/// Counts that open a sentence read as words: "Two Rosaries offered this week".
enum CountWords {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.numberStyle = .spellOut
        return formatter
    }()

    /// Capitalised English word for 0...20; digits above that.
    static func sentenceStart(_ count: Int) -> String {
        guard (0...20).contains(count),
              let word = formatter.string(from: NSNumber(value: count)) else { return "\(count)" }
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    /// Prayer rhythm card second line.
    static func rosariesOfferedThisWeek(_ count: Int) -> String {
        "\(sentenceStart(count)) \(count == 1 ? "Rosary" : "Rosaries") offered this week"
    }
}
