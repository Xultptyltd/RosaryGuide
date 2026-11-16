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
data class OfferIntention(
    val id: String,
    val title: String,
    val note: String? = null,
    val category: IntentionCategory = IntentionCategory.Personal,
    val sourceId: String? = null,
    val isPinned: Boolean = false,
    val createdAtEpochMs: Long = 0L,
) {
    val isPapal: Boolean get() = sourceId?.startsWith("pope-") == true
}

object IntentionPrivacy {
    const val MASKED_TEXT = "Hidden"

    fun hides(intention: OfferIntention, hidden: Boolean): Boolean =
        hidden && !intention.isPapal

    fun displayTitle(intention: OfferIntention, hidden: Boolean): String =
        if (hides(intention, hidden)) MASKED_TEXT else intention.title
}
