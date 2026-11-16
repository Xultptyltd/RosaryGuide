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
