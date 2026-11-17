package app.rosaryguide.feature.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import app.rosaryguide.core.designsystem.theme.LocalThemePalette

/**
 * Plain page-colour hold that follows a successful sign-in, ported from iOS
 * `SignInTransitionCover`. A tap skips the hold.
 */
@Composable
fun SignInTransitionScreen(
    onSkip: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(palette.background)
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = onSkip,
            )
            .semantics { contentDescription = "Sign-in transition" },
    )
}
