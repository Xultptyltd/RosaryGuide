package app.rosaryguide.core.model

import kotlinx.serialization.Serializable

@Serializable
data class BilingualText(
    val english: String,
    val latin: String,
) {
    /** The Latin text, or the English when there is no Latin version. */
    val latinOrEnglish: String get() = latin.ifEmpty { english }

    /** Whether a separate Latin text exists to show beside the English. */
    val hasDistinctLatin: Boolean get() = latin.isNotEmpty() && latin != english

    fun resolved(forLanguage: PrayerLanguage): String = when (forLanguage) {
        PrayerLanguage.English -> english
        PrayerLanguage.Latin -> latinOrEnglish
        PrayerLanguage.Bilingual -> if (hasDistinctLatin) "$english\n\n$latin" else english
    }

    fun primary(forLanguage: PrayerLanguage): String =
        if (forLanguage == PrayerLanguage.Latin) latinOrEnglish else english

    fun secondary(forLanguage: PrayerLanguage): String? =
        if (forLanguage == PrayerLanguage.Bilingual && hasDistinctLatin) latin else null
}
