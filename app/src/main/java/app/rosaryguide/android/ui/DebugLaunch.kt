package app.rosaryguide.android.ui

import android.content.Intent
import app.rosaryguide.core.data.launch.AppTab
import java.time.LocalDate

/**
 * Debug / screenshot hooks, inspired by iOS `DebugHooks` / `-RGDebug…` launch arguments.
 */
data class DebugLaunch(
    val skipSplash: Boolean = false,
    val forceTabs: Boolean = false,
    val forceOnboarding: Boolean = false,
    val forceSignIn: Boolean = false,
    val onboardingPage: Int? = null,
    val startTab: AppTab = AppTab.Today,
    val feastId: String? = null,
    val feastDate: LocalDate? = null,
    val articleId: String? = null,
    val prayerId: String? = null,
    val mysterySet: String? = null,
    val openHowTo: Boolean = false,
    val clockDate: LocalDate? = null,
) {
    companion object {
        fun from(intent: Intent?): DebugLaunch {
            if (intent == null) return DebugLaunch()
            val extras = intent.extras ?: return DebugLaunch()
            fun flag(key: String) = extras.getBoolean(key, false)
            fun str(key: String) = extras.getString(key)
            fun date(key: String) = str(key)?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
            val tab = when (str("start_tab")?.lowercase()) {
                "learn" -> AppTab.Learn
                "feasts" -> AppTab.Feasts
                "profile" -> AppTab.Profile
                else -> AppTab.Today
            }
            val page = if (extras.containsKey("onboarding_page")) extras.getInt("onboarding_page") else null
            return DebugLaunch(
                skipSplash = flag("skip_splash"),
                forceTabs = flag("force_tabs") || flag("skip_onboarding"),
                forceOnboarding = flag("force_onboarding"),
                forceSignIn = flag("force_signin") || flag("force_sign_in"),
                onboardingPage = page,
                startTab = tab,
                feastId = str("feast_id"),
                feastDate = date("feast_date"),
                articleId = str("article_id"),
                prayerId = str("prayer_id"),
                mysterySet = str("mystery_set"),
                openHowTo = flag("open_how_to"),
                clockDate = date("clock_date"),
            )
        }
    }
}
