package app.rosaryguide.core.data.sync

import java.util.Date

/**
 * Shared helpers for the account documents. Matches iOS `AccountSyncStore` / `IntentionRepository`
 * and the deployed `firestore.rules`.
 */
object SyncIds {
    private val uuid = Regex("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$")

    fun isUuid(value: String?): Boolean = value != null && uuid.matches(value)

    /**
     * iOS writes `UUID.uuidString`, which is upper case, and Firestore document ids and map keys
     * are case sensitive. Every id that crosses into the account is upper-cased so both apps
     * address the same document.
     */
    fun canonical(value: String): String = if (isUuid(value)) value.uppercase() else value

    fun newId(): String = java.util.UUID.randomUUID().toString().uppercase()
}

/** Reads a Firestore timestamp that the remote layer has turned into a [Date] (or epoch ms). */
internal fun Any?.asEpochMs(): Long? = when (this) {
    is Date -> time
    is Long -> this
    else -> null
}

internal fun Any?.asInt(): Int? = when (this) {
    is Int -> this
    is Long -> if (this in Int.MIN_VALUE..Int.MAX_VALUE) toInt() else null
    else -> null
}

internal fun Any?.asDouble(): Double? = (this as? Number)?.toDouble()

@Suppress("UNCHECKED_CAST")
internal fun Any?.asMap(): Map<String, Any?>? = this as? Map<String, Any?>

internal fun Any?.asStringList(): List<String>? = (this as? List<*>)?.filterIsInstance<String>()

internal fun Long.toDate(): Date = Date(this)
