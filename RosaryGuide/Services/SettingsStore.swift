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
        static let feastAlertMinutes = "settings.notifications.feastAlertMinutes"
        /// Shared with the `@AppStorage` readers in the intention views.
        static let hideIntentionText = "offer.hideIntentionText"
        static let appIcon = "settings.appIcon"
        static let updatedAt = "settings.updatedAt"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var language: PrayerLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            if rosaryLanguage != language {
                rosaryLanguage = language
            }
            userChanged()
        }
    }

    var rosaryLanguage: PrayerLanguage {
        didSet {
            defaults.set(rosaryLanguage.rawValue, forKey: Keys.rosaryLanguage)
            userChanged()
        }
    }

    var appearance: AppearancePreference {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
            userChanged()
        }
    }

    /// Optional extra after Finis — never inserted into the seven-stage rosary.
    var includeSaintMichael: Bool {
        didSet {
            defaults.set(includeSaintMichael, forKey: Keys.saintMichael)
            userChanged()
        }
    }

    /// Haptics are always on; there is no longer a setting to turn them off.
    var hapticsEnabled: Bool { true }

    var textSize: PrayerTextSize {
        didSet {
            defaults.set(textSize.rawValue, forKey: Keys.textSize)
            userChanged()
        }
    }

    /// Daily Rosary reminder (local notification).
    var dailyReminderEnabled: Bool {
        didSet {
            defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminder)
            userChanged()
        }
    }

    /// Reminder time as minutes after local midnight (default 7:00 pm).
    var dailyReminderMinutes: Int {
        didSet {
            defaults.set(dailyReminderMinutes, forKey: Keys.dailyReminderMinutes)
            userChanged()
        }
    }

    /// Alerts on feast days from the app's feast calendar.
    var feastAlertsEnabled: Bool {
        didSet {
            defaults.set(feastAlertsEnabled, forKey: Keys.feastAlerts)
            userChanged()
        }
    }

    /// Feast day alert time as minutes after local midnight (default 8:00 am).
    var feastAlertMinutes: Int {
        didSet {
            defaults.set(feastAlertMinutes, forKey: Keys.feastAlertMinutes)
            userChanged()
        }
    }

    /// The eye toggle on the Offer screen that hides intention text.
    var hideIntentionText: Bool {
        didSet {
            defaults.set(hideIntentionText, forKey: Keys.hideIntentionText)
            userChanged()
        }
    }

    /// The Home Screen icon the user chose. `AppIconService` applies it.
    var appIconChoice: AppIconOption {
        didSet {
            defaults.set(appIconChoice.rawValue, forKey: Keys.appIcon)
            userChanged()
        }
    }

    var hasStoredAppIconChoice: Bool {
        defaults.string(forKey: Keys.appIcon) != nil
    }

    /// When the user last changed a synced preference on this device, or the newer time
    /// that came from the account. `.syncNever` means never.
    private(set) var preferencesUpdatedAt: Date {
        didSet { defaults.set(preferencesUpdatedAt.timeIntervalSince1970, forKey: Keys.updatedAt) }
    }

    /// Called after the user changes a synced preference (not when synced values are applied).
    @ObservationIgnored var onUserChange: (() -> Void)?
    @ObservationIgnored private var isApplyingSynced = false

    var notificationPlan: NotificationService.Plan {
        NotificationService.Plan(
            dailyEnabled: dailyReminderEnabled,
            dailyMinutes: dailyReminderMinutes,
            feastsEnabled: feastAlertsEnabled,
            feastMinutes: feastAlertMinutes
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
        feastAlertMinutes = defaults.object(forKey: Keys.feastAlertMinutes) as? Int ?? SyncedPreferences.defaultFeastAlertMinutes
        hideIntentionText = defaults.bool(forKey: Keys.hideIntentionText)
        appIconChoice = AppIconOption(rawValue: defaults.string(forKey: Keys.appIcon) ?? "") ?? .black
        preferencesUpdatedAt = Date(timeIntervalSince1970: defaults.double(forKey: Keys.updatedAt))
    }

    func toggleLightDark(systemIsDark: Bool) {
        let current = appearance.resolved(systemIsDark: systemIsDark)
        appearance = current == .dark ? .light : .dark
    }

    private func userChanged() {
        guard !isApplyingSynced else { return }
        preferencesUpdatedAt = Date().syncRounded
        onUserChange?()
    }

    // MARK: - Sync

    var syncedPreferences: SyncedPreferences {
        SyncedPreferences(
            appearance: appearance,
            prayerLanguage: language,
            rosaryLanguage: rosaryLanguage,
            textSize: textSize,
            includeSaintMichael: includeSaintMichael,
            hideIntentionText: hideIntentionText,
            dailyReminderEnabled: dailyReminderEnabled,
            dailyReminderMinutes: dailyReminderMinutes,
            feastAlertsEnabled: feastAlertsEnabled,
            feastAlertMinutes: feastAlertMinutes,
            appIcon: appIconChoice,
            updatedAt: preferencesUpdatedAt
        )
    }

    /// Replaces the synced preferences without reporting a user change.
    func applySynced(_ preferences: SyncedPreferences) {
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        let value = preferences.normalized
        // Only assign what changed, so views and notifications are not disturbed needlessly.
        if language != value.prayerLanguage { language = value.prayerLanguage }
        if rosaryLanguage != value.rosaryLanguage { rosaryLanguage = value.rosaryLanguage }
        if appearance != value.appearance { appearance = value.appearance }
        if includeSaintMichael != value.includeSaintMichael { includeSaintMichael = value.includeSaintMichael }
        if textSize != value.textSize { textSize = value.textSize }
        if dailyReminderEnabled != value.dailyReminderEnabled { dailyReminderEnabled = value.dailyReminderEnabled }
        if dailyReminderMinutes != value.dailyReminderMinutes { dailyReminderMinutes = value.dailyReminderMinutes }
        if feastAlertsEnabled != value.feastAlertsEnabled { feastAlertsEnabled = value.feastAlertsEnabled }
        if feastAlertMinutes != value.feastAlertMinutes { feastAlertMinutes = value.feastAlertMinutes }
        if hideIntentionText != value.hideIntentionText { hideIntentionText = value.hideIntentionText }
        if appIconChoice != value.appIcon { appIconChoice = value.appIcon }
        preferencesUpdatedAt = value.updatedAt
    }

    /// Records the icon already on the Home Screen as the choice, without counting it as a change.
    func applySyncedAppIconChoice(_ option: AppIconOption) {
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        appIconChoice = option
    }

    /// Gives never-changed preferences a real timestamp before their first upload.
    func stampPreferences() {
        preferencesUpdatedAt = Date().syncRounded
    }

    /// Restores synced preferences to defaults while keeping the Home Screen icon
    /// already on the device (changing it would show a system alert). Assignments
    /// go through the property setters so the wipe is persisted and synced.
    func resetLocalPreferences(keepingAppIcon icon: AppIconOption) {
        language = .english
        rosaryLanguage = .english
        appearance = .system
        includeSaintMichael = false
        textSize = .medium
        dailyReminderEnabled = false
        dailyReminderMinutes = 19 * 60
        feastAlertsEnabled = false
        feastAlertMinutes = SyncedPreferences.defaultFeastAlertMinutes
        hideIntentionText = false
        appIconChoice = icon
        preferencesUpdatedAt = Date().syncRounded
    }
}
