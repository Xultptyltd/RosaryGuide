package app.rosaryguide.feature.onboarding

import android.app.Activity
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import app.rosaryguide.core.data.catalog.OnboardingCopy
import app.rosaryguide.core.data.catalog.OnboardingPage
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import kotlinx.coroutines.launch

@Composable
fun OnboardingScreen(
    onBegin: () -> Unit,
    modifier: Modifier = Modifier,
    initialPage: Int = 0,
) {
    val palette = LocalThemePalette.current
    val pages = OnboardingPage.pages
    val pagerState = rememberPagerState(initialPage = initialPage.coerceIn(0, pages.lastIndex)) { pages.size }
    val scope = rememberCoroutineScope()
    val reduceMotion = LocalReduceMotion.current

    HideStatusBarInLightMode()

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        // Full window height from y=0, matching iOS SignInLayout.panelHeight (0.5 when height ≥ 820).
        val panelHeight = RosarySpace.signInPanelHeight(maxHeight)
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
        ) { index ->
            OnboardingPageBody(
                page = pages[index],
                panelHeight = panelHeight,
            )
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(RosarySpace.lg),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                pages.forEachIndexed { i, _ ->
                    val active = i == pagerState.currentPage
                    Box(
                        modifier = Modifier
                            .size(if (active) 8.dp else 7.dp)
                            .clip(CircleShape)
                            .background(if (active) palette.ink else palette.strokeStrong),
                    )
                }
            }
            val isLast = pagerState.currentPage == pages.lastIndex
            GuidePrimaryButton(title = if (isLast) OnboardingCopy.BEGIN else OnboardingCopy.CONTINUE) {
                if (isLast) {
                    onBegin()
                } else {
                    scope.launch {
                        if (reduceMotion) pagerState.scrollToPage(pagerState.currentPage + 1)
                        else pagerState.animateScrollToPage(pagerState.currentPage + 1)
                    }
                }
            }
        }
    }
}

@Composable
private fun OnboardingPageBody(
    page: OnboardingPage,
    panelHeight: Dp,
) {
    val palette = LocalThemePalette.current
    val image = when (page.imageName) {
        "OnboardingRosaryDaily" -> R.drawable.onboarding_rosary_daily
        "OnboardingBeads" -> R.drawable.onboarding_beads
        else -> R.drawable.onboarding_intentions
    }
    val alignment = if (page.imageAlignment == "center") Alignment.Center else Alignment.TopCenter
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(panelHeight)
                .padding(horizontal = RosarySpace.panelInset)
                .clip(
                    RoundedCornerShape(
                        bottomStart = RosarySpace.panelRadius,
                        bottomEnd = RosarySpace.panelRadius,
                    ),
                )
                .background(Color.Black),
        ) {
            Image(
                painter = painterResource(image),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                alignment = alignment,
                modifier = Modifier.fillMaxSize(),
            )
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = page.title,
                style = RosaryType.headingPrimary.copy(lineHeight = 34.sp),
                color = palette.ink,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(RosarySpace.lg))
            Text(
                text = page.body,
                style = RosaryType.body.copy(lineHeight = 21.sp),
                color = palette.dim,
                textAlign = TextAlign.Center,
            )
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Spacer(Modifier.height(RosarySpace.onboardingFooterClearance))
    }
}

@Composable
private fun HideStatusBarInLightMode() {
    val palette = LocalThemePalette.current
    val view = LocalView.current
    DisposableEffect(palette.isDark, view) {
        val window = (view.context as? Activity)?.window
        if (window == null) {
            return@DisposableEffect onDispose { }
        }
        val controller = WindowCompat.getInsetsController(window, view)
        val previousAppearance = controller.isAppearanceLightStatusBars
        val previousBehavior = controller.systemBarsBehavior
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        if (!palette.isDark) {
            controller.hide(WindowInsetsCompat.Type.statusBars())
        } else {
            controller.show(WindowInsetsCompat.Type.statusBars())
            controller.isAppearanceLightStatusBars = false
        }
        onDispose {
            controller.systemBarsBehavior = previousBehavior
            controller.show(WindowInsetsCompat.Type.statusBars())
            controller.isAppearanceLightStatusBars = previousAppearance
        }
    }
}
