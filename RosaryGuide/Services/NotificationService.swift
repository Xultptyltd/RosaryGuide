import Foundation
import UserNotifications

/// Local notifications: the daily Rosary reminder and feast-day alerts.
/// Everything is scheduled on the device; nothing goes through a server.
enum NotificationService {
    static let dailyPrefix = "rosary.daily."
    static let feastPrefix = "rosary.feast."

    /// iOS keeps at most 64 pending local notifications per app. The daily
    /// reminder uses 7 (one repeating trigger per weekday), feasts up to 30.
    private static let feastDayLimit = 30

    /// What should be scheduled, taken from SettingsStore.
    struct Plan: Equatable, Sendable {
        var dailyEnabled: Bool
        var dailyMinutes: Int
        var feastsEnabled: Bool
        var feastMinutes: Int = SyncedPreferences.defaultFeastAlertMinutes

        var isEmpty: Bool { !dailyEnabled && !feastsEnabled }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the system permission prompt only if the user hasn't decided yet.
    /// Returns true when notifications are allowed. Records `askedForNotifications`
    /// on this device so Home will not ask again.
    static func requestPermission(defaults: UserDefaults = .standard) async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            NotificationPrompt.markAsked(in: defaults)
            let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            return granted ?? false
        default:
            return false
        }
    }

    /// First arrival at Home after onboarding or sign-in: ask once if the
    /// system status is still undecided, then schedule the default plan if granted.
    static func askOnHomeArrival(plan: Plan, defaults: UserDefaults = .standard) async {
        let status = await authorizationStatus()
        guard NotificationPrompt.shouldAsk(status: status, hasAsked: NotificationPrompt.hasAsked(in: defaults)) else {
            return
        }
        if await requestPermission(defaults: defaults) {
            await reschedule(plan)
        }
    }

    /// Replaces every pending Rosary Guide notification with what the plan asks for.
    /// Safe to call often (launch, foreground, settings change).
    static func reschedule(_ plan: Plan, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(dailyPrefix) || $0.hasPrefix(feastPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        guard !plan.isEmpty else { return }
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }

        var requests: [UNNotificationRequest] = []
        if plan.dailyEnabled {
            requests += dailyRequests(minutes: plan.dailyMinutes, now: now)
        }
        if plan.feastsEnabled {
            requests += feastRequests(minutes: plan.feastMinutes, now: now)
        }
        for request in requests {
            try? await center.add(request)
        }
    }

    // MARK: - Daily reminder

    /// One repeating trigger per weekday so reminders keep coming even if the app
    /// isn't opened. Every weekday has a fixed set (Sundays are always Glorious).
    private static func dailyRequests(minutes: Int, now: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let hour = max(0, min(23, minutes / 60))
        let minute = max(0, min(59, minutes % 60))
        let today = calendar.startOfDay(for: now)

        return (1...7).compactMap { weekday in
            // Next date (today included) that falls on this weekday, for the mystery set.
            let offset = (weekday - calendar.component(.weekday, from: today) + 7) % 7
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let content = UNMutableNotificationContent()
            // One line in the body; the lock screen already heads it with the app name.
            content.body = dailyBody(weekday: weekday, day: day)
            content.sound = .default
            content.threadIdentifier = "rosary.daily"

            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            return UNNotificationRequest(identifier: "\(dailyPrefix)\(weekday)", content: content, trigger: trigger)
        }
    }

    static func dailyBody(weekday: Int, day: Date) -> String {
        let set = MysteryCalendar.assignment(on: day).set
        return "Time to pray the \(set.shortName) Mysteries. Take a few quiet minutes for the Rosary."
    }

    // MARK: - Feast days

    /// "Today is the solemnity of All Saints"; several feasts on one day join with "and".
    static func feastBody(_ feasts: [Feast]) -> String {
        "Today is " + feasts.map(feastPhrase).joined(separator: " and ")
    }

    /// "the memorial of Our Lady of the Rosary". Seasonal days have no rank word, so they
    /// read as the day itself: "Ash Wednesday", "the First Sunday of Advent".
    static func feastPhrase(_ feast: Feast) -> String {
        let name = feast.name.english
        let named = articled(name)
        guard let rank = feast.rank.notificationWord else { return named }
        return "the \(rank) of \(named)"
    }

    /// Mystery and season names take "the" ("the Presentation of the Lord", "the First Sunday
    /// of Advent"); people and titles don't ("All Saints", "Saint Joseph", "Our Lady of Lourdes").
    private static func articled(_ name: String) -> String {
        if name.hasPrefix("The ") { return "the " + name.dropFirst(4) }
        let takesArticle = ["Presentation", "Epiphany", "Annunciation", "Visitation", "Nativity", "Baptism",
                            "Ascension", "Assumption", "Commemoration", "First", "Second", "Third", "Fourth", "Fifth"]
        return takesArticle.contains { name.hasPrefix($0 + " ") } ? "the " + name : name
    }

    /// One alert at the chosen time (default 9:00 am) on each upcoming feast day in the
    /// app's own feast calendar.
    private static func feastRequests(minutes: Int, now: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let hour = max(0, min(23, minutes / 60))
        let minute = max(0, min(59, minutes % 60))
        let upcoming = FeastCatalog.upcoming(from: now, limit: feastDayLimit * 2, calendar: calendar)
        let byDay = Dictionary(grouping: upcoming) { calendar.startOfDay(for: $0.date) }

        return byDay.keys.sorted()
            .compactMap { day -> UNNotificationRequest? in
                guard
                    let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                    fireDate > now,
                    let feasts = byDay[day], !feasts.isEmpty
                else { return nil }

                let content = UNMutableNotificationContent()
                content.body = feastBody(feasts.map(\.feast))
                content.sound = .default
                content.threadIdentifier = "rosary.feast"

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let id = calendar.dateComponents([.year, .month, .day], from: day)
                return UNNotificationRequest(
                    identifier: "\(feastPrefix)\(id.year ?? 0)-\(id.month ?? 0)-\(id.day ?? 0)",
                    content: content,
                    trigger: trigger
                )
            }
            .prefix(feastDayLimit)
            .map { $0 }
    }
}

/// Device-only permission prompt bookkeeping. Not synced; authorization is per iPhone.
enum NotificationPrompt {
    static let askedKey = "settings.notifications.askedForNotifications"
    /// Wait until the Home transition (splash or sign-in cover) has settled.
    static let homeArrivalDelay: Duration = .seconds(1)

    static func hasAsked(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: askedKey)
    }

    static func markAsked(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: askedKey)
    }

    /// The system prompt is shown only when the user has not decided yet and
    /// we have not already asked on this device. Never re-prompts after a denial.
    static func shouldAsk(status: UNAuthorizationStatus, hasAsked: Bool) -> Bool {
        status == .notDetermined && !hasAsked
    }
}

