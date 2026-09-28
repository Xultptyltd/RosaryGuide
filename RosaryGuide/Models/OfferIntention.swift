import Foundation
import SwiftUI

enum IntentionAccent: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case gray
    case gold
    case green
    case blue
    case violet
    case rose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gray: "Grey"
        case .gold: "Yellow"
        case .green: "Mint"
        case .blue: "Sky"
        case .violet: "Lavender"
        case .rose: "Pink"
        }
    }

    /// Greys first (default), then the five pastel contact colours.
    static var pickerOrder: [IntentionAccent] {
        [.gray, .gold, .green, .blue, .violet, .rose]
    }

    var color: Color {
        switch self {
        case .gray: Color(red: 0.78, green: 0.78, blue: 0.80)
        case .gold: Color(red: 0.96, green: 0.82, blue: 0.28)
        case .green: Color(red: 0.72, green: 0.90, blue: 0.78)
        case .blue: Color(red: 0.70, green: 0.86, blue: 0.96)
        case .violet: Color(red: 0.78, green: 0.76, blue: 0.94)
        case .rose: Color(red: 0.96, green: 0.78, blue: 0.84)
        }
    }

    var onColor: Color {
        Color(red: 0.12, green: 0.12, blue: 0.12)
    }
}

enum IntentionCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case personal
    case someone
    case world

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal: "Personal"
        case .someone: "Someone else"
        case .world: "Church & world"
        }
    }

    static func inferred(sourceId: String?, accent: IntentionAccent, emoji: String?) -> IntentionCategory {
        if sourceId?.hasPrefix("pope-") == true { return .world }
        if emoji == "👥" || accent == .blue { return .someone }
        if emoji == "🌍" || accent == .green { return .world }
        return .personal
    }
}

struct OfferIntention: Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var note: String?
    var timesCarried: Int
    var isPinned: Bool
    var createdAt: Date
    var lastCarriedAt: Date?
    var expiresAt: Date?
    /// e.g. "pope-2026-09" — marks Holy Father origin; still editable once saved.
    var sourceId: String?
    var category: IntentionCategory
    var accent: IntentionAccent
    var emoji: String?
    /// Mystery sets this intention should gently surface on. Empty = no preference.
    var suggestOn: [MysterySetKind]

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        timesCarried: Int = 0,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        lastCarriedAt: Date? = nil,
        expiresAt: Date? = nil,
        sourceId: String? = nil,
        category: IntentionCategory = .personal,
        accent: IntentionAccent = .gray,
        emoji: String? = nil,
        suggestOn: [MysterySetKind] = []
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.timesCarried = timesCarried
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.lastCarriedAt = lastCarriedAt
        self.expiresAt = expiresAt
        self.sourceId = sourceId
        self.category = category
        self.accent = accent
        self.emoji = emoji
        self.suggestOn = suggestOn
    }

    var isPapal: Bool {
        sourceId?.hasPrefix("pope-") == true
    }

    var categoryTitle: String {
        isPapal ? "Holy Father" : category.title
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var isNew: Bool { timesCarried <= 0 }

    /// Empty when new — UI shows a badge instead.
    var carriedLabel: String {
        if isNew { return "" }
        if let lastCarriedAt {
            let day = lastCarriedAt.formatted(.dateTime.month(.abbreviated).day())
            if timesCarried == 1 {
                return "Prayed once · Last \(day)"
            }
            return "Prayed \(timesCarried) times · Last \(day)"
        }
        return timesCarried == 1 ? "Prayed once" : "Prayed \(timesCarried) times"
    }

    /// Nil when the intention has no end date (do not show “Kept indefinitely”).
    var durationLabel: String? {
        guard let expiresAt else { return nil }
        return "Until \(expiresAt.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

    /// Prefer stored glyph; otherwise papal cross or the default pray emoji.
    var displayEmoji: String {
        if let emoji, !emoji.isEmpty { return emoji }
        return isPapal ? "✝️" : "🙏"
    }

    var usesGenericGlyph: Bool {
        false
    }


    /// At most one linked mystery (first entry). Empty suggestOn = none.
    var associatedMystery: MysterySetKind? { suggestOn.first }

    func isSuggested(on set: MysterySetKind) -> Bool {
        associatedMystery == set
    }

    /// Mystery to open when praying this intention; falls back to today's set.
    func prayMystery(today: MysterySetKind) -> MysterySetKind {
        associatedMystery ?? today
    }

    var suggestOnLabel: String? {
        associatedMystery?.shortName
    }


}


extension OfferIntention: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, note, timesCarried, isPinned, createdAt, lastCarriedAt, expiresAt, sourceId, category, accent, emoji, suggestOn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        timesCarried = try c.decodeIfPresent(Int.self, forKey: .timesCarried) ?? 0
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastCarriedAt = try c.decodeIfPresent(Date.self, forKey: .lastCarriedAt)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        sourceId = try c.decodeIfPresent(String.self, forKey: .sourceId)
        accent = try c.decodeIfPresent(IntentionAccent.self, forKey: .accent) ?? .gray
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji)
        category = try c.decodeIfPresent(IntentionCategory.self, forKey: .category)
            ?? IntentionCategory.inferred(sourceId: sourceId, accent: accent, emoji: emoji)
        suggestOn = try c.decodeIfPresent([MysterySetKind].self, forKey: .suggestOn) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encode(timesCarried, forKey: .timesCarried)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(lastCarriedAt, forKey: .lastCarriedAt)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try c.encodeIfPresent(sourceId, forKey: .sourceId)
        try c.encode(category, forKey: .category)
        try c.encode(accent, forKey: .accent)
        try c.encodeIfPresent(emoji, forKey: .emoji)
        try c.encode(suggestOn, forKey: .suggestOn)
    }
}

enum IntentionEmojiPresets {
    static let all: [String] = ["🙏", "✝️", "❤️", "🕊️", "🌹", "🕯️", "📿", "⭐", "💧", "👨‍👩‍👧", "😇", "💒", "📖", "🌸", "💫", "🤗", "💪", "🌍", "🏥", "👶"]
}
