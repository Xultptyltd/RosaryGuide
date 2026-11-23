package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.session.IntentionAccent
import app.rosaryguide.core.data.session.IntentionCategory
import app.rosaryguide.core.data.session.OfferIntention

/** `/users/{uid}/intentions/{intentionId}`. Matches iOS `OfferIntention.firestoreData()`. */
object IntentionDocuments {
    private val mysteryWire = setOf("joyful", "luminous", "sorrowful", "glorious")

    fun firestoreData(intention: OfferIntention, now: Long): Map<String, Any> {
        val data = mutableMapOf<String, Any>(
            "schemaVersion" to 1,
            "title" to intention.title.trim().ifEmpty { "Untitled intention" }.take(160),
            "timesCarried" to intention.timesCarried.coerceIn(0, 100_000),
            "isPinned" to intention.isPinned,
            "createdAt" to intention.createdAtEpochMs.toDate(),
            "category" to intention.category.storageName,
            "accent" to intention.accent.storageName,
            "suggestOn" to intention.suggestOn.map { it.lowercase() }.filter { it in mysteryWire }.distinct().take(4),
            // The edit time, so an older offline edit cannot overwrite a newer one.
            "updatedAt" to (intention.updatedAtEpochMs ?: now).toDate(),
        )
        intention.note?.takeIf { it.isNotEmpty() }?.let { data["note"] = it.take(2000) }
        intention.lastCarriedAtEpochMs?.let { data["lastCarriedAt"] = it.toDate() }
        intention.expiresAtEpochMs?.let { data["expiresAt"] = it.toDate() }
        intention.sourceId?.takeIf { it.isNotEmpty() }?.let { data["sourceId"] = it.take(80) }
        intention.emoji?.takeIf { it.isNotEmpty() }?.let { data["emoji"] = it.take(32) }
        // Absent when active: writes replace the whole document, so unarchiving clears it.
        intention.archivedAtEpochMs?.let { data["archivedAt"] = minOf(it, now).toDate() }
        return data
    }

    fun fromFirestore(documentId: String, data: Map<String, Any?>): OfferIntention? {
        if (!SyncIds.isUuid(documentId)) return null
        val title = data["title"] as? String ?: return null
        val timesCarried = data["timesCarried"].asInt() ?: return null
        val isPinned = data["isPinned"] as? Boolean ?: return null
        val createdAt = data["createdAt"].asEpochMs() ?: return null
        val category = IntentionCategory.fromStorage(data["category"] as? String) ?: return null
        val accent = IntentionAccent.fromStorage(data["accent"] as? String) ?: IntentionAccent.SkyBlue
        return OfferIntention(
            id = SyncIds.canonical(documentId),
            title = title,
            note = (data["note"] as? String)?.takeIf { it.isNotEmpty() },
            category = category,
            accent = accent,
            emoji = (data["emoji"] as? String)?.takeIf { it.isNotEmpty() },
            sourceId = (data["sourceId"] as? String)?.takeIf { it.isNotEmpty() },
            isPinned = isPinned,
            createdAtEpochMs = createdAt,
            archivedAtEpochMs = data["archivedAt"].asEpochMs(),
            expiresAtEpochMs = data["expiresAt"].asEpochMs(),
            suggestOn = data["suggestOn"].asStringList()?.filter { it in mysteryWire } ?: emptyList(),
            timesCarried = timesCarried,
            lastCarriedAtEpochMs = data["lastCarriedAt"].asEpochMs(),
            updatedAtEpochMs = data["updatedAt"].asEpochMs(),
        )
    }
}

/** Pure merge rules for intentions; port of iOS `IntentionMerge`. */
object IntentionMerge {
    data class Result(
        val intentions: List<OfferIntention>,
        /** Device copies newer than the account's, or not in it yet. */
        val toUpload: List<OfferIntention>,
        /** Account documents this device deleted after their last edit. */
        val toDelete: List<String>,
        /** Deletions still waiting for the server to confirm them. */
        val deleted: Map<String, Long>,
    )

    /** Gives each added or edited intention a fresh edit time. */
    fun stampingEdits(values: List<OfferIntention>, previous: List<OfferIntention>, now: Long): List<OfferIntention> {
        val before = previous.associateBy { it.id }
        return values.map { value ->
            val old = before[value.id]
            if (old != null && value.copy(updatedAtEpochMs = old.updatedAtEpochMs) == old) value
            else value.copy(updatedAtEpochMs = now)
        }
    }

    /**
     * - For an id in both, the newer edit wins; ties and device copies without an edit time go to
     *   the account. A newer device copy is uploaded again (server snapshots only).
     * - An account document deleted here at or after its last edit stays deleted and is deleted
     *   again. One edited elsewhere after the delete comes back.
     * - A device intention missing from the account is kept and uploaded unless the server had
     *   confirmed it before (then another device deleted it).
     * - Cache-only events never drop anything and upload nothing.
     */
    fun merge(
        local: List<OfferIntention>,
        remote: List<OfferIntention>,
        deleted: Map<String, Long>,
        previouslySynced: Set<String>,
        isFromCache: Boolean,
        now: Long,
    ): Result {
        val localById = local.associateBy { it.id }
        val remoteIds = remote.map { it.id }.toSet()
        val pendingDeletes = deleted.toMutableMap()
        val merged = mutableListOf<OfferIntention>()
        val toUpload = mutableListOf<OfferIntention>()
        val toDelete = mutableListOf<String>()

        for (item in remote) {
            val remoteEdit = item.updatedAtEpochMs ?: Long.MIN_VALUE
            val deletedAt = pendingDeletes[item.id]
            if (deletedAt != null) {
                if (remoteEdit <= deletedAt) {
                    toDelete += item.id
                    continue
                }
                pendingDeletes.remove(item.id)
            }
            val mine = localById[item.id]
            val localEdit = mine?.updatedAtEpochMs
            if (mine != null && localEdit != null && localEdit > remoteEdit) {
                merged += mine
                if (!isFromCache) toUpload += mine
            } else {
                merged += item
            }
        }

        var localOnly = local.filter { it.id !in remoteIds && it.id !in pendingDeletes }
        var remaining: Map<String, Long> = pendingDeletes
        if (!isFromCache) {
            localOnly = localOnly.filter { it.id !in previouslySynced }
            toUpload += localOnly.filter { !it.isExpired(now) }
            remaining = pendingDeletes.filterKeys { it in remoteIds }
        }
        return Result(merged + localOnly, toUpload, toDelete, remaining)
    }
}

fun OfferIntention.isExpired(now: Long): Boolean = expiresAtEpochMs?.let { it <= now } ?: false
