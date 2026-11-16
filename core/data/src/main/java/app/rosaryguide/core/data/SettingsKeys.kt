package app.rosaryguide.core.data

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey

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
}
