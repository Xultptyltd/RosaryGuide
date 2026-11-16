package app.rosaryguide.core.data.journey

import java.time.LocalDate
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ported from the non-sync iOS journey milestone cases. */
class JourneyMilestonesTest {
    private val zone = ZoneId.of("Australia/Perth")

    private fun at(year: Int, month: Int, day: Int): Long =
        LocalDate.of(year, month, day).atTime(8, 0).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun testFirstRosaryAndProgressText() {
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = listOf(at(2026, 11, 16)),
            prayerDatesEpochMs = listOf(at(2026, 11, 16)),
            mysteryDatesEpochMs = mapOf("joyful" to at(2026, 11, 16)),
            zone = zone,
        )
        val first = m.items.first { it.id == "Rosaries-1" }
        assertTrue(first.completed)
        assertEquals("First Rosary", first.title)
        assertEquals("1 of 1", first.progressText)
        val ten = m.items.first { it.id == "Rosaries-10" }
        assertFalse(ten.completed)
        assertEquals("1 of 10", ten.progressText)
        assertEquals("10 Rosaries", ten.title)
    }

    @Test
    fun testDaysInPrayerThresholdsAreNotConsecutive() {
        val dates = listOf(1, 3, 5, 8, 10, 12, 16).map { at(2026, 11, it) }
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = dates,
            prayerDatesEpochMs = dates,
            mysteryDatesEpochMs = emptyMap(),
            zone = zone,
        )
        val seven = m.items.first { it.id == "days-7" }
        assertTrue(seven.completed)
        assertEquals("7 days in prayer", seven.title)
        val thirty = m.items.first { it.id == "days-30" }
        assertFalse(thirty.completed)
        assertEquals("7 of 30", thirty.progressText)
    }

    @Test
    fun testSavedHundredDayAwardProvesFiftyFour() {
        val award = JourneyAward(dateEpochMs = at(2026, 1, 1), detail = "Every day of a long season.")
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = emptyList(),
            prayerDatesEpochMs = emptyList(),
            mysteryDatesEpochMs = emptyMap(),
            awards = mapOf("days-100" to award),
            zone = zone,
        )
        val fiftyFour = m.items.first { it.id == "days-54" }
        assertTrue(fiftyFour.completed)
        assertEquals("Every day of a long season.", fiftyFour.description)
        assertEquals(54, fiftyFour.count)
    }

    @Test
    fun testAllFourMysterySetsEarnAtTheLastDate() {
        val joyful = at(2026, 11, 1)
        val luminous = at(2026, 11, 2)
        val sorrowful = at(2026, 11, 10)
        val glorious = at(2026, 11, 16)
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = listOf(joyful, luminous, sorrowful, glorious),
            prayerDatesEpochMs = listOf(joyful, luminous, sorrowful, glorious),
            mysteryDatesEpochMs = mapOf(
                "joyful" to joyful,
                "luminous" to luminous,
                "sorrowful" to sorrowful,
                "glorious" to glorious,
            ),
            zone = zone,
        )
        val all = m.items.first { it.id == "all-mysteries" }
        assertTrue(all.completed)
        assertEquals(glorious, all.earnedAtEpochMs)
        assertEquals("4 of 4", all.progressText)
        assertEquals("All four mystery sets", all.title)
    }

    @Test
    fun testOfferingAwards() {
        val someone = at(2026, 11, 2)
        val world = at(2026, 11, 8)
        val papal = at(2026, 11, 16)
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = listOf(someone, world, papal),
            prayerDatesEpochMs = listOf(someone, world, papal),
            mysteryDatesEpochMs = emptyMap(),
            offeringDatesEpochMs = mapOf(
                "someone" to someone,
                "world" to world,
                "papal" to papal,
            ),
            zone = zone,
        )
        assertTrue(m.items.first { it.id == "rosary-for-another" }.completed)
        assertTrue(m.items.first { it.id == "rosary-for-church" }.completed)
        val pope = m.items.first { it.id == "rosary-for-pope" }
        assertTrue(pope.completed)
        assertEquals("A Rosary for the Pope’s intention", pope.title)
        assertEquals(papal, pope.earnedAtEpochMs)
    }

    @Test
    fun testPreviewPrefersEasierNonFeastItems() {
        val dates = (1..6).map { at(2026, 11, it) }
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = dates,
            prayerDatesEpochMs = dates,
            mysteryDatesEpochMs = mapOf("joyful" to dates.first()),
            offeringDatesEpochMs = emptyMap(),
            zone = zone,
        )
        val preview = m.preview
        assertTrue(preview.isNotEmpty())
        assertTrue(preview.none { it.category == JourneyMilestones.Category.Feasts } || preview.size < 3)
        assertTrue(preview.all { !it.completed })
    }

    @Test
    fun testOurLadyOfTheRosaryUsesTheFeastDay() {
        // 7 October 2026 is Our Lady of the Rosary.
        val feast = at(2026, 10, 7)
        val m = JourneyMilestones.from(
            rosaryDatesEpochMs = listOf(feast),
            prayerDatesEpochMs = listOf(feast),
            mysteryDatesEpochMs = emptyMap(),
            zone = zone,
        )
        val item = m.items.first { it.id == "our-lady-of-the-rosary" }
        assertTrue(item.completed)
        val marian = m.items.first { it.id == "marian-feasts-1" }
        assertTrue(marian.completed)
        assertTrue(marian.description.startsWith("Reached on"))
    }
}

class JourneyDayDetailTest {
    private val zone = ZoneId.of("Australia/Perth")

    @Test
    fun testHeadingIsAbbreviatedAsOn11Nov2026() {
        assertEquals(
            "Wed, 11 Nov 2026",
            JourneyDayDetail.heading(LocalDate.of(2026, 11, 11)),
        )
        assertEquals(
            "Mon, 16 Nov 2026",
            JourneyDayDetail.heading(LocalDate.of(2026, 11, 16)),
        )
    }

    @Test
    fun testIntentionLineIsShortenedCountText() {
        assertEquals("1 intention", JourneyDayDetail.intentionLine(listOf("Mum")))
        assertEquals("2 intentions", JourneyDayDetail.intentionLine(listOf("Mum", "Peace")))
        org.junit.Assert.assertNull(JourneyDayDetail.intentionLine(emptyList()))
        assertEquals("Mum and Peace", JourneyDayDetail.summary(listOf("Mum", "Peace")))
    }

    @Test
    fun testRecordedDayFallbackAndDurationSum() {
        val entries = JourneyDayDetail.entries(
            dayKey = "2026-11-11",
            sessions = emptyList(),
            decades = emptyList(),
            prayedDayKeys = setOf("2026-11-11"),
            zone = zone,
        )
        assertEquals(1, entries.size)
        assertEquals(JourneyDayEntry.Kind.RecordedDay, entries.first().kind)
        org.junit.Assert.assertNull(JourneyDayDetail.totalDuration(entries))
    }
}

class PopeIntentionCatalogTest {
    @Test
    fun testBundledNovember2026Intention() {
        val all = PopeIntentionCatalog.load()
        assertEquals(24, all.size)
        assertEquals("2026-01", all.first().yearMonth)
        val nov = PopeIntentionCatalog.intention(LocalDate.of(2026, 11, 16))
        org.junit.Assert.assertNotNull(nov)
        assertEquals("November 2026", nov!!.monthLabel())
        assertTrue(nov.title.isNotBlank())
    }
}
