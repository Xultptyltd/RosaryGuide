package app.rosaryguide.android.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DateRange
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.rounded.DateRange
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.sp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import app.rosaryguide.core.designsystem.theme.LocalRosaryColors
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.feature.feasts.FeastsStubScreen
import app.rosaryguide.feature.learn.LearnStubScreen
import app.rosaryguide.feature.profile.ProfileStubScreen
import app.rosaryguide.feature.today.TodayStubScreen
import kotlinx.serialization.Serializable

@Serializable
data object TodayRoute

@Serializable
data object LearnRoute

@Serializable
data object FeastsRoute

@Serializable
data object ProfileRoute

private data class TabSpec(
    val route: Any,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val routeClass: String,
)

private val tabs = listOf(
    TabSpec(TodayRoute, "Today", Icons.Rounded.Home, Icons.Outlined.Home, TodayRoute::class.qualifiedName!!),
    TabSpec(LearnRoute, "Learn", Icons.Rounded.Info, Icons.Outlined.Info, LearnRoute::class.qualifiedName!!),
    TabSpec(FeastsRoute, "Feasts", Icons.Rounded.DateRange, Icons.Outlined.DateRange, FeastsRoute::class.qualifiedName!!),
    TabSpec(ProfileRoute, "Profile", Icons.Rounded.Person, Icons.Outlined.Person, ProfileRoute::class.qualifiedName!!),
)

@Composable
fun RosaryGuideApp() {
    val navController = rememberNavController()
    val colors = LocalRosaryColors.current
    val backStackEntry by navController.currentBackStackEntryAsState()
    val destination = backStackEntry?.destination

    Scaffold(
        containerColor = colors.background,
        bottomBar = {
            NavigationBar(containerColor = colors.groupedBackground) {
                tabs.forEach { tab ->
                    val selected = destination?.hierarchy?.any { it.route == tab.routeClass } == true
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
                                imageVector = if (selected) tab.selectedIcon else tab.unselectedIcon,
                                contentDescription = tab.label,
                            )
                        },
                        label = {
                            Text(
                                text = tab.label,
                                style = RosaryType.caption.copy(fontSize = 12.sp),
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = colors.accentText,
                            selectedTextColor = colors.accentText,
                            unselectedIconColor = colors.textSecondary,
                            unselectedTextColor = colors.textSecondary,
                            indicatorColor = colors.accent.copy(alpha = 0.12f),
                        ),
                    )
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = TodayRoute,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable<TodayRoute> { TodayStubScreen() }
            composable<LearnRoute> { LearnStubScreen() }
            composable<FeastsRoute> { FeastsStubScreen() }
            composable<ProfileRoute> { ProfileStubScreen() }
        }
    }
}
