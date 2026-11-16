package app.rosaryguide.core.data.calendar

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Locale

class WeekStartTest {
    @Test
    fun localeFirstWeekdayMatchesFoundationConvention() {
        assertEquals(1, WeekStart.firstWeekday(Locale.US))
        assertEquals(2, WeekStart.firstWeekday(Locale("en", "AU")))
        assertEquals(2, WeekStart.firstWeekday(Locale.forLanguageTag("en-AU")))
        assertEquals(2, WeekStart.firstWeekday(Locale.GERMANY))
        assertEquals(2, WeekStart.firstWeekday(Locale.UK))
        assertEquals(1, WeekStart.firstWeekday(Locale.CANADA))
    }
}
