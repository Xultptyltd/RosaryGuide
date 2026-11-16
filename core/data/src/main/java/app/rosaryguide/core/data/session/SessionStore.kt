package app.rosaryguide.core.data.session

import app.rosaryguide.core.data.config.RosaryJson
import app.rosaryguide.core.data.journey.ActivePrayerClock
import app.rosaryguide.core.data.journey.CompletedDecadeSession
import app.rosaryguide.core.data.journey.JourneyAward
import app.rosaryguide.core.data.journey.JourneyDuration
import app.rosaryguide.core.data.journey.JourneyMilestones
import app.rosaryguide.core.data.journey.JourneyState
import app.rosaryguide.core.data.journey.PrayerRhythm
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
    fun loadJourneyState(): JourneyState
    fun saveJourneyState(state: JourneyState)
}

class InMemorySessionPreferences(
    session: PrayerSession? = null,
    completed: List<CompletedPrayerSession> = emptyList(),
    dayKeys: Set<String> = emptySet(),
    intentions: List<OfferIntention> = emptyList(),
    journey: JourneyState = JourneyState(),
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
    private var journeyState: JourneyState = journey

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
    override fun loadJourneyState(): JourneyState = journeyState
    override fun saveJourneyState(state: JourneyState) { journeyState = state }
}

/**
 * In-progress Rosary plus completed history, prayer clock, journey awards and
 * intention CRUD, ported from the persistence surface of iOS `SessionStore`
 * (account sync is M5).
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

    private val _journey = MutableStateFlow(prefs.loadJourneyState())
    val journey: StateFlow<JourneyState> = _journey.asStateFlow()

    private var clockState: ActivePrayerClock = ActivePrayerClock()

    val current: PrayerSession? get() = _session.value
    val completed: List<CompletedPrayerSession> get() = _completedSessions.value
    val completedDecades: List<CompletedDecadeSession> get() = _journey.value.completedDecades
    val prayerTimeByDay: Map<String, Double> get() = _journey.value.prayerTimeByDay
    val hideIntentionText: Boolean get() = _journey.value.hideIntentionText
    val activeIntentions: List<OfferIntention> get() = _intentions.value.filter { !it.isArchived }
    val archivedIntentions: List<OfferIntention> get() = _intentions.value.filter { it.isArchived }

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
        clockState = ActivePrayerClock().resume(nowEpochMs)
        publishSession(started)
        return started
    }

    fun updateStep(index: Int, nowEpochMs: Long = clock()) {
        val current = _session.value ?: return
        val (nextClock, credited) = clockState.step(nowEpochMs)
        clockState = nextClock
        publishSession(
            current.copy(
                stepIndex = index,
                updatedAtEpochMs = nowEpochMs,
                activeDuration = current.activeDuration + credited,
            ),
        )
    }

    fun touchClock(nowEpochMs: Long = clock()) {
        clockState = clockState.touch(nowEpochMs)
    }

    fun resumeClock(nowEpochMs: Long = clock()) {
        clockState = clockState.resume(nowEpochMs)
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

    /**
     * Records a standalone decade when its closing prayer is left, matching iOS
     * `recordCompletedDecadeIfNeeded`. A later full-Rosary complete removes these
     * partials via [removePartialDecades].
     */
    fun recordCompletedDecadeIfNeeded(decade: Int, nowEpochMs: Long = clock()) {
        val current = _session.value ?: return
        if (decade !in 1..5 || decade in current.completedDecades) return
        val duration = (current.activeDuration).coerceAtLeast(0.0)
        publishSession(current.copy(completedDecades = current.completedDecades + decade, updatedAtEpochMs = nowEpochMs))
        recordStandaloneDecade(
            CompletedDecadeSession(
                id = java.util.UUID.randomUUID().toString(),
                sessionId = current.id,
                decade = decade,
                mysterySet = current.mysterySet.name,
                startedAtEpochMs = current.startedAtEpochMs,
                completedAtEpochMs = nowEpochMs,
                duration = duration,
                intentionTitles = current.allIntentionTitles,
            ),
        )
    }

    fun removePartialDecades(sessionId: String) {
        publishJourney(
            _journey.value.copy(
                completedDecades = _journey.value.completedDecades.filter { it.sessionId != sessionId },
            ),
        )
    }


    fun clearHistoryAndData() {
        clockState = app.rosaryguide.core.data.journey.ActivePrayerClock()
        publishSession(null)
        _completedSessions.value = emptyList()
        _completedDayKeys.value = emptySet()
        prefs.saveCompletedSessions(emptyList())
        prefs.saveCompletedDayKeys(emptySet())
        publishJourney(app.rosaryguide.core.data.journey.JourneyState(hideIntentionText = _journey.value.hideIntentionText))
        _intentions.value = emptyList()
        prefs.saveIntentions(emptyList())
    }

    fun complete(nowEpochMs: Long = clock()): CompletedPrayerSession? {
        val current = _session.value ?: return null
        val (nextClock, credited) = clockState.take(nowEpochMs, keepRunning = false)
        clockState = nextClock
        val timed = current.activeDuration + credited
        val durationSeconds = if (timed > 0) {
            timed
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
        creditDayTime(day, durationSeconds)
        removePartialDecades(record.sessionId ?: current.id)
        publishAwards()
        publishSession(null)
        return record
    }

    fun discard() {
        clockState = ActivePrayerClock()
        publishSession(null)
    }

    fun addIntention(
        title: String,
        note: String? = null,
        category: IntentionCategory = IntentionCategory.Personal,
        accent: IntentionAccent = category.defaultAccent,
        emoji: String? = "🙏",
        pin: Boolean = false,
        sourceId: String? = null,
        expiresAtEpochMs: Long? = null,
        suggestOn: List<String> = emptyList(),
    ): OfferIntention {
        val trimmed = title.trim()
        val cleanNote = note?.trim()?.takeIf { it.isNotEmpty() }
        val cleanEmoji = emoji?.trim()?.takeIf { it.isNotEmpty() } ?: "🙏"
        val intention = OfferIntention(
            id = UUID.randomUUID().toString(),
            title = trimmed.ifEmpty { "Untitled intention" },
            note = cleanNote,
            category = category,
            accent = accent,
            emoji = cleanEmoji,
            sourceId = sourceId,
            isPinned = pin,
            createdAtEpochMs = clock(),
            expiresAtEpochMs = expiresAtEpochMs,
            suggestOn = suggestOn,
        )
        _intentions.value = listOf(intention) + _intentions.value
        prefs.saveIntentions(_intentions.value)
        return intention
    }

    fun updateIntention(updated: OfferIntention) {
        _intentions.value = _intentions.value.map { if (it.id == updated.id) updated else it }
        prefs.saveIntentions(_intentions.value)
    }

    fun setPinned(id: String, pinned: Boolean) {
        _intentions.value = _intentions.value.map { if (it.id == id) it.copy(isPinned = pinned) else it }
        prefs.saveIntentions(_intentions.value)
    }

    fun archiveIntention(id: String, nowEpochMs: Long = clock()) {
        _intentions.value = _intentions.value.map {
            if (it.id == id) it.copy(archivedAtEpochMs = nowEpochMs, isPinned = false) else it
        }
        prefs.saveIntentions(_intentions.value)
    }

    fun unarchiveIntention(id: String) {
        _intentions.value = _intentions.value.map {
            if (it.id == id) it.copy(archivedAtEpochMs = null) else it
        }
        prefs.saveIntentions(_intentions.value)
    }

    fun removeIntention(id: String) {
        _intentions.value = _intentions.value.filterNot { it.id == id }
        prefs.saveIntentions(_intentions.value)
    }

    fun setHideIntentionText(hidden: Boolean) {
        publishJourney(_journey.value.copy(hideIntentionText = hidden))
    }

    fun recordStandaloneDecade(
        decade: CompletedDecadeSession,
        dayKey: String? = null,
    ) {
        val day = dayKey ?: LocalDate.ofInstant(
            Instant.ofEpochMilli(decade.startedAtEpochMs ?: decade.completedAtEpochMs),
            zone,
        ).toString()
        val next = _journey.value.copy(
            completedDecades = listOf(decade) + _journey.value.completedDecades,
        )
        publishJourney(next)
        _completedDayKeys.value = _completedDayKeys.value + day
        prefs.saveCompletedDayKeys(_completedDayKeys.value)
        decade.duration?.let { creditDayTime(day, it) }
        publishAwards()
    }

    fun prayedDayStarts(): Set<Long> =
        _completedDayKeys.value.mapNotNull { key ->
            runCatching { LocalDate.parse(key).atStartOfDay(zone).toEpochSecond() }.getOrNull()
        }.toSet()

    fun rhythm(nowEpochMs: Long = clock(), firstWeekday: Int = 2, locale: java.util.Locale = java.util.Locale.forLanguageTag("en-AU")): PrayerRhythm =
        PrayerRhythm.from(
            prayedDayStarts = prayedDayStarts(),
            now = Instant.ofEpochMilli(nowEpochMs),
            zone = zone,
            firstWeekday = firstWeekday,
            locale = locale,
        )

    fun journeyMilestones(): JourneyMilestones = JourneyMilestones.from(
        rosaryDatesEpochMs = _completedSessions.value.map { it.startedAtEpochMs },
        prayerDatesEpochMs = prayerDates(),
        mysteryDatesEpochMs = mysteryDates(),
        offeringDatesEpochMs = offeringDates(),
        awards = _journey.value.awards,
        zone = zone,
    )

    private fun prayerDates(): List<Long> {
        val fromSessions = _completedSessions.value.map { it.startedAtEpochMs }
        val fromDecades = _journey.value.completedDecades.map { it.startedAtEpochMs ?: it.completedAtEpochMs }
        val fromKeys = _completedDayKeys.value.mapNotNull { key ->
            runCatching { LocalDate.parse(key).atStartOfDay(zone).toInstant().toEpochMilli() }.getOrNull()
        }
        return fromSessions + fromDecades + fromKeys
    }

    private fun mysteryDates(): Map<String, Long> {
        val first = mutableMapOf<String, Long>()
        for (session in _completedSessions.value.sortedBy { it.startedAtEpochMs }) {
            val key = session.mysterySet.name.lowercase()
            if (key !in first) first[key] = session.startedAtEpochMs
        }
        return first
    }

    private fun offeringDates(): Map<String, Long> {
        val first = mutableMapOf<String, Long>()
        for (session in _completedSessions.value.sortedBy { it.startedAtEpochMs }) {
            val keys = mutableSetOf<String>()
            if (session.intentionSourceId?.startsWith("pope-") == true) keys += "papal"
            val categories = listOfNotNull(session.intentionCategory) +
                (session.intentionIds ?: emptyList()).mapNotNull { id -> _intentions.value.firstOrNull { it.id == id }?.category }
            for (category in categories) {
                when (category) {
                    IntentionCategory.Someone -> keys += "someone"
                    IntentionCategory.World -> keys += "world"
                    IntentionCategory.Personal -> Unit
                }
            }
            // Papal source also counts as church & world on iOS? The papal bucket is separate.
            // A papal intention is World + sourceId. Still record papal separately.
            if (session.intentionSourceId?.startsWith("pope-") == true) {
                keys += "papal"
            }
            for (key in keys) {
                if (key !in first) first[key] = session.startedAtEpochMs
            }
        }
        return first
    }

    private fun creditDayTime(day: String, durationSeconds: Double) {
        val credited = JourneyDuration.dayTotal(durationSeconds)
        if (credited <= 0) return
        val times = _journey.value.prayerTimeByDay.toMutableMap()
        times[day] = JourneyDuration.dayTotal((times[day] ?: 0.0) + credited)
        publishJourney(_journey.value.copy(prayerTimeByDay = times))
    }

    private fun publishAwards() {
        val current = journeyMilestones()
        val awards = _journey.value.awards.toMutableMap()
        var changed = false
        for (item in current.items) {
            val earned = item.earnedAtEpochMs ?: continue
            if (item.id !in awards) {
                awards[item.id] = JourneyAward(dateEpochMs = earned, detail = item.description)
                changed = true
            }
        }
        if (changed) publishJourney(_journey.value.copy(awards = awards))
    }

    private fun publishJourney(state: JourneyState) {
        _journey.value = state
        prefs.saveJourneyState(state)
    }

    private fun publishSession(session: PrayerSession?) {
        _session.value = session
        prefs.saveSession(session)
    }
}

fun decodeCompletedSessions(json: String): List<CompletedPrayerSession> =
    RosaryJson.decodeFromString(ListSerializer(CompletedPrayerSession.serializer()), json)
