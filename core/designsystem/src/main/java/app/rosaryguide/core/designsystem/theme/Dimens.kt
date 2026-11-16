package app.rosaryguide.core.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Spacing and chrome tokens from iOS `AppTheme.Space`, `Component`, and `Accessibility`.
 * [scaled] caps Dynamic Type growth of paddings at 1.5×, matching `Space.scaleLimit`.
 */
object RosarySpace {
    val none: Dp = 0.dp
    val xs: Dp = 4.dp
    val sm: Dp = 8.dp
    val md: Dp = 12.dp
    val lg: Dp = 16.dp
    val xl: Dp = 24.dp
    val xxl: Dp = 32.dp
    val section: Dp = 44.dp
    const val ScaleLimit = 1.5f
    val gutter: Dp = 16.dp
    val minHitTarget: Dp = 48.dp
    val pillHeight: Dp = 52.dp
    val profileRowHeight: Dp = 56.dp
    val containerRadius: Dp = 20.dp
    val featureRadius: Dp = 24.dp
    val panelRadius: Dp = 32.dp
    val nestedRadius: Dp = 12.dp
}

@Composable
fun scaled(value: Dp): Dp {
    val factor = LocalDensity.current.fontScale.coerceAtMost(RosarySpace.ScaleLimit)
    return value * factor
}

@Immutable
data class RosaryDimens(
    val gutter: Dp = RosarySpace.gutter,
    val minHitTarget: Dp = RosarySpace.minHitTarget,
)

val LocalRosaryDimens = staticCompositionLocalOf { RosaryDimens() }
