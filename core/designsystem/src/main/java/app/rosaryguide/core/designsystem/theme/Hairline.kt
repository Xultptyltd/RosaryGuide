package app.rosaryguide.core.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * 1 physical pixel, matching iOS hairlines of `1 / displayScale` pt
 * (`AppTheme.Component.hairline` is `1 / 3` on the @3x iPhone refs).
 */
object Hairline {
    val thickness: Dp
        @Composable
        get() = (1f / LocalDensity.current.density).dp
}
