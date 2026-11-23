package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

/**
 * iOS `GuideSectionDivider`: an 8 dp bar between 16×40 endpoint caps,
 * tinted `palette.sectionDivider` (`#E3E4E8` light, `surface` `#1C1C1E` dark).
 */
@Composable
fun GuideSectionDivider(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val tint = ColorFilter.tint(palette.sectionDivider)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.sectionDividerEndpointHeight),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(R.drawable.section_divider_left),
            contentDescription = null,
            colorFilter = tint,
            modifier = Modifier.size(
                width = RosarySpace.sectionDividerEndpointWidth,
                height = RosarySpace.sectionDividerEndpointHeight,
            ),
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(RosarySpace.sectionDividerHeight)
                .background(palette.sectionDivider),
        )
        Image(
            painter = painterResource(R.drawable.section_divider_right),
            contentDescription = null,
            colorFilter = tint,
            modifier = Modifier.size(
                width = RosarySpace.sectionDividerEndpointWidth,
                height = RosarySpace.sectionDividerEndpointHeight,
            ),
        )
    }
}

/**
 * iOS `GuideSectionBoundary`: a full-bleed [GuideSectionDivider] with
 * vertical spacing (default `Space.lg` / 16 dp). Use this everywhere
 * iOS shows a large grouped section-separator band. Keep 1 px hairlines
 * for in-group row dividers.
 *
 * [fullBleed] expands past a parent that already applied [gutter]
 * horizontal padding, matching iOS `padding(.horizontal, -gutter)`.
 * Set it to false when the parent is already edge-to-edge.
 */
@Composable
fun SectionBand(
    modifier: Modifier = Modifier,
    verticalSpacing: Dp = RosarySpace.lg,
    fullBleed: Boolean = true,
    gutter: Dp = RosarySpace.gutter,
) {
    val gutterPx = with(LocalDensity.current) { gutter.roundToPx() }
    val bleed = if (fullBleed) {
        Modifier.layout { measurable, constraints ->
            val width = constraints.maxWidth + gutterPx * 2
            val placeable = measurable.measure(
                constraints.copy(minWidth = width, maxWidth = width),
            )
            layout(constraints.maxWidth, placeable.height) {
                placeable.place(-gutterPx, 0)
            }
        }
    } else {
        Modifier
    }
    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(bleed)
            .padding(vertical = verticalSpacing),
    ) {
        GuideSectionDivider()
    }
}

/**
 * Dialog / sheet action that uses [app.rosaryguide.core.designsystem.theme.ThemePalette.actionForeground]
 * (or [app.rosaryguide.core.designsystem.theme.ThemePalette.destructive] when [destructive] is true)
 * so the label stays at WCAG AA on dark surfaces.
 */
@Composable
fun GuideDialogButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    destructive: Boolean = false,
) {
    val palette = LocalThemePalette.current
    TextButton(onClick = onClick, modifier = modifier) {
        Text(
            text = text,
            style = RosaryType.bodyPray,
            color = if (destructive) palette.destructive else palette.actionForeground,
        )
    }
}
