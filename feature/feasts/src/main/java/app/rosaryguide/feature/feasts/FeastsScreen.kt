package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.layout
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.calendar.FeastAgenda
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionDivider
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.SectionBand
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.MysterySetKind
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale
import kotlinx.coroutines.launch
import kotlin.math.abs

private const val WeekPageOrigin = 12
private const val WeekPageCount = 12 + 26 + 1

@Composable
fun FeastsScreen(
    onFeastClick: (DatedFeast) -> Unit,
    today: LocalDate,
    modifier: Modifier = Modifier,
    onPray: (MysterySetKind) -> Unit = {},
    firstWeekday: Int = 2,
    locale: Locale = Locale.getDefault(),
    previewForceEmpty: Boolean = false,
    initialMarian: Boolean = false,
) {
    val palette = LocalThemePalette.current
    var marianOnly by remember { mutableStateOf(initialMarian) }
    var selectedDay by remember { mutableStateOf(today) }
    var calendarExpanded by remember { mutableStateOf(false) }
    var calendarDrag by remember { mutableFloatStateOf(0f) }
    var weekOffset by remember { mutableIntStateOf(0) }
    val scope = rememberCoroutineScope()
    val pagerState = rememberPagerState(
        initialPage = WeekPageOrigin,
        pageCount = { WeekPageCount },
    )
    LaunchedEffect(pagerState.settledPage) {
        weekOffset = pagerState.settledPage - WeekPageOrigin
    }

    val feasts = remember(selectedDay, marianOnly, today, previewForceEmpty) {
        if (previewForceEmpty) emptyList()
        else datedFeasts(selectedDay, marianOnly)
    }
    val agenda = remember(feasts, selectedDay, today, firstWeekday, previewForceEmpty) {
        if (previewForceEmpty) FeastAgenda(emptyList())
        else FeastAgenda.of(feasts, selectedDay, today, firstWeekday)
    }
    val feastDays = remember(feasts) { feasts.map { it.date }.toSet() }
    val weekStart = remember(today, firstWeekday, weekOffset) {
        FeastAgenda.startOfWeek(today, firstWeekday).plusDays(weekOffset * 7L)
    }
    val monthTitle = remember(weekStart, locale) {
        weekStart.format(DateTimeFormatter.ofPattern("MMMM yyyy", locale))
    }
    val showToday = weekOffset != 0 || selectedDay != today
    val density = LocalDensity.current
    val dayRow = RosarySpace.feastCalendarDayHeight
    val expandedHeight = dayRow * RosarySpace.feastCalendarWeekCount +
        RosarySpace.xs * (RosarySpace.feastCalendarWeekCount - 1)
    val dragDp = with(density) { calendarDrag.toDp() }
    val revealedHeight = if (calendarExpanded) {
        (expandedHeight + dragDp).coerceIn(dayRow, expandedHeight)
    } else {
        (dayRow + dragDp).coerceIn(dayRow, expandedHeight)
    }

    fun goToday() {
        selectedDay = today
        weekOffset = 0
        scope.launch { pagerState.animateScrollToPage(WeekPageOrigin) }
        calendarExpanded = false
        calendarDrag = 0f
    }

    Box(modifier.fillMaxSize()) {
        AppPageBackground()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = RosarySpace.tabBarContentClearance),
        ) {
            FeastsLargeTitle()
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(top = RosarySpace.lg),
            ) {
                FeastScopeControl(
                    selectedIndex = if (marianOnly) 1 else 0,
                    onSelect = { marianOnly = it == 1 },
                )

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = RosarySpace.lg)
                        .height(RosarySpace.calendarHitTarget),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = monthTitle,
                        style = RosaryType.calendarMonthTitle,
                        color = palette.ink,
                        modifier = Modifier.weight(1f),
                    )
                    if (showToday) {
                        Text(
                            text = "Today",
                            style = RosaryType.bodyPray,
                            color = palette.actionForeground,
                            modifier = Modifier.clickable(role = Role.Button, onClick = { goToday() }),
                        )
                    }
                }

                WeekdayHeader(firstWeekday = firstWeekday, locale = locale)

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(revealedHeight)
                        .clip(androidx.compose.ui.graphics.RectangleShape),
                ) {
                    if (calendarExpanded) {
                        ExpandedWeeks(
                            weekStart = weekStart,
                            today = today,
                            selectedDay = selectedDay,
                            feastDays = feastDays,
                            onSelect = { selectedDay = it },
                        )
                    } else {
                        HorizontalPager(
                            state = pagerState,
                            modifier = Modifier.fillMaxWidth(),
                        ) { page ->
                            val start = FeastAgenda.startOfWeek(today, firstWeekday)
                                .plusDays((page - WeekPageOrigin) * 7L)
                            WeekRow(
                                weekStart = start,
                                today = today,
                                selectedDay = selectedDay,
                                feastDays = feastDays,
                                onSelect = { selectedDay = it },
                            )
                        }
                    }
                }

                CalendarHandle(
                    expanded = calendarExpanded,
                    onToggle = {
                        calendarExpanded = !calendarExpanded
                        calendarDrag = 0f
                    },
                    onDrag = { calendarDrag = it },
                    onDragEnd = { distance, projected ->
                        val threshold = with(density) { RosarySpace.calendarSnapThreshold.toPx() }
                        val expanded = if (calendarExpanded) {
                            !(distance < -threshold || projected < -threshold)
                        } else {
                            distance > threshold || projected > threshold
                        }
                        calendarExpanded = expanded
                        calendarDrag = 0f
                    },
                )

                GuideSectionDivider(
                    modifier = Modifier
                        .padding(top = RosarySpace.calendarHandleDividerGap)
                        .padding(bottom = RosarySpace.md)
                        .layoutExpandToBleed(),
                )

                if (agenda.sections.isEmpty()) {
                    Text(
                        text = "No upcoming feasts for this selection.",
                        style = RosaryType.bodyPray,
                        color = palette.dim,
                    )
                } else {
                    agenda.sections.forEachIndexed { index, section ->
                        if (index > 0) {
                            SectionBand(fullBleed = true)
                        }
                        AgendaSection(
                            section = section,
                            locale = locale,
                            onFeastClick = onFeastClick,
                        )
                        val primary = section.items.firstOrNull()
                        if (index == 0 && primary != null && primary.date == selectedDay) {
                            FeastActionRow(
                                item = primary,
                                onLearn = { onFeastClick(primary) },
                                onPray = {
                                    onPray(
                                        primary.feast.suggestedMysterySet
                                            ?: MysteryCalendar.assignment(primary.date).set,
                                    )
                                },
                                modifier = Modifier.padding(top = RosarySpace.lg),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun FeastsLargeTitle() {
    val palette = LocalThemePalette.current
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
        Text("Feasts", style = title, color = palette.ink)
    }
}

@Composable
private fun FeastScopeControl(
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
) {
    val palette = LocalThemePalette.current
    val options = listOf("All feasts", "Marian feasts")
    val track = if (palette.isDark) Color(0xFF2C2C2E) else palette.cardSurface(PageStyle.Plain)
    val thumb = palette.emphasisSegmentThumb
    val cap = RoundedCornerShape(percent = 50)
    val index = selectedIndex.coerceIn(0, options.lastIndex)
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
                .padding(start = inset + thumbWidth * index, top = inset, bottom = inset)
                .width(thumbWidth)
                .height(40.dp)
                .shadow(1.5.dp, cap, clip = false)
                .background(thumb, cap),
        )
        Row(
            Modifier
                .fillMaxWidth()
                .fillMaxHeight(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            options.forEachIndexed { i, option ->
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable { onSelect(i) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = option,
                        style = RosaryType.segmentedControlPray,
                        color = if (i == index) palette.emphasisSegmentTitle else palette.dim,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

@Composable
private fun WeekdayHeader(firstWeekday: Int, locale: Locale) {
    val palette = LocalThemePalette.current
    val labels = remember(firstWeekday) {
        val start = java.time.DayOfWeek.SUNDAY.plus((firstWeekday - 1).toLong())
        (0..6).map { iosVeryShortWeekday(start.plus(it.toLong())) }
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = RosarySpace.sm)
            .height(RosarySpace.calendarWeekdayHeaderHeight),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        labels.forEach { label ->
            Text(
                text = label,
                style = RosaryType.captionPray,
                color = palette.dim,
                modifier = Modifier.weight(1f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
        }
    }
}

@Composable
private fun WeekRow(
    weekStart: LocalDate,
    today: LocalDate,
    selectedDay: LocalDate,
    feastDays: Set<LocalDate>,
    onSelect: (LocalDate) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(RosarySpace.feastCalendarDayHeight),
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.xs),
    ) {
        (0..6).forEach { column ->
            val day = weekStart.plusDays(column.toLong())
            DayButton(
                day = day,
                today = today,
                selected = day == selectedDay,
                hasFeast = day in feastDays,
                onSelect = { onSelect(day) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun ExpandedWeeks(
    weekStart: LocalDate,
    today: LocalDate,
    selectedDay: LocalDate,
    feastDays: Set<LocalDate>,
    onSelect: (LocalDate) -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.xs),
    ) {
        repeat(RosarySpace.feastCalendarWeekCount) { row ->
            WeekRow(
                weekStart = weekStart.plusDays(row * 7L),
                today = today,
                selectedDay = selectedDay,
                feastDays = feastDays,
                onSelect = onSelect,
            )
        }
    }
}

@Composable
private fun DayButton(
    day: LocalDate,
    today: LocalDate,
    selected: Boolean,
    hasFeast: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val isToday = day == today
    Column(
        modifier = modifier
            .fillMaxHeight()
            .clickable(role = Role.Button, onClick = onSelect),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.xs),
    ) {
        Box(
            modifier = Modifier
                .size(RosarySpace.calendarHitTarget)
                .background(if (selected) palette.accent else Color.Transparent, CircleShape)
                .then(
                    if (isToday && !selected) {
                        Modifier.border(1.dp, palette.accent, CircleShape)
                    } else {
                        Modifier
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = day.dayOfMonth.toString(),
                style = RosaryType.calendarDay,
                color = if (selected) palette.onAccent else palette.ink,
            )
        }
        Box(
            modifier = Modifier
                .size(4.dp)
                .background(if (hasFeast) palette.accent else Color.Transparent, CircleShape),
        )
    }
}

@Composable
private fun CalendarHandle(
    expanded: Boolean,
    onToggle: () -> Unit,
    onDrag: (Float) -> Unit,
    onDragEnd: (distance: Float, projected: Float) -> Unit,
) {
    val palette = LocalThemePalette.current
    var accumulated by remember { mutableFloatStateOf(0f) }
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = RosarySpace.calendarHandleDotGap)
            .height(RosarySpace.calendarHandleHeight)
            .clickable(role = Role.Button, onClick = onToggle)
            .pointerInput(expanded) {
                detectVerticalDragGestures(
                    onDragStart = { accumulated = 0f },
                    onVerticalDrag = { _, amount ->
                        accumulated += amount
                        onDrag(accumulated)
                    },
                    onDragEnd = { onDragEnd(accumulated, accumulated) },
                    onDragCancel = { onDrag(0f) },
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .width(RosarySpace.calendarHandleWidth)
                .height(RosarySpace.calendarHandleHeight)
                .clip(RoundedCornerShape(percent = 50))
                .background(palette.dim),
        )
    }
}

@Composable
private fun AgendaSection(
    section: FeastAgenda.Section,
    locale: Locale,
    onFeastClick: (DatedFeast) -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        if (section.title.isNotEmpty()) {
            GuideSectionLabel(
                text = section.title,
                strong = true,
                style = RosaryType.bodyPray,
                modifier = Modifier.padding(bottom = RosarySpace.sectionTitleGap - RosarySpace.xs),
            )
        } else {
            Spacer(Modifier.height(RosarySpace.sectionTitleGap))
        }
        section.items.forEachIndexed { index, item ->
            FeastTimelineRow(
                item = item,
                locale = locale,
                topPadding = if (index == 0) 0.dp else 14.dp,
                bottomPadding = if (index == section.items.lastIndex) 0.dp else 14.dp,
                onClick = { onFeastClick(item) },
            )
            if (index < section.items.lastIndex) {
                HorizontalDivider(
                    modifier = Modifier.padding(start = RosarySpace.feastDateColumnWidth + 20.dp),
                    thickness = Hairline.thickness,
                    color = LocalThemePalette.current.hair,
                )
            }
        }
    }
}

@Composable
private fun FeastTimelineRow(
    item: DatedFeast,
    locale: Locale,
    topPadding: androidx.compose.ui.unit.Dp,
    bottomPadding: androidx.compose.ui.unit.Dp,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    val month = item.date.format(DateTimeFormatter.ofPattern("MMM", locale)).uppercase(locale)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(top = topPadding, bottom = bottomPadding),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(20.dp),
    ) {
        Column(
            modifier = Modifier.width(RosarySpace.feastDateColumnWidth),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = item.date.dayOfMonth.toString(),
                style = RosaryType.calendarDateNumber,
                color = palette.ink,
            )
            Text(
                text = month,
                style = RosaryType.calendarMonthAbbrev,
                color = palette.dim,
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.feast.shortTitle,
                style = RosaryType.feastTimelineTitle,
                color = palette.ink,
                maxLines = 2,
            )
            Spacer(Modifier.height(RosarySpace.xs))
            Text(
                text = item.feast.rank.title,
                style = RosaryType.captionPray,
                color = palette.dim,
            )
        }
    }
}

@Composable
private fun FeastActionRow(
    item: DatedFeast,
    onLearn: () -> Unit,
    onPray: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(RosarySpace.md),
    ) {
        GuideSecondaryButton(
            title = "Learn",
            onClick = onLearn,
            modifier = Modifier.weight(1f),
        )
        GuidePrimaryButton(
            title = "Pray this Rosary",
            onClick = onPray,
            modifier = Modifier.weight(1f),
        )
    }
}

private fun datedFeasts(selectedDay: LocalDate, marianOnly: Boolean): List<DatedFeast> {
    val year = selectedDay.year
    val all = (year..(year + 1)).flatMap { FeastCatalog.dated(it) }
    return if (marianOnly) all.filter { it.feast.isMarian } else all
}

/** Expand past a parent that already applied the 16 dp gutter, matching iOS `-gutter`. */
private fun Modifier.layoutExpandToBleed(): Modifier {
    val gutter = RosarySpace.gutter
    return this.layout { measurable, constraints ->
        val gutterPx = gutter.roundToPx()
        val width = constraints.maxWidth + gutterPx * 2
        val placeable = measurable.measure(
            constraints.copy(minWidth = width, maxWidth = width),
        )
        layout(constraints.maxWidth, placeable.height) {
            placeable.place(-gutterPx, 0)
        }
    }
}


/** iOS `Calendar.veryShortStandaloneWeekdaySymbols` as shown on the Feasts ref (en). */
private fun iosVeryShortWeekday(day: java.time.DayOfWeek): String = when (day) {
    java.time.DayOfWeek.MONDAY -> "M"
    java.time.DayOfWeek.TUESDAY -> "Tu"
    java.time.DayOfWeek.WEDNESDAY -> "W"
    java.time.DayOfWeek.THURSDAY -> "Th"
    java.time.DayOfWeek.FRIDAY -> "F"
    java.time.DayOfWeek.SATURDAY -> "Sa"
    java.time.DayOfWeek.SUNDAY -> "Su"
}
