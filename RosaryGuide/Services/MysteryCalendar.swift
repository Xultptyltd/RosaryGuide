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
        switch weekday {
        case 1:
            switch season {
            case .advent, .christmas:
                set = .joyful
            case .lent, .triduum:
                set = .sorrowful
            case .easter, .ordinary:
                set = .glorious
            }
        case 2:
            set = .joyful
        case 3:
            set = .sorrowful
        case 4:
            set = .glorious
        case 5:
            set = .luminous
        case 6:
            set = .sorrowful
        default:
            set = .joyful
        }

        return MysteryAssignment(set: set, reason: set.themeSummary, season: season, feast: feast)
    }

    /// Monday–Sunday week strip, matching the website home calendar.
    static func week(containing date: Date, calendar: Calendar = LiturgicalCalendar.gregorian) -> [(Date, MysteryAssignment)] {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday … 7 = Saturday
        let startOffset = weekday == 1 ? -6 : (2 - weekday)
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
