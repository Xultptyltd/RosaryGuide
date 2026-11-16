package app.rosaryguide.core.data.art

import app.rosaryguide.core.model.MysterySetKind
import java.time.LocalDate

/**
 * Artwork filenames, ported from iOS `ArtCatalog`.
 * Android resources use underscores: `feast_assumption`, `mystery_01_annunciation`, `hero_joyful`.
 * Mother of the Church shares the Assumption file; every other dedicated feast has its own.
 */
object ArtCatalog {
    private val sharedFeastArt: Map<String, String> = mapOf(
        "mother-of-the-church" to "assumption",
    )

    private val dedicatedFeastHeroIds: Set<String> = setOf(
        "advent-1", "all-saints", "all-souls", "annunciation", "ascension", "ash-wednesday",
        "assumption", "baptism-movable", "carmel", "christmas", "christ-the-king", "corpus-christi",
        "divine-mercy", "easter", "epiphany", "fatima", "good-friday", "guadalupe", "guardian-angels",
        "holy-cross", "holy-family", "holy-name-mary", "holy-saturday", "holy-thursday",
        "immaculate-conception", "immaculate-heart", "joachim-anne", "john-baptist", "joseph",
        "loreto", "lourdes", "mary-mother-of-god", "michael", "nativity-mary", "palm-sunday",
        "pentecost", "peter-paul", "presentation", "presentation-mary", "queenship", "rosary",
        "sacred-heart", "sorrows", "transfiguration", "trinity", "visitation",
    )

    fun feastArtId(feastId: String): String? {
        val artId = sharedFeastArt[feastId] ?: feastId
        return if (artId in dedicatedFeastHeroIds) artId else null
    }

    /** Drawable resource name without extension, e.g. `feast_assumption`. */
    fun feastHeroName(feastId: String): String? =
        feastArtId(feastId)?.let { "feast_" + it.replace('-', '_') }

    fun plateSlugs(set: MysterySetKind): List<String> = when (set) {
        MysterySetKind.Joyful -> listOf(
            "01-annunciation", "02-visitation", "03-birth-of-jesus",
            "04-presentation-of-the-baby-jesus", "05-finding-of-the-child-jesus-in-the-temple",
        )
        MysterySetKind.Luminous -> listOf(
            "01-baptism-of-jesus-in-the-jordan", "02-miracle-at-the-wedding-at-cana",
            "03-proclamation-of-the-kingdom-of-god", "04-transfiguration",
            "05-institution-of-the-holy-eucharist",
        )
        MysterySetKind.Sorrowful -> listOf(
            "01-agony-in-the-garden", "02-scourging-at-the-pillar", "03-crowning-with-thorns",
            "04-carrying-of-the-cross", "05-crucifixion",
        )
        MysterySetKind.Glorious -> listOf(
            "01-resurrection", "02-ascension", "03-descent-of-the-holy-spirit",
            "04-assumption", "05-coronation",
        )
    }

    fun plateName(set: MysterySetKind, slug: String): String =
        "mystery_" + slug.replace('-', '_')

    fun heroName(set: MysterySetKind): String = "hero_" + set.name.replaceFirstChar { it.lowercase() }.let {
        when (set) {
            MysterySetKind.Joyful -> "joyful"
            MysterySetKind.Sorrowful -> "sorrowful"
            MysterySetKind.Glorious -> "glorious"
            MysterySetKind.Luminous -> "luminous"
        }
    }

    fun crucifixName(): String = "crucifix"

    /**
     * Complete-screen art. Home always shows the set's hero file, so the complete
     * screen uses one of the set's five scene plates, rotating by day of year.
     */
    fun completionPlate(set: MysterySetKind, date: LocalDate = LocalDate.now()): Pair<Int, String> {
        val slugs = plateSlugs(set)
        val index = (date.dayOfYear - 1) % slugs.size
        return (index + 1) to slugs[index]
    }

    fun focusY(set: MysterySetKind, number: Int): Float {
        val values = when (set) {
            MysterySetKind.Joyful -> floatArrayOf(0.30f, 0.30f, 0.32f, 0.34f, 0.36f)
            MysterySetKind.Luminous -> floatArrayOf(0.38f, 0.34f, 0.32f, 0.00f, 0.34f)
            MysterySetKind.Sorrowful -> floatArrayOf(0.30f, 0.32f, 0.28f, 0.28f, 0.20f)
            MysterySetKind.Glorious -> floatArrayOf(0.22f, 0.22f, 0.28f, 0.30f, 0.30f)
        }
        return values[(number - 1).coerceIn(0, 4)]
    }

    fun cardFocusY(set: MysterySetKind, number: Int): Float {
        val values = when (set) {
            MysterySetKind.Joyful -> floatArrayOf(0.0f, 0.0f, 0.28f, 0.12f, 0.20f)
            MysterySetKind.Luminous -> floatArrayOf(0.0f, 0.12f, 0.15f, 0.0f, 0.15f)
            MysterySetKind.Sorrowful -> floatArrayOf(0.15f, 0.12f, 0.0f, 0.0f, 0.0f)
            MysterySetKind.Glorious -> floatArrayOf(0.0f, 0.0f, 0.0f, 0.0f, 0.0f)
        }
        return values[(number - 1).coerceIn(0, 4)]
    }
}
