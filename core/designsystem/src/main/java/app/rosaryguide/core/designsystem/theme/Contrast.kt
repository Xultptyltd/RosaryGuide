package app.rosaryguide.core.designsystem.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * WCAG 2.x contrast, ported from iOS `ContrastTokenTests`.
 * Semi-transparent [background] is composited over optional [under] before the ratio is taken.
 */
object Contrast {
    fun contrastRatio(foreground: Color, background: Color, under: Color? = null): Double {
        val back = rgba(background, over = under)
        val front = rgba(foreground, over = null)
        val la = luminance(front)
        val lb = luminance(back)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private fun rgba(color: Color, over: Color?): Triple<Double, Double, Double> {
        val r = color.red.toDouble()
        val g = color.green.toDouble()
        val b = color.blue.toDouble()
        val a = color.alpha.toDouble()
        if (a >= 1.0 || over == null) return Triple(r, g, b)
        val under = rgba(over, over = null)
        return Triple(
            r * a + under.first * (1 - a),
            g * a + under.second * (1 - a),
            b * a + under.third * (1 - a),
        )
    }

    private fun luminance(c: Triple<Double, Double, Double>): Double {
        fun lin(v: Double): Double = if (v <= 0.04045) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
        return 0.2126 * lin(c.first) + 0.7152 * lin(c.second) + 0.0722 * lin(c.third)
    }
}

fun Color.toArgbLong(): Long = toArgb().toLong() and 0xFFFFFFFFL
