package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.model.HapticKind
import app.rosaryguide.core.model.RosaryStepKind

object RosaryHaptics {
    fun kind(kind: RosaryStepKind): HapticKind = when (kind) {
        RosaryStepKind.SignOfTheCross,
        RosaryStepKind.MysteryAnnouncement,
        -> HapticKind.Light
        RosaryStepKind.Completion -> HapticKind.Success
        else -> HapticKind.None
    }
}
