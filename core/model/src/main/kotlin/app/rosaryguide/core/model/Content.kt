package app.rosaryguide.core.model

import kotlinx.serialization.Serializable
import java.time.LocalDate

@Serializable
data class Mystery(
    val id: String,
    val set: MysterySetKind,
    val number: Int,
    val title: BilingualText,
    val fruit: BilingualText,
    val scriptureReference: String,
    val scriptureExcerpt: BilingualText,
    val artSlug: String,
    /** Card summary; empty when the catalog has no line for this id. */
    val summary: String = "",
)

@Serializable
data class Prayer(
    val id: String,
    val title: BilingualText,
    val text: BilingualText,
    val leaderPrompt: BilingualText? = null,
)

@Serializable
data class CompletionQuote(
    val id: String,
    val text: String,
    val attribution: String,
)

data class FeastCelebration(
    /** First sentence, e.g. "Today we celebrate the birth of our Lord." */
    val today: String,
    /** Ends the second sentence, e.g. "at Christmas". */
    val occasion: String,
)

/**
 * A liturgical feast. Equality is by [id] only, matching the iOS type.
 *
 * Dates are resolved through [dateOn] so catalogs stay bit-compatible with
 * the iOS `dateProvider`.
 */
data class Feast(
    val id: String,
    val name: BilingualText,
    val summary: String,
    val suggestedMysterySet: MysterySetKind?,
    val isMarian: Boolean,
    val rank: FeastRank,
    val dateOn: (Int) -> LocalDate?,
    val tagline: String = "",
    val celebration: FeastCelebration? = null,
    val shortTitleOverride: String? = null,
) {
    /**
     * Compact list label (matches rosaryguide.app home wording).
     */
    val shortTitle: String
        get() = shortTitleOverride ?: SHORT_TITLES[id] ?: name.english

    /** Home and the Learn screen offer this feast's set instead of the weekday's. */
    val recommendsOnHome: Boolean
        get() = suggestedMysterySet != null && celebration != null

    override fun equals(other: Any?): Boolean = other is Feast && id == other.id
    override fun hashCode(): Int = id.hashCode()

    companion object {
        val SHORT_TITLES: Map<String, String> = mapOf(
            "mary-mother-of-god" to "Mary, Mother of God",
            "presentation" to "Presentation of the Lord",
            "lourdes" to "Our Lady of Lourdes",
            "annunciation" to "Annunciation",
            "fatima" to "Our Lady of Fatima",
            "visitation" to "Visitation",
            "carmel" to "Our Lady of Mount Carmel",
            "assumption" to "Assumption",
            "queenship" to "Queenship of Mary",
            "nativity-mary" to "Nativity of Mary",
            "holy-name-mary" to "Holy Name of Mary",
            "sorrows" to "Our Lady of Sorrows",
            "rosary" to "Our Lady of the Rosary",
            "all-souls" to "All Souls' Day",
            "presentation-mary" to "Presentation of Mary",
            "immaculate-conception" to "Immaculate Conception",
            "immaculate-heart" to "Immaculate Heart of Mary",
            "mother-of-the-church" to "Mother of the Church",
            "guadalupe" to "Our Lady of Guadalupe",
            "christmas" to "Christmas",
        )
    }
}

data class DatedFeast(
    val feast: Feast,
    val date: LocalDate,
) {
    val id: String get() = "${feast.id}-$date"
}

data class SeasonalSundaySuggestion(
    val set: MysterySetKind,
    /** Ends the line, e.g. "on Sundays of Advent". */
    val occasion: String,
)

data class FeastLine(
    val lead: String,
    val setName: String,
    val tail: String,
) {
    val text: String get() = lead + setName + tail

    companion object {
        const val BACK_TO_TODAY_TITLE = "Back to today"
    }
}

data class MysteryAssignment(
    val set: MysterySetKind,
    val reason: String,
    val season: LiturgicalSeason,
    val feast: DatedFeast? = null,
    val seasonalSunday: SeasonalSundaySuggestion? = null,
) {
    /**
     * A major feast's set wins; otherwise an Advent or Lent Sunday's set.
     */
    val feastSuggestion: MysterySetKind?
        get() {
            val feast = feast?.feast
            if (feast != null && feast.recommendsOnHome) {
                val suggested = feast.suggestedMysterySet
                return if (suggested != null && suggested != set) suggested else null
            }
            val seasonal = seasonalSunday ?: return null
            return if (seasonal.set != set) seasonal.set else null
        }

    fun defaultSet(prefersWeekday: Boolean): MysterySetKind =
        if (prefersWeekday) set else (feastSuggestion ?: set)

    /** The set the Home picker's dot marks: always the weekday set, never a feast's. */
    val pickerDotSet: MysterySetKind get() = this.set

    fun shownSet(manual: MysterySetKind?, prefersWeekday: Boolean): MysterySetKind =
        manual ?: defaultSet(prefersWeekday)

    /**
     * Home's feast line, split so the set name can be an inline link:
     * "<today> Many pray the <setName> <occasion>."
     */
    val feastLine: FeastLine?
        get() {
            val suggested = feastSuggestion ?: return null
            val feast = feast?.feast
            if (feast != null && feast.recommendsOnHome) {
                val celebration = feast.celebration ?: return null
                return FeastLine(
                    lead = "${celebration.today} Many pray the ",
                    setName = "${suggested.shortName} Mysteries",
                    tail = " ${celebration.occasion}.",
                )
            }
            val seasonal = seasonalSunday ?: return null
            return FeastLine(
                lead = "Many pray the ",
                setName = "${suggested.shortName} Mysteries",
                tail = " ${seasonal.occasion}",
            )
        }
}

@Serializable
data class HowToPrayStep(
    val id: Int,
    val title: BilingualText,
    val body: String,
)

@Serializable
data class RosaryStepIdentity(
    val kind: RosaryStepKind,
    val stage: PrayTrackStage,
    val decade: Int? = null,
    val hailMary: Int? = null,
)

@Serializable
data class RosaryStep(
    val id: Int,
    val kind: RosaryStepKind,
    val title: BilingualText,
    val body: BilingualText,
    val subtitle: BilingualText? = null,
    val mystery: Mystery? = null,
    val decadeNumber: Int? = null,
    val hailMaryNumber: Int? = null,
    val intention: BilingualText? = null,
    val haptic: HapticKind = HapticKind.None,
    val stage: PrayTrackStage,
    val bead: BeadLocus? = null,
    val scriptureReference: String? = null,
    val closesDecade: Boolean = false,
    val isLastPrayer: Boolean = false,
) {
    val identity: RosaryStepIdentity
        get() = RosaryStepIdentity(kind, stage, decadeNumber, hailMaryNumber)

    val isPlate: Boolean get() = kind == RosaryStepKind.MysteryAnnouncement
    val isFinis: Boolean get() = kind == RosaryStepKind.Completion

    /** Matches website `#pnow`: Opening / Closing prayers, or `I · The Annunciation` in a decade. */
    val progressLabel: String
        get() = when (stage) {
            PrayTrackStage.Opening -> "Opening prayers"
            PrayTrackStage.Closing -> "Closing prayers"
            else -> mystery?.let { "${OrdinalWord.roman(it.number)} · ${it.title.english}" }
                ?: OrdinalWord.roman(stage.ordinal)
        }

    val nextLabel: String
        get() = when {
            isLastPrayer -> "Finish"
            isPlate -> "Next" // iOS nextLabel is "Continue" on plates; PrayView remaps it to "Next"
            isFinis -> "Amen"
            else -> "Next"
        }
}

/**
 * A clock that tracks the current calendar day and a same-day "prefer weekday set"
 * flag, reset when the day rolls over.
 */
class DayClock(now: LocalDate = LocalDate.now()) {
    var today: LocalDate = now
        private set
    var prefersWeekdaySet: Boolean = false

    fun refresh(now: LocalDate) {
        if (now != today) {
            today = now
            prefersWeekdaySet = false
        }
    }
}
