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
        var feastMinutes: Int = 8 * 60

        var isEmpty: Bool { !dailyEnabled && !feastsEnabled }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the system permission prompt only if the user hasn't decided yet.
    /// Returns true when notifications are allowed.
    static func requestPermission() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            return granted ?? false
        default:
            return false
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

    /// Removes every pending and delivered Rosary Guide notification.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Daily reminder

    /// One repeating trigger per weekday so reminders keep coming even if the app
    /// isn't opened. Mon–Sat mysteries are fixed by weekday; Sunday depends on the
    /// season, so its copy is refreshed whenever the app becomes active.
    private static func dailyRequests(minutes: Int, now: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let hour = max(0, min(23, minutes / 60))
        let minute = max(0, min(59, minutes % 60))
        let today = calendar.startOfDay(for: now)

        return (1...7).compactMap { weekday in
            // Next date (today included) that falls on this weekday, for the mystery set.
            let offset = (weekday - calendar.component(.weekday, from: today) + 7) % 7
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let set = MysteryCalendar.assignment(on: day).set

            let content = UNMutableNotificationContent()
            content.title = "Time to pray"
            content.body = "Today: the \(set.shortName) Mysteries. Take a few quiet minutes for the Rosary."
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

    // MARK: - Feast days

    /// One alert at the chosen time (default 8:00 am) on each upcoming feast day in the
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
                content.title = "Feast day"
                content.body = feasts.map { $0.feast.name.english }.joined(separator: " · ")
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
