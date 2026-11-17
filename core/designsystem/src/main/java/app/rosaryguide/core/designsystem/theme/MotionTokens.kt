package app.rosaryguide.core.designsystem.theme

import androidx.compose.animation.core.SpringSpec
import androidx.compose.animation.core.spring
import kotlin.math.PI

/**
 * Motion tokens ported from iOS `MotionTokens` / `PairMotion`.
 *
 * iOS `Animation.spring(response:dampingFraction:)` maps to Compose as
 * `stiffness = (2π / response)²` (mass 1) and `dampingRatio = dampingFraction`.
 */
object MotionTokens {
    /** iOS `MotionTokens.reveal`: response 0.52, dampingFraction 0.86. */
    val reveal: SpringSpec<Float> = iosSpring(response = 0.52f, dampingFraction = 0.86f)

    /** iOS `PairMotion.secondIn`: response 0.42, dampingFraction 0.86. */
    val pairSecondIn: SpringSpec<Float> = iosSpring(response = 0.42f, dampingFraction = 0.86f)

    /** iOS `PairMotion.secondOut`: response 0.3, dampingFraction 0.9. */
    val pairSecondOut: SpringSpec<Float> = iosSpring(response = 0.3f, dampingFraction = 0.9f)

    /** iOS `PairMotion.stagger` between Next expanding and Complete decade appearing. */
    const val pairStaggerMs: Long = 100L

    /** iOS `PairMotion.slide`: Complete decade slides out from under Next. */
    const val pairSlideDp: Float = 18f

    /** iOS `AppTheme.Component.mysteryPlateActionCircle` / `pillHeight`. */
    const val actionCircleDp: Float = 52f

    fun iosSpring(response: Float, dampingFraction: Float): SpringSpec<Float> {
        val omega = (2f * PI.toFloat()) / response
        return spring(dampingRatio = dampingFraction, stiffness = omega * omega)
    }
}
