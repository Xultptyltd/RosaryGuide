package app.rosaryguide.core.data.calendar

import app.rosaryguide.core.model.LiturgicalSeason
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit

class LiturgicalCalendarTest {

    private fun monthDay(date: LocalDate): Pair<Int, Int> = date.monthValue to date.dayOfMonth

    private fun season(y: Int, m: Int, d: Int) =
        LiturgicalCalendar.season( LocalDate.of(y, m, d))

    @Test
    fun testEasterDates() {
        assertEquals(3 to 31, monthDay(LiturgicalCalendar.easter(2024)))
        assertEquals(4 to 20, monthDay(LiturgicalCalendar.easter(2025)))
        assertEquals(4 to 5, monthDay(LiturgicalCalendar.easter(2026)))
        assertEquals(3 to 28, monthDay(LiturgicalCalendar.easter(2027)))
        assertEquals(4 to 16, monthDay(LiturgicalCalendar.easter(2028)))
    }

    @Test
    fun testAshWednesdayIsFortySixDaysBeforeEaster() {
        val easter = LiturgicalCalendar.easter(2026)
        val ash = LiturgicalCalendar.ashWednesday(2026)
        assertEquals(46, ChronoUnit.DAYS.between(ash, easter))
        assertEquals(2 to 18, monthDay(ash))
    }

    @Test
    fun testAdvent2026StartsNovember29() {
        assertEquals(11 to 29, monthDay(LiturgicalCalendar.firstSundayOfAdvent(2026)))
    }

    @Test
    fun testSeasonAroundEaster2026() {
        assertEquals(LiturgicalSeason.Ordinary, season(2026, 2, 17))
        assertEquals(LiturgicalSeason.Lent, season(2026, 2, 18))
        assertEquals(LiturgicalSeason.Triduum, season(2026, 4, 2))
        assertEquals(LiturgicalSeason.Easter, season(2026, 4, 5))
        assertEquals(LiturgicalSeason.Easter, season(2026, 5, 24))
        assertEquals(LiturgicalSeason.Ordinary, season(2026, 5, 25))
        assertEquals(LiturgicalSeason.Advent, season(2026, 12, 1))
        assertEquals(LiturgicalSeason.Christmas, season(2026, 12, 25))
        assertEquals(LiturgicalSeason.Christmas, season(2027, 1, 6))
    }

    @Test
    fun testEpiphanyIsSundayOnOrAfterJanuary2() {
        assertEquals(1 to 4, monthDay(LiturgicalCalendar.epiphany(2026)))
        assertEquals(1 to 3, monthDay(LiturgicalCalendar.epiphany(2027)))
        assertEquals(1 to 2, monthDay(LiturgicalCalendar.epiphany(2028)))
        assertEquals(1 to 7, monthDay(LiturgicalCalendar.epiphany(2029)))
        assertEquals(1 to 6, monthDay(LiturgicalCalendar.epiphany(2030)))
        assertEquals(1 to 8, monthDay(LiturgicalCalendar.epiphany(2034)))
        assertEquals(1 to 7, monthDay(LiturgicalCalendar.epiphany(2035)))
    }

    @Test
    fun testBaptismOfTheLordFollowsAppEpiphanyRule() {
        assertEquals(1 to 11, monthDay(LiturgicalCalendar.baptismOfTheLord(2026)))
        assertEquals(1 to 10, monthDay(LiturgicalCalendar.baptismOfTheLord(2027)))
        assertEquals(1 to 9, monthDay(LiturgicalCalendar.baptismOfTheLord(2028)))
        assertEquals(1 to 8, monthDay(LiturgicalCalendar.baptismOfTheLord(2029)))
        assertEquals(1 to 13, monthDay(LiturgicalCalendar.baptismOfTheLord(2030)))
        assertEquals(1 to 9, monthDay(LiturgicalCalendar.baptismOfTheLord(2034)))
        assertEquals(1 to 8, monthDay(LiturgicalCalendar.baptismOfTheLord(2035)))
        for (year in 2026..2036) {
            val epiphany = LiturgicalCalendar.epiphany(year)
            val baptism = LiturgicalCalendar.baptismOfTheLord(year)
            assertTrue("Baptism must not precede Epiphany in $year", !baptism.isBefore(epiphany))
        }
    }

    @Test
    fun testImpededSolemnitiesMoveOffSundaysAndHolyWeek() {
        assertEquals(3 to 20, monthDay(LiturgicalCalendar.saintJoseph(2023)))
        assertEquals(3 to 17, monthDay(LiturgicalCalendar.saintJoseph(2035)))
        assertEquals(3 to 19, monthDay(LiturgicalCalendar.saintJoseph(2026)))
        assertEquals(3 to 26, monthDay(LiturgicalCalendar.annunciation(2012)))
        assertEquals(4 to 9, monthDay(LiturgicalCalendar.annunciation(2029)))
        assertEquals(3 to 25, monthDay(LiturgicalCalendar.annunciation(2026)))
        assertEquals(12 to 9, monthDay(LiturgicalCalendar.immaculateConception(2024)))
        assertEquals(12 to 8, monthDay(LiturgicalCalendar.immaculateConception(2026)))
    }
}
