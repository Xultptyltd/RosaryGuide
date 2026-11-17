package app.rosaryguide.core.data.notify

import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.Feast
import app.rosaryguide.core.model.FeastRank
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationPlanTest {
    private val zone = ZoneId.of("Australia/Perth")
    private val now = LocalDateTime.of(LocalDate.of(2026, 11, 16), LocalTime.of(8, 0))

    @Test
    fun dailyPlanSchedulesSevenWeekdayTriggers() {
        val plan = NotificationPlan.build(
            NotificationPlan.Settings(true, TimeOfDay.DEFAULT_REMINDER_MINUTES, false, TimeOfDay.DEFAULT_REMINDER_MINUTES),
            now,
            zone,
        )
        assertEquals(7, plan.size)
        assertTrue(plan.all { it.kind == ReminderKind.Daily })
        assertTrue(plan.all { it.body.contains("Mysteries") })
    }

    @Test
    fun feastPlanUsesExactCopyAndCapsAtThirtyDays() {
        val from = now.toLocalDate()
        val upcoming = (0 until 40).associate { offset ->
            val day = from.plusDays(offset.toLong() + 1)
            day to listOf(
                Feast(
                    id = "f$offset",
                    name = BilingualText("Feast $offset", ""),
                    summary = "",
                    suggestedMysterySet = null,
                    isMarian = false,
                    rank = FeastRank.Memorial,
                    dateOn = { day },
                ),
            )
        }
        val plan = NotificationPlan.build(
            NotificationPlan.Settings(false, TimeOfDay.DEFAULT_REMINDER_MINUTES, true, TimeOfDay.DEFAULT_REMINDER_MINUTES),
            now,
            zone,
        ) { upcoming }
        assertEquals(30, plan.size)
        assertTrue(plan.first().body.startsWith("Today is "))
    }

    @Test
    fun disabledPlanIsEmpty() {
        val plan = NotificationPlan.build(
            NotificationPlan.Settings(false, TimeOfDay.DEFAULT_REMINDER_MINUTES, false, TimeOfDay.DEFAULT_REMINDER_MINUTES),
            now,
            zone,
        )
        assertTrue(plan.isEmpty())
    }

    @Test
    fun remindMeUsesFeastCopyAndScheduledTime() {
        val feast = Feast(
            id = "rosary",
            name = BilingualText("Our Lady of the Rosary", ""),
            summary = "",
            suggestedMysterySet = null,
            isMarian = true,
            rank = FeastRank.Memorial,
            dateOn = { null },
        )
        val date = LocalDate.of(2026, 11, 20)
        val reminder = NotificationPlan.remindMeReminder(
            feast = feast,
            date = date,
            minutes = 9 * 60,
            now = now,
            zone = zone,
        )
        assertEquals(ReminderKind.Feast, reminder.kind)
        assertTrue(reminder.id >= NotificationPlan.REMIND_ME_ID_BASE)
        assertEquals(date.toString(), reminder.dayKey)
        assertTrue(reminder.body.contains("Our Lady of the Rosary"))
        val trigger = java.time.Instant.ofEpochMilli(reminder.triggerEpochMs).atZone(zone).toLocalDateTime()
        assertEquals(date, trigger.toLocalDate())
        assertEquals(9, trigger.hour)
    }
}
