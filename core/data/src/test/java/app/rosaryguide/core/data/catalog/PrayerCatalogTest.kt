package app.rosaryguide.core.data.catalog

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PrayerCatalogTest {
    @Test
    fun allPrayersDoesNotIncludeAngelOfGod() {
        assertFalse(PrayerCatalog.all.any { it.id == "angel-of-god" || it.title.english == "Angel of God" })
        assertTrue(PrayerCatalog.all.any { it.id == "guardian-angel" && it.title.english == "Guardian Angel Prayer" })
        assertEquals(1, PrayerCatalog.all.count { it.title.english == "Guardian Angel Prayer" })
    }

    @Test
    fun retiredAngelOfGodIdFallsBackToGuardianAngel() {
        val prayer = PrayerCatalog.prayer("angel-of-god")
        assertNotNull(prayer)
        assertEquals("guardian-angel", prayer!!.id)
        assertEquals("Guardian Angel Prayer", prayer.title.english)
        assertEquals("guardian-angel", PrayerCatalog.canonicalId("angel-of-god"))
    }

    @Test
    fun searchAngelOfGodFindsGuardianAngelPrayer() {
        val matches = PrayerCatalog.all.filter { PrayerCatalog.matchesQuery(it, "Angel of God") }
        assertEquals(listOf("guardian-angel"), matches.map { it.id })
        val latin = PrayerCatalog.all.filter { PrayerCatalog.matchesQuery(it, "Angele Dei") }
        assertEquals(listOf("guardian-angel"), latin.map { it.id })
        assertTrue(PrayerCatalog.matchesQuery(PrayerCatalog.prayer("guardian-angel")!!, "guardian"))
    }

    @Test
    fun unknownPrayerIdIsNull() {
        assertEquals(null, PrayerCatalog.prayer("does-not-exist"))
    }
}
