package app.rosaryguide.feature.pray

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.GuideMarqueeText
import app.rosaryguide.core.designsystem.component.GuideOutlineButton
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideTertiaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import app.rosaryguide.core.model.PrayTrackStage
import app.rosaryguide.core.model.PrayerLanguage

private val ChromeCircle = 36.dp

@Composable
fun PrayChromeButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Box(
        modifier = modifier
            .size(RosarySpace.minHitTarget)
            .clip(CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { this.contentDescription = contentDescription },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(ChromeCircle)
                .shadow(2.dp, CircleShape, clip = false)
                .background(palette.surface.copy(alpha = 0.94f), CircleShape)
                .border(0.5.dp, palette.strokeSubtle, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = palette.ink,
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

@Composable
fun PrayFlowHeader(
    progressLabel: String,
    canRetreat: Boolean,
    onBack: () -> Unit,
    onSettings: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (canRetreat) {
                PrayChromeButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    onClick = onBack,
                )
            }
            PrayChromeButton(
                icon = Icons.Filled.Settings,
                contentDescription = "Rosary settings",
                onClick = onSettings,
            )
        }
        GuideMarqueeText(
            text = progressLabel,
            style = RosaryType.navigationTitle,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = RosarySpace.xs),
        )
        PrayChromeButton(
            icon = Icons.Filled.Close,
            contentDescription = "Close",
            onClick = onClose,
        )
    }
}

@Composable
fun SevenStageTrack(
    current: PrayTrackStage,
    onJump: (PrayTrackStage) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val stages = PrayTrackStage.entries
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = RosarySpace.lg)
            .padding(top = 14.dp, bottom = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(RosarySpace.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        stages.forEach { stage ->
            val color = when {
                stage == current -> palette.ink
                stage.ordinal < current.ordinal -> palette.ink.copy(alpha = 0.20f)
                else -> palette.ink.copy(alpha = 0.08f)
            }
            val spoken = when (stage) {
                PrayTrackStage.Opening -> "Opening prayers"
                PrayTrackStage.Closing -> "Closing prayers"
                else -> "${listOf("", "First", "Second", "Third", "Fourth", "Fifth")[stage.ordinal]} decade"
            }
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(RosarySpace.minHitTarget)
                    .clickable(role = Role.Button, onClick = { onJump(stage) })
                    .semantics { contentDescription = spoken },
                contentAlignment = Alignment.TopCenter,
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(color),
                )
            }
        }
    }
}

@Composable
fun PrayerLanguageToggle(
    language: PrayerLanguage,
    onChange: (PrayerLanguage) -> Unit,
    modifier: Modifier = Modifier,
    useFullTitles: Boolean = isAccessibilitySize(),
) {
    val palette = LocalThemePalette.current
    val options = PrayerLanguage.entries
    val ax = useFullTitles
    SingleChoiceSegmentedButtonRow(
        modifier = modifier
            .then(if (ax) Modifier.fillMaxWidth() else Modifier.width(220.dp))
            .semantics { contentDescription = "Prayer language" },
    ) {
        options.forEachIndexed { index, option ->
            SegmentedButton(
                selected = language == option,
                onClick = { onChange(option) },
                shape = SegmentedButtonDefaults.itemShape(index, options.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = palette.surface,
                    activeContentColor = palette.ink,
                    inactiveContainerColor = palette.strokeSubtle,
                    inactiveContentColor = palette.dim,
                ),
                icon = {},
                label = {
                    Text(
                        text = if (ax) option.title else option.chip,
                        style = RosaryType.segmentedControl,
                        maxLines = 1,
                    )
                },
            )
        }
    }
}

@Composable
fun PrayActionFooter(
    nextTitle: String,
    showCompleteDecade: Boolean,
    showLanguage: Boolean,
    language: PrayerLanguage,
    onNext: () -> Unit,
    onCompleteDecade: () -> Unit,
    onLanguageChange: (PrayerLanguage) -> Unit,
    modifier: Modifier = Modifier,
    showScroll: Boolean = false,
    onScroll: () -> Unit = {},
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(palette.prayBg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.lg),
        verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
    ) {
        if (showScroll) {
            GuideScrollActionButton(
                showScroll = true,
                title = nextTitle,
                onScroll = onScroll,
                onAdvance = onNext,
            )
        } else {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm),
        ) {
            GuidePrimaryButton(
                title = nextTitle,
                onClick = onNext,
                modifier = Modifier.weight(1f),
            )
            if (showCompleteDecade) {
                GuideTertiaryButton(
                    title = "Complete decade",
                    onClick = onCompleteDecade,
                    modifier = Modifier.weight(1f),
                )
            }
        }
        }
        if (showLanguage) {
            PrayerLanguageToggle(
                language = language,
                onChange = onLanguageChange,
                modifier = Modifier.align(Alignment.Start),
            )
        }
    }
}

@Composable
fun IntentionActionFooter(
    onAdd: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(palette.prayBg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.lg),
        verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
    ) {
        GuideOutlineButton(title = "Add intention", onClick = onAdd)
        GuidePrimaryButton(title = "Next", onClick = onNext)
    }
}


private val ScrollCircle = 56.dp

@Composable
fun GuideScrollActionButton(
    showScroll: Boolean,
    title: String,
    onScroll: () -> Unit,
    onAdvance: () -> Unit,
    modifier: Modifier = Modifier,
    scrollLabel: String = "Scroll to continue",
    primary: Boolean = true,
) {
    val palette = LocalThemePalette.current
    val circle = ScrollCircle
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = if (showScroll) Arrangement.End else Arrangement.Start,
    ) {
        Button(
            onClick = if (showScroll) onScroll else onAdvance,
            modifier = Modifier
                .then(if (showScroll) Modifier.size(circle) else Modifier.fillMaxWidth())
                .heightIn(min = if (showScroll) circle else RosarySpace.pillHeight),
            shape = androidx.compose.foundation.shape.RoundedCornerShape(RosarySpace.containerRadius),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (primary) palette.buttonPrimaryFill else palette.buttonSecondaryFill,
                contentColor = if (primary) palette.buttonPrimaryText else palette.buttonSecondaryText,
            ),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp),
        ) {
            if (showScroll) {
                Icon(
                    imageVector = Icons.Filled.KeyboardArrowDown,
                    contentDescription = scrollLabel,
                    modifier = Modifier.size(22.dp),
                )
            } else {
                androidx.compose.material3.Text(text = title, style = RosaryType.body)
            }
        }
    }
}
