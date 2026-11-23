package app.rosaryguide.feature.settings

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.AppIconOption
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon

@Composable
fun AppIconScreen(
    selected: AppIconOption,
    onSelect: (AppIconOption) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "App icon", onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                painter = painterResource(previewOf(selected)),
                contentDescription = selected.title,
                modifier = Modifier
                    .size(96.dp)
                    .clip(RoundedCornerShape(22.dp)),
            )
            Spacer(Modifier.height(RosarySpace.xl))
            Text(
                text = "Available",
                style = RosaryType.supportingLabelPray,
                color = palette.dim,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = RosarySpace.sm),
            )
            AppIconOption.entries.forEach { option ->
                val isOn = option == selected
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(shape)
                        .background(palette.surface)
                        .then(
                            if (isOn) Modifier.border(2.dp, palette.accent, shape) else Modifier,
                        )
                        .clickable { onSelect(option) }
                        .padding(RosarySpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Image(
                        painter = painterResource(previewOf(option)),
                        contentDescription = null,
                        modifier = Modifier
                            .size(48.dp)
                            .clip(RoundedCornerShape(12.dp)),
                    )
                    Text(
                        text = option.title,
                        style = RosaryType.bodyPray,
                        color = palette.ink,
                        modifier = Modifier
                            .weight(1f)
                            .padding(start = RosarySpace.md),
                    )
                    if (isOn) {
                        Icon(
                            imageVector = Icons.Filled.Check,
                            contentDescription = "Selected",
                            tint = palette.accent,
                            modifier = Modifier.size(22.dp),
                        )
                    }
                }
                Spacer(Modifier.height(RosarySpace.sm))
            }
        }
    }
}

private fun previewOf(option: AppIconOption): Int = when (option) {
    AppIconOption.Blue -> R.drawable.icon_preview_blue
    AppIconOption.Black -> R.drawable.icon_preview_black
    AppIconOption.White -> R.drawable.icon_preview_white
}
