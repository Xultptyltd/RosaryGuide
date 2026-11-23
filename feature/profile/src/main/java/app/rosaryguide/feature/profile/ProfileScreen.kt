package app.rosaryguide.feature.profile
import androidx.compose.foundation.ScrollState

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import app.rosaryguide.core.designsystem.R
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
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
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.component.GuestBackupCard
import app.rosaryguide.core.designsystem.component.AppPageBackground
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import app.rosaryguide.core.designsystem.component.GuideOutlineButton
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.Hairline
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
    val scrollToEnd: Boolean = false,
)

@OptIn(ExperimentalMaterial3Api::class)
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
            sessionStore.addIntention("Peace in the world", category = app.rosaryguide.core.data.session.IntentionCategory.World, emoji = "⛪")
            sessionStore.addIntention("For Grandma's recovery", category = app.rosaryguide.core.data.session.IntentionCategory.Someone, emoji = "👨‍👩‍👧")
            sessionStore.addIntention("Patience with my family", category = app.rosaryguide.core.data.session.IntentionCategory.Personal, emoji = "💚")
        }
        if (launch.sampleHistory && sessionStore.completed.isEmpty()) {
            seedSampleHistory(sessionStore, today, zone)
        }
    }

    var destination by remember {
        mutableStateOf(
            when {
                launch.openAllIntentions -> ProfileDestination.AllIntentions
                launch.openArchived -> ProfileDestination.Archived
                launch.openJourney -> ProfileDestination.Journey
                launch.openPapal -> ProfileDestination.Papal
                else -> ProfileDestination.Root
            },
        )
    }
    var editing by remember { mutableStateOf<OfferIntention?>(null) }
    var showEditor by remember { mutableStateOf(launch.openEditor) }
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

    Box(modifier) {
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
            onAdd = { editing = null; showEditor = true },
            onOpenAll = { destination = ProfileDestination.AllIntentions },
            onOpenArchived = { destination = ProfileDestination.Archived },
            onOpenDetail = { detail = it; destination = ProfileDestination.Detail },
            onEdit = { editing = it; showEditor = true },
            onPin = { sessionStore.setPinned(it.id, !it.isPinned) },
            onDelete = { sessionStore.removeIntention(it.id) },
            onPray = onPrayWith,
            onSignIn = onSignIn,
            onToggleHide = { sessionStore.setHideIntentionText(!hidden) },
            today = today,
            zone = zone,
            earliestActivityEpochMs = listOfNotNull(
                completed.minOfOrNull { it.startedAtEpochMs },
                intentions.minOfOrNull { it.createdAtEpochMs },
            ).minOrNull(),
            scrollToEnd = launch.scrollToEnd,
            modifier = modifier,
        )
        ProfileDestination.AllIntentions -> AllIntentionsScreen(
            intentions = active,
            archivedCount = archived.size,
            hidden = hidden,
            onBack = { destination = ProfileDestination.Root },
            onAdd = { editing = null; showEditor = true },
            onOpenArchived = { destination = ProfileDestination.Archived },
            onOpenDetail = { detail = it; destination = ProfileDestination.Detail },
            onEdit = { editing = it; showEditor = true },
            onPin = { sessionStore.setPinned(it.id, !it.isPinned) },
            onDelete = { sessionStore.removeIntention(it.id) },
            onPray = onPrayWith,
            onToggleHide = { sessionStore.setHideIntentionText(!hidden) },
            modifier = modifier,
        )
        ProfileDestination.Editor -> Unit
        ProfileDestination.Detail -> {
            val item = detail
            if (item == null) destination = ProfileDestination.Root
            else IntentionDetailScreen(
                intention = item,
                hidden = hidden,
                onBack = { destination = ProfileDestination.Root },
                onEdit = { editing = item; showEditor = true },
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

    if (showEditor) {
        val palette = LocalThemePalette.current
        ModalBottomSheet(
            onDismissRequest = { showEditor = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = palette.bg,
        ) {
            IntentionEditorScreen(
                existing = editing,
                onBack = { showEditor = false },
                onSave = { draft ->
                    if (editing == null) sessionStore.addIntention(
                        title = draft.title,
                        note = draft.note,
                        category = draft.category,
                        accent = draft.accent,
                        emoji = draft.emoji,
                        pin = draft.isPinned,
                    ) else {
                        sessionStore.updateIntention(draft)
                        if (detail?.id == draft.id) detail = draft
                    }
                    showEditor = false
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding(),
            )
        }
    }
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
    today: java.time.LocalDate,
    zone: java.time.ZoneId,
    earliestActivityEpochMs: Long? = null,
    scrollToEnd: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val preview = active.take(3)
    val gutter = Modifier.padding(horizontal = RosarySpace.gutter)
    Box(modifier = modifier.fillMaxSize()) {
        AppPageBackground()
        val scroll = remember(scrollToEnd) { ScrollState(if (scrollToEnd) Int.MAX_VALUE else 0) }
        val collapsePx = with(LocalDensity.current) { 28.dp.roundToPx() }
        val collapsed = scrollToEnd || scroll.value > collapsePx
        androidx.compose.runtime.LaunchedEffect(scrollToEnd, scroll.maxValue) {
            if (scrollToEnd && scroll.maxValue > 0) {
                scroll.scrollTo(scroll.maxValue)
            }
        }
    Column(
        modifier = Modifier.fillMaxSize(),
    ) {
        if (!collapsed) {
            ProfileLargeTitle(onOpenSettings = onOpenSettings)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(scroll)
                .padding(bottom = RosarySpace.tabBarContentClearance),
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
            val hero = preview.firstOrNull { it.isPinned } ?: preview.first()
            val rest = preview.filter { it.id != hero.id }
            IntentionHero(
                intention = hero,
                hidden = hidden,
                onOpen = { onOpenDetail(hero) },
                onPray = { onPray(hero) },
                onPin = { onPin(hero) },
                onEdit = { onEdit(hero) },
                onDelete = { onDelete(hero) },
            )
            rest.forEachIndexed { index, item ->
                if (index == 0) Spacer(Modifier.height(RosarySpace.md))
                IntentionRow(
                    intention = item,
                    hidden = hidden,
                    onOpen = { onOpenDetail(item) },
                    onPray = { onPray(item) },
                    onPin = { onPin(item) },
                    onEdit = { onEdit(item) },
                    onDelete = { onDelete(item) },
                )
                if (index != rest.lastIndex) {
                    HorizontalDivider(
                    thickness = Hairline.thickness, modifier = Modifier.padding(start = 56.dp),
                        color = palette.hair,
                    )
                }
            }
            Spacer(Modifier.height(RosarySpace.md))
            GuideOutlineButton(title = "View all intentions", onClick = onOpenAll)
            }
        }
        if (pope != null && active.none { it.sourceId == "pope-${pope.yearMonth}" }) {
            Column(modifier = gutter.fillMaxWidth()) {
            Spacer(Modifier.height(RosarySpace.lg))
            GuideSectionLabel(text = "Holy Father’s intention")
            Box(Modifier.clickable(onClick = onOpenPapal)) { HolyFatherCard(pope) }
            }
        }
        // Milestones live on the Journey screen, not the Profile hub, matching iOS OfferView.
        if (!isSignedIn) {
            Column(modifier = gutter.fillMaxWidth()) {
            Spacer(Modifier.height(RosarySpace.lg))
            GuestBackupCard(onCreateAccount = onSignIn, today = today, zone = zone, earliestActivityEpochMs = earliestActivityEpochMs)
            }
        }
        if (archivedCount > 0) {
            Text(
                text = "Archived intentions",
                style = RosaryType.captionPray,
                color = palette.accent,
                modifier = gutter
                    .clickable(onClick = onOpenArchived)
                    .padding(vertical = RosarySpace.sm),
            )
        }
        }
    }
        if (collapsed) {
            ProfileCompactTitleBar(onOpenSettings = onOpenSettings)
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
        GuideSectionLabel(text = "Your intentions", modifier = Modifier.weight(1f))
        if (showToggle) {
            Text(
                text = if (hidden) "Show titles" else "Hide titles",
                style = RosaryType.captionPray,
                color = palette.accent,
                modifier = Modifier.clickable(onClick = onToggleHide),
            )
        }
    }
}

@Composable
fun IntentionsEmptyCard(onAdd: () -> Unit, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(RosarySpace.lg + RosarySpace.xs),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(palette.mysteryIconFill),
            contentAlignment = Alignment.Center,
        ) {
            Image(
                painter = painterResource(app.rosaryguide.core.designsystem.R.drawable.intention_icon_personal),
                contentDescription = null,
                colorFilter = ColorFilter.tint(palette.mysteryIconGlyph),
                modifier = Modifier.size((44 * 0.8f).dp),
            )
        }
        Text(
            text = "What’s on your heart?",
            style = RosaryType.headingSecondaryPray,
            color = palette.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = RosarySpace.md),
        )
        Text(
            text = "Keep your intentions close as you pray.",
            style = RosaryType.bodyPray,
            color = palette.textSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = RosarySpace.xs),
        )
        GuidePrimaryButton(
            title = "Add intention",
            onClick = onAdd,
            modifier = Modifier.padding(top = RosarySpace.lg),
        )
    }
}

@Composable
fun HolyFatherCard(pope: PopeMonthIntention, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(R.drawable.pope_leo),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(96.dp),
        )
        Column(
            Modifier
                .weight(1f)
                .padding(start = RosarySpace.lg, end = RosarySpace.lg, top = RosarySpace.md, bottom = RosarySpace.md),
        ) {
            Text(pope.title, style = RosaryType.bodyPray, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(pope.monthLabel(), style = RosaryType.captionPray, color = palette.textSecondary)
        }
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


/**
 * Profile-only large title. iOS places the "Profile" H1 ~60 pt below the
 * safe area; Material [GuideLargeTopAppBar] added ~25–32 dp extra padding,
 * well beyond the status-inset difference, so this layout is local to Profile
 * and leaves the shared bar (Learn, Feasts) unchanged.
 */
@Composable
private fun ProfileLargeTitle(onOpenSettings: () -> Unit) {
    val palette = LocalThemePalette.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(
                start = RosarySpace.gutter,
                end = RosarySpace.gutter,
                // 60 dp below the status strip (iOS title top ≈ 119 pt with a 59 pt inset).
                top = 60.dp,
                // Title-to-card gap: 8 dp under the text box lands the rhythm card
                // near iOS 194.7 pt (32 dp overshot to 222).
                bottom = 8.dp,
            ),
    ) {
        Text(
            text = "Profile",
            style = RosaryType.h1Navigation,
            color = palette.ink,
            modifier = Modifier
                .align(Alignment.CenterStart)
                .guideHeading(),
        )
        ProfileGearChip(
            onOpenSettings = onOpenSettings,
            modifier = Modifier.align(Alignment.CenterEnd),
        )
    }
}

/**
 * Compact Profile chrome, overlaid on the scroll so content can fade
 * underneath. The 44 dp bar sits below [statusBarsPadding] (the gear must
 * not share the 3G strip). The downward scrim matches
 * [app.rosaryguide.core.designsystem.component.GuideTabBarScrollEdgeScrim]
 * but inverted, using the page grouped background.
 */
@Composable
private fun ProfileCompactTitleBar(onOpenSettings: () -> Unit) {
    val palette = LocalThemePalette.current
    val barColor = palette.groupedBackground
    val scrim = Brush.verticalGradient(listOf(barColor, Color.Transparent))
    Column(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(barColor)
                .statusBarsPadding(),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp),
            ) {
                Text(
                    text = "Profile",
                    style = RosaryType.navigationTitlePray,
                    color = palette.ink,
                    modifier = Modifier.align(Alignment.Center),
                )
                ProfileGearChip(
                    onOpenSettings = onOpenSettings,
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = RosarySpace.gutter),
                )
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(RosarySpace.tabBarScrollEdgeScrimHeight)
                .drawBehind { drawRect(scrim) },
        )
    }
}

@Composable
private fun ProfileGearChip(onOpenSettings: () -> Unit, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Box(
        modifier = modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(
                if (palette.isDark) androidx.compose.ui.graphics.Color.White.copy(alpha = 0.16f)
                else androidx.compose.ui.graphics.Color.White.copy(alpha = 0.92f),
            )
            .clickable(onClick = onOpenSettings),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Filled.Settings,
            contentDescription = "Settings",
            tint = palette.ink,
            modifier = Modifier.size(20.dp),
        )
    }
}
