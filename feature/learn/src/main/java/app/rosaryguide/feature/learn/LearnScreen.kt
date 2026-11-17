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
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.LearnCopy
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.search.localizedStandardContains
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideLargeTopAppBar
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
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
    val howToVisible = trimmed.isEmpty() ||
        LearnCopy.HOW_TO_PRAY_TITLE.localizedStandardContains(trimmed) ||
        "how to pray".localizedStandardContains(trimmed)
    val empty = trimmed.isNotEmpty() && !howToVisible && articles.isEmpty() && prayers.isEmpty() && sets.isEmpty()
    val searching = trimmed.isNotEmpty()

    Box(modifier.fillMaxSize().background(palette.bg)) {
        Column(Modifier.fillMaxSize()) {
            GuideLargeTopAppBar(title = "Learn")
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.xxl),
            ) {
                BoxSearch(value = query, onValueChange = { query = it }, placeholder = LearnCopy.SEARCH_PROMPT)
                Spacer(Modifier.height(RosarySpace.xl))
                if (empty) {
                    Text(text = LearnCopy.EMPTY, style = RosaryType.body, color = palette.dim)
                } else if (searching) {
                    if (howToVisible) {
                        GuideSectionLabel(text = "Guide")
                        LearnLinkRow(title = LearnCopy.HOW_TO_PRAY_TITLE, onClick = onHowToPray)
                        Spacer(Modifier.height(RosarySpace.lg))
                    }
                    if (sets.isNotEmpty()) {
                        GuideSectionLabel(text = LearnCopy.THE_MYSTERIES)
                        sets.forEach { MysteryTile(it, onClick = { onMysterySet(it) }) }
                        Spacer(Modifier.height(RosarySpace.lg))
                    }
                    if (prayers.isNotEmpty()) {
                        GuideSectionLabel(text = "Prayers")
                        prayers.forEach { prayer ->
                            LearnLinkRow(title = prayer.title.english, onClick = { onPrayer(prayer) })
                        }
                        Spacer(Modifier.height(RosarySpace.lg))
                    }
                    if (articles.isNotEmpty()) {
                        GuideSectionLabel(text = LearnCopy.COMMON_QUESTIONS)
                        articles.forEach { article ->
                            LearnLinkRow(title = article.title, caption = article.eyebrow, onClick = { onArticle(article) })
                        }
                    }
                } else {
                    IntroCard(onWalkthrough = { showWalkthrough = true })
                    Spacer(Modifier.height(RosarySpace.xl))
                    GuideSectionLabel(text = LearnCopy.THE_MYSTERIES)
                    sets.forEach { MysteryTile(it, onClick = { onMysterySet(it) }) }
                    Spacer(Modifier.height(RosarySpace.xl))
                    GuideSectionLabel(text = "Prayers")
                    PrayersTiles(onRosaryPrayers = onRosaryPrayers, onAllPrayers = onAllPrayers)
                    Spacer(Modifier.height(RosarySpace.xl))
                    GuideSectionLabel(text = LearnCopy.COMMON_QUESTIONS)
                    QuestionsAccordion(articles, initialExpandedArticleId)
                    Spacer(Modifier.height(RosarySpace.xl))
                    PrayTodayCard(title = todaySetTitle, resumeCta = resumeCta, onPray = if (resumeCta != null) onResumeRosary else onBeginRosary)
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
            .background(palette.surface)
            .padding(RosarySpace.xl),
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                text = LearnCopy.INTRO_TITLE,
                style = RosaryType.headingPrimary,
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
                        imageVector = Icons.Outlined.Info,
                        contentDescription = null,
                        tint = palette.accentText,
                        modifier = Modifier.size(30.dp),
                    )
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Text(LearnCopy.INTRO_SUBTITLE, style = RosaryType.supportingLabel, color = palette.dim)
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
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape)
            .clickable(onClick = onClick)
            .padding(RosarySpace.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(mysteryThumb(set)),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(56.dp).clip(RoundedCornerShape(RosarySpace.nestedRadius)),
        )
        Spacer(Modifier.width(RosarySpace.md))
        Column(Modifier.weight(1f)) {
            Text(
                text = "${set.shortName} Mysteries",
                style = RosaryType.body.copy(fontWeight = FontWeight.Medium),
                color = palette.ink,
            )
            Text(text = set.weekdayCaption, style = RosaryType.caption, color = palette.dim)
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
            .background(palette.surface)
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
                imageVector = if (title.startsWith("Rosary")) Icons.Filled.Star else Icons.Outlined.Info,
                contentDescription = null,
                tint = palette.accentText,
                modifier = Modifier.size(30.dp),
            )
        }
        Spacer(Modifier.height(RosarySpace.md))
        Text(title, style = RosaryType.body.copy(fontWeight = FontWeight.Medium), color = palette.ink)
        Text(subtitle, style = RosaryType.caption, color = palette.dim)
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
            .background(palette.surface)
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
                        style = RosaryType.body.copy(fontWeight = FontWeight.Medium),
                        color = palette.ink,
                        modifier = Modifier.weight(1f),
                    )
                    Icon(
                        imageVector = Icons.Filled.KeyboardArrowDown,
                        contentDescription = if (open) "Collapse" else "Expand",
                        tint = palette.dim,
                        modifier = Modifier.size(16.dp),
                    )
                }
                if (open) {
                    article.paragraphs.forEach { paragraph ->
                        Text(paragraph, style = RosaryType.supportingLabel, color = palette.dim)
                        Spacer(Modifier.height(RosarySpace.md))
                    }
                    Spacer(Modifier.height(RosarySpace.sm))
                }
            }
            if (index < articles.lastIndex) HorizontalDivider(color = palette.strokeRegular)
        }
    }
}

@Composable
private fun PrayTodayCard(title: String, resumeCta: String?, onPray: () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    val heading = if (resumeCta != null) "Resume your Rosary" else title
    val subtitle = if (resumeCta != null) "Pick up where you left off" else LearnCopy.PRAY_TODAY_SUBTITLE
    val cta = resumeCta ?: LearnCopy.PRAY_TODAY_TITLE_FRESH
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .padding(RosarySpace.xl),
    ) {
        Text(heading, style = RosaryType.headingSecondary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.sm))
        Text(subtitle, style = RosaryType.supportingLabel, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.lg))
        GuideSecondaryButton(title = cta, onClick = onPray)
    }
}

@Composable
private fun LearnLinkRow(title: String, caption: String? = null, onClick: () -> Unit) {
    val palette = LocalThemePalette.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = RosarySpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            if (caption != null) {
                Text(caption, style = RosaryType.caption, color = palette.accentText)
            }
            Text(title, style = RosaryType.body, color = palette.ink)
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = palette.dim)
    }
}

private val rosaryPrayerIds = setOf(
    "sign-of-the-cross", "apostles-creed", "our-father", "hail-mary",
    "glory-be", "hail-holy-queen", "concluding",
)

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
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = RosaryType.body.copy(color = palette.ink),
        cursorBrush = SolidColor(palette.accent),
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
        decorationBox = { inner ->
            if (value.isEmpty()) {
                Text(text = placeholder, style = RosaryType.body, color = palette.dim)
            }
            inner()
        },
    )
}
