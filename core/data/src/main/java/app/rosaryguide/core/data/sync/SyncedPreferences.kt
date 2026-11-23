package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.notify.TimeOfDay
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.PrayerTextSize
import app.rosaryguide.core.model.RosaryConfig
import kotlinx.serialization.Serializable

/**
 * `/users/{uid}/meta/preferences`. Port of iOS `SyncedPreferences`.
 *
 * Android does not show every synced preference yet (prayer and Rosary language, text size).
 * Those still round-trip: the device keeps the last account value and its change time, so an
 * Android device never resets what an iPhone chose.
 */
@Serializable
data class SyncedPreferences(
    val appearance: AppearancePreference = AppearancePreference.System,
    val prayerLanguage: PrayerLanguage = PrayerLanguage.English,
    val rosaryLanguage: PrayerLanguage = PrayerLanguage.English,
    val textSize: PrayerTextSize = PrayerTextSize.Medium,
    val includeSaintMichael: Boolean = false,
    val hideIntentionText: Boolean = false,
    val dailyReminderEnabled: Boolean = true,
    val dailyReminderMinutes: Int = TimeOfDay.DEFAULT_REMINDER_MINUTES,
    val feastAlertsEnabled: Boolean = true,
    val feastAlertMinutes: Int = TimeOfDay.DEFAULT_REMINDER_MINUTES,
    val appIcon: AppIconOption = AppIconOption.Blue,
    /** Last user change to any field; 0 means never (defaults), so any account copy wins. */
    val updatedAt: Long = NEVER,
    /** Null in copies from before Rosary settings synced; those keep the device's settings. */
    val rosaryConfig: RosaryConfig? = null,
    /** Per-field change times keyed by [Field.key]. Missing entries count as [updatedAt]. */
    val fieldUpdatedAt: Map<String, Long> = emptyMap(),
) {
    enum class Field(val key: String) {
        Appearance("appearance"),
        PrayerLanguageField("prayerLanguage"),
        RosaryLanguage("rosaryLanguage"),
        TextSize("textSize"),
        IncludeSaintMichael("includeSaintMichael"),
        HideIntentionText("hideIntentionText"),
        DailyReminderEnabled("dailyReminderEnabled"),
        DailyReminderMinutes("dailyReminderMinutes"),
        FeastAlertsEnabled("feastAlertsEnabled"),
        FeastAlertMinutes("feastAlertMinutes"),
        AppIcon("appIcon"),
        RosaryConfigField("rosaryConfig"),
    }

    /** How much of the document the deployed rules accept (iOS `SyncedPreferences.Schema`). */
    enum class Schema { Full, WithoutFieldTimes, WithoutRosaryConfig }

    fun changedAt(field: Field): Long = fieldUpdatedAt[field.key] ?: updatedAt

    fun normalized(): SyncedPreferences {
        val known = Field.entries.map { it.key }.toSet()
        return copy(
            dailyReminderMinutes = dailyReminderMinutes.coerceIn(0, MAX_MINUTES),
            feastAlertMinutes = feastAlertMinutes.coerceIn(0, MAX_MINUTES),
            fieldUpdatedAt = fieldUpdatedAt.filterKeys { it in known },
        )
    }

    fun stored(schema: Schema): SyncedPreferences {
        var value = normalized()
        if (schema >= Schema.WithoutFieldTimes) value = value.copy(fieldUpdatedAt = emptyMap())
        if (schema >= Schema.WithoutRosaryConfig) value = value.copy(rosaryConfig = null)
        return value
    }

    /** Every field stamped at [now]; used for the first upload of values never stamped. */
    fun stamped(now: Long): SyncedPreferences =
        copy(updatedAt = now, fieldUpdatedAt = Field.entries.associate { it.key to now })

    fun firestoreData(schema: Schema = Schema.Full): Map<String, Any> {
        val data = mutableMapOf<String, Any>(
            "schemaVersion" to 1,
            "appearance" to appearance.wire,
            "prayerLanguage" to prayerLanguage.wire,
            "rosaryLanguage" to rosaryLanguage.wire,
            "textSize" to textSize.wire,
            "includeSaintMichael" to includeSaintMichael,
            "hideIntentionText" to hideIntentionText,
            "dailyReminderEnabled" to dailyReminderEnabled,
            "dailyReminderMinutes" to dailyReminderMinutes.coerceIn(0, MAX_MINUTES),
            "feastAlertsEnabled" to feastAlertsEnabled,
            "feastAlertMinutes" to feastAlertMinutes.coerceIn(0, MAX_MINUTES),
            "appIcon" to appIcon.storageName,
            "updatedAt" to updatedAt.toDate(),
        )
        val config = rosaryConfig
        if (config != null && schema < Schema.WithoutRosaryConfig) {
            data["rosaryConfig"] = config.firestoreData()
        }
        if (fieldUpdatedAt.isNotEmpty() && schema < Schema.WithoutFieldTimes) {
            data["fieldUpdatedAt"] = fieldUpdatedAt.mapValues { it.value.toDate() }
        }
        return data
    }

    companion object {
        const val NEVER = 0L
        private const val MAX_MINUTES = 24 * 60 - 1

        /**
         * Last write wins per field, by each field's own change time; ties go to the account copy.
         * Times from a clock running ahead count as [now] so they cannot win for ever.
         */
        fun merge(local: SyncedPreferences, remote: SyncedPreferences, now: Long): SyncedPreferences {
            val times = mutableMapOf<String, Long>()
            var merged = local.copy(updatedAt = maxOf(local.updatedAt, remote.updatedAt))
            for (field in Field.entries) {
                val localTime = local.changedAt(field)
                val remoteTime = remote.changedAt(field)
                var useRemote = minOf(remoteTime, now) >= minOf(localTime, now)
                if (field == Field.RosaryConfigField) {
                    if (remote.rosaryConfig == null) useRemote = false
                    else if (local.rosaryConfig == null) useRemote = true
                }
                val source = if (useRemote) remote else local
                times[field.key] = if (useRemote) remoteTime else localTime
                merged = when (field) {
                    Field.Appearance -> merged.copy(appearance = source.appearance)
                    Field.PrayerLanguageField -> merged.copy(prayerLanguage = source.prayerLanguage)
                    Field.RosaryLanguage -> merged.copy(rosaryLanguage = source.rosaryLanguage)
                    Field.TextSize -> merged.copy(textSize = source.textSize)
                    Field.IncludeSaintMichael -> merged.copy(includeSaintMichael = source.includeSaintMichael)
                    Field.HideIntentionText -> merged.copy(hideIntentionText = source.hideIntentionText)
                    Field.DailyReminderEnabled -> merged.copy(dailyReminderEnabled = source.dailyReminderEnabled)
                    Field.DailyReminderMinutes -> merged.copy(dailyReminderMinutes = source.dailyReminderMinutes)
                    Field.FeastAlertsEnabled -> merged.copy(feastAlertsEnabled = source.feastAlertsEnabled)
                    Field.FeastAlertMinutes -> merged.copy(feastAlertMinutes = source.feastAlertMinutes)
                    Field.AppIcon -> merged.copy(appIcon = source.appIcon)
                    Field.RosaryConfigField -> merged.copy(rosaryConfig = source.rosaryConfig)
                }
            }
            return merged.copy(fieldUpdatedAt = times).normalized()
        }

        /** Parses the account document; null when a required field is missing or invalid. */
        fun fromFirestore(data: Map<String, Any?>): SyncedPreferences? {
            val appearance = AppearancePreference.entries.firstOrNull { it.wire == data["appearance"] } ?: return null
            val prayerLanguage = PrayerLanguage.entries.firstOrNull { it.wire == data["prayerLanguage"] } ?: return null
            val rosaryLanguage = PrayerLanguage.entries.firstOrNull { it.wire == data["rosaryLanguage"] } ?: return null
            val textSize = PrayerTextSize.entries.firstOrNull { it.wire == data["textSize"] } ?: return null
            val includeSaintMichael = data["includeSaintMichael"] as? Boolean ?: return null
            val hideIntentionText = data["hideIntentionText"] as? Boolean ?: return null
            val dailyEnabled = data["dailyReminderEnabled"] as? Boolean ?: return null
            val dailyMinutes = data["dailyReminderMinutes"].asInt() ?: return null
            val feastEnabled = data["feastAlertsEnabled"] as? Boolean ?: return null
            val appIconRaw = data["appIcon"] as? String ?: return null
            val appIcon = AppIconOption.entries.firstOrNull { it.storageName == appIconRaw } ?: return null
            val updatedAt = data["updatedAt"].asEpochMs() ?: return null
            return SyncedPreferences(
                appearance = appearance,
                prayerLanguage = prayerLanguage,
                rosaryLanguage = rosaryLanguage,
                textSize = textSize,
                includeSaintMichael = includeSaintMichael,
                hideIntentionText = hideIntentionText,
                dailyReminderEnabled = dailyEnabled,
                dailyReminderMinutes = dailyMinutes,
                feastAlertsEnabled = feastEnabled,
                // Documents written before this field existed get the 9:00 am default.
                feastAlertMinutes = data["feastAlertMinutes"].asInt() ?: TimeOfDay.DEFAULT_REMINDER_MINUTES,
                appIcon = appIcon,
                updatedAt = updatedAt,
                rosaryConfig = data["rosaryConfig"].asMap()?.let(::rosaryConfigFromFirestore),
                fieldUpdatedAt = data["fieldUpdatedAt"].asMap()
                    ?.mapNotNull { (k, v) -> v.asEpochMs()?.let { k to it } }?.toMap()
                    ?: emptyMap(),
            ).normalized()
        }
    }
}

internal val AppearancePreference.wire: String
    get() = when (this) {
        AppearancePreference.System -> "system"
        AppearancePreference.Light -> "light"
        AppearancePreference.Dark -> "dark"
    }

internal val PrayerLanguage.wire: String
    get() = when (this) {
        PrayerLanguage.English -> "english"
        PrayerLanguage.Latin -> "latin"
        PrayerLanguage.Bilingual -> "bilingual"
    }

internal val PrayerTextSize.wire: String
    get() = when (this) {
        PrayerTextSize.Small -> "small"
        PrayerTextSize.Medium -> "medium"
        PrayerTextSize.Large -> "large"
    }

/** Matches `validRosaryConfig` in firestore.rules and iOS `RosaryConfig.firestoreData()`. */
fun RosaryConfig.firestoreData(): Map<String, Any> = mapOf(
    "translation" to translation.firestoreValue,
    "fatimaPrayer" to fatimaPrayer,
    "oSacrament" to oSacrament,
    "closingPrayers" to closingPrayers,
    "memorare" to memorare,
    "saintMichael" to saintMichael,
    "intentionsStep" to intentionsStep,
    "showBeads" to showBeads,
)

fun rosaryConfigFromFirestore(map: Map<String, Any?>): RosaryConfig {
    val base = RosaryConfig()
    return RosaryConfig(
        translation = (map["translation"] as? String)?.let { BibleTranslation.fromStoredValue(it) } ?: base.translation,
        fatimaPrayer = map["fatimaPrayer"] as? Boolean ?: base.fatimaPrayer,
        oSacrament = map["oSacrament"] as? Boolean ?: base.oSacrament,
        closingPrayers = map["closingPrayers"] as? Boolean ?: base.closingPrayers,
        memorare = map["memorare"] as? Boolean ?: base.memorare,
        saintMichael = map["saintMichael"] as? Boolean ?: base.saintMichael,
        intentionsStep = map["intentionsStep"] as? Boolean ?: base.intentionsStep,
        showBeads = map["showBeads"] as? Boolean ?: base.showBeads,
    )
}
