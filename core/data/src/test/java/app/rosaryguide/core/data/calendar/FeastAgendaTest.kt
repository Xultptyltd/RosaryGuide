package app.rosaryguide.core.data.calendar

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.model.DatedFeast
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class FeastAgendaTest {
    private val firstWeekday = 2 // Monday, matching the iOS test calendar

    private fun day(month: Int, day: Int, year: Int = 2026): LocalDate =
        LocalDate.of(year, month, day)

    private fun feast(date: LocalDate, index: Int = 0): DatedFeast =
        DatedFeast(feast = FeastCatalog.all[index], date = date)

    @Test
    fun agendaPartitionsDatesWithoutRepeatingFocus() {
        val anchor = day(10, 9)
        val dates = listOf(
            anchor, day(10, 10), day(10, 15), day(11, 1), day(12, 1),
            day(1, 31, 2027), day(12, 31, 2027),
        )
        val input = dates.map { feast(it) } + listOf(feast(day(1, 1, 2028)))
        val value = FeastAgenda.of(input, selectedDay = anchor, today = anchor, firstWeekday = firstWeekday)
        assertEquals(
            listOf("Today", "This week", "This month", "Next month", "Later this year", "Next year"),
            value.sections.map { it.title },
        )
        val all = value.sections.flatMap { it.items }
        assertEquals(dates, all.map { it.date })
        assertEquals(all.size, all.map { it.id }.toSet().size)
    }

    @Test
    fun emptyDayShowsAllFeastsOnNextDateOnlyOnce() {
        val anchor = day(10, 9)
        val next = day(10, 10)
        val value = FeastAgenda.of(
            items = listOf(feast(next), feast(next, index = 1), feast(day(10, 15))),
            selectedDay = anchor,
            today = anchor,
            firstWeekday = firstWeekday,
        )
        assertEquals(listOf("Next", "This month"), value.sections.map { it.title })
        assertEquals(2, value.sections[0].items.size)
        assertEquals(3, value.sections.flatMap { it.items }.size)
    }

    @Test
    fun emptyAgendaAndPastDates() {
        val anchor = day(10, 9)
        assertTrue(FeastAgenda.of(emptyList(), selectedDay = anchor, firstWeekday = firstWeekday).sections.isEmpty())
        assertTrue(
            FeastAgenda.of(listOf(feast(day(10, 8))), selectedDay = anchor, firstWeekday = firstWeekday)
                .sections.isEmpty(),
        )
    }

    @Test
    fun selectedFutureDayUsesItsDateAndYearBoundary() {
        val anchor = day(12, 31)
        val value = FeastAgenda.of(
            items = listOf(
                feast(anchor),
                feast(day(1, 1, 2027)),
                feast(day(3, 31, 2027)),
                feast(day(4, 1, 2027)),
            ),
            selectedDay = anchor,
            today = day(10, 9),
            firstWeekday = firstWeekday,
        )
        assertEquals("", value.sections.first().title)
        assertEquals(listOf("", "Next month", "Next year"), value.sections.map { it.title })
        assertEquals(4, value.sections.flatMap { it.items }.size)
    }

    @Test
    fun decemberNextMonthDoesNotRepeatInNextYear() {
        val anchor = day(12, 10)
        val value = FeastAgenda.of(
            items = listOf(feast(day(12, 11)), feast(day(1, 15, 2027)), feast(day(2, 1, 2027))),
            selectedDay = anchor,
            today = anchor,
            firstWeekday = firstWeekday,
        )
        assertEquals(listOf("Next", "Next month", "Next year"), value.sections.map { it.title })
        assertEquals(listOf(day(1, 15, 2027)), value.sections[1].items.map { it.date })
        assertEquals(listOf(day(2, 1, 2027)), value.sections[2].items.map { it.date })
    }

    @Test
    fun noRemainingFeastsThisMonthKeepsNextFeastInNextMonth() {
        val anchor = day(10, 31)
        val dates = listOf(day(11, 1), day(11, 2), day(12, 8))
        val value = FeastAgenda.of(
            items = dates.map { feast(it) },
            selectedDay = anchor,
            today = anchor,
            firstWeekday = firstWeekday,
        )
        assertEquals(listOf("Next month", "Later this year"), value.sections.map { it.title })
        assertEquals(dates.take(2), value.sections[0].items.map { it.date })
        assertEquals(dates, value.sections.flatMap { it.items }.map { it.date })
    }

    @Test
    fun noRemainingDecemberFeastsUsesNextMonthForJanuary() {
        val anchor = day(12, 31)
        val value = FeastAgenda.of(
            items = listOf(feast(day(1, 1, 2027))),
            selectedDay = anchor,
            today = anchor,
            firstWeekday = firstWeekday,
        )
        assertEquals(listOf("Next month"), value.sections.map { it.title })
    }
}

class FeastMonthLayoutTest {
    @Test
    fun monthAlignmentAndLeapDays() {
        data class Case(val year: Int, val month: Int, val count: Int, val leading: Int, val rows: Int)
        val mondayFirst = listOf(
            Case(2024, 2, 29, 3, 5),
            Case(2021, 2, 28, 0, 4),
            Case(2026, 8, 31, 5, 6),
        )
        for (c in mondayFirst) {
            val date = LocalDate.of(c.year, c.month, 1)
            val layout = FeastMonthLayout.of(date, firstWeekday = 2)
            assertEquals(c.count, layout.cells.mapNotNull { it }.size)
            assertEquals(c.leading, layout.cells.takeWhile { it == null }.size)
            assertEquals(c.rows, layout.rows)
            assertEquals(c.count, layout.cells.mapNotNull { it }.last().dayOfMonth)
        }
        val october = LocalDate.of(2026, 10, 1)
        assertEquals(4, FeastMonthLayout.of(october, firstWeekday = 1).cells.takeWhile { it == null }.size)
    }
}
