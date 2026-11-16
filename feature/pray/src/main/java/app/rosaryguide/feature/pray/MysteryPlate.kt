package app.rosaryguide.feature.pray

import androidx.compose.foundation.Image
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.mysteryPlateDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.Mystery
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryStep

/**
 * Mystery-announcement plate, ported from iOS `PlateArtView` / `plateScrim`
 * (the rg-plate-fade treatment): wide art with a top vignette and a bottom
 * dissolve into the page, then the ordinal eyebrow, title, scripture, and fruit.
 */
@Composable
fun MysteryPlate(
    step: RosaryStep,
    language: PrayerLanguage,
    modifier: Modifier = Modifier,
    artHeight: androidx.compose.ui.unit.Dp = 320.dp,
) {
    val palette = LocalThemePalette.current
    val mystery = step.mystery ?: return
    val context = LocalContext.current
    val resId = mysteryPlateDrawableId(context, mystery.artSlug)
    val fade = palette.bg
    val ordinal = ordinalWord(mystery.number)
    val eyebrow = "$ordinal ${mystery.set.shortName}".uppercase()

    Column(modifier = modifier.fillMaxWidth()) {
        if (resId != 0) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(artHeight)
                    .clipToBounds(),
            ) {
                Image(
                    painter = painterResource(resId),
                    contentDescription = mystery.title.english,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
                // Top vignette + bottom dissolve (iOS plateScrim with bottomFade).
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .plateFade(fade),
                )
            }
        }
        Column(Modifier.padding(horizontal = RosarySpace.gutter)) {
            Spacer(Modifier.height(RosarySpace.md))
            Text(
                text = eyebrow,
                style = RosaryType.supportingLabel,
                color = palette.dim,
            )
            Spacer(Modifier.height(RosarySpace.xs))
            Text(
                text = mystery.title.resolved(language),
                style = RosaryType.headingPrimary,
                color = palette.ink,
            )
            Spacer(Modifier.height(RosarySpace.sm))
            val excerpt = step.body
            Text(
                text = excerpt.primary(language),
                style = RosaryType.serifBody,
                color = palette.ink,
            )
            excerpt.secondary(language)?.let { latin ->
                Spacer(Modifier.height(RosarySpace.sm))
                Text(text = latin, style = RosaryType.serifItalicBody, color = palette.dim)
            }
            step.scriptureReference?.let { ref ->
                Spacer(Modifier.height(RosarySpace.xs))
                Text(text = ref, style = RosaryType.caption, color = palette.dim)
            }
            Spacer(Modifier.height(RosarySpace.lg))
            HorizontalDivider(color = palette.strokeSubtle)
            Spacer(Modifier.height(RosarySpace.md))
            val fruit = mystery.fruit.resolved(language)
            if (fruit.isNotBlank()) {
                Row {
                    Text(text = "Fruit  ", style = RosaryType.supportingLabel, color = palette.dim)
                    Text(text = fruit, style = RosaryType.body, color = palette.ink)
                }
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
