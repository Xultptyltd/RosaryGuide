package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.journey.JourneyDayDetail
import app.rosaryguide.core.data.journey.JourneyDayEntry
import app.rosaryguide.core.data.journey.JourneyDuration
import app.rosaryguide.core.data.journey.JourneyMilestones
import app.rosaryguide.core.data.journey.PrayerRhythm
import app.rosaryguide.core.data.session.OfferedIntentions
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JourneyScreen(
    sessionStore: SessionStore,
    today: LocalDate,
    zone: ZoneId,
    locale: Locale,
    firstWeekday: Int,
    startOnHistory: Boolean,
    initialDay: LocalDate?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val completed by sessionStore.completedSessions.collectAsState()
    val dayKeys by sessionStore.completedDayKeys.collectAsState()
    val journey by sessionStore.journey.collectAsState()
    val milestones = remember(completed, dayKeys, journey) { sessionStore.journeyMilestones() }
    val rhythm = remember(dayKeys, today, firstWeekday) {
        sessionStore.rhythm(
            nowEpochMs = today.atTime(12, 0).atZone(zone).toInstant().toEpochMilli(),
            firstWeekday = firstWeekday,
            locale = locale,
        )
    }
    var historyTab by remember { mutableStateOf(startOnHistory) }
    var selectedDay by remember { mutableStateOf(initialDay) }
    var historyMonthsShown by remember { mutableIntStateOf(4) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md),
    ) {
        GuideDetailTopBar(title = "Journey", onBack = onBack)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(RosarySpace.containerRadius))
                .background(palette.surface)
                .padding(4.dp),
        ) {
            JourneyTabChip("Milestones", selected = !historyTab, modifier = Modifier.weight(1f)) { historyTab = false }
            JourneyTabChip("History", selected = historyTab, modifier = Modifier.weight(1f)) { historyTab = true }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        if (historyTab) {
            HistoryTab(
                sessionStore = sessionStore,
                today = today,
                zone = zone,
                locale = locale,
                monthsShown = historyMonthsShown,
                onShowMore = { historyMonthsShown += 4 },
                onOpenDay = { selectedDay = it },
            )
        } else {
            MilestonesTab(milestones = milestones, rhythm = rhythm)
        }
    }

    val day = selectedDay
    if (day != null) {
        val entries = JourneyDayDetail.entries(
            dayKey = day.toString(),
            sessions = completed,
            decades = journey.completedDecades,
            prayedDayKeys = dayKeys,
            zone = zone,
        )
        ModalBottomSheet(
            onDismissRequest = { selectedDay = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = palette.bg,
        ) {
            HistoryDaySheet(date = day, entries = entries, locale = locale)
        }
    }
}

@Composable
private fun JourneyTabChip(title: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val palette = LocalThemePalette.current
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(if (selected) palette.accent else androidx.compose.ui.graphics.Color.Transparent)
            .clickable(onClick = onClick)
            .padding(vertical = RosarySpace.sm),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            style = RosaryType.segmentedControl,
            color = if (selected) palette.onAccent else palette.ink,
        )
    }
}

@Composable
private fun MilestonesTab(milestones: JourneyMilestones, rhythm: PrayerRhythm) {
    val palette = LocalThemePalette.current
    val stage = milestoneStage(milestones, rhythm.hasEverPrayed)
    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = RosarySpace.xl)) {
        PrayerRhythmCard(rhythm)
        Spacer(Modifier.height(RosarySpace.lg))
        Text(stage.first, style = RosaryType.headingSecondary, color = palette.ink)
        Text(stage.second, style = RosaryType.supportingLabel, color = palette.textSecondary)
        Spacer(Modifier.height(RosarySpace.lg))
        milestones.orderedCategories.forEach { category ->
            GuideSectionLabel(text = category.title)
            milestones.items.filter { it.category == category }.forEach { item ->
                MilestoneRow(item)
                Spacer(Modifier.height(RosarySpace.sm))
            }
            Spacer(Modifier.height(RosarySpace.md))
        }
    }
}

@Composable
fun MilestoneRow(item: JourneyMilestones.Item, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(RosarySpace.lg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                painter = painterResource(milestoneGlyph(item.symbol)),
                contentDescription = null,
                tint = if (item.completed) palette.accent else palette.textSecondary,
                modifier = Modifier.size(22.dp),
            )
            Spacer(Modifier.width(RosarySpace.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(item.title, style = RosaryType.body, color = palette.ink)
                Text(item.description, style = RosaryType.caption, color = palette.textSecondary)
            }
            Text(item.progressText, style = RosaryType.caption, color = palette.textSecondary)
        }
        Spacer(Modifier.height(RosarySpace.sm))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(palette.strokeRegular),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(item.progress.toFloat())
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(if (item.completed) palette.accent else palette.strokeSelected),
            )
        }
    }
}

@Composable
private fun HistoryTab(
    sessionStore: SessionStore,
    today: LocalDate,
    zone: ZoneId,
    locale: Locale,
    monthsShown: Int,
    onShowMore: () -> Unit,
    onOpenDay: (LocalDate) -> Unit,
) {
    val palette = LocalThemePalette.current
    val sessions = sessionStore.completed
    val decades = sessionStore.completedDecades
    val dayKeys = sessionStore.completedDayKeys.value
    val cutoff = YearMonth.from(today).minusMonths((monthsShown - 1).toLong()).atDay(1)

    data class RowModel(val date: LocalDate, val label: String, val detail: String, val duration: String?)

    val rows = buildList {
        for (session in sessions) {
            val date = Instant.ofEpochMilli(session.startedAtEpochMs).atZone(zone).toLocalDate()
            if (date.isBefore(cutoff)) continue
            val duration = JourneyDuration.reliable(session.duration)?.let { JourneyDuration.text(it) }
            val title = session.mysterySet.shortName + " Mysteries"
            val offered = OfferedIntentions.summary(session.allIntentionTitles)
            add(RowModel(date, title, offered ?: "Rosary", duration))
        }
        for (decade in decades) {
            val epoch = decade.startedAtEpochMs ?: decade.completedAtEpochMs
            val date = Instant.ofEpochMilli(epoch).atZone(zone).toLocalDate()
            if (date.isBefore(cutoff)) continue
            val duration = JourneyDuration.reliable(decade.duration)?.let { JourneyDuration.text(it) }
            add(RowModel(date, "Decade ${decade.decade}", OfferedIntentions.summary(decade.intentionTitles) ?: "Decade", duration))
        }
        val covered = (sessions.map { Instant.ofEpochMilli(it.startedAtEpochMs).atZone(zone).toLocalDate() } +
            decades.map { Instant.ofEpochMilli(it.startedAtEpochMs ?: it.completedAtEpochMs).atZone(zone).toLocalDate() }).toSet()
        for (key in dayKeys) {
            val date = runCatching { LocalDate.parse(key) }.getOrNull() ?: continue
            if (date.isBefore(cutoff) || date in covered) continue
            add(RowModel(date, "Rosary prayed", "Prayed before times and mysteries were recorded", null))
        }
    }.sortedByDescending { it.date }

    val grouped = rows.groupBy { YearMonth.from(it.date) }
    val monthFormatter = DateTimeFormatter.ofPattern("LLLL yyyy", locale)
    val dayFormatter = DateTimeFormatter.ofPattern("EEE d", locale)

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = RosarySpace.xl)) {
        if (rows.isEmpty()) {
            Text("No prayer recorded yet.", style = RosaryType.supportingLabel, color = palette.textSecondary)
        } else {
            grouped.toSortedMap(compareByDescending { it }).forEach { (month, items) ->
                GuideSectionLabel(text = month.format(monthFormatter).replaceFirstChar { it.titlecase(locale) })
                items.forEach { row ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(RosarySpace.containerRadius))
                            .background(palette.surface)
                            .clickable { onOpenDay(row.date) }
                            .padding(RosarySpace.lg)
                            .padding(bottom = RosarySpace.sm),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(row.date.format(dayFormatter), style = RosaryType.caption, color = palette.textSecondary)
                                Text(row.label, style = RosaryType.body, color = palette.ink)
                                Text(row.detail, style = RosaryType.caption, color = palette.textSecondary)
                            }
                            row.duration?.let {
                                Text(it, style = RosaryType.caption, color = palette.ink)
                            }
                        }
                    }
                    Spacer(Modifier.height(RosarySpace.sm))
                }
            }
            val oldest = (dayKeys.mapNotNull { runCatching { LocalDate.parse(it) }.getOrNull() } +
                sessions.map { Instant.ofEpochMilli(it.startedAtEpochMs).atZone(zone).toLocalDate() })
                .minOrNull()
            if (oldest != null && oldest.isBefore(cutoff)) {
                Text(
                    "Show more",
                    style = RosaryType.body,
                    color = palette.accent,
                    modifier = Modifier.clickable(onClick = onShowMore).padding(vertical = RosarySpace.md),
                )
            }
        }
    }
}

@Composable
fun HistoryDaySheet(
    date: LocalDate,
    entries: List<JourneyDayEntry>,
    locale: Locale,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val rosaries = entries.count { it.kind == JourneyDayEntry.Kind.Rosary || it.kind == JourneyDayEntry.Kind.RecordedDay }
    val decades = entries.size - rosaries
    val parts = buildList {
        if (rosaries > 0) add(if (rosaries == 1) "1 Rosary" else "$rosaries Rosaries")
        if (decades > 0) add(if (decades == 1) "1 decade" else "$decades decades")
        JourneyDayDetail.totalDuration(entries)?.let { add(JourneyDuration.text(it)) }
    }
    val summary = if (parts.isEmpty()) "Nothing prayed" else parts.joinToString(" · ")

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = RosarySpace.gutter)
            .padding(bottom = RosarySpace.xl),
    ) {
        Text(JourneyDayDetail.heading(date, locale), style = RosaryType.headingSecondary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.xs))
        Text(summary, style = RosaryType.supportingLabel, color = palette.textSecondary)
        Spacer(Modifier.height(RosarySpace.lg))
        if (entries.isEmpty()) {
            Text(
                "No prayer recorded on this day.",
                style = RosaryType.supportingLabel,
                color = palette.dim,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(RosarySpace.containerRadius))
                    .background(palette.surface)
                    .padding(RosarySpace.lg),
            )
        } else {
            entries.forEach { entry ->
                HistoryDayEntryRow(entry)
                Spacer(Modifier.height(RosarySpace.sm))
            }
        }
    }
}

@Composable
private fun HistoryDayEntryRow(entry: JourneyDayEntry) {
    val palette = LocalThemePalette.current
    val title = entry.mysterySet?.let { "${it.shortName} Mysteries" } ?: "Rosary prayed"
    val time = entry.completedAtEpochMs?.let { epoch ->
        DateTimeFormatter.ofPattern("h:mm a", Locale.forLanguageTag("en-AU"))
            .format(Instant.ofEpochMilli(epoch).atZone(ZoneId.of("Australia/Perth")))
    }
    val status = when (entry.kind) {
        JourneyDayEntry.Kind.Rosary -> time?.let { "Rosary · finished $it" } ?: "Rosary"
        JourneyDayEntry.Kind.Decade -> time?.let { "Decade · $it" } ?: "Decade"
        JourneyDayEntry.Kind.RecordedDay -> "Prayed before times and mysteries were recorded"
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(RosarySpace.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(palette.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Text(entry.mysterySet?.letter ?: "✦", style = RosaryType.body, color = palette.ink)
        }
        Spacer(Modifier.width(RosarySpace.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = RosaryType.body, color = palette.ink)
            Text(status, style = RosaryType.caption, color = palette.textSecondary)
            OfferedIntentions.countText(entry.intentionTitles)?.let {
                Text(it, style = RosaryType.caption, color = palette.textSecondary)
            }
        }
        entry.duration?.let {
            Text(JourneyDuration.text(it), style = RosaryType.caption, color = palette.ink)
        }
    }
}


private fun milestoneGlyph(symbol: String): Int = when (symbol) {
    "circle.dotted" -> R.drawable.ic_milestone_circle_dotted
    "calendar" -> R.drawable.ic_milestone_calendar
    "leaf" -> R.drawable.ic_milestone_leaf
    "sparkles" -> R.drawable.ic_milestone_sparkles
    "person.2" -> R.drawable.ic_milestone_people
    "building" -> R.drawable.ic_milestone_building
    "cross" -> R.drawable.ic_milestone_cross
    else -> R.drawable.ic_milestone_circle_dotted
}
