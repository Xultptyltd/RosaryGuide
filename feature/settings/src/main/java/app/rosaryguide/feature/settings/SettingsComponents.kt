package app.rosaryguide.feature.settings
import app.rosaryguide.core.designsystem.R
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.layout.layout
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.foundation.Image

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import androidx.compose.foundation.layout.size

@Composable
fun SettingsSection(
    title: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    carded: Boolean = false,
    content: @Composable () -> Unit,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        GuideSectionLabel(
            text = title,
            strong = true,
            icon = icon,
            style = RosaryType.bodyPray,
        )
        // GuideSectionLabel already pads bottom xs (4). Add the rest so the
        // heading-to-rows gap is iOS sectionTitleGap (20) on plain Settings.
        Spacer(
            Modifier.height(
                if (carded) RosarySpace.sectionTitleGap
                else RosarySpace.sectionTitleGap - RosarySpace.xs,
            ),
        )
        if (carded) {
            Column(Modifier.settingsGroupCard()) { content() }
        } else {
            content()
        }
    }
}

@Composable
fun SettingsGroupCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .settingsGroupCard(),
    ) {
        content()
    }
}

@Composable
private fun Modifier.settingsGroupCard(): Modifier {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    return this
        .clip(shape)
        .background(palette.cardSurface(on = PageStyle.Grouped), shape)
        .border(Hairline.thickness, palette.cardSurfaceStroke, shape)
        .padding(horizontal = RosarySpace.md, vertical = 4.dp)
}

@Composable
internal fun settingsSwitchColors(): androidx.compose.material3.SwitchColors {
    val palette = LocalThemePalette.current
    // Keep the M3 on-colour (accent), but lift the off-track so it reads
    // against the card like an iOS switch in the off state.
    val offTrack = if (palette.isDark) Color(0xFF636366) else Color(0xFFC7C7CC)
    val offBorder = if (palette.isDark) Color(0xFF8E8E93) else Color(0xFFB0B0B5)
    return SwitchDefaults.colors(
        checkedTrackColor = palette.accent,
        checkedThumbColor = palette.onAccent,
        checkedBorderColor = palette.accent,
        uncheckedTrackColor = offTrack,
        uncheckedThumbColor = Color.White,
        uncheckedBorderColor = offBorder,
    )
}

/** SF Symbol `repeat` — used on the Each decade section header. */
val SettingsRepeatIcon: ImageVector
    get() = _settingsRepeatIcon ?: ImageVector.Builder(
        name = "SettingsRepeat",
        defaultWidth = 18.dp,
        defaultHeight = 18.dp,
        viewportWidth = 24f,
        viewportHeight = 24f,
    ).apply {
        val s = SolidColor(Color.Black)
        path(
            fill = null,
            stroke = s,
            strokeLineWidth = 2.15f,
            strokeLineCap = StrokeCap.Round,
            strokeLineJoin = StrokeJoin.Round,
        ) {
            moveTo(17f, 2f)
            lineTo(21f, 6f)
            lineTo(17f, 10f)
            moveTo(3f, 12f)
            verticalLineTo(10f)
            curveTo(3f, 7.79f, 4.79f, 6f, 7f, 6f)
            horizontalLineTo(21f)
            moveTo(7f, 22f)
            lineTo(3f, 18f)
            lineTo(7f, 14f)
            moveTo(21f, 12f)
            verticalLineTo(14f)
            curveTo(21f, 16.21f, 19.21f, 18f, 17f, 18f)
            horizontalLineTo(3f)
        }
    }.build().also { _settingsRepeatIcon = it }

private var _settingsRepeatIcon: ImageVector? = null

/** SF Symbol `moon.stars` — used on the Closing prayers section header. */
val SettingsMoonStarsIcon: ImageVector
    get() = _settingsMoonStarsIcon ?: ImageVector.Builder(
        name = "SettingsMoonStars",
        defaultWidth = 18.dp,
        defaultHeight = 18.dp,
        viewportWidth = 24f,
        viewportHeight = 24f,
    ).apply {
        val s = SolidColor(Color.Black)
        path(fill = s) {
            // Crescent (moon.stars)
            moveTo(12.8f, 3.1f)
            curveTo(9.6f, 3.8f, 7.2f, 6.7f, 7.2f, 10.2f)
            curveTo(7.2f, 14.1f, 10.3f, 17.2f, 14.2f, 17.2f)
            curveTo(16.0f, 17.2f, 17.6f, 16.5f, 18.8f, 15.4f)
            curveTo(17.6f, 18.4f, 14.6f, 20.6f, 11.1f, 20.6f)
            curveTo(6.2f, 20.6f, 2.2f, 16.6f, 2.2f, 11.7f)
            curveTo(2.2f, 7.2f, 5.4f, 3.4f, 9.7f, 2.5f)
            curveTo(10.8f, 2.8f, 11.8f, 3.0f, 12.8f, 3.1f)
            close()
        }
        path(fill = s) {
            // Large star
            moveTo(19.3f, 3.4f)
            lineTo(20.05f, 5.35f)
            lineTo(22.15f, 5.7f)
            lineTo(20.45f, 7.0f)
            lineTo(20.85f, 9.1f)
            lineTo(19.3f, 8.05f)
            lineTo(17.75f, 9.1f)
            lineTo(18.15f, 7.0f)
            lineTo(16.45f, 5.7f)
            lineTo(18.55f, 5.35f)
            close()
        }
        path(fill = s) {
            // Small star
            moveTo(16.6f, 1.2f)
            lineTo(17.05f, 2.3f)
            lineTo(18.2f, 2.5f)
            lineTo(17.3f, 3.2f)
            lineTo(17.5f, 4.35f)
            lineTo(16.6f, 3.75f)
            lineTo(15.7f, 4.35f)
            lineTo(15.9f, 3.2f)
            lineTo(15.0f, 2.5f)
            lineTo(16.15f, 2.3f)
            close()
        }
    }.build().also { _settingsMoonStarsIcon = it }

private var _settingsMoonStarsIcon: ImageVector? = null

@Composable
fun SettingsNavigationRow(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    value: String? = null,
    destructive: Boolean = false,
    enabled: Boolean = true,
    external: Boolean = false,
    showChevron: Boolean = true,
) {
    val palette = LocalThemePalette.current
    val color = when {
        !enabled -> palette.dim
        destructive -> palette.destructive
        else -> palette.ink
    }
    val ax = isAccessibilitySize()
    val rowMod = modifier
        .fillMaxWidth()
        .sizeIn(minHeight = 56.dp)
        .clickable(enabled = enabled, onClick = onClick)
    if (ax && value != null) {
        Column(modifier = rowMod) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, tint = color, modifier = Modifier.padding(end = RosarySpace.md))
                }
                Text(title, style = RosaryType.bodyPray, color = color, modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.dim,
                )
            }
            Text(value, style = RosaryType.bodyPray, color = palette.dim, modifier = Modifier.padding(top = RosarySpace.xs), maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    } else {
        Row(
            modifier = rowMod,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (icon != null) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier
                        .width(24.dp)
                        .size(20.dp)
                        .padding(end = 0.dp),
                )
                Spacer(Modifier.width(RosarySpace.lg))
            }
            Text(
                title,
                style = RosaryType.bodyPray,
                color = color,
                maxLines = 1,
                overflow = TextOverflow.Clip,
            )
            Spacer(Modifier.weight(1f).width(RosarySpace.md))
            if (value != null) {
                Text(
                    value,
                    style = RosaryType.bodyPray,
                    color = palette.dim,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.End,
                    modifier = Modifier.padding(start = RosarySpace.sm, end = if (showChevron || external) RosarySpace.sm else 0.dp),
                )
            }
            if (external) {
                Icon(
                    imageVector = SettingsSymbols.arrowUpRight,
                    contentDescription = null,
                    tint = palette.textSecondary,
                    modifier = Modifier.size(12.dp),
                )
            } else if (showChevron) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.textSecondary,
                    modifier = Modifier.size(12.dp),
                )
            }
        }
    }
}

@Composable
fun SettingsToggleRow(
    title: String,
    checked: Boolean,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    onCheckedChange: (Boolean) -> Unit,
) {
    val palette = LocalThemePalette.current
    val ax = isAccessibilitySize()
    if (ax) {
        Column(
            modifier = modifier
                .fillMaxWidth()
                .sizeIn(minHeight = 56.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, tint = palette.dim, modifier = Modifier.size(22.dp).padding(end = RosarySpace.sm))
                }
            Text(
                title,
                style = RosaryType.bodyPray,
                color = if (enabled) palette.ink else palette.dim,
            )
            }
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled,
                colors = settingsSwitchColors(),
            )
        }
    } else
    Row(
        modifier = modifier
            .fillMaxWidth()
            .sizeIn(minHeight = 56.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = palette.dim,
                modifier = Modifier
                    .size(22.dp)
                    .padding(end = RosarySpace.sm),
            )
        }
        Text(
            title,
            style = RosaryType.bodyPray,
            color = if (enabled) palette.ink else palette.dim,
            modifier = Modifier.weight(1f),
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled,
            colors = settingsSwitchColors(),
        )
    }
}

@Composable
fun SettingsFootnote(text: String, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Text(
        text = text,
        style = RosaryType.captionPray,
        color = palette.dim,
        modifier = modifier
            .fillMaxWidth()
            .padding(top = RosarySpace.sm, bottom = RosarySpace.md),
    )
}

@Composable
fun SettingsDivider() {
    val palette = LocalThemePalette.current
    HorizontalDivider(color = palette.hair, thickness = Hairline.thickness)
}


@Composable
fun SettingsSectionBoundary(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val gutterPx = with(LocalDensity.current) { RosarySpace.gutter.roundToPx() }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = RosarySpace.lg)
            // Expand past the page gutter so the band is full-bleed, matching
            // iOS GuideSectionBoundary (padding(.horizontal, -gutter)).
            .layout { measurable, constraints ->
                val width = constraints.maxWidth + gutterPx * 2
                val placeable = measurable.measure(
                    constraints.copy(minWidth = width, maxWidth = width),
                )
                layout(constraints.maxWidth, placeable.height) {
                    placeable.place(-gutterPx, 0)
                }
            }
            .height(40.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(R.drawable.section_divider_left),
            contentDescription = null,
            colorFilter = ColorFilter.tint(palette.sectionDivider),
            modifier = Modifier.size(width = 16.dp, height = 40.dp),
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(8.dp)
                .background(palette.sectionDivider),
        )
        Image(
            painter = painterResource(R.drawable.section_divider_right),
            contentDescription = null,
            colorFilter = ColorFilter.tint(palette.sectionDivider),
            modifier = Modifier.size(width = 16.dp, height = 40.dp),
        )
    }
}
