package app.rosaryguide.core.data.journey

import app.rosaryguide.core.data.session.CompletedPrayerSession
import app.rosaryguide.core.model.MysterySetKind
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

data class JourneyDayEntry(
    val id: String,
    val kind: Kind,
    val mysterySet: MysterySetKind?,
    val startedAtEpochMs: Long?,
    val completedAtEpochMs: Long?,
    val duration: Double?,
    val intentionTitles: List<String>,
) {
    enum class Kind { Rosary, Decade, RecordedDay }
}

/**
 * What was prayed on one calendar day, oldest first.
 * Ported from iOS `JourneyDayDetail`, including the 11 Nov 2026 abbreviated heading.
 */
object JourneyDayDetail {
    fun entries(
        dayKey: String,
        sessions: List<CompletedPrayerSession>,
        decades: List<CompletedDecadeSession>,
        prayedDayKeys: Set<String>,
        zone: ZoneId,
    ): List<JourneyDayEntry> {
        val day = runCatching { LocalDate.parse(dayKey) }.getOrNull() ?: return emptyList()
        fun belongsToStartDay(startedAt: Long?, completedAt: Long?): Boolean {
            val epoch = startedAt ?: completedAt ?: return false
            return LocalDate.ofInstant(Instant.ofEpochMilli(epoch), zone) == day
        }
        // A finished Rosary belongs to the day it was started.
        val rosaries = sessions.filter { session ->
            LocalDate.ofInstant(Instant.ofEpochMilli(session.startedAtEpochMs), zone) == day
        }.map { session ->
            JourneyDayEntry(
                id = session.id,
                kind = JourneyDayEntry.Kind.Rosary,
                mysterySet = session.mysterySet,
                startedAtEpochMs = session.startedAtEpochMs,
                completedAtEpochMs = session.completedAtEpochMs,
                duration = JourneyDuration.reliable(session.duration),
                intentionTitles = (session.intentionTitles ?: emptyList()).ifEmpty {
                    listOfNotNull(session.intentionTitle)
                },
            )
        }
        val decadeEntries = decades.filter { decade ->
            belongsToStartDay(decade.startedAtEpochMs, decade.completedAtEpochMs)
        }.map { decade ->
            JourneyDayEntry(
                id = decade.id,
                kind = JourneyDayEntry.Kind.Decade,
                mysterySet = decade.mysterySet?.let { raw ->
                    MysterySetKind.entries.firstOrNull { it.name.equals(raw, ignoreCase = true) }
                },
                startedAtEpochMs = decade.startedAtEpochMs,
                completedAtEpochMs = decade.completedAtEpochMs,
                duration = JourneyDuration.reliable(decade.duration),
                intentionTitles = decade.intentionTitles,
            )
        }
        val result = (rosaries + decadeEntries).toMutableList()
        if (result.isEmpty() && dayKey in prayedDayKeys) {
            result += JourneyDayEntry(
                id = "day-$dayKey",
                kind = JourneyDayEntry.Kind.RecordedDay,
                mysterySet = null,
                startedAtEpochMs = null,
                completedAtEpochMs = null,
                duration = null,
                intentionTitles = emptyList(),
            )
        }
        return result.sortedWith(
            compareBy<JourneyDayEntry> { it.completedAtEpochMs ?: Long.MIN_VALUE }
                .thenBy { it.id },
        )
    }

    fun totalDuration(entries: List<JourneyDayEntry>): Double? {
        val known = entries.mapNotNull { it.duration }
        return if (known.isEmpty()) null else known.sum()
    }

    /**
     * Locale-aware abbreviated heading, e.g. "Wed, 11 Nov 2026" in en-AU.
     * Shortened on 11 Nov 2026 to drop the long weekday and the extra intention preamble.
     */
    fun heading(date: LocalDate, locale: Locale = Locale.forLanguageTag("en-AU")): String {
        val formatter = DateTimeFormatter.ofPattern("EEE, d MMM yyyy", locale)
        return date.format(formatter)
    }

    /** Intention line under a day's prayer: titles only, joined, matching the shortened 11 Nov copy. */
    fun intentionLine(titles: List<String>): String? = countText(titles)

    /** "A", "A and B", "A, B and C". */
    fun summary(titles: List<String>): String? {
        val cleaned = titles.map { it.trim() }.filter { it.isNotEmpty() }
        return when (cleaned.size) {
            0 -> null
            1 -> cleaned[0]
            else -> cleaned.dropLast(1).joinToString(", ") + " and " + cleaned.last()
        }
    }

    /** "1 intention" / "N intentions"; nil when none were offered. Shortened 11 Nov 2026 line. */
    fun countText(titles: List<String>): String? {
        val cleaned = titles.map { it.trim() }.filter { it.isNotEmpty() }
        return when (cleaned.size) {
            0 -> null
            1 -> "1 intention"
            else -> "${cleaned.size} intentions"
        }
    }
}
