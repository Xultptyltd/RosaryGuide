package app.rosaryguide.android.ui

import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
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
import app.rosaryguide.feature.onboarding.LaunchSplashScreen
import app.rosaryguide.feature.onboarding.OnboardingScreen
import app.rosaryguide.feature.onboarding.SignInScreen
import app.rosaryguide.feature.pray.PrayLaunch
import app.rosaryguide.feature.pray.PrayScreen
import app.rosaryguide.feature.profile.ProfileStubScreen
import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.feature.today.TodayScreen
import java.time.LocalDate
import kotlinx.serialization.Serializable

@Serializable data object TodayRoute
@Serializable data object LearnRoute
@Serializable data object FeastsRoute
@Serializable data object ProfileRoute
@Serializable data class FeastDetailRoute(val feastId: String, val date: String)
@Serializable data object HowToPrayRoute
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
        val auth by viewModel.auth.state.collectAsStateWithLifecycle()
        val today = debugLaunch.clockDate ?: LocalDate.now()
        var showSplash by remember { mutableStateOf(!debugLaunch.skipSplash) }
        var showSignIn by remember { mutableStateOf(debugLaunch.forceSignIn) }
        var prayLaunch by remember { mutableStateOf<PrayLaunch?>(null) }

        fun openPray(set: MysterySetKind, fromDebug: Boolean = false) {
            val config = RosaryConfig.default.copy(
                showBeads = if (debugLaunch.hideBeads) false else RosaryConfig.default.showBeads,
                saintMichael = debugLaunch.includeSaintMichael || RosaryConfig.default.saintMichael,
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

        val didComplete = when {
            debugLaunch.forceOnboarding || debugLaunch.forceSignIn -> false
            debugLaunch.forceTabs -> true
            else -> flags.onboardingCompleted
        }
        val showsApp = LaunchGate.showsApp(
            didCompleteOnboarding = didComplete,
            isSignedIn = auth.isSignedIn,
            signedInThisLaunch = auth.interactiveSignIns > 0,
        ) && !debugLaunch.forceOnboarding && !debugLaunch.forceSignIn && !showSignIn

        Box(Modifier.fillMaxSize()) {
            if (showsApp) {
                AppTabs(
                    debugLaunch = debugLaunch,
                    today = today,
                    hasAskedForNotifications = flags.askedForNotifications,
                    onAskedForNotifications = viewModel::markAskedForNotifications,
                    onPray = { openPray(it) },
                )
            } else if (showSignIn || debugLaunch.forceSignIn) {
                SignInScreen(
                    onGoogle = {
                        viewModel.signInWithGoogle()
                        showSignIn = false
                    },
                    onGuest = {
                        viewModel.continueAsGuest()
                        showSignIn = false
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
                )
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
) {
    val navController = rememberNavController()
    val palette = LocalThemePalette.current
    val backStackEntry by navController.currentBackStackEntryAsState()
    val destination = backStackEntry?.destination
    val onTab = tabs.any { spec -> destination?.hierarchy?.any { it.hasRoute(spec.route::class) } == true }
        && destination?.hasRoute<FeastDetailRoute>() != true
        && destination?.hasRoute<HowToPrayRoute>() != true
        && destination?.hasRoute<ArticleRoute>() != true
        && destination?.hasRoute<PrayerRoute>() != true
        && destination?.hasRoute<MysterySetRoute>() != true

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

    Scaffold(
        containerColor = palette.bg,
        bottomBar = {
            if (onTab) {
                NavigationBar(containerColor = palette.groupedBackground) {
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
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startRoute,
            modifier = Modifier
                .padding(innerPadding)
                .statusBarsPadding(),
            enterTransition = { fadeIn() },
            exitTransition = { fadeOut() },
        ) {
            composable<TodayRoute> {
                TodayScreen(
                    today = today,
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
                )
            }
            composable<LearnRoute> {
                LearnScreen(
                    onHowToPray = { navController.navigate(HowToPrayRoute) },
                    onArticle = { navController.navigate(ArticleRoute(it.id)) },
                    onPrayer = { navController.navigate(PrayerRoute(it.id)) },
                    onMysterySet = { navController.navigate(MysterySetRoute(it.name)) },
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
            composable<ProfileRoute> { ProfileStubScreen() }
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
                DetailScaffold(title = set.titleText.english, onBack = { navController.popBackStack() }) {
                    MysterySetScreen(set)
                }
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
