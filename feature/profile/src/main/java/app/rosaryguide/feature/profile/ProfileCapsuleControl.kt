package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosaryType

/**
 * 44 dp capsule matching iOS `GuideChoiceControl` / `segmentedControlHeight`,
 * with the emphasis thumb/title colours used on Journey and the intention editor.
 */
@Composable
fun ProfileCapsuleControl(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val track = if (palette.isDark) Color(0xFF2C2C2E) else palette.cardSurface(PageStyle.Plain)
    val thumb = palette.emphasisSegmentThumb
    val cap = RoundedCornerShape(percent = 50)
    val index = selectedIndex.coerceIn(0, (options.size - 1).coerceAtLeast(0))
    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(44.dp)
            .background(track, cap),
    ) {
        val inset = 2.dp
        val thumbWidth = (maxWidth - inset * 2) / options.size.coerceAtLeast(1)
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .padding(start = inset + thumbWidth * index, top = inset, bottom = inset)
                .width(thumbWidth)
                .height(40.dp)
                .shadow(1.5.dp, cap, clip = false)
                .background(thumb, cap),
        )
        Row(
            Modifier
                .fillMaxWidth()
                .fillMaxHeight(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            options.forEachIndexed { i, option ->
                val selected = i == index
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable { onSelect(i) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = option,
                        style = RosaryType.segmentedControlPray,
                        color = if (selected) palette.emphasisSegmentTitle else palette.dim,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}
