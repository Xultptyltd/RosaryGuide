package app.rosaryguide.core.data.notify

/**
 * When the system review prompt may be asked: from the 3rd finished Rosary on,
 * at most once per app version. Ported from iOS `ReviewPromptGate`.
 */
class ReviewPromptGate(
    private val currentVersion: String,
    private val lastPromptedVersion: String? = null,
) {
    fun shouldPrompt(completedRosaries: Int): Boolean {
        if (currentVersion.isEmpty() || completedRosaries < MINIMUM_COMPLETED_ROSARIES) return false
        return lastPromptedVersion != currentVersion
    }

    companion object {
        const val MINIMUM_COMPLETED_ROSARIES = 3
        const val LAST_PROMPTED_VERSION_KEY = "review.lastPromptedVersion"
        const val SETTLE_DELAY_MS = 2_000L
    }
}
