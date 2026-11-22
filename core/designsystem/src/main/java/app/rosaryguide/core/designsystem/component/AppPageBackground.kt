package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalThemePalette

/**
 * iOS `AppPageBackground`: Marian-blue orbs over the grouped page colour.
 * Used on Learn (and iOS Home/Feasts). Static resting pose so Roborazzi is stable.
 */
@Composable
fun AppPageBackground(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val glow = palette.accent
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(palette.groupedBackground),
    ) {
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .blur(70.dp),
        ) {
            val w = size.width
            val h = size.height
            val vmax = maxOf(w, h)
            val orbs = if (palette.isDark) {
                listOf(
                    OrbSpec(0.90f, -0.35f, -0.45f, viewport = false, index = 0, opacity = 0.15f),
                    OrbSpec(0.80f, -0.40f, -0.35f, viewport = false, index = 1, opacity = 0.10f),
                    OrbSpec(0.55f, 0.25f, 0.35f, viewport = true, index = 2, opacity = 0.07f),
                )
            } else {
                listOf(
                    OrbSpec(0.90f, -0.35f, -0.45f, viewport = false, index = 0, opacity = 0.08f),
                    OrbSpec(0.80f, -0.40f, -0.35f, viewport = false, index = 1, opacity = 0.05f),
                    OrbSpec(0.55f, 0.25f, 0.35f, viewport = true, index = 2, opacity = 0.035f),
                )
            }
            orbs.forEach { orb ->
                val diameter = orb.diameter * vmax
                val x = if (orb.viewport) {
                    orb.x * w
                } else if (orb.index == 1) {
                    w - orb.x * vmax - diameter
                } else {
                    orb.x * vmax
                }
                val y = if (orb.viewport) {
                    orb.y * h
                } else if (orb.index == 1) {
                    h - orb.y * vmax - diameter
                } else {
                    orb.y * vmax
                }
                val radius = diameter / 2f
                val center = Offset(x + radius, y + radius)
                drawCircle(
                    brush = Brush.radialGradient(
                        colorStops = arrayOf(
                            0f to glow.copy(alpha = orb.opacity),
                            0.65f to glow.copy(alpha = 0f),
                        ),
                        center = center,
                        radius = radius,
                    ),
                    radius = radius,
                    center = center,
                    alpha = 0.85f,
                )
            }
        }
    }
}

private data class OrbSpec(
    val diameter: Float,
    val x: Float,
    val y: Float,
    val viewport: Boolean,
    val index: Int,
    val opacity: Float,
)
