package app.rosaryguide.core.data.calendar

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.LiturgicalSeason
import app.rosaryguide.core.model.MysteryAssignment
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.SeasonalSundaySuggestion
import java.time.LocalDate

object MysteryCalendar {
    fun assignment(date: LocalDate): MysteryAssignment {
        val season = LiturgicalCalendar.season(date)
        val weekday = LiturgicalCalendar.weekday(date)
        val feast = FeastCatalog.feasts(date)
            .sortedByDescending { it.feast.rank.precedence }
            .firstOrNull()
        val set = when (weekday) {
            1 -> MysterySetKind.Glorious // Sundays always take the Glorious Mysteries
            2 -> MysterySetKind.Joyful
            3 -> MysterySetKind.Sorrowful
            4 -> MysterySetKind.Glorious
            5 -> MysterySetKind.Luminous
            6 -> MysterySetKind.Sorrowful
            else -> MysterySetKind.Joyful
        }
        return MysteryAssignment(
            set = set,
            reason = set.themeSummary,
            season = season,
            feast = feast,
            seasonalSunday = seasonalSunday(date, season),
        )
    }

    /**
     * Week strip starting on [firstWeekday] (Sunday = 1 … Saturday = 7).
     * Monday-start weeks use 2, matching a typical Australian first weekday.
     */
    fun week(
        date: LocalDate,
        firstWeekday: Int = 1,
    ): List<Pair<LocalDate, MysteryAssignment>> {
        val weekday = LiturgicalCalendar.weekday(date)
        val startOffset = -((weekday - firstWeekday + 7) % 7)
        val start = date.plusDays(startOffset.toLong())
        return (0 until 7).map { offset ->
            val day = start.plusDays(offset.toLong())
            day to assignment(day)
        }
    }

    fun seasonalSunday(date: LocalDate, season: LiturgicalSeason): SeasonalSundaySuggestion? {
        if (LiturgicalCalendar.weekday(date) != 1) return null
        return when (season) {
            LiturgicalSeason.Advent -> SeasonalSundaySuggestion(MysterySetKind.Joyful, "on Sundays of Advent")
            LiturgicalSeason.Lent -> SeasonalSundaySuggestion(MysterySetKind.Sorrowful, "on Sundays of Lent")
            else -> null
        }
    }
}
