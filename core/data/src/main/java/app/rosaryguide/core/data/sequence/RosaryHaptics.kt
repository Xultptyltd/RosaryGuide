package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.model.HapticKind
import app.rosaryguide.core.model.RosaryStep
import app.rosaryguide.core.model.RosaryStepKind

/**
 * One calm rhythm for the Rosary, ported from iOS `RosaryHaptics`: a soft tap per
 * Hail Mary, a slightly firmer tap on the larger beads and prayers, a medium tap as
 * each mystery is announced, and a gentle success only when a decade is completed.
 * One haptic per step, never stacked.
 */
object RosaryHaptics {
    fun kind(kind: RosaryStepKind): HapticKind = when (kind) {
        RosaryStepKind.HailMary -> HapticKind.Soft
        RosaryStepKind.MysteryAnnouncement -> HapticKind.Medium
        else -> HapticKind.Light
    }

    data class Arrival(
        val kind: HapticKind,
        val celebratedDecade: Int? = null,
    )

    /**
     * Haptic for arriving on [step]. Finishing a decade (by Complete decade, or by
     * moving on from its closing prayer) is the one success moment. Each decade
     * celebrates once: pass the decades already celebrated, and add the returned
     * decade (if any) to that set.
     */
    fun arrival(
        step: RosaryStep,
        previous: RosaryStep?,
        viaCompleteDecade: Boolean = false,
        celebrated: Set<Int> = emptySet(),
    ): Arrival {
        val decade: Int? = when {
            viaCompleteDecade -> previous?.decadeNumber ?: step.decadeNumber
            previous != null && previous.closesDecade && step.id > previous.id -> previous.decadeNumber
            else -> return Arrival(step.haptic, null)
        }
        if (decade != null && decade in celebrated) return Arrival(step.haptic, null)
        return Arrival(HapticKind.Success, decade)
    }
}
