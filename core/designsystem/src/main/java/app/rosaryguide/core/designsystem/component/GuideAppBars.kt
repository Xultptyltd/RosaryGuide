package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.guideHeading
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize

/**
 * Native Material 3 top bars, themed with Rosary Guide tokens.
 *
 * These replace the iOS-chevron imitation. Tab roots that use iOS
 * `guideRootChrome` (system large title) map to [GuideLargeTopAppBar].
 * Pushed pages that use iOS `guideDetailChrome` (inline title + system back)
 * map to [GuideTopAppBar].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GuideLargeTopAppBar(
    title: String,
    modifier: Modifier = Modifier,
    onBack: (() -> Unit)? = null,
    closeInsteadOfBack: Boolean = false,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val palette = LocalThemePalette.current
    LargeTopAppBar(
        title = {
            Text(
                text = title,
                style = RosaryType.h1Navigation,
                color = palette.ink,
                maxLines = if (isAccessibilitySize()) 3 else 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.guideHeading(),
            )
        },
        modifier = modifier,
        navigationIcon = {
            if (onBack != null) {
                IconButton(onClick = onBack) {
                    Icon(
                        imageVector = if (closeInsteadOfBack) Icons.Filled.Close else Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = if (closeInsteadOfBack) "Close" else "Back",
                        tint = palette.ink,
                    )
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = palette.bg,
            scrolledContainerColor = palette.bg,
            titleContentColor = palette.ink,
            actionIconContentColor = palette.ink,
        ),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GuideTopAppBar(
    title: String,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
    closeInsteadOfBack: Boolean = false,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val palette = LocalThemePalette.current
    val ax = isAccessibilitySize()
    CenterAlignedTopAppBar(
        title = {
            Text(
                text = title,
                style = RosaryType.navigationTitle,
                color = palette.ink,
                maxLines = if (ax) 3 else 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.guideHeading(),
            )
        },
        modifier = modifier,
        navigationIcon = {
            if (onBack != null) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier.heightIn(min = RosarySpace.minHitTarget),
                ) {
                    Icon(
                        imageVector = if (closeInsteadOfBack) Icons.Filled.Close else Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = if (closeInsteadOfBack) "Close" else "Back",
                        tint = palette.ink,
                    )
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = palette.bg,
            titleContentColor = palette.ink,
            navigationIconContentColor = palette.ink,
            actionIconContentColor = palette.ink,
        ),
    )
}
