package app.rosaryguide.core.data.calendar

import java.util.Calendar
import java.util.Locale

/**
 * First weekday, ported from iOS `Calendar.current.firstWeekday`
 * (Sunday = 1 … Saturday = 7). Follows the device locale. A few
 * regions (notably Australia and New Zealand) still report Sunday in
 * some JRE locale tables; Foundation starts those weeks on Monday, so
 * we match iOS there.
 */
object WeekStart {
    private val mondayStartCountries = setOf("AU", "NZ")

    fun firstWeekday(locale: Locale = Locale.getDefault()): Int {
        if (locale.country.uppercase(Locale.ROOT) in mondayStartCountries) {
            return Calendar.MONDAY
        }
        return Calendar.getInstance(locale).firstDayOfWeek
    }
}
