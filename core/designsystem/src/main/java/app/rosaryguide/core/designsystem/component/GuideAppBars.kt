package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import app.rosaryguide.core.designsystem.R
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
    containerColor: Color? = null,
) {
    val palette = LocalThemePalette.current
    val barColor = containerColor ?: palette.bg
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
            containerColor = barColor,
            scrolledContainerColor = barColor,
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
    containerColor: Color? = null,
    milkyBack: Boolean = true,
    milkyOnPlain: Boolean = false,
    chevronBack: Boolean = false,
) {
    val palette = LocalThemePalette.current
    val ax = isAccessibilitySize()
    val barColor = containerColor ?: palette.bg
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
                    val label = if (closeInsteadOfBack) "Close" else "Back"
                    if (milkyBack && !closeInsteadOfBack) {
                        GuideMilkyCircleChip(milkyOnPlain = milkyOnPlain) {
                            if (chevronBack) {
                                Icon(
                                    painter = painterResource(R.drawable.ic_chevron_backward),
                                    contentDescription = label,
                                    tint = palette.ink,
                                    modifier = Modifier.size(20.dp),
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = label,
                                    tint = palette.ink,
                                    modifier = Modifier.size(20.dp),
                                )
                            }
                        }
                    } else if (chevronBack && !closeInsteadOfBack) {
                        Icon(
                            painter = painterResource(R.drawable.ic_chevron_backward),
                            contentDescription = label,
                            tint = palette.ink,
                            modifier = Modifier.size(20.dp),
                        )
                    } else {
                        Icon(
                            imageVector = if (closeInsteadOfBack) Icons.Filled.Close else Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = label,
                            tint = palette.ink,
                        )
                    }
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = barColor,
            titleContentColor = palette.ink,
            navigationIconContentColor = palette.ink,
            actionIconContentColor = palette.ink,
        ),
    )
}

/**
 * 40 dp milky circle used by the Learn/Profile back chip and the
 * All-intentions more control. [milkyOnPlain] adds the hairline fill
 * used on plain Settings pages; the default is the wash-page disc.
 */
@Composable
fun GuideMilkyCircleChip(
    modifier: Modifier = Modifier,
    milkyOnPlain: Boolean = false,
    content: @Composable androidx.compose.foundation.layout.BoxScope.() -> Unit,
) {
    val palette = LocalThemePalette.current
    val chip = when {
        palette.isDark -> Color.White.copy(alpha = 0.16f)
        milkyOnPlain -> Color(0xFFF4F4F5)
        else -> Color.White.copy(alpha = 0.92f)
    }
    Box(
        modifier = modifier
            .size(RosarySpace.controlSize)
            .clip(CircleShape)
            .background(chip)
            .then(
                if (milkyOnPlain && !palette.isDark) {
                    Modifier.border(
                        app.rosaryguide.core.designsystem.theme.Hairline.thickness,
                        palette.cardSurfaceStroke,
                        CircleShape,
                    )
                } else Modifier,
            ),
        contentAlignment = Alignment.Center,
        content = content,
    )
}
