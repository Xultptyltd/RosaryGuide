package app.rosaryguide.feature.learn

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.ui.text.font.FontWeight
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import app.rosaryguide.core.model.PrayerLanguage
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.foundation.layout.Arrangement
import app.rosaryguide.core.data.catalog.PrayerCatalog
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.Alignment
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.material3.Icon
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.Icons
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.clickable
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
    var language by remember { mutableStateOf(PrayerLanguage.English) }
    val shown = if (prayer.text.hasDistinctLatin) language else PrayerLanguage.English
    val ax = isAccessibilitySize()
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)
            .padding(bottom = RosarySpace.xxl),
    ) {
        Text(text = prayer.title.english, style = RosaryType.headingPrimary, color = palette.ink)
        if (prayer.title.latin.isNotBlank() && prayer.title.latin != prayer.title.english) {
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = prayer.title.latin, style = RosaryType.serifItalicBody, color = palette.dim)
        }
        if (prayer.text.hasDistinctLatin) {
            Spacer(Modifier.height(RosarySpace.lg))
            Text("Prayer language", style = RosaryType.caption, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.sm))
            val options = listOf(PrayerLanguage.English, PrayerLanguage.Latin, PrayerLanguage.Bilingual)
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                options.forEachIndexed { index, option ->
                    SegmentedButton(
                        selected = language == option,
                        onClick = { language = option },
                        shape = SegmentedButtonDefaults.itemShape(index, options.size),
                        colors = SegmentedButtonDefaults.colors(
                            activeContainerColor = palette.accent,
                            activeContentColor = palette.onAccent,
                            inactiveContainerColor = palette.surface,
                            inactiveContentColor = palette.ink,
                        ),
                        label = { Text(option.title, style = RosaryType.caption, maxLines = 1) },
                    )
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        if (shown == PrayerLanguage.Bilingual && prayer.text.hasDistinctLatin) {
            if (ax) {
                Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.xxl)) {
                    Text(prayer.text.english, style = RosaryType.serifBody, color = palette.ink)
                    Text(prayer.text.latin, style = RosaryType.serifItalicBody, color = palette.ink)
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(RosarySpace.xl),
                ) {
                    Text(prayer.text.english, style = RosaryType.serifBody, color = palette.ink, modifier = Modifier.weight(1f))
                    Text(prayer.text.latin, style = RosaryType.serifItalicBody, color = palette.ink, modifier = Modifier.weight(1f))
                }
            }
        } else {
            val body = if (shown == PrayerLanguage.Latin) prayer.text.latinOrEnglish else prayer.text.english
            val style = if (shown == PrayerLanguage.Latin) RosaryType.serifItalicBody else RosaryType.serifBody
            Text(body, style = style, color = palette.ink)
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

@Composable
fun RosaryPrayersScreen(
    onPrayer: (Prayer) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.lg, bottom = RosarySpace.xxl),
    ) {
        RosaryPrayerGroup(
            title = "Opening prayers",
            detail = "Begin on the crucifix and introductory beads.",
            rows = listOf(
                PrayerRowRef("sign-of-the-cross"),
                PrayerRowRef("apostles-creed"),
                PrayerRowRef("our-father"),
                PrayerRowRef("hail-mary", 3),
                PrayerRowRef("glory-be"),
            ),
            onPrayer = onPrayer,
        )
        Spacer(Modifier.height(RosarySpace.xxl))
        RosaryPrayerGroup(
            title = "Each decade",
            detail = "Repeat for each of the five mysteries.",
            rows = listOf(
                PrayerRowRef("our-father"),
                PrayerRowRef("hail-mary", 10),
                PrayerRowRef("glory-be"),
                PrayerRowRef("fatima"),
            ),
            onPrayer = onPrayer,
        )
        Spacer(Modifier.height(RosarySpace.xxl))
        RosaryPrayerGroup(
            title = "Closing prayers",
            detail = "After the fifth decade.",
            rows = listOf(
                PrayerRowRef("hail-holy-queen"),
                PrayerRowRef("versicle"),
                PrayerRowRef("concluding"),
                PrayerRowRef("sign-of-the-cross"),
            ),
            onPrayer = onPrayer,
        )
    }
}

private data class PrayerRowRef(val id: String, val count: Int? = null)

@Composable
private fun RosaryPrayerGroup(
    title: String,
    detail: String,
    rows: List<PrayerRowRef>,
    onPrayer: (Prayer) -> Unit,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    app.rosaryguide.core.designsystem.component.GuideSectionLabel(text = title)
    Text(detail, style = RosaryType.caption, color = palette.dim)
    Spacer(Modifier.height(RosarySpace.sm))
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface),
    ) {
        rows.forEachIndexed { index, row ->
            val prayer = app.rosaryguide.core.data.catalog.PrayerCatalog.prayer(row.id) ?: return@forEachIndexed
            androidx.compose.foundation.layout.Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onPrayer(prayer) }
                    .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
            ) {
                Text(prayer.title.english, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
                if (row.count != null) {
                    Text("×${row.count}", style = RosaryType.body, color = palette.dim)
                    Spacer(Modifier.width(RosarySpace.sm))
                }
                androidx.compose.material3.Icon(
                    imageVector = androidx.compose.material.icons.Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.textSecondary,
                )
            }
            if (index < rows.lastIndex) {
                androidx.compose.material3.HorizontalDivider(
                    color = palette.strokeRegular,
                    modifier = Modifier.padding(start = RosarySpace.lg),
                )
            }
        }
    }
}

@Composable
fun AllPrayersScreen(
    onPrayer: (Prayer) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var query by remember { mutableStateOf("") }
    val term = query.trim()
    val results = remember(term) {
        PrayerCatalog.all
            .filter { term.isEmpty() || it.title.english.contains(term, ignoreCase = true) || it.title.latin.contains(term, ignoreCase = true) }
            .sortedBy { it.title.english.lowercase() }
    }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.lg, bottom = RosarySpace.xxl),
    ) {
        val fieldPalette = palette
        androidx.compose.foundation.text.BasicTextField(
            value = query,
            onValueChange = { query = it },
            singleLine = true,
            textStyle = RosaryType.body.copy(color = fieldPalette.ink),
            cursorBrush = androidx.compose.ui.graphics.SolidColor(fieldPalette.accent),
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(RosarySpace.containerRadius))
                .background(fieldPalette.surface)
                .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
            decorationBox = { inner ->
                if (query.isEmpty()) {
                    Text("Search prayers", style = RosaryType.body, color = fieldPalette.dim)
                }
                inner()
            },
        )
        Spacer(Modifier.height(RosarySpace.lg))
        if (results.isEmpty()) {
            Text("No prayers found. Try another search.", style = RosaryType.body, color = palette.dim)
        } else {
            results.forEachIndexed { index, prayer ->
                androidx.compose.foundation.layout.Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onPrayer(prayer) }
                        .padding(vertical = RosarySpace.xl)
                        .heightIn(min = 40.dp),
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                ) {
                    Text(prayer.title.english, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
                    androidx.compose.material3.Icon(
                        imageVector = androidx.compose.material.icons.Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = palette.dim,
                    )
                }
                if (index < results.lastIndex) androidx.compose.material3.HorizontalDivider(color = palette.strokeRegular)
            }
        }
    }
}
