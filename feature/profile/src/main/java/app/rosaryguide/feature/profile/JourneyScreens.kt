package app.rosaryguide.feature.profile

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.journey.JourneyDayDetail
import app.rosaryguide.core.data.journey.JourneyDayEntry
import app.rosaryguide.core.data.journey.JourneyDuration
import app.rosaryguide.core.data.journey.JourneyMilestones
import app.rosaryguide.core.data.session.OfferedIntentions
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.OrdinalWord
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

private const val HistoryMonthsPerPage = 3

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
    var historyTab by remember { mutableStateOf(startOnHistory) }
    var selectedDay by remember { mutableStateOf(initialDay) }
    var historyMonthsShown by remember { mutableIntStateOf(HistoryMonthsPerPage) }
    var visibleMonth by remember { mutableStateOf(YearMonth.from(today)) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md),
    ) {
        GuideDetailTopBar(title = if (historyTab) "History" else "Milestones", onBack = onBack)
        val tabs = listOf("Milestones", "History")
        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            tabs.forEachIndexed { index, title ->
                val selected = (index == 1) == historyTab
                SegmentedButton(
                    selected = selected,
                    onClick = { historyTab = index == 1 },
                    shape = SegmentedButtonDefaults.itemShape(index, tabs.size),
                    colors = SegmentedButtonDefaults.colors(
                        activeContainerColor = palette.accent,
                        activeContentColor = palette.onAccent,
                        inactiveContainerColor = palette.surface,
                        inactiveContentColor = palette.ink,
                    ),
                    label = { Text(title, style = RosaryType.segmentedControl, maxLines = 1) },
                )
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        if (historyTab) {
            HistoryTab(
                sessionStore = sessionStore,
                today = today,
                zone = zone,
                locale = locale,
                firstWeekday = firstWeekday,
                visibleMonth = visibleMonth,
                onShiftMonth = { visibleMonth = visibleMonth.plusMonths(it.toLong()) },
                monthsShown = historyMonthsShown,
                onShowMore = { historyMonthsShown += HistoryMonthsPerPage },
                onOpenDay = { selectedDay = it },
            )
        } else {
            MilestonesTab(
                milestones = milestones,
                hasPrayer = dayKeys.isNotEmpty() || completed.isNotEmpty(),
            )
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
private fun MilestonesTab(milestones: JourneyMilestones, hasPrayer: Boolean) {
    val palette = LocalThemePalette.current
    val stage = milestoneStage(milestones, hasPrayer)
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xl),
    ) {
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
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(palette.accentTint),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_milestone_leaf),
                    contentDescription = null,
                    tint = palette.accentText,
                    modifier = Modifier.size(25.dp),
                )
            }
            Spacer(Modifier.width(RosarySpace.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(stage.first, style = RosaryType.headingSecondary, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.sm))
                Text(
                    "${milestones.earnedCount} of ${milestones.items.size} milestones completed",
                    style = RosaryType.caption,
                    color = palette.dim,
                )
            }
        }
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
                contentDescription = if (item.completed) "Completed" else null,
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
        if (item.completed) {
            item.earnedAtEpochMs?.let { earned ->
                val done = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.getDefault())
                    .format(Instant.ofEpochMilli(earned).atZone(ZoneId.systemDefault()))
                Spacer(Modifier.height(RosarySpace.xs))
                Text(
                    "Completed $done",
                    style = RosaryType.caption,
                    color = palette.dim,
                )
            }
        }
    }
}

@Composable
private fun HistoryTab(
    sessionStore: SessionStore,
    today: LocalDate,
    zone: ZoneId,
    locale: Locale,
    firstWeekday: Int,
    visibleMonth: YearMonth,
    onShiftMonth: (Int) -> Unit,
    monthsShown: Int,
    onShowMore: () -> Unit,
    onOpenDay: (LocalDate) -> Unit,
) {
    val palette = LocalThemePalette.current
    val sessions = sessionStore.completed
    val decades = sessionStore.completedDecades
    val dayKeys = sessionStore.completedDayKeys.value
    val prayerTimeByDay = sessionStore.prayerTimeByDay
    val cutoff = YearMonth.from(today).minusMonths((monthsShown - 1).toLong()).atDay(1)

    val sessionDates = sessions.map { Instant.ofEpochMilli(it.completedAtEpochMs).atZone(zone).toLocalDate() }
    val decadeDates = decades.map {
        Instant.ofEpochMilli(it.startedAtEpochMs ?: it.completedAtEpochMs).atZone(zone).toLocalDate()
    }
    val prayedDays = (
        sessionDates +
            dayKeys.mapNotNull { runCatching { LocalDate.parse(it) }.getOrNull() }
        ).toSet()
    val partialDays = decadeDates.filter { it !in prayedDays }.toSet()

    data class RowModel(
        val date: LocalDate,
        val label: String,
        val status: String,
        val intentionCount: String?,
        val duration: String?,
    )

    val rows = buildList {
        for (session in sessions) {
            val date = Instant.ofEpochMilli(session.completedAtEpochMs).atZone(zone).toLocalDate()
            if (date.isBefore(cutoff)) continue
            val duration = JourneyDuration.reliable(session.duration)?.let { JourneyDuration.text(it) }
            val status = duration?.let { "Rosary completed · $it" } ?: "Rosary completed"
            add(
                RowModel(
                    date = date,
                    label = session.mysterySet.shortName + " Mysteries",
                    status = status,
                    intentionCount = OfferedIntentions.countText(session.allIntentionTitles),
                    duration = duration,
                ),
            )
        }
        for (decade in decades) {
            val epoch = decade.startedAtEpochMs ?: decade.completedAtEpochMs
            val date = Instant.ofEpochMilli(epoch).atZone(zone).toLocalDate()
            if (date.isBefore(cutoff)) continue
            val duration = JourneyDuration.reliable(decade.duration)?.let { JourneyDuration.text(it) }
            val roman = runCatching { OrdinalWord.roman(decade.decade) }.getOrDefault(decade.decade.toString())
            val status = duration?.let { "Decade $roman prayed · $it" } ?: "Decade $roman prayed"
            add(
                RowModel(
                    date = date,
                    label = mysterySetTitle(decade.mysterySet) ?: "Decade $roman",
                    status = status,
                    intentionCount = OfferedIntentions.countText(decade.intentionTitles),
                    duration = duration,
                ),
            )
        }
        val covered = (sessionDates + decadeDates).toSet()
        for (key in dayKeys) {
            val date = runCatching { LocalDate.parse(key) }.getOrNull() ?: continue
            if (date.isBefore(cutoff) || date in covered) continue
            add(
                RowModel(
                    date = date,
                    label = "Rosary prayed",
                    status = "Prayed before times and mysteries were recorded",
                    intentionCount = null,
                    duration = null,
                ),
            )
        }
    }.sortedByDescending { it.date }

    val grouped = rows.groupBy { YearMonth.from(it.date) }
    val monthFormatter = DateTimeFormatter.ofPattern("LLLL yyyy", locale)
    val oldest = (dayKeys.mapNotNull { runCatching { LocalDate.parse(it) }.getOrNull() } + sessionDates + decadeDates)
        .minOrNull()
    val hasOlder = oldest != null && oldest.isBefore(cutoff)

    val monthStart = visibleMonth.atDay(1)
    val monthEnd = visibleMonth.atEndOfMonth()
    fun inVisibleMonth(date: LocalDate) = !date.isBefore(monthStart) && !date.isAfter(monthEnd)
    val monthRosaries = (sessionDates.filter(::inVisibleMonth).toSet() +
        dayKeys.mapNotNull { runCatching { LocalDate.parse(it) }.getOrNull() }.filter(::inVisibleMonth)).size
    val monthStandaloneDecades = decadeDates.filter { inVisibleMonth(it) && it !in prayedDays }.size
    val monthDecadeCount = monthRosaries * 5 + monthStandaloneDecades
    val monthDuration = prayerTimeByDay.entries
        .mapNotNull { (key, value) ->
            val date = runCatching { LocalDate.parse(key) }.getOrNull() ?: return@mapNotNull null
            if (inVisibleMonth(date)) JourneyDuration.dayTotal(value) else null
        }
        .sum()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xl),
        verticalArrangement = Arrangement.spacedBy(RosarySpace.xl),
    ) {
        JourneyMonthCalendar(
            visibleMonth = visibleMonth,
            today = today,
            locale = locale,
            firstWeekday = firstWeekday,
            prayedDays = prayedDays,
            partialDays = partialDays,
            monthRosaries = monthRosaries,
            monthDecadeCount = monthDecadeCount,
            monthDurationText = if (monthDuration > 0) JourneyDuration.text(monthDuration) else "—",
            onShiftMonth = onShiftMonth,
            onOpenDay = onOpenDay,
        )

        if (sessions.isEmpty() && decades.isEmpty() && dayKeys.isEmpty()) {
            Text(
                "Your completed Rosaries and decades will appear here.",
                style = RosaryType.body,
                color = palette.dim,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(RosarySpace.containerRadius))
                    .background(palette.surface)
                    .padding(RosarySpace.lg),
            )
        } else {
            if (rows.isEmpty()) {
                Text(
                    "No prayers in the last $monthsShown months.",
                    style = RosaryType.body,
                    color = palette.dim,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(RosarySpace.containerRadius))
                        .background(palette.surface)
                        .padding(RosarySpace.lg),
                )
            }
            grouped.toSortedMap(compareByDescending { it }).forEach { (month, items) ->
                GuideSectionLabel(text = month.format(monthFormatter).replaceFirstChar { it.titlecase(locale) })
                items.forEach { row ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(RosarySpace.containerRadius))
                            .background(palette.surface)
                            .clickable { onOpenDay(row.date) }
                            .padding(RosarySpace.lg),
                    ) {
                        Text(row.label, style = RosaryType.body, color = palette.ink)
                        Text(row.status, style = RosaryType.caption, color = palette.textSecondary)
                        row.intentionCount?.let {
                            Text(it, style = RosaryType.caption, color = palette.textSecondary)
                        }
                    }
                    Spacer(Modifier.height(RosarySpace.sm))
                }
            }
            if (hasOlder) {
                OutlinedButton(
                    onClick = onShowMore,
                    shape = RoundedCornerShape(RosarySpace.containerRadius),
                    border = BorderStroke(1.dp, palette.strokeRegular),
                    modifier = Modifier.heightIn(min = 40.dp),
                ) {
                    Text("Show more", style = RosaryType.body, color = palette.ink)
                }
            } else if (oldest != null) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(top = RosarySpace.sm),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("Your prayer history starts here", style = RosaryType.caption, color = palette.dim)
                    Text(
                        oldest.format(DateTimeFormatter.ofPattern("d MMMM yyyy", locale)),
                        style = RosaryType.caption,
                        color = palette.dim,
                    )
                }
            }
        }
    }
}

@Composable
private fun JourneyMonthCalendar(
    visibleMonth: YearMonth,
    today: LocalDate,
    locale: Locale,
    firstWeekday: Int,
    prayedDays: Set<LocalDate>,
    partialDays: Set<LocalDate>,
    monthRosaries: Int,
    monthDecadeCount: Int,
    monthDurationText: String,
    onShiftMonth: (Int) -> Unit,
    onOpenDay: (LocalDate) -> Unit,
) {
    val palette = LocalThemePalette.current
    val title = visibleMonth.month.getDisplayName(TextStyle.FULL, locale)
        .replaceFirstChar { it.titlecase(locale) } + " ${visibleMonth.year}"
    val weekdayNames = listOf("S", "M", "T", "W", "T", "F", "S")
    val start = ((firstWeekday - 1) % 7 + 7) % 7
    val labels = (0 until 7).map { weekdayNames[(start + it) % 7] }
    val first = visibleMonth.atDay(1)
    // java.time DayOfWeek: Mon=1..Sun=7. Convert to 0=Sun..6=Sat to match labels.
    val firstDowSundayBased = first.dayOfWeek.value % 7 // Sunday=0
    val lead = (firstDowSundayBased - start + 7) % 7
    val daysInMonth = visibleMonth.lengthOfMonth()
    val cells: List<LocalDate?> = buildList {
        repeat(lead) { add(null) }
        for (d in 1..daysInMonth) add(visibleMonth.atDay(d))
        val trailing = (7 - size % 7) % 7
        repeat(trailing) { add(null) }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(RosarySpace.lg),
        verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            IconButton(
                onClick = { onShiftMonth(-1) },
                modifier = Modifier.size(48.dp).semantics { contentDescription = "Previous month" },
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = null,
                    tint = palette.ink,
                    modifier = Modifier.size(22.dp),
                )
            }
            Text(
                title,
                style = RosaryType.body,
                color = palette.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f),
            )
            IconButton(
                onClick = { onShiftMonth(1) },
                modifier = Modifier.size(48.dp).semantics { contentDescription = "Next month" },
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.ink,
                    modifier = Modifier.size(22.dp),
                )
            }
        }
        Row(modifier = Modifier.fillMaxWidth()) {
            labels.forEach { label ->
                Text(
                    label,
                    style = RosaryType.caption,
                    color = palette.dim,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f),
                )
            }
        }
        cells.chunked(7).forEach { week ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm),
            ) {
                week.forEach { date ->
                    val prayed = date != null && date in prayedDays
                    val partial = date != null && !prayed && date in partialDays
                    val isToday = date == today
                    val isFuture = date != null && date.isAfter(today)
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .heightIn(min = 32.dp)
                            .then(
                                if (date != null && !isFuture) {
                                    Modifier.clickable { onOpenDay(date) }
                                } else {
                                    Modifier
                                },
                            ),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (date != null) {
                            val marked = prayed || partial || isToday
                            Box(
                                modifier = Modifier
                                    .size(if (marked) 32.dp else 28.dp)
                                    .clip(CircleShape)
                                    .background(if (prayed) palette.accent else Color.Transparent)
                                    .then(
                                        if (partial || isToday) {
                                            Modifier.border(BorderStroke(2.dp, palette.accent), CircleShape)
                                        } else {
                                            Modifier
                                        },
                                    ),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(
                                    date.dayOfMonth.toString(),
                                    style = RosaryType.caption,
                                    color = when {
                                        prayed -> palette.onAccent
                                        isFuture -> palette.futureDayText
                                        else -> palette.ink
                                    },
                                )
                            }
                        }
                    }
                }
            }
        }
        Row(
            horizontalArrangement = Arrangement.spacedBy(RosarySpace.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            JourneyLegendDot("Completed", filled = true)
            JourneyLegendDot("Partial", filled = false)
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(palette.strokeSubtle),
        )
        Row(modifier = Modifier.fillMaxWidth()) {
            JourneyInlineStat(
                value = monthRosaries.toString(),
                label = if (monthRosaries == 1) "Rosary" else "Rosaries",
                modifier = Modifier.weight(1f),
            )
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(48.dp)
                    .background(palette.strokeSubtle),
            )
            JourneyInlineStat(
                value = monthDecadeCount.toString(),
                label = if (monthDecadeCount == 1) "Decade" else "Decades",
                modifier = Modifier.weight(1f),
            )
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(48.dp)
                    .background(palette.strokeSubtle),
            )
            JourneyInlineStat(
                value = monthDurationText,
                label = "Prayer time",
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun JourneyLegendDot(title: String, filled: Boolean) {
    val palette = LocalThemePalette.current
    Row(
        horizontalArrangement = Arrangement.spacedBy(RosarySpace.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(CircleShape)
                .then(
                    if (filled) Modifier.background(palette.accent)
                    else Modifier.border(BorderStroke(2.dp, palette.accent), CircleShape)
                ),
        )
        Text(title, style = RosaryType.caption, color = palette.dim)
    }
}

@Composable
private fun JourneyInlineStat(value: String, label: String, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(RosarySpace.xs)) {
        Text(value, style = RosaryType.body, color = palette.ink)
        Text(label, style = RosaryType.caption, color = palette.textSecondary)
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


private fun mysterySetTitle(raw: String?): String? {
    val kind = MysterySetKind.entries.find { it.name.equals(raw, ignoreCase = true) } ?: return null
    return "${kind.shortName} Mysteries"
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
