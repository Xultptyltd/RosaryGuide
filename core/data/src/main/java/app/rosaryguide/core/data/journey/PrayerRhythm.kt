package app.rosaryguide.core.data.journey

import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.WeekFields
import java.util.Locale

/**
 * Streak, caption and month summary derived from the prayed-day history.
 * Ported from iOS `PrayerRhythm` in Theme/PrayerRhythmCard.swift.
 *
 * [firstWeekday] is iOS Calendar style: Sunday = 1 … Saturday = 7.
 */
data class PrayerRhythm(
    val dailyRun: Int,
    val weekRun: Int,
    val prayedToday: Boolean,
    val prayedDaysThisWeek: Int,
    val hasEverPrayed: Boolean,
    val isWelcomeBack: Boolean,
    val bigNumber: Int,
    val unit: Unit,
    val caption: String,
    val isMilestone: Boolean,
    val monthName: String,
    val prayedDaysThisMonth: Int,
    val weeks: List<List<Day?>>,
    val currentWeek: List<Day>,
    val weekdayLabels: List<String>,
) {
    enum class Unit { Day, Week }

    data class Day(
        val number: Int,
        val prayed: Boolean,
        val isToday: Boolean,
        val isFuture: Boolean,
    )

    val hasPrayed: Boolean get() = dailyRun > 0 || weekRun > 0 || prayedDaysThisMonth > 0

    val streakText: String
        get() = if (bigNumber == 1) "1 ${unitWord}" else "$bigNumber ${unitWord}s"

    private val unitWord: String get() = if (unit == Unit.Day) "day" else "week"

    data class CardCopy(val big: String, val caption: String)

    val card: CardCopy
        get() = when {
            !hasEverPrayed || (weekRun == 0 && dailyRun < 3) ->
                CardCopy("0 days", "Start this week")
            isMilestone -> CardCopy(streakText, caption)
            isWelcomeBack -> CardCopy(dayCount(prayedDaysThisWeek), "Welcome back")
            dailyRun >= 3 -> CardCopy(streakText, "In a row")
            weekRun == 1 && prayedDaysThisWeek > 0 ->
                CardCopy(dayCount(prayedDaysThisWeek), "This week")
            else -> CardCopy(streakText, "In a row")
        }

    val accessibilityLabel: String
        get() {
            val days = if (prayedDaysThisMonth == 1) "1 day" else "$prayedDaysThisMonth days"
            return "Your prayer, ${card.big}. ${card.caption}. Prayed $days in $monthName."
        }

    val weeklySummary: String
        get() {
            val days = prayedDaysThisWeek
            if (days == 0) return "Find room for prayer"
            return if (days == 1) "1 day this week" else "$days days this week"
        }

    companion object {
        fun from(
            prayedDayStarts: Set<Long>,
            now: Instant,
            zone: ZoneId,
            firstWeekday: Int = 2,
            locale: Locale = Locale.UK,
        ): PrayerRhythm {
            val calendarToday = now.atZone(zone).toLocalDate()
            val prayedDays: Set<LocalDate> = prayedDayStarts.mapNotNull { start ->
                val day = Instant.ofEpochSecond(start).atZone(zone).toLocalDate()
                if (!day.isAfter(calendarToday)) day else null
            }.toSet()

            fun prayed(day: LocalDate) = day in prayedDays
            fun weekStart(date: LocalDate): LocalDate {
                val first = dayOfWeekFromIos(firstWeekday)
                var cursor = date
                while (cursor.dayOfWeek != first) {
                    cursor = cursor.minusDays(1)
                }
                return cursor
            }

            val hasEverPrayed = prayedDays.isNotEmpty()
            val prayedToday = prayed(calendarToday)
            var cursor = if (prayedToday) calendarToday else calendarToday.minusDays(1)
            var days = 0
            while (prayed(cursor) && days < 400) {
                days += 1
                cursor = cursor.minusDays(1)
            }
            val dailyRun = days
            val dailyRunStart = cursor.plusDays(1)

            val prayedWeeks = prayedDays.map { weekStart(it) }.toSet()
            val thisWeek = weekStart(calendarToday)
            val prayedDaysThisWeek = prayedDays.count { !it.isBefore(thisWeek) && !it.isAfter(calendarToday) }
            val currentWeek = (0 until 7).map { offset ->
                val date = thisWeek.plusDays(offset.toLong())
                Day(
                    number = date.dayOfMonth,
                    prayed = prayed(date),
                    isToday = date == calendarToday,
                    isFuture = date.isAfter(calendarToday),
                )
            }
            val symbols = (1..7).map { dayOfWeekFromIos(it).getDisplayName(TextStyle.SHORT, locale) }
            val weekdayLabels = (0 until 7).map { symbols[(firstWeekday - 1 + it) % 7] }
            val prayedThisWeek = prayedDaysThisWeek > 0
            var weekCursor = if (prayedThisWeek) thisWeek else thisWeek.minusWeeks(1)
            var weeksCount = 0
            while (weekCursor in prayedWeeks && weeksCount < 60) {
                weeksCount += 1
                weekCursor = weekCursor.minusWeeks(1)
            }
            val weekRun = weeksCount
            val weekRunStartWeek = weekCursor.plusWeeks(1)
            val weekRunFirstDay = prayedDays.filter { !it.isBefore(weekRunStartWeek) }.minOrNull()
                ?: calendarToday

            val hasPrayerBeforeThisWeek = prayedDays.any { it.isBefore(thisWeek) }
            val isWelcomeBack = prayedThisWeek && weekRun == 1 && hasPrayerBeforeThisWeek

            val monthFormatter = DateTimeFormatter.ofPattern("LLLL", locale)
            val dayMonthFormatter = DateTimeFormatter.ofPattern("d MMM", locale)
            val monthName = calendarToday.format(monthFormatter)

            val result = rule(
                hasEverPrayed = hasEverPrayed,
                dailyRun = dailyRun,
                prayedToday = prayedToday,
                weekRun = weekRun,
                prayedThisWeek = prayedThisWeek,
                prayedDaysThisWeek = prayedDaysThisWeek,
                isWelcomeBack = isWelcomeBack,
                dailyRunStartDay = dailyRunStart.format(dayMonthFormatter),
                dailyRunStartMonth = dailyRunStart.format(monthFormatter),
                weekRunStartMonth = weekRunFirstDay.format(monthFormatter),
            )

            val cells = mutableListOf<Day?>()
            var monthCount = 0
            val monthStart = calendarToday.withDayOfMonth(1)
            val leading = ((monthStart.dayOfWeek.value - dayOfWeekFromIos(firstWeekday).value) + 7) % 7
            repeat(leading) { cells.add(null) }
            val daysInMonth = calendarToday.lengthOfMonth()
            for (offset in 0 until daysInMonth) {
                val date = monthStart.plusDays(offset.toLong())
                val isPrayed = prayed(date)
                if (isPrayed) monthCount += 1
                cells.add(
                    Day(
                        number = offset + 1,
                        prayed = isPrayed,
                        isToday = date == calendarToday,
                        isFuture = date.isAfter(calendarToday),
                    ),
                )
            }
            val trailing = (7 - cells.size % 7) % 7
            repeat(trailing) { cells.add(null) }
            val weeks = cells.chunked(7)

            return PrayerRhythm(
                dailyRun = dailyRun,
                weekRun = weekRun,
                prayedToday = prayedToday,
                prayedDaysThisWeek = prayedDaysThisWeek,
                hasEverPrayed = hasEverPrayed,
                isWelcomeBack = isWelcomeBack,
                bigNumber = result.number,
                unit = result.unit,
                caption = result.caption,
                isMilestone = result.isMilestone,
                monthName = monthName,
                prayedDaysThisMonth = monthCount,
                weeks = weeks,
                currentWeek = currentWeek,
                weekdayLabels = weekdayLabels,
            )
        }

        data class RuleResult(
            val number: Int,
            val unit: Unit,
            val caption: String,
            val isMilestone: Boolean,
        )

        fun rule(
            hasEverPrayed: Boolean,
            dailyRun: Int,
            prayedToday: Boolean,
            weekRun: Int,
            prayedThisWeek: Boolean,
            prayedDaysThisWeek: Int,
            isWelcomeBack: Boolean,
            dailyRunStartDay: String,
            dailyRunStartMonth: String,
            weekRunStartMonth: String,
        ): RuleResult {
            if (!hasEverPrayed) {
                return RuleResult(0, Unit.Day, "Start your rhythm this week", false)
            }
            if (dailyRun >= 3) {
                val milestone = if (prayedToday) when (dailyRun) {
                    3 -> "Three days in a row"
                    5 -> "Finding your rhythm"
                    7 -> "Every day this week"
                    10 -> "Every day since $dailyRunStartDay"
                    14 -> "A fortnight of prayer"
                    30, 60, 100 -> "Every day since $dailyRunStartMonth"
                    40 -> "Forty days, like Lent"
                    54 -> "A full novena"
                    90 -> "A whole season"
                    else -> null
                } else null
                if (milestone != null) {
                    return RuleResult(dailyRun, Unit.Day, milestone, true)
                }
                return RuleResult(
                    dailyRun,
                    Unit.Day,
                    if (prayedToday) "See you tomorrow" else "Pray today to keep it",
                    false,
                )
            }
            if (weekRun <= 0) {
                return RuleResult(0, Unit.Week, "Start your rhythm this week", false)
            }
            if (isWelcomeBack) {
                return RuleResult(1, Unit.Week, "Welcome back", false)
            }
            if (weekRun == 1 && prayedThisWeek) {
                when (prayedDaysThisWeek) {
                    1 -> return RuleResult(1, Unit.Day, "Once this week", false)
                    2 -> return RuleResult(1, Unit.Week, "Twice this week", false)
                    3 -> return RuleResult(1, Unit.Week, "Three days this week", false)
                    4 -> return RuleResult(1, Unit.Week, "Four days this week", false)
                    5 -> return RuleResult(1, Unit.Week, "Five days this week", false)
                    6 -> return RuleResult(1, Unit.Week, "Six days this week", false)
                }
            }
            if (prayedThisWeek) {
                val milestone = when (weekRun) {
                    2 -> "Two weeks running"
                    3 -> "Becoming a habit"
                    4 -> "A month of weeks"
                    8 -> "Every week since $weekRunStartMonth"
                    12 -> "Three months steady"
                    26 -> "Half a year faithful"
                    52 -> "A year of prayer"
                    else -> null
                }
                if (milestone != null) {
                    return RuleResult(weekRun, Unit.Week, milestone, true)
                }
            }
            return RuleResult(
                weekRun,
                Unit.Week,
                if (prayedThisWeek) "See you next week" else "Pray this week to keep it",
                false,
            )
        }

        private fun dayCount(n: Int): String = if (n == 1) "1 day" else "$n days"

        /** iOS Calendar weekday: Sunday = 1 … Saturday = 7. */
        fun dayOfWeekFromIos(firstWeekday: Int): DayOfWeek = when (((firstWeekday - 1) % 7 + 7) % 7) {
            0 -> DayOfWeek.SUNDAY
            1 -> DayOfWeek.MONDAY
            2 -> DayOfWeek.TUESDAY
            3 -> DayOfWeek.WEDNESDAY
            4 -> DayOfWeek.THURSDAY
            5 -> DayOfWeek.FRIDAY
            else -> DayOfWeek.SATURDAY
        }

        fun weekFields(firstWeekday: Int): WeekFields =
            WeekFields.of(dayOfWeekFromIos(firstWeekday), 1)
    }
}
