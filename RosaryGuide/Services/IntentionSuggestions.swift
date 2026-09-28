import Foundation

struct SuggestedIntention: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var note: String?
    var sourceLabel: String
    var monthLabel: String?
    var description: String?
    var extract: [String]?
    var sourceTitle: String?
    var sourceURL: String?
}

enum IntentionSuggestions {
    /// Feast-aware + papal suggestions for a given day (defaults to today).
    static func forDay(_ date: Date = Date()) -> [SuggestedIntention] {
        var items: [SuggestedIntention] = []

        if let papal = PopeIntentionStore.shared.intention(for: date) {
            items.append(
                SuggestedIntention(
                    id: "pope-\(papal.yearMonth)",
                    title: papal.title,
                    note: papal.note,
                    sourceLabel: "Holy Father’s Intention",
                    monthLabel: papal.monthLabel,
                    description: papal.description,
                    extract: papal.extract,
                    sourceTitle: papal.sourceTitle,
                    sourceURL: papal.sourceURL
                )
            )
        }

        for dated in FeastCatalog.feasts(on: date) {
            if let suggestion = feastSuggestion(for: dated.feast.id) {
                items.append(
                    SuggestedIntention(
                        id: "feast-\(dated.feast.id)",
                        title: suggestion.title,
                        note: suggestion.note,
                        sourceLabel: "Today · \(dated.feast.shortTitle)"
                    )
                )
            }
        }

        return items
    }

    private struct Seed {
        var title: String
        var note: String?
    }

    private static func feastSuggestion(for id: String) -> Seed? {
        switch id {
        case "all-souls":
            return Seed(title: "For the Holy Souls", note: "Especially those most forgotten.")
        case "all-saints":
            return Seed(title: "For growth in holiness", note: "That we may follow the saints with courage.")
        case "assumption", "queenship", "nativity-mary", "holy-name-mary", "presentation-mary",
             "immaculate-conception", "immaculate-heart", "mary-mother-of-god", "lourdes",
             "fatima", "carmel", "guadalupe", "rosary", "visitation", "annunciation", "sorrows":
            return Seed(title: "For Mary’s intercession", note: "Through the prayers of Our Lady.")
        case "joseph":
            return Seed(title: "For fathers and families", note: "Under the protection of St Joseph.")
        case "peter-paul":
            return Seed(title: "For the Church and her shepherds", note: "For the Holy Father and all bishops.")
        case "michael", "guardian-angels":
            return Seed(title: "For protection from evil", note: "Through the ministry of the holy angels.")
        case "sacred-heart":
            return Seed(title: "In reparation to the Sacred Heart", note: "For mercy on the whole world.")
        case "divine-mercy":
            return Seed(title: "For trust in Divine Mercy", note: "Jesus, I trust in You.")
        case "good-friday", "holy-thursday", "holy-saturday", "palm-sunday", "ash-wednesday":
            return Seed(title: "In union with Christ’s Passion", note: "For conversion of heart.")
        case "easter", "ascension", "pentecost", "trinity", "corpus-christi", "christ-the-king":
            return Seed(title: "In thanksgiving for the mysteries of Christ", note: "Glory to the risen Lord.")
        case "christmas", "epiphany", "presentation", "baptism-movable", "advent-1":
            return Seed(title: "For those awaiting light", note: "That Christ may be born anew in every heart.")
        default:
            return Seed(title: "For the intentions of the Church", note: nil)
        }
    }
}
