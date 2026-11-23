package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.auth.AuthBackend
import app.rosaryguide.core.data.auth.AuthResult
import app.rosaryguide.core.data.auth.AuthUser

/** In-memory Firestore: documents keyed by path, listeners fired synchronously. */
class FakeAccountRemote : AccountRemote {
    val docs = mutableMapOf<String, Map<String, Any?>>()
    val writes = mutableListOf<Pair<String, Map<String, Any>>>()
    val deletes = mutableListOf<String>()
    var rejectWrites: ((path: String, data: Map<String, Any>) -> RemoteError?) = { _, _ -> null }
    var failDeletes = false
    var cacheCleared = 0
    private val docListeners = mutableMapOf<String, MutableList<(Result<RemoteDocument>) -> Unit>>()
    private val intentionListeners = mutableMapOf<String, MutableList<(Result<RemoteIntentions>) -> Unit>>()

    fun metaPath(uid: String, d: MetaDocument) = "users/$uid/meta/${d.id}"
    fun intentionPath(uid: String, id: String) = "users/$uid/intentions/$id"

    override fun listen(uid: String, document: MetaDocument, onResult: (Result<RemoteDocument>) -> Unit): Registration {
        val path = metaPath(uid, document)
        docListeners.getOrPut(path) { mutableListOf() } += onResult
        onResult(Result.success(RemoteDocument(docs[path], isFromCache = false)))
        return Registration { docListeners[path]?.remove(onResult) }
    }

    override fun write(uid: String, document: MetaDocument, data: Map<String, Any>, onError: (RemoteError) -> Unit) {
        val path = metaPath(uid, document)
        writes += path to data
        rejectWrites(path, data)?.let { onError(it); return }
        docs[path] = data
    }

    /** Simulates another device writing a document. */
    fun pushDoc(uid: String, document: MetaDocument, data: Map<String, Any?>?) {
        val path = metaPath(uid, document)
        if (data == null) docs.remove(path) else docs[path] = data
        docListeners[path]?.toList()?.forEach { it(Result.success(RemoteDocument(docs[path], false))) }
    }

    override suspend fun delete(uid: String, document: MetaDocument) {
        if (failDeletes) throw RemoteError(RemoteError.Kind.Connectivity, "offline")
        val path = metaPath(uid, document)
        deletes += path
        docs.remove(path)
    }

    override fun listenIntentions(uid: String, onResult: (Result<RemoteIntentions>) -> Unit): Registration {
        intentionListeners.getOrPut(uid) { mutableListOf() } += onResult
        onResult(Result.success(intentionSnapshot(uid)))
        return Registration { intentionListeners[uid]?.remove(onResult) }
    }

    fun intentionSnapshot(uid: String): RemoteIntentions {
        val prefix = "users/$uid/intentions/"
        val items = docs.filterKeys { it.startsWith(prefix) }.map { (k, v) -> k.removePrefix(prefix) to v }
        return RemoteIntentions(items, items.map { it.first }.toSet(), isFromCache = false)
    }

    fun pushIntentions(uid: String) {
        intentionListeners[uid]?.toList()?.forEach { it(Result.success(intentionSnapshot(uid))) }
    }

    override suspend fun upsertIntention(uid: String, id: String, data: Map<String, Any>) {
        val path = intentionPath(uid, id)
        writes += path to data
        rejectWrites(path, data)?.let { throw it }
        docs[path] = data
    }

    override suspend fun deleteIntention(uid: String, id: String) {
        val path = intentionPath(uid, id)
        deletes += path
        docs.remove(path)
    }

    override suspend fun deleteAllIntentions(uid: String) {
        if (failDeletes) throw RemoteError(RemoteError.Kind.Connectivity, "offline")
        docs.keys.filter { it.startsWith("users/$uid/intentions/") }.forEach {
            deletes += it
            docs.remove(it)
        }
    }

    override suspend fun clearLocalCache() {
        cacheCleared += 1
    }
}

class FakeAuthBackend : AuthBackend {
    override val isConfigured: Boolean = true
    override var currentUser: AuthUser? = null
    var nextSignIn: AuthResult = AuthResult.Success(AuthUser("uid-a", "google.com", "Ann"))
    var nextReauth: AuthResult? = null
    var nextDelete: AuthResult? = null
    var signOuts = 0
    private val listeners = mutableListOf<(AuthUser?) -> Unit>()

    override fun addAuthStateListener(onChange: (AuthUser?) -> Unit): () -> Unit {
        listeners += onChange
        return { listeners.remove(onChange) }
    }

    private fun publish(user: AuthUser?) {
        currentUser = user
        listeners.toList().forEach { it(user) }
    }

    override suspend fun signInWithGoogle(): AuthResult {
        val result = nextSignIn
        if (result is AuthResult.Success) publish(result.user)
        return result
    }

    override suspend fun reauthenticateWithGoogle(): AuthResult =
        nextReauth ?: currentUser?.let { AuthResult.Success(it) } ?: AuthResult.Failure("No account is signed in")

    override suspend fun deleteCurrentUser(): AuthResult {
        nextDelete?.let { return it }
        val user = currentUser ?: return AuthResult.Failure("No account is signed in")
        publish(null)
        return AuthResult.Success(user)
    }

    override suspend fun signOut() {
        signOuts += 1
        publish(null)
    }
}

/** Keys and value checks from the deployed firestore.rules, for "would the rules accept this?". */
object RulesShape {
    val intentionAllowed = setOf(
        "schemaVersion", "title", "note", "timesCarried", "isPinned", "createdAt", "lastCarriedAt",
        "expiresAt", "sourceId", "category", "accent", "emoji", "suggestOn", "updatedAt", "archivedAt",
    )
    val intentionRequired = setOf(
        "schemaVersion", "title", "timesCarried", "isPinned", "createdAt", "category", "accent", "suggestOn", "updatedAt",
    )
    val preferencesFields = setOf(
        "schemaVersion", "appearance", "prayerLanguage", "rosaryLanguage", "textSize", "includeSaintMichael",
        "hideIntentionText", "dailyReminderEnabled", "dailyReminderMinutes", "feastAlertsEnabled",
        "feastAlertMinutes", "appIcon", "updatedAt",
    )
    val preferencesOptional = setOf("rosaryConfig", "fieldUpdatedAt")
    val rosaryConfigKeys = setOf(
        "showScripture", "fatimaPrayer", "oSacrament", "closingPrayers", "memorare", "saintMichael",
        "intentionsStep", "openingIntentionLines", "showBeads", "translation",
    )
    val progressAllowed = setOf("schemaVersion", "completedDays", "historyResetAt", "session", "sessionChangedAt", "updatedAt", "rosaries")
    val progressRequired = setOf("schemaVersion", "completedDays", "sessionChangedAt", "updatedAt")
    val sessionAllowed = setOf(
        "mysterySet", "stepIndex", "startedAt", "updatedAt", "includeSaintMichael", "language",
        "intentionId", "intentionTitle", "intentionIds", "intentionTitles", "rosaryConfig",
    )
    val sessionRequired = setOf("mysterySet", "stepIndex", "startedAt", "updatedAt", "includeSaintMichael", "language")
}
