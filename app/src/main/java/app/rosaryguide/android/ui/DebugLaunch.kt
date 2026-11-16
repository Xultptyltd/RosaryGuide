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
    val openWalkthrough: Boolean = false,
    val openRosaryPrayers: Boolean = false,
    val openAllPrayers: Boolean = false,
    val clockDate: LocalDate? = null,
    val openPray: Boolean = false,
    val showIntentions: Boolean = false,
    val showCompletion: Boolean = false,
    val prayStep: Int? = null,
    val forceFreshPray: Boolean = false,
    val hideBeads: Boolean = false,
    val includeSaintMichael: Boolean = false,
    val openJourney: Boolean = false,
    val journeyHistory: Boolean = false,
    val openAllIntentions: Boolean = false,
    val openIntentionEditor: Boolean = false,
    val openArchived: Boolean = false,
    val historyDay: LocalDate? = null,
    val sampleIntentions: Boolean = false,
    val sampleHistory: Boolean = false,
    val openPapal: Boolean = false,
    val openSettings: Boolean = false,
    val openCustomiseRosary: Boolean = false,
    val openNotifications: Boolean = false,
    val openAppIcon: Boolean = false,
    val openLegal: Boolean = false,
    val openAcknowledgements: Boolean = false,
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
            val prayStep = if (extras.containsKey("pray_step")) extras.getInt("pray_step") else null
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
                openWalkthrough = flag("open_walkthrough"),
                openRosaryPrayers = flag("open_rosary_prayers"),
                openAllPrayers = flag("open_all_prayers"),
                clockDate = date("clock_date"),
                openPray = flag("open_pray"),
                showIntentions = flag("show_intentions"),
                showCompletion = flag("show_completion"),
                prayStep = prayStep,
                forceFreshPray = flag("force_fresh_pray"),
                hideBeads = flag("hide_beads"),
                includeSaintMichael = flag("include_michael") || flag("include_saint_michael"),
                openJourney = flag("open_journey"),
                journeyHistory = flag("journey_history") || flag("open_history"),
                openAllIntentions = flag("open_intentions") || flag("open_all_intentions"),
                openIntentionEditor = flag("open_intention_editor"),
                openArchived = flag("open_archived"),
                historyDay = date("history_day"),
                sampleIntentions = flag("sample_intentions"),
                sampleHistory = flag("sample_history") || flag("sample_rhythm"),
                openPapal = flag("open_papal"),
                openSettings = flag("open_settings"),
                openCustomiseRosary = flag("open_customise_rosary"),
                openNotifications = flag("open_notifications"),
                openAppIcon = flag("open_app_icon"),
                openLegal = flag("open_legal") || flag("open_terms"),
                openAcknowledgements = flag("open_acknowledgements"),
            )
        }
    }
}
