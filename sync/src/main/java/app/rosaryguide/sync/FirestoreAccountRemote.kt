package app.rosaryguide.sync

import android.util.Log
import app.rosaryguide.core.data.sync.AccountRemote
import app.rosaryguide.core.data.sync.MetaDocument
import app.rosaryguide.core.data.sync.Registration
import app.rosaryguide.core.data.sync.RemoteDocument
import app.rosaryguide.core.data.sync.RemoteError
import app.rosaryguide.core.data.sync.RemoteIntentions
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.Timestamp
import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.MetadataChanges
import com.google.firebase.firestore.Query
import kotlinx.coroutines.tasks.await

/**
 * Firestore paths shared with iOS (`AccountDataRepository`, `FirestoreIntentionRepository`):
 * - `/users/{uid}/meta/preferences`
 * - `/users/{uid}/meta/progress`
 * - `/users/{uid}/intentions/{UUID}`
 *
 * Calls `FirebaseFirestore.getInstance()` each time: clearing the cache terminates the shared
 * instance, and a fresh call returns a working one afterwards.
 */
class FirestoreAccountRemote : AccountRemote {
    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()

    private fun meta(uid: String, document: MetaDocument): DocumentReference =
        db.collection("users").document(uid).collection("meta").document(document.id)

    private fun intentions(uid: String): CollectionReference =
        db.collection("users").document(uid).collection("intentions")

    override fun listen(uid: String, document: MetaDocument, onResult: (Result<RemoteDocument>) -> Unit): Registration {
        val registration = meta(uid, document).addSnapshotListener { snapshot, error ->
            if (error != null) {
                onResult(Result.failure(error.toRemoteError()))
                return@addSnapshotListener
            }
            snapshot ?: return@addSnapshotListener
            onResult(
                Result.success(
                    RemoteDocument(
                        data = if (snapshot.exists()) snapshot.data?.let(::fromFirestore) else null,
                        isFromCache = snapshot.metadata.isFromCache,
                    ),
                ),
            )
        }
        return Registration { registration.remove() }
    }

    override fun write(uid: String, document: MetaDocument, data: Map<String, Any>, onError: (RemoteError) -> Unit) {
        // Full replace, like iOS `setData(_, merge: false)`; queued offline at once.
        meta(uid, document).set(data)
            .addOnFailureListener { e ->
                Log.w(TAG, "Write ${document.id} failed", e)
                onError(e.toRemoteError())
            }
    }

    override suspend fun delete(uid: String, document: MetaDocument) {
        mapErrors { meta(uid, document).delete().await() }
    }

    override fun listenIntentions(uid: String, onResult: (Result<RemoteIntentions>) -> Unit): Registration {
        val registration = intentions(uid)
            .orderBy("createdAt", Query.Direction.ASCENDING)
            .addSnapshotListener(MetadataChanges.INCLUDE) { snapshot, error ->
                if (error != null) {
                    onResult(Result.failure(error.toRemoteError()))
                    return@addSnapshotListener
                }
                snapshot ?: return@addSnapshotListener
                onResult(
                    Result.success(
                        RemoteIntentions(
                            documents = snapshot.documents.map { it.id to fromFirestore(it.data ?: emptyMap()) },
                            confirmedIds = snapshot.documents.filter { !it.metadata.hasPendingWrites() }.map { it.id }.toSet(),
                            isFromCache = snapshot.metadata.isFromCache,
                        ),
                    ),
                )
            }
        return Registration { registration.remove() }
    }

    override suspend fun upsertIntention(uid: String, id: String, data: Map<String, Any>) {
        mapErrors { intentions(uid).document(id).set(data).await() }
    }

    override suspend fun deleteIntention(uid: String, id: String) {
        mapErrors { intentions(uid).document(id).delete().await() }
    }

    override suspend fun deleteAllIntentions(uid: String) {
        mapErrors {
            val documents = intentions(uid).get().await().documents
            documents.chunked(450).forEach { chunk ->
                val batch = db.batch()
                chunk.forEach { batch.delete(it.reference) }
                batch.commit().await()
            }
        }
    }

    override suspend fun clearLocalCache() {
        mapErrors {
            val instance = db
            instance.terminate().await()
            instance.clearPersistence().await()
        }
    }

    private suspend fun <T> mapErrors(block: suspend () -> T): T = try {
        block()
    } catch (e: FirebaseFirestoreException) {
        throw e.toRemoteError()
    } catch (e: FirebaseNetworkException) {
        throw RemoteError(RemoteError.Kind.Connectivity, e.message, e)
    }

    companion object {
        private const val TAG = "AccountSync"

        /** Firestore timestamps become `java.util.Date` for the shared parsers. */
        fun fromFirestore(value: Map<String, Any?>): Map<String, Any?> = value.mapValues { convert(it.value) }

        private fun convert(value: Any?): Any? = when (value) {
            is Timestamp -> value.toDate()
            is Map<*, *> -> value.entries.associate { (k, v) -> k.toString() to convert(v) }
            is List<*> -> value.map { convert(it) }
            else -> value
        }

        fun Exception.toRemoteError(): RemoteError = when (this) {
            is RemoteError -> this
            is FirebaseFirestoreException -> when (code) {
                FirebaseFirestoreException.Code.PERMISSION_DENIED ->
                    RemoteError(RemoteError.Kind.PermissionDenied, message, this)
                FirebaseFirestoreException.Code.UNAVAILABLE,
                FirebaseFirestoreException.Code.DEADLINE_EXCEEDED,
                FirebaseFirestoreException.Code.CANCELLED ->
                    RemoteError(RemoteError.Kind.Connectivity, message, this)
                else -> RemoteError(RemoteError.Kind.Other, message, this)
            }
            is FirebaseNetworkException -> RemoteError(RemoteError.Kind.Connectivity, message, this)
            else -> RemoteError(RemoteError.Kind.Other, message, this)
        }
    }
}
