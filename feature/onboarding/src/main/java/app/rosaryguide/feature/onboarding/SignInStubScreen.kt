package app.rosaryguide.feature.onboarding

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalRosaryColors
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

/**
 * M0 / M2 placeholder for the sign-in step.
 *
 * Android v1 is Google Sign-In and continue-as-guest only. There is no
 * Sign in with Apple button on Android (confirmed 16 November 2026).
 */
@Composable
fun SignInStubScreen(
    modifier: Modifier = Modifier,
    onContinueAsGuest: () -> Unit = {},
    onSignInWithGoogle: () -> Unit = {},
) {
    val colors = LocalRosaryColors.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.xl),
        verticalArrangement = Arrangement.Top,
    ) {
        Text(
            text = "Begin",
            style = RosaryType.headingPrimary,
            color = colors.textPrimary,
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Pray as a guest, or sign in with Google to sync with an existing Rosary Guide account. Sign in with Apple is not available on Android.",
            style = RosaryType.body,
            color = colors.textSecondary,
        )
        Spacer(modifier = Modifier.height(RosarySpace.xl))
        Button(
            onClick = onSignInWithGoogle,
            modifier = Modifier
                .fillMaxWidth()
                .height(RosarySpace.pillHeight),
            shape = RoundedCornerShape(RosarySpace.pillHeight / 2),
            colors = ButtonDefaults.buttonColors(
                containerColor = colors.googleButtonFill,
                contentColor = colors.googleButtonText,
            ),
            border = BorderStroke(1.dp, colors.googleButtonStroke),
        ) {
            Text(text = "Continue with Google", style = RosaryType.body)
        }
        Spacer(modifier = Modifier.height(RosarySpace.md))
        OutlinedButton(
            onClick = onContinueAsGuest,
            modifier = Modifier
                .fillMaxWidth()
                .height(RosarySpace.pillHeight),
            shape = RoundedCornerShape(RosarySpace.pillHeight / 2),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
            border = BorderStroke(1.dp, colors.textPrimary.copy(alpha = 0.28f)),
        ) {
            Text(text = "Continue as guest", style = RosaryType.body)
        }
    }
}
