package app.rosaryguide.core.data.session

import kotlinx.serialization.Serializable

@Serializable
enum class IntentionCategory {
    Personal,
    Someone,
    World,
    ;

    val title: String
        get() = when (this) {
            Personal -> "Personal"
            Someone -> "Someone else"
            World -> "Church & world"
        }

    val storageName: String
        get() = when (this) {
            Personal -> "personal"
            Someone -> "someone"
            World -> "world"
        }

    val defaultAccent: IntentionAccent
        get() = when (this) {
            Personal -> IntentionAccent.MintGreen
            Someone -> IntentionAccent.SkyBlue
            World -> IntentionAccent.Purple
        }

    companion object {
        fun fromStorage(raw: String?): IntentionCategory? = when (raw) {
            "personal" -> Personal
            "someone" -> Someone
            "world" -> World
            "papal" -> World
            else -> null
        }
    }
}

@Serializable
enum class IntentionAccent {
    MintGreen,
    SkyBlue,
    Purple,
    ;

    val storageName: String
        get() = when (this) {
            MintGreen -> "mintGreen"
            SkyBlue -> "skyBlue"
            Purple -> "purple"
        }

    companion object {
        fun fromStorage(raw: String?): IntentionAccent? = when (raw) {
            "mintGreen" -> MintGreen
            "skyBlue" -> SkyBlue
            "purple" -> Purple
            else -> null
        }
    }
}

@Serializable
data class OfferIntention(
    val id: String,
    val title: String,
    val note: String? = null,
    val category: IntentionCategory = IntentionCategory.Personal,
    val accent: IntentionAccent = IntentionAccent.MintGreen,
    val emoji: String? = "🙏",
    val sourceId: String? = null,
    val isPinned: Boolean = false,
    val createdAtEpochMs: Long = 0L,
    val archivedAtEpochMs: Long? = null,
    val expiresAtEpochMs: Long? = null,
    val suggestOn: List<String> = emptyList(),
    val timesCarried: Int = 0,
    /** Last time a Rosary was offered for it (synced as `lastCarriedAt`). */
    val lastCarriedAtEpochMs: Long? = null,
    /** Last edit on any device (synced as `updatedAt`); newest edit wins a sync conflict. */
    val updatedAtEpochMs: Long? = null,
) {
    val isPapal: Boolean get() = sourceId?.startsWith("pope-") == true
    val isArchived: Boolean get() = archivedAtEpochMs != null
    val displayEmoji: String get() = emoji?.takeIf { it.isNotBlank() } ?: "🙏"
}

object IntentionPrivacy {
    const val MASKED_TEXT = "Hidden"

    fun hides(intention: OfferIntention, hidden: Boolean): Boolean =
        hidden && !intention.isPapal

    fun displayTitle(intention: OfferIntention, hidden: Boolean): String =
        if (hides(intention, hidden)) MASKED_TEXT else intention.title
}
