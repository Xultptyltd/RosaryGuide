package app.rosaryguide.feature.pray

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.MotionTokens
import kotlinx.coroutines.delay

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
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
        contentAlignment = Alignment.Center,
    ) {
        GuideMarqueeText(
            text = progressLabel,
            style = RosaryType.navigationTitle,
            modifier = Modifier.padding(horizontal = 72.dp),
        )
        Row(
            modifier = Modifier.align(Alignment.CenterStart),
            verticalAlignment = Alignment.CenterVertically,
        ) {
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
        PrayChromeButton(
            icon = Icons.Filled.Close,
            contentDescription = "Close",
            onClick = onClose,
            modifier = Modifier.align(Alignment.CenterEnd),
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
    resetKey: Any? = null,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    var ready by remember(resetKey) { mutableStateOf(false) }
    var nextExpanded by remember(resetKey) { mutableStateOf(!showScroll) }
    var secondShown by remember(resetKey) { mutableStateOf(!showScroll && showCompleteDecade) }

    LaunchedEffect(resetKey, showScroll, showCompleteDecade, reduceMotion, ready) {
        val expand = !showScroll
        if (!ready) {
            nextExpanded = expand
            secondShown = expand && showCompleteDecade
            ready = true
            return@LaunchedEffect
        }
        if (!showCompleteDecade) {
            nextExpanded = expand
            secondShown = false
            return@LaunchedEffect
        }
        if (reduceMotion) {
            nextExpanded = expand
            secondShown = expand
            return@LaunchedEffect
        }
        if (expand) {
            nextExpanded = true
            delay(MotionTokens.pairStaggerMs)
            if (nextExpanded) secondShown = true
        } else if (secondShown) {
            secondShown = false
            delay(MotionTokens.pairStaggerMs)
            nextExpanded = false
        } else {
            nextExpanded = false
        }
    }

    val secondProgress by animateFloatAsState(
        targetValue = if (secondShown) 1f else 0f,
        animationSpec = if (reduceMotion) {
            snap()
        } else if (secondShown) {
            MotionTokens.pairSecondIn
        } else {
            MotionTokens.pairSecondOut
        },
        label = "pairSecond",
    )
    val showSecondSlot = showCompleteDecade && (secondShown || secondProgress > 0.01f)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(palette.prayBg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.lg),
        verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(if (secondShown) RosarySpace.md else 0.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            GuideScrollActionButton(
                showScroll = !nextExpanded,
                title = nextTitle,
                onScroll = onScroll,
                onAdvance = onNext,
                modifier = Modifier.weight(1f),
                primary = nextTitle == "Next" || nextTitle == "Finish" || nextTitle == "Done",
            )
            if (showSecondSlot) {
                val slidePx = with(LocalDensity.current) { MotionTokens.pairSlideDp.dp.toPx() }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .graphicsLayer {
                            val t = secondProgress
                            translationX = (1f - t) * -slidePx
                            scaleX = 0.96f + 0.04f * t
                            scaleY = 0.96f + 0.04f * t
                            transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0f, 0.5f)
                        },
                ) {
                    GuideTertiaryButton(
                        title = "Complete decade",
                        onClick = onCompleteDecade,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    // iOS PairSlotEffect.cover: a same-fill capsule over the label fades out.
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .background(
                                palette.buttonTertiaryFill.copy(alpha = 1f - secondProgress),
                                CircleShape,
                            ),
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


/**
 * Circle-to-pill action used by scrolling prayers, ported from iOS
 * `GuideScrollActionButton`. The shape is a [CircleShape] capsule at every
 * width. The frame springs with iOS `MotionTokens.reveal` (response 0.52,
 * dampingFraction 0.86); the chevron / label swap is instant (iOS
 * `.transition(.identity)`). Reduce Motion (animator scale 0) snaps.
 *
 * [morphProgressOverride] pins the width lerp (0 = circle, 1 = full pill)
 * for screenshot tests of intermediate frames.
 */
@Composable
fun GuideScrollActionButton(
    showScroll: Boolean,
    title: String,
    onScroll: () -> Unit,
    onAdvance: () -> Unit,
    modifier: Modifier = Modifier,
    scrollLabel: String = "Scroll to continue",
    primary: Boolean = true,
    morphProgressOverride: Float? = null,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    val circle = MotionTokens.actionCircleDp.dp
    val target = if (showScroll) 0f else 1f
    val animated by animateFloatAsState(
        targetValue = target,
        animationSpec = if (reduceMotion) snap() else MotionTokens.reveal,
        label = "scrollMorph",
    )
    val progress = morphProgressOverride ?: animated
    val fill = if (primary) palette.buttonPrimaryFill else palette.buttonSecondaryFill
    val content = if (primary) palette.buttonPrimaryText else palette.buttonSecondaryText

    BoxWithConstraints(modifier = modifier.fillMaxWidth()) {
        val width = circle + (maxWidth - circle) * progress
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
            Box(
                modifier = Modifier
                    .width(width)
                    .heightIn(min = circle)
                    .clip(CircleShape)
                    .background(fill)
                    .clickable(role = Role.Button) { if (showScroll) onScroll() else onAdvance() }
                    .semantics { contentDescription = if (showScroll) scrollLabel else title }
                    .padding(horizontal = if (showScroll) 0.dp else RosarySpace.md),
                contentAlignment = Alignment.Center,
            ) {
                // Content swaps instantly when [showScroll] changes; only the frame morphs.
                if (showScroll) {
                    Icon(
                        imageVector = Icons.Filled.KeyboardArrowDown,
                        contentDescription = null,
                        tint = content,
                        modifier = Modifier.size(17.dp),
                    )
                } else {
                    Text(
                        text = title,
                        style = RosaryType.body,
                        color = content,
                    )
                }
            }
        }
    }
}
