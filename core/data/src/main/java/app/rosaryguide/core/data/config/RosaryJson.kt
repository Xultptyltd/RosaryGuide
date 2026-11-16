package app.rosaryguide.core.data.config

import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.RosaryConfig
import kotlinx.serialization.json.Json

val RosaryJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = true
    explicitNulls = false
}

fun RosaryConfig.toJsonString(): String = RosaryJson.encodeToString(RosaryConfig.serializer(), this)

fun decodeRosaryConfig(json: String): RosaryConfig =
    RosaryJson.decodeFromString(RosaryConfig.serializer(), json)

fun RosaryConfig.firestoreData(): Map<String, Any?> = mapOf(
    "translation" to translation.firestoreValue,
    "fatimaPrayer" to fatimaPrayer,
    "oSacrament" to oSacrament,
    "closingPrayers" to closingPrayers,
    "memorare" to memorare,
    "saintMichael" to saintMichael,
    "intentionsStep" to intentionsStep,
    "showBeads" to showBeads,
)

fun RosaryConfig.Companion.fromFirestore(data: Map<String, Any?>): RosaryConfig {
    fun bool(key: String, default: Boolean): Boolean = when (val value = data[key]) {
        is Boolean -> value
        else -> default
    }
    val translation = when (val raw = data["translation"]) {
        is String -> BibleTranslation.fromStoredValue(raw) ?: BibleTranslation.WebCatholic
        else -> BibleTranslation.WebCatholic
    }
    return RosaryConfig(
        translation = translation,
        fatimaPrayer = bool("fatimaPrayer", true),
        oSacrament = bool("oSacrament", false),
        closingPrayers = bool("closingPrayers", true),
        memorare = bool("memorare", false),
        saintMichael = bool("saintMichael", false),
        intentionsStep = bool("intentionsStep", true),
        showBeads = bool("showBeads", true),
    )
}
