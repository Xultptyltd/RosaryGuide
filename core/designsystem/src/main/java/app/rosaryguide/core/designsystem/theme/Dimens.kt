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
    /** iOS `RosaryFlow.prayerTitleBodyGap`. Sign of the Cross and plates use `lg` instead. */
    val prayerTitleBodyGap: Dp = 22.dp
    val section: Dp = 44.dp
    val sectionTitleGap: Dp = 20.dp
    const val ScaleLimit = 1.5f
    val gutter: Dp = 16.dp
    val minHitTarget: Dp = 48.dp
    /** iOS `AppTheme.controlSize` — Pray header chips are 40 pt glass circles. */
    val controlSize: Dp = 40.dp
    val pillHeight: Dp = 52.dp
    val profileRowHeight: Dp = 56.dp
    val containerRadius: Dp = 20.dp
    val featureRadius: Dp = 24.dp
    val panelRadius: Dp = 32.dp
    val nestedRadius: Dp = 12.dp
    val panelInset: Dp = 24.dp
    val onboardingControlsHeight: Dp = 132.dp
    /** iOS footerClearance: controlsHeight (132) + Space.xl (24). */
    val onboardingFooterClearance: Dp = onboardingControlsHeight + xl
    val signInLoopBottomPadding: Dp = 40.dp
    val signInStrandOverflow: Dp = 36.dp
    const val SignInBeadsAspect = 600f / 680f
    val sheetDragHandleWidth: Dp = 36.dp
    val sheetDragHandleHeight: Dp = 4.dp
    /** iOS handle sits ~5 pt below the sheet's top edge. */
    val sheetDragHandleTopPadding: Dp = 5.dp
    /**
     * Gap from the drag-indicator bottom to the first content line.
     * Measured on the iOS Pro Max week-feast ref: 72 px ÷ 3 = 24 pt (0.0251 of the frame).
     */
    val sheetHandleToContent: Dp = 24.dp
    val tabBarContentClearance: Dp = 108.dp
    val sheetOverlap: Dp = 56.dp
    val homeSheetOverlap: Dp = 36.dp
    val mysteryCardWidthFraction = 0.85f
    val mysteryCardArtAspect = 1.3f
    const val TitleLineHeight = 1.02f
    /** iOS `AppTheme.rosaryMysteryArtworkTopInset` — art starts below the Pray header. */
    // iOS token is 104 pt. Pixel 7 status+header+progress sit a little
    // lower, so 118 dp keeps the dove clearly under the bar without
    // changing the 0.58 bottom (title/Fruit stay put).
    val rosaryMysteryArtworkTopInset: Dp = 118.dp
    /** iOS `AppTheme.rosaryMysteryArtworkBottomFraction` — visible art bottom as a fraction of screen height. */
    const val rosaryMysteryArtworkBottomFraction = 0.58f

    fun homeHeroHeight(viewport: Dp): Dp {
        val raw = viewport * 0.46f
        return minOf(maxOf(320.dp, raw), 464.dp)
    }

    /** clamp(43.2, width × 0.115, 56), with a 38.4 compact override at ≤ 376 dp. */
    fun homeTitleSizeSp(widthDp: Float): Float {
        if (widthDp <= 376f) return 38.4f
        return (widthDp * 0.115f).coerceIn(43.2f, 56f)
    }

    /** iOS week-feast detent: min(max(estimated, 460), 640). */
    fun weekFeastSheetHeight(): Dp = 460.dp

    /** iOS mystery-detail detent: min(max(estimated, 460), 760). Pixel 7 needs the cap so Fruit stays above the fold. */
    fun mysteryDetailSheetHeight(): Dp = 760.dp

    /** iOS SignInLayout.beadsWidth(panelHeight). */
    fun signInBeadsWidth(panelHeight: Dp): Dp {
        val raw = (panelHeight - signInLoopBottomPadding + signInStrandOverflow) * SignInBeadsAspect
        return kotlin.math.round(raw.value).dp
    }

    /**
     * Frame-fraction landmarks measured on the iOS Pro Max refs (1320×2868).
     * Used so Pixel 7 (shorter 914 dp frame) still lands the same composition.
     */
    object ParityFractions {
        const val onboardingTitleTop = 0.573f
        const val onboardingCtaTop = 0.868f
        const val signInQuoteTop = 0.576f
        const val signInGoogleTop = 0.775f
        const val mysteryFruitTop = 0.782f
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
