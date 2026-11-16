package app.rosaryguide.core.designsystem.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider

/**
 * Product theme. Material 3 is the engine; values come from iOS `ThemePalette`.
 * Dynamic color (Material You) is intentionally off so Marian blue stays #0054FF.
 */
@Composable
fun RosaryGuideTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colors = if (darkTheme) darkRosaryColors() else lightRosaryColors()
    CompositionLocalProvider(
        LocalRosaryColors provides colors,
        LocalRosaryDimens provides RosaryDimens(),
    ) {
        MaterialTheme(
            colorScheme = colors.toMaterialScheme(),
            typography = RosaryTypography,
            content = content,
        )
    }
}
