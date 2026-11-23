package app.rosaryguide.feature.profile

import androidx.compose.ui.graphics.Color
import app.rosaryguide.core.data.session.IntentionAccent
import app.rosaryguide.core.data.session.IntentionCategory

fun IntentionAccent.fill(): Color = when (this) {
    IntentionAccent.MintGreen -> Color(0xFF00C895)
    IntentionAccent.SkyBlue -> Color(0xFF5EA1FF)
    IntentionAccent.Purple -> Color(0xFF9751FA)
}

fun IntentionAccent.label(): String = when (this) {
    IntentionAccent.MintGreen -> "Soft mint green"
    IntentionAccent.SkyBlue -> "Soft Marian Blue"
    IntentionAccent.Purple -> "Soft purple"
}

val INTENTION_EMOJIS = listOf(
    "🙏", "❤️", "🕊️", "🌹", "✨", "✝️", "🌍", "🕯️", "💙", "🤍",
    "👨‍👩‍👧", "💒", "🌿", "⭐", "🤲",
)

fun IntentionCategory.glyph(): String = when (this) {
    IntentionCategory.Personal -> "🙏"
    IntentionCategory.Someone -> "👥"
    IntentionCategory.World -> "⛪"
}

fun intentionCategoryGlyph(intention: app.rosaryguide.core.data.session.OfferIntention): Int =
    intentionCategoryGlyph(intention.category, intention.emoji)

fun intentionCategoryGlyph(category: IntentionCategory, emoji: String? = null): Int {
    val fromEmoji = when (emoji) {
        "🙏", "❤️", "❤", "♥️", "♥" -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_personal
        "👥" -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_someone
        "🌍", "🌎", "🌏", "⛪" -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_world
        else -> null
    }
    return fromEmoji ?: when (category) {
        IntentionCategory.Personal -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_personal
        IntentionCategory.Someone -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_someone
        IntentionCategory.World -> app.rosaryguide.core.designsystem.R.drawable.intention_icon_world
    }
}
