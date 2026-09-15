import Foundation

struct MysteryAssignment: Equatable {
    var set: MysterySetKind
    var reason: String
    var season: LiturgicalSeason
    var feastOverride: DatedFeast?
}

enum MysteryCalendar {
    static func assignment(on date: Date, calendar: Calendar = LiturgicalCalendar.gregorian) -> MysteryAssignment {
        let season = LiturgicalCalendar.season(on: date, calendar: calendar)
        let weekday = calendar.component(.weekday, from: date)
        let feasts = FeastCatalog.feasts(on: date, calendar: calendar)
        let overrideFeast = feasts.first { feastShouldOverride($0.feast) }

        if let overrideFeast, let set = overrideFeast.feast.suggestedMysterySet {
            return MysteryAssignment(
                set: set,
                reason: "Today is \(overrideFeast.feast.name.english). The \(set.name.english) belong to this feast.",
                season: season,
                feastOverride: overrideFeast
            )
        }

        let set: MysterySetKind
        let reason: String

        switch weekday {
        case 1: // Sunday
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

        return MysteryAssignment(set: set, reason: reason, season: season, feastOverride: feasts.first)
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

    private static func feastShouldOverride(_ feast: Feast) -> Bool {
        switch feast.id {
        case "christmas", "annunciation", "good-friday", "easter", "pentecost",
             "assumption", "immaculate-conception", "rosary", "holy-thursday",
             "baptism-movable", "corpus-christi":
            return true
        default:
            return false
        }
    }
}
