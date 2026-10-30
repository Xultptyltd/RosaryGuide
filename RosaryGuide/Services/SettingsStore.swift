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
        static let bluePrimaryIconMigrated = "settings.appIcon.bluePrimaryMigrated"
        static let rosaryConfig = "settings.rosaryConfig"
        static let updatedAt = "settings.updatedAt"
        static let fieldUpdatedAt = "settings.fieldUpdatedAt"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var language: PrayerLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            if rosaryLanguage != language {
                rosaryLanguage = language
            }
            userChanged(.prayerLanguage)
        }
    }

    var rosaryLanguage: PrayerLanguage {
        didSet {
            defaults.set(rosaryLanguage.rawValue, forKey: Keys.rosaryLanguage)
            userChanged(.rosaryLanguage)
        }
    }

    var appearance: AppearancePreference {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
            userChanged(.appearance)
        }
    }

    /// Optional extra after Finis — never inserted into the seven-stage rosary.
    var includeSaintMichael: Bool {
        didSet {
            defaults.set(includeSaintMichael, forKey: Keys.saintMichael)
            userChanged(.includeSaintMichael)
        }
    }

    /// Rosary settings (scripture, optional prayers, intention step). Synced with the
    /// other preferences (`rosaryConfig` in firestore.rules).
    /// Saint Michael is not on the Rosary settings page; it stays the optional
    /// button on the finish screen, so the config keeps its default (off).
    var rosaryConfig: RosaryConfig {
        didSet {
            if let data = try? JSONEncoder().encode(rosaryConfig) {
                defaults.set(data, forKey: Keys.rosaryConfig)
            }
            if rosaryConfig != oldValue { userChanged(.rosaryConfig) }
        }
    }

    /// The config a new Rosary is built with.
    var currentRosaryConfig: RosaryConfig {
        rosaryConfig
    }

    /// Haptics are always on; there is no longer a setting to turn them off.
    var hapticsEnabled: Bool { true }

    var textSize: PrayerTextSize {
        didSet {
            defaults.set(textSize.rawValue, forKey: Keys.textSize)
            userChanged(.textSize)
        }
    }

    /// Daily Rosary reminder (local notification).
    var dailyReminderEnabled: Bool {
        didSet {
            defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminder)
            userChanged(.dailyReminderEnabled)
        }
    }

    /// Reminder time as minutes after local midnight (default 7:00 pm).
    var dailyReminderMinutes: Int {
        didSet {
            defaults.set(dailyReminderMinutes, forKey: Keys.dailyReminderMinutes)
            userChanged(.dailyReminderMinutes)
        }
    }

    /// Alerts on feast days from the app's feast calendar.
    var feastAlertsEnabled: Bool {
        didSet {
            defaults.set(feastAlertsEnabled, forKey: Keys.feastAlerts)
            userChanged(.feastAlertsEnabled)
        }
    }

    /// Feast day alert time as minutes after local midnight (default 8:00 am).
    var feastAlertMinutes: Int {
        didSet {
            defaults.set(feastAlertMinutes, forKey: Keys.feastAlertMinutes)
            userChanged(.feastAlertMinutes)
        }
    }

    /// The eye toggle on the Offer screen that hides intention text.
    var hideIntentionText: Bool {
        didSet {
            defaults.set(hideIntentionText, forKey: Keys.hideIntentionText)
            userChanged(.hideIntentionText)
        }
    }

    /// The Home Screen icon the user chose. `AppIconService` applies it.
    var appIconChoice: AppIconOption {
        didSet {
            defaults.set(appIconChoice.rawValue, forKey: Keys.appIcon)
            userChanged(.appIcon)
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

    /// When each synced preference was last changed (`SyncedPreferences.Field` raw values),
    /// so two devices changing different settings both keep their change.
    private(set) var fieldUpdatedAt: [String: Date] {
        didSet {
            defaults.set(fieldUpdatedAt.mapValues(\.timeIntervalSince1970), forKey: Keys.fieldUpdatedAt)
        }
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
        rosaryLanguage = PrayerLanguage(rawValue: defaults.string(forKey: Keys.rosaryLanguage) ?? "") ?? legacyLanguage
        appearance = AppearancePreference(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        includeSaintMichael = defaults.object(forKey: Keys.saintMichael) as? Bool ?? false
        rosaryConfig = defaults.data(forKey: Keys.rosaryConfig)
            .flatMap { try? JSONDecoder().decode(RosaryConfig.self, from: $0) } ?? .default
        // Drop any stored "off" from the old Haptics toggle.
        defaults.removeObject(forKey: Keys.haptics)
        textSize = PrayerTextSize(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .medium
        dailyReminderEnabled = defaults.bool(forKey: Keys.dailyReminder)
        dailyReminderMinutes = defaults.object(forKey: Keys.dailyReminderMinutes) as? Int ?? 19 * 60
        feastAlertsEnabled = defaults.bool(forKey: Keys.feastAlerts)
        feastAlertMinutes = defaults.object(forKey: Keys.feastAlertMinutes) as? Int ?? SyncedPreferences.defaultFeastAlertMinutes
        hideIntentionText = defaults.bool(forKey: Keys.hideIntentionText)
        appIconChoice = AppIconOption(rawValue: defaults.string(forKey: Keys.appIcon) ?? "") ?? .blue
        preferencesUpdatedAt = Date(timeIntervalSince1970: defaults.double(forKey: Keys.updatedAt))
        fieldUpdatedAt = (defaults.dictionary(forKey: Keys.fieldUpdatedAt) as? [String: Double] ?? [:])
            .mapValues { Date(timeIntervalSince1970: $0) }
        fillMissingFieldTimes()
    }

    /// Settings from before per-field times: every field counts as changed when the set last
    /// changed. Keeps their merge exactly as it was until a field is changed again.
    private func fillMissingFieldTimes() {
        guard preferencesUpdatedAt != .syncNever else { return }
        var times = fieldUpdatedAt
        for field in SyncedPreferences.Field.allCases where times[field.rawValue] == nil {
            times[field.rawValue] = preferencesUpdatedAt
        }
        if times != fieldUpdatedAt { fieldUpdatedAt = times }
    }

    func toggleLightDark(systemIsDark: Bool) {
        let current = appearance.resolved(systemIsDark: systemIsDark)
        appearance = current == .dark ? .light : .dark
    }

    private func userChanged(_ field: SyncedPreferences.Field) {
        guard !isApplyingSynced else { return }
        let now = Date().syncRounded
        fieldUpdatedAt[field.rawValue] = now
        preferencesUpdatedAt = now
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
            updatedAt: preferencesUpdatedAt,
            rosaryConfig: rosaryConfig,
            fieldUpdatedAt: fieldUpdatedAt
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
        if let config = value.rosaryConfig, rosaryConfig != config { rosaryConfig = config }
        preferencesUpdatedAt = value.updatedAt
        fieldUpdatedAt = value.fieldUpdatedAt
    }

    /// Records the icon already on the Home Screen as the choice, without counting it as a change.
    func applySyncedAppIconChoice(_ option: AppIconOption) {
        isApplyingSynced = true
        defer { isApplyingSynced = false }
        appIconChoice = option
    }

    /// Before 1.589 (5) black was the primary icon, so a stored "black" on a device showing the
    /// primary icon was just the old default. Blue is the primary now: once, record blue as a
    /// change so this device and the account follow the new default, and the account's old
    /// "black" does not switch the icon back (with the system alert). Black picked after this
    /// is the black alternate and is kept.
    func migrateToBluePrimaryIcon(showing current: AppIconOption) {
        guard !defaults.bool(forKey: Keys.bluePrimaryIconMigrated) else { return }
        defaults.set(true, forKey: Keys.bluePrimaryIconMigrated)
        guard hasStoredAppIconChoice, appIconChoice == .black, current == .blue else { return }
        appIconChoice = .blue
    }

    /// Gives never-changed preferences a real timestamp before their first upload.
    func stampPreferences() {
        preferencesUpdatedAt = Date().syncRounded
        fillMissingFieldTimes()
    }

    /// Restores synced preferences to defaults while keeping the Home Screen icon
    /// already on the device (changing it would show a system alert). Assignments
    /// go through the property setters so the wipe is persisted and synced.
    func resetLocalPreferences(keepingAppIcon icon: AppIconOption) {
        language = .english
        rosaryLanguage = .english
        appearance = .system
        includeSaintMichael = false
        rosaryConfig = .default
        textSize = .medium
        dailyReminderEnabled = false
        dailyReminderMinutes = 19 * 60
        feastAlertsEnabled = false
        feastAlertMinutes = SyncedPreferences.defaultFeastAlertMinutes
        hideIntentionText = false
        appIconChoice = icon
        // Every field counts as changed now, including ones that already had the default.
        let now = Date().syncRounded
        preferencesUpdatedAt = now
        fieldUpdatedAt = Dictionary(uniqueKeysWithValues: SyncedPreferences.Field.allCases.map { ($0.rawValue, now) })
    }
}
