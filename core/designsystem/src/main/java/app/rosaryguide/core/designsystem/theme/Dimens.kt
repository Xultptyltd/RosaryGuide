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
    val sectionTitleGap: Dp = 20.dp
    const val ScaleLimit = 1.5f
    val gutter: Dp = 16.dp
    val minHitTarget: Dp = 48.dp
    val pillHeight: Dp = 52.dp
    val profileRowHeight: Dp = 56.dp
    val containerRadius: Dp = 20.dp
    val featureRadius: Dp = 24.dp
    val panelRadius: Dp = 32.dp
    val nestedRadius: Dp = 12.dp
    val panelInset: Dp = 24.dp
    val onboardingControlsHeight: Dp = 132.dp
    val tabBarContentClearance: Dp = 108.dp
    val sheetOverlap: Dp = 56.dp
    val homeSheetOverlap: Dp = 36.dp
    val mysteryCardWidthFraction = 0.85f
    val mysteryCardArtAspect = 1.3f
    const val TitleLineHeight = 1.02f

    fun homeHeroHeight(viewport: Dp): Dp {
        val raw = viewport * 0.46f
        return minOf(maxOf(320.dp, raw), 464.dp)
    }

    /** clamp(43.2, width × 0.115, 56), with a 38.4 compact override at ≤ 376 dp. */
    fun homeTitleSizeSp(widthDp: Float): Float {
        if (widthDp <= 376f) return 38.4f
        return (widthDp * 0.115f).coerceIn(43.2f, 56f)
    }

    fun signInPanelHeight(screenHeight: Dp, compact: Boolean = false): Dp {
        val fraction = if (compact) {
            if (screenHeight < 820.dp) 0.28f else 0.32f
        } else {
            if (screenHeight < 820.dp) 0.45f else 0.5f
        }
        return (screenHeight * fraction)
    }
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
