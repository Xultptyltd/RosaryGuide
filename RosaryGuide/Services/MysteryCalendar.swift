import Foundation

struct MysteryAssignment: Equatable {
    var set: MysterySetKind
    var reason: String
    var season: LiturgicalSeason
    var feast: DatedFeast?

    var feastSuggestion: MysterySetKind? {
        guard let suggested = feast?.feast.suggestedMysterySet, suggested != set else { return nil }
        return suggested
    }
}

enum MysteryCalendar {
    static func assignment(on date: Date, calendar: Calendar = LiturgicalCalendar.gregorian) -> MysteryAssignment {
        let season = LiturgicalCalendar.season(on: date, calendar: calendar)
        let weekday = calendar.component(.weekday, from: date)
        let feast = FeastCatalog.feasts(on: date, calendar: calendar)
            .sorted { lhs, rhs in
                rankScore(lhs.feast.rank) > rankScore(rhs.feast.rank)
            }
            .first

        let set: MysterySetKind
        let reason: String

        switch weekday {
        case 1:
            switch season {
            case .advent, .christmas:
                set = .joyful
                reason = "Sundays of \(season.name.english) take the Joyful Mysteries."
            case .lent, .triduum:
                set = .sorrowful
                reason = "Sundays of Lent take the Sorrowful Mysteries."
            case .easter:
                set = .glorious
                reason = "Sundays of Easter take the Glorious Mysteries."
            case .ordinary:
                set = .glorious
                reason = "Sundays of Ordinary Time take the Glorious Mysteries."
            }
        case 2:
            set = .joyful
            reason = "Mondays take the Joyful Mysteries."
        case 3:
            set = .sorrowful
            reason = "Tuesdays take the Sorrowful Mysteries."
        case 4:
            set = .glorious
            reason = "Wednesdays take the Glorious Mysteries."
        case 5:
            set = .luminous
            reason = "Thursdays take the Luminous Mysteries."
        case 6:
            set = .sorrowful
            reason = "Fridays take the Sorrowful Mysteries."
        default:
            set = .joyful
            reason = "Saturdays take the Joyful Mysteries."
        }

        return MysteryAssignment(set: set, reason: reason, season: season, feast: feast)
    }

    static func week(containing date: Date, calendar: Calendar = LiturgicalCalendar.gregorian) -> [(Date, MysteryAssignment)] {
        let weekday = calendar.component(.weekday, from: date)
        let startOffset = 1 - weekday
        guard let start = calendar.date(byAdding: .day, value: startOffset, to: calendar.startOfDay(for: date)) else {
            return [(date, assignment(on: date, calendar: calendar))]
        }
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return (day, assignment(on: day, calendar: calendar))
        }
    }

    private static func rankScore(_ rank: FeastRank) -> Int {
        switch rank {
        case .solemnity: return 5
        case .feast: return 4
        case .memorial: return 3
        case .optionalMemorial: return 2
        case .seasonal: return 1
        }
    }
}
