package app.rosaryguide.android

import android.app.Application
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.notifications.ReminderEnvironment
import app.rosaryguide.notifications.ReminderScheduler
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class RosaryGuideApplication : Application() {
    @Inject lateinit var settingsStore: SettingsStore
    @Inject lateinit var reminderScheduler: ReminderScheduler

    override fun onCreate() {
        super.onCreate()
        ReminderEnvironment.reschedule = {
            reminderScheduler.reschedule(settingsStore.current)
        }
        reminderScheduler.ensureChannel()
        reminderScheduler.reschedule(settingsStore.current)
    }
}
