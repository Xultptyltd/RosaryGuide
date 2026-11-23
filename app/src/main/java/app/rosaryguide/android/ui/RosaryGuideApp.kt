package app.rosaryguide.android.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.union
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Icon
import app.rosaryguide.feature.onboarding.SignInTransitionScreen
import app.rosaryguide.core.model.AppearancePreference
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
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
import app.rosaryguide.core.data.navigation.NavigationIa
import app.rosaryguide.core.data.sequence.RosarySequenceBuilder
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuideTabBar
import app.rosaryguide.core.designsystem.component.GuideTabBarScrollEdgeScrim
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.component.ProvideReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.feature.feasts.FeastDetailScreen
import app.rosaryguide.feature.feasts.FeastPatronagesScreen
import app.rosaryguide.feature.feasts.FeastRelatedPrayersScreen
import app.rosaryguide.feature.feasts.FeastScriptureScreen
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
@Serializable data class FeastRelatedPrayersRoute(val feastId: String, val date: String)
@Serializable data class FeastPatronagesRoute(val feastId: String, val date: String)
@Serializable data class FeastScriptureRoute(val feastId: String, val date: String)
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
        // Sign-in failures (offline, no Google account on the device); a cancel shows nothing.
        androidx.compose.runtime.LaunchedEffect(auth.errorMessage) {
            val message = auth.errorMessage ?: return@LaunchedEffect
            android.widget.Toast.makeText(context, message, android.widget.Toast.LENGTH_LONG).show()
            viewModel.auth.clearError()
        }
        val versionName = remember {
            runCatching {
                context.packageManager.getPackageInfo(context.packageName, 0).versionName
            }.getOrNull().orEmpty().ifBlank { "0.7.0-m7" }
        }
        var showSplash by remember { mutableStateOf(debugLaunch.holdSplash || !debugLaunch.skipSplash) }
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
        androidx.compose.runtime.LaunchedEffect(debugLaunch) {
            showSplash = debugLaunch.holdSplash || !debugLaunch.skipSplash
            showSignIn = debugLaunch.forceSignIn
            consumeForceOnboarding = false
        }
        var signInOrigin by remember { mutableStateOf<NavigationIa.SignInOrigin?>(null) }
        var tabsResetKey by remember { mutableIntStateOf(0) }

        fun finishInAppSignIn(signIn: () -> Unit) {
            signIn()
            val origin = signInOrigin
            showSignIn = false
            signInOrigin = null
            consumeForceOnboarding = true
            when (NavigationIa.afterSignIn(origin ?: NavigationIa.SignInOrigin.Profile)) {
                NavigationIa.AfterSignInLanding.TodayClearingStacks -> {
                    showSettings = false
                    showWelcomeReplay = false
                    tabsResetKey += 1
                }
                NavigationIa.AfterSignInLanding.StayOnSettings -> {
                    showSettings = true
                }
                NavigationIa.AfterSignInLanding.StayOnProfile -> Unit
            }
        }

        fun openPray(
            set: MysterySetKind,
            fromDebug: Boolean = false,
            isResume: Boolean = false,
            startingDecade: Int? = null,
        ) {
            val base = viewModel.settingsStore.current.rosaryConfig
            val config = base.copy(
                showBeads = if (debugLaunch.hideBeads) false else base.showBeads,
                saintMichael = debugLaunch.includeSaintMichael || base.saintMichael,
            )
            val decadeStep = startingDecade?.let { decade ->
                RosarySequenceBuilder.build(set, config)
                    .indexOfFirst { it.decadeNumber == decade }
                    .takeIf { it >= 0 }
            }
            prayLaunch = PrayLaunch(
                mysterySet = set,
                startStep = debugLaunch.prayStep ?: decadeStep,
                showIntentions = fromDebug && debugLaunch.showIntentions,
                showCompletion = fromDebug && debugLaunch.showCompletion,
                showSaintMichael = fromDebug && debugLaunch.showMichaelLayer,
                showCustomise = fromDebug && debugLaunch.showCustomise,
                forceFresh = startingDecade != null || (fromDebug && (
                    debugLaunch.forceFreshPray ||
                        debugLaunch.showCompletion ||
                        debugLaunch.showIntentions ||
                        debugLaunch.showMichaelLayer ||
                        debugLaunch.showCustomise
                    )),
                isResume = isResume,
                showReplaceDialog = fromDebug && debugLaunch.showReplaceDialog,
                config = config,
                completionQuoteId = debugLaunch.completionQuoteId,
                scrollPlateToEnd = fromDebug && debugLaunch.scrollPlateToEnd,
            )
        }

        LaunchedEffect(
            debugLaunch.openPray,
            debugLaunch.showIntentions,
            debugLaunch.showCompletion,
            debugLaunch.showMichaelLayer,
            debugLaunch.showCustomise,
            debugLaunch.showReplaceDialog,
            debugLaunch.prayStep,
            debugLaunch.nonce,
        ) {
            if (debugLaunch.openPray ||
                debugLaunch.showIntentions ||
                debugLaunch.showCompletion ||
                debugLaunch.showMichaelLayer ||
                debugLaunch.showCustomise ||
                debugLaunch.showReplaceDialog
            ) {
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
        ) && !forcingEntry
        val firstRunSignIn = (showSignIn || debugLaunch.forceSignIn) && !showsApp
        val inAppSignIn = showSignIn && showsApp

        Box(Modifier.fillMaxSize()) {
            if (showsApp) {
                androidx.compose.runtime.key(tabsResetKey) {
                AppTabs(
                    debugLaunch = debugLaunch,
                    today = today,
                    prayedDayKeys = prayedDayKeys,
                    hasAskedForNotifications = flags.askedForNotifications || debugLaunch.forceTabs,
                    onAskedForNotifications = viewModel::markAskedForNotifications,
                    onPray = { openPray(it) },
                    onResumePray = { openPray(it, isResume = true) },
                    onPrayDecade = { set, decade -> openPray(set, startingDecade = decade) },
                    onRemindMe = { viewModel.scheduleFeastReminder(it) },
                    onPrayWith = { intention ->
                        val set = MysteryCalendar.assignment(today).set
                        prayLaunch = PrayLaunch(
                            mysterySet = set,
                            seedIntentions = listOf(intention.id to intention.title),
                            config = viewModel.settingsStore.current.rosaryConfig,
                        )
                    },
                    sessionStore = viewModel.sessionStore,
                    isSignedIn = auth.isSignedIn,
                    onSignIn = {
                        signInOrigin = NavigationIa.SignInOrigin.Profile
                        showSignIn = true
                    },
                    onOpenSettings = {
                        settingsPage = SettingsPage.Root
                        showSettings = true
                    },
                    appearance = settings.appearance,
                    onAppearance = { viewModel.settingsStore.setAppearance(it) },
                )
                }
            } else if (firstRunSignIn) {
                SignInScreen(
                    onGoogle = {
                        // The Google sheet opens over this screen; it closes only once signed in.
                        viewModel.signInWithGoogle { signedIn ->
                            if (signedIn) {
                                showSignIn = false
                                signInOrigin = null
                                consumeForceOnboarding = true
                            }
                        }
                    },
                    onGuest = {
                        viewModel.continueAsGuest()
                        showSignIn = false
                        signInOrigin = null
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
                LaunchSplashScreen(onFinished = { showSplash = false }, hold = debugLaunch.holdSplash)
            }
            if (debugLaunch.holdSignInTransition) {
                SignInTransitionScreen(onSkip = { })
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
                    onSignOut = {
                        viewModel.signOut()
                        showSettings = false
                        showWelcomeReplay = false
                        showSignIn = false
                        prayLaunch = null
                    },
                    onReplayWelcome = {
                        showWelcomeReplay = true
                    },
                    onSignIn = {
                        signInOrigin = NavigationIa.SignInOrigin.Settings
                        showSignIn = true
                    },
                    onBack = { showSettings = false },
                    onDeleteAccount = { onFinished -> viewModel.deleteAccount(onFinished) },
                    onAccountDeleted = {
                        viewModel.finishAccountDeletion()
                        showSettings = false
                        showWelcomeReplay = false
                        showSignIn = false
                        prayLaunch = null
                    },
                    today = today,
                    earliestActivityEpochMs = listOfNotNull(
                        completed.minOfOrNull { it.startedAtEpochMs },
                        intentions.minOfOrNull { it.createdAtEpochMs },
                    ).minOrNull(),
                    modifier = Modifier.fillMaxSize(),
                )
            }

            if (showWelcomeReplay) {
                OnboardingScreen(
                    initialPage = 0,
                    onBegin = { showWelcomeReplay = false },
                )
            }

            if (inAppSignIn) {
                SignInScreen(
                    onGoogle = {
                        viewModel.signInWithGoogle { signedIn -> if (signedIn) finishInAppSignIn {} }
                    },
                    onGuest = { finishInAppSignIn { viewModel.continueAsGuest() } },
                    isSigningInWithGoogle = auth.isSigningInWithGoogle,
                    modifier = Modifier.fillMaxSize(),
                )
            }

            if (prayLaunch != null) {
                BackHandler { prayLaunch = null }
            }
            if (showWelcomeReplay) {
                BackHandler { showWelcomeReplay = false }
            }
            if (inAppSignIn) {
                BackHandler { showSignIn = false; signInOrigin = null }
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
    onResumePray: (MysterySetKind) -> Unit = onPray,
    onPrayDecade: (MysterySetKind, Int) -> Unit = { set, _ -> onPray(set) },
    onRemindMe: (DatedFeast) -> Unit = {},
    prayedDayKeys: Set<String> = emptySet(),
    onPrayWith: (OfferIntention) -> Unit = {},
    sessionStore: SessionStore,
    isSignedIn: Boolean = false,
    onSignIn: () -> Unit = {},
    onOpenSettings: () -> Unit = {},
    appearance: AppearancePreference = AppearancePreference.System,
    onAppearance: (AppearancePreference) -> Unit = {},
) {
    val navController = rememberNavController()
    val palette = LocalThemePalette.current
    val prayerSession by sessionStore.session.collectAsStateWithLifecycle()
    val resumeCta = prayerSession?.takeIf {
        it.isResumable(System.currentTimeMillis())
    }?.continueCTATitle()
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
            debugLaunch.openRosaryPrayers -> navController.navigate(RosaryPrayersRoute)
            debugLaunch.openAllPrayers -> navController.navigate(AllPrayersRoute)
            debugLaunch.openWalkthrough -> navController.navigate(LearnRoute)
            debugLaunch.articleId != null -> navController.navigate(ArticleRoute(debugLaunch.articleId))
            debugLaunch.prayerId != null -> navController.navigate(PrayerRoute(debugLaunch.prayerId))
            debugLaunch.mysterySet != null && !debugLaunch.openPray && !debugLaunch.showIntentions && !debugLaunch.showCompletion ->
                navController.navigate(MysterySetRoute(debugLaunch.mysterySet))
        }
    }

    val onToday = destination?.hierarchy?.any { it.hasRoute(TodayRoute::class) } == true
    val tabInsets = WindowInsets.safeDrawing.only(WindowInsetsSides.Horizontal).let { horizontal ->
        if (onToday) horizontal else horizontal.union(WindowInsets.safeDrawing.only(WindowInsetsSides.Top))
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(if (onToday) palette.groupedBackground else palette.bg)
            .windowInsetsPadding(tabInsets),
    ) {
        val reduceMotion = LocalReduceMotion.current
        // Tab floats over content, as on iOS. Clip only the 10 dp margin below the
        // capsule so a bottom CTA cannot peek out under the bar.
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = RosarySpace.tabBarBottomMargin)
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
                androidx.compose.runtime.key(
                    debugLaunch.nonce,
                    debugLaunch.openWeekFeastSheet,
                    debugLaunch.openMysteryDetailSheet,
                ) {
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
                        onResumePray = onResumePray,
                        onPrayDecade = onPrayDecade,
                        resumableCta = resumeCta,
                        openWeekFeastSheet = debugLaunch.openWeekFeastSheet,
                        openMysteryDetailSheet = debugLaunch.openMysteryDetailSheet,
                        debugNonce = debugLaunch.nonce,
                        appearance = appearance,
                        onAppearance = onAppearance,
                    )
                }
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
                    onResumeRosary = { onResumePray(MysteryCalendar.assignment(today).set) },
                    todaySetTitle = MysteryCalendar.assignment(today).set.titleText.english,
                    resumeCta = resumeCta,
                    startWalkthrough = debugLaunch.openWalkthrough,
                )
            }
            composable<FeastsRoute> {
                FeastsScreen(
                    today = today,
                    onFeastClick = { item ->
                        navController.navigate(FeastDetailRoute(item.feast.id, item.date.toString()))
                    },
                    onPray = onPray,
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
                val item = DatedFeast(feast, date)
                FeastDetailScreen(
                    item = item,
                    onPray = onPray,
                    onBack = { navController.popBackStack() },
                    onRemindMe = { onRemindMe(item) },
                    onOpenRelatedPrayers = {
                        navController.navigate(FeastRelatedPrayersRoute(feast.id, date.toString()))
                    },
                    onOpenPatronages = {
                        navController.navigate(FeastPatronagesRoute(feast.id, date.toString()))
                    },
                    onOpenScripture = {
                        navController.navigate(FeastScriptureRoute(feast.id, date.toString()))
                    },
                )
            }
            composable<FeastRelatedPrayersRoute> { entry ->
                val route = entry.toRoute<FeastRelatedPrayersRoute>()
                val feast = FeastCatalog.all.find { it.id == route.feastId } ?: return@composable
                val date = runCatching { LocalDate.parse(route.date) }.getOrDefault(today)
                FeastRelatedPrayersScreen(
                    item = DatedFeast(feast, date),
                    onBack = { navController.popBackStack() },
                )
            }
            composable<FeastPatronagesRoute> { entry ->
                val route = entry.toRoute<FeastPatronagesRoute>()
                val feast = FeastCatalog.all.find { it.id == route.feastId } ?: return@composable
                val date = runCatching { LocalDate.parse(route.date) }.getOrDefault(today)
                FeastPatronagesScreen(
                    item = DatedFeast(feast, date),
                    onBack = { navController.popBackStack() },
                )
            }
            composable<FeastScriptureRoute> { entry ->
                val route = entry.toRoute<FeastScriptureRoute>()
                val feast = FeastCatalog.all.find { it.id == route.feastId } ?: return@composable
                val date = runCatching { LocalDate.parse(route.date) }.getOrDefault(today)
                FeastScriptureScreen(
                    item = DatedFeast(feast, date),
                    onBack = { navController.popBackStack() },
                )
            }
            composable<HowToPrayRoute> {
                DetailScaffold(title = "How to pray", onBack = { navController.popBackStack() }) {
                    HowToPrayScreen()
                }
            }
            composable<RosaryPrayersRoute> {
                DetailScaffold(title = "Rosary prayers", onBack = { navController.popBackStack() }, ambient = true) {
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
                DetailScaffold(title = article.title, onBack = { navController.popBackStack() }, ambient = true) {
                    LearnArticleScreen(article)
                }
            }
            composable<PrayerRoute> { entry ->
                val route = entry.toRoute<PrayerRoute>()
                val prayer = PrayerCatalog.prayer(route.id) ?: return@composable
                DetailScaffold(title = "", onBack = { navController.popBackStack() }, ambient = true) {
                    PrayerReaderScreen(prayer)
                }
            }
            composable<MysterySetRoute> { entry ->
                val route = entry.toRoute<MysterySetRoute>()
                val set = runCatching { MysterySetKind.valueOf(route.set) }.getOrNull() ?: return@composable
                DetailScaffold(title = set.shortName, onBack = { navController.popBackStack() }, ambient = true) {
                    MysterySetScreen(set, onPray = onPray)
                }
            }
        }
        }
        val selectedIndex = tabs.indexOfFirst { tab ->
            destination?.hierarchy?.any { it.hasRoute(tab.route::class) } == true
        }.let { if (it < 0) 0 else it }
        val tabScrimColor = if (onToday) palette.groupedBackground else palette.bg
        GuideTabBarScrollEdgeScrim(
            color = tabScrimColor,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
        GuideTabBar(
            selectedIndex = selectedIndex,
            onSelected = { index ->
                val tab = tabs[index]
                navController.navigate(tab.route) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            },
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

@Composable
private fun DetailScaffold(
    title: String,
    onBack: () -> Unit,
    ambient: Boolean = false,
    content: @Composable () -> Unit,
) {
    val palette = LocalThemePalette.current
    Box(Modifier.fillMaxSize()) {
        if (ambient) AppPageBackground()
        else Box(Modifier.fillMaxSize().background(palette.bg))
        Column(Modifier.fillMaxSize()) {
            GuideDetailTopBar(
                title = title,
                onBack = onBack,
                containerColor = if (ambient) Color.Transparent else palette.bg,
            )
            Box(Modifier.weight(1f)) { content() }
        }
    }
}
