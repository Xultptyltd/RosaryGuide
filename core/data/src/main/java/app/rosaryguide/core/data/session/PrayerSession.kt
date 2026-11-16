package app.rosaryguide.core.data.session

import app.rosaryguide.core.data.config.RosaryJson
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.data.sequence.RosarySequenceBuilder
import app.rosaryguide.core.model.RosaryConfig
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import kotlinx.serialization.Serializable

@Serializable
data class PrayerSession(
    val id: String = UUID.randomUUID().toString(),
    val mysterySet: MysterySetKind,
    val stepIndex: Int,
    val startedAtEpochMs: Long,
    val updatedAtEpochMs: Long,
    val activeDuration: Double = 0.0,
    val completedDecades: Set<Int> = emptySet(),
    val lastCompletedDecadeActiveDuration: Double = 0.0,
    val includeSaintMichael: Boolean = false,
    val language: PrayerLanguage = PrayerLanguage.English,
    val intentionIds: List<String> = emptyList(),
    val intentionTitles: List<String> = emptyList(),
    val intentionId: String? = null,
    val intentionTitle: String? = null,
    val intentionCategory: IntentionCategory? = null,
    val intentionSourceId: String? = null,
    val rosaryConfig: RosaryConfig = RosaryConfig.default,
    val timingRunningSinceEpochMs: Long? = null,
    val timingLastInteractionEpochMs: Long? = null,
) {
    val allIntentionTitles: List<String>
        get() = OfferedIntentions.titles(intentionTitles, intentionTitle)

    fun normalized(): PrayerSession {
        val ids = (intentionIds.ifEmpty { listOfNotNull(intentionId) }).take(MAX_INTENTIONS)
        val titles = (intentionTitles.ifEmpty { listOfNotNull(intentionTitle) }).take(MAX_INTENTIONS)
        return copy(
            intentionIds = ids,
            intentionTitles = titles,
            intentionId = ids.firstOrNull(),
            intentionTitle = titles.firstOrNull(),
        )
    }

    /**
     * A Rosary can be resumed on the day it was started, and after midnight
     * while it is still fresh ([OVERNIGHT_RESUME_WINDOW_MS] after the last bead).
     */
    fun isResumable(nowEpochMs: Long, zone: ZoneId = ZoneId.systemDefault()): Boolean {
        val startedDay = LocalDate.ofInstant(Instant.ofEpochMilli(startedAtEpochMs), zone)
        val nowDay = LocalDate.ofInstant(Instant.ofEpochMilli(nowEpochMs), zone)
        if (startedDay == nowDay) return true
        if (startedDay != nowDay.minusDays(1)) return false
        return nowEpochMs - updatedAtEpochMs < OVERNIGHT_RESUME_WINDOW_MS
    }

    fun continueCTATitle(): String {
        val steps = RosarySequenceBuilder.build(mysterySet, rosaryConfig)
        if (steps.isEmpty()) return "Continue"
        val idx = stepIndex.coerceIn(0, steps.lastIndex)
        return "Continue — ${steps[idx].stage.continuePhrase}"
    }

    companion object {
        const val MAX_INTENTIONS = 5
        const val OVERNIGHT_RESUME_WINDOW_MS = 6 * 60 * 60 * 1000L

        fun create(
            mysterySet: MysterySetKind,
            stepIndex: Int,
            startedAtEpochMs: Long,
            updatedAtEpochMs: Long,
            includeSaintMichael: Boolean = false,
            language: PrayerLanguage = PrayerLanguage.English,
            intentionId: String? = null,
            intentionTitle: String? = null,
            intentionIds: List<String>? = null,
            intentionTitles: List<String>? = null,
            intentionCategory: IntentionCategory? = null,
            intentionSourceId: String? = null,
            rosaryConfig: RosaryConfig = RosaryConfig.default,
            id: String = UUID.randomUUID().toString(),
            activeDuration: Double = 0.0,
            completedDecades: Set<Int> = emptySet(),
        ): PrayerSession = PrayerSession(
            id = id,
            mysterySet = mysterySet,
            stepIndex = stepIndex,
            startedAtEpochMs = startedAtEpochMs,
            updatedAtEpochMs = updatedAtEpochMs,
            activeDuration = activeDuration,
            completedDecades = completedDecades,
            includeSaintMichael = includeSaintMichael,
            language = language,
            intentionIds = intentionIds ?: emptyList(),
            intentionTitles = intentionTitles ?: emptyList(),
            intentionId = intentionId,
            intentionTitle = intentionTitle,
            intentionCategory = intentionCategory,
            intentionSourceId = intentionSourceId,
            rosaryConfig = rosaryConfig,
        ).normalized()
    }
}

@Serializable
data class CompletedPrayerSession(
    val id: String = UUID.randomUUID().toString(),
    val sessionId: String? = null,
    val mysterySet: MysterySetKind,
    val startedAtEpochMs: Long,
    val completedAtEpochMs: Long,
    val duration: Double,
    val intentionId: String? = null,
    val intentionTitle: String? = null,
    val intentionCategory: IntentionCategory? = null,
    val intentionSourceId: String? = null,
    val intentionIds: List<String>? = null,
    val intentionTitles: List<String>? = null,
) {
    val allIntentionTitles: List<String>
        get() = OfferedIntentions.titles(intentionTitles, intentionTitle)
}

fun PrayerSession.toJson(): String = RosaryJson.encodeToString(PrayerSession.serializer(), normalized())

fun decodePrayerSession(json: String): PrayerSession =
    RosaryJson.decodeFromString(PrayerSession.serializer(), json).normalized()
