package app.rosaryguide.core.data.prefs

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import app.rosaryguide.core.data.SettingsKeys
import app.rosaryguide.core.data.notify.TimeOfDay
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.AppearancePreference
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

class DataStoreSettingsPreferences(
    private val dataStore: DataStore<Preferences>,
) : SettingsPreferences {
    override fun load(): UserSettings = runBlocking {
        val prefs = dataStore.data.first()
        UserSettings(
            appearance = AppearancePreference.entries.firstOrNull {
                it.name.equals(prefs[SettingsKeys.Appearance], ignoreCase = true) ||
                    it.title.equals(prefs[SettingsKeys.Appearance], ignoreCase = true)
            } ?: AppearancePreference.System,
            rosaryConfig = decodeRosaryConfig(prefs[SettingsKeys.RosaryConfig]),
            dailyReminderEnabled = prefs[SettingsKeys.DailyReminder] ?: true,
            dailyReminderMinutes = prefs[SettingsKeys.DailyReminderMinutes] ?: TimeOfDay.DEFAULT_REMINDER_MINUTES,
            feastAlertsEnabled = prefs[SettingsKeys.FeastAlerts] ?: true,
            feastAlertMinutes = prefs[SettingsKeys.FeastAlertMinutes] ?: TimeOfDay.DEFAULT_REMINDER_MINUTES,
            appIcon = AppIconOption.fromStorage(prefs[SettingsKeys.AppIcon]),
            lastReviewPromptVersion = prefs[SettingsKeys.ReviewLastPromptedVersion],
        )
    }

    override fun save(settings: UserSettings) {
        runBlocking {
            dataStore.edit { prefs ->
                prefs[SettingsKeys.Appearance] = settings.appearance.name.lowercase()
                prefs[SettingsKeys.RosaryConfig] = encodeRosaryConfig(settings.rosaryConfig)
                prefs[SettingsKeys.DailyReminder] = settings.dailyReminderEnabled
                prefs[SettingsKeys.DailyReminderMinutes] = settings.dailyReminderMinutes
                prefs[SettingsKeys.FeastAlerts] = settings.feastAlertsEnabled
                prefs[SettingsKeys.FeastAlertMinutes] = settings.feastAlertMinutes
                prefs[SettingsKeys.AppIcon] = settings.appIcon.storageName
                val version = settings.lastReviewPromptVersion
                if (version == null) prefs.remove(SettingsKeys.ReviewLastPromptedVersion)
                else prefs[SettingsKeys.ReviewLastPromptedVersion] = version
            }
        }
    }
}
