package app.rosaryguide.core.designsystem.component

import android.content.Context
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.DpSize

/**
 * Positions a feast (or other) image using the iOS cover scale and top-leading offset.
 * The painter is laid out at its intrinsic pixel size; [scale] and [offsetX]/[offsetY]
 * are applied from the top-left, matching `FeastCover`.
 */
@Composable
fun CroppedArt(
    painter: Painter,
    scale: Float,
    offsetX: Float,
    offsetY: Float,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
) {
    val density = LocalDensity.current
    val src = painter.intrinsicSize
    val layout = if (src.width.isFinite() && src.height.isFinite() && src.width > 1f && src.height > 1f) {
        with(density) { DpSize(src.width.toDp(), src.height.toDp()) }
    } else {
        null
    }
    BoxWithConstraints(modifier = modifier.clipToBounds()) {
        val imageModifier = if (layout != null) {
            Modifier.requiredSize(layout)
        } else {
            Modifier
        }
        Image(
            painter = painter,
            contentDescription = contentDescription,
            contentScale = ContentScale.FillBounds,
            alignment = Alignment.TopStart,
            modifier = imageModifier.graphicsLayer {
                transformOrigin = TransformOrigin(0f, 0f)
                scaleX = scale
                scaleY = scale
                translationX = offsetX
                translationY = offsetY
            },
        )
    }
}

fun drawableIdByName(context: Context, name: String): Int {
    val appId = context.resources.getIdentifier(name, "drawable", context.packageName)
    if (appId != 0) return appId
    return context.resources.getIdentifier(name, "drawable", "app.rosaryguide.core.designsystem")
}

fun feastHeroDrawableId(context: Context, feastId: String): Int {
    val artId = when (feastId) {
        "mother-of-the-church" -> "assumption"
        else -> feastId
    }
    val name = "feast_" + artId.replace('-', '_')
    return drawableIdByName(context, name)
}

fun heroDrawableId(context: Context, setName: String): Int =
    drawableIdByName(context, "hero_" + setName.lowercase())
