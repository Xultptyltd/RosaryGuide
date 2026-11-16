package app.rosaryguide.core.data.launch

/**
 * Which screen the app opens on. Ported from iOS `LaunchGate`.
 * Onboarding shows once; after that the app is always open, signed in or not.
 * Signing in (from onboarding or Settings) only turns on sync.
 * A sign-in made on the onboarding screen keeps that screen up for its tick;
 * the app opens when onboarding completes.
 */
object LaunchGate {
    /** Leaving an account (sign out or delete) shows onboarding again. */
    fun returnsToOnboarding(previousUserId: String?, userId: String?): Boolean =
        previousUserId != null && userId == null

    /**
     * Tabs are shown when onboarding is complete, or when the user was already
     * signed in before this launch. A sign-in made during this launch does not
     * hide onboarding until onboarding itself completes.
     */
    fun showsApp(
        didCompleteOnboarding: Boolean,
        isSignedIn: Boolean,
        signedInThisLaunch: Boolean = false,
    ): Boolean = didCompleteOnboarding || (isSignedIn && !signedInThisLaunch)
}

enum class AppTab(val title: String, val iconAsset: String, val selectedIconAsset: String) {
    Today("Today", "TabTodayOutline", "TabTodayFilled"),
    Learn("Learn", "TabLearnOutline", "TabLearnFilled"),
    Feasts("Feasts", "TabFeastsOutline", "TabFeastsFilled"),
    Profile("Profile", "TabProfileOutline", "TabProfileFilled"),
    ;

    companion object {
        val titles: List<String> get() = entries.map { it.title }
    }
}
