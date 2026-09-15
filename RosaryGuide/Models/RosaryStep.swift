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

    var progressLabel: String {
        switch kind {
        case .mysteryAnnouncement:
            if let mystery { return "\(OrdinalWord.english(mystery.number)) \(mystery.set.shortName)" }
            return "Mystery"
        case .hailMary:
            if let decadeNumber, let hailMaryNumber {
                return "Decade \(decadeNumber) · Hail Mary \(hailMaryNumber)"
            }
            if let intention { return intention.english }
            return "Hail Mary"
        case .completion:
            return "Finis"
        default:
            return title.english
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
