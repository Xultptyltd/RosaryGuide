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
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.FeastCoverMath
import app.rosaryguide.core.data.art.FeastSubjects
import app.rosaryguide.core.data.art.SizeF
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.data.catalog.FeastNarratives
import app.rosaryguide.core.data.catalog.FeastRelatedPrayer
import app.rosaryguide.core.data.catalog.FeastScriptures
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
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
    chromeOverlapPx: Float = 0f,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val feast = item.feast
    val resId = feastHeroDrawableId(context, feast.id)
    val narrative = FeastNarratives.narrative(feast.id)
    val about = narrative?.about ?: feast.summary
    val history = narrative?.history
    val indulgence = narrative?.indulgence
    val passages = FeastScriptures.passages(feast.id)
    val prayers = prayersForDay(item, narrative?.relatedPrayers.orEmpty())
    val assignment = MysteryCalendar.assignment(item.date)
    val rosarySet = feast.suggestedMysterySet ?: assignment.set
    val metadata = "${item.date.format(DateTimeFormatter.ofPattern("d MMMM", Locale.getDefault()))}. ${feast.rank.title}".uppercase(Locale.getDefault())
    val dateValue = item.date.format(DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.getDefault()))
    var expandedPrayerId by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xxl),
    ) {
        if (resId != 0) {
            val subject = FeastSubjects.ofFeastId(feast.id)
            if (subject != null) {
                CroppedArt(
                    painter = painterResource(resId),
                    coverForFrame = { frameW, frameH ->
                        val cover = FeastCoverMath.feastCover(
                            SizeF(1280f, 720f),
                            SizeF(frameW, frameH),
                            subject,
                            subject.focusX,
                        )
                        val shift = FeastCoverMath.feastChromeShift(chromeOverlapPx, frameH)
                        Triple(cover.scale, cover.offsetX, cover.offsetY + shift)
                    },
                    contentDescription = feast.shortTitle,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(330.dp),
                )
            }
        }
        Column(Modifier.padding(horizontal = RosarySpace.gutter)) {
            Spacer(Modifier.height(18.dp))
            GuideSectionLabel(text = metadata)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(text = feast.shortTitle, style = RosaryType.headingPrimary, color = palette.ink)
            if (feast.summary.isNotBlank()) {
                Spacer(Modifier.height(RosarySpace.md))
                Text(text = feast.summary, style = RosaryType.body, color = palette.dim)
            }

            Spacer(Modifier.height(26.dp))
            meaningParagraphs(about).forEach { paragraph ->
                Text(text = paragraph, style = RosaryType.body, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.xl))
            }
            if (!history.isNullOrBlank()) {
                meaningParagraphs(history).forEach { paragraph ->
                    Text(text = paragraph, style = RosaryType.body, color = palette.ink)
                    Spacer(Modifier.height(RosarySpace.xl))
                }
            }

            FeastCard {
                QuickFactRow("Observed as", feast.rank.title)
                HorizontalDivider(color = palette.strokeRegular)
                QuickFactRow("Date", dateValue)
                HorizontalDivider(color = palette.strokeRegular)
                QuickFactRow("Rosary", "${rosarySet.shortName} Mysteries")
                if (isLikelyHolyDayOfObligation(feast.id)) {
                    HorizontalDivider(color = palette.strokeRegular)
                    QuickFactRow("Note", "May be a holy day of obligation depending on country and year")
                }
            }

            Spacer(Modifier.height(RosarySpace.xl))
            GuideSectionLabel(text = "Keep the day")
            Spacer(Modifier.height(RosarySpace.sm))
            FeastCard {
                val practices = FeastDayPractices.forFeast(feast.id, feast.isMarian, feast.rank)
                practices.forEachIndexed { index, practice ->
                    Column(Modifier.fillMaxWidth().padding(vertical = 15.dp)) {
                        Text(practice.first, style = RosaryType.headingSecondary, color = palette.ink)
                        Spacer(Modifier.height(RosarySpace.sm))
                        Text(practice.second, style = RosaryType.supportingLabel, color = palette.dim)
                    }
                    if (index < practices.lastIndex) HorizontalDivider(color = palette.strokeRegular)
                }
            }

            Spacer(Modifier.height(RosarySpace.xl))
            GuideSectionLabel(text = "Prayers for this day")
            Spacer(Modifier.height(RosarySpace.sm))
            prayers.forEach { prayer ->
                FeastPrayerCard(
                    prayer = prayer,
                    expanded = expandedPrayerId == prayer.id,
                    onToggle = { expandedPrayerId = if (expandedPrayerId == prayer.id) null else prayer.id },
                )
                Spacer(Modifier.height(RosarySpace.md))
            }

            Spacer(Modifier.height(RosarySpace.sm))
            GuideSectionLabel(text = "Scripture and Rosary")
            Spacer(Modifier.height(RosarySpace.sm))
            FeastCard {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onPray(rosarySet) }
                        .padding(vertical = RosarySpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(androidx.compose.ui.graphics.Color(app.rosaryguide.core.designsystem.theme.RosaryHex.MysteryJoyful)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(rosarySet.letter, style = RosaryType.headingSecondary, color = androidx.compose.ui.graphics.Color(app.rosaryguide.core.designsystem.theme.RosaryHex.MysteryOn))
                    }
                    Spacer(Modifier.width(RosarySpace.md))
                    Column {
                        GuideSectionLabel(text = "Mystery set")
                        Text(rosarySet.titleText.english, style = RosaryType.body, color = palette.ink)
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
                            GuideSectionLabel(text = passage.citation)
                            Spacer(Modifier.height(RosarySpace.xs))
                            Text(passage.heading, style = RosaryType.headingSecondary, color = palette.ink)
                            Spacer(Modifier.height(RosarySpace.sm))
                            Text(passage.text, style = RosaryType.supportingLabel, color = palette.dim)
                        }
                        if (index < passages.take(3).lastIndex) HorizontalDivider(color = palette.strokeRegular)
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
        }
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
            style = RosaryType.caption,
            color = palette.dim,
            modifier = Modifier.width(88.dp),
        )
        Text(text = value, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
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
private fun FeastTextCard(eyebrow: String, title: String, body: String) {
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
        GuideSectionLabel(text = eyebrow)
        Spacer(Modifier.height(RosarySpace.md))
        Text(title, style = RosaryType.headingSecondary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.md))
        Text(body, style = RosaryType.body, color = palette.dim)
    }
}

@Composable
private fun FeastPrayerCard(
    prayer: FeastRelatedPrayer,
    expanded: Boolean,
    onToggle: () -> Unit,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .sizeIn(minHeight = RosarySpace.minHitTarget)
                .clickable(role = Role.Button, onClick = onToggle)
                .padding(horizontal = 18.dp, vertical = RosarySpace.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(prayer.title, style = RosaryType.headingSecondary, color = palette.ink, modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = palette.dim,
                modifier = Modifier.rotate(if (expanded) 180f else 0f),
            )
        }
        AnimatedVisibility(
            visible = expanded,
            enter = if (reduceMotion) fadeIn() else expandVertically() + fadeIn(),
            exit = if (reduceMotion) fadeOut() else shrinkVertically() + fadeOut(),
        ) {
            Column(Modifier.padding(start = 18.dp, end = 18.dp, bottom = 18.dp)) {
                Text(prayer.english, style = RosaryType.body, color = palette.dim)
                prayer.latin?.takeIf { it.isNotBlank() }?.let { latin ->
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(latin, style = RosaryType.serifItalicBody, color = palette.dim)
                }
                prayer.note?.let { note ->
                    Spacer(Modifier.height(RosarySpace.md))
                    Text(note, style = RosaryType.caption, color = palette.dim)
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

private fun prayersForDay(item: DatedFeast, related: List<FeastRelatedPrayer>): List<FeastRelatedPrayer> {
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
