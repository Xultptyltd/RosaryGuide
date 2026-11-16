package app.rosaryguide.feature.profile

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.StubScreen
import app.rosaryguide.core.designsystem.theme.LocalRosaryColors
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun ProfileStubScreen(modifier: Modifier = Modifier) {
    val colors = LocalRosaryColors.current
    StubScreen(
        title = "Profile",
        subtitle = "Intentions, journey, and rhythm will live here (M4). Account sync lands in M5.",
        modifier = modifier,
    ) {
        Text(
            text = "Sign in",
            style = RosaryType.headingSecondary,
            color = colors.textPrimary,
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "You can continue as a guest, or sign in with Google to restore a Rosary Guide account. Sign in with Apple is not offered on Android.",
            style = RosaryType.body,
            color = colors.textSecondary,
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Continue with Google  ·  Continue as guest",
            style = RosaryType.caption,
            color = colors.accentText,
        )
    }
}
