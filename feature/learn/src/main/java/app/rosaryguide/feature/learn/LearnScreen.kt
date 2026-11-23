package app.rosaryguide.feature.learn

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.LearnCopy
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.search.localizedStandardContains
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.feature.learn.R as LearnR
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuideLargeTopAppBar
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.SectionBand
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.Prayer

@Composable
fun LearnScreen(
    onHowToPray: () -> Unit,
    onArticle: (LearnArticle) -> Unit,
    onPrayer: (Prayer) -> Unit,
    onMysterySet: (MysterySetKind) -> Unit,
    onRosaryPrayers: () -> Unit = {},
    onAllPrayers: () -> Unit = {},
    onBeginRosary: () -> Unit = {},
    onResumeRosary: () -> Unit = onBeginRosary,
    todaySetTitle: String = "Joyful Mysteries",
    resumeCta: String? = null,
    startWalkthrough: Boolean = false,
    modifier: Modifier = Modifier,
    initialQuery: String = "",
    initialExpandedArticleId: String? = null,
    initialScrollToQuestions: Boolean = false,
) {
    val palette = LocalThemePalette.current
    var query by remember { mutableStateOf(initialQuery) }
    var showWalkthrough by remember { mutableStateOf(startWalkthrough) }
    val trimmed = query.trim()
    val articles = LearnArticle.commonQuestions.filter { article ->
        trimmed.isEmpty() ||
            article.title.localizedStandardContains(trimmed) ||
            article.paragraphs.any { it.localizedStandardContains(trimmed) }
    }
    val prayers = PrayerCatalog.all.filter { prayer ->
        PrayerCatalog.matchesQuery(prayer, trimmed)
    }
    val sets = MysterySetKind.displayOrder.filter { set ->
        trimmed.isEmpty() ||
            set.shortName.localizedStandardContains(trimmed) ||
            set.titleText.english.localizedStandardContains(trimmed) ||
            set.themeSummary.localizedStandardContains(trimmed)
    }
    val empty = trimmed.isNotEmpty() && prayers.isEmpty() && sets.isEmpty()
    val searching = trimmed.isNotEmpty()

    val scroll = rememberScrollState()
    var questionsY by remember { mutableStateOf(0) }
    LaunchedEffect(initialScrollToQuestions, questionsY) {
        if (initialScrollToQuestions && questionsY > 0) {
            scroll.scrollTo(questionsY)
        }
    }
    Box(modifier.fillMaxSize()) {
        AppPageBackground()
        Column(Modifier.fillMaxSize()) {
            if (initialScrollToQuestions) {
                CompactLearnTitle()
            } else {
                LearnLargeTitle()
            }
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(scroll)
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.tabBarContentClearance),
            ) {
                BoxSearch(value = query, onValueChange = { query = it }, placeholder = LearnCopy.SEARCH_PROMPT)
                Spacer(Modifier.height(RosarySpace.xl))
                if (empty) {
                    Text(text = LearnCopy.EMPTY, style = RosaryType.bodyPray, color = palette.dim)
                } else if (searching) {
                    if (sets.isNotEmpty()) {
                        GuideSectionLabel(text = LearnCopy.THE_MYSTERIES, strong = true, style = RosaryType.bodyPray)
                        sets.forEach { MysteryTile(it, onClick = { onMysterySet(it) }) }
                        Spacer(Modifier.height(RosarySpace.lg))
                    }
                    if (prayers.isNotEmpty()) {
                        prayers.forEachIndexed { index, prayer ->
                            LearnLinkRow(
                                title = prayer.title.english,
                                onClick = { onPrayer(prayer) },
                                showDivider = index < prayers.lastIndex,
                            )
                        }
                        Spacer(Modifier.height(RosarySpace.lg))
                    }
                } else {
                    IntroCard(onWalkthrough = { showWalkthrough = true })
                    SectionBand()
                    GuideSectionLabel(text = LearnCopy.THE_MYSTERIES, strong = true, style = RosaryType.bodyPray)
                    sets.forEach { MysteryTile(it, onClick = { onMysterySet(it) }) }
                    SectionBand()
                    GuideSectionLabel(text = "Prayers", strong = true, style = RosaryType.bodyPray)
                    PrayersTiles(onRosaryPrayers = onRosaryPrayers, onAllPrayers = onAllPrayers)
                    SectionBand()
                    Column(Modifier.onGloballyPositioned { questionsY = it.positionInParent().y.toInt() }) {
                    GuideSectionLabel(text = LearnCopy.COMMON_QUESTIONS, strong = true, style = RosaryType.bodyPray)
                    QuestionsAccordion(articles, initialExpandedArticleId)
                    }
                    SectionBand()
                    PrayTodayCard(title = todaySetTitle, resumeCta = resumeCta, onPray = if (resumeCta != null) onResumeRosary else onBeginRosary)
                    if (initialScrollToQuestions) {
                        Spacer(Modifier.height(640.dp))
                    }
                }
            }
        }
        if (showWalkthrough) {
            RosaryWalkthroughScreen(
                onClose = { showWalkthrough = false },
                onBegin = {
                    showWalkthrough = false
                    onBeginRosary()
                },
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

@Composable
private fun IntroCard(onWalkthrough: () -> Unit) {
    val palette = LocalThemePalette.current
    val ax = isAccessibilitySize()
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(RosarySpace.xl),
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                text = LearnCopy.INTRO_TITLE,
                style = RosaryType.headingPrimaryPray,
                color = palette.ink,
                modifier = Modifier.weight(1f),
            )
            if (!ax) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(palette.accentTint),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        painter = painterResource(LearnR.drawable.ic_book_closed),
                        contentDescription = null,
                        tint = palette.accentText,
                        modifier = Modifier.size(30.dp),
                    )
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Text(LearnCopy.INTRO_SUBTITLE, style = RosaryType.themeSummary, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.lg))
        GuidePrimaryButton(title = LearnCopy.BEGIN_WALKTHROUGH, onClick = onWalkthrough)
    }
}

@Composable
private fun MysteryTile(set: MysterySetKind, onClick: () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = RosarySpace.md)
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .border(1.dp, palette.cardSurfaceStroke, shape)
            .clickable(onClick = onClick)
            .padding(RosarySpace.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        MysterySetAvatar(set)
        Spacer(Modifier.width(RosarySpace.md))
        Column(Modifier.weight(1f)) {
            Text(
                text = "${set.shortName} Mysteries",
                style = RosaryType.bodyPray,
                color = palette.ink,
            )
            Text(text = set.weekdayCaption, style = RosaryType.captionPray, color = palette.dim)
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = palette.dim, modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun PrayersTiles(onRosaryPrayers: () -> Unit, onAllPrayers: () -> Unit) {
    val ax = isAccessibilitySize()
    val modifier = Modifier.fillMaxWidth()
    if (ax) {
        Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.md), modifier = modifier) {
            PrayerTile("Rosary prayers", "Used in the Rosary", onRosaryPrayers)
            PrayerTile("All prayers", "The full collection", onAllPrayers)
        }
    } else {
        Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.md), modifier = modifier) {
            Box(Modifier.weight(1f)) { PrayerTile("Rosary prayers", "Used in the Rosary", onRosaryPrayers) }
            Box(Modifier.weight(1f)) { PrayerTile("All prayers", "The full collection", onAllPrayers) }
        }
    }
}

@Composable
private fun PrayerTile(title: String, subtitle: String, onClick: () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .clickable(onClick = onClick)
            .padding(RosarySpace.lg),
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(palette.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                painter = painterResource(
                    if (title.startsWith("Rosary")) LearnR.drawable.ic_prayer_rosary
                    else LearnR.drawable.ic_prayer_all,
                ),
                contentDescription = null,
                tint = palette.accentText,
                modifier = Modifier.size(30.dp),
            )
        }
        Spacer(Modifier.height(RosarySpace.md))
        Text(title, style = RosaryType.bodyPray, color = palette.ink)
        Text(subtitle, style = RosaryType.captionPray, color = palette.dim)
    }
}

@Composable
private fun QuestionsAccordion(articles: List<LearnArticle>, initialExpandedArticleId: String? = null) {
    val palette = LocalThemePalette.current
    var expandedId by remember { mutableStateOf(initialExpandedArticleId) }
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(horizontal = RosarySpace.lg),
    ) {
        articles.forEachIndexed { index, article ->
            val open = expandedId == article.id
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { expandedId = if (open) null else article.id }
                        .padding(vertical = RosarySpace.lg),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        article.title,
                        style = RosaryType.bodyPray,
                        color = palette.ink,
                        modifier = Modifier.weight(1f),
                    )
                    Icon(
                        imageVector = Icons.Filled.KeyboardArrowDown,
                        contentDescription = if (open) "Collapse" else "Expand",
                        tint = palette.dim,
                        modifier = Modifier.size(16.dp).rotate(if (open) 180f else 0f),
                    )
                }
                if (open) {
                    article.paragraphs.forEach { paragraph ->
                        Text(paragraph, style = RosaryType.themeSummary, color = palette.dim)
                        Spacer(Modifier.height(RosarySpace.md))
                    }
                    Spacer(Modifier.height(RosarySpace.sm))
                }
            }
            if (index < articles.lastIndex) HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
        }
    }
}

@Composable
private fun PrayTodayCard(title: String, resumeCta: String?, onPray: () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    val heading = if (resumeCta != null) "Resume your Rosary" else LearnCopy.PRAY_TODAY_HEADING
    val subtitle = if (resumeCta != null) "Pick up where you left off" else LearnCopy.PRAY_TODAY_SUBTITLE
    val cta = resumeCta ?: LearnCopy.PRAY_TODAY_TITLE_FRESH
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(RosarySpace.xl),
    ) {
        Text(heading, style = RosaryType.headingPrimaryPray, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.sm))
        Text(subtitle, style = RosaryType.bodyPray, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.lg))
        GuideSecondaryButton(title = cta, onClick = onPray)
    }
}

@Composable
private fun LearnLinkRow(title: String, caption: String? = null, onClick: () -> Unit, showDivider: Boolean = false) {
    val palette = LocalThemePalette.current
    Column(Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .padding(vertical = RosarySpace.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                if (caption != null) {
                    Text(caption, style = RosaryType.captionPray, color = palette.accentText)
                }
                Text(title, style = RosaryType.bodyPray, color = palette.ink)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = palette.dim)
        }
        if (showDivider) HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
    }
}

private val rosaryPrayerIds = setOf(
    "sign-of-the-cross", "apostles-creed", "our-father", "hail-mary",
    "glory-be", "hail-holy-queen", "concluding",
)



@Composable
private fun LearnLargeTitle() {
    val palette = LocalThemePalette.current
    // iOS large-title cap is 127.7 dp (0.1335). Status 52.57 + 56 dp targets that after Trim.Both.
    val title = RosaryType.h1Navigation.copy(
        platformStyle = PlatformTextStyle(includeFontPadding = false),
        lineHeightStyle = LineHeightStyle(
            alignment = LineHeightStyle.Alignment.Center,
            trim = LineHeightStyle.Trim.Both,
        ),
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = 56.dp, bottom = 8.dp),
    ) {
        Text("Learn", style = title, color = palette.ink)
    }
}

@Composable
private fun CompactLearnTitle() {
    val palette = LocalThemePalette.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text("Learn", style = RosaryType.navigationTitle, color = palette.ink)
    }
}

@Composable
private fun MysterySetAvatar(set: MysterySetKind, size: androidx.compose.ui.unit.Dp = 56.dp) {
    val palette = LocalThemePalette.current
    val icon = when (set) {
        MysterySetKind.Joyful -> LearnR.drawable.ic_mystery_joyful
        MysterySetKind.Luminous -> LearnR.drawable.ic_mystery_luminous
        MysterySetKind.Sorrowful -> LearnR.drawable.ic_mystery_sorrowful
        MysterySetKind.Glorious -> LearnR.drawable.ic_mystery_glorious
    }
    Box(
        modifier = Modifier.size(size),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .matchParentSize()
                .clip(CircleShape)
                .background(palette.accent),
        )
        val glyph = if (set == MysterySetKind.Sorrowful) size * 0.96f else size * 0.78f
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            tint = palette.onAccent,
            modifier = Modifier.size(glyph),
        )
    }
}

private fun mysteryThumb(set: MysterySetKind): Int = when (set) {
    MysterySetKind.Joyful -> R.drawable.mystery_01_annunciation
    MysterySetKind.Sorrowful -> R.drawable.mystery_01_agony_in_the_garden
    MysterySetKind.Glorious -> R.drawable.mystery_01_resurrection
    MysterySetKind.Luminous -> R.drawable.mystery_01_baptism_of_jesus_in_the_jordan
}

@Composable
private fun BoxSearch(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(percent = 50)
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = RosaryType.bodyPray.copy(color = palette.ink),
        cursorBrush = SolidColor(palette.accent),
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .border(Hairline.thickness, palette.cardSurfaceStroke, shape)
            .padding(horizontal = RosarySpace.md, vertical = RosarySpace.md),
        decorationBox = { inner ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Search,
                    contentDescription = null,
                    tint = palette.dim,
                    modifier = Modifier.size(20.dp).padding(end = RosarySpace.sm),
                )
                Box(Modifier.weight(1f)) {
                    if (value.isEmpty()) {
                        Text(text = placeholder, style = RosaryType.bodyPray, color = palette.dim)
                    }
                    inner()
                }
                if (value.isNotEmpty()) {
                    Box(
                        modifier = Modifier
                            .size(20.dp)
                            .clip(CircleShape)
                            .background(palette.dim)
                            .clickable { onValueChange("") },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = "Clear search",
                            tint = Color.White,
                            modifier = Modifier.size(12.dp),
                        )
                    }
                }
            }
        },
    )
}
