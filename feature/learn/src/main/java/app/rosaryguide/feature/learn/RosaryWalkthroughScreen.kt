package app.rosaryguide.feature.learn

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
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
        image = R.drawable.mystery_01_annunciation,
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

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        Column(Modifier.fillMaxSize().navigationBarsPadding()) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f).fillMaxWidth(),
            ) { index ->
                val page = pages[index]
                Column(Modifier.fillMaxSize()) {
                    Image(
                        painter = painterResource(page.image),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                    )
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = RosarySpace.gutter)
                            .padding(top = RosarySpace.lg, bottom = RosarySpace.md),
                    ) {
                        Text(page.title, style = RosaryType.headingSecondary, color = palette.ink)
                        Spacer(Modifier.height(RosarySpace.sm))
                        Text(page.body, style = RosaryType.body, color = palette.dim)
                    }
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.xl),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(bottom = RosarySpace.lg),
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
                GuidePrimaryButton(title = if (isLast) "Begin Rosary" else "Continue") {
                    if (isLast) onBegin()
                    else scope.launch {
                        if (reduceMotion) pagerState.scrollToPage(pagerState.currentPage + 1)
                        else pagerState.animateScrollToPage(pagerState.currentPage + 1)
                    }
                }
                if (isLast) {
                    TextButton(onClick = onClose) {
                        Text("Done", style = RosaryType.body, color = palette.accentText)
                    }
                }
            }
        }
        IconButton(
            onClick = onClose,
            modifier = Modifier
                .statusBarsPadding()
                .align(Alignment.TopEnd)
                .padding(RosarySpace.sm),
        ) {
            Icon(Icons.Filled.Close, contentDescription = "Close guide", tint = palette.ink)
        }
    }
}
