package app.rosaryguide.feature.today

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.art.FeastCoverMath
import app.rosaryguide.core.data.art.FeastSubjects
import app.rosaryguide.core.data.art.SizeF
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.data.calendar.WeekStart
import app.rosaryguide.core.data.art.ArtCatalog
import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.data.catalog.HomeCopy
import app.rosaryguide.core.data.catalog.resolvedTagline
import app.rosaryguide.core.data.notify.NotificationPrompt
import app.rosaryguide.core.designsystem.component.CroppedArt
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideScreenHeader
import app.rosaryguide.core.designsystem.component.GuideSectionDivider
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.drawableIdByName
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun TodayScreen(
    onViewAllFeasts: () -> Unit,
    onFeastClick: (DatedFeast) -> Unit,
    onPray: (app.rosaryguide.core.model.MysterySetKind) -> Unit,
    modifier: Modifier = Modifier,
    today: LocalDate = LocalDate.now(),
    hasAskedForNotifications: Boolean = true,
    onAskedForNotifications: () -> Unit = {},
) {
    val palette = LocalThemePalette.current
    val firstWeekday = WeekStart.firstWeekday()
    var selected by remember(today) { mutableStateOf(today) }
    val assignment = remember(selected) { MysteryCalendar.assignment(selected) }
    val week = remember(today, firstWeekday) { MysteryCalendar.week(today, firstWeekday) }
    val upcoming = remember(today) { FeastCatalog.upcoming(today, limit = 8) }
    val featured = upcoming.firstOrNull()
    val rest = if (featured == null) emptyList() else upcoming.drop(1).take(2)
    val isToday = selected == today

    NotificationPermissionEffect(
        hasAsked = hasAskedForNotifications,
        onAsked = onAskedForNotifications,
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xxl),
    ) {
        GuideScreenHeader(
            title = "Today",
            modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg),
        )

        WeekStrip(
            days = week.map { it.first },
            today = today,
            selected = selected,
            onSelect = { selected = it },
            modifier = Modifier.padding(bottom = RosarySpace.lg),
        )

        MysteryCard(
            setName = assignment.set.shortName,
            reason = assignment.reason,
            heroName = ArtCatalog.heroName(assignment.set),
            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
        )

        Spacer(Modifier.height(RosarySpace.md))
        GuidePrimaryButton(
            title = if (isToday) HomeCopy.PRAY_TODAYS_MYSTERIES else HomeCopy.prayTheMysteries(assignment.set),
            onClick = { onPray(assignment.set) },
            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
        )

        Spacer(Modifier.height(RosarySpace.xl))
        GuideSectionDivider(Modifier.padding(horizontal = RosarySpace.gutter))
        Spacer(Modifier.height(RosarySpace.xl))

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            GuideSectionLabel(text = HomeCopy.UPCOMING_FEAST_DAYS, modifier = Modifier)
            Text(
                text = HomeCopy.VIEW_ALL_FEASTS,
                style = RosaryType.caption,
                color = palette.accentText,
                modifier = Modifier.clickable(onClick = onViewAllFeasts),
            )
        }

        if (featured != null) {
            FeaturedFeastCard(
                item = featured,
                today = today,
                onClick = { onFeastClick(featured) },
                modifier = Modifier.padding(horizontal = RosarySpace.gutter),
            )
            Spacer(Modifier.height(RosarySpace.sm))
        }
        rest.forEach { item ->
            FeastRow(
                item = item,
                onClick = { onFeastClick(item) },
                modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.xs),
            )
        }

        Spacer(Modifier.height(RosarySpace.xl))
        GuideSectionLabel(
            text = HomeCopy.THIS_WEEK,
            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
        )
        week.forEach { (date, dayAssignment) ->
            val feastToday = FeastCatalog.feasts(date).firstOrNull()
            WeekFeastRow(
                date = date,
                isToday = date == today,
                mysteryLetter = dayAssignment.set.letter,
                feastName = feastToday?.feast?.shortTitle,
                onClick = {
                    if (feastToday != null) onFeastClick(feastToday) else selected = date
                },
                modifier = Modifier.padding(horizontal = RosarySpace.gutter),
            )
        }
    }
}

@Composable
private fun NotificationPermissionEffect(
    hasAsked: Boolean,
    onAsked: () -> Unit,
) {
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { onAsked() }
    LaunchedEffect(hasAsked) {
        if (!NotificationPrompt.shouldPrompt(hasAsked = hasAsked, systemPermissionDetermined = false)) {
            return@LaunchedEffect
        }
        delay(NotificationPrompt.HOME_ARRIVAL_DELAY_MS)
        if (Build.VERSION.SDK_INT >= 33) {
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            onAsked()
        }
    }
}

@Composable
private fun WeekStrip(
    days: List<LocalDate>,
    today: LocalDate,
    selected: LocalDate,
    onSelect: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val dayFmt = DateTimeFormatter.ofPattern("EE", Locale.getDefault())
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        days.forEach { date ->
            val isToday = date == today
            val isSelected = date == selected
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (isSelected) palette.surface else androidx.compose.ui.graphics.Color.Transparent)
                    .clickable { onSelect(date) }
                    .padding(horizontal = 8.dp, vertical = 8.dp)
                    .width(52.dp),
            ) {
                Text(
                    text = date.format(dayFmt).uppercase(Locale.getDefault()),
                    style = RosaryType.caption,
                    color = if (isSelected) palette.ink else palette.dim,
                )
                Text(
                    text = date.dayOfMonth.toString(),
                    style = RosaryType.body.copy(fontWeight = FontWeight.Medium),
                    color = palette.ink,
                )
                if (isToday) {
                    Spacer(Modifier.height(4.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(palette.todayPillFill)
                            .border(1.dp, palette.strokeRegular, RoundedCornerShape(8.dp))
                            .padding(horizontal = 6.dp, vertical = 1.dp),
                    ) {
                        Text(
                            text = HomeCopy.TODAY_PILL,
                            style = RosaryType.caption.copy(fontWeight = FontWeight.Medium),
                            color = palette.todayPillText,
                            maxLines = 1,
                            softWrap = false,
                        )
                    }
                } else {
                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }
}

@Composable
private fun MysteryCard(
    setName: String,
    reason: String,
    heroName: String,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = drawableIdByName(context, heroName)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.featureRadius))
            .background(palette.cardSurface(PageStyle.Plain)),
    ) {
        if (resId != 0) {
            Image(
                painter = painterResource(resId),
                contentDescription = setName,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(176.dp),
            )
        }
        Column(Modifier.padding(RosarySpace.lg)) {
            Text(text = "$setName Mysteries", style = RosaryType.headingCard, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = reason, style = RosaryType.supportingLabel, color = palette.dim)
        }
    }
}

@Composable
private fun FeaturedFeastCard(
    item: DatedFeast,
    today: LocalDate,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = feastHeroDrawableId(context, item.feast.id)
    val dateLabel = if (item.date == today) {
        "TODAY"
    } else {
        "Next · ${item.date.format(DateTimeFormatter.ofPattern("d MMMM", Locale.getDefault()))}".uppercase(Locale.getDefault())
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.featureRadius))
            .background(palette.cardSurface(PageStyle.Plain))
            .clickable(onClick = onClick),
    ) {
        if (resId != 0) {
            val subject = FeastSubjects.ofFeastId(item.feast.id)
            if (subject != null) {
                CroppedArt(
                    painter = painterResource(resId),
                    coverForFrame = { frameW, frameH ->
                        val cover = FeastCoverMath.feastCover(
                            imageSize = SizeF(1280f, 720f),
                            frame = SizeF(frameW, frameH),
                            subject = subject,
                            focusX = subject.focusX,
                        )
                        Triple(cover.scale, cover.offsetX, cover.offsetY)
                    },
                    contentDescription = item.feast.shortTitle,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(176.dp),
                )
            } else {
                Image(
                    painter = painterResource(resId),
                    contentDescription = item.feast.shortTitle,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(176.dp),
                )
            }
        }
        Column(Modifier.padding(RosarySpace.lg)) {
            Text(text = dateLabel, style = RosaryType.caption, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = item.feast.shortTitle, style = RosaryType.headingCard, color = palette.ink)
            val tagline = item.feast.resolvedTagline
            if (tagline.isNotBlank()) {
                Spacer(Modifier.height(RosarySpace.xs))
                Text(text = tagline, style = RosaryType.supportingLabel, color = palette.dim)
            }
        }
    }
}

@Composable
private fun FeastRow(
    item: DatedFeast,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val date = item.date.format(DateTimeFormatter.ofPattern("d MMM", Locale.getDefault()))
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.nestedRadius))
            .clickable(onClick = onClick)
            .padding(vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = date, style = RosaryType.supportingLabel, color = palette.dim, modifier = Modifier.width(72.dp))
        Text(text = item.feast.shortTitle, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun WeekFeastRow(
    date: LocalDate,
    isToday: Boolean,
    mysteryLetter: String,
    feastName: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val day = date.format(DateTimeFormatter.ofPattern("EEE d", Locale.getDefault()))
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = day, style = RosaryType.supportingLabel, color = if (isToday) palette.ink else palette.dim, modifier = Modifier.width(80.dp))
        Box(
            modifier = Modifier
                .size(22.dp)
                .clip(CircleShape)
                .background(palette.mysteryIconFill),
            contentAlignment = Alignment.Center,
        ) {
            Text(text = mysteryLetter, style = RosaryType.caption, color = palette.mysteryIconGlyph)
        }
        Spacer(Modifier.width(RosarySpace.sm))
        Text(
            text = feastName ?: "",
            style = RosaryType.body,
            color = palette.ink,
            modifier = Modifier.weight(1f),
        )
    }
}

