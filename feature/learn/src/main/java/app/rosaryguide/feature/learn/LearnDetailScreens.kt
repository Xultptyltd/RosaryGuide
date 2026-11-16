package app.rosaryguide.feature.learn

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.designsystem.component.drawableIdByName
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.Prayer

@Composable
fun LearnArticleScreen(article: LearnArticle, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)
            .padding(bottom = RosarySpace.xxl),
    ) {
        Text(text = article.eyebrow, style = RosaryType.caption, color = palette.accentText)
        Spacer(Modifier.height(RosarySpace.xs))
        Text(text = article.title, style = RosaryType.headingPrimary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.lg))
        article.paragraphs.forEach { paragraph ->
            Text(text = paragraph, style = RosaryType.serifBody, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.md))
        }
    }
}

@Composable
fun PrayerReaderScreen(prayer: Prayer, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)
            .padding(bottom = RosarySpace.xxl),
    ) {
        Text(text = prayer.title.english, style = RosaryType.headingPrimary, color = palette.ink)
        if (prayer.title.latin.isNotBlank()) {
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = prayer.title.latin, style = RosaryType.serifItalicBody, color = palette.dim)
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Text(text = prayer.text.english, style = RosaryType.serifBody, color = palette.ink)
        if (prayer.text.latin.isNotBlank()) {
            Spacer(Modifier.height(RosarySpace.lg))
            Text(text = prayer.text.latin, style = RosaryType.serifItalicBody, color = palette.dim)
        }
    }
}

@Composable
fun MysterySetScreen(set: MysterySetKind, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val heroId = drawableIdByName(context, ArtCatalog.heroName(set))
    val mysteries = MysteryCatalog.mysteries(set)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xxl),
    ) {
        if (heroId != 0) {
            Image(
                painter = painterResource(heroId),
                contentDescription = set.titleText.english,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
            )
        }
        Column(Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)) {
            Text(text = set.titleText.english, style = RosaryType.headingPrimary, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = set.weekdayCaption, style = RosaryType.supportingLabel, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(text = set.themeSummary, style = RosaryType.body, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xl))
            mysteries.forEach { mystery ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = RosarySpace.lg)
                        .clip(RoundedCornerShape(RosarySpace.nestedRadius)),
                ) {
                    Text(text = "${mystery.number}. ${mystery.title.english}", style = RosaryType.headingSecondary, color = palette.ink)
                    if (mystery.summary.isNotBlank()) {
                        Spacer(Modifier.height(RosarySpace.xs))
                        Text(text = mystery.summary, style = RosaryType.supportingLabel, color = palette.dim)
                    }
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(text = mystery.scriptureReference, style = RosaryType.caption, color = palette.accentText)
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(text = mystery.scriptureExcerpt.english, style = RosaryType.serifBody, color = palette.ink)
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(text = "Fruit: ${mystery.fruit.english}", style = RosaryType.supportingLabel, color = palette.dim)
                }
            }
        }
    }
}
