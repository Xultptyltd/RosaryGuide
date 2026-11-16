package app.rosaryguide.core.designsystem.component

import android.content.Context
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.painter.Painter

/**
 * [coverForFrame] is called with the laid-out frame size in pixels and must
 * return (scale, offsetX, offsetY) with a top-left origin, matching iOS
 * `ArtCatalog.feastCover`. Computing the cover against the real frame is what
 * makes the card full-bleed.
 */
@Composable
fun CroppedArt(
    painter: Painter,
    coverForFrame: (frameWidthPx: Float, frameHeightPx: Float) -> Triple<Float, Float, Float>,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
) {
    val src = painter.intrinsicSize
    val srcW = if (src.width.isFinite() && src.width > 1f) src.width else 1280f
    val srcH = if (src.height.isFinite() && src.height > 1f) src.height else 720f
    Box(
        modifier = modifier
            .clipToBounds()
            .drawWithCache {
                val frameW = size.width.coerceAtLeast(1f)
                val frameH = size.height.coerceAtLeast(1f)
                val (scale, offsetX, offsetY) = coverForFrame(frameW, frameH)
                onDrawBehind {
                    translate(offsetX, offsetY) {
                        scale(scaleX = scale, scaleY = scale, pivot = Offset.Zero) {
                            with(painter) { draw(Size(srcW, srcH)) }
                        }
                    }
                }
            },
        content = {},
    )
    // contentDescription is reserved for a later semantics wrapper; keep the parameter.
    @Suppress("UNUSED_PARAMETER")
    val ignored = contentDescription
}

/** Legacy entry point when the cover has already been computed for this frame. */
@Composable
fun CroppedArt(
    painter: Painter,
    scale: Float,
    offsetX: Float,
    offsetY: Float,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
) {
    CroppedArt(
        painter = painter,
        coverForFrame = { _, _ -> Triple(scale, offsetX, offsetY) },
        modifier = modifier,
        contentDescription = contentDescription,
    )
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

fun mysteryPlateDrawableId(context: Context, artSlug: String): Int =
    drawableIdByName(context, "mystery_" + artSlug.replace('-', '_'))
