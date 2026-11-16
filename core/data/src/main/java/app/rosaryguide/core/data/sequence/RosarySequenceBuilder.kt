package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.data.catalog.MysteryScripture
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.model.BeadLocus
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.BilingualText
import app.rosaryguide.core.model.Mystery
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayTrackStage
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.core.model.RosaryStep
import app.rosaryguide.core.model.RosaryStepIdentity
import app.rosaryguide.core.model.RosaryStepKind

object RosarySequenceBuilder {
    /**
     * Maps a position in [old] to the equivalent position in [new] (same set, different config).
     * A surviving step keeps its identity. If the current step was removed, the user lands on
     * the first step after the last surviving step before it.
     */
    fun remap(index: Int, old: List<RosaryStep>, new: List<RosaryStep>): Int {
        if (new.isEmpty()) return 0
        if (index !in old.indices) return minOf(maxOf(index, 0), new.lastIndex)
        val lookup = LinkedHashMap<RosaryStepIdentity, Int>()
        new.forEachIndexed { offset, step ->
            if (step.identity !in lookup) lookup[step.identity] = offset
        }
        lookup[old[index].identity]?.let { return it }
        for (previous in (index - 1) downTo 0) {
            lookup[old[previous].identity]?.let { mapped ->
                return minOf(mapped + 1, new.lastIndex)
            }
        }
        return 0
    }

    fun build(set: MysterySetKind, config: RosaryConfig = RosaryConfig.default): List<RosaryStep> {
        val steps = mutableListOf<RosaryStep>()
        var id = 0

        fun append(
            kind: RosaryStepKind,
            title: BilingualText? = null,
            body: BilingualText? = null,
            subtitle: BilingualText? = null,
            mystery: Mystery? = null,
            decade: Int? = null,
            hailMary: Int? = null,
            intention: BilingualText? = null,
            stage: PrayTrackStage,
            bead: BeadLocus? = null,
            scriptureReference: String? = null,
        ) {
            val prayer = PrayerCatalog.prayer(kind)
            steps += RosaryStep(
                id = id,
                kind = kind,
                title = title ?: prayer?.title ?: BilingualText("", ""),
                body = body ?: prayer?.text ?: BilingualText("", ""),
                subtitle = subtitle ?: intention,
                mystery = mystery,
                decadeNumber = decade,
                hailMaryNumber = hailMary,
                intention = intention,
                haptic = RosaryHaptics.kind(kind),
                stage = stage,
                bead = bead,
                scriptureReference = scriptureReference,
            )
            id += 1
        }

        append(
            RosaryStepKind.SignOfTheCross,
            intention = BilingualText("Offer this Rosary for your intention", ""),
            stage = PrayTrackStage.Opening,
            bead = BeadLocus.Crucifix,
        )
        append(RosaryStepKind.Creed, stage = PrayTrackStage.Opening, bead = BeadLocus.Crucifix)
        append(RosaryStepKind.OurFather, stage = PrayTrackStage.Opening, bead = BeadLocus.OpeningOurFather)
        PrayerCatalog.openingIntentions.forEachIndexed { index, intention ->
            append(
                RosaryStepKind.HailMary,
                subtitle = intention,
                hailMary = index + 1,
                intention = intention,
                stage = PrayTrackStage.Opening,
                bead = BeadLocus.OpeningHail(index + 1),
            )
        }
        append(RosaryStepKind.GloryBe, stage = PrayTrackStage.Opening, bead = BeadLocus.OpeningGlory)

        for (mystery in MysteryCatalog.mysteries(set)) {
            val decade = mystery.number
            val stage = PrayTrackStage.decade(decade)
            append(
                RosaryStepKind.MysteryAnnouncement,
                title = mystery.title,
                body = BilingualText(
                    english = MysteryScripture.excerpt(mystery, config.translation),
                    latin = MysteryScripture.excerpt(mystery, BibleTranslation.Vulgate),
                ),
                subtitle = mystery.fruit,
                mystery = mystery,
                decade = decade,
                stage = stage,
                bead = BeadLocus.DecadeOurFather(decade),
                scriptureReference = mystery.scriptureReference,
            )
            append(
                RosaryStepKind.OurFather,
                mystery = mystery,
                decade = decade,
                stage = stage,
                bead = BeadLocus.DecadeOurFather(decade),
            )
            for (bead in 1..10) {
                append(
                    RosaryStepKind.HailMary,
                    mystery = mystery,
                    decade = decade,
                    hailMary = bead,
                    stage = stage,
                    bead = BeadLocus.DecadeHail(decade, bead),
                )
            }
            append(
                RosaryStepKind.GloryBe,
                mystery = mystery,
                decade = decade,
                stage = stage,
                bead = BeadLocus.DecadeGlory(decade),
            )
            if (config.fatimaPrayer) {
                append(
                    RosaryStepKind.Fatima,
                    mystery = mystery,
                    decade = decade,
                    stage = stage,
                    bead = BeadLocus.DecadeFatima(decade),
                )
            }
            if (config.oSacrament) {
                append(
                    RosaryStepKind.OSacrament,
                    mystery = mystery,
                    decade = decade,
                    stage = stage,
                    bead = BeadLocus.DecadeFatima(decade),
                )
            }
            steps[steps.lastIndex] = steps.last().copy(closesDecade = true)
        }

        if (config.closingPrayers) {
            append(RosaryStepKind.HailHolyQueen, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
            append(RosaryStepKind.Versicle, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
            append(RosaryStepKind.ConcludingPrayer, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
        }
        if (config.memorare) {
            append(RosaryStepKind.Memorare, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
        }
        if (config.saintMichael) {
            append(RosaryStepKind.SaintMichael, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
        }
        append(RosaryStepKind.SignOfTheCross, stage = PrayTrackStage.Closing, bead = BeadLocus.Closing)
        steps[steps.lastIndex] = steps.last().copy(isLastPrayer = true)

        append(
            RosaryStepKind.Completion,
            title = BilingualText("Rosary complete", "Rosarium completum est."),
            body = BilingualText("", ""),
            subtitle = null,
            stage = PrayTrackStage.Closing,
        )
        return steps
    }
}
