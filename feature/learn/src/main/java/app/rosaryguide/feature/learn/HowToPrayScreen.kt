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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.HowToPrayContent
import app.rosaryguide.core.data.catalog.LearnCopy
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideScreenHeader
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

private val walkthroughImages = listOf(
    R.drawable.walkthrough_rosary_intro,
    R.drawable.walkthrough_rosary_decade,
    R.drawable.walkthrough_rosary_structure,
    R.drawable.walkthrough_mary,
)

@Composable
fun HowToPrayScreen(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    val pagerState = rememberPagerState { walkthroughImages.size }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(bottom = RosarySpace.xxl),
    ) {
        GuideScreenHeader(
            title = LearnCopy.HOW_TO_PRAY_TITLE,
            modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg),
        )
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp)
                .padding(horizontal = RosarySpace.gutter),
        ) { index ->
            Image(
                painter = painterResource(walkthroughImages[index]),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(RosarySpace.featureRadius)),
            )
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = RosarySpace.sm),
            horizontalArrangement = Arrangement.Center,
        ) {
            walkthroughImages.forEachIndexed { i, _ ->
                Box(
                    modifier = Modifier
                        .padding(horizontal = 3.dp)
                        .size(7.dp)
                        .clip(CircleShape)
                        .background(if (i == pagerState.currentPage) palette.ink else palette.strokeStrong),
                )
            }
        }
        Text(
            text = HowToPrayContent.introduction.english,
            style = RosaryType.serifBody,
            color = palette.ink,
            modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.md),
        )
        HowToPrayContent.steps.forEach { step ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.sm),
            ) {
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(palette.stepNumberFill),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(text = step.id.toString(), style = RosaryType.caption, color = palette.stepNumberText)
                }
                Column(Modifier.padding(start = RosarySpace.md)) {
                    Text(text = step.title.english, style = RosaryType.body, color = palette.ink)
                    Spacer(Modifier.height(4.dp))
                    Text(text = step.body, style = RosaryType.supportingLabel, color = palette.dim)
                }
            }
        }
        Text(
            text = "Which mysteries by day",
            style = RosaryType.headingSecondary,
            color = palette.ink,
            modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.md),
        )
        HowToPrayContent.weekdayGuide.forEach { (day, set) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.xs),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(text = day, style = RosaryType.body, color = palette.ink)
                Text(text = set, style = RosaryType.body, color = palette.dim)
            }
        }
        Text(
            text = HowToPrayContent.beadsNote,
            style = RosaryType.supportingLabel,
            color = palette.dim,
            modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.lg),
        )
    }
}
