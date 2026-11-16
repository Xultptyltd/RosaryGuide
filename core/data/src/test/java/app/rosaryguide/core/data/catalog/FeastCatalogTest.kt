package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.data.calendar.LiturgicalCalendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.ChronoUnit

class FeastCatalogTest {

    private fun monthDay(date: LocalDate): Pair<Int, Int> = date.monthValue to date.dayOfMonth

    private fun motherOfTheChurch(year: Int): LocalDate =
        FeastCatalog.all.first { it.id == "mother-of-the-church" }.dateOn(year)!!

    @Test
    fun testFeastLookupUsesTheGregorianYear() {
        // Android always uses ISO/Gregorian LocalDate, so the civil year is the
        // Gregorian year (the iOS test guards against Calendar.current being Buddhist).
        val christmas = LocalDate.of(2026, 12, 25)
        val onChristmas = FeastCatalog.feasts( christmas)
        assertTrue(onChristmas.any { it.feast.id == "christmas" })
        val upcoming = FeastCatalog.upcoming(date = christmas, limit = 4)
        assertEquals("christmas", upcoming.first().feast.id)
    }

    @Test
    fun testMotherOfTheChurchIsMondayAfterPentecost() {
        assertEquals(5 to 25, monthDay(motherOfTheChurch(2026)))
        assertEquals(5 to 17, monthDay(motherOfTheChurch(2027)))
        assertEquals(6 to 5, monthDay(motherOfTheChurch(2028)))
        for (year in 2026..2036) {
            val easter = LiturgicalCalendar.easter(year)
            val mother = motherOfTheChurch(year)
            assertEquals("Mother of the Church should be Easter+50 in $year", 50, ChronoUnit.DAYS.between(easter, mother))
            assertEquals("Should be Monday in $year", DayOfWeek.MONDAY, mother.dayOfWeek)
        }
    }

    @Test
    fun testSearchAliasesBelongToExistingFeasts() {
        val ids = FeastCatalog.all.map { it.id }.toSet()
        assertTrue(FeastCatalog.searchAliases.isNotEmpty())
        for (id in FeastCatalog.searchAliases.keys) {
            assertTrue(id, id in ids)
        }
    }

    @Test
    fun testFamiliarNamesResolveToExistingFeasts() {
        val cases = listOf(
            "Candlemas" to "presentation",
            "Theotokos" to "mary-mother-of-god",
            "Holy Thursday" to "holy-thursday",
            "Good Friday" to "good-friday",
            "Corpus Christi" to "corpus-christi",
            "Divine Mercy Sunday" to "divine-mercy",
            "Divine Mercy" to "divine-mercy",
            "Christ the King" to "christ-the-king",
            "All Souls Day" to "all-souls",
            "Mother of the Church" to "mother-of-the-church",
            "Our Lady of Guadalupe" to "guadalupe",
            "Assumptio" to "assumption",
        )
        for ((query, id) in cases) {
            val hits = FeastCatalog.all.filter { FeastCatalog.matchesSearch(it, query) }
            assertEquals(query, listOf(id), hits.map { it.id })
        }
        assertFalse(FeastCatalog.matchesSearch(FeastCatalog.all[0], "   "))
        assertTrue(FeastCatalog.searchResults(query = "  ", date = LocalDate.of(2026, 6, 1)).isEmpty())
    }

    @Test
    fun testEveryFeastIsSearchableByNameAndOpensOnItsNextDate() {
        val from = LocalDate.of(2026, 1, 1)
        val ids = FeastCatalog.all.map { it.id }.toSet()
        for (feast in FeastCatalog.all) {
            assertTrue(feast.id, FeastCatalog.matchesSearch(feast, feast.name.english))
            assertTrue(feast.id, FeastCatalog.matchesSearch(feast, feast.shortTitle))
            assertTrue(feast.id, feast.name.latin.isNotEmpty())
            val hits = FeastCatalog.searchResults(query = feast.name.english, date = from)
            assertEquals(feast.id, hits.map { it.feast.id }.toSet().size, hits.size)
            val match = hits.firstOrNull { it.feast.id == feast.id }
            assertNotNull(feast.id, match)
            assertTrue(feast.id, match!!.feast.id in ids)
            assertFalse(feast.id, match.date.isBefore(from))
        }
    }

    @Test
    fun testAssumptionSearchUsesTheNextCelebration() {
        val before = FeastCatalog.searchResults(query = "Assumption", date = LocalDate.of(2026, 6, 1))
        assertEquals(listOf("assumption"), before.map { it.feast.id })
        assertEquals(8 to 15, monthDay(before.first().date))
        assertEquals(2026, before.first().date.year)

        val after = FeastCatalog.searchResults(query = "Assumption", date = LocalDate.of(2026, 8, 16))
        assertEquals(listOf("assumption"), after.map { it.feast.id })
        assertEquals(8 to 15, monthDay(after.first().date))
        assertEquals(2027, after.first().date.year)
    }

    @Test
    fun testMotherOfTheChurchSearchKeepsSharedAssumptionArt() {
        val hits = FeastCatalog.searchResults(query = "Mother of the Church", date = LocalDate.of(2026, 1, 1))
        val feast = hits.first().feast
        assertEquals("mother-of-the-church", feast.id)
        val mother = ArtCatalog.feastHeroName(feast.id)
        val assumption = ArtCatalog.feastHeroName("assumption")
        assertEquals("feast_assumption", mother)
        assertEquals(assumption, mother)
    }

    @Test
    fun testEveryFeastHasTagline() {
        for (feast in FeastCatalog.all) {
            val line = feast.tagline
            assertTrue(feast.id, line.isNotEmpty())
            assertFalse(feast.id, line.endsWith("."))
            assertTrue(feast.id, line.split(" ").size <= 6)
        }
    }
}
