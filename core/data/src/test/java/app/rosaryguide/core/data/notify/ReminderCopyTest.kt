package app.rosaryguide.core.data.notify

import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.Feast
import app.rosaryguide.core.model.FeastRank
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ReminderCopyTest {

    private fun feast(name: String, rank: FeastRank): Feast = Feast(
        id = name,
        name = BilingualText(name, name),
        summary = "",
        suggestedMysterySet = null,
        isMarian = false,
        rank = rank,
        dateOn = { null },
    )

    @Test
    fun testSundayCopyNamesGlorious() {
        val adventSunday = LocalDate.of(2026, 11, 29)
        assertTrue(ReminderCopy.dailyBody(weekday = 1, day = adventSunday).contains("Glorious"))
        val monday = LocalDate.of(2026, 10, 19)
        assertTrue(ReminderCopy.dailyBody(weekday = 2, day = monday).contains("Joyful"))
    }

    @Test
    fun testDailyCopyIsOneSentenceNamingTheSet() {
        val sunday = LocalDate.of(2026, 11, 1)
        assertEquals(
            "Time to pray the Glorious Mysteries. Take a few quiet minutes for the Rosary.",
            ReminderCopy.dailyBody(weekday = 1, day = sunday),
        )
    }

    @Test
    fun testFeastCopyUsesRankAndReadsNaturally() {
        assertEquals("Today is the solemnity of All Saints", ReminderCopy.feastBody(listOf(feast("All Saints", FeastRank.Solemnity))))
        assertEquals("Today is the memorial of Saint Charles Borromeo", ReminderCopy.feastBody(listOf(feast("Saint Charles Borromeo", FeastRank.Memorial))))
        assertEquals(
            "Today is the solemnity of the Assumption of the Blessed Virgin Mary",
            ReminderCopy.feastBody(listOf(feast("The Assumption of the Blessed Virgin Mary", FeastRank.Solemnity))),
        )
        assertEquals("Today is the memorial of Our Lady of Lourdes", ReminderCopy.feastBody(listOf(feast("Our Lady of Lourdes", FeastRank.OptionalMemorial))))
        assertEquals("Today is the feast of the Presentation of the Lord", ReminderCopy.feastBody(listOf(feast("Presentation of the Lord", FeastRank.Feast))))
    }

    @Test
    fun testEveryCatalogFeastReadsAsASentence() {
        for (feast in FeastCatalog.all) {
            val body = ReminderCopy.feastBody(listOf(feast))
            assertTrue(body, body.startsWith("Today is "))
            assertFalse(body, body.contains(" The "))
            assertFalse(body, body.contains("the the "))
        }
    }

    @Test
    fun testSeasonalDaysAndSharedDays() {
        assertEquals("Today is Ash Wednesday", ReminderCopy.feastBody(listOf(feast("Ash Wednesday", FeastRank.Seasonal))))
        assertEquals(
            "Today is the First Sunday of Advent",
            ReminderCopy.feastBody(listOf(feast("First Sunday of Advent", FeastRank.Seasonal))),
        )
        assertEquals(
            "Today is the Commemoration of All the Faithful Departed",
            ReminderCopy.feastBody(listOf(feast("The Commemoration of All the Faithful Departed", FeastRank.Seasonal))),
        )
        assertEquals(
            "Today is the memorial of Our Lady of the Rosary and the solemnity of Saints Peter and Paul",
            ReminderCopy.feastBody(
                listOf(feast("Our Lady of the Rosary", FeastRank.Memorial), feast("Saints Peter and Paul", FeastRank.Solemnity)),
            ),
        )
    }
}
