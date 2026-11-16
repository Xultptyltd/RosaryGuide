package app.rosaryguide.core.data.journey

import app.rosaryguide.core.data.config.RosaryJson
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer

@Serializable
data class PopeMonthIntention(
    val yearMonth: String,
    val title: String,
    val note: String? = null,
) {
    fun monthLabel(locale: Locale = Locale.forLanguageTag("en-AU")): String {
        val parts = yearMonth.split("-")
        if (parts.size != 2) return yearMonth
        val year = parts[0].toIntOrNull() ?: return yearMonth
        val month = parts[1].toIntOrNull() ?: return yearMonth
        val date = LocalDate.of(year, month, 1)
        return date.format(DateTimeFormatter.ofPattern("MMMM yyyy", locale))
    }
}

object PopeIntentionCatalog {
    fun load(json: String? = null): List<PopeMonthIntention> {
        val raw = json ?: bundledJson() ?: return emptyList()
        return runCatching {
            RosaryJson.decodeFromString(ListSerializer(PopeMonthIntention.serializer()), raw)
                .sortedBy { it.yearMonth }
        }.getOrDefault(emptyList())
    }

    fun intention(forDate: LocalDate, intentions: List<PopeMonthIntention> = load()): PopeMonthIntention? {
        val key = yearMonth(forDate)
        return intentions.firstOrNull { it.yearMonth == key }
    }

    fun yearMonth(date: LocalDate): String = "%04d-%02d".format(date.year, date.monthValue)

    private fun bundledJson(): String? {
        val stream = PopeIntentionCatalog::class.java.classLoader
            ?.getResourceAsStream("pope_intentions.json")
            ?: return null
        return stream.bufferedReader().use { it.readText() }
    }
}
