package app.rosaryguide.core.data.notify

/**
 * When and whether to ask for notification permission, ported from iOS
 * `NotificationPrompt`. Asked once, ~1 s after first Home appearance, if never asked.
 * Never re-prompts after a denial. Device-only; not synced.
 */
object NotificationPrompt {
    const val ASKED_KEY = "settings.notifications.askedForNotifications"
    const val HOME_ARRIVAL_DELAY_MS = 1_000L

    fun shouldPrompt(hasAsked: Boolean, systemPermissionDetermined: Boolean): Boolean {
        return !hasAsked && !systemPermissionDetermined
    }
}
