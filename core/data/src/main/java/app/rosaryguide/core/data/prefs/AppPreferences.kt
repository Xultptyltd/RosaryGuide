package app.rosaryguide.core.data.prefs

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import app.rosaryguide.core.data.SettingsKeys
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

data class SessionFlags(
    val onboardingCompleted: Boolean = false,
    val askedForNotifications: Boolean = false,
    val authProvider: String = "none",
    val authUserId: String? = null,
) {
    val isSignedIn: Boolean get() = authProvider == "google"
    val isGuest: Boolean get() = authProvider == "guest"
}

interface AppPreferences {
    val flags: Flow<SessionFlags>
    suspend fun setOnboardingCompleted(value: Boolean)
    suspend fun setAskedForNotifications(value: Boolean)
    suspend fun setAuth(provider: String, userId: String?)
}

class DataStoreAppPreferences(
    private val dataStore: DataStore<Preferences>,
) : AppPreferences {
    override val flags: Flow<SessionFlags> = dataStore.data.map { prefs ->
        SessionFlags(
            onboardingCompleted = prefs[SettingsKeys.OnboardingCompleted] ?: false,
            askedForNotifications = prefs[SettingsKeys.AskedForNotifications] ?: false,
            authProvider = prefs[SettingsKeys.AuthProvider] ?: "none",
            authUserId = prefs[SettingsKeys.AuthUserId],
        )
    }.distinctUntilChanged()

    override suspend fun setOnboardingCompleted(value: Boolean) {
        dataStore.edit { it[SettingsKeys.OnboardingCompleted] = value }
    }

    override suspend fun setAskedForNotifications(value: Boolean) {
        dataStore.edit { it[SettingsKeys.AskedForNotifications] = value }
    }

    override suspend fun setAuth(provider: String, userId: String?) {
        dataStore.edit { prefs ->
            prefs[SettingsKeys.AuthProvider] = provider
            if (userId == null) prefs.remove(SettingsKeys.AuthUserId)
            else prefs[SettingsKeys.AuthUserId] = userId
        }
    }
}

/** In-memory stand-in for JVM tests and previews. */
class InMemoryAppPreferences(
    initial: SessionFlags = SessionFlags(),
) : AppPreferences {
    private val state = MutableStateFlow(initial)
    override val flags: Flow<SessionFlags> = state

    override suspend fun setOnboardingCompleted(value: Boolean) {
        state.value = state.value.copy(onboardingCompleted = value)
    }

    override suspend fun setAskedForNotifications(value: Boolean) {
        state.value = state.value.copy(askedForNotifications = value)
    }

    override suspend fun setAuth(provider: String, userId: String?) {
        state.value = state.value.copy(authProvider = provider, authUserId = userId)
    }
}
