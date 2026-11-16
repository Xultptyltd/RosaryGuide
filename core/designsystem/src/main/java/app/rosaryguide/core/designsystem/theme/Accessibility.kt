package app.rosaryguide.core.designsystem.theme

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics

/** Dynamic Type / font-scale helpers, ported from iOS AX5 reflow tactics. */
object AccessibilitySize {
    /** Reflow stacks start at 160% so 200% is comfortably covered. */
    const val ACCESSIBILITY_FONT_SCALE = 1.6f
}

@Composable
fun isAccessibilitySize(): Boolean {
    return LocalDensity.current.fontScale >= AccessibilitySize.ACCESSIBILITY_FONT_SCALE
}

@Composable
fun fontScale(): Float = LocalDensity.current.fontScale

fun Modifier.guideHeading(): Modifier = this.semantics { heading() }

fun isIncreasedContrast(context: Context): Boolean {
    val highText = Settings.Secure.getInt(
        context.contentResolver,
        "high_text_contrast_enabled",
        0,
    ) == 1
    if (highText) return true
    if (Build.VERSION.SDK_INT >= 34) {
        val manager = context.getSystemService(UiModeManager::class.java)
        if (manager != null && manager.contrast >= 0.3f) return true
    }
    return false
}

@Composable
fun rememberIncreasedContrast(): Boolean {
    val context = LocalContext.current
    return remember(context) { isIncreasedContrast(context) }
}
