package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.PlatformTextStyle
import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.mysteryPlateDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.Mystery
import app.rosaryguide.core.model.OrdinalWord
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryStep

/**
 * Mystery-announcement plate, ported from iOS `PlateArtView` / `plateScrim`
 * (the rg-plate-fade treatment): wide art with a top vignette and a bottom
 * dissolve into the page, then the ordinal eyebrow, title, scripture, and fruit.
 *
 * The art is a fixed hero (iOS `plateHeroImage`); only [MysteryPlateReading]
 * scrolls, so scripture moves over the painting.
 */
@Composable
fun MysteryPlate(
    step: RosaryStep,
    language: PrayerLanguage,
    modifier: Modifier = Modifier,
    artHeight: androidx.compose.ui.unit.Dp = 320.dp,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        MysteryPlateArt(step = step, modifier = Modifier.fillMaxWidth().height(artHeight))
        MysteryPlateReading(step = step, language = language)
    }
}

@Composable
fun MysteryPlateArt(
    step: RosaryStep,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val mystery = step.mystery ?: return
    val context = LocalContext.current
    val resId = mysteryPlateDrawableId(context, mystery.artSlug)
    val fade = palette.bg
    if (resId == 0) return
    val painter = painterResource(resId)
    val backdrop = if (palette.isDark) Color.Black else palette.bg
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(backdrop)
            .clipToBounds(),
    ) {
        // iOS `PlateArtView` uses FocusedRasterImage with contentMode `.fill`
        // and `ArtCatalog.bandFocus` (Annunciation y = 0.51).
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
                    focusY = ArtCatalog.bandFocusY(mystery.set, mystery.number),
                )
            },
            modifier = Modifier.fillMaxSize(),
            contentDescription = mystery.title.english,
        )
        // Top vignette + bottom dissolve (iOS plateScrim with bottomFade).
        Box(
            modifier = Modifier
                .fillMaxSize()
                .plateFade(fade),
        )
    }
}

@Composable
fun MysteryPlateReading(
    step: RosaryStep,
    language: PrayerLanguage,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val mystery = step.mystery ?: return
    val eyebrow = mystery.set.shortName.uppercase()
    // Ported from iOS `locus` + `announceBody` + `MysteryFruitLine` for a plate.
    Column(modifier.padding(horizontal = RosarySpace.gutter).padding(top = 6.dp)) {
        Row(
            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.md),
            verticalAlignment = Alignment.Top,
        ) {
            Text(
                text = OrdinalWord.roman(mystery.number),
                style = RosaryType.bodyPray.copy(fontWeight = FontWeight.Medium),
                color = palette.textSecondary,
            )
            // iOS HStack firstTextBaseline: 16 pt roman and 12 pt eyebrow share a
            // baseline. typo ascent is 0.97 of size, so the caption sits 3.88 dp lower.
            Text(
                text = eyebrow,
                style = RosaryType.captionMediumPray.copy(letterSpacing = 2.sp),
                color = palette.dim,
                modifier = Modifier.padding(top = 3.88.dp),
            )
        }
        // iOS locus stack is Space.sm (8) plus padding.bottom xs (4) under the eyebrow.
        Spacer(Modifier.height(12.dp))
        Text(
            text = mystery.title.resolved(language),
            style = RosaryType.modalTitlePray,
            color = palette.ink,
        )
        // iOS `locus` padding.bottom Space.lg before the scripture.
        Spacer(Modifier.height(RosarySpace.lg))
        val excerpt = step.body
        PrayerBody(
            text = excerpt.primary(language),
            style = RosaryType.prayerTextReading,
            color = palette.ink,
        )
        excerpt.secondary(language)?.let { latin ->
            Spacer(Modifier.height(RosarySpace.xxl))
            PrayerBody(
                text = latin,
                style = RosaryType.prayerTextReading,
                color = palette.dim,
            )
        }
        step.scriptureReference?.let { ref ->
            // iOS announceBody stack spacing (sm) under the scripture block.
            Spacer(Modifier.height(RosarySpace.sm))
            Text(
                text = ref,
                style = RosaryType.scriptureReferenceMystery,
                color = palette.dim,
            )
        }
        // iOS FruitLine `.padding(.top, Space.lg)` plus announceBody Space.sm = 24.
        Spacer(Modifier.height(RosarySpace.lg + RosarySpace.sm))
        HorizontalDivider(color = palette.strokeSubtle)
        Spacer(Modifier.height(RosarySpace.sm))
        val fruit = mystery.fruit.resolved(language)
        if (fruit.isNotBlank()) {
            Row(
                horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.sm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Fruit",
                    style = RosaryType.bodyPray.copy(
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 0.8.sp,
                    ),
                    color = palette.textSecondary,
                )
                Text(
                    text = fruit,
                    style = RosaryType.bodyPray,
                    color = palette.ink,
                )
            }
        }
    }

}

private fun Modifier.plateFade(fade: Color): Modifier =
    this.drawWithContent {
        drawContent()
        drawRect(
            brush = Brush.verticalGradient(
                colorStops = arrayOf(
                    0f to fade.copy(alpha = 0.55f),
                    0.10f to fade.copy(alpha = 0.12f),
                    0.28f to Color.Transparent,
                    0.62f to Color.Transparent,
                    1f to fade.copy(alpha = 0.92f),
                ),
            ),
        )
    }

internal fun ordinalWord(n: Int): String =
    listOf("First", "Second", "Third", "Fourth", "Fifth").getOrElse(n - 1) { n.toString() }
