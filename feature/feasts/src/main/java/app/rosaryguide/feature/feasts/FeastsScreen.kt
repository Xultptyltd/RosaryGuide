package app.rosaryguide.feature.feasts

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.calendar.FeastAgenda
import app.rosaryguide.core.data.calendar.WeekStart
import app.rosaryguide.core.data.calendar.FeastMonthLayout
import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.data.search.localizedStandardContains
import app.rosaryguide.core.designsystem.component.GuideMarqueeText
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun FeastsScreen(
    onFeastClick: (DatedFeast) -> Unit,
    modifier: Modifier = Modifier,
    today: LocalDate = LocalDate.now(),
    initialFeastId: String? = null,
) {
    val palette = LocalThemePalette.current
    val firstWeekday = WeekStart.firstWeekday()
    var month by remember(today) { mutableStateOf(today.withDayOfMonth(1)) }
    var selected by remember(today, initialFeastId) {
        mutableStateOf(today)
    }
    var query by remember { mutableStateOf("") }

    val items = remember(today) {
        val year = today.year
        (FeastCatalog.dated(year) + FeastCatalog.dated(year + 1))
            .sortedWith(compareBy<DatedFeast> { it.date }.thenBy { it.id })
    }
    val layout = remember(month, firstWeekday) { FeastMonthLayout.of(month, firstWeekday) }
    val agenda = remember(items, selected, today, firstWeekday) {
        FeastAgenda.of(items, selectedDay = selected, today = today, firstWeekday = firstWeekday)
    }
    val feastDays = remember(items, month) {
        items.filter { it.date.year == month.year && it.date.month == month.month }.map { it.date }.toSet()
    }
    val results = if (query.trim().isEmpty()) emptyList() else FeastCatalog.searchResults(query, today)
    val monthTitle = month.format(DateTimeFormatter.ofPattern("MMMM yyyy", Locale.getDefault()))
    val weekdayLabels = weekdayHeaders(firstWeekday)

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        Column(Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg)) {
            GuideMarqueeText(text = monthTitle, style = RosaryType.headingPrimary)
            Spacer(Modifier.height(RosarySpace.md))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    text = "Previous",
                    style = RosaryType.caption,
                    color = palette.accentText,
                    modifier = Modifier.clickable { month = month.minusMonths(1) },
                )
                Text(
                    text = "Today",
                    style = RosaryType.caption,
                    color = palette.accentText,
                    modifier = Modifier.clickable {
                        month = today.withDayOfMonth(1)
                        selected = today
                    },
                )
                Text(
                    text = "Next",
                    style = RosaryType.caption,
                    color = palette.accentText,
                    modifier = Modifier.clickable { month = month.plusMonths(1) },
                )
            }
            Spacer(Modifier.height(RosarySpace.md))
            BasicTextField(
                value = query,
                onValueChange = { query = it },
                singleLine = true,
                textStyle = RosaryType.body.copy(color = palette.ink),
                cursorBrush = SolidColor(palette.accent),
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(RosarySpace.containerRadius))
                    .background(palette.surface)
                    .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
                decorationBox = { inner ->
                    if (query.isEmpty()) {
                        Text(text = "Search feasts", style = RosaryType.body, color = palette.dim)
                    }
                    inner()
                },
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            if (query.trim().isNotEmpty()) {
                if (results.isEmpty()) {
                    Text(text = "Nothing can be found. Try another search", style = RosaryType.body, color = palette.dim)
                } else {
                    results.forEach { item ->
                        AgendaRow(item, onFeastClick)
                    }
                }
            } else {
                Row(Modifier.fillMaxWidth()) {
                    weekdayLabels.forEach { label ->
                        Text(
                            text = label,
                            style = RosaryType.caption,
                            color = palette.dim,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
                Spacer(Modifier.height(RosarySpace.xs))
                layout.cells.chunked(7).forEach { week ->
                    Row(Modifier.fillMaxWidth()) {
                        week.forEach { date ->
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .aspectRatio(1f)
                                    .clickable(enabled = date != null) {
                                        date?.let {
                                            selected = it
                                        }
                                    },
                                contentAlignment = Alignment.Center,
                            ) {
                                if (date != null) {
                                    val isSelected = date == selected
                                    val isToday = date == today
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .clip(CircleShape)
                                                .background(
                                                    when {
                                                        isSelected -> palette.ink
                                                        isToday -> palette.accentTint
                                                        else -> androidx.compose.ui.graphics.Color.Transparent
                                                    },
                                                ),
                                            contentAlignment = Alignment.Center,
                                        ) {
                                            Text(
                                                text = date.dayOfMonth.toString(),
                                                style = RosaryType.body.copy(
                                                    fontWeight = if (isToday || isSelected) FontWeight.Medium else FontWeight.Normal,
                                                ),
                                                color = if (isSelected) palette.bg else palette.ink,
                                            )
                                        }
                                        if (date in feastDays) {
                                            Box(
                                                modifier = Modifier
                                                    .padding(top = 2.dp)
                                                    .size(4.dp)
                                                    .clip(CircleShape)
                                                    .background(palette.feastIndicator),
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer(Modifier.height(RosarySpace.lg))
                agenda.sections.forEach { section ->
                    if (section.title.isNotBlank()) {
                        Text(
                            text = section.title,
                            style = RosaryType.supportingLabel,
                            color = palette.dim,
                            modifier = Modifier.padding(top = RosarySpace.md, bottom = RosarySpace.xs),
                        )
                    }
                    section.items.forEach { item ->
                        AgendaRow(item, onFeastClick)
                    }
                }
            }
        }
    }
}

@Composable
private fun AgendaRow(item: DatedFeast, onClick: (DatedFeast) -> Unit) {
    val palette = LocalThemePalette.current
    val date = item.date.format(DateTimeFormatter.ofPattern("d MMM", Locale.getDefault()))
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick(item) }
            .padding(vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(Modifier.weight(1f)) {
            Text(text = item.feast.shortTitle, style = RosaryType.body, color = palette.ink)
            Text(text = item.feast.rank.title, style = RosaryType.caption, color = palette.dim)
        }
        Text(text = date, style = RosaryType.supportingLabel, color = palette.dim)
    }
}


private fun weekdayHeaders(firstWeekday: Int): List<String> {
    val names = listOf("S", "M", "T", "W", "T", "F", "S") // Sunday-first
    val start = firstWeekday - 1
    return (0 until 7).map { names[(start + it) % 7] }
}
