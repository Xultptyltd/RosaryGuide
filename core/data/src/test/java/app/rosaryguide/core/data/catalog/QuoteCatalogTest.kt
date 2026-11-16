package app.rosaryguide.core.data.catalog

import org.junit.Assert.assertEquals
import org.junit.Test

class QuoteCatalogTest {
    @Test
    fun testEveryCompletionQuoteIsShown() {
        assertEquals(14, QuoteCatalog.all.size)
        assertEquals("montfort-treasure", QuoteCatalog.all.first().id)
        assertEquals(QuoteCatalog.all.size, QuoteCatalog.shortQuotes.size)
        assertEquals(QuoteCatalog.maxCompletionCharacters, QuoteCatalog.all.maxOf { it.text.length })
        assertEquals(QuoteCatalog.all.size, QuoteCatalog.all.map { it.id }.toSet().size)
    }

    @Test
    fun testCompletionQuotesCycleThroughAllBeforeRepeating() {
        val defaults = MapQuotePreferences()
        val count = QuoteCatalog.all.size
        val firstRound = (0 until count).map { QuoteCatalog.freshCompletionQuote(defaults).id }
        assertEquals(count, firstRound.toSet().size)
        val secondRound = (0 until count).map { QuoteCatalog.freshCompletionQuote(defaults).id }
        assertEquals(firstRound, secondRound)
    }

    @Test
    fun testSelectingWithoutRememberingDoesNotAdvance() {
        val defaults = MapQuotePreferences()
        val a = QuoteCatalog.selectCompletionQuote(defaults)
        assertEquals(a.id, QuoteCatalog.selectCompletionQuote(defaults).id)
    }

    @Test
    fun testMigratesFromLastShownQuote() {
        val defaults = MapQuotePreferences()
        defaults.setString(QuoteCatalog.LAST_COMPLETION_QUOTE_KEY, QuoteCatalog.all[3].id)
        assertEquals(QuoteCatalog.all[4].id, QuoteCatalog.selectCompletionQuote(defaults).id)
        defaults.setString(QuoteCatalog.LAST_COMPLETION_QUOTE_KEY, "removed-quote")
        assertEquals(QuoteCatalog.all[0].id, QuoteCatalog.selectCompletionQuote(defaults).id)
    }
}
