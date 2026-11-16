package app.rosaryguide.core.data.prefs

import app.rosaryguide.core.data.SettingsKeys
import app.rosaryguide.core.data.config.RosaryJson
import app.rosaryguide.core.data.notify.NotificationPlan
import app.rosaryguide.core.data.notify.TimeOfDay
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.RosaryConfig
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class UserSettings(
    val appearance: AppearancePreference = AppearancePreference.System,
    val rosaryConfig: RosaryConfig = RosaryConfig.default,
    val dailyReminderEnabled: Boolean = true,
    val dailyReminderMinutes: Int = TimeOfDay.DEFAULT_REMINDER_MINUTES,
    val feastAlertsEnabled: Boolean = true,
    val feastAlertMinutes: Int = TimeOfDay.DEFAULT_REMINDER_MINUTES,
    val appIcon: AppIconOption = AppIconOption.Blue,
    val lastReviewPromptVersion: String? = null,
) {
    val notificationPlanSettings: NotificationPlan.Settings
        get() = NotificationPlan.Settings(
            dailyEnabled = dailyReminderEnabled,
            dailyMinutes = dailyReminderMinutes,
            feastEnabled = feastAlertsEnabled,
            feastMinutes = feastAlertMinutes,
        )
}

interface SettingsPreferences {
    fun load(): UserSettings
    fun save(settings: UserSettings)
}

class InMemorySettingsPreferences(
    initial: UserSettings = UserSettings(),
) : SettingsPreferences {
    private var stored: UserSettings = initial
    override fun load(): UserSettings = stored
    override fun save(settings: UserSettings) { stored = settings }
}

/**
 * Local settings, ported from iOS `SettingsStore`. Defaults match a new install:
 * both reminder kinds on, at 9:00. Saved values are never overwritten by defaults.
 */
class SettingsStore(
    private val prefs: SettingsPreferences = InMemorySettingsPreferences(),
) {
    private val _value = MutableStateFlow(prefs.load())
    val value: StateFlow<UserSettings> = _value.asStateFlow()
    val current: UserSettings get() = _value.value

    fun update(transform: (UserSettings) -> UserSettings) {
        val next = transform(_value.value)
        _value.value = next
        prefs.save(next)
    }

    fun setAppearance(value: AppearancePreference) = update { it.copy(appearance = value) }
    fun setRosaryConfig(value: RosaryConfig) = update { it.copy(rosaryConfig = value) }
    fun resetRosaryConfig() = setRosaryConfig(RosaryConfig.default)
    fun setDailyReminderEnabled(value: Boolean) = update { it.copy(dailyReminderEnabled = value) }
    fun setDailyReminderMinutes(value: Int) = update { it.copy(dailyReminderMinutes = value) }
    fun setFeastAlertsEnabled(value: Boolean) = update { it.copy(feastAlertsEnabled = value) }
    fun setFeastAlertMinutes(value: Int) = update { it.copy(feastAlertMinutes = value) }
    fun setAppIcon(value: AppIconOption) = update { it.copy(appIcon = value) }
    fun markReviewPrompted(version: String) = update { it.copy(lastReviewPromptVersion = version) }

    fun resetLocalPreferences(keepingAppIcon: AppIconOption = current.appIcon) {
        update {
            UserSettings(appIcon = keepingAppIcon)
        }
    }

    fun toggleLightDark(systemIsDark: Boolean) {
        val dark = current.appearance.isDark(systemIsDark)
        setAppearance(if (dark) AppearancePreference.Light else AppearancePreference.Dark)
    }
}

fun encodeRosaryConfig(config: RosaryConfig): String =
    RosaryJson.encodeToString(RosaryConfig.serializer(), config)

fun decodeRosaryConfig(raw: String?): RosaryConfig =
    raw?.let { runCatching { RosaryJson.decodeFromString(RosaryConfig.serializer(), it) }.getOrNull() }
        ?: RosaryConfig.default
