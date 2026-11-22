package app.rosaryguide.core.designsystem.component

import android.os.Build
import android.graphics.RenderEffect as AndroidRenderEffect
import android.graphics.Shader as AndroidShader
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace

/**
 * iOS-sized sheet grabber: 36×4 pt, ~5 pt from the sheet top, no extra bottom padding.
 * Content then uses [RosarySpace.sheetHandleToContent] (24 dp) so the first line sits
 * where iOS places “Memorial · …” under the drag indicator.
 */
@Composable
fun GuideSheetDragHandle(modifier: Modifier = Modifier) {
    val isDark = LocalThemePalette.current.isDark
    val fill = if (isDark) Color(0xFF8E8E93) else Color(0xFFC5C5C7)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = RosarySpace.sheetDragHandleTopPadding),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(
                    width = RosarySpace.sheetDragHandleWidth,
                    height = RosarySpace.sheetDragHandleHeight,
                )
                .clip(RoundedCornerShape(percent = 50))
                .background(fill),
        )
    }
}

/**
 * Translucent fill and a hairline border, approximating iOS glass.
 * On API 31+ a light RenderEffect blur is applied to this layer only when
 * [blur] is true; keep it false on any box that also draws sharp labels.
 */
fun Modifier.guideGlass(isDark: Boolean, shape: Shape, blur: Boolean = false): Modifier = composed {
    val fill = if (isDark) Color.White.copy(alpha = 0.16f) else Color.White.copy(alpha = 0.58f)
    val stroke = if (isDark) Color.White.copy(alpha = 0.28f) else Color.White.copy(alpha = 0.72f)
    val hairline = 0.5.dp
    val base = this.clip(shape)
    val maybeBlur = if (blur && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        base.graphicsLayer {
            clip = true
            renderEffect = AndroidRenderEffect
                .createBlurEffect(20f, 20f, AndroidShader.TileMode.CLAMP)
                .asComposeRenderEffect()
        }
    } else {
        base
    }
    maybeBlur
        .background(fill, shape)
        .border(hairline, stroke, shape)
}

@Composable
fun GuideGlassSurface(
    isDark: Boolean,
    shape: Shape,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    // Do not place a fillMaxSize child here: that expands a wrap-content tab bar
    // to the full window and covers Today. Glass is the background of this box.
    Box(
        modifier = modifier
            .clip(shape)
            .guideGlass(isDark, shape, blur = false),
    ) {
        content()
    }
}
