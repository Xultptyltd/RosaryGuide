package app.rosaryguide.android

import android.app.Application
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.notifications.ReminderEnvironment
import app.rosaryguide.notifications.ReminderScheduler
import app.rosaryguide.android.di.AppScope
import app.rosaryguide.core.data.auth.AuthStore
import app.rosaryguide.core.data.sync.AccountSync
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

@HiltAndroidApp
class RosaryGuideApplication : Application() {
    @Inject lateinit var settingsStore: SettingsStore
    @Inject lateinit var reminderScheduler: ReminderScheduler
    @Inject lateinit var authStore: AuthStore
    @Inject lateinit var accountSync: AccountSync
    @Inject @AppScope lateinit var appScope: CoroutineScope

    override fun onCreate() {
        super.onCreate()
        ReminderEnvironment.reschedule = {
            reminderScheduler.reschedule(settingsStore.current)
        }
        reminderScheduler.ensureChannel()
        reminderScheduler.reschedule(settingsStore.current)
        // Signing in turns sync on for that account; signing out keeps the data on this device
        // and stops syncing (iOS `.onChange(of: auth.userID)`).
        appScope.launch {
            authStore.state.map { it.userId }.distinctUntilChanged().collect { accountSync.configureSync(it) }
        }
    }
}
