import Foundation
import Observation

@Observable
final class SettingsStore {
    private enum Keys {
        static let language = "settings.language"
        static let rosaryLanguage = "settings.rosaryLanguage"
        static let appearance = "settings.appearance"
        static let saintMichael = "settings.includeSaintMichael"
        static let haptics = "settings.hapticsEnabled"
        static let textSize = "settings.textSize"
        static let dailyReminder = "settings.notifications.dailyReminder"
        static let dailyReminderMinutes = "settings.notifications.dailyReminderMinutes"
        static let feastAlerts = "settings.notifications.feastAlerts"
    }

    var language: PrayerLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
            if rosaryLanguage != language {
                rosaryLanguage = language
            }
        }
    }

    var rosaryLanguage: PrayerLanguage {
        didSet { UserDefaults.standard.set(rosaryLanguage.rawValue, forKey: Keys.rosaryLanguage) }
    }

    var appearance: AppearancePreference {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Optional extra after Finis — never inserted into the seven-stage rosary.
    var includeSaintMichael: Bool {
        didSet { UserDefaults.standard.set(includeSaintMichael, forKey: Keys.saintMichael) }
    }

    /// Haptics are always on; there is no longer a setting to turn them off.
    var hapticsEnabled: Bool { true }

    var textSize: PrayerTextSize {
        didSet { UserDefaults.standard.set(textSize.rawValue, forKey: Keys.textSize) }
    }

    /// Daily Rosary reminder (local notification).
    var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: Keys.dailyReminder) }
    }

    /// Reminder time as minutes after local midnight (default 7:00 pm).
    var dailyReminderMinutes: Int {
        didSet { UserDefaults.standard.set(dailyReminderMinutes, forKey: Keys.dailyReminderMinutes) }
    }

    /// 8:00 am alerts on feast days from the app's feast calendar.
    var feastAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(feastAlertsEnabled, forKey: Keys.feastAlerts) }
    }

    var notificationPlan: NotificationService.Plan {
        NotificationService.Plan(
            dailyEnabled: dailyReminderEnabled,
            dailyMinutes: dailyReminderMinutes,
            feastsEnabled: feastAlertsEnabled
        )
    }

    init(defaults: UserDefaults = .standard) {
        let legacyLanguage = PrayerLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        language = legacyLanguage
        rosaryLanguage = legacyLanguage
        appearance = AppearancePreference(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        includeSaintMichael = defaults.object(forKey: Keys.saintMichael) as? Bool ?? false
        // Drop any stored "off" from the old Haptics toggle.
        defaults.removeObject(forKey: Keys.haptics)
        textSize = PrayerTextSize(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .medium
        dailyReminderEnabled = defaults.bool(forKey: Keys.dailyReminder)
        dailyReminderMinutes = defaults.object(forKey: Keys.dailyReminderMinutes) as? Int ?? 19 * 60
        feastAlertsEnabled = defaults.bool(forKey: Keys.feastAlerts)
    }

    func toggleLightDark(systemIsDark: Bool) {
        let current = appearance.resolved(systemIsDark: systemIsDark)
        appearance = current == .dark ? .light : .dark
    }
}
