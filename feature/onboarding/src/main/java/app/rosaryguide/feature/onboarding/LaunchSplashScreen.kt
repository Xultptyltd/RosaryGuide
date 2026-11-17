package app.rosaryguide.feature.onboarding

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.RosaryHex
import app.rosaryguide.core.designsystem.theme.RosaryType
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.LottieCompositionFactory
import com.airbnb.lottie.compose.animateLottieCompositionAsState
import kotlinx.coroutines.delay

/** Marian blue canvas. Lottie plays at 1.4×; Reduce Motion shows a serif “R” and finishes at 0.8s. */
private val MarianBlue = Color(RosaryHex.MarianBlue)
private const val REDUCE_MOTION_MS = 800L
private const val COMPOSITION_WAIT_MS = 2_000L
private const val PLAY_CAP_MS = 6_000L

@Composable
fun LaunchSplashScreen(
    onFinished: () -> Unit,
    modifier: Modifier = Modifier,
    previewProgress: Float? = null,
    hold: Boolean = false,
) {
    val reduceMotion = LocalReduceMotion.current && previewProgress == null
    val context = LocalContext.current
    val composition = remember(context) {
        LottieCompositionFactory.fromAssetSync(context, "rosary_loader_intro_dark.json").value
    }
    val progress = animateLottieCompositionAsState(
        composition = composition,
        iterations = 1,
        isPlaying = !reduceMotion && composition != null,
        speed = 1.4f,
        restartOnPlay = false,
    )
    var finished by remember { mutableStateOf(false) }
    fun finish() {
        if (previewProgress != null || hold) return
        if (!finished) {
            finished = true
            onFinished()
        }
    }

    LaunchedEffect(reduceMotion, composition, progress.isAtEnd, progress.progress) {
        if (reduceMotion) {
            delay(REDUCE_MOTION_MS)
            finish()
            return@LaunchedEffect
        }
        if (composition == null) {
            delay(COMPOSITION_WAIT_MS)
            if (composition == null) {
                // Asset failed to load — hold the Marian-blue canvas briefly, then continue.
                delay(1_200)
                finish()
            }
            return@LaunchedEffect
        }
        if (progress.isAtEnd && progress.progress >= 0.99f) {
            finish()
        }
    }

    LaunchedEffect(reduceMotion) {
        delay(if (reduceMotion) REDUCE_MOTION_MS + 200 else PLAY_CAP_MS)
        finish()
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MarianBlue),
        contentAlignment = Alignment.Center,
    ) {
        if (reduceMotion) {
            var visible by remember { mutableStateOf(false) }
            LaunchedEffect(Unit) { visible = true }
            val scale by animateFloatAsState(
                targetValue = if (visible) 1f else 0.92f,
                animationSpec = tween(400, easing = FastOutSlowInEasing),
                label = "splash-r",
            )
            Text(
                text = "R",
                style = RosaryType.serifDisplay,
                color = Color.White,
                modifier = Modifier.scale(scale),
            )
        } else if (composition != null) {
            LottieAnimation(
                composition = composition,
                progress = { previewProgress ?: progress.progress },
                modifier = Modifier.size(144.dp),
            )
        }
    }
}
