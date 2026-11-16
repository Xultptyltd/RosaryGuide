package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.data.launch.AppTab
import app.rosaryguide.core.data.launch.LaunchGate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LearnArticleTest {
    @Test
    fun learnTabTitleAndIcon() {
        assertEquals("Learn", AppTab.Learn.title)
        assertEquals("TabLearnOutline", AppTab.Learn.iconAsset)
        assertEquals("TabLearnFilled", AppTab.Learn.selectedIconAsset)
        assertEquals(listOf("Today", "Learn", "Feasts", "Profile"), AppTab.titles)
    }

    @Test
    fun meditatingOnTheMysteriesIsACommonQuestion() {
        assertTrue(LearnArticle.Meditate in LearnArticle.commonQuestions)
        assertEquals("How do I meditate on the mysteries?", LearnArticle.Meditate.title)
        assertEquals(3, LearnArticle.Meditate.paragraphs.size)
        for (paragraph in LearnArticle.Meditate.paragraphs) {
            assertTrue(paragraph.isNotBlank())
        }
    }

    @Test
    fun whatIsRosaryIsStartHereAndOthersAreCommonQuestion() {
        assertEquals("Start here", LearnArticle.WhatIsRosary.eyebrow)
        assertEquals("Common question", LearnArticle.HowToPray.eyebrow)
        assertEquals(8, LearnArticle.commonQuestions.size)
        assertEquals("What is the Rosary?", LearnArticle.WhatIsRosary.title)
    }

    @Test
    fun searchChromeCopy() {
        assertEquals("Prayers, mysteries and how to pray", LearnCopy.SEARCH_TITLE)
        assertEquals("Nothing can be found. Try another search", LearnCopy.EMPTY)
    }
}

class HowToPrayContentTest {
    @Test
    fun eightStepsAndWeekdayGuide() {
        assertEquals(8, HowToPrayContent.steps.size)
        assertEquals("Begin with the Sign of the Cross", HowToPrayContent.steps.first().title.english)
        assertEquals("Optional Saint Michael after Finis", HowToPrayContent.steps.last().title.english)
        assertEquals(7, HowToPrayContent.weekdayGuide.size)
        assertEquals("Sunday" to "Glorious Mysteries", HowToPrayContent.weekdayGuide.first())
        assertEquals("Saturday" to "Joyful Mysteries", HowToPrayContent.weekdayGuide.last())
        assertTrue(HowToPrayContent.beadsNote.contains("You do not need beads to pray"))
        assertTrue(HowToPrayContent.steps[1].title.english.contains("Apostles"))
    }
}

class OnboardingCopyTest {
    @Test
    fun threePagesAndBeginCta() {
        assertEquals(3, OnboardingPage.pages.size)
        assertEquals("Make room\nfor prayer.", OnboardingPage.pages[0].title)
        assertEquals("center", OnboardingPage.pages[1].imageAlignment)
        assertTrue(OnboardingPage.pages[2].title.contains("heart"))
        // typographic apostrophe in "what's"
        assertTrue(OnboardingPage.pages[2].title.contains("\u2019") || OnboardingPage.pages[2].title.contains("what"))
        assertEquals("Begin", OnboardingCopy.BEGIN)
        assertEquals("Continue", OnboardingCopy.CONTINUE)
    }

    @Test
    fun signInIsGoogleAndGuestOnly() {
        assertEquals(listOf("google", "guest"), OnboardingCopy.providers)
        assertFalse(OnboardingCopy.providers.contains("apple"))
        assertEquals("Continue with Google", OnboardingCopy.CONTINUE_WITH_GOOGLE)
        assertEquals("Continue as guest", OnboardingCopy.CONTINUE_AS_GUEST)
        assertEquals(
            "\u201CAchain that links\nheaven and earth\u201D".let {
                "\u201C" + "A chain that links\nheaven and earth" + "\u201D"
            },
            OnboardingCopy.signInQuote,
        )
        assertEquals("Attributed to St Thérèse of Lisieux", OnboardingCopy.signInQuoteAttribution)
        assertTrue(OnboardingCopy.LEGAL_PREFIX.startsWith("By continuing you agree to our"))
        assertEquals("https://xult.ltd/terms/", OnboardingCopy.TERMS_URL)
        assertEquals("https://xult.ltd/privacy/", OnboardingCopy.PRIVACY_URL)
    }
}

class LaunchGateTest {
    @Test
    fun showsAppWhenOnboardingCompletedOrAlreadySignedIn() {
        assertFalse(LaunchGate.showsApp(didCompleteOnboarding = false, isSignedIn = false))
        assertTrue(LaunchGate.showsApp(didCompleteOnboarding = true, isSignedIn = false))
        assertTrue(LaunchGate.showsApp(didCompleteOnboarding = false, isSignedIn = true, signedInThisLaunch = false))
        assertFalse(LaunchGate.showsApp(didCompleteOnboarding = false, isSignedIn = true, signedInThisLaunch = true))
        assertTrue(LaunchGate.showsApp(didCompleteOnboarding = true, isSignedIn = true, signedInThisLaunch = true))
    }

    @Test
    fun returnsToOnboardingOnSignOut() {
        assertTrue(LaunchGate.returnsToOnboarding(previousUserId = "u1", userId = null))
        assertFalse(LaunchGate.returnsToOnboarding(previousUserId = null, userId = null))
        assertFalse(LaunchGate.returnsToOnboarding(previousUserId = "u1", userId = "u1"))
    }
}

class FeastNarrativeCatalogTest {
    @Test
    fun narrativesAndScripturesCoverTheDedicatedFeasts() {
        assertEquals(41, FeastNarratives.coveredIds.size)
        assertEquals(41, FeastScriptures.coveredIds.size)
        assertTrue("christmas" in FeastNarratives.coveredIds)
        assertTrue("presentation-mary" in FeastNarratives.coveredIds)
        val christmas = FeastNarratives.narrative("christmas")!!
        assertTrue(christmas.about.contains("Word is made flesh"))
        assertTrue(FeastScriptures.passages("christmas").isNotEmpty())
        assertTrue(FeastScriptures.passages("christmas").any { it.citation.contains("Luke 2") })
        val mercy = FeastNarratives.narrative("divine-mercy")!!
        assertTrue(mercy.indulgence!!.contains("plenary indulgence"))
        assertTrue(christmas.relatedPrayerIds.contains("angelus"))
        assertEquals("The Angelus", FeastRelatedPrayers.byId("angelus")!!.title)
    }
}

class NotificationPromptTest {
    @Test
    fun askedOnceAndNeverAfterDenial() {
        assertEquals("settings.notifications.askedForNotifications", app.rosaryguide.core.data.notify.NotificationPrompt.ASKED_KEY)
        assertEquals(1_000L, app.rosaryguide.core.data.notify.NotificationPrompt.HOME_ARRIVAL_DELAY_MS)
        assertTrue(app.rosaryguide.core.data.notify.NotificationPrompt.shouldPrompt(hasAsked = false, systemPermissionDetermined = false))
        assertFalse(app.rosaryguide.core.data.notify.NotificationPrompt.shouldPrompt(hasAsked = true, systemPermissionDetermined = false))
        assertFalse(app.rosaryguide.core.data.notify.NotificationPrompt.shouldPrompt(hasAsked = false, systemPermissionDetermined = true))
    }
}

class HomeCopyTest {
    @Test
    fun todayChrome() {
        assertEquals("TODAY", HomeCopy.TODAY_PILL)
        assertEquals("Upcoming feast days", HomeCopy.UPCOMING_FEAST_DAYS)
        assertEquals("This week", HomeCopy.THIS_WEEK)
        assertEquals("View all feasts", HomeCopy.VIEW_ALL_FEASTS)
        assertEquals("Pray today's mysteries", HomeCopy.PRAY_TODAYS_MYSTERIES)
        assertEquals("Pray the Joyful Mysteries", HomeCopy.prayTheMysteries(app.rosaryguide.core.model.MysterySetKind.Joyful))
    }
}
