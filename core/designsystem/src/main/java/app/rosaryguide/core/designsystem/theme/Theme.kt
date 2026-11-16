package app.rosaryguide.core.designsystem.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.CompositionLocalProvider

/**
 * Product theme. Material 3 is the engine; values come from iOS `ThemePalette`.
 * Dynamic color (Material You) is intentionally off so Marian blue stays #0054FF.
 */
@Composable
fun RosaryGuideTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    contrast: ColorSchemeContrast = ColorSchemeContrast.Standard,
    content: @Composable () -> Unit,
) {
    val colors = if (darkTheme) darkRosaryColors() else lightRosaryColors()
    val palette = ThemePalette(isDark = darkTheme, contrast = contrast)
    CompositionLocalProvider(
        LocalRosaryColors provides colors,
        LocalRosaryDimens provides RosaryDimens(),
        LocalThemePalette provides palette,
    ) {
        MaterialTheme(
            colorScheme = colors.toMaterialScheme(),
            typography = RosaryTypography,
            content = content,
        )
    }
}

val LocalThemePalette = staticCompositionLocalOf { ThemePalette.Light }
