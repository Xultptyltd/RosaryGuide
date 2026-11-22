package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.mysteryPlateDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.CompletionQuote
import app.rosaryguide.core.model.MysterySetKind
import kotlinx.coroutines.delay

@Composable
fun CompletionScreen(
    mysterySet: MysterySetKind,
    quote: CompletionQuote,
    intentionTitles: List<String>,
    includeSaintMichael: Boolean,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
    onMichael: (() -> Unit)? = if (includeSaintMichael) ({}) else null,
    onReadyForReview: () -> Unit = {},
) {
    LaunchedEffect(Unit) {
        delay(app.rosaryguide.core.data.notify.ReviewPromptGate.SETTLE_DELAY_MS)
        onReadyForReview()
    }

    val palette = LocalThemePalette.current
    val fade = palette.completionBackground
    val offered = intentionTitles.map { it.trim() }.filter { it.isNotEmpty() }
    val showQuote = offered.isEmpty()
    val context = LocalContext.current
    // Match the iOS finish screen: the first mystery of the set just prayed
    // (Annunciation for a Joyful Rosary).
    val plateMystery = MysteryCatalog.mysteries(mysterySet).firstOrNull()
    val resId = plateMystery?.let { mysteryPlateDrawableId(context, it.artSlug) } ?: 0

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(fade)
            // 16 dp keeps Saint Michael clear of the Pixel 7 gesture pill.
            // Title / Done still have budget inside the 2% band (they were
            // 0.35% high and 1.45% low at 6 dp).
            .padding(bottom = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .clipToBounds(),
        ) {
            if (resId != 0 && plateMystery != null) {
                val painter = painterResource(resId)
                // iOS fills the leftover above the tick edge-to-edge
                // (FocusedRasterImage + ArtCatalog.focus, Annunciation y = 0.30),
                // with a Space.xl downward shift clipped to the frame and a
                // soft bottom fade. The tall window cover-crops the sides
                // (no lectern) and enlarges the figures.
                CroppedArt(
                    painter = painter,
                    coverForFrame = { frameW, frameH ->
                        val src = painter.intrinsicSize
                        ArtCatalog.coverForFocus(
                            sourceWidth = if (src.width.isFinite() && src.width > 1f) src.width else 1280f,
                            sourceHeight = if (src.height.isFinite() && src.height > 1f) src.height else 853f,
                            frameWidth = frameW,
                            frameHeight = frameH,
                            focusX = 0.5f,
                            focusY = ArtCatalog.focusY(mysterySet, plateMystery.number),
                        )
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .offset(y = RosarySpace.xl),
                )
            }
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .drawWithContent {
                        drawContent()
                        drawRect(
                            brush = Brush.verticalGradient(
                                colorStops = arrayOf(
                                    0f to fade.copy(alpha = 0.18f),
                                    0.12f to Color.Transparent,
                                    0.46f to Color.Transparent,
                                    0.62f to fade.copy(alpha = 0.16f),
                                    0.76f to fade.copy(alpha = 0.40f),
                                    0.90f to fade.copy(alpha = 0.72f),
                                    1f to fade,
                                ),
                            ),
                        )
                    },
            )
        }
        val playTick = android.os.Build.FINGERPRINT.lowercase() != "robolectric"
        // iOS iconSlot: padding.top xs, padding.bottom -10. The art Box is
        // weight(1f) and now fills the leftover down to the tick, so the
        // fade meets the check the way iOS does.
        Spacer(Modifier.height(RosarySpace.xs))
        RosaryTickPlayer(
            size = 88.dp,
            plays = playTick,
            tickColor = palette.completionTick,
            modifier = Modifier.padding(top = RosarySpace.xs),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .offset(y = (-10).dp)
                .padding(horizontal = RosarySpace.gutter),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "ROSARY COMPLETE",
                style = RosaryType.caption.copy(
                    letterSpacing = 1.4.sp,
                    platformStyle = PlatformTextStyle(includeFontPadding = false),
                ),
                color = palette.completionMeta,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "${mysterySet.shortName} Mysteries",
                style = RosaryType.headingPrimary.copy(
                    platformStyle = PlatformTextStyle(includeFontPadding = false),
                ),
                color = palette.completionTitle,
                textAlign = TextAlign.Center,
            )
            if (showQuote) {
                Spacer(Modifier.height(40.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(palette.surface, RoundedCornerShape(RosarySpace.containerRadius))
                        .padding(horizontal = RosarySpace.lg, vertical = 14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text = quote.text,
                        style = RosaryType.body,
                        color = palette.completionTitle.copy(alpha = 0.88f),
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(RosarySpace.sm))
                    Text(
                        text = quote.attribution.uppercase(),
                        style = RosaryType.supportingLabel.copy(letterSpacing = 0.8.sp),
                        color = palette.completionLabel,
                        textAlign = TextAlign.Center,
                    )
                }
            } else {
                Spacer(Modifier.height(32.dp))
                Text(
                    text = "OFFERED FOR",
                    style = RosaryType.caption.copy(letterSpacing = 1.2.sp),
                    color = palette.completionMeta,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Start,
                )
                Spacer(Modifier.height(RosarySpace.sm))
                Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
                    offered.forEach { title ->
                        Text(
                            text = title,
                            style = RosaryType.body,
                            color = palette.completionMetaValue,
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(palette.surface, RoundedCornerShape(RosarySpace.nestedRadius))
                                .padding(horizontal = 14.dp, vertical = 12.dp),
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(36.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .offset(y = (-10).dp)
                .padding(horizontal = RosarySpace.gutter),
            verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
        ) {
            GuidePrimaryButton(title = "Done", onClick = onDone)
            val michael = onMichael
            if (includeSaintMichael && michael != null) {
                GuideSecondaryButton(title = "Saint Michael Prayer", onClick = michael)
            }
        }
    }
}
