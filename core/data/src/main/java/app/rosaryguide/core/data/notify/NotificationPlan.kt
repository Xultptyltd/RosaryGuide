package app.rosaryguide.core.data.notify

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.model.Feast
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.math.abs

enum class ReminderKind { Daily, Feast }

data class ScheduledReminder(
    val id: Int,
    val kind: ReminderKind,
    val triggerEpochMs: Long,
    val body: String,
    val dayKey: String,
)

/**
 * Builds the local reminder schedule, ported from iOS `NotificationService.Plan`.
 * Daily uses seven weekday triggers; feast alerts cover up to [MAX_FEAST_DAYS]
 * upcoming days from the feast catalog.
 */
object NotificationPlan {
    const val MAX_FEAST_DAYS = 30
    const val DAILY_ID_BASE = 100
    const val FEAST_ID_BASE = 200
    const val REMIND_ME_ID_BASE = 500

    data class Settings(
        val dailyEnabled: Boolean,
        val dailyMinutes: Int,
        val feastEnabled: Boolean,
        val feastMinutes: Int,
    ) {
        val isEmpty: Boolean get() = !dailyEnabled && !feastEnabled
    }

    fun build(
        settings: Settings,
        now: LocalDateTime,
        zone: ZoneId,
        upcomingFeasts: (LocalDate) -> Map<LocalDate, List<Feast>> = { day ->
            defaultUpcoming(day)
        },
    ): List<ScheduledReminder> {
        val items = mutableListOf<ScheduledReminder>()
        if (settings.dailyEnabled) {
            for (offset in 0 until 7) {
                val day = now.toLocalDate().plusDays(offset.toLong())
                val at = TimeOfDay.atDate(day, settings.dailyMinutes, zone)
                val trigger = if (at.isAfter(now)) at else TimeOfDay.atDate(day.plusDays(7), settings.dailyMinutes, zone)
                items += ScheduledReminder(
                    id = DAILY_ID_BASE + ((day.dayOfWeek.value) % 7),
                    kind = ReminderKind.Daily,
                    triggerEpochMs = trigger.atZone(zone).toInstant().toEpochMilli(),
                    body = ReminderCopy.dailyBody(day.dayOfWeek.value, day),
                    dayKey = trigger.toLocalDate().toString(),
                )
            }
        }
        if (settings.feastEnabled) {
            val byDay = upcomingFeasts(now.toLocalDate())
            var index = 0
            for ((day, feasts) in byDay.toSortedMap()) {
                if (index >= MAX_FEAST_DAYS) break
                if (feasts.isEmpty()) continue
                val at = TimeOfDay.atDate(day, settings.feastMinutes, zone)
                if (!at.isAfter(now) && day == now.toLocalDate()) continue
                if (!at.isAfter(now)) continue
                items += ScheduledReminder(
                    id = FEAST_ID_BASE + index,
                    kind = ReminderKind.Feast,
                    triggerEpochMs = at.atZone(zone).toInstant().toEpochMilli(),
                    body = ReminderCopy.feastBody(feasts),
                    dayKey = day.toString(),
                )
                index += 1
            }
        }
        return items
    }

    private fun defaultUpcoming(from: LocalDate): Map<LocalDate, List<Feast>> {
        return FeastCatalog.upcoming(from, limit = 80)
            .groupBy { it.date }
            .mapValues { (_, dated) -> dated.map { it.feast } }
            .toSortedMap()
            .entries
            .take(MAX_FEAST_DAYS)
            .associate { it.key to it.value }
    }

    /**
     * A one-off feast reminder for the feast-detail “Remind me” action.
     * Uses the same copy and time-of-day as the regular feast-alert plan.
     * If that time has already passed, the reminder fires one minute from [now].
     */
    fun remindMeReminder(
        feast: Feast,
        date: LocalDate,
        minutes: Int,
        now: LocalDateTime,
        zone: ZoneId,
    ): ScheduledReminder {
        var at = TimeOfDay.atDate(date, minutes, zone)
        if (!at.isAfter(now)) {
            at = now.plusMinutes(1)
        }
        return ScheduledReminder(
            id = REMIND_ME_ID_BASE + (abs(feast.id.hashCode()) % 100),
            kind = ReminderKind.Feast,
            triggerEpochMs = at.atZone(zone).toInstant().toEpochMilli(),
            body = ReminderCopy.feastBody(listOf(feast)),
            dayKey = date.toString(),
        )
    }
}
