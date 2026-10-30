import Foundation
import Observation
import UIKit

/// The current calendar day, refreshed at midnight, on time or time-zone changes and when
/// the app becomes active. Views that read `today` redraw when the day rolls over.
@MainActor
@Observable
final class DayClock {
    private(set) var today: Date
    /// On a feast with its own recommended set, the user chose the weekday set instead.
    /// Shared by Home and the Pray hub, and reset when the day rolls over.
    var prefersWeekdaySet = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(now: Date = Date()) {
        today = Calendar.current.startOfDay(for: now)
        let names: [Notification.Name] = [
            .NSCalendarDayChanged,
            .NSSystemTimeZoneDidChange,
            UIApplication.significantTimeChangeNotification
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                MainActor.assumeIsolated {
                    if note.name == .NSSystemTimeZoneDidChange { NSTimeZone.resetSystemTimeZone() }
                    self?.refresh()
                }
            }
        }
    }

    /// Moves `today` forward (or back) when the calendar day has changed.
    func refresh(now: Date = Date()) {
        let day = Calendar.current.startOfDay(for: now)
        if day != today {
            today = day
            prefersWeekdaySet = false
        }
    }
}

struct MysteryAssignment: Equatable {
    var set: MysterySetKind
    var reason: String
    var season: LiturgicalSeason
    var feast: DatedFeast?
    /// Advent and Lent Sundays: the seasonal set, offered the same way as a feast's.
    var seasonalSunday: SeasonalSundaySuggestion? = nil

    /// A major feast's set wins; otherwise an Advent or Lent Sunday's set.
    var feastSuggestion: MysterySetKind? {
        if let feast = feast?.feast, feast.recommendsOnHome, let suggested = feast.suggestedMysterySet {
            return suggested != set ? suggested : nil
        }
        guard let seasonalSunday, seasonalSunday.set != set else { return nil }
        return seasonalSunday.set
    }

    /// The set Home and the Pray hub offer by default: the feast's recommended set when it
    /// differs from the weekday's, unless the user chose the weekday set for today.
    func defaultSet(prefersWeekday: Bool) -> MysterySetKind {
        prefersWeekday ? set : (feastSuggestion ?? set)
    }

    /// The set the Home picker's dot marks: always the weekday set, never a feast's.
    var pickerDotSet: MysterySetKind { self.set }

    /// A set picked by hand always wins over the default.
    func shownSet(manual: MysterySetKind?, prefersWeekday: Bool) -> MysterySetKind {
        manual ?? defaultSet(prefersWeekday: prefersWeekday)
    }

    /// Home's feast line, split so the set name can be an inline link:
    /// "<today> Many pray the <setName> <occasion>."
    var feastLine: FeastLine? {
        guard let suggested = feastSuggestion else { return nil }
        if let feast = feast?.feast, feast.recommendsOnHome {
            guard let celebration = feast.celebration else { return nil }
            return FeastLine(lead: "\(celebration.today) Many pray the ",
                             setName: "\(suggested.shortName) Mysteries",
                             tail: " \(celebration.occasion).")
        }
        guard let seasonalSunday else { return nil }
        return FeastLine(lead: "Many pray the ",
                         setName: "\(suggested.shortName) Mysteries",
                         tail: " \(seasonalSunday.occasion)")
    }
}

/// Some pray the Joyful Mysteries on Advent Sundays and the Sorrowful on Lent Sundays
/// (Palm Sunday included). The weekday set stays Glorious; this is only a suggestion.
struct SeasonalSundaySuggestion: Equatable {
    var set: MysterySetKind
    /// Ends the line, e.g. "on Sundays of Advent".
    var occasion: String

    static func on(_ date: Date, season: LiturgicalSeason, calendar: Calendar = LiturgicalCalendar.gregorian) -> SeasonalSundaySuggestion? {
        guard calendar.component(.weekday, from: date) == 1 else { return nil }
        switch season {
        case .advent: return SeasonalSundaySuggestion(set: .joyful, occasion: "on Sundays of Advent")
        case .lent: return SeasonalSundaySuggestion(set: .sorrowful, occasion: "on Sundays of Lent")
        default: return nil
        }
    }
}

struct FeastLine: Equatable {
    var lead: String
    var setName: String
    var tail: String
    var text: String { lead + setName + tail }
    static let backToTodayTitle = "Back to today"
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
            // Sundays always take the Glorious Mysteries, in every season.
            set = .glorious
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

        return MysteryAssignment(set: set, reason: set.themeSummary, season: season, feast: feast,
                                 seasonalSunday: SeasonalSundaySuggestion.on(date, season: season, calendar: calendar))
    }

    /// Week strip starting on the user's first weekday (Monday in Australia), the same
    /// weeks the prayer rhythm card and the Feasts calendar use.
    static func week(
        containing date: Date,
        calendar: Calendar = LiturgicalCalendar.gregorian,
        firstWeekday: Int = Calendar.current.firstWeekday
    ) -> [(Date, MysteryAssignment)] {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday … 7 = Saturday
        let startOffset = -((weekday - firstWeekday + 7) % 7)
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
