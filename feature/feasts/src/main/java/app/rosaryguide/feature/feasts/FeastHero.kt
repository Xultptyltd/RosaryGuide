package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.FeastCover
import app.rosaryguide.core.data.art.FeastCoverMath
import app.rosaryguide.core.data.art.FeastSubjects
import app.rosaryguide.core.data.art.SizeF
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.Feast

/** iPhone 17 Pro Max logical width of the refs, used to scale hero height to this device. */
internal val FeastIosRefWidth = 440.dp

/**
 * iOS safe-area top on the Pro Max refs, so the 44 dp nav is centred at 84 pt —
 * the measured title / chevron centre — instead of sitting in the 9:41 strip.
 */
internal val FeastIosSafeAreaTop = 62.dp

internal val FeastNavHeight = 44.dp

/** iOS `padding(.top, -8)` tuck of the banner under the nav. */
internal val FeastHeroUnderlap = 8.dp

internal data class FeastChromeMetrics(
    val navTop: Dp,
    val navHeight: Dp = FeastNavHeight,
    val underlap: Dp = FeastHeroUnderlap,
) {
    val barBottom: Dp get() = navTop + navHeight
    val heroTop: Dp get() = (barBottom - underlap).coerceAtLeast(0.dp)
}

@Composable
internal fun rememberFeastChromeMetrics(): FeastChromeMetrics {
    val status = with(LocalDensity.current) { WindowInsets.statusBars.getTop(this).toDp() }
    return FeastChromeMetrics(navTop = maxOf(status, FeastIosSafeAreaTop))
}

/** iOS banner height as a fraction of the 440 pt ref width, scaled to [width]. */
internal fun feastHeroHeight(width: Dp, iOSHeight: Dp, iOSWidth: Dp = FeastIosRefWidth): Dp {
    if (iOSWidth <= 0.dp) return iOSHeight
    return iOSHeight * (width / iOSWidth)
}

@Composable
internal fun FeastHeroBanner(
    feast: Feast,
    height: Dp,
    chromeOverlapPx: Float,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = feastHeroDrawableId(context, feast.id)
    val subject = FeastSubjects.ofFeastId(feast.id)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .background(palette.bg),
    ) {
        if (resId != 0) {
            CroppedArt(
                painter = painterResource(resId),
                coverForFrame = { frameW, frameH ->
                    val cover = if (subject != null) {
                        FeastCoverMath.feastCover(
                            SizeF(1280f, 720f),
                            SizeF(frameW, frameH),
                            subject,
                            subject.focusX,
                        )
                    } else {
                        FeastCover(1f, 0f, 0f)
                    }
                    val shift = FeastCoverMath.feastChromeShift(chromeOverlapPx, frameH)
                    Triple(cover.scale, cover.offsetX, cover.offsetY + shift)
                },
                contentDescription = "Feast artwork for ${feast.shortTitle}",
                modifier = Modifier.fillMaxSize(),
            )
        }
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colorStops = arrayOf(
                            (1f - RosarySpace.feastHeroBottomFade) to palette.bg.copy(alpha = 0f),
                            1f to palette.bg,
                        ),
                    ),
                ),
        )
    }
}

@Composable
internal fun FeastOverlayChrome(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    metrics: FeastChromeMetrics = rememberFeastChromeMetrics(),
) {
    val palette = LocalThemePalette.current
    Box(modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(metrics.barBottom)
                .background(palette.bg),
        )
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .height(Hairline.thickness)
                .background(palette.hair),
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = metrics.navTop)
                .height(metrics.navHeight)
                .padding(horizontal = 8.dp),
        ) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .size(44.dp)
                    .clickable(role = Role.Button, onClick = onBack),
                contentAlignment = Alignment.Center,
            ) {
                FeastBackChip {
                    Icon(
                        painter = painterResource(R.drawable.ic_chevron_backward),
                        contentDescription = "Back",
                        tint = palette.ink,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
            Text(
                text = title,
                style = RosaryType.navigationTitlePray,
                color = palette.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(horizontal = 52.dp)
                    .fillMaxWidth(),
            )
        }
    }
}

/**
 * iOS milky toolbar back disc: solid white in light with a soft shadow,
 * a slightly lifted dark disc in dark. Local to Feasts so shared
 * [app.rosaryguide.core.designsystem.component.GuideMilkyCircleChip]
 * defaults stay put on approved screens.
 */
@Composable
private fun FeastBackChip(content: @Composable () -> Unit) {
    val palette = LocalThemePalette.current
    val fill = if (palette.isDark) Color.White.copy(alpha = 0.16f) else Color.White
    Box(
        modifier = Modifier
            .size(RosarySpace.controlSize)
            .shadow(
                elevation = if (palette.isDark) 2.dp else 3.dp,
                shape = CircleShape,
                clip = false,
                ambientColor = Color.Black.copy(alpha = if (palette.isDark) 0.40f else 0.16f),
                spotColor = Color.Black.copy(alpha = if (palette.isDark) 0.40f else 0.22f),
            )
            .background(fill, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        content()
    }
}

@Composable
internal fun FeastHeroTopSpacer(metrics: FeastChromeMetrics = rememberFeastChromeMetrics()) {
    Spacer(Modifier.height(metrics.heroTop))
}
