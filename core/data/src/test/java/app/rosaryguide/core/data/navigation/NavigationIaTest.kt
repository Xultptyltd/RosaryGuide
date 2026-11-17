package app.rosaryguide.core.data.navigation

import app.rosaryguide.core.data.journey.JourneyPrayerDetailFacts
import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.Feast
import app.rosaryguide.core.model.FeastRank
import app.rosaryguide.core.model.MysterySetKind
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NavigationIaTest {
    private val perth = ZoneId.of("Australia/Perth")
    private val locale = Locale.forLanguageTag("en-AU")

    @Test
    fun historyRowOpensPrayerDetailSheet() {
        assertEquals(NavigationIa.JourneySheet.PrayerDetail, NavigationIa.journeySheetForHistoryRow())
    }

    @Test
    fun calendarDayOpensDaySheet() {
        assertEquals(NavigationIa.JourneySheet.DayDetail, NavigationIa.journeySheetForCalendarDay())
    }

    @Test
    fun weekDayWithoutFeastSelectsTheDay() {
        val date = LocalDate.of(2026, 11, 17)
        val action = NavigationIa.weekDayAction(date, feast = null)
        assertEquals(NavigationIa.WeekDayAction.SelectDay(date), action)
    }

    @Test
    fun weekDayWithFeastOpensWeekFeastSheet() {
        val date = LocalDate.of(2026, 9, 29)
        val feast = DatedFeast(sampleFeast("michael", "Saints Michael, Gabriel and Raphael"), date)
        val action = NavigationIa.weekDayAction(date, feast)
        assertEquals(NavigationIa.WeekDayAction.OpenWeekFeastSheet(feast), action)
    }

    @Test
    fun weekFeastDescriptionUsesDedicatedCopyForMichael() {
        val text = NavigationIa.weekFeastDescription(sampleFeast("michael", "The Archangels"))
        assertTrue(text.contains("three archangels"))
    }

    @Test
    fun signOutReturnsToOnboarding() {
        assertFalse(NavigationIa.ONBOARDING_COMPLETED_AFTER_SIGN_OUT)
        assertFalse(NavigationIa.showsAppAfterSignOut())
    }

    @Test
    fun settingsOpensOnlyFromProfileGear() {
        assertTrue(NavigationIa.isSettingsEntryAllowed(NavigationIa.SettingsEntry.ProfileGear))
        assertFalse(NavigationIa.isSettingsEntryAllowed(NavigationIa.SettingsEntry.Today))
        assertFalse(NavigationIa.isSettingsEntryAllowed(NavigationIa.SettingsEntry.Tab))
        assertEquals(NavigationIa.SettingsRootClose.Back, NavigationIa.settingsRootClose())
    }

    @Test
    fun profileEditorAndFeastSecondaryAndLearnSearchRoutes() {
        assertEquals(NavigationIa.ProfileEditorPresentation.Sheet, NavigationIa.profileEditorPresentation())
        assertFalse(NavigationIa.feastSecondaryPagesArePushes())
        assertTrue(NavigationIa.isLiveLearnSearchDestination(NavigationIa.LearnSearchDestination.Prayer))
        assertTrue(NavigationIa.isLiveLearnSearchDestination(NavigationIa.LearnSearchDestination.MysterySet))
        assertTrue(NavigationIa.isLiveLearnSearchDestination(NavigationIa.LearnSearchDestination.Feast))
        assertFalse(NavigationIa.isLiveLearnSearchDestination(NavigationIa.LearnSearchDestination.HowToPray))
        assertFalse(NavigationIa.isLiveLearnSearchDestination(NavigationIa.LearnSearchDestination.Article))
    }

    @Test
    fun signInAndReplayWelcomeLandings() {
        assertEquals(
            NavigationIa.AfterSignInLanding.TodayClearingStacks,
            NavigationIa.afterSignIn(NavigationIa.SignInOrigin.Profile),
        )
        assertEquals(
            NavigationIa.AfterSignInLanding.StayOnSettings,
            NavigationIa.afterSignIn(NavigationIa.SignInOrigin.Settings),
        )
        assertTrue(NavigationIa.REPLAY_WELCOME_KEEPS_SETTINGS)
    }

    @Test
    fun notificationAndLowPriorityPolicy() {
        assertTrue(NavigationIa.NOTIFICATION_TAP_OPENS_LAUNCHER)
        assertFalse(NavigationIa.NOTIFICATION_TAP_HAS_CUSTOM_DESTINATION)
        assertTrue(NavigationIa.DELETE_ACCOUNT_STUBBED_UNTIL_M5)
        assertFalse(NavigationIa.THEME_GALLERY_EXPORTED)
        assertEquals(
            NavigationIa.PrayAddIntentionPresentation.NestedSheet,
            NavigationIa.prayAddIntentionPresentation(),
        )
    }

    @Test
    fun prayerDetailFactsIncludeDateDurationAndDecade() {
        val facts = JourneyPrayerDetailFacts.from(
            mysterySet = MysterySetKind.Joyful,
            decade = 1,
            completedAtEpochMs = 1_731_747_600_000L, // 2024-11-16 21:00 UTC → 17 Nov 2024 05:00 Perth
            startedAtEpochMs = 1_731_746_400_000L,
            durationSeconds = 1200.0,
            intentionTitles = listOf("For peace"),
            zone = perth,
            locale = locale,
        )
        assertEquals("Joyful Mysteries", facts.title)
        assertEquals("Single decade", facts.subtitle)
        assertEquals("Date", facts.facts[0].label)
        assertTrue(facts.facts[0].value.contains("November"))
        assertEquals("Started", facts.facts[1].label)
        assertEquals("Duration", facts.facts[2].label)
        assertEquals("20 mins", facts.facts[2].value)
        assertEquals(FactMatch("Mysteries", "Joyful"), facts.facts[3].label to facts.facts[3].value)
        assertTrue(facts.facts[4].value.startsWith("I ·"))
        assertEquals(listOf("For peace"), facts.intentionTitles)
    }

    private fun FactMatch(label: String, value: String) = label to value

    private fun sampleFeast(id: String, title: String) = Feast(
        id = id,
        name = BilingualText(title, title),
        summary = "Summary for $title",
        suggestedMysterySet = null,
        isMarian = false,
        rank = FeastRank.Feast,
        dateOn = { null },
        shortTitleOverride = title,
    )
}
