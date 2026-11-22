package app.rosaryguide.feature.pray

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.ui.graphics.Color
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
import app.rosaryguide.core.designsystem.theme.PageStyle
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

private val ChromeCircle = RosarySpace.controlSize

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
        // iOS `guideFloatingGlass` chips are milky 40 pt circles. A 0.58
        // white fill disappears on pale art and on a white page; use a
        // nearly-opaque surface in light and a frosted dark fill at night.
        val fill = if (palette.isDark) Color.White.copy(alpha = 0.16f) else Color(0xFFF4F4F5)
        val stroke = if (palette.isDark) Color.White.copy(alpha = 0.28f) else Color.Black.copy(alpha = 0.08f)
        Box(
            modifier = Modifier
                .size(ChromeCircle)
                .shadow(2.dp, CircleShape, clip = false)
                .background(fill, CircleShape)
                .border(0.5.dp, stroke, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = palette.ink,
                // Material icons include padding; 16.dp reads closer to iOS 13 pt semibold.
                modifier = Modifier.size(16.dp),
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
            .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.xs),
        contentAlignment = Alignment.Center,
    ) {
        GuideMarqueeText(
            text = progressLabel,
            style = RosaryType.progressLabel,
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
    if (ax && isAccessibilitySize()) {
        Column(
            modifier = modifier.fillMaxWidth().semantics { contentDescription = "Prayer language" },
            verticalArrangement = Arrangement.spacedBy(RosarySpace.sm),
        ) {
            options.forEach { option ->
                val selected = language == option
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(percent = 50))
                        .background(if (selected) palette.accent else palette.surface)
                        .clickable(role = Role.Button, onClick = { onChange(option) })
                        .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = option.title,
                        style = RosaryType.segmentedControlPray,
                        color = if (selected) palette.onAccent else palette.ink,
                    )
                }
            }
        }
        return
    }
    // Custom capsule matching the iOS segmented treatment: grey track,
    // raised white (light) or dark (dark) thumb, rounded ends, no dividers.
    val track = if (palette.isDark) Color(0xFF2C2C2E) else palette.surface
    val thumb = if (palette.isDark) Color(0xFF1C1C1E) else Color.White
    val selectedIndex = options.indexOf(language).coerceAtLeast(0)
    val width = if (ax) modifier else modifier.width(220.dp)
    // Bead-header chip stays 36 dp. The Saint Michael / reader control uses
    // iOS `Component.segmentedControlHeight` (44 pt, controlSize large).
    val controlHeight = if (ax) 44.dp else 36.dp
    val cap = RoundedCornerShape(percent = 50)
    BoxWithConstraints(
        modifier = width
            .height(controlHeight)
            .background(track, cap)
            .semantics { contentDescription = "Prayer language" },
    ) {
        val count = options.size
        val inset = 2.dp
        val thumbWidth = (maxWidth - inset * 2) / count
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .padding(start = inset + thumbWidth * selectedIndex, top = inset, bottom = inset)
                .width(thumbWidth)
                .height(controlHeight - inset * 2)
                .shadow(1.5.dp, cap, clip = false)
                .background(thumb, cap),
        )
        Row(Modifier.fillMaxWidth().fillMaxHeight(), verticalAlignment = Alignment.CenterVertically) {
            options.forEach { option ->
                val selected = language == option
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable(role = Role.Button, onClick = { onChange(option) }),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = if (ax) option.title else option.chip,
                        style = RosaryType.segmentedControlPray,
                        color = if (selected) palette.ink else palette.dim,
                        maxLines = 1,
                    )
                }
            }
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

    // iOS collapsed scroll circle floats over the reading; a solid foot would
    // hide Fruit when it sits beside the circle (as it does on the plate ref).
    Column(
        modifier = modifier
            .fillMaxWidth()
            .then(if (showScroll) Modifier else Modifier.background(palette.prayBg))
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
        val shape = RoundedCornerShape(percent = 50)
        val fill = palette.cardSurface(on = PageStyle.Grouped)
        Button(
            onClick = onAdd,
            modifier = Modifier
                .fillMaxWidth()
                .height(RosarySpace.pillHeight),
            shape = shape,
            colors = ButtonDefaults.buttonColors(
                containerColor = fill,
                contentColor = palette.ink,
            ),
            border = if (palette.isDark) null else BorderStroke(0.5.dp, palette.cardSurfaceStroke),
        ) {
            Text(text = "Add intention", style = RosaryType.bodyPray)
        }
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
