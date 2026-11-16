package app.rosaryguide.core.data.session

import app.rosaryguide.core.data.config.RosaryJson
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryConfig
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.builtins.ListSerializer

interface SessionPreferences {
    fun loadSession(): PrayerSession?
    fun saveSession(session: PrayerSession?)
    fun loadCompletedSessions(): List<CompletedPrayerSession>
    fun saveCompletedSessions(sessions: List<CompletedPrayerSession>)
    fun loadCompletedDayKeys(): Set<String>
    fun saveCompletedDayKeys(keys: Set<String>)
    fun loadIntentions(): List<OfferIntention>
    fun saveIntentions(intentions: List<OfferIntention>)
}

class InMemorySessionPreferences(
    session: PrayerSession? = null,
    completed: List<CompletedPrayerSession> = emptyList(),
    dayKeys: Set<String> = emptySet(),
    intentions: List<OfferIntention> = emptyList(),
) : SessionPreferences {
    private var sessionJson: String? = session?.toJson()
    private var completedJson: String = RosaryJson.encodeToString(
        ListSerializer(CompletedPrayerSession.serializer()),
        completed,
    )
    private var dayKeys: Set<String> = dayKeys
    private var intentionsJson: String = RosaryJson.encodeToString(
        ListSerializer(OfferIntention.serializer()),
        intentions,
    )

    override fun loadSession(): PrayerSession? = sessionJson?.let { decodePrayerSession(it) }
    override fun saveSession(session: PrayerSession?) {
        sessionJson = session?.toJson()
    }
    override fun loadCompletedSessions(): List<CompletedPrayerSession> =
        if (completedJson.isBlank()) emptyList()
        else RosaryJson.decodeFromString(ListSerializer(CompletedPrayerSession.serializer()), completedJson)
    override fun saveCompletedSessions(sessions: List<CompletedPrayerSession>) {
        completedJson = RosaryJson.encodeToString(ListSerializer(CompletedPrayerSession.serializer()), sessions)
    }
    override fun loadCompletedDayKeys(): Set<String> = dayKeys
    override fun saveCompletedDayKeys(keys: Set<String>) { dayKeys = keys }
    override fun loadIntentions(): List<OfferIntention> =
        if (intentionsJson.isBlank()) emptyList()
        else RosaryJson.decodeFromString(ListSerializer(OfferIntention.serializer()), intentionsJson)
    override fun saveIntentions(intentions: List<OfferIntention>) {
        intentionsJson = RosaryJson.encodeToString(ListSerializer(OfferIntention.serializer()), intentions)
    }
}

/**
 * In-progress Rosary plus completed history, ported from the persistence surface of
 * iOS `SessionStore` (no account sync or milestones in M3).
 */
class SessionStore(
    private val prefs: SessionPreferences = InMemorySessionPreferences(),
    private val zone: ZoneId = ZoneId.systemDefault(),
    private val clock: () -> Long = { System.currentTimeMillis() },
) {
    private val _session = MutableStateFlow(prefs.loadSession()?.normalized())
    val session: StateFlow<PrayerSession?> = _session.asStateFlow()

    private val _completedSessions = MutableStateFlow(prefs.loadCompletedSessions())
    val completedSessions: StateFlow<List<CompletedPrayerSession>> = _completedSessions.asStateFlow()

    private val _completedDayKeys = MutableStateFlow(prefs.loadCompletedDayKeys())
    val completedDayKeys: StateFlow<Set<String>> = _completedDayKeys.asStateFlow()

    private val _intentions = MutableStateFlow(prefs.loadIntentions())
    val intentions: StateFlow<List<OfferIntention>> = _intentions.asStateFlow()

    val current: PrayerSession? get() = _session.value
    val completed: List<CompletedPrayerSession> get() = _completedSessions.value

    fun start(
        set: MysterySetKind,
        language: PrayerLanguage = PrayerLanguage.English,
        intentionIds: List<String> = emptyList(),
        intentionTitles: List<String> = emptyList(),
        intentionCategory: IntentionCategory? = null,
        intentionSourceId: String? = null,
        config: RosaryConfig = RosaryConfig.default,
        nowEpochMs: Long = clock(),
    ): PrayerSession {
        val started = PrayerSession.create(
            mysterySet = set,
            stepIndex = 0,
            startedAtEpochMs = nowEpochMs,
            updatedAtEpochMs = nowEpochMs,
            includeSaintMichael = config.saintMichael,
            language = language,
            intentionIds = intentionIds,
            intentionTitles = intentionTitles,
            intentionCategory = intentionCategory,
            intentionSourceId = intentionSourceId,
            rosaryConfig = config,
        )
        publishSession(started)
        return started
    }

    fun updateStep(index: Int, nowEpochMs: Long = clock()) {
        val current = _session.value ?: return
        publishSession(current.copy(stepIndex = index, updatedAtEpochMs = nowEpochMs))
    }

    fun updateIntentions(
        ids: List<String>,
        titles: List<String>,
        category: IntentionCategory? = null,
        sourceId: String? = null,
        nowEpochMs: Long = clock(),
    ) {
        val current = _session.value ?: return
        publishSession(
            current.copy(
                intentionIds = ids,
                intentionTitles = titles,
                intentionId = ids.firstOrNull(),
                intentionTitle = titles.firstOrNull(),
                intentionCategory = category,
                intentionSourceId = sourceId,
                updatedAtEpochMs = nowEpochMs,
            ).normalized(),
        )
    }

    fun updateRosaryConfig(config: RosaryConfig) {
        val current = _session.value ?: return
        publishSession(current.copy(rosaryConfig = config, includeSaintMichael = config.saintMichael))
    }

    fun recordCompletedDecade(decade: Int) {
        val current = _session.value ?: return
        publishSession(current.copy(completedDecades = current.completedDecades + decade))
    }

    fun complete(nowEpochMs: Long = clock()): CompletedPrayerSession? {
        val current = _session.value ?: return null
        val durationSeconds = if (current.activeDuration > 0) {
            current.activeDuration
        } else {
            ((nowEpochMs - current.startedAtEpochMs).coerceAtLeast(0) / 1000.0)
        }
        val record = CompletedPrayerSession(
            id = UUID.randomUUID().toString(),
            sessionId = current.id,
            mysterySet = current.mysterySet,
            startedAtEpochMs = current.startedAtEpochMs,
            completedAtEpochMs = nowEpochMs,
            duration = durationSeconds,
            intentionId = current.intentionId,
            intentionTitle = current.intentionTitle,
            intentionCategory = current.intentionCategory,
            intentionSourceId = current.intentionSourceId,
            intentionIds = current.intentionIds,
            intentionTitles = current.intentionTitles,
        )
        val day = LocalDate.ofInstant(Instant.ofEpochMilli(current.startedAtEpochMs), zone).toString()
        _completedSessions.value = listOf(record) + _completedSessions.value
        _completedDayKeys.value = _completedDayKeys.value + day
        prefs.saveCompletedSessions(_completedSessions.value)
        prefs.saveCompletedDayKeys(_completedDayKeys.value)
        publishSession(null)
        return record
    }

    fun discard() {
        publishSession(null)
    }

    fun addIntention(title: String, category: IntentionCategory = IntentionCategory.Personal): OfferIntention {
        val intention = OfferIntention(
            id = UUID.randomUUID().toString(),
            title = title.trim(),
            category = category,
            createdAtEpochMs = clock(),
        )
        _intentions.value = listOf(intention) + _intentions.value
        prefs.saveIntentions(_intentions.value)
        return intention
    }

    fun removeIntention(id: String) {
        _intentions.value = _intentions.value.filterNot { it.id == id }
        prefs.saveIntentions(_intentions.value)
    }

    private fun publishSession(session: PrayerSession?) {
        _session.value = session
        prefs.saveSession(session)
    }
}

fun decodeCompletedSessions(json: String): List<CompletedPrayerSession> =
    RosaryJson.decodeFromString(ListSerializer(CompletedPrayerSession.serializer()), json)
