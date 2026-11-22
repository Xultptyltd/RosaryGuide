package app.rosaryguide.feature.learn

import android.app.Activity
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import kotlinx.coroutines.launch

private data class WalkthroughPage(
    val title: String,
    val body: String,
    val image: Int,
    val centerCrop: Boolean = true,
)

private val walkthroughPages = listOf(
    WalkthroughPage(
        title = "What is the Rosary?",
        body = "The Rosary is a way to draw closer to God through prayer and reflection on the life of Jesus, with Mary. You don’t need to know the prayers—we’ll guide you.",
        image = R.drawable.walkthrough_rosary_intro,
    ),
    WalkthroughPage(
        title = "A moment to reflect",
        body = "Each “mystery” is a moment in the lives of Jesus and Mary. For example, imagine Mary hearing that she will become Jesus’ mother. As you pray, think about trusting God when life feels uncertain.",
        // iOS `MysteryJoyful` (Madonna and Child). Default alignment is `.top`.
        image = R.drawable.walkthrough_mystery_joyful,
        centerCrop = false,
    ),
    WalkthroughPage(
        title = "One decade at a time",
        body = "A decade is a group of ten Hail Marys, beginning with an Our Father and ending with a Glory Be. While you say these prayers, reflect on one mystery.",
        image = R.drawable.walkthrough_rosary_decade,
    ),
    WalkthroughPage(
        title = "Start with a little time",
        body = "You can begin with just one decade. Take your time, and if your mind wanders, gently return to prayer. You don’t need to do it perfectly.",
        image = R.drawable.walkthrough_rosary_structure,
    ),
    WalkthroughPage(
        title = "We’ll guide you",
        body = "No rosary beads or memorised prayers needed. We’ll show you every prayer and mystery, one step at a time. Begin with the opening prayers, then follow along at your own pace.",
        image = R.drawable.walkthrough_mary,
        centerCrop = false,
    ),
)

@Composable
fun RosaryWalkthroughScreen(
    onClose: () -> Unit,
    onBegin: () -> Unit,
    modifier: Modifier = Modifier,
    initialPage: Int = 0,
) {
    val palette = LocalThemePalette.current
    val pages = walkthroughPages
    val pagerState = rememberPagerState(initialPage = initialPage.coerceIn(0, pages.lastIndex)) { pages.size }
    val scope = rememberCoroutineScope()
    val reduceMotion = LocalReduceMotion.current

    // iOS: `.statusBarHidden(palette.scheme == .light)` — art runs under the
    // bar, so light mode hides the dark icons; dark mode shows them.
    HideStatusBarInLightMode()

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        // iOS `SignInLayout.panelHeight` of the full window, including insets.
        val panelHeight = RosarySpace.signInPanelHeight(maxHeight)
        val statusTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
        // iOS OnboardingPanel top fade: `safeAreaInsets.top + Space.xl`.
        val fadeHeight = statusTop + RosarySpace.xl
        val isLast = pagerState.currentPage == pages.lastIndex
        // iOS `footerClearance`: controlsHeight + Space.xl, taller on the last page.
        val footerClearance = if (isLast) {
            RosarySpace.onboardingFooterClearance + RosarySpace.minHitTarget + RosarySpace.sm
        } else {
            RosarySpace.onboardingFooterClearance
        }

        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
        ) { index ->
            val page = pages[index]
            Column(
                Modifier.fillMaxSize(),
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
                        painter = painterResource(page.image),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        alignment = if (page.centerCrop) Alignment.Center else Alignment.TopCenter,
                        modifier = Modifier
                            .fillMaxSize()
                            .then(
                                if (reduceMotion) Modifier
                                else Modifier.graphicsLayer {
                                    scaleX = 1.018f
                                    scaleY = 1.018f
                                },
                            ),
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(fadeHeight)
                            .align(Alignment.TopCenter)
                            .background(
                                Brush.verticalGradient(
                                    0.00f to Color.Black,
                                    0.40f to Color.Black,
                                    1.00f to Color.Transparent,
                                ),
                            ),
                    )
                }
                // iOS: Spacer(minLength: Space.lg), text centered in the remaining
                // space, Spacer(minLength: Space.lg), then footerClearance.
                Spacer(Modifier.height(RosarySpace.lg))
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = RosarySpace.gutter),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Text(
                        page.title,
                        style = RosaryType.headingPrimaryWalkthrough,
                        color = palette.ink,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(RosarySpace.lg))
                    Text(
                        page.body,
                        style = RosaryType.themeSummary,
                        color = palette.dim,
                        textAlign = TextAlign.Center,
                    )
                }
                Spacer(Modifier.height(RosarySpace.lg))
                Spacer(Modifier.height(footerClearance))
            }
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // iOS OnboardingDots: active capsule 18×6, inactive 6×6, spacing Space.sm.
            Row(
                horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = RosarySpace.lg),
            ) {
                pages.forEachIndexed { i, _ ->
                    val active = i == pagerState.currentPage
                    Box(
                        modifier = Modifier
                            .width(if (active) 18.dp else 6.dp)
                            .height(6.dp)
                            .clip(RoundedCornerShape(percent = 50))
                            .background(if (active) palette.ink else palette.strokeStrong),
                    )
                }
            }
            GuidePrimaryButton(title = if (isLast) "Begin Rosary" else "Continue") {
                if (isLast) onBegin()
                else scope.launch {
                    if (reduceMotion) pagerState.scrollToPage(pagerState.currentPage + 1)
                    else pagerState.animateScrollToPage(pagerState.currentPage + 1)
                }
            }
            if (isLast) {
                TextButton(onClick = onClose) {
                    Text("Done", style = RosaryType.bodyPray, color = palette.accentText)
                }
            }
        }

        // iOS close: 13 pt semibold xmark in a 40 pt `guideFloatingGlass` circle,
        // 48 pt hit target, padded `gutter + Space.sm` from the trailing edge
        // and `Space.xs` below the safe area.
        // Dark: iOS `guideFloatingGlass` / `.regularMaterial` is a visible grey
        // milky chip. A white veil (even at 0.28–0.32) lightens the cream
        // sculpture and disappears; a mid-grey 0.60 fill matches the sampled
        // iOS colour on marble (~#8F8988) and still reads as a filled disk
        // on the black panel (~#3B3B3D).
        val closeFill = if (palette.isDark) Color(0xFF636366).copy(alpha = 0.60f) else Color(0xFFF4F4F5)
        val closeStroke = if (palette.isDark) Color.White.copy(alpha = 0.28f) else Color.Black.copy(alpha = 0.08f)
        Box(
            modifier = Modifier
                .statusBarsPadding()
                .align(Alignment.TopEnd)
                .padding(
                    end = RosarySpace.gutter + RosarySpace.sm,
                    top = RosarySpace.xs,
                )
                .size(RosarySpace.minHitTarget)
                .semantics {
                    role = Role.Button
                    contentDescription = "Close guide"
                }
                .clickable(onClick = onClose),
            contentAlignment = Alignment.Center,
        ) {
            Box(
                modifier = Modifier
                    .size(RosarySpace.controlSize)
                    .shadow(2.dp, CircleShape, clip = false)
                    .background(closeFill, CircleShape)
                    .border(Hairline.thickness, closeStroke, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = null,
                    tint = palette.ink,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
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
