package app.rosaryguide.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class PrayerLanguage {
    @SerialName("english") English,
    @SerialName("latin") Latin,
    @SerialName("bilingual") Bilingual,
    ;

    val chip: String
        get() = when (this) {
            English -> "Eng"
            Latin -> "Lat"
            Bilingual -> "Both"
        }

    val title: String
        get() = when (this) {
            English -> "English"
            Latin -> "Latin"
            Bilingual -> "English + Latin"
        }

    val shortTitle: String get() = chip
}

@Serializable
enum class AppearancePreference {
    @SerialName("system") System,
    @SerialName("light") Light,
    @SerialName("dark") Dark,
    ;

    val title: String
        get() = when (this) {
            System -> "System"
            Light -> "Light"
            Dark -> "Dark"
        }

    fun isDark(systemIsDark: Boolean): Boolean = when (this) {
        System -> systemIsDark
        Light -> false
        Dark -> true
    }
}

@Serializable
enum class PrayerTextSize {
    @SerialName("small") Small,
    @SerialName("medium") Medium,
    @SerialName("large") Large,
    ;

    /** Medium matches site `--ps: 1.3125rem` (~21pt). Small/Large step ±~10–15%. */
    val scale: Double
        get() = when (this) {
            Small -> 0.9
            Medium -> 1.0
            Large -> 1.15
        }

    val next: PrayerTextSize
        get() = when (this) {
            Small -> Medium
            Medium -> Large
            Large -> Small
        }
}

@Serializable
enum class MysterySetKind {
    @SerialName("joyful") Joyful,
    @SerialName("sorrowful") Sorrowful,
    @SerialName("glorious") Glorious,
    @SerialName("luminous") Luminous,
    ;

    val shortName: String
        get() = when (this) {
            Joyful -> "Joyful"
            Sorrowful -> "Sorrowful"
            Glorious -> "Glorious"
            Luminous -> "Luminous"
        }

    val letter: String
        get() = when (this) {
            Joyful -> "J"
            Luminous -> "L"
            Sorrowful -> "S"
            Glorious -> "G"
        }

    val themeSummary: String
        get() = when (this) {
            Joyful -> "The Incarnation and hidden life of Jesus."
            Luminous -> "The public ministry of Christ."
            Sorrowful -> "The Passion and sacrifice of Jesus."
            Glorious -> "The Resurrection and heavenly glory."
        }

    val titleText: BilingualText
        get() = when (this) {
            Joyful -> BilingualText("Joyful Mysteries", "Mysteria Gaudiosa")
            Sorrowful -> BilingualText("Sorrowful Mysteries", "Mysteria Dolorosa")
            Glorious -> BilingualText("Glorious Mysteries", "Mysteria Gloriosa")
            Luminous -> BilingualText("Luminous Mysteries", "Mysteria Luminosa")
        }

    val weekdayNames: String get() = days(inSeason = LiturgicalSeason.Ordinary)

    /** Learn caption: "Monday · Saturday". Same weekly pattern as MysteryCalendar in every season. */
    val weekdayCaption: String
        get() = when (this) {
            Joyful -> "Monday · Saturday"
            Luminous -> "Thursday"
            Sorrowful -> "Tuesday · Friday"
            Glorious -> "Wednesday · Sunday"
        }

    fun days(inSeason: LiturgicalSeason): String {
        // The weekly pattern is the same in every season; Sundays are always Glorious.
        return when (this) {
            Joyful -> "Mondays and Saturdays"
            Luminous -> "Thursdays"
            Sorrowful -> "Tuesdays and Fridays"
            Glorious -> "Wednesdays and Sundays"
        }
    }

    companion object {
        val displayOrder: List<MysterySetKind> = listOf(Joyful, Luminous, Sorrowful, Glorious)
    }
}

@Serializable
enum class LiturgicalSeason {
    @SerialName("advent") Advent,
    @SerialName("christmas") Christmas,
    @SerialName("ordinary") Ordinary,
    @SerialName("lent") Lent,
    @SerialName("easter") Easter,
    @SerialName("triduum") Triduum,
    ;

    val nameText: BilingualText
        get() = when (this) {
            Advent -> BilingualText("Advent", "Adventus")
            Christmas -> BilingualText("Christmas", "Nativitas")
            Ordinary -> BilingualText("Ordinary Time", "Tempus per annum")
            Lent -> BilingualText("Lent", "Quadragesima")
            Easter -> BilingualText("Easter", "Tempus Paschale")
            Triduum -> BilingualText("Paschal Triduum", "Sacrum Triduum Paschale")
        }

    val liturgicalColorName: String
        get() = when (this) {
            Advent, Lent -> "Violet"
            Christmas, Easter -> "White"
            Ordinary -> "Green"
            Triduum -> "Red / White"
        }
}

@Serializable
enum class FeastRank {
    @SerialName("solemnity") Solemnity,
    @SerialName("feast") Feast,
    @SerialName("memorial") Memorial,
    @SerialName("optionalMemorial") OptionalMemorial,
    @SerialName("seasonal") Seasonal,
    ;

    val title: String
        get() = when (this) {
            Solemnity -> "Solemnity"
            Feast -> "Feast"
            Memorial -> "Memorial"
            OptionalMemorial -> "Optional Memorial"
            Seasonal -> "Seasonal"
        }

    /** Higher wins when two feasts share a day. */
    val precedence: Int
        get() = when (this) {
            Solemnity -> 5
            Feast -> 4
            Memorial -> 3
            OptionalMemorial -> 2
            Seasonal -> 1
        }

    /** Lowercase rank for notification sentences; optional memorials read as "memorial". */
    val notificationWord: String?
        get() = when (this) {
            Solemnity -> "solemnity"
            Feast -> "feast"
            Memorial, OptionalMemorial -> "memorial"
            Seasonal -> null
        }
}

object OrdinalWord {
    fun english(n: Int): String = listOf("First", "Second", "Third", "Fourth", "Fifth")[n - 1]
    fun latin(n: Int): String = listOf("Primum", "Secundum", "Tertium", "Quartum", "Quintum")[n - 1]
    fun roman(n: Int): String = listOf("I", "II", "III", "IV", "V")[n - 1]
}

@Serializable
enum class PrayTrackStage {
    @SerialName("opening") Opening,
    @SerialName("first") First,
    @SerialName("second") Second,
    @SerialName("third") Third,
    @SerialName("fourth") Fourth,
    @SerialName("fifth") Fifth,
    @SerialName("closing") Closing,
    ;

    val label: String
        get() = listOf("Opening", "I", "II", "III", "IV", "V", "Close")[ordinal]

    /** Web-style resume phrase: "Continue — first mystery" */
    val continuePhrase: String
        get() = listOf(
            "the opening prayers",
            "first mystery",
            "second mystery",
            "third mystery",
            "fourth mystery",
            "fifth mystery",
            "the closing prayers",
        )[ordinal]

    companion object {
        fun decade(n: Int): PrayTrackStage = entries.getOrElse(n) { First }
    }
}

@Serializable
sealed class BeadLocus {
    @Serializable
    data object Crucifix : BeadLocus()
    @Serializable
    data object OpeningOurFather : BeadLocus()
    @Serializable
    data class OpeningHail(val n: Int) : BeadLocus()
    @Serializable
    data object OpeningGlory : BeadLocus()
    @Serializable
    data class DecadeOurFather(val decade: Int) : BeadLocus()
    @Serializable
    data class DecadeHail(val decade: Int, val hail: Int) : BeadLocus()
    @Serializable
    data class DecadeGlory(val decade: Int) : BeadLocus()
    @Serializable
    data class DecadeFatima(val decade: Int) : BeadLocus()
    @Serializable
    data object Closing : BeadLocus()
}

@Serializable
enum class RosaryStepKind {
    SignOfTheCross,
    Creed,
    OurFather,
    HailMary,
    GloryBe,
    Fatima,
    MysteryAnnouncement,
    HailHolyQueen,
    Versicle,
    ConcludingPrayer,
    SaintMichael,
    OSacrament,
    Memorare,
    Completion,
}

@Serializable
enum class HapticKind {
    Light,
    Success,
    None,
}

object CountWords {
    private val words = listOf(
        "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
        "Seventeen", "Eighteen", "Nineteen", "Twenty",
    )

    /** Capitalised English word for 0...20; digits above that. */
    fun sentenceStart(count: Int): String =
        if (count in 0..20) words[count] else count.toString()

    fun rosariesOfferedThisWeek(count: Int): String {
        val noun = if (count == 1) "Rosary" else "Rosaries"
        return "${sentenceStart(count)} $noun offered this week"
    }
}
