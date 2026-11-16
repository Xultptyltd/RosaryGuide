package app.rosaryguide.core.data.journey

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ported from the iOS `ActivePrayerClock` cases in `PrayerRhythmTests`. */
class ActivePrayerClockTest {
    @Test
    fun testIdleGapIsCappedAtTenMinutes() {
        var clock = ActivePrayerClock().resume(0)
        val (_, credited) = clock.take(30 * 60 * 1000L, keepRunning = false)
        assertEquals(10 * 60.0, credited, 0.01)
    }

    @Test
    fun testTouchResetsTheIdleAllowance() {
        var clock = ActivePrayerClock().resume(0)
        clock = clock.touch(8 * 60 * 1000L)
        val (_, credited) = clock.take(18 * 60 * 1000L, keepRunning = false)
        assertEquals(18 * 60.0, credited, 0.01)
    }

    @Test
    fun testAbandonedGapStaysCappedWhenKeepRunning() {
        var clock = ActivePrayerClock().resume(0)
        val (next, first) = clock.take(30 * 60 * 1000L, keepRunning = true)
        assertEquals(10 * 60.0, first, 0.01)
        val (_, second) = next.take(40 * 60 * 1000L, keepRunning = false)
        assertEquals(0.0, second, 0.01)
    }

    @Test
    fun testStepBanksTimeAndResumes() {
        var clock = ActivePrayerClock().resume(0)
        val (next, credited) = clock.step(90_000L)
        assertEquals(90.0, credited, 0.01)
        assertTrue(next.isRunning)
        val (_, later) = next.take(150_000L, keepRunning = false)
        assertEquals(60.0, later, 0.01)
    }

    @Test
    fun testPausedClockStepReturnsZero() {
        val clock = ActivePrayerClock()
        val (next, credited) = clock.step(1_000L)
        assertEquals(0.0, credited, 0.01)
        assertFalse(next.isRunning)
    }

    @Test
    fun testClockDoesNotRunBackwards() {
        var clock = ActivePrayerClock().resume(10_000L)
        val (_, credited) = clock.take(1_000L, keepRunning = false)
        assertEquals(0.0, credited, 0.01)
    }
}

class JourneyDurationTest {
    @Test
    fun testTextRules() {
        assertEquals("Under a minute", JourneyDuration.text(20.0))
        assertEquals("1 min", JourneyDuration.text(60.0))
        assertEquals("18 mins", JourneyDuration.text(18 * 60.0))
        assertEquals("1 hr", JourneyDuration.text(60 * 60.0))
        assertEquals("1 hr 5 mins", JourneyDuration.text(65 * 60.0))
        assertEquals("2 hrs", JourneyDuration.text(120 * 60.0))
        assertEquals("2 hrs 1 min", JourneyDuration.text(121 * 60.0))
    }

    @Test
    fun testReliableRejectsZeroAndOverlong() {
        org.junit.Assert.assertNull(JourneyDuration.reliable(0.0))
        org.junit.Assert.assertNull(JourneyDuration.reliable(0.5))
        org.junit.Assert.assertNull(JourneyDuration.reliable(3 * 60 * 60 + 1.0))
        assertEquals(90.0, JourneyDuration.reliable(90.0)!!, 0.01)
    }

    @Test
    fun testDayTotalCapsAtTwelveHours() {
        assertEquals(12 * 60 * 60.0, JourneyDuration.dayTotal(20 * 60 * 60.0), 0.01)
        assertEquals(0.0, JourneyDuration.dayTotal(Double.NaN), 0.01)
    }
}
