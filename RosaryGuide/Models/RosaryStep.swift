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

    var isOpening: Bool { stage == .opening }
    var isClosing: Bool { stage == .closing || kind == .completion }
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
        switch kind {
        case .mysteryAnnouncement: "Continue"
        case .completion: "Amen"
        default: "Next"
        }
    }
}
