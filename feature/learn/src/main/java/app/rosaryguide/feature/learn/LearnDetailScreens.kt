package app.rosaryguide.feature.learn

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.ui.text.font.FontWeight
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import app.rosaryguide.core.model.PrayerLanguage
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.foundation.layout.Arrangement
import app.rosaryguide.core.data.catalog.PrayerCatalog
import androidx.compose.ui.graphics.Color
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
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.designsystem.component.drawableIdByName
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.focusedCover
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.Prayer
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Search

@Composable
fun LearnArticleScreen(article: LearnArticle, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)
            .padding(bottom = 96.dp),
    ) {
        Text(text = article.eyebrow, style = RosaryType.captionPray, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.xs))
        Text(text = article.title, style = RosaryType.headingPrimaryPray, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.lg))
        article.paragraphs.forEach { paragraph ->
            Text(text = paragraph, style = RosaryType.bodyPray, color = palette.dim)
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
            
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)
            .padding(bottom = 96.dp),
    ) {
        Text(text = prayer.title.english, style = RosaryType.headingPrimaryPray, color = palette.ink)
        if (prayer.title.latin.isNotBlank() && prayer.title.latin != prayer.title.english) {
            Spacer(Modifier.height(RosarySpace.sm))
            Text(text = prayer.title.latin, style = RosaryType.themeSummary, color = palette.dim)
        }
        if (prayer.text.hasDistinctLatin) {
            Spacer(Modifier.height(RosarySpace.xl))
            LearnLanguageCapsule(language = language, onChange = { language = it })
        }
        // iOS PrayerReaderBlock: stack Space.xl plus reader padding.vertical lg.
        Spacer(Modifier.height(RosarySpace.xl))
        if (shown == PrayerLanguage.Bilingual && prayer.text.hasDistinctLatin) {
            if (ax) {
                Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.xxl)) {
                    LearnPrayerParagraphs(prayer.text.english, palette.ink)
                    LearnPrayerParagraphs(prayer.text.latin, palette.dim)
                }
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(RosarySpace.xl),
                ) {
                    Box(Modifier.weight(1f)) { LearnPrayerParagraphs(prayer.text.english, palette.ink) }
                    Box(Modifier.weight(1f)) { LearnPrayerParagraphs(prayer.text.latin, palette.dim) }
                }
            }
        } else {
            val body = if (shown == PrayerLanguage.Latin) prayer.text.latinOrEnglish else prayer.text.english
            LearnPrayerParagraphs(body, palette.ink)
        }
    }
}

@Composable
fun MysterySetScreen(
    set: MysterySetKind,
    modifier: Modifier = Modifier,
    onPray: (MysterySetKind) -> Unit = {},
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val heroId = drawableIdByName(context, ArtCatalog.heroName(set))
    val mysteries = MysteryCatalog.mysteries(set)
    var expanded by remember { mutableStateOf(setOf<String>()) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.xl, bottom = 96.dp),
    ) {
        if (heroId != 0) {
            val painter = painterResource(heroId)
            val (fx, fy) = ArtCatalog.heroWideFocus(set)
            val src = painter.intrinsicSize
            CroppedArt(
                painter = painter,
                coverForFrame = { fw, fh ->
                    focusedCover(src.width, src.height, fw, fh, fx, fy)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
                    .clip(RoundedCornerShape(RosarySpace.containerRadius)),
                contentDescription = set.displayTitle,
            )
            Spacer(Modifier.height(RosarySpace.xl))
        }
        Text(text = set.displayTitle, style = RosaryType.headingPrimaryPray, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.md))
        Text(text = set.learnDescription, style = RosaryType.bodyReading, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.xl))
        val shape = RoundedCornerShape(RosarySpace.containerRadius)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(shape)
                .background(palette.cardSurface(PageStyle.Grouped))
                .border(1.dp, palette.strokeRegular, shape)
                .padding(horizontal = RosarySpace.lg),
        ) {
            mysteries.forEachIndexed { index, mystery ->
                val isOpen = mystery.id in expanded
                Column(Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                expanded = if (isOpen) expanded - mystery.id else expanded + mystery.id
                            }
                            .padding(vertical = RosarySpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(palette.surface),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "${index + 1}",
                                style = RosaryType.captionPray,
                                color = palette.dim,
                            )
                        }
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(start = RosarySpace.md, end = RosarySpace.sm),
                        ) {
                            Text(
                                text = mystery.title.english,
                                style = RosaryType.bodyPray,
                                color = palette.ink,
                                maxLines = 1,
                            )
                            val fruit = mystery.fruit.english
                            if (fruit.isNotBlank() && !isOpen) {
                                Spacer(Modifier.height(2.dp))
                                Text(text = fruit, style = RosaryType.captionPray, color = palette.dim)
                            }
                        }
                        Icon(
                            imageVector = Icons.Filled.KeyboardArrowDown,
                            contentDescription = if (isOpen) "Collapse" else "Expand",
                            tint = palette.dim,
                            modifier = Modifier.size(14.dp),
                        )
                    }
                    if (isOpen) {
                        Column(Modifier.padding(start = 40.dp, bottom = RosarySpace.lg)) {
                            if (mystery.summary.isNotBlank()) {
                                Text(mystery.summary, style = RosaryType.themeSummary, color = palette.dim)
                                Spacer(Modifier.height(RosarySpace.xs))
                            }
                            Text(mystery.scriptureReference, style = RosaryType.captionPray, color = palette.dim)
                            Spacer(Modifier.height(RosarySpace.xs))
                            Text(mystery.scriptureExcerpt.english, style = RosaryType.bodyPray, color = palette.dim)
                            Spacer(Modifier.height(RosarySpace.xs))
                            Text("Fruit: ${mystery.fruit.english}", style = RosaryType.themeSummary, color = palette.dim)
                        }
                    }
                }
                if (index < mysteries.lastIndex) {
                    androidx.compose.material3.HorizontalDivider(color = palette.strokeRegular)
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.xl))
        GuidePrimaryButton(title = "Pray these mysteries", onClick = { onPray(set) })
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
            
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.lg, bottom = 96.dp),
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
    app.rosaryguide.core.designsystem.component.GuideSectionLabel(text = title, strong = true, style = RosaryType.bodyPray)
    Text(detail, style = RosaryType.captionPray, color = palette.dim)
    Spacer(Modifier.height(RosarySpace.sm))
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped)),
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
                Text(prayer.title.english, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
                if (row.count != null) {
                    Text("×${row.count}", style = RosaryType.bodyPray, color = palette.dim)
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
    initialQuery: String = "",
) {
    val palette = LocalThemePalette.current
    var query by remember { mutableStateOf(initialQuery) }
    val term = query.trim()
    val results = remember(term) {
        PrayerCatalog.all
            .filter { PrayerCatalog.matchesQuery(it, term) }
            .sortedBy { it.title.english.lowercase() }
    }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.lg, bottom = 96.dp),
    ) {
        val fieldPalette = palette
        val searchShape = RoundedCornerShape(percent = 50)
        androidx.compose.foundation.text.BasicTextField(
            value = query,
            onValueChange = { query = it },
            singleLine = true,
            textStyle = RosaryType.bodyPray.copy(color = fieldPalette.ink),
            cursorBrush = androidx.compose.ui.graphics.SolidColor(fieldPalette.accent),
            modifier = Modifier
                .fillMaxWidth()
                .clip(searchShape)
                .background(fieldPalette.cardSurface(PageStyle.Grouped))
                .border(1.dp, fieldPalette.cardSurfaceStroke, searchShape)
                .padding(horizontal = RosarySpace.md, vertical = RosarySpace.md),
            decorationBox = { inner ->
                androidx.compose.foundation.layout.Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    androidx.compose.material3.Icon(
                        imageVector = androidx.compose.material.icons.Icons.Filled.Search,
                        contentDescription = null,
                        tint = fieldPalette.dim,
                        modifier = Modifier.size(20.dp).padding(end = RosarySpace.sm),
                    )
                    Box(Modifier.weight(1f)) {
                        if (query.isEmpty()) {
                            Text("Search prayers", style = RosaryType.bodyPray, color = fieldPalette.dim)
                        }
                        inner()
                    }
                    if (query.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .size(20.dp)
                                .clip(RoundedCornerShape(percent = 50))
                                .background(fieldPalette.dim)
                                .clickable { query = "" },
                            contentAlignment = androidx.compose.ui.Alignment.Center,
                        ) {
                            androidx.compose.material3.Icon(
                                imageVector = Icons.Filled.Close,
                                contentDescription = "Clear search",
                                tint = androidx.compose.ui.graphics.Color.White,
                                modifier = Modifier.size(12.dp),
                            )
                        }
                    }
                }
            },
        )
        Spacer(Modifier.height(RosarySpace.lg))
        if (results.isEmpty()) {
            Text("No prayers found. Try another search.", style = RosaryType.bodyPray, color = palette.dim)
        } else {
            results.forEachIndexed { index, prayer ->
                androidx.compose.foundation.layout.Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onPrayer(prayer) }
                        .heightIn(min = 72.dp)
                        .padding(vertical = RosarySpace.xl),
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                ) {
                    Text(prayer.title.english, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
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


/** iOS `PrayerReaderBlock` paragraphs: 18 pt sans + lineSpacing 8, xl gap. */
@Composable
private fun LearnPrayerParagraphs(text: String, color: androidx.compose.ui.graphics.Color) {
    val paragraphs = text.split("\n\n".toRegex()).filter { it.isNotBlank() }
    Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.xl)) {
        paragraphs.forEach { paragraph ->
            Text(
                text = paragraph.replace("\n".toRegex(), " ").trim(),
                style = RosaryType.prayerTextMichael,
                color = color,
            )
        }
    }
}

/** 44 dp capsule matching iOS `GuideChoiceControl` / `segmentedControlHeight`. */
@Composable
private fun LearnLanguageCapsule(
    language: PrayerLanguage,
    onChange: (PrayerLanguage) -> Unit,
) {
    val palette = LocalThemePalette.current
    val options = listOf(PrayerLanguage.English, PrayerLanguage.Latin, PrayerLanguage.Bilingual)
    val track = if (palette.isDark) Color(0xFF2C2C2E) else palette.cardSurface(PageStyle.Grouped)
    val thumb = if (palette.isDark) Color(0xFF1C1C1E) else Color.White
    val cap = RoundedCornerShape(percent = 50)
    val selectedIndex = options.indexOf(language).coerceAtLeast(0)
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp)
            .background(track, cap),
    ) {
        val inset = 2.dp
        val thumbWidth = (maxWidth - inset * 2) / options.size
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .padding(start = inset + thumbWidth * selectedIndex, top = inset, bottom = inset)
                .width(thumbWidth)
                .height(40.dp)
                .shadow(1.5.dp, cap, clip = false)
                .background(thumb, cap),
        )
        Row(Modifier.fillMaxWidth().fillMaxHeight(), verticalAlignment = Alignment.CenterVertically) {
            options.forEach { option ->
                val selected = language == option
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable { onChange(option) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = option.title,
                        style = RosaryType.segmentedControlPray,
                        color = if (selected) palette.ink else palette.dim,
                    )
                }
            }
        }
    }
}
