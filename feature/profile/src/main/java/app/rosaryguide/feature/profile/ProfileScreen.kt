package app.rosaryguide.feature.profile

import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.calendar.WeekStart
import app.rosaryguide.core.data.journey.JourneyDayDetail
import app.rosaryguide.core.data.journey.PopeIntentionCatalog
import app.rosaryguide.core.data.journey.PopeMonthIntention
import app.rosaryguide.core.data.session.IntentionPrivacy
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.component.GuideLargeTopAppBar
import app.rosaryguide.core.designsystem.component.GuideOutlineButton
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.guideHeading
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale

enum class ProfileDestination {
    Root, AllIntentions, Editor, Detail, Archived, Journey, Papal,
}

data class ProfileLaunch(
    val openJourney: Boolean = false,
    val journeyHistory: Boolean = false,
    val openAllIntentions: Boolean = false,
    val openEditor: Boolean = false,
    val openArchived: Boolean = false,
    val historyDay: LocalDate? = null,
    val sampleIntentions: Boolean = false,
    val sampleHistory: Boolean = false,
    val openPapal: Boolean = false,
)

@Composable
fun ProfileScreen(
    sessionStore: SessionStore,
    today: LocalDate = LocalDate.now(),
    zone: ZoneId = ZoneId.of("Australia/Perth"),
    locale: Locale = Locale.forLanguageTag("en-AU"),
    firstWeekday: Int = WeekStart.firstWeekday(locale),
    isSignedIn: Boolean = false,
    onPrayWith: (OfferIntention) -> Unit = {},
    onSignIn: () -> Unit = {},
    onOpenSettings: () -> Unit = {},
    launch: ProfileLaunch = ProfileLaunch(),
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val intentions by sessionStore.intentions.collectAsState()
    val completed by sessionStore.completedSessions.collectAsState()
    val dayKeys by sessionStore.completedDayKeys.collectAsState()
    val journey by sessionStore.journey.collectAsState()

    LaunchedEffect(launch.sampleIntentions, launch.sampleHistory) {
        if (launch.sampleIntentions && sessionStore.activeIntentions.isEmpty()) {
            sessionStore.addIntention("For Mum", category = app.rosaryguide.core.data.session.IntentionCategory.Someone, emoji = "💙", pin = true)
            sessionStore.addIntention("Peace in the world", category = app.rosaryguide.core.data.session.IntentionCategory.World, emoji = "🌍")
            sessionStore.addIntention("My family", category = app.rosaryguide.core.data.session.IntentionCategory.Personal, emoji = "🙏")
        }
        if (launch.sampleHistory && sessionStore.completed.isEmpty()) {
            seedSampleHistory(sessionStore, today, zone)
        }
    }

    var destination by remember {
        mutableStateOf(
            when {
                launch.openEditor -> ProfileDestination.Editor
                launch.openAllIntentions -> ProfileDestination.AllIntentions
                launch.openArchived -> ProfileDestination.Archived
                launch.openJourney -> ProfileDestination.Journey
                launch.openPapal -> ProfileDestination.Papal
                else -> ProfileDestination.Root
            },
        )
    }
    var editing by remember { mutableStateOf<OfferIntention?>(null) }
    var detail by remember { mutableStateOf<OfferIntention?>(null) }
    var journeyHistoryTab by remember { mutableStateOf(launch.journeyHistory) }
    var historyDay by remember { mutableStateOf(launch.historyDay) }

    val active = intentions.filter { !it.isArchived }
    val archived = intentions.filter { it.isArchived }
    val hidden = journey.hideIntentionText
    val pope = remember(today) { PopeIntentionCatalog.intention(today) }
    val rhythm = remember(dayKeys, today, firstWeekday) {
        sessionStore.rhythm(
            nowEpochMs = today.atTime(12, 0).atZone(zone).toInstant().toEpochMilli(),
            firstWeekday = firstWeekday,
            locale = locale,
        )
    }
    val milestones = remember(completed, dayKeys, journey, intentions) { sessionStore.journeyMilestones() }

    when (destination) {
        ProfileDestination.Root -> ProfileHome(
            rhythm = rhythm,
            milestones = milestones,
            active = active,
            archivedCount = archived.size,
            hidden = hidden,
            pope = pope,
            isSignedIn = isSignedIn,
            onOpenSettings = onOpenSettings,
            onOpenPapal = { destination = ProfileDestination.Papal },
            onOpenRhythm = { journeyHistoryTab = false; destination = ProfileDestination.Journey },
            onOpenJourney = { journeyHistoryTab = false; destination = ProfileDestination.Journey },
            onAdd = { editing = null; destination = ProfileDestination.Editor },
            onOpenAll = { destination = ProfileDestination.AllIntentions },
            onOpenArchived = { destination = ProfileDestination.Archived },
            onOpenDetail = { detail = it; destination = ProfileDestination.Detail },
            onEdit = { editing = it; destination = ProfileDestination.Editor },
            onPin = { sessionStore.setPinned(it.id, !it.isPinned) },
            onDelete = { sessionStore.removeIntention(it.id) },
            onPray = onPrayWith,
            onSignIn = onSignIn,
            onToggleHide = { sessionStore.setHideIntentionText(!hidden) },
            modifier = modifier,
        )
        ProfileDestination.AllIntentions -> AllIntentionsScreen(
            intentions = active,
            archivedCount = archived.size,
            hidden = hidden,
            onBack = { destination = ProfileDestination.Root },
            onAdd = { editing = null; destination = ProfileDestination.Editor },
            onOpenArchived = { destination = ProfileDestination.Archived },
            onOpenDetail = { detail = it; destination = ProfileDestination.Detail },
            onEdit = { editing = it; destination = ProfileDestination.Editor },
            onPin = { sessionStore.setPinned(it.id, !it.isPinned) },
            onDelete = { sessionStore.removeIntention(it.id) },
            onPray = onPrayWith,
            onToggleHide = { sessionStore.setHideIntentionText(!hidden) },
            modifier = modifier,
        )
        ProfileDestination.Editor -> IntentionEditorScreen(
            existing = editing,
            onBack = { destination = if (editing != null && detail?.id == editing?.id) ProfileDestination.Detail else ProfileDestination.Root },
            onSave = { draft ->
                if (editing == null) sessionStore.addIntention(
                    title = draft.title,
                    note = draft.note,
                    category = draft.category,
                    accent = draft.accent,
                    emoji = draft.emoji,
                    pin = draft.isPinned,
                ) else sessionStore.updateIntention(draft)
                destination = ProfileDestination.Root
            },
            modifier = modifier,
        )
        ProfileDestination.Detail -> {
            val item = detail
            if (item == null) destination = ProfileDestination.Root
            else IntentionDetailScreen(
                intention = item,
                hidden = hidden,
                onBack = { destination = ProfileDestination.Root },
                onEdit = { editing = item; destination = ProfileDestination.Editor },
                onPray = { onPrayWith(item) },
                onPin = { sessionStore.setPinned(item.id, !item.isPinned); detail = item.copy(isPinned = !item.isPinned) },
                onArchive = { sessionStore.archiveIntention(item.id); destination = ProfileDestination.Root },
                onDelete = { sessionStore.removeIntention(item.id); destination = ProfileDestination.Root },
                modifier = modifier,
            )
        }
        ProfileDestination.Archived -> ArchivedIntentionsScreen(
            intentions = archived,
            hidden = hidden,
            onBack = { destination = ProfileDestination.AllIntentions },
            onRestore = { sessionStore.unarchiveIntention(it.id) },
            onDelete = { sessionStore.removeIntention(it.id) },
            modifier = modifier,
        )
        ProfileDestination.Papal -> {
            val item = pope
            if (item == null) destination = ProfileDestination.Root
            else PapalIntentionScreen(
                pope = item,
                alreadyAdded = active.any { it.sourceId == "pope-${item.yearMonth}" },
                onBack = { destination = ProfileDestination.Root },
                onAdd = {
                    sessionStore.addIntention(
                        title = item.title,
                        note = item.note,
                        category = app.rosaryguide.core.data.session.IntentionCategory.World,
                        accent = app.rosaryguide.core.data.session.IntentionAccent.Purple,
                        emoji = "✝️",
                        sourceId = "pope-${item.yearMonth}",
                    )
                },
                modifier = modifier,
            )
        }
        ProfileDestination.Journey -> JourneyScreen(
            sessionStore = sessionStore,
            today = today,
            zone = zone,
            locale = locale,
            firstWeekday = firstWeekday,
            startOnHistory = journeyHistoryTab,
            initialDay = historyDay,
            onBack = { destination = ProfileDestination.Root; historyDay = null },
            modifier = modifier,
        )
    }
}

@Composable
private fun ProfileHome(
    rhythm: app.rosaryguide.core.data.journey.PrayerRhythm,
    milestones: app.rosaryguide.core.data.journey.JourneyMilestones,
    active: List<OfferIntention>,
    archivedCount: Int,
    hidden: Boolean,
    pope: PopeMonthIntention?,
    isSignedIn: Boolean,
    onOpenSettings: () -> Unit,
    onOpenPapal: () -> Unit = {},
    onOpenRhythm: () -> Unit,
    onOpenJourney: () -> Unit,
    onAdd: () -> Unit,
    onOpenAll: () -> Unit,
    onOpenArchived: () -> Unit,
    onOpenDetail: (OfferIntention) -> Unit,
    onEdit: (OfferIntention) -> Unit,
    onPin: (OfferIntention) -> Unit,
    onDelete: (OfferIntention) -> Unit,
    onPray: (OfferIntention) -> Unit,
    onSignIn: () -> Unit,
    onToggleHide: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val preview = active.take(3)
    val gutter = Modifier.padding(horizontal = RosarySpace.gutter)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideLargeTopAppBar(
            title = "Profile",
            actions = {
                IconButton(onClick = onOpenSettings) {
                    Icon(Icons.Filled.Settings, contentDescription = "Settings", tint = palette.ink)
                }
            },
        )
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(bottom = RosarySpace.xl),
        ) {
        Box(modifier = gutter.clickable(onClick = onOpenRhythm)) {
            PrayerRhythmCard(rhythm)
        }
        Spacer(Modifier.height(RosarySpace.lg))
        IntentionsHeader(onToggleHide = onToggleHide, hidden = hidden, showToggle = active.isNotEmpty(), modifier = gutter)
        if (active.isEmpty()) {
            IntentionsEmptyCard(onAdd = onAdd)
        } else {
            Column(modifier = gutter.fillMaxWidth()) {
            preview.forEachIndexed { index, item ->
                IntentionRow(
                    intention = item,
                    hidden = hidden,
                    onOpen = { onOpenDetail(item) },
                    onPray = { onPray(item) },
                    onPin = { onPin(item) },
                    onEdit = { onEdit(item) },
                    onDelete = { onDelete(item) },
                )
                if (index != preview.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 52.dp),
                        color = palette.strokeSubtle,
                    )
                }
            }
            Spacer(Modifier.height(RosarySpace.md))
            GuideOutlineButton(title = "View all intentions", onClick = onOpenAll)
            Spacer(Modifier.height(RosarySpace.sm))
            GuidePrimaryButton(title = "Add intention", onClick = onAdd)
            }
        }
        if (pope != null) {
            Column(modifier = gutter.fillMaxWidth()) {
            Spacer(Modifier.height(RosarySpace.lg))
            GuideSectionLabel(text = "Holy Father’s intention")
            Box(Modifier.clickable(onClick = onOpenPapal)) { HolyFatherCard(pope) }
            }
        }
        if (milestones.preview.isNotEmpty() || milestones.earnedCount > 0 || rhythm.hasEverPrayed) {
            Column(modifier = gutter.fillMaxWidth()) {
            Spacer(Modifier.height(RosarySpace.lg))
            GuideSectionLabel(text = "Milestones")
            val stage = milestoneStage(milestones, rhythm.hasEverPrayed)
            Text(text = stage.first, style = RosaryType.headingSecondary, color = palette.ink)
            Text(text = stage.second, style = RosaryType.caption, color = palette.textSecondary)
            Spacer(Modifier.height(RosarySpace.sm))
            milestones.preview.forEach { item ->
                MilestoneRow(item)
                Spacer(Modifier.height(RosarySpace.sm))
            }
            Text(
                text = "View all milestones",
                style = RosaryType.body,
                color = palette.accent,
                modifier = Modifier
                    .clickable(onClick = onOpenJourney)
                    .padding(vertical = RosarySpace.sm),
            )
            }
        }
        if (!isSignedIn) {
            Column(modifier = gutter.fillMaxWidth()) {
            Spacer(Modifier.height(RosarySpace.lg))
            GuestBackupCard(onSignIn = onSignIn)
            }
        }
        if (archivedCount > 0) {
            Text(
                text = "Archived intentions",
                style = RosaryType.caption,
                color = palette.accent,
                modifier = gutter
                    .clickable(onClick = onOpenArchived)
                    .padding(vertical = RosarySpace.sm),
            )
        }
        }
    }
}

@Composable
private fun IntentionsHeader(onToggleHide: () -> Unit, hidden: Boolean, showToggle: Boolean, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        GuideSectionLabel(text = "Intentions", modifier = Modifier.weight(1f))
        if (showToggle) {
            Text(
                text = if (hidden) "Show titles" else "Hide titles",
                style = RosaryType.caption,
                color = palette.accent,
                modifier = Modifier.clickable(onClick = onToggleHide),
            )
        }
    }
}

@Composable
fun IntentionsEmptyCard(onAdd: () -> Unit, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(app.rosaryguide.core.designsystem.R.drawable.praying_hands_empty),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxWidth()
                .height(280.dp)

        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.md),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                "Keep the people, needs and hopes you carry close as you pray.",
                style = RosaryType.body,
                color = palette.dim,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Spacer(Modifier.height(RosarySpace.lg))
            GuidePrimaryButton(title = "Add your first intention", onClick = onAdd)
        }
    }
}

@Composable
fun HolyFatherCard(pope: PopeMonthIntention, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(RosarySpace.lg),
    ) {
        Text(pope.monthLabel(), style = RosaryType.caption, color = palette.textSecondary)
        Spacer(Modifier.height(RosarySpace.xs))
        Text(pope.title, style = RosaryType.headingSecondary, color = palette.ink)
        pope.note?.let {
            Spacer(Modifier.height(RosarySpace.sm))
            Text(it, style = RosaryType.supportingLabel, color = palette.textSecondary)
        }
    }
}

@Composable
fun GuestBackupCard(onSignIn: () -> Unit, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.containerRadius))
            .background(palette.surface)
            .padding(RosarySpace.lg),
    ) {
        Text("Your prayers are not backed up yet", style = RosaryType.headingSecondary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.xs))
        Text(
            "Your prayer is saved on this device. Sign in with Google to back it up when account sync arrives.",
            style = RosaryType.supportingLabel,
            color = palette.textSecondary,
        )
        Spacer(Modifier.height(RosarySpace.md))
        GuideSecondaryButton(title = "Create an account", onClick = onSignIn)
    }
}

fun milestoneStage(
    progress: app.rosaryguide.core.data.journey.JourneyMilestones,
    hasPrayer: Boolean,
): Pair<String, String> {
    val completed = progress.earnedCount
    val total = progress.items.size
    if (total > 0 && completed == total) {
        return "Faithfully continuing" to "Every milestone reached. Your journey continues."
    }
    if (!hasPrayer && completed == 0) {
        return "A first prayer awaits" to "Begin your first Rosary, one prayer at a time."
    }
    val fraction = completed.toDouble() / total.coerceAtLeast(1).toDouble()
    return when {
        fraction >= 0.60 -> "Steady in prayer" to "Returning to prayer, through the seasons of life."
        fraction >= 0.25 -> "Growing in prayer" to "Making room for God in everyday life."
        else -> "Beginning in prayer" to "A little time with God, one prayer at a time."
    }
}

private fun seedSampleHistory(store: SessionStore, today: LocalDate, zone: ZoneId) {
    val sets = app.rosaryguide.core.model.MysterySetKind.entries
    for (offset in listOf(0, 1, 3, 8, 14, 21, 30)) {
        val day = today.minusDays(offset.toLong())
        val start = day.atTime(20, 0).atZone(zone).toInstant().toEpochMilli()
        store.start(sets[offset % sets.size], nowEpochMs = start)
        store.complete(nowEpochMs = start + 20 * 60 * 1000)
    }
}
