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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
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
    resumableCta: String? = null,
    prayedDayKeys: Set<String> = emptySet(),
    hasAskedForNotifications: Boolean = true,
    onAskedForNotifications: () -> Unit = {},
    onOpenSettings: () -> Unit = {},
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
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            GuideScreenHeader(title = "Today", modifier = Modifier.weight(1f))
            IconButton(onClick = onOpenSettings) {
                Icon(Icons.Filled.Settings, contentDescription = "Settings", tint = palette.ink)
            }
        }

        MysteryCard(
            setName = assignment.set.shortName,
            reason = assignment.reason,
            heroName = ArtCatalog.heroName(assignment.set),
            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
        )

        Spacer(Modifier.height(RosarySpace.md))
        GuidePrimaryButton(
            title = when {
                isToday && resumableCta != null -> resumableCta
                isToday -> HomeCopy.PRAY_TODAYS_MYSTERIES
                else -> HomeCopy.prayTheMysteries(assignment.set)
            },
            onClick = { onPray(assignment.set) },
            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
        )

        Spacer(Modifier.height(RosarySpace.xl))
        GuideSectionDivider(Modifier.padding(horizontal = RosarySpace.gutter))
        Spacer(Modifier.height(RosarySpace.xl))

        val ax = isAccessibilitySize()
        if (ax) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter),
            ) {
                GuideSectionLabel(text = HomeCopy.UPCOMING_FEAST_DAYS)
                Text(
                    text = HomeCopy.VIEW_ALL_FEASTS,
                    style = RosaryType.caption,
                    color = palette.accentText,
                    modifier = Modifier
                        .clickable(onClick = onViewAllFeasts)
                        .padding(vertical = RosarySpace.sm),
                )
            }
        } else {
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
                modifier = Modifier
                    .clickable(onClick = onViewAllFeasts)
                    .padding(vertical = RosarySpace.sm),
            )
        }
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
        week.forEachIndexed { index, (date, dayAssignment) ->
            val isTodayRow = date == today
            val nextIsToday = index < week.lastIndex && week[index + 1].first == today
            WeekGlanceRow(
                date = date,
                assignment = dayAssignment,
                isToday = isTodayRow,
                prayed = date.toString() in prayedDayKeys,
                onClick = { selected = date },
                modifier = Modifier.padding(horizontal = RosarySpace.gutter),
            )
            if (index < week.lastIndex && !isTodayRow && !nextIsToday) {
                androidx.compose.material3.HorizontalDivider(
                    modifier = Modifier.padding(horizontal = RosarySpace.gutter),
                    color = palette.strokeSubtle,
                    thickness = 1.dp,
                )
            }
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
    val ax = isAccessibilitySize()
    val rowMod = modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(RosarySpace.nestedRadius))
        .clickable(onClick = onClick)
        .padding(vertical = RosarySpace.sm)
    if (ax) {
        Column(modifier = rowMod) {
            Text(text = date, style = RosaryType.supportingLabel, color = palette.dim)
            Text(text = item.feast.shortTitle, style = RosaryType.body, color = palette.ink)
        }
    } else {
    Row(
        modifier = rowMod,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = date, style = RosaryType.supportingLabel, color = palette.dim, modifier = Modifier.width(72.dp))
        Text(text = item.feast.shortTitle, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
    }
    }
}


@Composable
private fun WeekGlanceRow(
    date: java.time.LocalDate,
    assignment: app.rosaryguide.core.model.MysteryAssignment,
    isToday: Boolean,
    prayed: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val weekday = date.format(java.time.format.DateTimeFormatter.ofPattern("EEE", java.util.Locale.getDefault()))
    val dayMonth = date.format(java.time.format.DateTimeFormatter.ofPattern("d MMM", java.util.Locale.getDefault()))
    val shape = RoundedCornerShape(RosarySpace.md)
    val ax = isAccessibilitySize()
    val feastTitle = assignment.feast?.feast?.shortTitle
    val description = buildString {
        append(weekday)
        append(", ")
        append(dayMonth)
        append(", ")
        append(assignment.set.shortName)
        if (feastTitle != null) {
            append(", ")
            append(feastTitle)
        }
        if (prayed) append(", prayed")
        if (isToday) append(", today")
    }
    val rowMod = modifier
        .fillMaxWidth()
        .then(
            if (isToday) Modifier
                .background(
                    if (palette.isDark) palette.ink.copy(alpha = 0.07f) else palette.surface,
                    shape,
                )
                .padding(horizontal = RosarySpace.md)
            else Modifier
        )
        .clickable(onClick = onClick)
        .semantics { contentDescription = description }
        .padding(vertical = RosarySpace.md)
    if (ax) {
        Column(modifier = rowMod) {
            Text(text = "$weekday  $dayMonth", style = RosaryType.body, color = palette.ink)
            feastTitle?.let { Text(text = it, style = RosaryType.caption, color = palette.dim) }
            Text(
                text = assignment.set.shortName + if (prayed) "  ✓" else "",
                style = RosaryType.body,
                color = if (isToday) palette.ink else palette.dim,
            )
        }
    } else {
    Row(
        modifier = rowMod,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = weekday,
            style = RosaryType.body,
            color = palette.ink,
            modifier = Modifier.width(44.dp),
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = dayMonth,
                style = RosaryType.supportingLabel,
                color = if (isToday) palette.ink else palette.dim,
            )
            feastTitle?.let { feast ->
                Text(text = feast, style = RosaryType.caption, color = palette.dim)
            }
        }
        Text(
            text = assignment.set.shortName,
            style = RosaryType.body,
            color = if (isToday) palette.ink else palette.dim,
        )
        Spacer(Modifier.width(RosarySpace.sm))
        Text(
            text = "✓",
            style = RosaryType.body,
            color = palette.accent.copy(alpha = if (prayed) 1f else 0f),
            modifier = Modifier.width(22.dp),
        )
    }
    }
}
