package app.rosaryguide.feature.pray

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.sequence.PathCommand
import app.rosaryguide.core.data.sequence.RosaryGeometry
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.model.BeadLocus
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

@Composable
fun BeadRail(
    current: BeadLocus?,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val geometry = RosaryGeometry.shared
    val stroke = with(LocalDensity.current) { 1.4.dp.toPx() }
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(96.dp),
    ) {
        val scale = min(size.width / geometry.viewW.toFloat(), size.height / geometry.viewH.toFloat())
        val ox = ((size.width - geometry.viewW * scale) / 2f).toFloat()
        val oy = ((size.height - geometry.viewH * scale) / 2f).toFloat()
        fun map(x: Double, y: Double) = Offset((ox + x * scale).toFloat(), (oy + y * scale).toFloat())

        val cord = palette.dim.copy(alpha = 0.55f)
        drawPath(pathFrom(geometry.pendantPath, ox, oy, scale), color = cord, style = Stroke(stroke, cap = StrokeCap.Round))
        drawPath(pathFrom(geometry.loopPath, ox, oy, scale), color = cord, style = Stroke(stroke, cap = StrokeCap.Round))

        val medal = map(geometry.medal.x, geometry.medal.y)
        val medalIsCurrent = current is BeadLocus.DecadeOurFather && current.decade == 1
        drawCircle(
            color = if (medalIsCurrent) palette.accent else palette.ink,
            radius = (RosaryGeometry.R_MEDAL * scale).toFloat(),
            center = medal,
        )
        drawCircle(color = palette.bg, radius = (RosaryGeometry.R_MEDAL * scale * 0.45).toFloat(), center = medal)

        val crucifix = map(geometry.crucifix.x, geometry.crucifix.y)
        val arm = (7.0 * scale).toFloat()
        drawLine(palette.ink, crucifix - Offset(arm, 0f), crucifix + Offset(arm, 0f), strokeWidth = stroke * 2, cap = StrokeCap.Round)
        drawLine(palette.ink, crucifix - Offset(0f, arm * 1.15f), crucifix + Offset(0f, arm * 0.85f), strokeWidth = stroke * 2, cap = StrokeCap.Round)

        for (bead in geometry.beads) {
            if (bead.isSpace) continue
            val center = map(bead.point.x, bead.point.y)
            val radius = (geometry.radiusOf(bead) * scale).toFloat()
            val color: Color = when (bead.locus) {
                current -> palette.accent
                else -> palette.ink.copy(alpha = if (bead.large) 0.92f else 0.78f)
            }
            drawCircle(color = color, radius = radius, center = center)
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

// Silence unused PI import if the compiler flags it — used only if we switch to degrees.
@Suppress("unused")
private const val Tau = PI * 2
