package app.rosaryguide.feature.pray

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.airbnb.lottie.LottieCompositionFactory
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieClipSpec
import com.airbnb.lottie.compose.animateLottieCompositionAsState

/**
 * Native player for the bundled `RosaryTick.json` composition, ported from
 * iOS `RosaryTickPlayer`. The tick stroke finishes at frame 70 of 96; the
 * hold frame (82/96) keeps the tick on screen for the completion slot.
 */
@Composable
fun RosaryTickPlayer(
    modifier: Modifier = Modifier,
    size: Dp = 88.dp,
    plays: Boolean = true,
    onComplete: () -> Unit = {},
) {
    val context = LocalContext.current
    val composition = remember(context) {
        LottieCompositionFactory.fromAssetSync(context, "RosaryTick.json").value
    }
    val hold = HOLD_PROGRESS
    val progress = animateLottieCompositionAsState(
        composition = composition,
        isPlaying = plays && composition != null,
        iterations = 1,
        clipSpec = LottieClipSpec.Progress(0f, hold),
        speed = 1f,
    )
    LottieAnimation(
        composition = composition,
        progress = { if (plays) progress.progress else hold },
        modifier = modifier.size(size),
    )
    LaunchedEffect(plays, progress.isAtEnd, composition) {
        if (plays && progress.isAtEnd && composition != null) onComplete()
    }
}

internal const val HOLD_PROGRESS = 82f / 96f
