import Foundation
import Observation
import UIKit

/// The current calendar day, refreshed at midnight, on time or time-zone changes and when
/// the app becomes active. Views that read `today` redraw when the day rolls over.
@MainActor
@Observable
final class DayClock {
    private(set) var today: Date
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
        if day != today { today = day }
    }
}

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

        return MysteryAssignment(set: set, reason: set.themeSummary, season: season, feast: feast)
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
