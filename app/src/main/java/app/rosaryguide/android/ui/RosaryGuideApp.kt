package app.rosaryguide.android.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import app.rosaryguide.core.data.catalog.FeastCatalog
import app.rosaryguide.core.data.catalog.LearnArticle
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.launch.AppTab
import app.rosaryguide.core.data.launch.LaunchGate
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.component.ProvideReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.feature.feasts.FeastDetailScreen
import app.rosaryguide.feature.feasts.FeastsScreen
import app.rosaryguide.feature.learn.HowToPrayScreen
import app.rosaryguide.feature.learn.LearnArticleScreen
import app.rosaryguide.feature.learn.LearnScreen
import app.rosaryguide.feature.learn.MysterySetScreen
import app.rosaryguide.feature.learn.PrayerReaderScreen
import app.rosaryguide.feature.learn.RosaryPrayersScreen
import app.rosaryguide.feature.learn.AllPrayersScreen
import app.rosaryguide.feature.onboarding.LaunchSplashScreen
import app.rosaryguide.feature.onboarding.OnboardingScreen
import app.rosaryguide.feature.onboarding.SignInScreen
import app.rosaryguide.feature.pray.PrayLaunch
import app.rosaryguide.feature.pray.PrayScreen
import app.rosaryguide.feature.profile.ProfileLaunch
import app.rosaryguide.feature.profile.ProfileScreen
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.data.calendar.WeekStart
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.feature.today.TodayScreen
import app.rosaryguide.feature.settings.SettingsPage
import app.rosaryguide.feature.settings.SettingsScreen
import androidx.compose.ui.platform.LocalContext
import android.app.Activity
import java.time.LocalDate
import kotlinx.serialization.Serializable

@Serializable data object TodayRoute
@Serializable data object LearnRoute
@Serializable data object FeastsRoute
@Serializable data object ProfileRoute
@Serializable data class FeastDetailRoute(val feastId: String, val date: String)
@Serializable data object HowToPrayRoute
@Serializable data object RosaryPrayersRoute
@Serializable data object AllPrayersRoute
@Serializable data class ArticleRoute(val id: String)
@Serializable data class PrayerRoute(val id: String)
@Serializable data class MysterySetRoute(val set: String)

private data class TabSpec(
    val route: Any,
    val tab: AppTab,
    val selectedIcon: Int,
    val unselectedIcon: Int,
)

private val tabs = listOf(
    TabSpec(TodayRoute, AppTab.Today, R.drawable.tab_today_filled, R.drawable.tab_today_outline),
    TabSpec(LearnRoute, AppTab.Learn, R.drawable.tab_learn_filled, R.drawable.tab_learn_outline),
    TabSpec(FeastsRoute, AppTab.Feasts, R.drawable.tab_feasts_filled, R.drawable.tab_feasts_outline),
    TabSpec(ProfileRoute, AppTab.Profile, R.drawable.tab_profile_filled, R.drawable.tab_profile_outline),
)

@Composable
fun RosaryGuideApp(
    debugLaunch: DebugLaunch = DebugLaunch(),
    onFirstFrame: () -> Unit = {},
    viewModel: AppViewModel = hiltViewModel(),
) {
    onFirstFrame()
    ProvideReduceMotion {
        val flags by viewModel.flags.collectAsStateWithLifecycle()
        val prayedDayKeys by viewModel.sessionStore.completedDayKeys.collectAsStateWithLifecycle()
        val auth by viewModel.auth.state.collectAsStateWithLifecycle()
        val today = debugLaunch.clockDate ?: LocalDate.now()
        val settings by viewModel.settingsStore.value.collectAsStateWithLifecycle()
        val intentions by viewModel.sessionStore.intentions.collectAsStateWithLifecycle()
        val completed by viewModel.sessionStore.completedSessions.collectAsStateWithLifecycle()
        val context = LocalContext.current
        val versionName = remember {
            runCatching {
                context.packageManager.getPackageInfo(context.packageName, 0).versionName
            }.getOrNull().orEmpty().ifBlank { "0.7.0-m7" }
        }
        var showSplash by remember { mutableStateOf(!debugLaunch.skipSplash) }
        var showSignIn by remember { mutableStateOf(debugLaunch.forceSignIn) }
        var prayLaunch by remember { mutableStateOf<PrayLaunch?>(null) }
        var showSettings by remember {
            mutableStateOf(
                debugLaunch.openSettings ||
                    debugLaunch.openCustomiseRosary ||
                    debugLaunch.openNotifications ||
                    debugLaunch.openAppIcon ||
                    debugLaunch.openLegal ||
                    debugLaunch.openAcknowledgements,
            )
        }
        var settingsPage by remember {
            mutableStateOf(
                when {
                    debugLaunch.openCustomiseRosary -> SettingsPage.CustomiseRosary
                    debugLaunch.openNotifications -> SettingsPage.Notifications
                    debugLaunch.openAppIcon -> SettingsPage.AppIcon
                    debugLaunch.openLegal -> SettingsPage.Terms
                    debugLaunch.openAcknowledgements -> SettingsPage.Acknowledgements
                    else -> SettingsPage.Root
                },
            )
        }
        var showWelcomeReplay by remember { mutableStateOf(false) }
        var consumeForceOnboarding by remember { mutableStateOf(false) }

        fun openPray(set: MysterySetKind, fromDebug: Boolean = false) {
            val base = viewModel.settingsStore.current.rosaryConfig
            val config = base.copy(
                showBeads = if (debugLaunch.hideBeads) false else base.showBeads,
                saintMichael = debugLaunch.includeSaintMichael || base.saintMichael,
            )
            prayLaunch = PrayLaunch(
                mysterySet = set,
                startStep = debugLaunch.prayStep,
                showIntentions = fromDebug && debugLaunch.showIntentions,
                showCompletion = fromDebug && debugLaunch.showCompletion,
                forceFresh = fromDebug && (debugLaunch.forceFreshPray || debugLaunch.showCompletion || debugLaunch.showIntentions),
                config = config,
            )
        }

        LaunchedEffect(debugLaunch.openPray, debugLaunch.showIntentions, debugLaunch.showCompletion) {
            if (debugLaunch.openPray || debugLaunch.showIntentions || debugLaunch.showCompletion) {
                val set = debugLaunch.mysterySet?.let { raw ->
                    MysterySetKind.entries.firstOrNull { it.name.equals(raw, ignoreCase = true) || it.shortName.equals(raw, ignoreCase = true) }
                } ?: MysteryCalendar.assignment(today).set
                openPray(set, fromDebug = true)
            }
        }

        val forcingEntry = (debugLaunch.forceOnboarding || debugLaunch.forceSignIn) && !consumeForceOnboarding
        val didComplete = when {
            forcingEntry -> false
            debugLaunch.forceTabs || consumeForceOnboarding -> true
            else -> flags.onboardingCompleted
        }
        val showsApp = LaunchGate.showsApp(
            didCompleteOnboarding = didComplete,
            isSignedIn = auth.isSignedIn,
            signedInThisLaunch = auth.interactiveSignIns > 0,
        ) && !forcingEntry && !showSignIn

        Box(Modifier.fillMaxSize()) {
            if (showsApp) {
                AppTabs(
                    debugLaunch = debugLaunch,
                    today = today,
                    prayedDayKeys = prayedDayKeys,
                    hasAskedForNotifications = flags.askedForNotifications,
                    onAskedForNotifications = viewModel::markAskedForNotifications,
                    onPray = { openPray(it) },
                    onPrayWith = { intention ->
                        val set = MysteryCalendar.assignment(today).set
                        prayLaunch = PrayLaunch(
                            mysterySet = set,
                            seedIntentions = listOf(intention.id to intention.title),
                            forceFresh = true,
                            config = viewModel.settingsStore.current.rosaryConfig,
                        )
                    },
                    sessionStore = viewModel.sessionStore,
                    isSignedIn = auth.isSignedIn,
                    onSignIn = { showSignIn = true },
                    onOpenSettings = {
                        settingsPage = SettingsPage.Root
                        showSettings = true
                    },
                )
            } else if (showSignIn || debugLaunch.forceSignIn) {
                SignInScreen(
                    onGoogle = {
                        viewModel.signInWithGoogle()
                        showSignIn = false
                        consumeForceOnboarding = true
                    },
                    onGuest = {
                        viewModel.continueAsGuest()
                        showSignIn = false
                        consumeForceOnboarding = true
                    },
                    isSigningInWithGoogle = auth.isSigningInWithGoogle,
                )
            } else {
                OnboardingScreen(
                    initialPage = debugLaunch.onboardingPage ?: 0,
                    onBegin = { showSignIn = true },
                )
            }

            if (showSplash) {
                LaunchSplashScreen(onFinished = { showSplash = false })
            }

            prayLaunch?.let { launch ->
                PrayScreen(
                    launch = launch,
                    sessionStore = viewModel.sessionStore,
                    quotePreferences = viewModel.quotePreferences,
                    onClose = { prayLaunch = null },
                    modifier = Modifier.fillMaxSize(),
                    settingsConfig = settings.rosaryConfig,
                    onRosaryConfigChange = { viewModel.settingsStore.setRosaryConfig(it) },
                    onReadyForReview = {
                        val activity = context as? Activity
                        if (activity != null) viewModel.maybeRequestReview(activity, versionName)
                    },
                )
            }

            if (showSettings) {
                SettingsScreen(
                    settings = settings,
                    appVersion = versionName,
                    isSignedIn = auth.isSignedIn,
                    signedInWith = if (auth.isSignedIn) "Google" else null,
                    hasAppHistory = completed.isNotEmpty() || intentions.isNotEmpty() || prayedDayKeys.isNotEmpty(),
                    playStorePackage = context.packageName,
                    initialPage = settingsPage,
                    onAppearance = { viewModel.settingsStore.setAppearance(it) },
                    onRosaryConfig = { viewModel.settingsStore.setRosaryConfig(it) },
                    onDailyEnabled = {
                        viewModel.settingsStore.setDailyReminderEnabled(it)
                        viewModel.rescheduleReminders()
                    },
                    onDailyMinutes = {
                        viewModel.settingsStore.setDailyReminderMinutes(it)
                        viewModel.rescheduleReminders()
                    },
                    onFeastEnabled = {
                        viewModel.settingsStore.setFeastAlertsEnabled(it)
                        viewModel.rescheduleReminders()
                    },
                    onFeastMinutes = {
                        viewModel.settingsStore.setFeastAlertMinutes(it)
                        viewModel.rescheduleReminders()
                    },
                    onAppIcon = { viewModel.setAppIcon(it) },
                    onClearHistory = { viewModel.clearAppHistory() },
                    onSignOut = { viewModel.signOut() },
                    onReplayWelcome = {
                        showSettings = false
                        showWelcomeReplay = true
                    },
                    onSignIn = {
                        showSettings = false
                        showSignIn = true
                    },
                    onBack = { showSettings = false },
                    modifier = Modifier.fillMaxSize(),
                )
            }

            if (showWelcomeReplay) {
                OnboardingScreen(
                    initialPage = 0,
                    onBegin = { showWelcomeReplay = false },
                )
            }

            if (prayLaunch != null) {
                BackHandler { prayLaunch = null }
            }
            if (showWelcomeReplay) {
                BackHandler { showWelcomeReplay = false }
            }
        }
    }
}

@Composable
private fun AppTabs(
    debugLaunch: DebugLaunch,
    today: LocalDate,
    hasAskedForNotifications: Boolean,
    onAskedForNotifications: () -> Unit,
    onPray: (MysterySetKind) -> Unit,
    prayedDayKeys: Set<String> = emptySet(),
    onPrayWith: (OfferIntention) -> Unit = {},
    sessionStore: SessionStore,
    isSignedIn: Boolean = false,
    onSignIn: () -> Unit = {},
    onOpenSettings: () -> Unit = {},
) {
    val navController = rememberNavController()
    val palette = LocalThemePalette.current
    val backStackEntry by navController.currentBackStackEntryAsState()
    val destination = backStackEntry?.destination
    val startRoute: Any = when (debugLaunch.startTab) {
        AppTab.Today -> TodayRoute
        AppTab.Learn -> LearnRoute
        AppTab.Feasts -> FeastsRoute
        AppTab.Profile -> ProfileRoute
    }

    LaunchedEffect(debugLaunch) {
        when {
            debugLaunch.feastId != null -> {
                val date = debugLaunch.feastDate ?: today
                navController.navigate(FeastDetailRoute(debugLaunch.feastId, date.toString()))
            }
            debugLaunch.openHowTo -> navController.navigate(HowToPrayRoute)
            debugLaunch.articleId != null -> navController.navigate(ArticleRoute(debugLaunch.articleId))
            debugLaunch.prayerId != null -> navController.navigate(PrayerRoute(debugLaunch.prayerId))
            debugLaunch.mysterySet != null && !debugLaunch.openPray && !debugLaunch.showIntentions && !debugLaunch.showCompletion ->
                navController.navigate(MysterySetRoute(debugLaunch.mysterySet))
        }
    }

    val density = LocalDensity.current
    val fontScale = density.fontScale
    var tabBarHeight by remember { mutableStateOf(80.dp) }
    val tabClearance = if (fontScale >= 1.6f) maxOf(tabBarHeight, 148.dp) else tabBarHeight
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(palette.bg)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Horizontal + WindowInsetsSides.Top)),
    ) {
        val reduceMotion = LocalReduceMotion.current
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = tabClearance)
                .clipToBounds(),
        ) {
        NavHost(
            navController = navController,
            startDestination = startRoute,
            modifier = Modifier.fillMaxSize(),
            enterTransition = { if (reduceMotion) EnterTransition.None else fadeIn() },
            exitTransition = { if (reduceMotion) ExitTransition.None else fadeOut() },
            popEnterTransition = { if (reduceMotion) EnterTransition.None else fadeIn() },
            popExitTransition = { if (reduceMotion) ExitTransition.None else fadeOut() },
        ) {
            composable<TodayRoute> {
                TodayScreen(
                    today = today,
                    prayedDayKeys = prayedDayKeys,
                    hasAskedForNotifications = hasAskedForNotifications,
                    onAskedForNotifications = onAskedForNotifications,
                    onViewAllFeasts = {
                        navController.navigate(FeastsRoute) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onFeastClick = { item ->
                        navController.navigate(FeastDetailRoute(item.feast.id, item.date.toString()))
                    },
                    onPray = onPray,
                    onOpenSettings = onOpenSettings,
                )
            }
            composable<LearnRoute> {
                LearnScreen(
                    onHowToPray = { navController.navigate(HowToPrayRoute) },
                    onArticle = { navController.navigate(ArticleRoute(it.id)) },
                    onPrayer = { navController.navigate(PrayerRoute(it.id)) },
                    onMysterySet = { navController.navigate(MysterySetRoute(it.name)) },
                    onRosaryPrayers = { navController.navigate(RosaryPrayersRoute) },
                    onAllPrayers = { navController.navigate(AllPrayersRoute) },
                    onBeginRosary = { onPray(MysteryCalendar.assignment(today).set) },
                    todaySetTitle = MysteryCalendar.assignment(today).set.titleText.english,
                )
            }
            composable<FeastsRoute> {
                FeastsScreen(
                    today = today,
                    onFeastClick = { item ->
                        navController.navigate(FeastDetailRoute(item.feast.id, item.date.toString()))
                    },
                )
            }
            composable<ProfileRoute> {
                ProfileScreen(
                    sessionStore = sessionStore,
                    today = today,
                    isSignedIn = isSignedIn,
                    onPrayWith = onPrayWith,
                    onSignIn = onSignIn,
                    onOpenSettings = onOpenSettings,
                    launch = ProfileLaunch(
                        openJourney = debugLaunch.openJourney || debugLaunch.historyDay != null,
                        journeyHistory = debugLaunch.journeyHistory || debugLaunch.historyDay != null,
                        openAllIntentions = debugLaunch.openAllIntentions,
                        openEditor = debugLaunch.openIntentionEditor,
                        openArchived = debugLaunch.openArchived,
                        historyDay = debugLaunch.historyDay,
                        sampleIntentions = debugLaunch.sampleIntentions,
                        sampleHistory = debugLaunch.sampleHistory,
                        openPapal = debugLaunch.openPapal,
                    ),
                )
            }
            composable<FeastDetailRoute> { entry ->
                val route = entry.toRoute<FeastDetailRoute>()
                val feast = FeastCatalog.all.find { it.id == route.feastId } ?: return@composable
                val date = runCatching { LocalDate.parse(route.date) }.getOrDefault(today)
                DetailScaffold(title = feast.shortTitle, onBack = { navController.popBackStack() }) {
                    FeastDetailScreen(item = DatedFeast(feast, date), onPray = onPray)
                }
            }
            composable<HowToPrayRoute> {
                DetailScaffold(title = "How to pray the Rosary", onBack = { navController.popBackStack() }) {
                    HowToPrayScreen()
                }
            }
            composable<RosaryPrayersRoute> {
                DetailScaffold(title = "Rosary prayers", onBack = { navController.popBackStack() }) {
                    RosaryPrayersScreen(onPrayer = { navController.navigate(PrayerRoute(it.id)) })
                }
            }
            composable<AllPrayersRoute> {
                DetailScaffold(title = "All prayers", onBack = { navController.popBackStack() }) {
                    AllPrayersScreen(onPrayer = { navController.navigate(PrayerRoute(it.id)) })
                }
            }
            composable<ArticleRoute> { entry ->
                val route = entry.toRoute<ArticleRoute>()
                val article = LearnArticle.byId(route.id) ?: return@composable
                DetailScaffold(title = article.title, onBack = { navController.popBackStack() }) {
                    LearnArticleScreen(article)
                }
            }
            composable<PrayerRoute> { entry ->
                val route = entry.toRoute<PrayerRoute>()
                val prayer = PrayerCatalog.prayer(route.id) ?: return@composable
                DetailScaffold(title = prayer.title.english, onBack = { navController.popBackStack() }) {
                    PrayerReaderScreen(prayer)
                }
            }
            composable<MysterySetRoute> { entry ->
                val route = entry.toRoute<MysterySetRoute>()
                val set = runCatching { MysterySetKind.valueOf(route.set) }.getOrNull() ?: return@composable
                DetailScaffold(title = set.shortName, onBack = { navController.popBackStack() }) {
                    MysterySetScreen(set)
                }
            }
        }
        }
        NavigationBar(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .onSizeChanged { size ->
                    if (size.height > 0) {
                        val measured = with(density) { size.height.toDp() }
                        if (measured > tabBarHeight) tabBarHeight = measured
                    }
                },
            containerColor = palette.groupedBackground,
            windowInsets = WindowInsets.safeDrawing.only(
                WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal,
            ),
        ) {
            tabs.forEach { tab ->
                val selected = destination?.hierarchy?.any { it.hasRoute(tab.route::class) } == true
                NavigationBarItem(
                    selected = selected,
                    onClick = {
                        navController.navigate(tab.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    icon = {
                        Icon(
                            painter = painterResource(if (selected) tab.selectedIcon else tab.unselectedIcon),
                            contentDescription = tab.tab.title,
                        )
                    },
                    label = {
                        Text(text = tab.tab.title, style = RosaryType.caption.copy(fontSize = 12.sp))
                    },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = palette.tabSelected,
                        selectedTextColor = palette.tabSelected,
                        unselectedIconColor = palette.textSecondary,
                        unselectedTextColor = palette.textSecondary,
                        indicatorColor = palette.accent.copy(alpha = 0.12f),
                    ),
                )
            }
        }
    }
}

@Composable
private fun DetailScaffold(
    title: String,
    onBack: () -> Unit,
    content: @Composable () -> Unit,
) {
    val palette = LocalThemePalette.current
    Column(Modifier.fillMaxSize().background(palette.bg)) {
        GuideDetailTopBar(title = title, onBack = onBack)
        Box(Modifier.weight(1f)) { content() }
    }
}
