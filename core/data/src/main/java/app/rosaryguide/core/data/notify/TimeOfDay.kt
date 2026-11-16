package app.rosaryguide.core.data.notify

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId

/** Minutes-from-midnight helpers, ported from iOS `TimeOfDay`. */
object TimeOfDay {
    const val DEFAULT_REMINDER_MINUTES = 9 * 60

    fun minutes(hour: Int, minute: Int): Int = hour * 60 + minute

    fun hour(minutes: Int): Int = minutes.coerceIn(0, 24 * 60 - 1) / 60

    fun minute(minutes: Int): Int = minutes.coerceIn(0, 24 * 60 - 1) % 60

    fun format(minutes: Int): String {
        val h = hour(minutes)
        val m = minute(minutes)
        val ampm = if (h >= 12) "pm" else "am"
        val hour12 = when (val v = h % 12) {
            0 -> 12
            else -> v
        }
        return if (m == 0) "$hour12:00 $ampm" else "%d:%02d %s".format(hour12, m, ampm)
    }

    fun atDate(day: LocalDate, minutes: Int, zone: ZoneId): LocalDateTime =
        LocalDateTime.of(day, LocalTime.of(hour(minutes), minute(minutes)))

    fun nextTriggerEpochMs(from: LocalDateTime, minutes: Int, zone: ZoneId): Long {
        var day = from.toLocalDate()
        var whenTime = atDate(day, minutes, zone)
        if (!whenTime.isAfter(from)) day = day.plusDays(1)
        whenTime = atDate(day, minutes, zone)
        return whenTime.atZone(zone).toInstant().toEpochMilli()
    }
}
