package app.rosaryguide.android.parity

import android.app.Application
import androidx.compose.runtime.Composable
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

    @Test fun rosaryPrayersLight() = shot("rosary-prayers", dark = false) { RosaryPrayers() }
    @Test fun rosaryPrayersDark() = shot("rosary-prayers", dark = true) { RosaryPrayers() }

    @Test fun allPrayersLight() = shot("all-prayers", dark = false) { AllPrayers() }
    @Test fun allPrayersDark() = shot("all-prayers", dark = true) { AllPrayers() }

    @Test fun prayerReaderLight() = shot("prayer-reader", dark = false) { Reader() }
    @Test fun prayerReaderDark() = shot("prayer-reader", dark = true) { Reader() }

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
    private fun Feasts() {
        FeastsScreen(onFeastClick = {}, today = today)
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
    private fun Settings(page: SettingsPage) {
        SettingsScreen(
            settings = settings,
            appVersion = "0.7.0-m7",
            isSignedIn = false,
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
