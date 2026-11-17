package app.rosaryguide.android.parity

import android.app.Application
import app.rosaryguide.feature.settings.CustomiseRosaryScreen
import app.rosaryguide.feature.profile.IntentionDetailScreen
import app.rosaryguide.feature.profile.ArchivedIntentionsScreen
import app.rosaryguide.feature.learn.MysterySetScreen
import app.rosaryguide.feature.learn.LearnArticleScreen
import app.rosaryguide.feature.learn.HowToPrayScreen
import app.rosaryguide.feature.feasts.FeastDetailScreen
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.FeastCatalog
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.rosaryguide.core.data.calendar.WeekStart
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.journey.PopeIntentionCatalog
import app.rosaryguide.core.data.prefs.UserSettings
import app.rosaryguide.core.data.session.CompletedPrayerSession
import app.rosaryguide.core.data.session.InMemorySessionPreferences
import app.rosaryguide.core.data.session.IntentionCategory
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.theme.RosaryGuideTheme
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.feature.feasts.FeastsScreen
import app.rosaryguide.feature.learn.AllPrayersScreen
import app.rosaryguide.feature.learn.LearnScreen
import app.rosaryguide.feature.learn.PrayerReaderScreen
import app.rosaryguide.feature.learn.RosaryPrayersScreen
import app.rosaryguide.feature.learn.RosaryWalkthroughScreen
import app.rosaryguide.feature.profile.IntentionEditorScreen
import app.rosaryguide.feature.profile.JourneyScreen
import app.rosaryguide.feature.profile.PapalIntentionScreen
import app.rosaryguide.feature.profile.ProfileLaunch
import app.rosaryguide.feature.profile.ProfileScreen
import app.rosaryguide.feature.settings.NotificationsSettingsScreen
import app.rosaryguide.feature.settings.SettingsConfirmDialog
import app.rosaryguide.feature.settings.SettingsPage
import app.rosaryguide.feature.settings.SettingsScreen
import app.rosaryguide.feature.today.TodayScreen
import com.github.takahirom.roborazzi.RobolectricDeviceQualifiers
import com.github.takahirom.roborazzi.captureRoboImage
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import java.util.UUID
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import app.rosaryguide.core.data.catalog.MapQuotePreferences
import app.rosaryguide.core.data.catalog.QuoteCatalog
import app.rosaryguide.core.data.sequence.RosarySequenceBuilder
import app.rosaryguide.core.model.RosaryStepKind
import app.rosaryguide.feature.pray.PrayLaunch
import app.rosaryguide.feature.pray.PrayScreen
import app.rosaryguide.feature.onboarding.LaunchSplashScreen
import app.rosaryguide.feature.onboarding.OnboardingScreen
import app.rosaryguide.feature.onboarding.SignInScreen
import app.rosaryguide.core.model.AppIconOption
import org.robolectric.annotation.GraphicsMode

/**
 * JVM / Robolectric screenshots at Pixel 7 size (1080×2400, 420 dpi).
 * Light and dark frames are written to /workspace/android/shots/parity/.
 */
@RunWith(AndroidJUnit4::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(
    application = Application::class,
    sdk = [34],
    qualifiers = RobolectricDeviceQualifiers.Pixel7,
)
class ParityScreenshotTest {

    @get:Rule
    val composeRule = createComposeRule()

    private val today: LocalDate = LocalDate.of(2026, 11, 16)
    private val zone: ZoneId = ZoneId.of("Australia/Perth")
    private val locale: Locale = Locale.forLanguageTag("en-AU")
    private val firstWeekday: Int = WeekStart.firstWeekday(locale)
    private val settings = UserSettings(appearance = AppearancePreference.Light)

    @Test fun todayLight() = shot("today", dark = false) { Today() }
    @Test fun todayDark() = shot("today", dark = true) { Today() }

    @Test fun learnLight() = shot("learn", dark = false) { Learn() }
    @Test fun learnDark() = shot("learn", dark = true) { Learn() }

    @Test fun learnWalkthroughLight() = shot("learn-walkthrough", dark = false) { Walkthrough() }
    @Test fun learnWalkthroughDark() = shot("learn-walkthrough", dark = true) { Walkthrough() }

    @Test fun rosaryPrayersLight() = shot("rosary-prayers", dark = false) { Pushed("Rosary prayers") { RosaryPrayers() } }
    @Test fun rosaryPrayersDark() = shot("rosary-prayers", dark = true) { Pushed("Rosary prayers") { RosaryPrayers() } }

    @Test fun allPrayersLight() = shot("all-prayers", dark = false) { Pushed("All prayers") { AllPrayers() } }
    @Test fun allPrayersDark() = shot("all-prayers", dark = true) { Pushed("All prayers") { AllPrayers() } }

    @Test fun prayerReaderLight() = shot("prayer-reader", dark = false) { Pushed("") { Reader() } }
    @Test fun prayerReaderDark() = shot("prayer-reader", dark = true) { Pushed("") { Reader() } }

    @Test fun feastsLight() = shot("feasts", dark = false) { Feasts() }
    @Test fun feastsDark() = shot("feasts", dark = true) { Feasts() }

    @Test fun profileEmptyLight() = shot("profile-empty", dark = false) { Profile(filled = false) }
    @Test fun profileEmptyDark() = shot("profile-empty", dark = true) { Profile(filled = false) }

    @Test fun profileLight() = shot("profile", dark = false) { Profile(filled = true) }
    @Test fun profileDark() = shot("profile", dark = true) { Profile(filled = true) }

    @Test fun intentionsAllLight() = shot("intentions-all", dark = false) {
        Profile(filled = true, launch = ProfileLaunch(openAllIntentions = true, sampleIntentions = true))
    }
    @Test fun intentionsAllDark() = shot("intentions-all", dark = true) {
        Profile(filled = true, launch = ProfileLaunch(openAllIntentions = true, sampleIntentions = true))
    }

    @Test fun intentionEditorLight() = shot("intention-editor", dark = false) {
        IntentionEditorScreen(existing = null, onBack = {}, onSave = {})
    }
    @Test fun intentionEditorDark() = shot("intention-editor", dark = true) {
        IntentionEditorScreen(existing = null, onBack = {}, onSave = {})
    }

    @Test fun papalLight() = shot("papal", dark = false) { Papal() }
    @Test fun papalDark() = shot("papal", dark = true) { Papal() }

    @Test fun journeyLight() = shot("journey", dark = false) { Journey(history = false) }
    @Test fun journeyDark() = shot("journey", dark = true) { Journey(history = false) }

    @Test fun journeyHistoryLight() = shot("journey-history", dark = false) { Journey(history = true) }
    @Test fun journeyHistoryDark() = shot("journey-history", dark = true) { Journey(history = true) }

    @Test fun historyDayLight() = shot("history-day", dark = false) { Journey(history = true, day = today) }
    @Test fun historyDayDark() = shot("history-day", dark = true) { Journey(history = true, day = today) }

    @Test fun settingsLight() = shot("settings", dark = false) { Settings(SettingsPage.Root) }
    @Test fun settingsDark() = shot("settings", dark = true) { Settings(SettingsPage.Root) }

    @Test fun settingsNotificationsLight() = shot("settings-notifications", dark = false) {
        Notifications()
    }
    @Test fun settingsNotificationsDark() = shot("settings-notifications", dark = true) {
        Notifications()
    }

    @Test
    fun settingsNotificationsPickerLight() {
        composeRule.setContent { Themed(dark = false) { Notifications() } }
        composeRule.onNodeWithText("Reminder time").performClick()
        composeRule.waitForIdle()
        composeRule.onRoot().captureRoboImage("$OUT/settings-notifications-picker-light.png")
    }

    @Test
    fun settingsNotificationsPickerDark() {
        composeRule.setContent { Themed(dark = true) { Notifications() } }
        composeRule.onNodeWithText("Reminder time").performClick()
        composeRule.waitForIdle()
        composeRule.onRoot().captureRoboImage("$OUT/settings-notifications-picker-dark.png")
    }


    @Test fun prayOpeningLight() = shot("pray-opening", dark = false) { Pray(openingLaunch()) }
    @Test fun prayOpeningDark() = shot("pray-opening", dark = true) { Pray(openingLaunch()) }

    @Test fun prayIntentionsLight() = shot("pray-intentions", dark = false) { Pray(intentionLaunch(), emptyKeepList = true) }
    @Test fun prayIntentionsDark() = shot("pray-intentions", dark = true) { Pray(intentionLaunch(), emptyKeepList = true) }

    @Test fun prayPlateLight() = shot("pray-plate", dark = false) { Pray(stepLaunch(plateIndex)) }
    @Test fun prayPlateDark() = shot("pray-plate", dark = true) { Pray(stepLaunch(plateIndex)) }

    @Test fun prayDecadeLight() = shot("pray-decade", dark = false) { Pray(stepLaunch(hailIndex)) }
    @Test fun prayDecadeDark() = shot("pray-decade", dark = true) { Pray(stepLaunch(hailIndex)) }

    @Test fun prayDecadeEndLight() = shot("pray-decade-end", dark = false) { Pray(stepLaunch(decadeEndIndex)) }
    @Test fun prayDecadeEndDark() = shot("pray-decade-end", dark = true) { Pray(stepLaunch(decadeEndIndex)) }

    @Test fun prayClosingLight() = shot("pray-closing", dark = false) { Pray(stepLaunch(closingIndex)) }
    @Test fun prayClosingDark() = shot("pray-closing", dark = true) { Pray(stepLaunch(closingIndex)) }

    @Test fun prayCompletionLight() = shot("pray-completion", dark = false) { Pray(completionLaunch(), emptyKeepList = true) }
    @Test fun prayCompletionDark() = shot("pray-completion", dark = true) { Pray(completionLaunch(), emptyKeepList = true) }

    @Test fun prayCustomiseLight() = shot("pray-customise", dark = false) { Pray(customiseLaunch()) }
    @Test fun prayCustomiseDark() = shot("pray-customise", dark = true) { Pray(customiseLaunch()) }

    @Test fun prayMichaelLight() = shot("pray-michael", dark = false) { Pray(michaelLaunch()) }
    @Test fun prayMichaelDark() = shot("pray-michael", dark = true) { Pray(michaelLaunch()) }

    @Test fun prayReplaceDialogLight() = shot("pray-replace-dialog", dark = false) {
        Pray(baseLaunch().copy(showReplaceDialog = true))
    }
    @Test fun prayReplaceDialogDark() = shot("pray-replace-dialog", dark = true) {
        Pray(baseLaunch().copy(showReplaceDialog = true))
    }

    @Test fun settingsCustomiseLight() = shot("settings-customise", dark = false) { Settings(SettingsPage.CustomiseRosary) }
    @Test fun settingsCustomiseDark() = shot("settings-customise", dark = true) { Settings(SettingsPage.CustomiseRosary) }

    @Test fun settingsAppIconLight() = shot("settings-app-icon", dark = false) { Settings(SettingsPage.AppIcon) }
    @Test fun settingsAppIconDark() = shot("settings-app-icon", dark = true) { Settings(SettingsPage.AppIcon) }

    @Test fun settingsLegalLight() = shot("settings-legal", dark = false) { Settings(SettingsPage.Privacy) }
    @Test fun settingsLegalDark() = shot("settings-legal", dark = true) { Settings(SettingsPage.Privacy) }

    @Test fun settingsAcknowledgementsLight() = shot("settings-acknowledgements", dark = false) { Settings(SettingsPage.Acknowledgements) }
    @Test fun settingsAcknowledgementsDark() = shot("settings-acknowledgements", dark = true) { Settings(SettingsPage.Acknowledgements) }

    @Test fun settingsClearHistoryLight() = shot("settings-clear-history", dark = false) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.ClearHistory)
    }
    @Test fun settingsClearHistoryDark() = shot("settings-clear-history", dark = true) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.ClearHistory)
    }
    @Test fun settingsDeleteAccountLight() = shot("settings-delete-account", dark = false) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.DeleteAccount)
    }
    @Test fun settingsDeleteAccountDark() = shot("settings-delete-account", dark = true) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.DeleteAccount)
    }

    @Test fun onboarding1Light() = shot("onboarding-1", dark = false) { OnboardingScreen(onBegin = {}, initialPage = 0) }
    @Test fun onboarding1Dark() = shot("onboarding-1", dark = true) { OnboardingScreen(onBegin = {}, initialPage = 0) }
    @Test fun onboarding2Light() = shot("onboarding-2", dark = false) { OnboardingScreen(onBegin = {}, initialPage = 1) }
    @Test fun onboarding2Dark() = shot("onboarding-2", dark = true) { OnboardingScreen(onBegin = {}, initialPage = 1) }
    @Test fun onboarding3Light() = shot("onboarding-3", dark = false) { OnboardingScreen(onBegin = {}, initialPage = 2) }
    @Test fun onboarding3Dark() = shot("onboarding-3", dark = true) { OnboardingScreen(onBegin = {}, initialPage = 2) }

    @Test fun signinLight() = shot("signin", dark = false) { SignInScreen(onGoogle = {}, onGuest = {}) }
    @Test fun signinDark() = shot("signin", dark = true) { SignInScreen(onGoogle = {}, onGuest = {}) }

    @Test fun splashLight() = shot("splash", dark = false) {
        LaunchSplashScreen(onFinished = {}, previewProgress = 1f)
    }
    @Test fun splashDark() = shot("splash", dark = true) {
        LaunchSplashScreen(onFinished = {}, previewProgress = 1f)
    }

    @Test fun feastDetailLight() = shot("feast-detail", dark = false) { FeastDetail() }
    @Test fun feastDetailDark() = shot("feast-detail", dark = true) { FeastDetail() }

    @Test fun howtoLight() = shot("howto", dark = false) { Pushed("How to pray") { HowToPrayScreen() } }
    @Test fun howtoDark() = shot("howto", dark = true) { Pushed("How to pray") { HowToPrayScreen() } }

    @Test fun articleLight() = shot("article", dark = false) { Article() }
    @Test fun articleDark() = shot("article", dark = true) { Article() }

    @Test fun faqArticleLight() = shot("faq-article", dark = false) { FaqArticle() }
    @Test fun faqArticleDark() = shot("faq-article", dark = true) { FaqArticle() }

    @Test fun mysterySetLight() = shot("mystery-set", dark = false) { MysterySet() }
    @Test fun mysterySetDark() = shot("mystery-set", dark = true) { MysterySet() }

    @Test fun intentionDetailLight() = shot("intention-detail", dark = false) { IntentionDetail() }
    @Test fun intentionDetailDark() = shot("intention-detail", dark = true) { IntentionDetail() }

    @Test fun intentionsArchivedLight() = shot("intentions-archived", dark = false) { Archived(empty = false) }
    @Test fun intentionsArchivedDark() = shot("intentions-archived", dark = true) { Archived(empty = false) }

    @Test fun intentionsArchivedEmptyLight() = shot("intentions-archived-empty", dark = false) { Archived(empty = true) }
    @Test fun intentionsArchivedEmptyDark() = shot("intentions-archived-empty", dark = true) { Archived(empty = true) }

    @Test fun settingsReportProblemLight() = shot("settings-report-problem", dark = false) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.ReportProblem)
    }
    @Test fun settingsReportProblemDark() = shot("settings-report-problem", dark = true) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.ReportProblem)
    }
    @Test fun settingsSignOutLight() = shot("settings-sign-out", dark = false) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.SignOut)
    }
    @Test fun settingsSignOutDark() = shot("settings-sign-out", dark = true) {
        Settings(SettingsPage.Root, signedIn = true, confirm = SettingsConfirmDialog.SignOut)
    }
    @Test fun settingsResetRosaryLight() = shot("settings-reset-rosary", dark = false) {
        CustomiseRosaryScreen(config = settings.rosaryConfig, onConfigChange = {}, onBack = {}, initialConfirmReset = true)
    }
    @Test fun settingsResetRosaryDark() = shot("settings-reset-rosary", dark = true) {
        CustomiseRosaryScreen(config = settings.rosaryConfig, onConfigChange = {}, onBack = {}, initialConfirmReset = true)
    }

    @Test fun learnEmptyLight() = shot("learn-empty", dark = false) { LearnEmpty() }
    @Test fun learnEmptyDark() = shot("learn-empty", dark = true) { LearnEmpty() }
    @Test fun feastsEmptyLight() = shot("feasts-empty", dark = false) { Feasts(query = "zzzzzx") }
    @Test fun feastsEmptyDark() = shot("feasts-empty", dark = true) { Feasts(query = "zzzzzx") }
    @Test fun allPrayersEmptyLight() = shot("all-prayers-empty", dark = false) { Pushed("All prayers") { AllPrayersScreen(onPrayer = {}, initialQuery = "zzzzzx") } }
    @Test fun allPrayersEmptyDark() = shot("all-prayers-empty", dark = true) { Pushed("All prayers") { AllPrayersScreen(onPrayer = {}, initialQuery = "zzzzzx") } }



    @Composable
    private fun Themed(dark: Boolean, content: @Composable () -> Unit) {
        RosaryGuideTheme(darkTheme = dark, content = content)
    }

    private fun shot(stem: String, dark: Boolean, content: @Composable () -> Unit) {
        composeRule.setContent { Themed(dark = dark, content = content) }
        composeRule.waitForIdle()
        val suffix = if (dark) "dark" else "light"
        composeRule.onRoot().captureRoboImage("$OUT/$stem-$suffix.png")
    }


    @Composable
    private fun Pushed(title: String, content: @Composable () -> Unit) {
        Column(Modifier.fillMaxSize()) {
            GuideDetailTopBar(title = title, onBack = {})
            content()
        }
    }

    @Composable
    private fun FeastDetail() {
        val feast = FeastCatalog.all.first { it.id == "annunciation" }
        val date = feast.dateOn(2026) ?: java.time.LocalDate.of(2026, 3, 25)
        Pushed(feast.shortTitle) {
            FeastDetailScreen(item = DatedFeast(feast, date), onPray = {})
        }
    }

    @Composable
    private fun Article() {
        val article = LearnArticle.commonQuestions.first()
        Pushed(article.title) { LearnArticleScreen(article) }
    }

    @Composable
    private fun MysterySet() {
        Pushed(MysterySetKind.Joyful.shortName) {
            MysterySetScreen(set = MysterySetKind.Joyful, onPray = {})
        }
    }

    @Composable
    private fun IntentionDetail() {
        IntentionDetailScreen(
            intention = OfferIntention(
                id = "int-mum",
                title = "For Mum",
                note = "For her health and peace.",
                category = IntentionCategory.Someone,
                emoji = "💙",
                isPinned = true,
                createdAtEpochMs = java.time.LocalDate.of(2026, 3, 1).atStartOfDay(zone).toInstant().toEpochMilli(),
                timesCarried = 2,
            ),
            hidden = false,
            onBack = {},
            onEdit = {},
            onPray = {},
            onPin = {},
            onArchive = {},
            onDelete = {},
        )
    }

    @Composable
    private fun Archived(empty: Boolean) {
        val items = if (empty) emptyList() else listOf(
            OfferIntention(id = "int-old", title = "For a friend", category = IntentionCategory.Someone, emoji = "🤝", archivedAtEpochMs = 1L),
        )
        ArchivedIntentionsScreen(intentions = items, hidden = false, onBack = {}, onRestore = {}, onDelete = {})
    }

    @Composable
    private fun LearnEmpty() {
        LearnScreen(
            onHowToPray = {},
            onArticle = {},
            onPrayer = {},
            onMysterySet = {},
            todaySetTitle = "Joyful Mysteries",
            initialQuery = "zzzzzx",
        )
    }

    @Composable
    private fun Today() {
        TodayScreen(
            onViewAllFeasts = {},
            onFeastClick = {},
            onPray = {},
            today = today,
        )
    }

    @Composable
    private fun Learn() {
        LearnScreen(
            onHowToPray = {},
            onArticle = {},
            onPrayer = {},
            onMysterySet = {},
            todaySetTitle = "Joyful Mysteries",
        )
    }

    @Composable
    private fun FaqArticle() {
        LearnScreen(
            onHowToPray = {},
            onArticle = {},
            onPrayer = {},
            onMysterySet = {},
            todaySetTitle = "Joyful Mysteries",
            initialExpandedArticleId = LearnArticle.commonQuestions.first().id,
        )
    }

    @Composable
    private fun Walkthrough() {
        RosaryWalkthroughScreen(onClose = {}, onBegin = {}, initialPage = 0)
    }

    @Composable
    private fun RosaryPrayers() {
        RosaryPrayersScreen(onPrayer = {})
    }

    @Composable
    private fun AllPrayers() {
        AllPrayersScreen(onPrayer = {})
    }

    @Composable
    private fun Reader() {
        PrayerReaderScreen(prayer = PrayerCatalog.all.first { it.id == "apostles-creed" })
    }

    @Composable
    private fun Feasts(query: String = "") {
        FeastsScreen(onFeastClick = {}, today = today, initialQuery = query)
    }

    @Composable
    private fun Profile(filled: Boolean, launch: ProfileLaunch = ProfileLaunch()) {
        ProfileScreen(
            sessionStore = if (filled) filledStore() else SessionStore(),
            today = today,
            zone = zone,
            locale = locale,
            firstWeekday = firstWeekday,
            launch = launch.copy(sampleIntentions = filled, sampleHistory = filled),
        )
    }

    @Composable
    private fun Journey(history: Boolean, day: LocalDate? = null) {
        JourneyScreen(
            sessionStore = filledStore(),
            today = today,
            zone = zone,
            locale = locale,
            firstWeekday = firstWeekday,
            startOnHistory = history,
            initialDay = day,
            onBack = {},
        )
    }

    @Composable
    private fun Papal() {
        val pope = PopeIntentionCatalog.intention(today)
            ?: PopeMonthIntentionFallback
        PapalIntentionScreen(pope = pope, alreadyAdded = false, onBack = {}, onAdd = {})
    }

    @Composable
    private fun Settings(
        page: SettingsPage,
        signedIn: Boolean = false,
        confirm: SettingsConfirmDialog =
            SettingsConfirmDialog.None,
    ) {
        SettingsScreen(
            settings = settings,
            appVersion = "0.7.0-m7",
            isSignedIn = signedIn,
            initialConfirm = confirm,
            hasAppHistory = true,
            initialPage = page,
            onAppearance = {},
            onRosaryConfig = {},
            onDailyEnabled = {},
            onDailyMinutes = {},
            onFeastEnabled = {},
            onFeastMinutes = {},
            onAppIcon = {},
            onClearHistory = {},
            onSignOut = {},
            onReplayWelcome = {},
            onSignIn = {},
            onBack = {},
        )
    }

    @Composable
    private fun Notifications() {
        NotificationsSettingsScreen(
            settings = settings,
            onDailyEnabled = {},
            onDailyMinutes = {},
            onFeastEnabled = {},
            onFeastMinutes = {},
            onBack = {},
        )
    }


    private val joyfulSteps = RosarySequenceBuilder.build(MysterySetKind.Joyful)
    private val plateIndex = joyfulSteps.indexOfFirst { it.isPlate }
    private val hailIndex = joyfulSteps.indexOfFirst {
        it.kind == RosaryStepKind.HailMary && it.decadeNumber == 1 && it.hailMaryNumber == 1
    }
    private val decadeEndIndex = joyfulSteps.indexOfFirst { it.closesDecade && it.decadeNumber == 1 }
    private val closingIndex = joyfulSteps.indexOfFirst { it.isLastPrayer }

    private fun openingLaunch() = baseLaunch()
    private fun intentionLaunch() = baseLaunch().copy(showIntentions = true, seedIntentions = emptyList())
    private fun stepLaunch(start: Int) = baseLaunch().copy(startStep = start.coerceAtLeast(0))
    private fun completionLaunch() = baseLaunch().copy(showCompletion = true, seedIntentions = emptyList())
    private fun customiseLaunch() = baseLaunch().copy(showCustomise = true)
    private fun michaelLaunch() = baseLaunch().copy(showSaintMichael = true)

    private fun baseLaunch() = PrayLaunch(
        mysterySet = MysterySetKind.Joyful,
        forceFresh = true,
        seedIntentions = listOf("mum" to "For Mum"),
    )

    @Composable
    private fun Pray(launch: PrayLaunch, emptyKeepList: Boolean = false) {
        val store = remember(emptyKeepList) { if (emptyKeepList) emptyStore() else filledStore() }
        PrayScreen(
            launch = launch,
            sessionStore = store,
            quotePreferences = remember { completionQuotePrefs() },
            onClose = {},
        )
    }

    private fun emptyStore(): SessionStore = SessionStore(
        prefs = InMemorySessionPreferences(),
        zone = zone,
    )

    private fun completionQuotePrefs(): MapQuotePreferences {
        val prefs = MapQuotePreferences()
        val index = QuoteCatalog.all.indexOfFirst { it.id == "jp2-favourite" }
        if (index >= 0) prefs.setInt(QuoteCatalog.NEXT_COMPLETION_QUOTE_KEY, index)
        return prefs
    }

    private fun filledStore(): SessionStore {
        val start = today.atTime(20, 0).atZone(zone).toInstant().toEpochMilli()
        val sessions = listOf(0, 1, 3, 8).map { offset ->
            val day = today.minusDays(offset.toLong())
            val at = day.atTime(20, 0).atZone(zone).toInstant().toEpochMilli()
            CompletedPrayerSession(
                mysterySet = MysterySetKind.entries[offset % MysterySetKind.entries.size],
                startedAtEpochMs = at,
                completedAtEpochMs = at + 20 * 60 * 1000,
                duration = 20 * 60.0,
                intentionTitle = "For Mum",
            )
        }
        val keys = sessions.map {
            java.time.Instant.ofEpochMilli(it.completedAtEpochMs).atZone(zone).toLocalDate().toString()
        }.toSet()
        val intentions = listOf(
            OfferIntention(id = "int-mum", title = "For Mum", category = IntentionCategory.Someone, emoji = "💙", isPinned = true),
            OfferIntention(id = "int-peace", title = "Peace in the world", category = IntentionCategory.World, emoji = "🌍"),
            OfferIntention(id = "int-family", title = "My family", category = IntentionCategory.Personal, emoji = "🙏"),
        )
        return SessionStore(
            prefs = InMemorySessionPreferences(
                completed = sessions,
                dayKeys = keys,
                intentions = intentions,
            ),
            zone = zone,
        )
    }

    companion object {
        private const val OUT = "/workspace/android/shots/parity"
        private val PopeMonthIntentionFallback = app.rosaryguide.core.data.journey.PopeMonthIntention(
            yearMonth = "2026-11",
            title = "For the prevention of suicide",
            note = "That those who are struggling might find hope.",
        )
    }
}
