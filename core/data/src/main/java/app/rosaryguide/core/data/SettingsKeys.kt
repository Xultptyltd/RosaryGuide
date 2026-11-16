package app.rosaryguide.core.data

import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey

/**
 * DataStore preference keys. Names and merge rules will be aligned with the iOS
 * `SettingsStore` / Firestore field names in later milestones. No Firebase yet.
 */
object SettingsKeys {
    val OnboardingCompleted = booleanPreferencesKey("onboarding.completed")
    val Appearance = stringPreferencesKey("appearance")
}
