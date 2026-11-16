package app.rosaryguide.feature.pray

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import app.rosaryguide.core.model.HapticKind

/**
 * Maps iOS `HapticService` kinds onto [VibrationEffect]. Softest for Hail Marys,
 * slightly firmer for larger beads, medium for mystery announcements, and a
 * short two-pulse success when a decade is completed.
 */
class HapticPlayer(context: Context) {
    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= 31) {
        context.getSystemService(VibratorManager::class.java)?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    fun prepare(enabled: Boolean) {
        if (!enabled) return
        // Android has no generator.prepare(); a no-op keeps the iOS call site shape.
    }

    fun play(kind: HapticKind, enabled: Boolean) {
        if (!enabled || kind == HapticKind.None) return
        val vibrator = vibrator ?: return
        if (!vibrator.hasVibrator()) return
        val effect = effectFor(kind) ?: return
        vibrator.vibrate(effect)
    }

    fun selection(enabled: Boolean) {
        play(HapticKind.Soft, enabled)
    }

    private fun effectFor(kind: HapticKind): VibrationEffect? = when (kind) {
        HapticKind.Soft -> VibrationEffect.createOneShot(12, 48)
        HapticKind.Light -> VibrationEffect.createOneShot(18, 96)
        HapticKind.Medium -> VibrationEffect.createOneShot(28, 160)
        HapticKind.Heavy -> VibrationEffect.createOneShot(40, 255)
        HapticKind.Success -> VibrationEffect.createWaveform(longArrayOf(0, 18, 40, 28), intArrayOf(0, 180, 0, 220), -1)
        HapticKind.Warning -> VibrationEffect.createWaveform(longArrayOf(0, 24, 50, 24), intArrayOf(0, 200, 0, 200), -1)
        HapticKind.None -> null
    }
}
