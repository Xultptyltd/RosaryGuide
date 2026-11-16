package app.rosaryguide.feature.learn

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.LearnCopy
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.search.localizedStandardContains
import app.rosaryguide.core.designsystem.component.GuideRow
import app.rosaryguide.core.designsystem.component.GuideScreenHeader
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.Prayer

@Composable
fun LearnScreen(
    onHowToPray: () -> Unit,
    onArticle: (LearnArticle) -> Unit,
    onPrayer: (Prayer) -> Unit,
    onMysterySet: (MysterySetKind) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var query by remember { mutableStateOf("") }
    val trimmed = query.trim()
    val articles = LearnArticle.commonQuestions.filter { article ->
        trimmed.isEmpty() ||
            article.title.localizedStandardContains(trimmed) ||
            article.paragraphs.any { it.localizedStandardContains(trimmed) }
    }
    val prayers = PrayerCatalog.all.filter { prayer ->
        trimmed.isEmpty() ||
            prayer.title.english.localizedStandardContains(trimmed) ||
            prayer.title.latin.localizedStandardContains(trimmed)
    }
    val sets = MysterySetKind.entries.filter { set ->
        trimmed.isEmpty() ||
            set.shortName.localizedStandardContains(trimmed) ||
            set.titleText.english.localizedStandardContains(trimmed) ||
            set.themeSummary.localizedStandardContains(trimmed)
    }
    val howToVisible = trimmed.isEmpty() ||
        LearnCopy.HOW_TO_PRAY_TITLE.localizedStandardContains(trimmed) ||
        "how to pray".localizedStandardContains(trimmed)
    val empty = trimmed.isNotEmpty() && !howToVisible && articles.isEmpty() && prayers.isEmpty() && sets.isEmpty()

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(bottom = RosarySpace.xxl),
    ) {
        GuideScreenHeader(title = "Learn", modifier = Modifier.padding(vertical = RosarySpace.lg))
        BoxSearch(
            value = query,
            onValueChange = { query = it },
            placeholder = LearnCopy.SEARCH_TITLE,
        )
        Spacer(Modifier.height(RosarySpace.lg))
        if (empty) {
            Text(text = LearnCopy.EMPTY, style = RosaryType.body, color = palette.dim)
        } else {
            if (howToVisible) {
                GuideRow(title = LearnCopy.HOW_TO_PRAY_TITLE, onClick = onHowToPray)
                Spacer(Modifier.height(RosarySpace.lg))
            }
            if (articles.isNotEmpty()) {
                articles.forEach { article ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(RosarySpace.nestedRadius))
                            .clickable { onArticle(article) }
                            .padding(vertical = RosarySpace.sm),
                    ) {
                        Text(text = article.eyebrow, style = RosaryType.caption, color = palette.accentText)
                        Spacer(Modifier.height(2.dp))
                        Text(text = article.title, style = RosaryType.body, color = palette.ink)
                    }
                }
                Spacer(Modifier.height(RosarySpace.lg))
            }
            if (prayers.isNotEmpty()) {
                GuideSectionLabel(text = "Prayers")
                prayers.forEach { prayer ->
                    GuideRow(title = prayer.title.english, onClick = { onPrayer(prayer) })
                    Spacer(Modifier.height(RosarySpace.xs))
                }
                Spacer(Modifier.height(RosarySpace.md))
            }
            if (sets.isNotEmpty()) {
                GuideSectionLabel(text = "Mysteries")
                sets.forEach { set ->
                    GuideRow(
                        title = set.titleText.english,
                        subtitle = set.weekdayCaption,
                        onClick = { onMysterySet(set) },
                    )
                    Spacer(Modifier.height(RosarySpace.xs))
                }
            }
        }
    }
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
