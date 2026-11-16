package app.rosaryguide.core.data.calendar

import app.rosaryguide.core.model.DatedFeast
import java.time.LocalDate

/**
 * Disjoint agenda groups relative to the selected day, including year boundaries.
 * Ported from iOS `FeastAgenda`. [firstWeekday] uses the Foundation convention:
 * Sunday = 1 … Saturday = 7.
 */
data class FeastAgenda(
    val sections: List<Section>,
) {
    data class Section(
        val title: String,
        val items: List<DatedFeast>,
    )

    companion object {
        private val bucketTitles = listOf(
            "This week", "This month", "Next month", "Later this year", "Next year",
        )

        fun of(
            items: List<DatedFeast>,
            selectedDay: LocalDate,
            today: LocalDate = selectedDay,
            firstWeekday: Int = 2,
        ): FeastAgenda {
            val start = selectedDay
            val weekEnd = startOfWeek(start, firstWeekday).plusDays(7)
            val monthEnd = start.withDayOfMonth(1).plusMonths(1)
            val nextMonthEnd = monthEnd.plusMonths(1)
            val yearEnd = LocalDate.of(start.year + 1, 1, 1)
            val horizon = yearEnd.plusYears(1)
            val upcoming = items
                .filter { !it.date.isBefore(start) && it.date.isBefore(horizon) }
                .sortedWith(compareBy<DatedFeast> { it.date }.thenBy { it.id })
            val selected = upcoming.filter { it.date == start }
            val focus: List<DatedFeast> = if (selected.isNotEmpty()) {
                selected
            } else {
                val next = upcoming.firstOrNull()
                if (next != null && next.date.isBefore(monthEnd)) {
                    upcoming.filter { it.date == next.date }
                } else {
                    emptyList()
                }
            }
            val result = mutableListOf<Section>()
            if (focus.isNotEmpty()) {
                val title = when {
                    selected.isEmpty() -> "Next"
                    start == today -> "Today"
                    else -> ""
                }
                result += Section(title, focus)
            }
            val focusedIds = focus.map { it.id }.toSet()
            val remaining = upcoming.filter { it.id !in focusedIds }
            val buckets = List(bucketTitles.size) { mutableListOf<DatedFeast>() }
            for (item in remaining) {
                val index = when {
                    item.date.isBefore(weekEnd) && item.date.isBefore(monthEnd) -> 0
                    item.date.isBefore(monthEnd) -> 1
                    item.date.isBefore(nextMonthEnd) -> 2
                    item.date.isBefore(yearEnd) -> 3
                    else -> 4
                }
                buckets[index] += item
            }
            for (i in bucketTitles.indices) {
                if (buckets[i].isNotEmpty()) {
                    result += Section(bucketTitles[i], buckets[i])
                }
            }
            return FeastAgenda(result)
        }

        fun startOfWeek(date: LocalDate, firstWeekday: Int): LocalDate {
            val weekday = LiturgicalCalendar.weekday(date)
            val startOffset = -((weekday - firstWeekday + 7) % 7)
            return date.plusDays(startOffset.toLong())
        }
    }
}

/**
 * Month cells aligned to [firstWeekday], without dates from adjacent months.
 * Sunday = 1 … Saturday = 7.
 */
data class FeastMonthLayout(
    val cells: List<LocalDate?>,
) {
    val rows: Int get() = if (cells.isEmpty()) 0 else cells.size / 7

    companion object {
        fun of(month: LocalDate, firstWeekday: Int = 2): FeastMonthLayout {
            val start = month.withDayOfMonth(1)
            val count = start.lengthOfMonth()
            val leading = (LiturgicalCalendar.weekday(start) - firstWeekday + 7) % 7
            val days = MutableList<LocalDate?>(leading) { null }
            days += (0 until count).map { start.plusDays(it.toLong()) }
            val trailing = (7 - days.size % 7) % 7
            repeat(trailing) { days += null }
            return FeastMonthLayout(days)
        }
    }
}
