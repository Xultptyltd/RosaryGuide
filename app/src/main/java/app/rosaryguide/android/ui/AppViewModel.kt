package app.rosaryguide.android.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.rosaryguide.core.data.auth.StubAuthStore
import app.rosaryguide.core.data.prefs.AppPreferences
import app.rosaryguide.core.data.catalog.QuotePreferences
import app.rosaryguide.core.data.prefs.SessionFlags
import app.rosaryguide.core.data.session.SessionStore
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class AppViewModel @Inject constructor(
    private val preferences: AppPreferences,
    val auth: StubAuthStore,
    val sessionStore: SessionStore,
    val quotePreferences: QuotePreferences,
) : ViewModel() {
    val flags: StateFlow<SessionFlags> = preferences.flags.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        SessionFlags(),
    )

    fun completeOnboarding() {
        viewModelScope.launch { preferences.setOnboardingCompleted(true) }
    }

    fun markAskedForNotifications() {
        viewModelScope.launch { preferences.setAskedForNotifications(true) }
    }

    fun signInWithGoogle() {
        auth.signInWithGoogle()
        viewModelScope.launch {
            preferences.setAuth("google", auth.state.value.userId)
            preferences.setOnboardingCompleted(true)
        }
    }

    fun continueAsGuest() {
        auth.continueAsGuest()
        viewModelScope.launch {
            preferences.setAuth("guest", null)
            preferences.setOnboardingCompleted(true)
        }
    }
}
