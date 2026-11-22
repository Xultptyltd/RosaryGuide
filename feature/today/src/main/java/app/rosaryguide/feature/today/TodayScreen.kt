package app.rosaryguide.feature.today

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.mutableIntStateOf
import app.rosaryguide.core.data.catalog.MysteryCatalog
import app.rosaryguide.core.designsystem.component.GuideGlassSurface
import app.rosaryguide.core.designsystem.component.GuideSheetDragHandle
import app.rosaryguide.core.data.navigation.NavigationIa
import app.rosaryguide.core.model.Mystery
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.OrdinalWord
import kotlinx.coroutines.launch

import android.content.Intent
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import app.rosaryguide.core.designsystem.theme.RosaryFonts
import app.rosaryguide.core.model.AppearancePreference
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
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
import app.rosaryguide.core.designsystem.component.GuideOutlineButton
import app.rosaryguide.core.designsystem.component.mysteryPlateDrawableId
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.graphics.Path
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.Canvas
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideScreenHeader
import app.rosaryguide.core.designsystem.component.GuideSectionDivider
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.drawableIdByName
import app.rosaryguide.core.designsystem.component.feastHeroDrawableId
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize
import app.rosaryguide.core.model.DatedFeast
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodayScreen(
    onViewAllFeasts: () -> Unit,
    onFeastClick: (DatedFeast) -> Unit,
    onPray: (app.rosaryguide.core.model.MysterySetKind) -> Unit,
    onResumePray: (app.rosaryguide.core.model.MysterySetKind) -> Unit = onPray,
    modifier: Modifier = Modifier,
    today: LocalDate = LocalDate.now(),
    resumableCta: String? = null,
    prayedDayKeys: Set<String> = emptySet(),
    hasAskedForNotifications: Boolean = true,
    onAskedForNotifications: () -> Unit = {},
    onPrayDecade: (MysterySetKind, Int) -> Unit = { set, _ -> onPray(set) },
    openWeekFeastSheet: Boolean = false,
    openMysteryDetailSheet: Boolean = false,
    debugNonce: Long = 0L,
    appearance: AppearancePreference = AppearancePreference.System,
    onAppearance: (AppearancePreference) -> Unit = {},
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val firstWeekday = WeekStart.firstWeekday()
    val assignment = remember(today) { MysteryCalendar.assignment(today) }
    val week = remember(today, firstWeekday) { MysteryCalendar.week(today, firstWeekday) }
    val upcoming = remember(today) { FeastCatalog.upcoming(today, limit = 8) }
    val featured = upcoming.firstOrNull()
    val rest = if (featured == null) emptyList() else upcoming.drop(1).take(2)
    var selectedSet by remember { mutableStateOf<MysterySetKind?>(null) }
    var prefersWeekday by remember { mutableStateOf(false) }
    val currentSet = assignment.shownSet(selectedSet, prefersWeekday)
    val todaysSet = assignment.defaultSet(prefersWeekday)
    val isShowingTodayMysteries = currentSet == todaysSet
    fun debugWeekFeast(): DatedFeast? {
        if (!openWeekFeastSheet) return null
        val target = LocalDate.of(2026, 11, 21)
        return FeastCatalog.upcoming(today, limit = 20).firstOrNull {
            it.date == target || it.feast.id.contains("presentation", ignoreCase = true)
        } ?: FeastCatalog.upcoming(today, limit = 8).firstOrNull()
    }
    var weekFeast by remember(openWeekFeastSheet, debugNonce, today) { mutableStateOf(debugWeekFeast()) }
    var pendingFeastDetail by remember { mutableStateOf<DatedFeast?>(null) }
    var showMysterySheet by remember(openMysteryDetailSheet, debugNonce) { mutableStateOf(openMysteryDetailSheet) }
    var lastMysteryIndex by remember(openMysteryDetailSheet, debugNonce) { mutableIntStateOf(0) }
    var showAppearanceMenu by remember { mutableStateOf(false) }

    LaunchedEffect(weekFeast, pendingFeastDetail) {
        val pending = pendingFeastDetail
        if (weekFeast == null && pending != null) {
            onFeastClick(pending)
            pendingFeastDetail = null
        }
    }
    LaunchedEffect(openWeekFeastSheet, today) {
        if (openWeekFeastSheet && weekFeast == null) {
            val target = LocalDate.of(2026, 11, 21)
            weekFeast = FeastCatalog.upcoming(today, limit = 20).firstOrNull {
                it.date == target || it.feast.id.contains("presentation", ignoreCase = true)
            } ?: FeastCatalog.upcoming(today, limit = 8).firstOrNull()
        }
    }
    LaunchedEffect(openMysteryDetailSheet) {
        if (openMysteryDetailSheet) {
            lastMysteryIndex = 0
            showMysterySheet = true
        }
    }

    NotificationPermissionEffect(
        hasAsked = hasAskedForNotifications,
        onAsked = onAskedForNotifications,
    )

    val dateLabel = today.format(DateTimeFormatter.ofPattern("EEEE d MMMM", Locale.forLanguageTag("en-AU")))
    val ctaTitle = when {
        isShowingTodayMysteries && resumableCta != null -> resumableCta
        isShowingTodayMysteries && today.toString() in prayedDayKeys -> HomeCopy.PRAY_AGAIN
        isShowingTodayMysteries -> HomeCopy.PRAY_TODAYS_MYSTERIES
        else -> HomeCopy.prayTheMysteries(currentSet)
    }
    val mysteries = MysteryCatalog.mysteries(currentSet)
    val railTitle = if (isShowingTodayMysteries) "Today's mysteries" else currentSet.titleText.english

    BoxWithConstraints(modifier = modifier.fillMaxSize().background(palette.groupedBackground)) {
        val pageWidth = maxWidth
        val topInset = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
        val screenHeight = LocalConfiguration.current.screenHeightDp.dp
        // Use the device frame, not the iPhone 17 Pro Max's taller 956 pt window, so the
        // first screen still shows "Today's mysteries" and a rail peek above the tab bar.
        val viewport = screenHeight
        val heroBody = RosarySpace.homeHeroHeight(viewport)
        val artworkTop = topInset * 0.6f
        val rawHero = heroBody + topInset + artworkTop
        val heroHeight = (rawHero - 18.dp).coerceAtLeast(460.dp)
        val titleSize = RosarySpace.homeTitleSizeSp(pageWidth.value)
        val heroName = ArtCatalog.heroName(currentSet)
        val heroRes = drawableIdByName(context, heroName)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = RosarySpace.tabBarContentClearance),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(heroHeight)
                    .background(palette.groupedBackground),
            ) {
                if (heroRes != 0) {
                    val heroPainter = painterResource(heroRes)
                    val src = heroPainter.intrinsicSize
                    CroppedArt(
                        painter = heroPainter,
                        coverForFrame = { frameW, frameH ->
                            ArtCatalog.coverForFocus(
                                sourceWidth = if (src.width.isFinite() && src.width > 1f) src.width else 1280f,
                                sourceHeight = if (src.height.isFinite() && src.height > 1f) src.height else 720f,
                                frameWidth = frameW,
                                frameHeight = frameH,
                                focusX = 0.5f,
                                focusY = 0.28f,
                            )
                        },
                        contentDescription = "${currentSet.shortName} Mysteries",
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = artworkTop)
                            .height(heroBody + topInset)
                            .align(Alignment.TopCenter),
                    )
                }
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(heroHeight)
                        .background(
                            Brush.verticalGradient(
                                0.00f to palette.groupedBackground.copy(alpha = if (palette.isDark) 0.34f else 0.18f),
                                0.22f to Color.Transparent,
                                0.64f to palette.groupedBackground.copy(alpha = 0.55f),
                                0.86f to palette.groupedBackground,
                                1.00f to palette.groupedBackground,
                            ),
                        ),
                )
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(top = topInset, end = RosarySpace.gutter),
                ) {
                    val chipLabel = if (palette.isDark) "Dark" else "Light"
                    val chipShape = RoundedCornerShape(percent = 50)
                    GuideGlassSurface(
                        isDark = palette.isDark,
                        shape = chipShape,
                        modifier = Modifier.clickable { showAppearanceMenu = true },
                    ) {
                        Row(
                            modifier = Modifier
                                .semantics { contentDescription = "Appearance" }
                                .padding(horizontal = 14.dp)
                                .heightIn(min = 44.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            AppearanceChipIcon(dark = palette.isDark, tint = palette.ink)
                            Text(chipLabel, style = RosaryType.caption.copy(fontWeight = FontWeight.Medium), color = palette.ink)
                        }
                    }
                    DropdownMenu(
                        expanded = showAppearanceMenu,
                        onDismissRequest = { showAppearanceMenu = false },
                    ) {
                        AppearancePreference.entries.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option.title, style = RosaryType.body) },
                                onClick = {
                                    onAppearance(option)
                                    showAppearanceMenu = false
                                },
                            )
                        }
                    }
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .offset(y = -RosarySpace.homeSheetOverlap)
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(top = RosarySpace.sm),
            ) {
                Text(text = dateLabel, style = RosaryType.caption, color = palette.dim)
                Spacer(Modifier.height(RosarySpace.md))
                Text(
                    text = "${currentSet.shortName}\nMysteries",
                    style = TextStyle(
                        color = palette.ink,
                        fontFamily = RosaryFonts.sans,
                        fontWeight = FontWeight.Normal,
                        fontSize = titleSize.sp,
                        lineHeight = (titleSize * RosarySpace.TitleLineHeight).sp,
                        lineHeightStyle = LineHeightStyle(
                            alignment = LineHeightStyle.Alignment.Center,
                            trim = LineHeightStyle.Trim.Both,
                        ),
                        platformStyle = PlatformTextStyle(includeFontPadding = false),
                    ),
                    modifier = Modifier.semantics { contentDescription = "${currentSet.shortName} Mysteries" },
                )
                Spacer(Modifier.height(RosarySpace.md))
                Text(
                    text = currentSet.themeSummary,
                    style = RosaryType.body.copy(lineHeight = 21.sp),
                    color = palette.dim,
                )
                Spacer(Modifier.height(RosarySpace.xl))
                MysterySetPicker(
                    current = currentSet,
                    todaySet = assignment.pickerDotSet,
                    onSelect = { selectedSet = it },
                )
                Spacer(Modifier.height(RosarySpace.lg))
                GuidePrimaryButton(
                    title = ctaTitle,
                    onClick = {
                        if (isShowingTodayMysteries && resumableCta != null) onResumePray(currentSet) else onPray(currentSet)
                    },
                )
                Spacer(Modifier.height(RosarySpace.xxl))
                GuideSectionLabel(text = railTitle, strong = true)
                Spacer(Modifier.height(RosarySpace.sectionTitleGap))
            }

            val cardWidth = (pageWidth * RosarySpace.mysteryCardWidthFraction)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .offset(y = -RosarySpace.homeSheetOverlap)
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.sm),
                horizontalArrangement = Arrangement.spacedBy(RosarySpace.md),
            ) {
                mysteries.forEachIndexed { index, mystery ->
                    MysteryRailCard(
                        mystery = mystery,
                        fallbackArt = heroName,
                        width = cardWidth,
                        onClick = {
                            lastMysteryIndex = index
                            showMysterySheet = true
                        },
                    )
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .offset(y = -RosarySpace.homeSheetOverlap)
                    .padding(bottom = RosarySpace.xxl),
            ) {
                GuideSectionDivider(Modifier.padding(horizontal = RosarySpace.gutter))
                Spacer(Modifier.height(RosarySpace.xl))
                GuideSectionLabel(
                    text = HomeCopy.UPCOMING_FEAST_DAYS,
                    strong = true,
                    modifier = Modifier.padding(horizontal = RosarySpace.gutter),
                )
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
                GuideOutlineButton(
                    title = HomeCopy.VIEW_ALL_FEASTS,
                    onClick = onViewAllFeasts,
                    modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.md),
                )

                Spacer(Modifier.height(RosarySpace.xl))
                GuideSectionDivider(Modifier.padding(horizontal = RosarySpace.gutter))
                Spacer(Modifier.height(RosarySpace.xl))
                GuideSectionLabel(
                    text = HomeCopy.THIS_WEEK,
                    strong = true,
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
                        onClick = {
                            when (val action = NavigationIa.weekDayAction(date, dayAssignment.feast)) {
                                is NavigationIa.WeekDayAction.SelectDay -> selectedSet = dayAssignment.set
                                is NavigationIa.WeekDayAction.OpenWeekFeastSheet -> weekFeast = action.feast
                            }
                        },
                        modifier = Modifier.padding(horizontal = RosarySpace.gutter),
                    )
                    if (index < week.lastIndex && !isTodayRow && !nextIsToday) {
                        HorizontalDivider(
                            modifier = Modifier.padding(horizontal = RosarySpace.gutter),
                            color = palette.hair,
                            thickness = Hairline.thickness,
                        )
                    }
                }

                Spacer(Modifier.height(RosarySpace.xxl))
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(percent = 50))
                            .background(palette.buttonTertiaryFill)
                            .clickable {
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_SUBJECT, "Rosary Guide")
                                    putExtra(
                                        Intent.EXTRA_TEXT,
                                        "I've been praying the Rosary with Rosary Guide. Take a look:\nhttps://rosaryguide.app",
                                    )
                                }
                                context.startActivity(Intent.createChooser(send, "Share Rosary Guide"))
                            }
                            .padding(horizontal = RosarySpace.lg)
                            .heightIn(min = 44.dp)
                            .semantics { contentDescription = "Share Rosary Guide" },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("Share Rosary Guide", style = RosaryType.body, color = palette.buttonTertiaryText)
                    }
                }
            }
        }
    }

    val feastForSheet = weekFeast
    if (feastForSheet != null) {
        ModalBottomSheet(
            onDismissRequest = { weekFeast = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = palette.bg,
            shape = RoundedCornerShape(topStart = RosarySpace.containerRadius, topEnd = RosarySpace.containerRadius),
            dragHandle = { GuideSheetDragHandle() },
            contentWindowInsets = { WindowInsets(0, 0, 0, 0) },
        ) {
            WeekFeastSheet(
                item = feastForSheet,
                onExplore = {
                    pendingFeastDetail = feastForSheet
                    weekFeast = null
                },
            )
        }
    }

    if (showMysterySheet) {
        ModalBottomSheet(
            onDismissRequest = { showMysterySheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = palette.bg,
            shape = RoundedCornerShape(topStart = RosarySpace.containerRadius, topEnd = RosarySpace.containerRadius),
            dragHandle = { GuideSheetDragHandle() },
            contentWindowInsets = { WindowInsets(0, 0, 0, 0) },
        ) {
            MysteryDetailPagerSheet(
                set = currentSet,
                initialIndex = lastMysteryIndex,
                onIndexChanged = { lastMysteryIndex = it },
                onPrayDecade = { decade ->
                    showMysterySheet = false
                    onPrayDecade(currentSet, decade)
                },
            )
        }
    }
}

@Composable
private fun MysterySetPicker(
    current: MysterySetKind,
    todaySet: MysterySetKind,
    onSelect: (MysterySetKind) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val options = MysterySetKind.displayOrder
    val track = if (palette.isDark) palette.surface else Color(0xFFE5E5EA)
    val thumb = if (palette.isDark) Color(0xFF2C2C2E) else Color.White
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(44.dp)
            .clip(RoundedCornerShape(percent = 50))
            .background(track)
            .semantics { contentDescription = "Mystery set" },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        options.forEach { set ->
            val selected = current == set
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxSize()
                    .padding(2.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(if (selected) thumb else Color.Transparent)
                    .clickable { onSelect(set) },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    if (set == todaySet) {
                        Box(
                            modifier = Modifier
                                .padding(bottom = 2.dp)
                                .size(4.dp)
                                .clip(CircleShape)
                                .background(if (selected) palette.ink else palette.dim.copy(alpha = 0.45f)),
                        )
                    } else {
                        Spacer(Modifier.height(6.dp))
                    }
                    Text(
                        text = set.shortName,
                        style = RosaryType.segmentedControl,
                        color = palette.ink,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

@Composable
private fun MysteryRailCard(
    mystery: Mystery,
    fallbackArt: String,
    width: androidx.compose.ui.unit.Dp,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = mysteryPlateDrawableId(context, mystery.artSlug).takeIf { it != 0 }
        ?: drawableIdByName(context, fallbackArt)
    Column(
        modifier = modifier
            .width(width)
            .clip(RoundedCornerShape(RosarySpace.featureRadius))
            .background(palette.cardSurface(PageStyle.Grouped))
            .clickable(onClick = onClick),
    ) {
        if (resId != 0) {
            Image(
                painter = painterResource(resId),
                contentDescription = mystery.title.english,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(RosarySpace.mysteryCardArtAspect),
            )
        }
        Column(Modifier.padding(RosarySpace.lg)) {
            Text(text = mystery.title.english, style = RosaryType.headingCard, color = palette.ink)
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
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = drawableIdByName(context, heroName)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.featureRadius))
            .background(palette.cardSurface(PageStyle.Grouped))
            .clickable(onClick = onClick)
            .semantics { contentDescription = "$setName Mysteries" },
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
            .background(palette.cardSurface(PageStyle.Grouped))
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
    val day = item.date.format(DateTimeFormatter.ofPattern("dd", Locale.getDefault()))
    val month = item.date.format(DateTimeFormatter.ofPattern("MMM", Locale.getDefault())).uppercase(Locale.getDefault())
    val ax = isAccessibilitySize()
    val rowMod = modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(RosarySpace.nestedRadius))
        .clickable(onClick = onClick)
        .padding(vertical = RosarySpace.sm)
    if (ax) {
        Column(modifier = rowMod) {
            Text(text = "$day $month", style = RosaryType.supportingLabel, color = palette.dim)
            Text(text = item.feast.shortTitle, style = RosaryType.body, color = palette.ink)
        }
    } else {
    Row(
        modifier = rowMod,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier.width(44.dp).padding(end = RosarySpace.xs),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(text = day, style = RosaryType.headingSecondary, color = palette.ink)
            Text(text = month, style = RosaryType.caption, color = palette.dim)
        }
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

@Composable
private fun WeekFeastSheet(
    item: DatedFeast,
    onExplore: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val dateText = item.date.format(DateTimeFormatter.ofPattern("d MMMM yyyy", Locale.forLanguageTag("en-AU")))
    Column(
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.weekFeastSheetHeight())
            .navigationBarsPadding(),
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.sheetHandleToContent),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(RosarySpace.xs),
            ) {
                FeastRankCrown()
                Text(
                    "${item.feast.rank.title} · $dateText",
                    style = RosaryType.caption,
                    color = palette.textSecondary,
                )
            }
            Spacer(Modifier.height(RosarySpace.sm))
            Text(item.feast.shortTitle, style = RosaryType.headingPrimary, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.xl))
            Text(
                NavigationIa.weekFeastDescription(item.feast),
                style = RosaryType.body.copy(lineHeight = 21.sp),
                color = palette.ink,
            )
        }
        GuideSecondaryButton(
            title = "Explore this feast",
            onClick = onExplore,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(vertical = RosarySpace.lg),
        )
    }
}

@Composable
private fun FeastRankCrown(modifier: Modifier = Modifier) {
    val color = LocalThemePalette.current.feastIndicator
    Canvas(modifier = modifier.size(12.dp)) {
        val w = size.width
        val h = size.height
        val path = Path().apply {
            moveTo(0f, h * 0.42f)
            lineTo(w * 0.18f, h * 0.68f)
            lineTo(w * 0.50f, h * 0.08f)
            lineTo(w * 0.82f, h * 0.68f)
            lineTo(w, h * 0.42f)
            lineTo(w * 0.88f, h * 0.92f)
            lineTo(w * 0.12f, h * 0.92f)
            close()
        }
        drawPath(path, color)
    }
}

@Composable
private fun AppearanceChipIcon(dark: Boolean, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(12.dp)) {
        if (dark) {
            val r = size.minDimension * 0.42f
            val moon = Path().apply {
                addOval(
                    androidx.compose.ui.geometry.Rect(
                        center.x - r,
                        center.y - r,
                        center.x + r,
                        center.y + r,
                    ),
                )
                addOval(
                    androidx.compose.ui.geometry.Rect(
                        center.x - r * 0.35f,
                        center.y - r * 1.15f,
                        center.x + r * 1.15f,
                        center.y + r * 0.45f,
                    ),
                )
                fillType = androidx.compose.ui.graphics.PathFillType.EvenOdd
            }
            drawPath(moon, tint)
        } else {
            val r = size.minDimension * 0.22f
            drawCircle(color = tint, radius = r, center = center)
            val ray = size.minDimension * 0.46f
            val inner = size.minDimension * 0.32f
            for (i in 0 until 8) {
                val a = Math.toRadians(i * 45.0).toFloat()
                drawLine(
                    color = tint,
                    start = androidx.compose.ui.geometry.Offset(
                        center.x + kotlin.math.cos(a) * inner,
                        center.y + kotlin.math.sin(a) * inner,
                    ),
                    end = androidx.compose.ui.geometry.Offset(
                        center.x + kotlin.math.cos(a) * ray,
                        center.y + kotlin.math.sin(a) * ray,
                    ),
                    strokeWidth = 1.2f,
                    cap = androidx.compose.ui.graphics.StrokeCap.Round,
                )
            }
        }
    }
}

@Composable
private fun MysteryDetailPagerSheet(
    set: MysterySetKind,
    initialIndex: Int,
    onIndexChanged: (Int) -> Unit,
    onPrayDecade: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val mysteries = MysteryCatalog.mysteries(set)
    val start = initialIndex.coerceIn(0, (mysteries.size - 1).coerceAtLeast(0))
    val pagerState = rememberPagerState(initialPage = start, pageCount = { mysteries.size })
    LaunchedEffect(pagerState.currentPage) { onIndexChanged(pagerState.currentPage) }
    val current = mysteries.getOrNull(pagerState.currentPage)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.mysteryDetailSheetHeight())
            .navigationBarsPadding(),
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
        ) { page ->
            MysteryDetailPage(mystery = mysteries[page], contextName = ArtCatalog.heroName(set))
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = RosarySpace.sm),
            horizontalArrangement = Arrangement.Center,
        ) {
            mysteries.indices.forEach { index ->
                Box(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (index == pagerState.currentPage) palette.ink else palette.dim),
                )
            }
        }
        GuideSecondaryButton(
            title = "Pray this decade",
            onClick = { current?.let { onPrayDecade(it.number) } },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(vertical = RosarySpace.lg),
        )
    }
}

@Composable
private fun MysteryDetailPage(mystery: Mystery, contextName: String) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val resId = mysteryPlateDrawableId(context, mystery.artSlug).takeIf { it != 0 }
        ?: drawableIdByName(context, contextName)
    val tightCaption = RosaryType.caption.copy(
        platformStyle = PlatformTextStyle(includeFontPadding = false),
    )
    val tightTitle = RosaryType.headingPrimary.copy(
        platformStyle = PlatformTextStyle(includeFontPadding = false),
    )
    val tightBody = RosaryType.body.copy(
        lineHeight = 21.sp,
        platformStyle = PlatformTextStyle(includeFontPadding = false),
    )
    // iOS stacks art, title, scripture, and Fruit with Space.xl (24). The true
    // iOS Fruit line is at 0.855, just above the pager dots.
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.sheetHandleToContent, bottom = RosarySpace.md),
    ) {
        if (resId != 0) {
            Image(
                painter = painterResource(resId),
                contentDescription = mystery.title.english,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(RosarySpace.mysteryCardArtAspect)
                    .clip(RoundedCornerShape(RosarySpace.containerRadius)),
            )
            Spacer(Modifier.height(RosarySpace.xl))
        }
        val ordinal = runCatching { OrdinalWord.english(mystery.number) }.getOrDefault(mystery.number.toString())
        Text(
            "$ordinal mystery · ${mystery.set.titleText.english}",
            style = tightCaption,
            color = palette.dim,
        )
        Spacer(Modifier.height(RosarySpace.sm))
        Text(mystery.title.english, style = tightTitle, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.xl))
        if (mystery.scriptureExcerpt.english.isNotBlank()) {
            Text(
                mystery.scriptureExcerpt.english,
                style = tightBody,
                color = palette.ink,
            )
            Spacer(Modifier.height(RosarySpace.sm))
        }
        Text(mystery.scriptureReference, style = tightCaption, color = palette.dim)
        if (mystery.fruit.english.isNotBlank()) {
            Spacer(Modifier.height(RosarySpace.xl))
            MysteryFruitLine(fruit = mystery.fruit.english)
        }
    }
}

@Composable
private fun MysteryFruitLine(fruit: String) {
    val palette = LocalThemePalette.current
    Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
        HorizontalDivider(color = palette.hair, thickness = Hairline.thickness)
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
            Text(
                "Fruit",
                style = RosaryType.body.copy(fontWeight = FontWeight.Medium),
                color = palette.textSecondary,
            )
            Text(fruit, style = RosaryType.body, color = palette.ink)
        }
    }
}
