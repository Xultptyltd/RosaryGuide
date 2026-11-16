package app.rosaryguide.core.data.session

import app.rosaryguide.core.model.CountWords
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerLanguage
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class OfferedIntentionsTest {
    @Test
    fun testOfferedIntentionsSummary() {
        assertNull(OfferedIntentions.summary(emptyList()))
        assertEquals("A", OfferedIntentions.summary(listOf("A")))
        assertEquals("A and B", OfferedIntentions.summary(listOf("A", "B")))
        assertEquals("A, B and C", OfferedIntentions.summary(listOf("A", "B", "C")))
    }

    @Test
    fun testOfferedIntentionsCountText() {
        assertNull(OfferedIntentions.countText(emptyList()))
        assertEquals("1 intention", OfferedIntentions.countText(listOf("A")))
        assertEquals("2 intentions", OfferedIntentions.countText(listOf("A", "B")))
        assertEquals("3 intentions", OfferedIntentions.countText(listOf("A", "B", "C")))
    }

    @Test
    fun testRosaryCaptionSpellsCountAtSentenceStart() {
        assertEquals("One Rosary offered this week", CountWords.rosariesOfferedThisWeek(1))
        assertEquals("Two Rosaries offered this week", CountWords.rosariesOfferedThisWeek(2))
        assertEquals("Seven Rosaries offered this week", CountWords.rosariesOfferedThisWeek(7))
        assertEquals("Zero Rosaries offered this week", CountWords.rosariesOfferedThisWeek(0))
        assertEquals("Twenty Rosaries offered this week", CountWords.rosariesOfferedThisWeek(20))
        assertEquals("21 Rosaries offered this week", CountWords.rosariesOfferedThisWeek(21))
    }
}

class PrayerSessionTest {
    private val perth = ZoneId.of("Australia/Perth")
    private fun at(month: Int, day: Int, hour: Int, minute: Int = 0): Long =
        LocalDateTime.of(2026, month, day, hour, minute).atZone(perth).toInstant().toEpochMilli()

    @Test
    fun testIntentionsAreCappedAtFive() {
        val session = PrayerSession.create(
            mysterySet = MysterySetKind.Glorious,
            stepIndex = 0,
            startedAtEpochMs = 1L,
            updatedAtEpochMs = 1L,
            includeSaintMichael = false,
            language = PrayerLanguage.English,
            intentionIds = (0 until 6).map { UUID.randomUUID().toString() },
        )
        assertEquals(5, session.intentionIds.size)
    }

    @Test
    fun testLegacySingleIntentionSessionMigratesToArrays() {
        val id = UUID.randomUUID().toString()
        val legacy = PrayerSession.create(
            mysterySet = MysterySetKind.Joyful,
            stepIndex = 3,
            startedAtEpochMs = 1L,
            updatedAtEpochMs = 1L,
            intentionId = id,
            intentionTitle = "Family",
        )
        val obj = Json.parseToJsonElement(legacy.toJson()).jsonObject.toMutableMap()
        obj.remove("intentionIds")
        obj.remove("intentionTitles")
        val decoded = decodePrayerSession(Json.encodeToString(kotlinx.serialization.json.JsonObject.serializer(), kotlinx.serialization.json.JsonObject(obj)))
        assertEquals(listOf(id), decoded.intentionIds)
        assertEquals(listOf("Family"), decoded.intentionTitles)
    }

    @Test
    fun testMultipleIntentionsRoundTripAndKeepLegacyKeys() {
        val ids = listOf(UUID.randomUUID().toString(), UUID.randomUUID().toString(), UUID.randomUUID().toString())
        val session = PrayerSession.create(
            mysterySet = MysterySetKind.Sorrowful,
            stepIndex = 1,
            startedAtEpochMs = 1L,
            updatedAtEpochMs = 1L,
            intentionIds = ids,
            intentionTitles = listOf("A", "B", "C"),
        )
        val json = Json.parseToJsonElement(session.toJson()).jsonObject
        assertEquals(ids[0], json["intentionId"]?.jsonPrimitive?.content)
        assertEquals("A", json["intentionTitle"]?.jsonPrimitive?.content)
        val encodedIds = json["intentionIds"]!!.jsonArray.map { it.jsonPrimitive.content }
        assertEquals(ids, encodedIds)
        val decoded = decodePrayerSession(session.toJson())
        assertEquals(ids, decoded.intentionIds)
        assertEquals(listOf("A", "B", "C"), decoded.intentionTitles)
    }

    @Test
    fun testRosaryStaysResumableJustAfterMidnight() {
        val started = at(10, 14, 23, 50)
        val lastBead = at(10, 14, 23, 58)
        val session = PrayerSession.create(
            mysterySet = MysterySetKind.Joyful,
            stepIndex = 20,
            startedAtEpochMs = started,
            updatedAtEpochMs = lastBead,
        )
        assertTrue(session.isResumable(at(10, 15, 0, 30), perth))
        assertFalse(session.isResumable(at(10, 15, 9, 0), perth))
        assertFalse(session.isResumable(at(10, 16, 0, 10), perth))
    }
}

class SessionStoreTest {
    @Test
    fun testCompletedRosaryKeepsAllIntentionsAndOldRecordsFallBack() {
        val store = SessionStore(InMemorySessionPreferences())
        val ids = listOf(UUID.randomUUID().toString(), UUID.randomUUID().toString())
        store.start(MysterySetKind.Joyful, intentionIds = ids, intentionTitles = listOf("Mum", "Peace"))
        store.complete()
        assertEquals(ids, store.completed.first().intentionIds)
        assertEquals(listOf("Mum", "Peace"), store.completed.first().allIntentionTitles)

        val old = CompletedPrayerSession(
            mysterySet = MysterySetKind.Joyful,
            startedAtEpochMs = 1L,
            completedAtEpochMs = 2L,
            duration = 60.0,
            intentionId = UUID.randomUUID().toString(),
            intentionTitle = "Church",
        )
        assertEquals(listOf("Church"), old.allIntentionTitles)
    }

    @Test
    fun testProgressPersistsAcrossStoreReload() {
        val prefs = InMemorySessionPreferences()
        val first = SessionStore(prefs)
        first.start(MysterySetKind.Luminous, intentionTitles = listOf("Peace"))
        first.updateStep(12)
        val reloaded = SessionStore(prefs)
        assertEquals(MysterySetKind.Luminous, reloaded.current?.mysterySet)
        assertEquals(12, reloaded.current?.stepIndex)
        assertEquals(listOf("Peace"), reloaded.current?.allIntentionTitles)
    }
}
