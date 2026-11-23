package app.rosaryguide.feature.settings

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

/** SF Symbol stand-ins for Settings rows. */
object SettingsSymbols {
    val sliderHorizontal3: ImageVector
        get() = _slider ?: image(20f, "SliderHorizontal3") {
            val s = SolidColor(Color.Black)
            path(fill = null, stroke = s, strokeLineWidth = 1.6f, strokeLineCap = StrokeCap.Round) {
                moveTo(3f, 6f); lineTo(17f, 6f)
                moveTo(3f, 10.5f); lineTo(17f, 10.5f)
                moveTo(3f, 15f); lineTo(17f, 15f)
            }
            path(fill = s) {
                knob(7.2f, 6f)
                knob(12.2f, 10.5f)
                knob(6.2f, 15f)
            }
        }.also { _slider = it }

    val circleLeftHalfFilled: ImageVector
        get() = _half ?: image(20f, "CircleLeftHalfFilled") {
            val s = SolidColor(Color.Black)
            path(fill = null, stroke = s, strokeLineWidth = 1.5f) {
                moveTo(17.5f, 10f)
                arcTo(7.5f, 7.5f, 0f, true, true, 2.5f, 10f)
                arcTo(7.5f, 7.5f, 0f, true, true, 17.5f, 10f)
                close()
            }
            path(fill = s) {
                moveTo(10f, 2.5f)
                arcTo(7.5f, 7.5f, 0f, false, false, 10f, 17.5f)
                close()
            }
        }.also { _half = it }

    val app: ImageVector
        get() = _app ?: image(20f, "App") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.5f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                moveTo(6.4f, 3.4f)
                lineTo(13.6f, 3.4f)
                arcTo(3f, 3f, 0f, false, true, 16.6f, 6.4f)
                lineTo(16.6f, 13.6f)
                arcTo(3f, 3f, 0f, false, true, 13.6f, 16.6f)
                lineTo(6.4f, 16.6f)
                arcTo(3f, 3f, 0f, false, true, 3.4f, 13.6f)
                lineTo(3.4f, 6.4f)
                arcTo(3f, 3f, 0f, false, true, 6.4f, 3.4f)
                close()
            }
        }.also { _app = it }

    val exclamationBubble: ImageVector
        get() = _bubble ?: image(20f, "ExclamationBubble") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.5f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                moveTo(4.2f, 3.6f)
                lineTo(15.8f, 3.6f)
                arcTo(2.4f, 2.4f, 0f, false, true, 18.2f, 6f)
                lineTo(18.2f, 12.2f)
                arcTo(2.4f, 2.4f, 0f, false, true, 15.8f, 14.6f)
                lineTo(9.2f, 14.6f)
                lineTo(5f, 17.6f)
                lineTo(5f, 14.6f)
                lineTo(4.2f, 14.6f)
                arcTo(2.4f, 2.4f, 0f, false, true, 1.8f, 12.2f)
                lineTo(1.8f, 6f)
                arcTo(2.4f, 2.4f, 0f, false, true, 4.2f, 3.6f)
                close()
            }
            path(fill = s) {
                moveTo(9.3f, 6.1f)
                lineTo(10.7f, 6.1f)
                lineTo(10.4f, 11.05f)
                lineTo(9.6f, 11.05f)
                close()
                moveTo(9.3f, 12.25f)
                lineTo(10.7f, 12.25f)
                lineTo(10.7f, 13.65f)
                lineTo(9.3f, 13.65f)
                close()
            }
        }.also { _bubble = it }

    val arrowUpRight: ImageVector
        get() = _arrow ?: image(12f, "ArrowUpRight") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.6f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                moveTo(3.2f, 8.8f)
                lineTo(8.8f, 3.2f)
                moveTo(4.4f, 3.2f)
                lineTo(8.8f, 3.2f)
                lineTo(8.8f, 7.6f)
            }
        }.also { _arrow = it }


    val lightbulb: ImageVector
        get() = _bulb ?: image(20f, "Lightbulb") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.5f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                // bulb
                moveTo(7.2f, 11.8f)
                arcTo(4.8f, 4.8f, 0f, true, true, 12.8f, 11.8f)
                lineTo(12.2f, 14.2f)
                lineTo(7.8f, 14.2f)
                close()
                moveTo(8f, 15.6f)
                lineTo(12f, 15.6f)
                moveTo(8.4f, 17.2f)
                lineTo(11.6f, 17.2f)
            }
        }.also { _bulb = it }

    val sparkles: ImageVector
        get() = _spark ?: image(20f, "Sparkles") {
            val s = SolidColor(Color.Black)
            path(fill = s) {
                // four-point star
                moveTo(8.5f, 2.4f)
                lineTo(9.6f, 6.6f)
                lineTo(13.8f, 7.7f)
                lineTo(9.6f, 8.8f)
                lineTo(8.5f, 13f)
                lineTo(7.4f, 8.8f)
                lineTo(3.2f, 7.7f)
                lineTo(7.4f, 6.6f)
                close()
                moveTo(14.6f, 10.8f)
                lineTo(15.2f, 13.2f)
                lineTo(17.6f, 13.8f)
                lineTo(15.2f, 14.4f)
                lineTo(14.6f, 16.8f)
                lineTo(14f, 14.4f)
                lineTo(11.6f, 13.8f)
                lineTo(14f, 13.2f)
                close()
            }
        }.also { _spark = it }

    val docText: ImageVector
        get() = _doc ?: image(20f, "DocText") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.5f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                moveTo(6f, 3.2f)
                lineTo(11.2f, 3.2f)
                lineTo(16f, 8f)
                lineTo(16f, 16.4f)
                arcTo(1.6f, 1.6f, 0f, false, true, 14.4f, 18f)
                lineTo(6f, 18f)
                arcTo(1.6f, 1.6f, 0f, false, true, 4.4f, 16.4f)
                lineTo(4.4f, 4.8f)
                arcTo(1.6f, 1.6f, 0f, false, true, 6f, 3.2f)
                close()
                moveTo(11.2f, 3.2f)
                lineTo(11.2f, 8f)
                lineTo(16f, 8f)
                moveTo(7.2f, 11.2f)
                lineTo(12.8f, 11.2f)
                moveTo(7.2f, 14.2f)
                lineTo(11.6f, 14.2f)
            }
        }.also { _doc = it }

    val handRaised: ImageVector
        get() = _hand ?: image(20f, "HandRaised") {
            val s = SolidColor(Color.Black)
            path(
                fill = null,
                stroke = s,
                strokeLineWidth = 1.5f,
                strokeLineCap = StrokeCap.Round,
                strokeLineJoin = StrokeJoin.Round,
            ) {
                // simplified raised hand
                moveTo(7.2f, 9.2f)
                lineTo(7.2f, 4.6f)
                arcTo(1.1f, 1.1f, 0f, false, true, 9.4f, 4.6f)
                lineTo(9.4f, 8.6f)
                moveTo(9.4f, 8.2f)
                lineTo(9.4f, 3.8f)
                arcTo(1.1f, 1.1f, 0f, false, true, 11.6f, 3.8f)
                lineTo(11.6f, 8.4f)
                moveTo(11.6f, 8.2f)
                lineTo(11.6f, 5.2f)
                arcTo(1.1f, 1.1f, 0f, false, true, 13.8f, 5.2f)
                lineTo(13.8f, 10.6f)
                arcTo(4.4f, 4.4f, 0f, false, true, 9.4f, 15f)
                lineTo(8.2f, 15f)
                arcTo(3.6f, 3.6f, 0f, false, true, 4.6f, 11.4f)
                lineTo(4.6f, 9.6f)
                arcTo(1.1f, 1.1f, 0f, false, true, 6.8f, 9.6f)
                lineTo(6.8f, 11f)
            }
        }.also { _hand = it }

    private var _slider: ImageVector? = null
    private var _half: ImageVector? = null
    private var _app: ImageVector? = null
    private var _bubble: ImageVector? = null
    private var _arrow: ImageVector? = null
    private var _bulb: ImageVector? = null
    private var _spark: ImageVector? = null
    private var _doc: ImageVector? = null
    private var _hand: ImageVector? = null
}

private fun image(
    size: Float,
    name: String,
    block: ImageVector.Builder.() -> Unit,
): ImageVector = ImageVector.Builder(
    name = name,
    defaultWidth = size.dp,
    defaultHeight = size.dp,
    viewportWidth = size,
    viewportHeight = size,
).apply(block).build()

private fun androidx.compose.ui.graphics.vector.PathBuilder.knob(cx: Float, cy: Float) {
    val r = 1.55f
    moveTo(cx + r, cy)
    arcTo(r, r, 0f, true, true, cx - r, cy)
    arcTo(r, r, 0f, true, true, cx + r, cy)
    close()
}
