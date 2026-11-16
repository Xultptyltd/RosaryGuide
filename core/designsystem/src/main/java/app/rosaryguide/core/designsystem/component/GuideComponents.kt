package app.rosaryguide.core.designsystem.component

import android.provider.Settings
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.IntOffset
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import kotlin.math.roundToInt

val LocalReduceMotion = staticCompositionLocalOf { false }

@Composable
fun rememberReduceMotion(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        val scale = Settings.Global.getFloat(
            context.contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            1f,
        )
        scale == 0f
    }
}

@Composable
fun ProvideReduceMotion(content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalReduceMotion provides rememberReduceMotion(), content = content)
}

@Composable
fun GuideSectionLabel(
    text: String,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Text(
        text = text,
        style = RosaryType.supportingLabel,
        color = palette.textSecondary,
        modifier = modifier.padding(bottom = RosarySpace.xs),
    )
}

@Composable
fun GuidePill(
    text: String,
    modifier: Modifier = Modifier,
    emphasized: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val palette = LocalThemePalette.current
    val background = if (emphasized) palette.accent else palette.surface
    val foreground = if (emphasized) palette.onAccent else palette.ink
    val click = if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier
    Box(
        modifier = modifier
            .height(RosarySpace.pillHeight)
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(background)
            .then(click)
            .padding(horizontal = RosarySpace.lg),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = text, style = RosaryType.body, color = foreground)
    }
}

@Composable
fun GuideRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    onClick: (() -> Unit)? = null,
) {
    val palette = LocalThemePalette.current
    val click = if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier
    Row(
        modifier = modifier
            .fillMaxWidth()
            .sizeIn(minHeight = RosarySpace.profileRowHeight)
            .clip(RoundedCornerShape(RosarySpace.nestedRadius))
            .background(palette.cardSurface(app.rosaryguide.core.designsystem.theme.PageStyle.Grouped))
            .then(click)
            .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, style = RosaryType.body, color = palette.ink)
            if (subtitle != null) {
                Text(text = subtitle, style = RosaryType.caption, color = palette.textSecondary)
            }
        }
        Text(text = "›", style = RosaryType.headingSecondary, color = palette.textSecondary)
    }
}

@Composable
fun GuideScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
) {
    val palette = LocalThemePalette.current
    Column(modifier = modifier.fillMaxWidth()) {
        Text(text = title, style = RosaryType.headingPrimary, color = palette.ink)
        if (subtitle != null) {
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = subtitle, style = RosaryType.supportingLabel, color = palette.textSecondary)
        }
    }
}

@Composable
fun GuideMarqueeText(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle = RosaryType.body,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    if (reduceMotion) {
        Text(
            text = text,
            style = style,
            color = palette.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = modifier,
        )
        return
    }
    val transition = rememberInfiniteTransition(label = "marquee")
    val offset by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 8000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "marquee-offset",
    )
    Box(modifier = modifier.clipToBounds()) {
        Text(
            text = text,
            style = style,
            color = palette.ink,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.offset { IntOffset((-offset * 200f).roundToInt(), 0) },
        )
    }
}
