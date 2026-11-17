package app.rosaryguide.core.data.journey

import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.OrdinalWord
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

data class JourneyPrayerDetailFacts(
    val title: String,
    val subtitle: String,
    val facts: List<Fact>,
    val intentionTitles: List<String>,
    val emptyIntentionsLabel: String,
) {
    data class Fact(val label: String, val value: String)

    companion object {
        fun from(
            mysterySet: MysterySetKind?,
            decade: Int?,
            completedAtEpochMs: Long,
            startedAtEpochMs: Long?,
            durationSeconds: Double?,
            intentionTitles: List<String>,
            zone: ZoneId,
            locale: Locale = Locale.forLanguageTag("en-AU"),
        ): JourneyPrayerDetailFacts {
            val title = mysterySet?.let { "${it.shortName} Mysteries" } ?: "Rosary prayed"
            val subtitle = if (decade == null) "Rosary completed" else "Single decade"
            val completed = Instant.ofEpochMilli(completedAtEpochMs).atZone(zone)
            val dateFormatter = DateTimeFormatter.ofPattern("EEEE d MMMM yyyy", locale)
            val timeFormatter = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).withLocale(locale)
            val startedInstant = startedAtEpochMs?.let { Instant.ofEpochMilli(it) }
                ?: JourneyDuration.reliable(durationSeconds)?.let {
                    Instant.ofEpochMilli(completedAtEpochMs).minusMillis((it * 1000).toLong())
                }
            val facts = buildList {
                add(Fact("Date", completed.format(dateFormatter)))
                add(
                    Fact(
                        "Started",
                        startedInstant?.atZone(zone)?.format(timeFormatter) ?: "Not recorded",
                    ),
                )
                add(
                    Fact(
                        "Duration",
                        JourneyDuration.reliable(durationSeconds)?.let { JourneyDuration.text(it) } ?: "Not recorded",
                    ),
                )
                if (mysterySet != null) add(Fact("Mysteries", mysterySet.shortName))
                if (decade != null) {
                    val name = mysterySet?.let { set ->
                        MysteryCatalog.mysteries(set).firstOrNull { it.number == decade }?.title?.english
                    }
                    val roman = runCatching { OrdinalWord.roman(decade) }.getOrDefault(decade.toString())
                    add(Fact("Decade", if (name != null) "$roman · $name" else roman))
                }
            }
            val empty = if (mysterySet == null) "Not recorded" else "No specific intention"
            return JourneyPrayerDetailFacts(
                title = title,
                subtitle = subtitle,
                facts = facts,
                intentionTitles = intentionTitles,
                emptyIntentionsLabel = empty,
            )
        }
    }
}
