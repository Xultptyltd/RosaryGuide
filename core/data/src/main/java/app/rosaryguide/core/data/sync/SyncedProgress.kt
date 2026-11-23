package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.session.CompletedPrayerSession
import app.rosaryguide.core.data.session.IntentionCategory
import app.rosaryguide.core.data.session.PrayerSession
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryConfig
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlinx.serialization.Serializable

/**
 * `/users/{uid}/meta/progress`: prayed days, finished Rosaries and the in-progress Rosary.
 * Port of iOS `SyncedProgress`.
 */
@Serializable
data class SyncedProgress(
    val completedDays: Set<String> = emptySet(),
    val session: PrayerSession? = null,
    val sessionChangedAt: Long = SyncedPreferences.NEVER,
    val historyResetAt: Long? = null,
    /** Null when this copy does not carry them; null never removes anything. */
    val rosaries: List<CompletedPrayerSession>? = null,
) {
    enum class Schema { Full, WithoutRosaries, WithoutSessionExtras }

    fun normalized(now: Long, zone: ZoneId): SyncedProgress {
        val cutoff = cutoffDayKey(now, zone)
        val session = session?.let { s ->
            s.copy(
                intentionIds = s.intentionIds.take(PrayerSession.MAX_INTENTIONS),
                intentionTitles = s.intentionTitles.take(PrayerSession.MAX_INTENTIONS).map { it.take(160) },
            )
        }
        return copy(
            completedDays = completedDays.filter { isDayKey(it) && it >= cutoff }.toSet(),
            session = session,
            rosaries = rosaries?.let { normalizedRosaries(it, cutoff, zone) },
        )
    }

    fun stored(schema: Schema, now: Long, zone: ZoneId): SyncedProgress {
        var value = normalized(now, zone)
        if (schema >= Schema.WithoutRosaries) value = value.copy(rosaries = null)
        val s = value.session
        if (schema >= Schema.WithoutSessionExtras && s != null) {
            value = value.copy(
                session = s.copy(
                    intentionIds = s.intentionIds.take(1),
                    intentionTitles = s.intentionTitles.take(1),
                    rosaryConfig = RosaryConfig.default,
                ),
            )
        }
        return value
    }

    /** Account fields compared for "does it need uploading?" and "did anything change?". */
    fun comparable(schema: Schema, now: Long, zone: ZoneId): SyncedProgress {
        val value = stored(schema, now, zone)
        return value.copy(
            session = value.session?.let { s -> wireSession(s) },
            rosaries = value.rosaries?.map { wireRosary(it) }?.sortedBy { it.id },
        )
    }

    /**
     * An account document written before the in-progress Rosary carried its intention list and
     * Rosary settings has neither key. For the same Rosary keep what this device knows.
     */
    fun fillingSessionFields(missingIn: Map<String, Any?>, local: PrayerSession?, now: Long, zone: ZoneId): SyncedProgress {
        val incoming = session ?: return this
        local ?: return this
        val map = missingIn["session"].asMap() ?: return this
        if (incoming.startedAtEpochMs != local.startedAtEpochMs ||
            incoming.mysterySet != local.mysterySet ||
            incoming.intentionId?.let(SyncIds::canonical) != local.intentionId?.let(SyncIds::canonical)
        ) return this
        var filled = incoming
        if (map["intentionIds"] == null) {
            filled = filled.copy(intentionIds = local.intentionIds, intentionTitles = local.intentionTitles)
        }
        if (map["rosaryConfig"] == null) filled = filled.copy(rosaryConfig = local.rosaryConfig)
        return copy(session = filled).normalized(now, zone)
    }

    fun firestoreData(schema: Schema, now: Long, zone: ZoneId): Map<String, Any> {
        val value = normalized(now, zone)
        val data = mutableMapOf<String, Any>(
            "schemaVersion" to 1,
            "completedDays" to value.completedDays.sorted().takeLast(MAX_DAYS),
            "sessionChangedAt" to value.sessionChangedAt.toDate(),
            "updatedAt" to now.toDate(),
        )
        value.historyResetAt?.let { data["historyResetAt"] = it.toDate() }
        value.session?.let { s ->
            val ids = s.intentionIds.map(SyncIds::canonical).filter(SyncIds::isUuid)
            val map = mutableMapOf<String, Any>(
                "mysterySet" to s.mysterySet.wire,
                "stepIndex" to s.stepIndex.coerceIn(0, 500),
                "startedAt" to s.startedAtEpochMs.toDate(),
                "updatedAt" to s.updatedAtEpochMs.toDate(),
                "includeSaintMichael" to s.includeSaintMichael,
                "language" to s.language.wire,
            )
            // The single keys stay for older builds, which read only those.
            s.intentionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid)?.let { map["intentionId"] = it }
            s.intentionTitle?.let { map["intentionTitle"] = it.take(160) }
            if (schema < Schema.WithoutSessionExtras) {
                map["intentionIds"] = ids.distinct()
                map["intentionTitles"] = s.intentionTitles
                map["rosaryConfig"] = s.rosaryConfig.firestoreData()
            }
            data["session"] = map
        }
        val rosaries = value.rosaries
        if (rosaries != null && schema < Schema.WithoutRosaries) {
            data["rosaries"] = rosaries.associate { SyncIds.canonical(it.id) to it.firestoreData() }
        }
        return data
    }

    companion object {
        const val HISTORY_WINDOW_DAYS = 366L
        const val MAX_ROSARIES = 1500
        private const val MAX_DAYS = 400
        private val dayKeyPattern = Regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")

        fun isDayKey(key: String): Boolean =
            dayKeyPattern.matches(key) && runCatching { LocalDate.parse(key) }.isSuccess

        fun dayKey(epochMs: Long, zone: ZoneId): String =
            LocalDate.ofInstant(Instant.ofEpochMilli(epochMs), zone).toString()

        fun cutoffDayKey(now: Long, zone: ZoneId): String =
            LocalDate.ofInstant(Instant.ofEpochMilli(now), zone).minusDays(HISTORY_WINDOW_DAYS).toString()

        /** The day a finished Rosary counts for: the day it was started. */
        fun creditedDayKey(record: CompletedPrayerSession, zone: ZoneId): String =
            dayKey(record.startedAtEpochMs, zone)

        /** One record per id (the first wins), newest first, inside the history window. */
        fun normalizedRosaries(records: List<CompletedPrayerSession>, cutoff: String, zone: ZoneId): List<CompletedPrayerSession> {
            val seen = mutableSetOf<String>()
            val result = records.filter { seen.add(SyncIds.canonical(it.id)) }
                .filter { dayKey(it.completedAtEpochMs, zone) >= cutoff }
                .map { r ->
                    r.copy(
                        duration = maxOf(0.0, Math.round(r.duration * 1000) / 1000.0),
                        intentionTitle = r.intentionTitle?.take(160),
                        intentionIds = r.intentionIds?.take(PrayerSession.MAX_INTENTIONS),
                        intentionTitles = r.intentionTitles?.take(PrayerSession.MAX_INTENTIONS)?.map { it.take(160) },
                    )
                }
                .sortedWith(compareByDescending<CompletedPrayerSession> { it.completedAtEpochMs }.thenBy { SyncIds.canonical(it.id) })
            return result.take(MAX_ROSARIES)
        }

        /**
         * Prayed days are a union (minus anything wiped by the newest "Clear app history").
         * The in-progress Rosary is last write wins; ties go to the account copy.
         */
        fun merge(local: SyncedProgress, remote: SyncedProgress, now: Long, zone: ZoneId): SyncedProgress {
            val reset = listOfNotNull(local.historyResetAt, remote.historyResetAt).maxOrNull()
            fun contribution(p: SyncedProgress): Set<String> {
                if (reset == null || (p.historyResetAt ?: Long.MIN_VALUE) >= reset) return p.completedDays
                val resetDay = dayKey(reset, zone)
                return p.completedDays.filter { it > resetDay }.toSet()
            }
            val newer = if (remote.sessionChangedAt >= local.sessionChangedAt) remote else local
            val session = newer.session?.takeIf { it.isResumable(now, zone) }
            val rosaries = if (local.rosaries != null || remote.rosaries != null) {
                ((local.rosaries ?: emptyList()) + (remote.rosaries ?: emptyList()))
                    .filter { r -> reset == null || r.completedAtEpochMs > reset }
            } else {
                null
            }
            val days = (contribution(local) + contribution(remote)).toMutableSet()
            rosaries?.forEach { days += creditedDayKey(it, zone) }
            return SyncedProgress(
                completedDays = days,
                session = session,
                sessionChangedAt = newer.sessionChangedAt,
                historyResetAt = reset,
                rosaries = rosaries,
            ).normalized(now, zone)
        }

        fun fromFirestore(data: Map<String, Any?>, now: Long, zone: ZoneId): SyncedProgress? {
            val days = data["completedDays"].asStringList() ?: return null
            val changedAt = data["sessionChangedAt"].asEpochMs() ?: return null
            val session = data["session"].asMap()?.let(::sessionFromFirestore)
            val rosaries = data["rosaries"].asMap()?.mapNotNull { (key, value) ->
                value.asMap()?.let { rosaryFromFirestore(key, it) }
            }
            return SyncedProgress(
                completedDays = days.toSet(),
                session = session,
                sessionChangedAt = changedAt,
                historyResetAt = data["historyResetAt"].asEpochMs(),
                rosaries = rosaries,
            ).normalized(now, zone)
        }

        private fun sessionFromFirestore(map: Map<String, Any?>): PrayerSession? {
            val set = MysterySetKind.entries.firstOrNull { it.wire == map["mysterySet"] } ?: return null
            val step = map["stepIndex"].asInt() ?: return null
            val startedAt = map["startedAt"].asEpochMs() ?: return null
            val updatedAt = map["updatedAt"].asEpochMs() ?: return null
            val saintMichael = map["includeSaintMichael"] as? Boolean ?: return null
            val language = PrayerLanguage.entries.firstOrNull { it.wire == map["language"] } ?: return null
            return PrayerSession.create(
                mysterySet = set,
                stepIndex = step,
                startedAtEpochMs = startedAt,
                updatedAtEpochMs = updatedAt,
                includeSaintMichael = saintMichael,
                language = language,
                intentionId = (map["intentionId"] as? String)?.takeIf(SyncIds::isUuid)?.let(SyncIds::canonical),
                intentionTitle = map["intentionTitle"] as? String,
                intentionIds = map["intentionIds"].asStringList()?.filter(SyncIds::isUuid)?.map(SyncIds::canonical),
                intentionTitles = map["intentionTitles"].asStringList(),
                rosaryConfig = map["rosaryConfig"].asMap()?.let(::rosaryConfigFromFirestore) ?: RosaryConfig.default,
            )
        }

        private fun rosaryFromFirestore(key: String, data: Map<String, Any?>): CompletedPrayerSession? {
            if (!SyncIds.isUuid(key)) return null
            val set = MysterySetKind.entries.firstOrNull { it.wire == data["mysterySet"] } ?: return null
            val startedAt = data["startedAt"].asEpochMs() ?: return null
            val completedAt = data["completedAt"].asEpochMs() ?: return null
            return CompletedPrayerSession(
                id = SyncIds.canonical(key),
                sessionId = (data["sessionId"] as? String)?.takeIf(SyncIds::isUuid)?.let(SyncIds::canonical),
                mysterySet = set,
                startedAtEpochMs = startedAt,
                completedAtEpochMs = completedAt,
                duration = data["duration"].asDouble() ?: 0.0,
                intentionId = (data["intentionId"] as? String)?.takeIf(SyncIds::isUuid)?.let(SyncIds::canonical),
                intentionTitle = data["intentionTitle"] as? String,
                intentionCategory = IntentionCategory.fromStorage(data["intentionCategory"] as? String),
                intentionSourceId = data["intentionSourceId"] as? String,
                intentionIds = data["intentionIds"].asStringList()?.filter(SyncIds::isUuid)?.map(SyncIds::canonical),
                intentionTitles = data["intentionTitles"].asStringList(),
            )
        }

        /** Only the fields the account stores, so local-only fields never count as changes. */
        private fun wireSession(s: PrayerSession): PrayerSession = PrayerSession(
            id = "",
            mysterySet = s.mysterySet,
            stepIndex = s.stepIndex.coerceIn(0, 500),
            startedAtEpochMs = s.startedAtEpochMs,
            updatedAtEpochMs = s.updatedAtEpochMs,
            includeSaintMichael = s.includeSaintMichael,
            language = s.language,
            intentionIds = s.intentionIds.map(SyncIds::canonical).filter(SyncIds::isUuid),
            intentionTitles = s.intentionTitles,
            intentionId = s.intentionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid),
            intentionTitle = s.intentionTitle,
            rosaryConfig = s.rosaryConfig,
        )

        private fun wireRosary(r: CompletedPrayerSession): CompletedPrayerSession = r.copy(
            id = SyncIds.canonical(r.id),
            sessionId = r.sessionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid),
            intentionId = r.intentionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid),
            intentionIds = r.intentionIds?.map(SyncIds::canonical)?.filter(SyncIds::isUuid),
        )
    }
}

internal val MysterySetKind.wire: String
    get() = when (this) {
        MysterySetKind.Joyful -> "joyful"
        MysterySetKind.Sorrowful -> "sorrowful"
        MysterySetKind.Glorious -> "glorious"
        MysterySetKind.Luminous -> "luminous"
    }

/** One finished Rosary in `progress.rosaries`, keyed by its id. */
fun CompletedPrayerSession.firestoreData(): Map<String, Any> {
    val map = mutableMapOf<String, Any>(
        "mysterySet" to mysterySet.wire,
        "startedAt" to startedAtEpochMs.toDate(),
        "completedAt" to completedAtEpochMs.toDate(),
        "duration" to duration,
    )
    sessionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid)?.let { map["sessionId"] = it }
    intentionId?.let(SyncIds::canonical)?.takeIf(SyncIds::isUuid)?.let { map["intentionId"] = it }
    intentionTitle?.let { map["intentionTitle"] = it }
    intentionCategory?.let { map["intentionCategory"] = it.storageName }
    intentionSourceId?.let { map["intentionSourceId"] = it }
    intentionIds?.let { ids -> map["intentionIds"] = ids.map(SyncIds::canonical).filter(SyncIds::isUuid) }
    intentionTitles?.let { map["intentionTitles"] = it }
    return map
}
