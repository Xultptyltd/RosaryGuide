package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
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
import app.rosaryguide.core.designsystem.component.GuideMilkyCircleChip
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.Feast

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
) {
    val palette = LocalThemePalette.current
    val status = with(LocalDensity.current) { WindowInsets.statusBars.getTop(this).toDp() }
    val nav = 44.dp
    Box(modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(status + nav)
                .background(
                    Brush.verticalGradient(
                        0f to palette.bg.copy(alpha = if (palette.isDark) 0.72f else 0.78f),
                        0.72f to palette.bg.copy(alpha = if (palette.isDark) 0.40f else 0.48f),
                        1f to palette.bg.copy(alpha = 0f),
                    ),
                ),
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .height(nav)
                .padding(horizontal = 8.dp),
        ) {
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .size(44.dp)
                .clickable(role = Role.Button, onClick = onBack),
            contentAlignment = Alignment.Center,
        ) {
            GuideMilkyCircleChip(milkyOnPlain = false) {
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
