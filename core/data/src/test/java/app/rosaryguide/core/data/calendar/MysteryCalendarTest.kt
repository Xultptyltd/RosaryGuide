package app.rosaryguide.core.data.calendar

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.model.DayClock
import app.rosaryguide.core.model.LiturgicalSeason
import app.rosaryguide.core.model.MysterySetKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class MysteryCalendarTest {

    private fun date(y: Int, m: Int, d: Int) = LocalDate.of(y, m, d)
    private fun setOn(y: Int, m: Int, d: Int) = MysteryCalendar.assignment( date(y, m, d)).set
    private fun setDefault(y: Int, m: Int, d: Int) =
        MysteryCalendar.assignment( date(y, m, d)).defaultSet(prefersWeekday = false)
    private fun on(y: Int, m: Int, d: Int) = MysteryCalendar.assignment( date(y, m, d))

    @Test
    fun testEveryMysteryHasCardSummary() {
        assertEquals(20, MysteryCatalog.all.size)
        for (mystery in MysteryCatalog.all) {
            val line = mystery.summary.trim()
            assertTrue(mystery.id, line.isNotEmpty())
            assertTrue(mystery.id, line.endsWith("."))
            assertTrue(mystery.id, line.split(" ").size <= 6)
        }
    }

    @Test
    fun testWeekdayAssignmentsInOrdinaryTime() {
        assertEquals(MysterySetKind.Joyful, setOn(2026, 9, 14))
        assertEquals(MysterySetKind.Sorrowful, setOn(2026, 9, 15))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 9, 16))
        assertEquals(MysterySetKind.Luminous, setOn(2026, 9, 17))
        assertEquals(MysterySetKind.Sorrowful, setOn(2026, 9, 18))
        assertEquals(MysterySetKind.Joyful, setOn(2026, 9, 19))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 9, 20))
    }

    @Test
    fun testSundaysAreAlwaysGlorious() {
        assertEquals(MysterySetKind.Glorious, setOn(2026, 11, 29))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 12, 27))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 3, 1))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 3, 29))
        assertEquals(MysterySetKind.Glorious, setOn(2026, 4, 12))
        assertEquals("Wednesdays and Sundays", MysterySetKind.Glorious.days(LiturgicalSeason.Lent))
        assertEquals("Mondays and Saturdays", MysterySetKind.Joyful.days(LiturgicalSeason.Advent))
    }

    @Test
    fun testFeastsDoNotOverrideWeekdaySet() {
        assertEquals(MysterySetKind.Sorrowful, setOn(2026, 12, 25))
        assertEquals(MysterySetKind.Joyful, setOn(2026, 8, 15))
        val christmas = MysteryCalendar.assignment( date(2026, 12, 25))
        assertEquals(MysterySetKind.Joyful, christmas.feastSuggestion)
        val assumption = MysteryCalendar.assignment( date(2026, 8, 15))
        assertEquals(MysterySetKind.Glorious, assumption.feastSuggestion)
    }

    @Test
    fun testHomeDefaultsToTheFeastSetAndCanSwitch() {
        val christmas = MysteryCalendar.assignment( date(2026, 12, 25))
        assertEquals(MysterySetKind.Sorrowful, christmas.set)
        assertEquals(MysterySetKind.Joyful, christmas.defaultSet(prefersWeekday = false))
        assertEquals(MysterySetKind.Sorrowful, christmas.defaultSet(prefersWeekday = true))
        assertEquals(MysterySetKind.Joyful, christmas.shownSet(manual = null, prefersWeekday = false))
        assertEquals(MysterySetKind.Sorrowful, christmas.pickerDotSet)
        assertEquals(MysterySetKind.Luminous, christmas.shownSet(manual = MysterySetKind.Luminous, prefersWeekday = false))
        assertEquals(MysterySetKind.Luminous, christmas.shownSet(manual = MysterySetKind.Luminous, prefersWeekday = true))
        val line = christmas.feastLine!!
        assertEquals("Today we celebrate the birth of our Lord. Many pray the Joyful Mysteries at Christmas.", line.text)
        assertEquals("Joyful Mysteries", line.setName)
        assertEquals("Back to today", app.rosaryguide.core.model.FeastLine.BACK_TO_TODAY_TITLE)
    }

    @Test
    fun testOnlyMajorFeastsRecommendASetOnHome() {
        val ids = setOf(
            "christmas", "annunciation", "immaculate-conception", "ash-wednesday", "good-friday",
            "holy-thursday", "baptism-movable", "corpus-christi", "easter", "assumption", "pentecost",
        )
        assertEquals(ids, FeastCatalog.all.filter { it.recommendsOnHome }.map { it.id }.toSet())
        assertEquals(ids, FeastCatalog.celebrations.keys)
        assertEquals(MysterySetKind.Glorious, setDefault(2026, 8, 15))
        assertEquals(MysterySetKind.Glorious, setDefault(2026, 2, 11))
        assertNull(MysteryCalendar.assignment( date(2026, 2, 11)).feastLine)
        assertEquals(MysterySetKind.Sorrowful, setDefault(2026, 10, 2))
        assertNull(MysteryCalendar.assignment( date(2026, 10, 2)).feastLine)
        assertEquals(MysterySetKind.Joyful, setDefault(2026, 12, 8))
        assertEquals(MysterySetKind.Joyful, FeastCatalog.all.first { it.id == "guadalupe" }.suggestedMysterySet)
        for (id in ids) {
            val line = FeastCatalog.celebrations.getValue(id)
            assertTrue(id, line.today.startsWith("Today "))
            assertTrue(id, line.today.endsWith("."))
            assertFalse(id, line.occasion.endsWith("."))
            assertTrue(id, line.occasion.startsWith("on ") || line.occasion.startsWith("at "))
        }
    }

    @Test
    fun testHomeKeepsWeekdaySetWhenFeastAgreesOrNoFeast() {
        val assumption = MysteryCalendar.assignment( date(2027, 8, 15))
        assertNotNull(assumption.feast)
        assertNull(assumption.feastSuggestion)
        assertNull(assumption.feastLine)
        assertEquals(MysterySetKind.Glorious, assumption.defaultSet(prefersWeekday = false))
        val plain = MysteryCalendar.assignment( date(2026, 9, 17))
        assertEquals(MysterySetKind.Luminous, plain.defaultSet(prefersWeekday = false))
        assertNull(plain.feastLine)
    }

    @Test
    fun testWeekdayChoiceResetsAtDayRollover() {
        val start = date(2026, 12, 25)
        val clock = DayClock(start)
        clock.prefersWeekdaySet = true
        clock.refresh(start)
        assertTrue(clock.prefersWeekdaySet)
        clock.refresh(start.plusDays(1))
        assertFalse(clock.prefersWeekdaySet)
    }

    @Test
    fun testCatalogHasTwentyMysteriesWithArtSlugs() {
        assertEquals(20, MysteryCatalog.all.size)
        for (set in MysterySetKind.displayOrder) {
            val items = MysteryCatalog.mysteries(set)
            assertEquals(5, items.size)
            assertTrue(items.all { it.artSlug.isNotEmpty() })
        }
    }

    @Test
    fun testWeekdayCaptionsMatchCalendar() {
        val weeks = listOf(Triple(2026, 9, 14), Triple(2026, 11, 30), Triple(2026, 3, 2))
        val names = listOf("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
        for ((y, m, d) in weeks) {
            val days = mutableMapOf<MysterySetKind, MutableList<String>>()
            for (offset in 0 until 7) {
                val day = date(y, m, d).plusDays(offset.toLong())
                val weekday = LiturgicalCalendar.weekday(day)
                days.getOrPut(MysteryCalendar.assignment(day).set) { mutableListOf<String>() }
                    .add(names[weekday - 1])
            }
            for (set in MysterySetKind.displayOrder) {
                assertEquals(
                    "$set $y-$m",
                    set.weekdayCaption.split(" · ").toSet(),
                    days[set]?.toSet() ?: emptySet<String>(),
                )
            }
        }
    }

    @Test
    fun testAdventSundaysSuggestJoyful() {
        fun assertSuggests(expected: MysterySetKind?, y: Int, m: Int, d: Int) {
            assertEquals(date(y, m, d).toString(), expected, on(y, m, d).feastSuggestion)
        }
        assertSuggests(MysterySetKind.Joyful, 2026, 11, 29)
        assertSuggests(MysterySetKind.Joyful, 2026, 12, 20)
        assertSuggests(null, 2026, 11, 22)
        assertSuggests(MysterySetKind.Joyful, 2025, 11, 30)
        assertSuggests(MysterySetKind.Joyful, 2025, 12, 21)
        assertSuggests(null, 2025, 11, 23)
        assertSuggests(MysterySetKind.Joyful, 2027, 11, 28)
        assertSuggests(MysterySetKind.Joyful, 2027, 12, 19)
        assertSuggests(MysterySetKind.Joyful, 2028, 12, 3)
        assertSuggests(MysterySetKind.Joyful, 2028, 12, 24)
    }

    @Test
    fun testLentSundaysSuggestSorrowfulThroughPalmSunday() {
        fun assertSuggests(expected: MysterySetKind?, y: Int, m: Int, d: Int) {
            assertEquals(date(y, m, d).toString(), expected, on(y, m, d).feastSuggestion)
        }
        assertSuggests(MysterySetKind.Sorrowful, 2026, 2, 22)
        assertSuggests(MysterySetKind.Sorrowful, 2026, 3, 29)
        assertSuggests(null, 2026, 4, 5)
        assertSuggests(null, 2026, 2, 15)
        assertSuggests(MysterySetKind.Sorrowful, 2025, 3, 9)
        assertSuggests(MysterySetKind.Sorrowful, 2025, 4, 13)
        assertSuggests(null, 2025, 4, 20)
        assertSuggests(MysterySetKind.Sorrowful, 2027, 2, 14)
        assertSuggests(MysterySetKind.Sorrowful, 2027, 3, 21)
        assertSuggests(null, 2027, 3, 28)
    }

    @Test
    fun testWeekdaysInAdventAndLentAreUnchanged() {
        assertNull(on(2026, 12, 1).feastSuggestion)
        assertNull(on(2026, 3, 4).feastSuggestion)
    }

    @Test
    fun testSeasonalLineCopy() {
        val advent = on(2026, 11, 29).feastLine!!
        assertEquals("Many pray the Joyful Mysteries on Sundays of Advent", advent.text)
        assertEquals("Joyful Mysteries", advent.setName)
        val lent = on(2026, 3, 29).feastLine!!
        assertEquals("Many pray the Sorrowful Mysteries on Sundays of Lent", lent.text)
        assertFalse(advent.text.contains("."))
    }

    @Test
    fun testFeastTakesPrecedenceOverSeasonalSunday() {
        val christmas = FeastCatalog.dated( 2026).first { it.feast.id == "christmas" }
        val a = on(2026, 11, 29).copy(feast = christmas)
        assertEquals(MysterySetKind.Joyful, a.feastSuggestion)
        assertTrue(a.feastLine!!.text.startsWith("Today we celebrate the birth of our Lord."))
        val easter = FeastCatalog.dated( 2026).first { it.feast.id == "easter" }
        val lent = on(2026, 3, 29).copy(feast = easter)
        assertNull(lent.feastSuggestion)
    }

    @Test
    fun testWeekFollowsFirstWeekday() {
        val sunday = date(2026, 10, 18)
        val monday = MysteryCalendar.week(date = sunday, firstWeekday = 2)
        assertEquals(2, LiturgicalCalendar.weekday(monday.first().first))
        assertEquals(12, monday.first().first.dayOfMonth)
        val sundayStart = MysteryCalendar.week(date = sunday, firstWeekday = 1)
        assertEquals(18, sundayStart.first().first.dayOfMonth)
        assertEquals(7, sundayStart.size)
    }
}
