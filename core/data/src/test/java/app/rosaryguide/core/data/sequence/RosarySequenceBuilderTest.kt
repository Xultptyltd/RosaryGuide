package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.data.catalog.MysteryScripture
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.config.decodeRosaryConfig
import app.rosaryguide.core.data.config.fromFirestore
import app.rosaryguide.core.data.config.firestoreData
import app.rosaryguide.core.data.config.toJsonString
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayTrackStage
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.core.model.RosaryStepKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class RosarySequenceBuilderTest {

    private fun config(block: (RosaryConfig) -> RosaryConfig): RosaryConfig = block(RosaryConfig())

    private fun count(block: (RosaryConfig) -> RosaryConfig): Int =
        RosarySequenceBuilder.build(MysterySetKind.Joyful, block(RosaryConfig())).size

    @Test
    fun testSevenStageSequenceOmitsSaintMichael() {
        val steps = RosarySequenceBuilder.build(MysterySetKind.Joyful)
        assertFalse(steps.any { it.kind == RosaryStepKind.SaintMichael })
        assertEquals(53, steps.count { it.kind == RosaryStepKind.HailMary })
        assertEquals(5, steps.count { it.kind == RosaryStepKind.MysteryAnnouncement })
        assertEquals(RosaryStepKind.Completion, steps.last().kind)
        assertEquals(7, steps.map { it.stage }.toSet().size)
        assertEquals("Luke 1:26-27", MysteryCatalog.joyful.first().scriptureReference)
    }

    @Test
    fun testAllSetsBuild() {
        for (set in MysterySetKind.displayOrder) {
            val steps = RosarySequenceBuilder.build(set)
            assertTrue(steps.size > 70)
            assertEquals(RosaryStepKind.SignOfTheCross, steps.first().kind)
        }
    }

    @Test
    fun testPrayersHaveEnglishAndLatin() {
        assertTrue(PrayerCatalog.hailMary.text.english.isNotEmpty())
        assertTrue(PrayerCatalog.hailMary.text.latin.isNotEmpty())
        assertTrue(PrayerCatalog.saintMichael.text.latin.isNotEmpty())
    }

    @Test
    fun testStepCountsPerCombination() {
        assertEquals(82, RosarySequenceBuilder.build(MysterySetKind.Joyful).size)
        assertEquals(82, count { it })
        assertEquals(77, count { it.copy(fatimaPrayer = false) })
        assertEquals(87, count { it.copy(oSacrament = true) })
        assertEquals(79, count { it.copy(closingPrayers = false) })
        assertEquals(83, count { it.copy(memorare = true) })
        assertEquals(83, count { it.copy(saintMichael = true) })
        assertEquals(89, count { it.copy(memorare = true, saintMichael = true, oSacrament = true) })
        assertEquals(74, count { it.copy(fatimaPrayer = false, closingPrayers = false) })
    }

    @Test
    fun testDecadeEndsAndLastPrayerFollowConfig() {
        val configs = listOf(
            RosaryConfig.default,
            RosaryConfig(fatimaPrayer = false, closingPrayers = false),
            RosaryConfig(oSacrament = true, memorare = true, saintMichael = true),
        )
        for (config in configs) {
            val steps = RosarySequenceBuilder.build(MysterySetKind.Sorrowful, config)
            assertEquals(listOf(1, 2, 3, 4, 5), steps.filter { it.closesDecade }.map { it.decadeNumber })
            assertEquals(1, steps.count { it.isLastPrayer })
            assertEquals(steps.size - 2, steps.indexOfFirst { it.isLastPrayer })
            assertEquals(RosaryStepKind.Completion, steps.last().kind)
            assertEquals(7, steps.map { it.stage }.toSet().size)
        }
        val extras = RosaryConfig(memorare = true, saintMichael = true)
        val closing = RosarySequenceBuilder.build(MysterySetKind.Glorious, extras).takeLast(7).map { it.kind }
        assertEquals(
            listOf(
                RosaryStepKind.HailHolyQueen,
                RosaryStepKind.Versicle,
                RosaryStepKind.ConcludingPrayer,
                RosaryStepKind.Memorare,
                RosaryStepKind.SaintMichael,
                RosaryStepKind.SignOfTheCross,
                RosaryStepKind.Completion,
            ),
            closing,
        )
    }

    @Test
    fun testScriptureTranslationAndOpeningLines() {
        var plate = RosarySequenceBuilder.build(
            MysterySetKind.Joyful,
            RosaryConfig(translation = BibleTranslation.DouayRheims),
        ).first { it.isPlate }
        assertTrue(plate.body.english.startsWith("And in the sixth month, the angel Gabriel"))
        plate = RosarySequenceBuilder.build(
            MysterySetKind.Joyful,
            RosaryConfig(translation = BibleTranslation.Vulgate),
        ).first { it.isPlate }
        assertTrue(plate.body.english.startsWith("In mense autem sexto"))
        assertEquals("Luke 1:26-27", plate.scriptureReference)
        val old = decodeRosaryConfig("""{"showScripture":false,"memorare":true}""")
        assertTrue(old.memorare)
        for (mystery in MysteryCatalog.all) {
            assertTrue(mystery.id, MysteryScripture.douayRheims.containsKey(mystery.id))
            assertTrue(mystery.id, MysteryScripture.vulgate.containsKey(mystery.id))
        }
        val oldLines = decodeRosaryConfig("""{"openingIntentionLines":false}""")
        val opening = RosarySequenceBuilder.build(MysterySetKind.Joyful, oldLines)
            .filter { it.stage == PrayTrackStage.Opening && it.kind == RosaryStepKind.HailMary }
        assertEquals(PrayerCatalog.openingIntentions, opening.map { it.subtitle })
    }

    @Test
    fun testFatimaOffMidDecadeKeepsSameStep() {
        val old = RosarySequenceBuilder.build(MysterySetKind.Joyful)
        val new = RosarySequenceBuilder.build(MysterySetKind.Joyful, RosaryConfig(fatimaPrayer = false))
        val index = old.indexOfFirst { it.decadeNumber == 2 && it.kind == RosaryStepKind.HailMary && it.hailMaryNumber == 5 }
        val mapped = RosarySequenceBuilder.remap(index, old, new)
        assertEquals(old[index].identity, new[mapped].identity)
        assertEquals(index - 1, mapped)
        val glory = new.indexOfFirst { it.decadeNumber == 2 && it.kind == RosaryStepKind.GloryBe }
        assertTrue(new[glory].closesDecade)
    }

    @Test
    fun testMemorareOnNearEndComesNext() {
        val old = RosarySequenceBuilder.build(MysterySetKind.Glorious)
        val new = RosarySequenceBuilder.build(MysterySetKind.Glorious, RosaryConfig(memorare = true))
        val index = old.indexOfFirst { it.kind == RosaryStepKind.ConcludingPrayer }
        val mapped = RosarySequenceBuilder.remap(index, old, new)
        assertEquals(RosaryStepKind.ConcludingPrayer, new[mapped].kind)
        assertEquals(RosaryStepKind.Memorare, new[mapped + 1].kind)
        assertEquals(RosaryStepKind.SignOfTheCross, new[mapped + 2].kind)
        assertTrue(new[mapped + 2].isLastPrayer)
        assertFalse(new[mapped + 1].isLastPrayer)
    }

    @Test
    fun testRemovedCurrentStepMovesToNextSurvivor() {
        val old = RosarySequenceBuilder.build(MysterySetKind.Sorrowful)
        val fatimaOff = RosarySequenceBuilder.build(MysterySetKind.Sorrowful, RosaryConfig(fatimaPrayer = false))
        val fatima2 = old.indexOfFirst { it.kind == RosaryStepKind.Fatima && it.decadeNumber == 2 }
        val mapped = RosarySequenceBuilder.remap(fatima2, old, fatimaOff)
        assertEquals(RosaryStepKind.MysteryAnnouncement, fatimaOff[mapped].kind)
        assertEquals(3, fatimaOff[mapped].decadeNumber)

        val withMemorare = RosaryConfig(memorare = true)
        val before = RosarySequenceBuilder.build(MysterySetKind.Sorrowful, withMemorare)
        val after = RosarySequenceBuilder.build(
            MysterySetKind.Sorrowful,
            RosaryConfig(memorare = true, closingPrayers = false),
        )
        val versicle = before.indexOfFirst { it.kind == RosaryStepKind.Versicle }
        assertEquals(RosaryStepKind.Memorare, after[RosarySequenceBuilder.remap(versicle, before, after)].kind)

        val bare = RosarySequenceBuilder.build(MysterySetKind.Sorrowful, RosaryConfig(closingPrayers = false))
        val landed = bare[RosarySequenceBuilder.remap(old.indexOfFirst { it.kind == RosaryStepKind.Versicle }, old, bare)]
        assertEquals(RosaryStepKind.SignOfTheCross, landed.kind)
        assertEquals(PrayTrackStage.Closing, landed.stage)
    }

    @Test
    fun testTranslationChangeKeepsPositionAndSwapsScripture() {
        val old = RosarySequenceBuilder.build(MysterySetKind.Joyful)
        val new = RosarySequenceBuilder.build(
            MysterySetKind.Joyful,
            RosaryConfig(translation = BibleTranslation.DouayRheims),
        )
        val plate = old.indexOfFirst { it.isPlate }
        val mapped = RosarySequenceBuilder.remap(plate, old, new)
        assertEquals(plate, mapped)
        assertTrue(new[mapped].body.english.startsWith("And in the sixth month, the angel Gabriel"))
    }

    @Test
    fun testScriptureIsWebCatholicForMysteries() {
        val joyful = MysteryCatalog.all.first { it.id == "joyful-1" }
        assertTrue(joyful.scriptureExcerpt.english.startsWith("Now in the sixth month, the angel Gabriel was sent from God"))
        assertEquals(BibleTranslation.WebCatholic, RosaryConfig().translation)
        val plate = RosarySequenceBuilder.build(MysterySetKind.Joyful).first { it.isPlate }
        assertTrue(plate.body.english.startsWith("Now in the sixth month"))
        val resurrection = MysteryCatalog.all.first { it.id == "glorious-1" }
        assertEquals("Luke 24:5-6", resurrection.scriptureReference)
        assertEquals("Why do you seek the living among the dead? He isn’t here, but is risen.", resurrection.scriptureExcerpt.english)
        val previous = listOf(
            "handmaid of the Lord", "Hail, full of grace", "swaddling cloths",
            "close of the age", "Truly, I say to you", "Fear not",
        )
        for (text in MysteryCatalog.all.map { it.scriptureExcerpt.english }) {
            for (phrase in previous) {
                assertFalse("$phrase: $text", text.contains(phrase, ignoreCase = true))
            }
            assertTrue(text.isNotEmpty())
        }
    }

    @Test
    fun testOldTranslationSettingBecomesWebCatholic() {
        val stored = decodeRosaryConfig("""{"translation":"rsv2ce","memorare":true}""")
        assertEquals(BibleTranslation.WebCatholic, stored.translation)
        assertTrue(stored.memorare)
        val encoded = Json.parseToJsonElement(stored.toJsonString()).jsonObject
        assertEquals("webc", encoded["translation"]!!.jsonPrimitive.content)
        assertEquals(stored, decodeRosaryConfig(stored.toJsonString()))
        val unknown = decodeRosaryConfig("""{"translation":"kjv"}""")
        assertEquals(BibleTranslation.WebCatholic, unknown.translation)
    }

    @Test
    fun testFirestoreKeepsTokenTheDeployedRulesAllow() {
        assertEquals(BibleTranslation.WebCatholic, RosaryConfig.fromFirestore(mapOf("translation" to "rsv2ce")).translation)
        assertEquals(BibleTranslation.WebCatholic, RosaryConfig.fromFirestore(mapOf("translation" to "webc")).translation)
        assertEquals(BibleTranslation.Vulgate, RosaryConfig.fromFirestore(mapOf("translation" to "vulgate")).translation)
        val allowed = setOf("rsv2ce", "douayRheims", "vulgate")
        for (translation in BibleTranslation.entries) {
            val config = RosaryConfig(translation = translation)
            val token = config.firestoreData()["translation"] as String
            assertTrue("$translation", token in allowed)
            assertEquals(translation, RosaryConfig.fromFirestore(config.firestoreData()).translation)
        }
    }

    @Test
    fun testFirestoreRoundTrip() {
        val config = RosaryConfig(translation = BibleTranslation.DouayRheims, fatimaPrayer = false, memorare = true)
        assertEquals(config, RosaryConfig.fromFirestore(config.firestoreData()))
    }
}
