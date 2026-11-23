package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rosaryguide.core.data.catalog.FeastNarratives
import app.rosaryguide.core.data.catalog.FeastScriptures
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.Feast
import app.rosaryguide.core.model.FeastRank

@Composable
fun FeastRelatedPrayersScreen(
    item: DatedFeast,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val narrative = FeastNarratives.narrative(item.feast.id)
    val prayers = prayersForDay(item, narrative?.relatedPrayers.orEmpty())
    var expandedPrayerId by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(prayers) {
        if (expandedPrayerId == null) expandedPrayerId = prayers.firstOrNull()?.id
    }
    FeastSecondaryPage(
        title = "Related prayers",
        feast = item.feast,
        onBack = onBack,
        modifier = modifier,
    ) {
        prayers.forEachIndexed { index, prayer ->
            FeastPrayerCard(
                prayer = prayer,
                expanded = expandedPrayerId == prayer.id,
                onToggle = {
                    expandedPrayerId = if (expandedPrayerId == prayer.id) null else prayer.id
                },
                flush = true,
            )
            if (index < prayers.lastIndex) {
                HorizontalDivider(thickness = Hairline.thickness, color = LocalThemePalette.current.hair)
            }
        }
    }
}

@Composable
fun FeastPatronagesScreen(
    item: DatedFeast,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val patronages = patronagesFor(item.feast)
    FeastSecondaryPage(
        title = "Patronages",
        feast = item.feast,
        onBack = onBack,
        modifier = modifier,
    ) {
        Text(
            text = "Traditions associated with this feast.",
            style = RosaryType.serifBody.copy(lineHeight = 33.sp),
            color = palette.dim,
        )
        Spacer(Modifier.height(RosarySpace.xl))
        patronages.forEachIndexed { index, patronage ->
            GuideSectionLabel(text = "Patronage", style = RosaryType.captionPray)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(
                text = patronage,
                style = RosaryType.serifTitle.copy(lineHeight = 34.sp),
                color = palette.ink,
            )
            Spacer(Modifier.height(20.dp))
            if (index < patronages.lastIndex) {
                HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                Spacer(Modifier.height(RosarySpace.xl))
            }
        }
    }
}

@Composable
fun FeastScriptureScreen(
    item: DatedFeast,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val passages = FeastScriptures.passages(item.feast.id)
    FeastSecondaryPage(
        title = "In Scripture",
        feast = item.feast,
        onBack = onBack,
        modifier = modifier,
    ) {
        if (passages.isEmpty()) {
            GuideSectionLabel(text = "Scripture", style = RosaryType.captionPray)
            Spacer(Modifier.height(RosarySpace.md))
            Text(
                text = "${item.feast.shortTitle} is held within the Church's living memory of Scripture, prayer, and worship.",
                style = RosaryType.serifBody.copy(lineHeight = 42.sp),
                color = palette.ink,
            )
        } else {
            passages.forEachIndexed { index, passage ->
                GuideSectionLabel(text = passage.citation, style = RosaryType.captionPray)
                Spacer(Modifier.height(RosarySpace.md))
                Text(passage.heading, style = RosaryType.serifTitle, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.md))
                Text(
                    text = passage.text,
                    style = RosaryType.serifBody.copy(lineHeight = 34.sp),
                    color = palette.dim,
                )
                Spacer(Modifier.height(22.dp))
                if (index < passages.lastIndex) {
                    HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                    Spacer(Modifier.height(RosarySpace.xl))
                }
            }
        }
    }
}

@Composable
private fun FeastSecondaryPage(
    title: String,
    feast: Feast,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val palette = LocalThemePalette.current
    val density = LocalDensity.current
    val chromeDp = with(density) { WindowInsets.statusBars.getTop(this).toDp() } + 44.dp
    val chromeOverlapPx = with(density) { chromeDp.toPx() }
    Box(modifier.fillMaxSize()) {
        AppPageBackground()
        Box(
            Modifier
                .fillMaxSize()
                .background(palette.bg),
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = RosarySpace.tabBarContentClearance),
        ) {
            FeastHeroBanner(
                feast = feast,
                height = RosarySpace.feastSecondaryHeroHeight + chromeDp,
                chromeOverlapPx = chromeOverlapPx,
            )
            Column(Modifier.padding(horizontal = RosarySpace.gutter)) {
                Spacer(Modifier.height(22.dp))
                GuideSectionLabel(
                    text = feast.rank.title,
                    style = RosaryType.captionPray,
                )
                Spacer(Modifier.height(RosarySpace.sm))
                Text(title, style = RosaryType.serifDisplay, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.sm))
                Text(feast.shortTitle, style = RosaryType.serifBody, color = palette.dim)
                Spacer(Modifier.height(30.dp))
                content()
                Spacer(Modifier.height(34.dp))
            }
        }
        FeastOverlayChrome(title = title, onBack = onBack)
    }
}

internal fun patronagesFor(feast: Feast): List<String> = when (feast.id) {
    "mary-mother-of-god" -> listOf("Mothers", "Peace", "The Church beginning the civil year")
    "lourdes" -> listOf("The sick", "Pilgrims", "Those seeking healing")
    "joseph" -> listOf("The universal Church", "Families", "Workers", "A holy death")
    "fatima" -> listOf("Conversion", "Peace", "Families praying the Rosary")
    "carmel" -> listOf("The Carmelite family", "Those who wear the Brown Scapular", "Contemplative prayer")
    "michael" -> listOf("Police, soldiers, and first responders", "The protection of the Church", "Those in spiritual battle")
    "guardian-angels" -> listOf("Children", "Travelers", "Daily protection")
    "rosary" -> listOf("Those devoted to the Rosary", "Families", "Perseverance in prayer")
    "all-souls" -> listOf("The faithful departed", "Those who grieve", "Prayer for the holy souls")
    "immaculate-conception" -> listOf("The United States", "Purity of heart", "A new beginning in grace")
    "guadalupe" -> listOf("The Americas", "The unborn", "Evangelization")
    else -> when {
        feast.isMarian -> listOf(
            "Those seeking Mary’s intercession",
            "Families",
            "Growth in faith, hope, and love",
        )
        feast.rank == FeastRank.Solemnity -> listOf(
            "The whole Church",
            "Renewal in the mystery celebrated today",
        )
        else -> listOf(
            "Those who keep this feast",
            "A deeper love for Christ and his Church",
        )
    }
}
