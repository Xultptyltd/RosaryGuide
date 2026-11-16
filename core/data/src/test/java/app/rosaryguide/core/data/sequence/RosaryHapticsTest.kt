package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.model.HapticKind
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.RosaryStepKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class RosaryHapticsTest {
    private val steps = RosarySequenceBuilder.build(MysterySetKind.Joyful)

    @Test
    fun testBeadRhythm() {
        for (step in steps) {
            when (step.kind) {
                RosaryStepKind.HailMary -> assertEquals(HapticKind.Soft, step.haptic)
                RosaryStepKind.MysteryAnnouncement -> assertEquals(HapticKind.Medium, step.haptic)
                else -> assertEquals("${step.kind}", HapticKind.Light, step.haptic)
            }
        }
        assertFalse(steps.any { it.haptic == HapticKind.Heavy || it.haptic == HapticKind.Success })
    }

    @Test
    fun testDecadeCompletionIsTheOnlySuccess() {
        val closing = steps.indexOfFirst { it.closesDecade }
        val next = steps[closing + 1]
        assertEquals(HapticKind.Success, RosaryHaptics.arrival(next, steps[closing]).kind)
        // Stepping back onto a decade's closing prayer is not a completion.
        assertEquals(steps[closing].haptic, RosaryHaptics.arrival(steps[closing], next).kind)
        val hail = steps.indexOfFirst { it.kind == RosaryStepKind.HailMary && it.decadeNumber == 1 }
        assertEquals(HapticKind.Soft, RosaryHaptics.arrival(steps[hail + 1], steps[hail]).kind)
        assertEquals(HapticKind.Success, RosaryHaptics.arrival(steps[hail + 1], steps[hail], viaCompleteDecade = true).kind)
    }

    @Test
    fun testCompleteDecadeCelebratesOnce() {
        val hail = steps.indexOfFirst { it.kind == RosaryStepKind.HailMary && it.decadeNumber == 1 }
        val skip = RosaryHaptics.arrival(steps[hail + 1], steps[hail], viaCompleteDecade = true)
        assertEquals(HapticKind.Success, skip.kind)
        assertEquals(1, skip.celebratedDecade)
        val closing = steps.indexOfFirst { it.closesDecade && it.decadeNumber == 1 }
        val leave = RosaryHaptics.arrival(steps[closing + 1], steps[closing], celebrated = setOf(1))
        assertEquals(steps[closing + 1].haptic, leave.kind)
        assertNull(leave.celebratedDecade)
    }

    @Test
    fun testSaintMichaelSitsAfterClosingPrayersBeforeFinalSignOfTheCross() {
        val kinds = RosarySequenceBuilder.build(
            MysterySetKind.Joyful,
            app.rosaryguide.core.model.RosaryConfig(saintMichael = true),
        ).map { it.kind }
        val michael = kinds.lastIndexOf(RosaryStepKind.SaintMichael)
        assertEquals(RosaryStepKind.ConcludingPrayer, kinds[michael - 1])
        assertEquals(RosaryStepKind.SignOfTheCross, kinds[michael + 1])
        assertEquals(RosaryStepKind.Completion, kinds[michael + 2])
    }

    @Test
    fun testShowBeadsDoesNotChangeTheSteps() {
        val hidden = app.rosaryguide.core.model.RosaryConfig(showBeads = false)
        assertEquals(
            RosarySequenceBuilder.build(MysterySetKind.Joyful, hidden).map { it.kind },
            RosarySequenceBuilder.build(MysterySetKind.Joyful).map { it.kind },
        )
    }

    @Test
    fun testSaintMichaelDefaultsOff() {
        assertEquals(false, app.rosaryguide.core.model.RosaryConfig.default.saintMichael)
    }

    @Test
    fun testRosaryDefaultsMatchTheRequestedPrayers() {
        val config = app.rosaryguide.core.model.RosaryConfig.default
        assertEquals(true, config.intentionsStep)
        assertEquals(true, config.showBeads)
        assertEquals(true, config.fatimaPrayer)
        assertEquals(true, config.closingPrayers)
        assertEquals(false, config.saintMichael)
        assertEquals(false, config.memorare)
        assertEquals(false, config.oSacrament)
    }
}
