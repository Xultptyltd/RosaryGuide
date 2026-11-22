package app.rosaryguide.android.parity

import android.view.View
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.data.launch.AppTab
import app.rosaryguide.core.designsystem.component.GuideGlassSurface
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

/**
 * Pixel 7 system chrome measured from approved Mac emulator captures
 * (1080×2400 @ 420 dpi, density 2.625).
 *
 * - Status bar inset: 138 px = 52.57 dp (appearance-chip top on today-light).
 *   System icons sit in the upper band (ink y = 51–84 px).
 * - Navigation bar inset: 24 dp (week-feast “Explore” sits 16 dp padding +
 *   24 dp inset = 40 dp from the bottom).
 * - Gesture pill: 108×4 dp, 10 dp from the bottom edge, #666 / light on dark.
 */
object Pixel7Chrome {
    val StatusBarHeight: Dp = 52.57.dp
    val NavigationBarHeight: Dp = 24.dp
    val GesturePillWidth: Dp = 108.dp
    val GesturePillHeight: Dp = 4.dp
    val GesturePillBottom: Dp = 10.dp
    const val WidthPx: Int = 1080
    const val HeightPx: Int = 2400
    const val DensityDpi: Int = 420
    const val Density: Float = 2.625f
}

fun pixel7WindowInsets(density: Float): WindowInsetsCompat {
    val statusPx = (Pixel7Chrome.StatusBarHeight.value * density).toInt()
    val navPx = (Pixel7Chrome.NavigationBarHeight.value * density).toInt()
    return WindowInsetsCompat.Builder()
        .setInsets(WindowInsetsCompat.Type.statusBars(), Insets.of(0, statusPx, 0, 0))
        .setInsets(WindowInsetsCompat.Type.navigationBars(), Insets.of(0, 0, 0, navPx))
        .setInsets(WindowInsetsCompat.Type.systemBars(), Insets.of(0, statusPx, 0, navPx))
        .setInsets(WindowInsetsCompat.Type.mandatorySystemGestures(), Insets.of(0, 0, 0, navPx))
        .setInsets(WindowInsetsCompat.Type.systemGestures(), Insets.of(0, 0, 0, navPx))
        .setInsets(WindowInsetsCompat.Type.tappableElement(), Insets.of(0, 0, 0, navPx))
        .setInsets(WindowInsetsCompat.Type.displayCutout(), Insets.of(0, 0, 0, 0))
        .setInsetsIgnoringVisibility(WindowInsetsCompat.Type.statusBars(), Insets.of(0, statusPx, 0, 0))
        .setInsetsIgnoringVisibility(WindowInsetsCompat.Type.navigationBars(), Insets.of(0, 0, 0, navPx))
        .setInsetsIgnoringVisibility(WindowInsetsCompat.Type.systemBars(), Insets.of(0, statusPx, 0, navPx))
        .build()
}

fun applyPixel7WindowInsets(view: View) {
    val insets = pixel7WindowInsets(view.resources.displayMetrics.density)

    // Compose ignores test-constructed WindowInsetsCompat unless this flag is on,
    // then it round-trips through the platform WindowInsets object.
    val companionClass = Class.forName("androidx.compose.foundation.layout.WindowInsetsHolder\$Companion")
    val holderClass = Class.forName("androidx.compose.foundation.layout.WindowInsetsHolder")
    val companion = holderClass.getField("Companion").get(null)
    companionClass.getMethod("setUseTestInsets", java.lang.Boolean.TYPE).invoke(companion, true)
    val holder = companionClass.getMethod("getOrCreateFor", View::class.java).invoke(companion, view)
    holderClass.getMethod("update", WindowInsetsCompat::class.java, java.lang.Integer.TYPE)
        .invoke(holder, insets, 0)

    var current: View? = view
    while (current != null) {
        ViewCompat.dispatchApplyWindowInsets(current, insets)
        current = current.parent as? View
    }
}

@Composable
fun Pixel7DeviceFrame(
    dark: Boolean,
    showStatusBar: Boolean = true,
    showTabBar: Boolean = false,
    selectedTab: AppTab = AppTab.Today,
    content: @Composable () -> Unit,
) {
    val view = LocalView.current
    val density = LocalDensity.current
    LaunchedEffect(view) {
        applyPixel7WindowInsets(view)
    }

    val palette = LocalThemePalette.current
    var tabClearance by remember { mutableStateOf(80.dp) }

    Box(modifier = Modifier.fillMaxSize().background(palette.bg)) {
        if (showTabBar) {
            content()
            ParityTabBar(
                selected = selectedTab,
                isDark = palette.isDark,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .onSizeChanged { size ->
                        if (size.height > 0) {
                            val measured = with(density) { size.height.toDp() + 10.dp + 16.dp }
                            if (measured > tabClearance) tabClearance = measured
                        }
                    },
            )
        } else {
            content()
        }

        if (showStatusBar) {
            StatusBarStrip(
                dark = dark,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(Pixel7Chrome.StatusBarHeight)
                    .align(Alignment.TopCenter),
            )
        }
        GesturePill(
            dark = dark,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = Pixel7Chrome.GesturePillBottom),
        )
    }
}

@Composable
private fun StatusBarStrip(dark: Boolean, modifier: Modifier = Modifier) {
    val ink = if (dark) Color.White else Color(0xFF1A1A1A)
    val style = TextStyle(
        fontSize = 14.sp,
        fontWeight = FontWeight.Medium,
        color = ink,
        letterSpacing = 0.sp,
        platformStyle = PlatformTextStyle(includeFontPadding = false),
    )
    Row(
        modifier = modifier.padding(start = 31.dp, end = 22.dp, top = 20.5.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text("9:41", style = style)
        Text("3G", style = style)
    }
}

@Composable
private fun GesturePill(dark: Boolean, modifier: Modifier = Modifier) {
    val color = if (dark) Color(0xFFEBEBEB) else Color(0xFF666666)
    Box(
        modifier = modifier
            .width(Pixel7Chrome.GesturePillWidth)
            .height(Pixel7Chrome.GesturePillHeight)
            .clip(RoundedCornerShape(percent = 50))
            .background(color),
    )
}

@Composable
private fun ParityTabBar(
    selected: AppTab,
    isDark: Boolean,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val tabs = listOf(
        AppTab.Today to (R.drawable.tab_today_filled to R.drawable.tab_today_outline),
        AppTab.Learn to (R.drawable.tab_learn_filled to R.drawable.tab_learn_outline),
        AppTab.Feasts to (R.drawable.tab_feasts_filled to R.drawable.tab_feasts_outline),
        AppTab.Profile to (R.drawable.tab_profile_filled to R.drawable.tab_profile_outline),
    )
    val tabShape = RoundedCornerShape(percent = 50)
    val tabMod = modifier
        .padding(start = 20.dp, end = 20.dp, bottom = 10.dp)
        .fillMaxWidth()
        .then(if (isDark) Modifier else Modifier.shadow(16.dp, tabShape, clip = false))
        .clip(tabShape)
        .background(if (isDark) Color.White.copy(alpha = 0.16f) else Color.White.copy(alpha = 0.96f))
        .border(
            width = 0.5.dp,
            color = if (isDark) Color.White.copy(alpha = 0.28f) else Color.Black.copy(alpha = 0.08f),
            shape = tabShape,
        )
    Box(tabMod) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            tabs.forEach { (tab, icons) ->
                val isSelected = tab == selected
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(percent = 50))
                        .background(
                            if (isSelected && !isDark) palette.groupedBackground
                            else Color.Transparent,
                        )
                        .padding(vertical = RosarySpace.sm),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Icon(
                        painter = painterResource(if (isSelected) icons.first else icons.second),
                        contentDescription = tab.title,
                        tint = if (isSelected) palette.tabSelected else palette.textSecondary,
                    )
                    Text(
                        text = tab.title,
                        style = RosaryType.caption.copy(fontSize = 12.sp),
                        color = if (isSelected) palette.tabSelected else palette.textSecondary,
                    )
                }
            }
        }
    }
}
