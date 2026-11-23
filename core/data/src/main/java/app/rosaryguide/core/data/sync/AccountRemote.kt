package app.rosaryguide.core.data.sync

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/** The two fixed documents under `/users/{uid}/meta`. Nothing else there is readable. */
enum class MetaDocument(val id: String) { Preferences("preferences"), Progress("progress") }

/** A document event. [data] is null when the document does not exist. Timestamps arrive as `java.util.Date`. */
data class RemoteDocument(val data: Map<String, Any?>?, val isFromCache: Boolean)

/** `/users/{uid}/intentions` event; [confirmedIds] have no pending local writes. */
data class RemoteIntentions(
    val documents: List<Pair<String, Map<String, Any?>>>,
    val confirmedIds: Set<String>,
    val isFromCache: Boolean,
)

class RemoteError(val kind: Kind, message: String? = null, cause: Throwable? = null) : Exception(message, cause) {
    enum class Kind { PermissionDenied, Connectivity, Other }
}

fun interface Registration { fun remove() }

/**
 * Firestore, behind an interface so sync rules can be tested with a fake.
 * Paths: `/users/{uid}/meta/{preferences|progress}` and `/users/{uid}/intentions/{UUID}`.
 */
interface AccountRemote {
    fun listen(uid: String, document: MetaDocument, onResult: (Result<RemoteDocument>) -> Unit): Registration

    /** Queues the full-document write at once; [onError] runs if the server rejects it. */
    fun write(uid: String, document: MetaDocument, data: Map<String, Any>, onError: (RemoteError) -> Unit)
    suspend fun delete(uid: String, document: MetaDocument)

    fun listenIntentions(uid: String, onResult: (Result<RemoteIntentions>) -> Unit): Registration
    suspend fun upsertIntention(uid: String, id: String, data: Map<String, Any>)
    suspend fun deleteIntention(uid: String, id: String)
    suspend fun deleteAllIntentions(uid: String)

    /** Drops Firestore's on-device cache (account deletion). */
    suspend fun clearLocalCache()
}

/** Small string store for per-account device copies (iOS `UserDefaults` keys). */
interface KeyValueStore {
    fun get(key: String): String?
    fun set(key: String, value: String?)
}

class InMemoryKeyValueStore : KeyValueStore {
    val values = mutableMapOf<String, String>()
    override fun get(key: String): String? = values[key]
    override fun set(key: String, value: String?) {
        if (value == null) values.remove(key) else values[key] = value
    }
}

class DataStoreKeyValueStore(private val dataStore: DataStore<Preferences>) : KeyValueStore {
    override fun get(key: String): String? = runBlocking { dataStore.data.first()[stringPreferencesKey(key)] }
    override fun set(key: String, value: String?) {
        runBlocking {
            dataStore.edit { prefs ->
                val k = stringPreferencesKey(key)
                if (value == null) prefs.remove(k) else prefs[k] = value
            }
        }
    }
}
