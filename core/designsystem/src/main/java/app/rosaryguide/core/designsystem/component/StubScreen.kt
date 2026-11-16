package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalRosaryColors
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun StubScreen(
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    extra: @Composable () -> Unit = {},
) {
    val colors = LocalRosaryColors.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.xl),
        verticalArrangement = Arrangement.Top,
    ) {
        Text(text = title, style = RosaryType.headingPrimary, color = colors.textPrimary)
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = subtitle, style = RosaryType.body, color = colors.textSecondary)
        Spacer(modifier = Modifier.height(RosarySpace.xl))
        extra()
    }
}
