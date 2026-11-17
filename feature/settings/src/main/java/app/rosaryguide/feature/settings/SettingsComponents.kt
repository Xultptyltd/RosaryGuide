package app.rosaryguide.feature.settings

import androidx.compose.foundation.clickable
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import androidx.compose.foundation.layout.size

@Composable
fun SettingsSection(
    title: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        GuideSectionLabel(text = title)
        Spacer(Modifier.height(RosarySpace.sm))
        content()
    }
}

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
        .sizeIn(minHeight = RosarySpace.minHitTarget)
        .clickable(enabled = enabled, onClick = onClick)
        .padding(vertical = 14.dp)
    if (ax && value != null) {
        Column(modifier = rowMod) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, tint = color, modifier = Modifier.padding(end = RosarySpace.md))
                }
                Text(title, style = RosaryType.body, color = color, modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.dim,
                )
            }
            Text(value, style = RosaryType.body, color = palette.dim, modifier = Modifier.padding(top = RosarySpace.xs))
        }
    } else {
        Row(
            modifier = rowMod,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = color, modifier = Modifier.padding(end = RosarySpace.md))
            }
            Text(title, style = RosaryType.body, color = color, modifier = Modifier.weight(1f))
            if (value != null) {
                Text(value, style = RosaryType.body, color = palette.dim)
                Spacer(Modifier.width(RosarySpace.xs))
            }
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = palette.dim,
            )
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
                .sizeIn(minHeight = RosarySpace.minHitTarget)
                .padding(vertical = 8.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, tint = palette.dim, modifier = Modifier.size(22.dp).padding(end = RosarySpace.sm))
                }
            Text(
                title,
                style = RosaryType.body,
                color = if (enabled) palette.ink else palette.dim,
            )
            }
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled,
                colors = SwitchDefaults.colors(
                    checkedTrackColor = palette.accent,
                    checkedThumbColor = palette.onAccent,
                ),
            )
        }
    } else
    Row(
        modifier = modifier
            .fillMaxWidth()
            .sizeIn(minHeight = RosarySpace.minHitTarget)
            .padding(vertical = 8.dp),
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
            style = RosaryType.body,
            color = if (enabled) palette.ink else palette.dim,
            modifier = Modifier.weight(1f),
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled,
            colors = SwitchDefaults.colors(
                checkedTrackColor = palette.accent,
                checkedThumbColor = palette.onAccent,
            ),
        )
    }
}

@Composable
fun SettingsFootnote(text: String, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Text(
        text = text,
        style = RosaryType.caption,
        color = palette.dim,
        modifier = modifier
            .fillMaxWidth()
            .padding(top = RosarySpace.sm, bottom = RosarySpace.md),
    )
}

@Composable
fun SettingsDivider() {
    val palette = LocalThemePalette.current
    HorizontalDivider(color = palette.strokeRegular, thickness = 0.5.dp)
}
