package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

data class GuideTabItem(
    val title: String,
    val selectedIcon: Int,
    val unselectedIcon: Int,
)

/** The four root tabs, with the same filled / outline assets the app ships. */
val GuideTabs = listOf(
    GuideTabItem("Today", R.drawable.tab_today_filled, R.drawable.tab_today_outline),
    GuideTabItem("Learn", R.drawable.tab_learn_filled, R.drawable.tab_learn_outline),
    GuideTabItem("Feasts", R.drawable.tab_feasts_filled, R.drawable.tab_feasts_outline),
    GuideTabItem("Profile", R.drawable.tab_profile_filled, R.drawable.tab_profile_outline),
)

/**
 * Floating iOS-style tab capsule. There is no backdrop blur, so the fill is
 * opaque enough that scrolling content behind it doesn't read as clutter.
 */
@Composable
fun GuideTabBar(
    selectedIndex: Int,
    onSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    items: List<GuideTabItem> = GuideTabs,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(percent = 50)
    val fill = if (palette.isDark) Color(0xF21C1C1E) else Color.White.copy(alpha = 0.96f)
    val hairline = if (palette.isDark) Color.White.copy(alpha = 0.20f) else Color.Black.copy(alpha = 0.08f)
    Row(
        modifier = modifier
            .padding(
                start = RosarySpace.tabBarSideMargin,
                end = RosarySpace.tabBarSideMargin,
                bottom = RosarySpace.tabBarBottomMargin,
            )
            .fillMaxWidth()
            .shadow(16.dp, shape, clip = false)
            .clip(shape)
            .background(fill)
            .border(0.5.dp, hairline, shape)
            .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        items.forEachIndexed { index, item ->
            val selected = index == selectedIndex
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(
                        when {
                            selected && palette.isDark -> Color.White.copy(alpha = 0.12f)
                            selected -> palette.groupedBackground
                            else -> Color.Transparent
                        },
                    )
                    .clickable { onSelected(index) }
                    .padding(vertical = RosarySpace.sm),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(
                    painter = painterResource(if (selected) item.selectedIcon else item.unselectedIcon),
                    contentDescription = item.title,
                    tint = if (selected) palette.tabSelected else palette.textSecondary,
                )
                Text(
                    text = item.title,
                    style = RosaryType.caption.copy(fontSize = 12.sp),
                    color = if (selected) palette.tabSelected else palette.textSecondary,
                )
            }
        }
    }
}
