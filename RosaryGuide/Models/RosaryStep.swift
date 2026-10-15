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
