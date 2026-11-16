package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.FeastCoverMath
import app.rosaryguide.core.data.art.FeastSubjects
import app.rosaryguide.core.data.art.SizeF
import app.rosaryguide.core.data.catalog.FeastNarratives
import app.rosaryguide.core.data.catalog.FeastScriptures
import app.rosaryguide.core.data.catalog.HomeCopy
import app.rosaryguide.core.data.catalog.resolvedTagline
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun FeastDetailScreen(
    item: DatedFeast,
    onPray: () -> Unit,
    modifier: Modifier = Modifier,
    chromeOverlapPx: Float = 0f,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val density = LocalDensity.current
    val resId = feastHeroDrawableId(context, item.feast.id)
    val narrative = FeastNarratives.narrative(item.feast.id)
    val about = narrative?.about ?: item.feast.summary
    val history = narrative?.history
    val indulgence = narrative?.indulgence
    val passages = FeastScriptures.passages(item.feast.id)
    val related = narrative?.relatedPrayers.orEmpty()
    val dateLabel = item.date.format(DateTimeFormatter.ofPattern("EEEE d MMMM yyyy", Locale.getDefault()))
    val heroHeight = 280.dp

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xxl),
    ) {
        if (resId != 0) {
            val subject = FeastSubjects.ofFeastId(item.feast.id)
            val frameW = with(density) { 400.dp.toPx() }
            val frameH = with(density) { heroHeight.toPx() }
            val cover = if (subject != null) {
                FeastCoverMath.feastCover(
                    SizeF(1280f, 720f),
                    SizeF(frameW, frameH),
                    subject,
                    subject.focusX,
                )
            } else {
                null
            }
            val shift = FeastCoverMath.feastChromeShift(chromeOverlapPx, frameH)
            if (cover != null) {
                CroppedArt(
                    painter = painterResource(resId),
                    scale = cover.scale,
                    offsetX = cover.offsetX,
                    offsetY = cover.offsetY + shift,
                    contentDescription = item.feast.name.english,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(heroHeight),
                )
            }
        }
        Column(Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)) {
            Text(text = dateLabel, style = RosaryType.caption, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = item.feast.name.english, style = RosaryType.headingPrimary, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = item.feast.rank.title, style = RosaryType.supportingLabel, color = palette.dim)
            val tagline = item.feast.resolvedTagline
            if (tagline.isNotBlank()) {
                Spacer(Modifier.height(RosarySpace.sm))
                Text(text = tagline, style = RosaryType.body, color = palette.ink)
            }
            if (item.feast.recommendsOnHome && item.feast.suggestedMysterySet != null) {
                Spacer(Modifier.height(RosarySpace.lg))
                GuidePrimaryButton(
                    title = HomeCopy.prayTheMysteries(item.feast.suggestedMysterySet!!),
                    onClick = onPray,
                )
            }
            Spacer(Modifier.height(RosarySpace.xl))
            Text(text = "About", style = RosaryType.headingSecondary, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(text = about, style = RosaryType.serifBody, color = palette.ink)
            if (!history.isNullOrBlank()) {
                Spacer(Modifier.height(RosarySpace.xl))
                Text(text = "History", style = RosaryType.headingSecondary, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.sm))
                Text(text = history, style = RosaryType.serifBody, color = palette.ink)
            }
            if (!indulgence.isNullOrBlank()) {
                Spacer(Modifier.height(RosarySpace.xl))
                Text(text = "Indulgence", style = RosaryType.headingSecondary, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.sm))
                Text(text = indulgence, style = RosaryType.serifBody, color = palette.ink)
            }
            if (passages.isNotEmpty()) {
                Spacer(Modifier.height(RosarySpace.xl))
                Text(text = "Scripture", style = RosaryType.headingSecondary, color = palette.ink)
                passages.forEach { passage ->
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(text = passage.heading, style = RosaryType.caption, color = palette.accentText)
                    Spacer(Modifier.height(2.dp))
                    Text(text = passage.citation, style = RosaryType.supportingLabel, color = palette.dim)
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(text = passage.text, style = RosaryType.serifBody, color = palette.ink)
                }
            }
            if (related.isNotEmpty()) {
                Spacer(Modifier.height(RosarySpace.xl))
                Text(text = "Related prayers", style = RosaryType.headingSecondary, color = palette.ink)
                related.forEach { prayer ->
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(text = prayer.title, style = RosaryType.body, color = palette.ink)
                    prayer.note?.let {
                        Spacer(Modifier.height(2.dp))
                        Text(text = it, style = RosaryType.caption, color = palette.dim)
                    }
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(text = prayer.english, style = RosaryType.serifBody, color = palette.ink)
                    prayer.latin?.let { latin ->
                        Spacer(Modifier.height(RosarySpace.sm))
                        Text(text = latin, style = RosaryType.serifItalicBody, color = palette.dim)
                    }
                }
            }
        }
    }
}
