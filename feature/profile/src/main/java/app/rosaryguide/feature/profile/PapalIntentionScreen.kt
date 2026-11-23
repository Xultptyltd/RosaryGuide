package app.rosaryguide.feature.profile

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.journey.PopeMonthIntention
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun PapalIntentionScreen(
    pope: PopeMonthIntention,
    alreadyAdded: Boolean,
    onBack: () -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var added by remember { mutableStateOf(alreadyAdded) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
    ) {
        GuideDetailTopBar(title = "Holy Father’s intention", onBack = onBack)
        Column(Modifier.padding(horizontal = RosarySpace.gutter).padding(bottom = RosarySpace.xl)) {
            Image(
                painter = painterResource(R.drawable.pope_leo_wide),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(1.3f)
                    .clip(RoundedCornerShape(RosarySpace.containerRadius)),
            )
            Spacer(Modifier.height(RosarySpace.lg))
            Text(
                text = pope.monthLabel().uppercase(),
                style = RosaryType.captionPray,
                color = palette.dim,
            )
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = pope.title, style = RosaryType.headingSecondaryPray, color = palette.ink)
            pope.note?.let {
                Spacer(Modifier.height(RosarySpace.lg))
                Text(text = it, style = RosaryType.bodyPray, color = palette.ink)
            }
            Spacer(Modifier.height(RosarySpace.xl))
            if (added) {
                GuideSecondaryButton(title = "Done", onClick = onBack)
            } else {
                GuidePrimaryButton(
                    title = "Add to my intentions",
                    onClick = {
                        onAdd()
                        added = true
                    },
                )
            }
        }
    }
}
