package app.rosaryguide.core.data.calendar

import java.time.DayOfWeek
import java.time.LocalDate

/**
 * Gregorian liturgical date helpers, ported from iOS `LiturgicalCalendar`.
 * [LocalDate] is ISO-8601/Gregorian, so the civil year is always the Gregorian year
 * (the iOS type has a dedicated `year(of:)` to ignore Buddhist or Japanese calendars).
 */
object LiturgicalCalendar {

    fun date(year: Int, month: Int, day: Int): LocalDate = LocalDate.of(year, month, day)

    fun yearOf(date: LocalDate): Int = date.year

    fun addingDays(days: Int, to: LocalDate): LocalDate = to.plusDays(days.toLong())

    /** Sunday = 1 … Saturday = 7, matching Foundation Calendar weekday. */
    fun weekday(date: LocalDate): Int =
        if (date.dayOfWeek == DayOfWeek.SUNDAY) 1 else date.dayOfWeek.value + 1

    /** Gregorian Computus (Anonymous algorithm). */
    fun easter(year: Int): LocalDate {
        val a = year % 19
        val b = year / 100
        val c = year % 100
        val d = b / 4
        val e = b % 4
        val f = (b + 8) / 25
        val g = (b - f + 1) / 3
        val h = (19 * a + b - d - g + 15) % 30
        val i = c / 4
        val k = c % 4
        val l = (32 + 2 * e + 2 * i - h - k) % 7
        val m = (a + 11 * h + 22 * l) / 451
        val month = (h + l - 7 * m + 114) / 31
        val day = ((h + l - 7 * m + 114) % 31) + 1
        return date(year, month, day)
    }

    /** First Sunday of Advent: Sunday between 27 November and 3 December. */
    fun firstSundayOfAdvent(year: Int): LocalDate {
        val november27 = date(year, 11, 27)
        val daysUntilSunday = (8 - weekday(november27)) % 7
        return addingDays(daysUntilSunday, november27)
    }

    /** US Epiphany observance: Sunday on or after 2 January (transferred from 6 January). */
    fun epiphany(year: Int): LocalDate = sundayOnOrAfter(date(year, 1, 2))

    /**
     * Baptism of the Lord — US particular calendar, derived from the same Epiphany date the app uses.
     * Normally the Sunday after Epiphany. When Epiphany falls on 7 or 8 January,
     * Baptism is the following Monday so it never precedes Epiphany.
     */
    fun baptismOfTheLord(year: Int): LocalDate {
        val epiphanyDate = epiphany(year)
        val day = epiphanyDate.dayOfMonth
        return if (day == 7 || day == 8) addingDays(1, epiphanyDate) else addingDays(7, epiphanyDate)
    }

    /** Sacred Heart: Friday after the second Sunday after Pentecost (Easter + 68). */
    fun sacredHeart(year: Int): LocalDate = addingDays(68, easter(year))

    /**
     * Holy Family: Sunday within the Octave of Christmas (26–31 December), or 30 December
     * when Christmas is a Sunday and the octave has no Sunday.
     */
    fun holyFamily(year: Int): LocalDate {
        val sunday = sundayOnOrAfter(date(year, 12, 26))
        return if (sunday.monthValue == 12 && sunday.dayOfMonth <= 31) sunday
        else date(year, 12, 30)
    }

    fun ashWednesday(year: Int): LocalDate = addingDays(-46, easter(year))

    fun pentecost(year: Int): LocalDate = addingDays(49, easter(year))

    fun holyThursday(year: Int): LocalDate = addingDays(-3, easter(year))

    fun season(date: LocalDate): app.rosaryguide.core.model.LiturgicalSeason {
        val year = date.year
        val advent = firstSundayOfAdvent(year)
        val christmas = date(year, 12, 25)
        val baptism = baptismOfTheLord(year)
        val ash = ashWednesday(year)
        val easterSunday = easter(year)
        val holyThu = holyThursday(year)
        val pentecostSunday = pentecost(year)

        if (date >= advent) {
            return if (date < christmas) app.rosaryguide.core.model.LiturgicalSeason.Advent
            else app.rosaryguide.core.model.LiturgicalSeason.Christmas
        }
        if (date <= baptism) return app.rosaryguide.core.model.LiturgicalSeason.Christmas
        if (date >= holyThu && date < easterSunday) return app.rosaryguide.core.model.LiturgicalSeason.Triduum
        if (date >= ash && date < easterSunday) return app.rosaryguide.core.model.LiturgicalSeason.Lent
        if (date >= easterSunday && date <= pentecostSunday) return app.rosaryguide.core.model.LiturgicalSeason.Easter
        return app.rosaryguide.core.model.LiturgicalSeason.Ordinary
    }

    /** US-style: solemnity observed on the Sunday on or after [date] (if not already Sunday). */
    fun sundayOnOrAfter(date: LocalDate): LocalDate {
        val weekday = weekday(date)
        return if (weekday == 1) date else addingDays(8 - weekday, date)
    }

    /** Monday after Divine Mercy Sunday (octave of Easter). */
    fun mondayAfterDivineMercy(year: Int): LocalDate = addingDays(8, easter(year))

    /**
     * 25 March, or the next day when that is a Sunday of Lent. Holy Week and the Easter
     * Octave outrank the solemnity, so it then waits until the Monday after Divine Mercy Sunday.
     */
    fun annunciation(year: Int): LocalDate {
        val mar25 = date(year, 3, 25)
        if (isInHolyWeekOrEasterOctave(mar25, year)) return mondayAfterDivineMercy(year)
        if (weekday(mar25) == 1) return addingDays(1, mar25)
        return mar25
    }

    /**
     * 19 March. A Sunday of Lent keeps it the next day. Holy Week keeps it on the Saturday
     * before Palm Sunday (the Monday would still be inside Holy Week).
     */
    fun saintJoseph(year: Int): LocalDate {
        val mar19 = date(year, 3, 19)
        if (isInHolyWeekOrEasterOctave(mar19, year)) {
            val palm = addingDays(-7, easter(year))
            return addingDays(-1, palm)
        }
        if (weekday(mar19) == 1) return addingDays(1, mar19)
        return mar19
    }

    /** 8 December. An Advent Sunday outranks the solemnity, so it is kept the next day. */
    fun immaculateConception(year: Int): LocalDate {
        val dec8 = date(year, 12, 8)
        return if (weekday(dec8) == 1) addingDays(1, dec8) else dec8
    }

    fun isInHolyWeekOrEasterOctave(date: LocalDate, year: Int): Boolean {
        val easterSunday = easter(year)
        val palm = addingDays(-7, easterSunday)
        val octaveEnd = addingDays(7, easterSunday)
        return date >= palm && date <= octaveEnd
    }
}
