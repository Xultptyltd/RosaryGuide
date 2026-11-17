package app.rosaryguide.feature.onboarding

import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.airbnb.lottie.LottieCompositionFactory
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.animateLottieCompositionAsState

/**
 * Sign-in hero animation, ported from iOS `RosaryBeadsFallPlayer`.
 * The composition is 600×680; frame 0 and the last frame (1584) are identical
 * so the loop is seamless. Reduce Motion holds the settled last frame.
 */
@Composable
fun RosaryBeadsFallPlayer(
    modifier: Modifier = Modifier,
    plays: Boolean = true,
) {
    val context = LocalContext.current
    val composition = remember(context) {
        LottieCompositionFactory.fromAssetSync(context, "RosaryBeadsFall.json").value
    }
    val progress = animateLottieCompositionAsState(
        composition = composition,
        isPlaying = plays && composition != null,
        iterations = LottieConstants.IterateForever,
        speed = 1f,
    )
    LottieAnimation(
        composition = composition,
        progress = { if (plays) progress.progress else 1f },
        modifier = modifier.aspectRatio(ASPECT_RATIO),
    )
}

private const val ASPECT_RATIO = 600f / 680f
