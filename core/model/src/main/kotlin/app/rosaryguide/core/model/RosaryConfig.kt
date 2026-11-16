package app.rosaryguide.core.model

import kotlinx.serialization.Serializable

/**
 * How the user prays the Rosary. Saved on each session so a resumed Rosary
 * rebuilds the same steps even if Settings changed meanwhile.
 *
 * Unknown keys such as a stored `showScripture` or `openingIntentionLines`
 * are ignored (scripture and opening lines are always shown).
 */
@Serializable
data class RosaryConfig(
    val translation: BibleTranslation = BibleTranslation.WebCatholic,
    val fatimaPrayer: Boolean = true,
    /** O Sacrament most holy, after the Fatima prayer in each decade. */
    val oSacrament: Boolean = false,
    /** Hail, holy Queen + versicle + closing prayer, as one group. */
    val closingPrayers: Boolean = true,
    val memorare: Boolean = false,
    val saintMichael: Boolean = false,
    /** The "Offer this Rosary for" step after the Sign of the Cross. */
    val intentionsStep: Boolean = true,
    /** The virtual bead strand in the prayer flow. Display only. */
    val showBeads: Boolean = true,
) {
    companion object {
        /** Matches the fixed sequence from before this setting existed. */
        val default: RosaryConfig = RosaryConfig()
    }
}
