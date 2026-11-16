package app.rosaryguide.core.data

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey

/**
 * DataStore preference keys. Names follow the iOS `SettingsStore` / `@AppStorage` keys
 * so later sync can merge on the same field names. No Firebase yet.
 */
object SettingsKeys {
    val OnboardingCompleted = booleanPreferencesKey("onboarding.completed")
    val Appearance = stringPreferencesKey("appearance")
    val AskedForNotifications = booleanPreferencesKey("settings.notifications.askedForNotifications")
    /** `none`, `guest`, or `google`. Guest is local-only and is not `isSignedIn`. */
    val AuthProvider = stringPreferencesKey("auth.provider")
    val AuthUserId = stringPreferencesKey("auth.userId")
    val SessionPrayer = stringPreferencesKey("session.prayer")
    val SessionCompleted = stringPreferencesKey("session.completedPrayerSessions")
    val SessionCompletedDayKeys = stringSetPreferencesKey("session.completedDayKeys")
    val SessionIntentions = stringPreferencesKey("session.offerIntentions")
    val SessionJourney = stringPreferencesKey("session.journeyState")
    val NextCompletionQuoteIndex = intPreferencesKey("rosary.completion.nextQuoteIndex")
    val LastCompletionQuoteId = stringPreferencesKey("rosary.completion.lastQuoteId")
    val DailyReminder = booleanPreferencesKey("settings.notifications.dailyReminder")
    val DailyReminderMinutes = intPreferencesKey("settings.notifications.dailyReminderMinutes")
    val FeastAlerts = booleanPreferencesKey("settings.notifications.feastAlerts")
    val FeastAlertMinutes = intPreferencesKey("settings.notifications.feastAlertMinutes")
    val AppIcon = stringPreferencesKey("settings.appIcon")
    val RosaryConfig = stringPreferencesKey("settings.rosaryConfig")
    val ReviewLastPromptedVersion = stringPreferencesKey("review.lastPromptedVersion")
}


