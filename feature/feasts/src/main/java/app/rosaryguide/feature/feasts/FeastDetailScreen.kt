package app.rosaryguide.feature.feasts

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.data.catalog.FeastNarratives
import app.rosaryguide.core.data.catalog.FeastRelatedPrayer
import app.rosaryguide.core.data.catalog.FeastScriptures
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.component.SectionBand
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosaryHex
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.FeastRank
import app.rosaryguide.core.model.MysterySetKind
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun FeastDetailScreen(
    item: DatedFeast,
    onPray: (MysterySetKind) -> Unit,
    modifier: Modifier = Modifier,
    onBack: () -> Unit = {},
    onRemindMe: () -> Unit = {},
    onOpenRelatedPrayers: () -> Unit = {},
    onOpenPatronages: () -> Unit = {},
    onOpenScripture: () -> Unit = {},
    includeChrome: Boolean = true,
    locale: Locale = Locale.getDefault(),
) {
    val palette = LocalThemePalette.current
    val feast = item.feast
    val narrative = FeastNarratives.narrative(feast.id)
    val about = narrative?.about ?: feast.summary
    val history = narrative?.history
    val indulgence = narrative?.indulgence
    val passages = FeastScriptures.passages(feast.id)
    val prayers = prayersForDay(item, narrative?.relatedPrayers.orEmpty())
    val assignment = MysteryCalendar.assignment(item.date)
    val rosarySet = feast.suggestedMysterySet ?: assignment.set
    val metadata = "${item.date.format(DateTimeFormatter.ofPattern("d MMMM", locale))}. ${feast.rank.title}"
        .uppercase(locale)
    val dateValue = item.date.format(DateTimeFormatter.ofPattern("d MMMM yyyy", locale))
    var expandedPrayerId by remember { mutableStateOf<String?>(null) }
    val density = LocalDensity.current
    val chrome = rememberFeastChromeMetrics()
    val underlapPx = with(density) { chrome.underlap.toPx() }

    BoxWithConstraints(modifier.fillMaxSize()) {
        val heroHeight = feastHeroHeight(maxWidth, RosarySpace.feastHeroHeight)
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
            FeastHeroTopSpacer(chrome)
            FeastHeroBanner(
                feast = feast,
                height = heroHeight,
                chromeOverlapPx = underlapPx,
            )
            Column(Modifier.padding(horizontal = RosarySpace.gutter)) {
                Spacer(Modifier.height(18.dp))
                Text(
                    text = metadata,
                    style = RosaryType.captionPray,
                    color = palette.dim,
                )
                Spacer(Modifier.height(RosarySpace.sm))
                Text(
                    text = feast.shortTitle,
                    style = RosaryType.headingPrimaryPray,
                    color = palette.ink,
                    maxLines = 3,
                )
                if (feast.summary.isNotBlank()) {
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(
                        text = feast.summary,
                        style = RosaryType.bodyFeastSummary,
                        color = palette.dim,
                    )
                }

                Spacer(Modifier.height(26.dp))
                meaningParagraphs(about).forEach { paragraph ->
                    Text(
                        text = paragraph,
                        style = RosaryType.bodySmallFeast,
                        color = palette.ink,
                    )
                    Spacer(Modifier.height(RosarySpace.xl))
                }
                if (!history.isNullOrBlank()) {
                    meaningParagraphs(history).forEach { paragraph ->
                        Text(
                            text = paragraph,
                            style = RosaryType.bodySmallFeast,
                            color = palette.ink,
                        )
                        Spacer(Modifier.height(RosarySpace.xl))
                    }
                }

                FeastCard {
                    QuickFactRow("Observed as", feast.rank.title)
                    HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                    QuickFactRow("Date", dateValue)
                    HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                    QuickFactRow("Rosary", "${rosarySet.shortName} Mysteries")
                    if (isLikelyHolyDayOfObligation(feast.id)) {
                        HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                        QuickFactRow(
                            "Note",
                            "May be a holy day of obligation depending on country and year",
                        )
                    }
                }

                SectionBand(fullBleed = true)
                GuideSectionLabel(
                    text = "Keep the day",
                    strong = true,
                    style = RosaryType.bodyPray,
                )
                Spacer(Modifier.height(RosarySpace.sectionTitleGap - RosarySpace.xs))
                FeastCard {
                    val practices = FeastDayPractices.forFeast(feast.id, feast.isMarian, feast.rank)
                    practices.forEachIndexed { index, practice ->
                        Column(Modifier.fillMaxWidth().padding(vertical = 15.dp)) {
                            Text(practice.first, style = RosaryType.bodyPray, color = palette.ink)
                            Spacer(Modifier.height(RosarySpace.sm))
                            Text(practice.second, style = RosaryType.themeSummary, color = palette.dim)
                        }
                        if (index < practices.lastIndex) {
                            HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                        }
                    }
                }

                SectionBand(fullBleed = true)
                GuideSectionLabel(
                    text = "Prayers for this day",
                    strong = true,
                    style = RosaryType.bodyPray,
                )
                Spacer(Modifier.height(RosarySpace.sectionTitleGap - 12.dp - RosarySpace.xs))
                prayers.forEach { prayer ->
                    FeastPrayerCard(
                        prayer = prayer,
                        expanded = expandedPrayerId == prayer.id,
                        onToggle = {
                            expandedPrayerId = if (expandedPrayerId == prayer.id) null else prayer.id
                        },
                    )
                    Spacer(Modifier.height(RosarySpace.md))
                }

                SectionBand(fullBleed = true)
                GuideSectionLabel(
                    text = "Scripture and Rosary",
                    strong = true,
                    style = RosaryType.bodyPray,
                )
                Spacer(Modifier.height(RosarySpace.sectionTitleGap - 12.dp - RosarySpace.xs))
                FeastCard {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onPray(rosarySet) }
                            .padding(vertical = RosarySpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        MysterySetMark(rosarySet)
                        Spacer(Modifier.width(RosarySpace.md))
                        Column {
                            GuideSectionLabel(
                                text = "Mystery set",
                                strong = true,
                                style = RosaryType.bodyPray,
                            )
                            Text(
                                rosarySet.titleText.english,
                                style = RosaryType.bodyPray,
                                color = palette.ink,
                            )
                        }
                    }
                }
                Spacer(Modifier.height(RosarySpace.md))
                if (passages.isEmpty()) {
                    FeastTextCard(
                        eyebrow = "Scripture",
                        title = "Held in the Church’s memory",
                        body = "${feast.shortTitle} is kept through Scripture, prayer, worship, and the Church’s living tradition.",
                    )
                } else {
                    FeastCard {
                        passages.take(3).forEachIndexed { index, passage ->
                            Column(Modifier.fillMaxWidth().padding(vertical = 15.dp)) {
                                GuideSectionLabel(
                                    text = passage.citation,
                                    style = RosaryType.captionPray,
                                )
                                Spacer(Modifier.height(RosarySpace.sm))
                                Text(passage.heading, style = RosaryType.bodyPray, color = palette.ink)
                                Spacer(Modifier.height(RosarySpace.sm))
                                Text(passage.text, style = RosaryType.themeSummary, color = palette.dim)
                            }
                            if (index < passages.take(3).lastIndex) {
                                HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                            }
                        }
                    }
                }

                if (!indulgence.isNullOrBlank()) {
                    Spacer(Modifier.height(RosarySpace.xl))
                    FeastTextCard(
                        eyebrow = "Indulgence",
                        title = "A grace attached to this day",
                        body = indulgence,
                    )
                }

                Spacer(Modifier.height(RosarySpace.xl))
                FeastInfoRow("Related prayers", onOpenRelatedPrayers)
                HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                FeastInfoRow("Patronages", onOpenPatronages)
                HorizontalDivider(thickness = Hairline.thickness, color = palette.hair)
                FeastInfoRow("In Scripture", onOpenScripture)
                Spacer(Modifier.height(40.dp))
            }
        }
        if (includeChrome) {
            FeastOverlayChrome(title = feast.shortTitle, onBack = onBack, metrics = chrome)
        }
    }
}

@Composable
private fun FeastInfoRow(title: String, onClick: () -> Unit) {
    val palette = LocalThemePalette.current
    Text(
        text = title,
        style = RosaryType.serifBody,
        color = palette.ink,
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = 17.dp),
    )
}

@Composable
private fun MysterySetMark(set: MysterySetKind) {
    Box(
        modifier = Modifier
            .size(56.dp)
            .clip(CircleShape)
            .background(Color(RosaryHex.MysteryJoyful)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            set.letter,
            style = RosaryType.headingSecondaryPray,
            color = Color(RosaryHex.MysteryOn),
        )
    }
}

@Composable
private fun QuickFactRow(label: String, value: String) {
    val palette = LocalThemePalette.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 15.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Text(
            text = label,
            style = RosaryType.captionPray,
            color = palette.dim,
            modifier = Modifier.width(88.dp),
        )
        Text(
            text = value,
            style = RosaryType.bodyPray,
            color = palette.ink,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun FeastCard(content: @Composable () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape)
            .padding(horizontal = RosarySpace.lg),
    ) { content() }
}

@Composable
internal fun FeastTextCard(eyebrow: String, title: String, body: String) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape)
            .padding(RosarySpace.lg),
    ) {
        GuideSectionLabel(text = eyebrow, style = RosaryType.captionPray)
        Spacer(Modifier.height(RosarySpace.md))
        Text(title, style = RosaryType.headingSecondaryPray, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.md))
        Text(body, style = RosaryType.bodySmallFeastPrayer, color = palette.dim)
    }
}

@Composable
internal fun FeastPrayerCard(
    prayer: FeastRelatedPrayer,
    expanded: Boolean,
    onToggle: () -> Unit,
    flush: Boolean = false,
    showLatin: Boolean = false,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    val frame = if (flush) {
        Modifier.fillMaxWidth()
    } else {
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape)
    }
    Column(
        modifier = frame,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .sizeIn(minHeight = RosarySpace.minHitTarget)
                .clickable(role = Role.Button, onClick = onToggle)
                .padding(horizontal = if (flush) 0.dp else 18.dp, vertical = RosarySpace.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                prayer.title,
                style = RosaryType.bodyPray,
                color = palette.ink,
                modifier = Modifier.weight(1f),
            )
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = palette.dim,
                modifier = Modifier
                    .size(12.dp)
                    .rotate(if (expanded) 180f else 0f),
            )
        }
        AnimatedVisibility(
            visible = expanded,
            enter = if (reduceMotion) fadeIn() else expandVertically() + fadeIn(),
            exit = if (reduceMotion) fadeOut() else shrinkVertically() + fadeOut(),
        ) {
            Column(Modifier.padding(start = if (flush) 0.dp else 18.dp, end = if (flush) 0.dp else 18.dp, bottom = 18.dp)) {
                Text(prayer.english, style = RosaryType.bodySmallFeastPrayer, color = palette.dim)
                if (showLatin) {
                    prayer.latin?.takeIf { it.isNotBlank() }?.let { latin ->
                        Spacer(Modifier.height(RosarySpace.md))
                        Text(
                            latin,
                            style = RosaryType.themeSummary,
                            color = palette.dim,
                        )
                    }
                }
                prayer.note?.let { note ->
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(note, style = RosaryType.captionPray, color = palette.dim)
                }
            }
        }
    }
}

private fun meaningParagraphs(body: String): List<String> {
    val trimmed = body.trim()
    if (trimmed.isEmpty()) return emptyList()
    val byBlank = trimmed.split("\n\n").map { it.trim() }.filter { it.isNotEmpty() }
    if (byBlank.size > 1) return byBlank
    val sentences = trimmed.split('.')
        .map { it.trim() }
        .filter { it.isNotEmpty() }
        .map { if (it.endsWith('?') || it.endsWith('!')) it else "$it." }
    if (sentences.size < 2) return listOf(trimmed)
    val mid = sentences.size / 2
    return listOf(sentences.take(mid).joinToString(" "), sentences.drop(mid).joinToString(" "))
}

private fun isLikelyHolyDayOfObligation(id: String): Boolean =
    id in setOf("mary-mother-of-god", "assumption", "all-saints", "immaculate-conception", "christmas")

internal fun prayersForDay(item: DatedFeast, related: List<FeastRelatedPrayer>): List<FeastRelatedPrayer> {
    if (related.isNotEmpty()) return related
    val feast = item.feast
    fun of(id: String): FeastRelatedPrayer? {
        val prayer = PrayerCatalog.prayer(id) ?: return null
        return FeastRelatedPrayer(
            id = prayer.id,
            title = prayer.title.english,
            english = prayer.text.english,
            latin = prayer.text.latin.takeIf { it.isNotBlank() },
        )
    }
    return when {
        feast.isMarian -> listOfNotNull(of("hail-holy-queen"))
        feast.id == "michael" -> listOfNotNull(of("saint-michael"))
        feast.id == "guardian-angels" -> listOfNotNull(of("guardian-angel"))
        else -> listOfNotNull(of("our-father"))
    }
}

internal object FeastDayPractices {
    fun forFeast(id: String, isMarian: Boolean, rank: FeastRank): List<Pair<String, String>> = when (id) {
        "michael" -> listOf(
            "Pray for protection" to "Pray the Saint Michael Prayer for the Church, your family, and anyone in danger.",
            "Remember the archangels" to "Michael defends, Gabriel announces, and Raphael heals. Ask God for courage, clarity, and healing.",
            "Pray the Glorious Mysteries" to "The feast points toward heaven, the angels, and the victory of Christ.",
        )
        "guardian-angels" -> listOf(
            "Ask for guidance" to "Pause before decisions today and ask God to guide you through your guardian angel.",
            "Pray for children and travelers" to "This memorial is a natural day to pray for protection over the vulnerable and those on the road.",
            "Give thanks" to "Thank God for hidden help, providence, and care you may never fully see.",
        )
        "all-souls" -> listOf(
            "Pray for the dead" to "Offer the Rosary, the Eternal Rest prayer, or Mass for the faithful departed.",
            "Visit a cemetery" to "Catholics traditionally visit cemeteries and pray for the holy souls, especially in early November.",
            "Offer today’s Rosary" to "Name someone you love and offer the Sorrowful Mysteries for them.",
        )
        "rosary" -> listOf(
            "Pray five decades" to "This is the natural day to pray the full Rosary with attention and without hurry.",
            "Pray as a family" to "The memorial has long been connected with families and communities gathering around the beads.",
            "Stay with one mystery" to "If time is short, pray one decade slowly and carry that mystery through the day.",
        )
        "immaculate-conception" -> listOf(
            "Attend Mass if obliged" to "This solemnity is a holy day of obligation in some places, including the United States, subject to the local calendar.",
            "Ask for purity of heart" to "Pray for a clean beginning, a freer yes to God, and Mary’s help against sin.",
            "Pray a Marian prayer" to "The Memorare or Hail Holy Queen fits the day especially well.",
        )
        "assumption" -> listOf(
            "Attend Mass if obliged" to "This solemnity is a holy day of obligation in many places, subject to the local calendar.",
            "Pray with hope" to "The Assumption points to the resurrection of the body and the destiny God prepares for his saints.",
            "Pray the Glorious Mysteries" to "The fourth Glorious Mystery belongs directly to this day.",
        )
        "christmas" -> listOf(
            "Attend Mass" to "Christmas is one of the great solemnities of the Church’s year.",
            "Pray the Joyful Mysteries" to "The Nativity is the heart of the day; pray it slowly and simply.",
            "Keep the octave" to "The Church celebrates Christmas for eight days, then continues the season until the Baptism of the Lord.",
        )
        else -> when {
            isMarian -> listOf(
                "Pray this Rosary" to "Let the day lead you back to Christ through Mary.",
                "Pray a Marian prayer" to "The Hail Holy Queen, Memorare, or Angelus is a simple way to keep the feast.",
                "Offer an intention" to "Bring one person or need to Mary’s intercession today.",
            )
            rank == FeastRank.Solemnity -> listOf(
                "Go to Mass if obliged" to "Some solemnities are holy days of obligation depending on country and year.",
                "Pray the suggested mysteries" to "Use the Rosary set connected to this mystery where the app suggests one.",
                "Mark the day" to "Read the Gospel, pray slowly, and let the feast shape the whole day.",
            )
            else -> listOf(
                "Read the short meditation" to "Begin with what the Church is remembering today.",
                "Pray one related prayer" to "Choose the prayer below and offer it for a real intention.",
                "Carry one line" to "Take one phrase from the feast into the rest of the day.",
            )
        }
    }
}
