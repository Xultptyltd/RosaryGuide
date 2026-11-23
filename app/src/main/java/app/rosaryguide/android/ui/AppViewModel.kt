package app.rosaryguide.android.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.rosaryguide.core.data.auth.AuthStore
import app.rosaryguide.core.data.sync.AccountDeletion
import app.rosaryguide.feature.settings.DeleteAccountResult
import app.rosaryguide.android.icons.AppIconController
import app.rosaryguide.android.review.AppReviewPrompter
import app.rosaryguide.core.data.prefs.AppPreferences
import app.rosaryguide.core.data.catalog.QuotePreferences
import app.rosaryguide.core.data.prefs.SessionFlags
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.DatedFeast
import java.time.ZoneId
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
    val auth: AuthStore,
    private val accountDeletion: AccountDeletion,
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

    /** [onResult] runs with true once Firebase has the Google account (false on cancel or failure). */
    fun signInWithGoogle(onResult: (Boolean) -> Unit = {}) {
        auth.signInWithGoogle { signedIn ->
            if (signedIn) {
                viewModelScope.launch {
                    preferences.setAuth("google", auth.state.value.userId)
                    preferences.setOnboardingCompleted(true)
                }
            }
            onResult(signedIn)
        }
    }

    fun deleteAccount(onResult: (DeleteAccountResult) -> Unit) {
        viewModelScope.launch {
            val result = when (val outcome = accountDeletion.run()) {
                AccountDeletion.Outcome.Deleted -> DeleteAccountResult.Deleted
                AccountDeletion.Outcome.Cancelled -> DeleteAccountResult.Cancelled
                is AccountDeletion.Outcome.Failed -> DeleteAccountResult.Failed(outcome.message)
            }
            if (result == DeleteAccountResult.Deleted) {
                preferences.setAuth("none", null)
                reminderScheduler.reschedule(settingsStore.current)
            }
            onResult(result)
        }
    }

    /** After "Account deleted": back to onboarding, like sign-out. */
    fun finishAccountDeletion() {
        viewModelScope.launch { preferences.setOnboardingCompleted(false) }
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
        appIconController.pending = null
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
        viewModelScope.launch {
            preferences.setOnboardingCompleted(false)
            preferences.setAuth("guest", null)
        }
    }

    fun scheduleFeastReminder(item: DatedFeast, zone: ZoneId = ZoneId.of("Australia/Perth")) {
        reminderScheduler.scheduleRemindMe(item.feast, item.date, settingsStore.current, zone)
    }

    fun maybeRequestReview(activity: Activity, versionName: String) {
        val count = sessionStore.completedSessions.value.size
        reviewPrompter.maybePrompt(activity, count, versionName)
    }
}
