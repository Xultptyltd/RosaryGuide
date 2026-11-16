package app.rosaryguide.core.data.journey

import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Ported from iOS `PrayerRhythmTests` caption and streak cases.
 * Calendar is Gregorian English, Monday-start (firstWeekday = 2).
 */
class PrayerRhythmTest {
    private val zone: ZoneId = ZoneId.of("Australia/Perth")
    private val locale: Locale = Locale.forLanguageTag("en-AU")

    private fun at(year: Int, month: Int, day: Int, hour: Int = 8): Long =
        LocalDate.of(year, month, day).atTime(hour, 0).atZone(zone).toEpochSecond()

    private fun start(year: Int, month: Int, day: Int): Long =
        LocalDate.of(year, month, day).atStartOfDay(zone).toEpochSecond()

    private fun rhythm(nowY: Int, nowM: Int, nowD: Int, vararg days: Triple<Int, Int, Int>): PrayerRhythm {
        val prayed = days.map { start(it.first, it.second, it.third) }.toSet()
        return PrayerRhythm.from(
            prayedDayStarts = prayed,
            now = java.time.Instant.ofEpochSecond(at(nowY, nowM, nowD)),
            zone = zone,
            firstWeekday = 2,
            locale = locale,
        )
    }

    private fun assertCard(r: PrayerRhythm, streak: String, caption: String, milestone: Boolean? = null) {
        assertEquals(streak, r.streakText)
        assertEquals(caption, r.caption)
        if (milestone != null) assertEquals(milestone, r.isMilestone)
    }

    @Test
    fun testNeverPrayed() {
        val r = rhythm(2026, 11, 16)
        assertCard(r, "0 days", "Start your rhythm this week", false)
        assertEquals("0 days", r.card.big)
        assertEquals("Start this week", r.card.caption)
        assertEquals("Find room for prayer", r.weeklySummary)
        assertFalse(r.hasEverPrayed)
    }

    @Test
    fun testOnceThisWeek() {
        val r = rhythm(2026, 11, 16, Triple(2026, 11, 16))
        assertCard(r, "1 day", "Once this week", false)
        assertEquals(1, r.prayedDaysThisWeek)
        assertTrue(r.prayedToday)
    }

    @Test
    fun testTwiceThisWeek() {
        val r = rhythm(2026, 11, 17, Triple(2026, 11, 16), Triple(2026, 11, 17))
        assertCard(r, "1 week", "Twice this week", false)
        assertEquals(2, r.prayedDaysThisWeek)
    }

    @Test
    fun testThreeDaysThisWeekWhenNotADailyRun() {
        // Monday, Wednesday and Friday of the same week: three distinct days, daily run is 1.
        val r = rhythm(2026, 11, 20, Triple(2026, 11, 16), Triple(2026, 11, 18), Triple(2026, 11, 20))
        assertEquals(1, r.dailyRun)
        assertEquals(3, r.prayedDaysThisWeek)
        assertCard(r, "1 week", "Three days this week", false)
    }

    @Test
    fun testThreeDaysInARowOnTheDay() {
        val r = rhythm(2026, 11, 18, Triple(2026, 11, 16), Triple(2026, 11, 17), Triple(2026, 11, 18))
        assertCard(r, "3 days", "Three days in a row", true)
        assertEquals("3 days", r.card.big)
    }

    @Test
    fun testThreeDayRunWithoutPrayingToday() {
        val r = rhythm(2026, 11, 19, Triple(2026, 11, 16), Triple(2026, 11, 17), Triple(2026, 11, 18))
        assertCard(r, "3 days", "Pray today to keep it", false)
        assertEquals(3, r.dailyRun)
        assertFalse(r.prayedToday)
    }

    @Test
    fun testFindingYourRhythmOnDayFive() {
        val days = (14..18).map { Triple(2026, 11, it) }
        val r = rhythm(2026, 11, 18, *days.toTypedArray())
        assertCard(r, "5 days", "Finding your rhythm", true)
    }

    @Test
    fun testEveryDayThisWeekOnDaySeven() {
        val days = (12..18).map { Triple(2026, 11, it) }
        val r = rhythm(2026, 11, 18, *days.toTypedArray())
        assertCard(r, "7 days", "Every day this week", true)
    }

    @Test
    fun testEveryDaySinceDayMonthOnDayTen() {
        val days = (9..18).map { Triple(2026, 11, it) }
        val r = rhythm(2026, 11, 18, *days.toTypedArray())
        assertCard(r, "10 days", "Every day since 9 Nov", true)
    }

    @Test
    fun testFortnight() {
        val days = (5..18).map { Triple(2026, 11, it) }
        val r = rhythm(2026, 11, 18, *days.toTypedArray())
        assertCard(r, "14 days", "A fortnight of prayer", true)
    }

    @Test
    fun testSeeYouTomorrowOnNonMilestoneDailyRun() {
        val days = (15..18).map { Triple(2026, 11, it) }
        val r = rhythm(2026, 11, 18, *days.toTypedArray())
        assertCard(r, "4 days", "See you tomorrow", false)
        assertEquals("In a row", r.card.caption)
    }

    @Test
    fun testWelcomeBackAfterEmptyWeek() {
        // Prayed the week before last, skipped last week, prayed this week (week of 16 Nov).
        val r = rhythm(2026, 11, 16, Triple(2026, 11, 2), Triple(2026, 11, 16))
        assertTrue(r.isWelcomeBack)
        assertCard(r, "1 week", "Welcome back", false)
        assertEquals("1 day", r.card.big)
        assertEquals("Welcome back", r.card.caption)
    }

    @Test
    fun testTwoWeeksRunning() {
        // This week (Mon 16) and last week (Mon 9–Sun 15).
        val r = rhythm(2026, 11, 16, Triple(2026, 11, 10), Triple(2026, 11, 16))
        assertEquals(2, r.weekRun)
        assertCard(r, "2 weeks", "Two weeks running", true)
    }

    @Test
    fun testPrayThisWeekToKeepIt() {
        // Last week only; today (Mon 16) not prayed.
        val r = rhythm(2026, 11, 16, Triple(2026, 11, 10))
        assertEquals(1, r.weekRun)
        assertCard(r, "1 week", "Pray this week to keep it", false)
    }

    @Test
    fun testLapsedResetsToStartYourRhythm() {
        // Prayed in October, nothing last week or this week (now Mon 16 Nov).
        val r = rhythm(2026, 11, 16, Triple(2026, 10, 12))
        assertEquals(0, r.weekRun)
        assertCard(r, "0 weeks", "Start your rhythm this week", false)
        assertEquals("0 days", r.card.big)
        assertEquals("Start this week", r.card.caption)
    }

    @Test
    fun testSeeYouNextWeekOnNonMilestoneWeekRun() {
        // Five-week run is not a listed milestone.
        val r = rhythm(
            2026, 11, 16,
            Triple(2026, 10, 12),
            Triple(2026, 10, 19),
            Triple(2026, 10, 26),
            Triple(2026, 11, 2),
            Triple(2026, 11, 9),
            Triple(2026, 11, 16),
        )
        assertEquals(6, r.weekRun)
        assertCard(r, "6 weeks", "See you next week", false)
        assertEquals("In a row", r.card.caption)
    }

    @Test
    fun testMonthGridTodayAndFuture() {
        val r = rhythm(2026, 11, 16, Triple(2026, 11, 16))
        assertEquals("November", r.monthName)
        assertEquals(1, r.prayedDaysThisMonth)
        val today = r.weeks.flatten().first { it?.isToday == true }
        assertEquals(16, today!!.number)
        assertTrue(today.prayed)
        val future = r.weeks.flatten().first { it?.number == 17 }
        assertTrue(future!!.isFuture)
        assertFalse(future.prayed)
        // Monday-start: 1 Nov 2026 is Sunday, so leading blanks = 6.
        assertEquals(6, r.weeks.first().count { it == null })
        assertEquals(listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"), r.weekdayLabels)
    }

    @Test
    fun testFortyDaysLikeLent() {
        val start = LocalDate.of(2026, 10, 10)
        val days = (0 until 40).map { start.plusDays(it.toLong()) }.map { Triple(it.year, it.monthValue, it.dayOfMonth) }
        val last = start.plusDays(39)
        val r = rhythm(last.year, last.monthValue, last.dayOfMonth, *days.toTypedArray())
        assertCard(r, "40 days", "Forty days, like Lent", true)
    }

    @Test
    fun testAFullNovenaOnDayFiftyFour() {
        val start = LocalDate.of(2026, 9, 26)
        val days = (0 until 54).map { start.plusDays(it.toLong()) }.map { Triple(it.year, it.monthValue, it.dayOfMonth) }
        val last = start.plusDays(53)
        val r = rhythm(last.year, last.monthValue, last.dayOfMonth, *days.toTypedArray())
        assertCard(r, "54 days", "A full novena", true)
    }
}
