package app.rosaryguide.core.data.prefs

import app.rosaryguide.core.data.notify.ReviewPromptGate
import app.rosaryguide.core.data.notify.TimeOfDay
import app.rosaryguide.core.model.RosaryConfig
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ported from iOS `NotificationAndRosaryDefaultTests`. */
class SettingsStoreTest {
    @Test
    fun testNewInstallEnablesRemindersAndFeastsAtNine() {
        val settings = SettingsStore(InMemorySettingsPreferences())
        assertTrue(settings.current.dailyReminderEnabled)
        assertEquals(9 * 60, settings.current.dailyReminderMinutes)
        assertTrue(settings.current.feastAlertsEnabled)
        assertEquals(9 * 60, settings.current.feastAlertMinutes)
        assertEquals(TimeOfDay.DEFAULT_REMINDER_MINUTES, 9 * 60)
    }

    @Test
    fun testSavedNotificationSettingsAreNotOverwritten() {
        val stored = UserSettings(
            dailyReminderEnabled = false,
            dailyReminderMinutes = 19 * 60,
            feastAlertsEnabled = false,
            feastAlertMinutes = 8 * 60,
        )
        val settings = SettingsStore(InMemorySettingsPreferences(stored))
        assertFalse(settings.current.dailyReminderEnabled)
        assertEquals(19 * 60, settings.current.dailyReminderMinutes)
        assertFalse(settings.current.feastAlertsEnabled)
        assertEquals(8 * 60, settings.current.feastAlertMinutes)
    }

    @Test
    fun testRosaryDefaultsMatchTheRequestedPrayers() {
        val config = RosaryConfig.default
        assertTrue(config.intentionsStep)
        assertTrue(config.showBeads)
        assertTrue(config.fatimaPrayer)
        assertTrue(config.closingPrayers)
        assertFalse(config.saintMichael)
        assertFalse(config.memorare)
        assertFalse(config.oSacrament)
        assertEquals(config, SettingsStore(InMemorySettingsPreferences()).current.rosaryConfig)
    }

    @Test
    fun testSavedRosaryConfigIsNotOverwritten() {
        val config = RosaryConfig.default.copy(
            intentionsStep = false,
            showBeads = false,
            fatimaPrayer = false,
            closingPrayers = false,
            saintMichael = true,
            memorare = true,
            oSacrament = true,
        )
        val settings = SettingsStore(InMemorySettingsPreferences(UserSettings(rosaryConfig = config)))
        assertEquals(config, settings.current.rosaryConfig)
    }

    @Test
    fun testTimeOfDayRoundTripsNineOClock() {
        assertEquals(9 * 60, TimeOfDay.DEFAULT_REMINDER_MINUTES)
        assertEquals(9, TimeOfDay.hour(9 * 60))
        assertEquals(0, TimeOfDay.minute(9 * 60))
        assertEquals("9:00 am", TimeOfDay.format(9 * 60))
        val zone = ZoneId.of("Australia/Perth")
        val at = TimeOfDay.atDate(LocalDate.of(2026, 11, 16), 9 * 60, zone)
        assertEquals(LocalTime.of(9, 0), at.toLocalTime())
    }

    @Test
    fun testResetLocalPreferencesKeepsTheAppIcon() {
        val settings = SettingsStore(
            InMemorySettingsPreferences(
                UserSettings(
                    dailyReminderEnabled = false,
                    dailyReminderMinutes = 19 * 60,
                    rosaryConfig = RosaryConfig.default.copy(showBeads = false),
                    appIcon = app.rosaryguide.core.model.AppIconOption.Black,
                ),
            ),
        )
        settings.resetLocalPreferences(keepingAppIcon = settings.current.appIcon)
        assertTrue(settings.current.dailyReminderEnabled)
        assertEquals(9 * 60, settings.current.dailyReminderMinutes)
        assertEquals(RosaryConfig.default, settings.current.rosaryConfig)
        assertEquals(app.rosaryguide.core.model.AppIconOption.Black, settings.current.appIcon)
    }
}

class ReviewPromptGateTest {
    @Test
    fun testAsksFromTheThirdRosaryOncePerVersion() {
        val gate = ReviewPromptGate(currentVersion = "1.0")
        assertFalse(gate.shouldPrompt(0))
        assertFalse(gate.shouldPrompt(1))
        assertFalse(gate.shouldPrompt(2))
        assertTrue(gate.shouldPrompt(3))
        assertTrue(gate.shouldPrompt(12))
    }

    @Test
    fun testDoesNotAskAgainUntilTheVersionChanges() {
        val prompted = ReviewPromptGate(currentVersion = "1.0", lastPromptedVersion = "1.0")
        assertFalse(prompted.shouldPrompt(3))
        assertFalse(prompted.shouldPrompt(50))
        val next = ReviewPromptGate(currentVersion = "1.1", lastPromptedVersion = "1.0")
        assertTrue(next.shouldPrompt(4))
        val marked = ReviewPromptGate(currentVersion = "1.1", lastPromptedVersion = "1.1")
        assertFalse(marked.shouldPrompt(5))
    }

    @Test
    fun testEmptyVersionNeverPrompts() {
        val gate = ReviewPromptGate(currentVersion = "")
        assertFalse(gate.shouldPrompt(10))
    }
}
