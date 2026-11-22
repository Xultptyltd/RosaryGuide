package app.rosaryguide.feature.pray

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.imageResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.sequence.PathCommand
import app.rosaryguide.core.data.sequence.RosaryGeometry
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.ThemePalette
import app.rosaryguide.core.model.BeadLocus
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

private enum class BeadState { Future, Now, Done }

@Composable
fun BeadRail(
    current: BeadLocus?,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val geometry = RosaryGeometry.shared
    val stroke = with(LocalDensity.current) { 1.4.dp.toPx() }
    val reduceMotion = LocalReduceMotion.current
    val crucifixImage = ImageBitmap.imageResource(R.drawable.crucifix)
    val phase = if (reduceMotion) {
        0.45f
    } else {
        val transition = rememberInfiniteTransition(label = "beadHalo")
        val animated = transition.animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = 1120, easing = LinearEasing),
            ),
            label = "beadHaloPhase",
        )
        animated.value
    }
    // Phase 0 is a tight, opaque burst. iOS refs are captured later in the
    // cycle as a large faint halo — especially in dark, where a t=0 ring
    // reads as a solid blue circle on the crucifix. Start 72% through.
    val settled = if (reduceMotion) 0.45f else (phase + 0.72f) % 1f
    val wave = easeOutCubic(settled)
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(96.dp),
    ) {
        val scale = min(size.width / geometry.viewW.toFloat(), size.height / geometry.viewH.toFloat())
        val ox = ((size.width - geometry.viewW * scale) / 2f).toFloat()
        val oy = ((size.height - geometry.viewH * scale) / 2f).toFloat()
        fun map(x: Double, y: Double) = Offset((ox + x * scale).toFloat(), (oy + y * scale).toFloat())

        val cord = mix(palette.dim, palette.prayBg, if (palette.isDark) 0.40f else 0.55f)
        drawPath(pathFrom(geometry.pendantPath, ox, oy, scale), color = cord, style = Stroke(stroke, cap = StrokeCap.Round))
        drawPath(pathFrom(geometry.loopPath, ox, oy, scale), color = cord, style = Stroke(stroke, cap = StrokeCap.Round))

        val pulsePoint: Offset? = when (current) {
            is BeadLocus.Crucifix -> map(geometry.crucifix.x, geometry.crucifix.y)
            is BeadLocus.Closing, is BeadLocus.DecadeOurFather ->
                if (current is BeadLocus.Closing || (current is BeadLocus.DecadeOurFather && current.decade == 1))
                    map(geometry.medal.x, geometry.medal.y)
                else geometry.beads.firstOrNull { it.locus == current && !it.isSpace }?.let { map(it.point.x, it.point.y) }
                    ?: geometry.beads.firstOrNull { it.locus == current }?.let { map(it.point.x, it.point.y) }
            else -> geometry.beads.firstOrNull { it.locus == current }?.let { map(it.point.x, it.point.y) }
        }
        if (pulsePoint != null) {
            val large = geometry.beads.firstOrNull { it.locus == current }?.large == true
            val isSpace = geometry.beads.firstOrNull { it.locus == current }?.isSpace == true
            val (baseRadius, expansion, lineWidth) = when (current) {
                is BeadLocus.Crucifix -> Triple(15.0, 17.0, 2.2)
                is BeadLocus.Closing -> Triple(14.0, 16.0, 2.0)
                is BeadLocus.DecadeOurFather ->
                    if (current.decade == 1) Triple(14.0, 16.0, 2.0)
                    else if (large) Triple(7.0, 7.4, 1.45) else Triple(5.2, 5.8, 1.2)
                else -> when {
                    isSpace -> Triple(7.0, 7.2, 1.35)
                    large -> Triple(7.0, 7.4, 1.45)
                    else -> Triple(5.2, 5.8, 1.2)
                }
            }
            val outerR = ((baseRadius + expansion * wave) * scale).toFloat()
            val innerR = (max(baseRadius * 0.62, baseRadius - expansion * 0.16) * scale).toFloat()
            val outerOpacity = if (reduceMotion) 0.42f else 0.72f * (1f - wave)
            val fillOpacity = if (reduceMotion) 0.26f else 0.44f * (1f - wave)
            drawCircle(
                color = palette.beadPulseFill.copy(alpha = fillOpacity),
                radius = innerR,
                center = pulsePoint,
            )
            drawCircle(
                color = palette.beadPulseStroke.copy(alpha = outerOpacity),
                radius = outerR,
                center = pulsePoint,
                style = Stroke(width = (lineWidth * scale).toFloat()),
            )
        }

        for (bead in geometry.beads) {
            val center = map(bead.point.x, bead.point.y)
            val state = beadState(current, bead.locus)
            if (bead.isSpace) {
                if (state == BeadState.Now) {
                    drawCircle(
                        color = palette.accent.copy(alpha = 0.18f),
                        radius = 6f * scale,
                        center = center,
                    )
                }
                continue
            }
            val radius = (geometry.radiusOf(bead) * scale).toFloat()
            val fill = when (state) {
                BeadState.Now -> palette.accent
                BeadState.Done -> mix(palette.ink, palette.prayBg, 0.74f)
                BeadState.Future -> mix(palette.ink, palette.prayBg, 0.34f)
            }
            drawCircle(color = palette.prayBg, radius = radius, center = center)
            drawCircle(color = fill, radius = radius, center = center)
            val shineR = max(0.38f, radius * 0.19f)
            val shineOp = if (state == BeadState.Future) {
                if (palette.isDark) 0.38f else 0.62f
            } else {
                if (palette.isDark) 0.22f else 0.32f
            }
            drawCircle(
                color = palette.beadHighlight.copy(alpha = shineOp),
                radius = shineR,
                center = Offset(center.x - radius * 0.40f, center.y - radius * 0.44f),
            )
        }

        paintMedal(
            palette = palette,
            center = map(geometry.medal.x, geometry.medal.y),
            scale = scale,
            state = beadState(current, BeadLocus.Closing).let {
                if (current is BeadLocus.DecadeOurFather && current.decade == 1) BeadState.Now else it
            },
        )
        paintCrucifix(
            image = crucifixImage,
            center = map(geometry.crucifix.x, geometry.crucifix.y),
            scale = scale,
            palette = palette,
            state = beadState(current, BeadLocus.Crucifix),
        )
    }
}

private fun easeOutCubic(value: Float): Float {
    val t = value.coerceIn(0f, 1f)
    return 1f - (1f - t) * (1f - t) * (1f - t)
}

private fun mix(fg: Color, bg: Color, amount: Float): Color {
    val t = amount.coerceIn(0f, 1f)
    return Color(
        red = bg.red + (fg.red - bg.red) * t,
        green = bg.green + (fg.green - bg.green) * t,
        blue = bg.blue + (fg.blue - bg.blue) * t,
        alpha = 1f,
    )
}

private fun beadOrder(bead: BeadLocus): Int = when (bead) {
    is BeadLocus.Crucifix -> 0
    is BeadLocus.OpeningOurFather -> 1
    is BeadLocus.OpeningHail -> 1 + bead.n
    is BeadLocus.OpeningGlory -> 5
    is BeadLocus.DecadeOurFather -> 100 * bead.decade
    is BeadLocus.DecadeHail -> 100 * bead.decade + bead.hail
    is BeadLocus.DecadeGlory -> 100 * bead.decade + 11
    is BeadLocus.DecadeFatima -> 100 * bead.decade + 12
    is BeadLocus.Closing -> 1000
}

private fun locusMatches(a: BeadLocus, b: BeadLocus): Boolean {
    if (a == b) return true
    if (a is BeadLocus.DecadeGlory && b is BeadLocus.DecadeFatima && a.decade == b.decade) return true
    if (a is BeadLocus.DecadeFatima && b is BeadLocus.DecadeGlory && a.decade == b.decade) return true
    return false
}

private fun beadState(current: BeadLocus?, candidate: BeadLocus): BeadState {
    if (current == null) return BeadState.Future
    if (candidate is BeadLocus.Closing && current is BeadLocus.DecadeOurFather && current.decade == 1) {
        return BeadState.Now
    }
    if (locusMatches(current, candidate)) return BeadState.Now
    if (beadOrder(candidate) < beadOrder(current)) return BeadState.Done
    return BeadState.Future
}

private fun DrawScope.paintMedal(
    palette: ThemePalette,
    center: Offset,
    scale: Float,
    state: BeadState,
) {
    val rimW = 18.6f * scale
    val rimH = 13.5f * scale
    val fieldW = 14.8f * scale
    val fieldH = 10.36f * scale
    val rimFill = if (state == BeadState.Future) palette.beadMedalRimFuture else palette.beadMedalRim
    drawOval(
        color = rimFill,
        topLeft = Offset(center.x - rimW / 2f, center.y - rimH / 2f),
        size = Size(rimW, rimH),
    )
    drawOval(
        color = palette.beadMedalField,
        topLeft = Offset(center.x - fieldW / 2f, center.y - fieldH / 2f),
        size = Size(fieldW, fieldH),
    )
    val glyph = Path().apply {
        moveTo(center.x - 2.2f * scale, center.y + 2.0f * scale)
        lineTo(center.x - 2.2f * scale, center.y - 1.5f * scale)
        lineTo(center.x, center.y + 0.55f * scale)
        lineTo(center.x + 2.2f * scale, center.y - 1.5f * scale)
        lineTo(center.x + 2.2f * scale, center.y + 2.0f * scale)
    }
    drawPath(
        path = glyph,
        color = palette.beadMedalGlyph,
        style = Stroke(width = 0.7f * scale, cap = StrokeCap.Round),
    )
}

private fun DrawScope.paintCrucifix(
    image: ImageBitmap,
    center: Offset,
    scale: Float,
    palette: ThemePalette,
    state: BeadState,
) {
    val cxH = 40f * scale
    val cxW = cxH * 0.503f
    val alpha = if (state == BeadState.Future) {
        if (palette.isDark) 0.80f else 0.88f
    } else {
        1f
    }
    rotate(degrees = 90f, pivot = center) {
        if (image.width > 0 && image.height > 0) {
            drawImage(
                image = image,
                dstOffset = IntOffset(
                    (center.x - cxW / 2f).toInt(),
                    (center.y - cxH / 2f).toInt(),
                ),
                dstSize = IntSize(cxW.toInt().coerceAtLeast(1), cxH.toInt().coerceAtLeast(1)),
                alpha = alpha,
            )
        } else {
            val ink = palette.ink.copy(alpha = 0.9f * alpha)
            drawRect(
                color = ink,
                topLeft = Offset(center.x - 1.15f * scale, center.y - cxH / 2f),
                size = Size(2.3f * scale, cxH),
            )
            drawRect(
                color = ink,
                topLeft = Offset(center.x - cxW * 0.42f, center.y - cxH * 0.18f),
                size = Size(cxW * 0.84f, 2.3f * scale),
            )
        }
    }
}

private fun pathFrom(commands: List<PathCommand>, ox: Float, oy: Float, scale: Float): Path {
    val path = Path()
    for (cmd in commands) {
        when (cmd.type) {
            PathCommand.Type.Move -> path.moveTo((ox + cmd.x * scale).toFloat(), (oy + cmd.y * scale).toFloat())
            PathCommand.Type.Line -> path.lineTo((ox + cmd.x * scale).toFloat(), (oy + cmd.y * scale).toFloat())
            PathCommand.Type.Arc -> appendArc(path, cmd, ox, oy, scale)
            PathCommand.Type.Close -> path.close()
        }
    }
    return path
}

/** Approximate a circular arc with line segments so Canvas can stroke the stadium loop. */
private fun appendArc(path: Path, cmd: PathCommand, ox: Float, oy: Float, scale: Float) {
    val sweep = if (cmd.clockwise) cmd.startAngle - cmd.endAngle else cmd.endAngle - cmd.startAngle
    val steps = 12
    for (i in 1..steps) {
        val t = i / steps.toDouble()
        val angle = cmd.startAngle + sweep * t
        val x = cmd.cx + cos(angle) * cmd.radius
        val y = cmd.cy + sin(angle) * cmd.radius
        path.lineTo((ox + x * scale).toFloat(), (oy + y * scale).toFloat())
    }
}

@Suppress("unused")
private const val Tau = PI * 2
