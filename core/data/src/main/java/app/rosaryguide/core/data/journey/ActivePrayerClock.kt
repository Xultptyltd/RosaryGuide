package app.rosaryguide.core.data.journey

import kotlinx.serialization.Serializable

/**
 * Caps idle gaps at ten minutes. Ported from iOS `ActivePrayerClock`.
 */
data class ActivePrayerClock(
    val runningSinceEpochMs: Long? = null,
    val lastInteractionEpochMs: Long? = null,
) {
    val isRunning: Boolean get() = runningSinceEpochMs != null

    fun resume(nowEpochMs: Long): ActivePrayerClock {
        if (runningSinceEpochMs != null) return this
        return ActivePrayerClock(runningSinceEpochMs = nowEpochMs, lastInteractionEpochMs = nowEpochMs)
    }

    fun touch(nowEpochMs: Long): ActivePrayerClock {
        if (runningSinceEpochMs == null) return this
        return copy(lastInteractionEpochMs = nowEpochMs)
    }

    /** Banks time so far and times on from [nowEpochMs] with a fresh idle allowance. */
    fun step(nowEpochMs: Long): Pair<ActivePrayerClock, Double> {
        if (!isRunning) return this to 0.0
        val (paused, credited) = take(nowEpochMs, keepRunning = false)
        return paused.resume(nowEpochMs) to credited
    }

    fun take(nowEpochMs: Long, keepRunning: Boolean): Pair<ActivePrayerClock, Double> {
        val start = runningSinceEpochMs ?: return this to 0.0
        val last = lastInteractionEpochMs ?: start
        val idleEnd = last + IDLE_LIMIT_MS
        val end = minOf(nowEpochMs, idleEnd)
        val credited = maxOf(0.0, (end - start) / 1000.0)
        val next = if (keepRunning) {
            val anchor = maxOf(minOf(nowEpochMs, idleEnd), start)
            ActivePrayerClock(runningSinceEpochMs = anchor, lastInteractionEpochMs = lastInteractionEpochMs)
        } else {
            ActivePrayerClock()
        }
        val safe = if (credited.isFinite()) credited else 0.0
        return next to safe
    }

    companion object {
        const val IDLE_LIMIT_SECONDS = 10 * 60.0
        const val IDLE_LIMIT_MS = 10 * 60 * 1000L
    }
}

/**
 * Duration display rules for the Rhythm / History screens.
 * Ported from iOS `JourneyDuration`.
 */
object JourneyDuration {
    const val LONGEST_PLAUSIBLE_SECONDS = 3 * 60 * 60.0
    const val LONGEST_DAY_SECONDS = 12 * 60 * 60.0

    fun reliable(duration: Double?): Double? {
        val value = duration ?: return null
        if (!value.isFinite() || value < 1.0 || value > LONGEST_PLAUSIBLE_SECONDS) return null
        return value
    }

    fun dayTotal(duration: Double): Double {
        if (!duration.isFinite()) return 0.0
        return duration.coerceIn(0.0, LONGEST_DAY_SECONDS)
    }

    /** "Under a minute", "1 min", "18 mins", "1 hr", "1 hr 5 mins". */
    fun text(duration: Double): String {
        val minutes = kotlin.math.round(duration / 60.0).toInt()
        if (minutes < 1) return "Under a minute"
        if (minutes < 60) return if (minutes == 1) "1 min" else "$minutes mins"
        val hours = minutes / 60
        val rest = minutes % 60
        val hourText = if (hours == 1) "1 hr" else "$hours hrs"
        if (rest == 0) return hourText
        val restText = if (rest == 1) "1 min" else "$rest mins"
        return "$hourText $restText"
    }
}

@Serializable
data class CompletedDecadeSession(
    val id: String,
    val decade: Int,
    val mysterySet: String? = null,
    val startedAtEpochMs: Long? = null,
    val completedAtEpochMs: Long,
    val duration: Double? = null,
    val intentionTitles: List<String> = emptyList(),
)

@Serializable
data class JourneyAward(
    val dateEpochMs: Long,
    val detail: String,
)

@Serializable
data class JourneyState(
    val completedDecades: List<CompletedDecadeSession> = emptyList(),
    val prayerTimeByDay: Map<String, Double> = emptyMap(),
    val awards: Map<String, JourneyAward> = emptyMap(),
    val hideIntentionText: Boolean = false,
)
