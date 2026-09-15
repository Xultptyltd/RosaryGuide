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
    var isOpening: Bool
    var isClosing: Bool

    var progressLabel: String {
        if let decadeNumber, let hailMaryNumber {
            return "Decade \(decadeNumber) · Hail Mary \(hailMaryNumber) of 10"
        }
        if let decadeNumber {
            return "Decade \(decadeNumber) of 5"
        }
        if isOpening { return "Opening" }
        if isClosing { return "Closing" }
        return "Rosary"
    }
}
