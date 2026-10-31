import Foundation
import SwiftUI

/// Shared redaction rules for the optional intention privacy eye.
/// Holy Father intentions remain readable while personal intentions are hidden.
enum IntentionPrivacy {
    static let maskedText = "Hidden"
    static let maskedNoteText = "Not shown while intentions are hidden."

    static func hides(_ intention: OfferIntention, hidden: Bool) -> Bool {
        hidden && !intention.isPapal
    }

    static func displayText(_ text: String, hidden: Bool) -> String {
        hidden ? maskedText : text
    }

    static func displayTitle(_ intention: OfferIntention, hidden: Bool) -> String {
        displayText(intention.title, hidden: hides(intention, hidden: hidden))
    }
}

enum IntentionAccent: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case skyBlue
    case mintGreen
    case purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skyBlue: "Soft Marian Blue"
        case .mintGreen: "Soft mint green"
        case .purple: "Soft purple"
        }
    }

    /// Avatar palette (case names are legacy, kept for saved data):
    /// mintGreen = Personal, skyBlue = Someone else, purple = Church & world.
    static var pickerOrder: [IntentionAccent] {
        [.mintGreen, .skyBlue, .purple]
    }

    var color: Color {
        switch self {
        case .mintGreen: AppTheme.intentionPersonal
        case .skyBlue: AppTheme.intentionSomeoneElse
        case .purple: AppTheme.intentionChurch
        }
    }

    var onColor: Color {
        switch self {
        case .mintGreen: AppTheme.intentionPersonalOn
        case .skyBlue: AppTheme.intentionSomeoneElseOn
        case .purple: AppTheme.intentionChurchOn
        }
    }

    /// Keep existing saved intentions colourful without allowing legacy hues
    /// to reappear in the avatar palette.
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        // Migrate former palette names (incl. teal → purple) without
        // reintroducing grey/yellow/rose into the current UI.
        case "skyBlue", "paleBlue", "blue": self = .skyBlue
        case "mintGreen", "paleGreen": self = .mintGreen
        case "purple", "teal", "green", "violet": self = .purple
        case "gray", "gold", "rose": self = .skyBlue
        default: self = .skyBlue
        }
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
        if PapalIntention.isPapal(sourceId) { return .world }
        if emoji == "👥" || accent == .skyBlue { return .someone }
        if emoji == "🌍" || accent == .purple { return .world }
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
    /// e.g. "pope-2026-09" — marks Holy Father origin; notes stay read-only once saved.
    var sourceId: String?
    var category: IntentionCategory
    var accent: IntentionAccent
    var emoji: String?
    /// Mystery sets this intention should gently surface on. Empty = no preference.
    var suggestOn: [MysterySetKind]
    /// When this intention was last edited on any device (whole milliseconds). Decides which
    /// copy wins when two devices change it while offline. Nil on copies saved before this existed.
    var updatedAt: Date? = nil
    /// When this intention was archived (out of the active lists). Nil while active. Synced.
    var archivedAt: Date? = nil

    var isArchived: Bool { archivedAt != nil }

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
        accent: IntentionAccent = .skyBlue,
        emoji: String? = nil,
        suggestOn: [MysterySetKind] = [],
        updatedAt: Date? = nil,
        archivedAt: Date? = nil
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
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }

    var isPapal: Bool {
        PapalIntention.isPapal(sourceId)
    }

    var categoryTitle: String {
        isPapal ? "Holy Father’s Intention" : category.title
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

    /// Prefer stored glyph; otherwise papal cross or the default personal heart.
    var displayEmoji: String {
        if let emoji, !emoji.isEmpty { return emoji }
        return isPapal ? "✝️" : "❤️"
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
        case updatedAt, archivedAt
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
        accent = try c.decodeIfPresent(IntentionAccent.self, forKey: .accent) ?? .skyBlue
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji)
        category = try c.decodeIfPresent(IntentionCategory.self, forKey: .category)
            ?? IntentionCategory.inferred(sourceId: sourceId, accent: accent, emoji: emoji)
        suggestOn = try c.decodeIfPresent([MysterySetKind].self, forKey: .suggestOn) ?? []
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
        archivedAt = try c.decodeIfPresent(Date.self, forKey: .archivedAt)
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
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(archivedAt, forKey: .archivedAt)
    }
}

