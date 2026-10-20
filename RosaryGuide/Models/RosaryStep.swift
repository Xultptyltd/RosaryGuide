import Foundation

enum RosaryStepKind: Hashable, Codable {
    case signOfTheCross
    case creed
    case ourFather
    case hailMary
    case gloryBe
    case fatima
    case mysteryAnnouncement
    case hailHolyQueen
    case versicle
    case concludingPrayer
    case saintMichael
    case oSacrament
    case memorare
    case completion
}

struct RosaryStep: Identifiable, Hashable {
    var id: Int
    var kind: RosaryStepKind
    var title: BilingualText
    var body: BilingualText
    var subtitle: BilingualText?
    var mystery: Mystery?
    var decadeNumber: Int?
    var hailMaryNumber: Int?
    var intention: BilingualText?
    var haptic: HapticKind
    var stage: PrayTrackStage
    var bead: BeadLocus?
    var scriptureReference: String?
    /// Last step of a decade (Fatima, O Sacrament or Glory be, depending on settings).
    var closesDecade = false
    /// Last prayer before the finis screen; its button reads "Finish".
    var isLastPrayer = false

    var isPlate: Bool { kind == .mysteryAnnouncement }
    var isFinis: Bool { kind == .completion }

    /// Matches website `#pnow`: Opening / Closing prayers, or `I · The Annunciation` in a decade.
    var progressLabel: String {
        switch stage {
        case .opening:
            return "Opening prayers"
        case .closing:
            return "Closing prayers"
        case .first, .second, .third, .fourth, .fifth:
            if let mystery {
                return "\(OrdinalWord.roman(mystery.number)) · \(mystery.title.english)"
            }
            return OrdinalWord.roman(stage.rawValue)
        }
    }

    var nextLabel: String {
        if isLastPrayer { return "Finish" }
        switch kind {
        case .mysteryAnnouncement: return "Continue"
        case .completion: return "Amen"
        default: return "Next"
        }
    }
}

// MARK: - VoiceOver

extension PrayTrackStage {
    /// Spoken name, e.g. "Opening prayers", "First decade", "Closing prayers".
    var spokenName: String {
        switch self {
        case .opening: "Opening prayers"
        case .closing: "Closing prayers"
        default: "\(OrdinalWord.english(rawValue)) decade"
        }
    }
}

extension BeadLocus {
    /// Where the bead sits, as VoiceOver reads it, e.g. "Hail Mary 3 of 10, first decade".
    var spokenDescription: String {
        switch self {
        case .crucifix: "Crucifix, opening prayers"
        case .openingOurFather: "Our Father, opening prayers"
        case .openingHail(let n): "Hail Mary \(n) of 3, opening prayers"
        case .openingGlory: "Glory Be, opening prayers"
        case .decadeOurFather(let d): "Our Father, \(Self.decade(d))"
        case .decadeHail(let d, let n): "Hail Mary \(n) of 10, \(Self.decade(d))"
        case .decadeGlory(let d): "Glory Be, \(Self.decade(d))"
        case .decadeFatima(let d): "Fatima Prayer, \(Self.decade(d))"
        case .closing: "Closing prayers"
        }
    }

    private static func decade(_ d: Int) -> String {
        (1...5).contains(d) ? "\(OrdinalWord.english(d).lowercased()) decade" : "decade \(d)"
    }
}

extension RosaryStep {
    /// The step as VoiceOver announces it: the prayer, its count and its place,
    /// e.g. "Hail Mary 3 of 10, first decade" or "First Joyful Mystery, The Annunciation".
    var spokenProgress: String {
        let name = title.english
        if isPlate, let mystery {
            return "\(OrdinalWord.english(mystery.number)) \(mystery.set.shortName) Mystery, \(mystery.title.english)"
        }
        if kind == .hailMary, let n = hailMaryNumber {
            if let d = decadeNumber, (1...5).contains(d) {
                return "\(name) \(n) of 10, \(OrdinalWord.english(d).lowercased()) decade"
            }
            return "\(name) \(n) of 3, opening prayers"
        }
        if isFinis { return name }
        return "\(name), \(stage.spokenName.prefix(1).lowercased() + stage.spokenName.dropFirst())"
    }
}
