package app.rosaryguide.android.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.rosaryguide.core.data.auth.StubAuthStore
import app.rosaryguide.android.icons.AppIconController
import app.rosaryguide.android.review.AppReviewPrompter
import app.rosaryguide.core.data.prefs.AppPreferences
import app.rosaryguide.core.data.catalog.QuotePreferences
import app.rosaryguide.core.data.prefs.SessionFlags
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.notifications.ReminderScheduler
import android.app.Activity
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
    val settingsStore: SettingsStore,
    private val reminderScheduler: ReminderScheduler,
    private val appIconController: AppIconController,
    private val reviewPrompter: AppReviewPrompter,
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

    fun rescheduleReminders() {
        reminderScheduler.reschedule(settingsStore.current)
    }

    fun setAppIcon(option: AppIconOption) {
        settingsStore.setAppIcon(option)
        appIconController.apply(option)
    }

    fun clearAppHistory() {
        sessionStore.clearHistoryAndData()
        settingsStore.resetLocalPreferences()
        reminderScheduler.reschedule(settingsStore.current)
    }

    fun signOut() {
        auth.signOut()
        viewModelScope.launch { preferences.setAuth("guest", null) }
    }

    fun maybeRequestReview(activity: Activity, versionName: String) {
        val count = sessionStore.completedSessions.value.size
        reviewPrompter.maybePrompt(activity, count, versionName)
    }
}
