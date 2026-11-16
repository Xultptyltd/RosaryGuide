package app.rosaryguide.android.review

import android.app.Activity
import app.rosaryguide.core.data.notify.ReviewPromptGate
import app.rosaryguide.core.data.prefs.SettingsStore
import com.google.android.play.core.review.ReviewManagerFactory

class AppReviewPrompter(
    private val settingsStore: SettingsStore,
) {
    fun maybePrompt(activity: Activity, completedRosaries: Int, versionName: String) {
        val gate = ReviewPromptGate(
            currentVersion = versionName,
            lastPromptedVersion = settingsStore.current.lastReviewPromptVersion,
        )
        if (!gate.shouldPrompt(completedRosaries)) return
        val manager = ReviewManagerFactory.create(activity)
        manager.requestReviewFlow().addOnCompleteListener { task ->
            if (task.isSuccessful) {
                manager.launchReviewFlow(activity, task.result)
                    .addOnCompleteListener { settingsStore.markReviewPrompted(versionName) }
            } else {
                settingsStore.markReviewPrompted(versionName)
            }
        }
    }
}
