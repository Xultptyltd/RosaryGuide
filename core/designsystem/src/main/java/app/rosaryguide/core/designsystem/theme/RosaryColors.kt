package app.rosaryguide.core.designsystem.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme

private fun Long.toComposeColor(): Color = Color(this)

@Immutable
data class RosaryColors(
    val isDark: Boolean,
    val background: Color,
    val groupedBackground: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val surface: Color,
    val cardOnPlain: Color,
    val accent: Color,
    val onAccent: Color,
    val accentText: Color,
    val destructive: Color,
    val success: Color,
    val feastGold: Color,
    val sectionDivider: Color,
    val buttonTertiaryFill: Color,
    val googleButtonFill: Color,
    val googleButtonStroke: Color,
    val googleButtonText: Color,
    val intentionPersonal: Color,
    val intentionSomeoneElse: Color,
    val intentionChurch: Color,
    val mysteryJoyful: Color,
    val mysteryLuminous: Color,
    val mysterySorrowful: Color,
    val mysteryGlorious: Color,
    val mysteryOn: Color,
) {
    fun toMaterialScheme(): ColorScheme {
        val onSecondary = if (isDark) Color.Black else Color.White
        return if (isDark) {
            darkColorScheme(
                primary = accent,
                onPrimary = onAccent,
                primaryContainer = accent.copy(alpha = 0.12f),
                onPrimaryContainer = accentText,
                inversePrimary = accentText,
                secondary = feastGold,
                onSecondary = onSecondary,
                secondaryContainer = feastGold.copy(alpha = 0.16f),
                onSecondaryContainer = feastGold,
                tertiary = success,
                onTertiary = Color.White,
                tertiaryContainer = success.copy(alpha = 0.16f),
                onTertiaryContainer = success,
                background = background,
                onBackground = textPrimary,
                surface = surface,
                onSurface = textPrimary,
                surfaceVariant = groupedBackground,
                onSurfaceVariant = textSecondary,
                surfaceTint = accent,
                inverseSurface = textPrimary,
                inverseOnSurface = background,
                error = destructive,
                onError = Color.White,
                errorContainer = destructive.copy(alpha = 0.16f),
                onErrorContainer = destructive,
                outline = textPrimary.copy(alpha = 0.22f),
                outlineVariant = sectionDivider,
                scrim = Color.Black,
            )
        } else {
            lightColorScheme(
                primary = accent,
                onPrimary = onAccent,
                primaryContainer = accent.copy(alpha = 0.12f),
                onPrimaryContainer = accentText,
                inversePrimary = accentText,
                secondary = feastGold,
                onSecondary = onSecondary,
                secondaryContainer = feastGold.copy(alpha = 0.16f),
                onSecondaryContainer = feastGold,
                tertiary = success,
                onTertiary = Color.White,
                tertiaryContainer = success.copy(alpha = 0.16f),
                onTertiaryContainer = success,
                background = background,
                onBackground = textPrimary,
                surface = surface,
                onSurface = textPrimary,
                surfaceVariant = groupedBackground,
                onSurfaceVariant = textSecondary,
                surfaceTint = accent,
                inverseSurface = textPrimary,
                inverseOnSurface = background,
                error = destructive,
                onError = Color.White,
                errorContainer = destructive.copy(alpha = 0.16f),
                onErrorContainer = destructive,
                outline = textPrimary.copy(alpha = 0.12f),
                outlineVariant = sectionDivider,
                scrim = Color.Black,
            )
        }
    }
}

fun lightRosaryColors(): RosaryColors = RosaryColors(
    isDark = false,
    background = RosaryHex.BackgroundLight.toComposeColor(),
    groupedBackground = RosaryHex.GroupedBackgroundLight.toComposeColor(),
    textPrimary = RosaryHex.TextPrimaryLight.toComposeColor(),
    textSecondary = RosaryHex.TextSecondaryLight.toComposeColor(),
    surface = RosaryHex.SurfaceLight.toComposeColor(),
    cardOnPlain = RosaryHex.CardOnPlainLight.toComposeColor(),
    accent = RosaryHex.MarianBlue.toComposeColor(),
    onAccent = RosaryHex.OnAccent.toComposeColor(),
    accentText = RosaryHex.MarianBlue.toComposeColor(),
    destructive = RosaryHex.DestructiveLight.toComposeColor(),
    success = RosaryHex.SuccessLight.toComposeColor(),
    feastGold = RosaryHex.FeastGoldLight.toComposeColor(),
    sectionDivider = RosaryHex.SectionDividerLight.toComposeColor(),
    buttonTertiaryFill = RosaryHex.SurfaceLight.toComposeColor(),
    googleButtonFill = Color.White,
    googleButtonStroke = RosaryHex.GoogleButtonStrokeLight.toComposeColor(),
    googleButtonText = RosaryHex.GoogleButtonTextLight.toComposeColor(),
    intentionPersonal = RosaryHex.IntentionPersonal.toComposeColor(),
    intentionSomeoneElse = RosaryHex.IntentionSomeoneElse.toComposeColor(),
    intentionChurch = RosaryHex.IntentionChurch.toComposeColor(),
    mysteryJoyful = RosaryHex.MysteryJoyful.toComposeColor(),
    mysteryLuminous = RosaryHex.MysteryLuminous.toComposeColor(),
    mysterySorrowful = RosaryHex.MysterySorrowful.toComposeColor(),
    mysteryGlorious = RosaryHex.MysteryGlorious.toComposeColor(),
    mysteryOn = RosaryHex.MysteryOn.toComposeColor(),
)

fun darkRosaryColors(): RosaryColors = RosaryColors(
    isDark = true,
    background = RosaryHex.BackgroundDark.toComposeColor(),
    groupedBackground = RosaryHex.GroupedBackgroundDark.toComposeColor(),
    textPrimary = RosaryHex.TextPrimaryDark.toComposeColor(),
    textSecondary = RosaryHex.TextSecondaryDark.toComposeColor(),
    surface = RosaryHex.SurfaceDark.toComposeColor(),
    cardOnPlain = RosaryHex.SurfaceDark.toComposeColor(),
    accent = RosaryHex.MarianBlue.toComposeColor(),
    onAccent = RosaryHex.OnAccent.toComposeColor(),
    accentText = RosaryHex.MarianBlueDarkText.toComposeColor(),
    destructive = RosaryHex.DestructiveDark.toComposeColor(),
    success = RosaryHex.SuccessDark.toComposeColor(),
    feastGold = RosaryHex.FeastGoldDark.toComposeColor(),
    sectionDivider = RosaryHex.SurfaceDark.toComposeColor(),
    buttonTertiaryFill = RosaryHex.ButtonTertiaryDark.toComposeColor(),
    googleButtonFill = RosaryHex.GoogleButtonFillDark.toComposeColor(),
    googleButtonStroke = RosaryHex.GoogleButtonStrokeDark.toComposeColor(),
    googleButtonText = RosaryHex.GoogleButtonTextDark.toComposeColor(),
    intentionPersonal = RosaryHex.IntentionPersonal.toComposeColor(),
    intentionSomeoneElse = RosaryHex.IntentionSomeoneElse.toComposeColor(),
    intentionChurch = RosaryHex.IntentionChurch.toComposeColor(),
    mysteryJoyful = RosaryHex.MysteryJoyful.toComposeColor(),
    mysteryLuminous = RosaryHex.MysteryLuminous.toComposeColor(),
    mysterySorrowful = RosaryHex.MysterySorrowful.toComposeColor(),
    mysteryGlorious = RosaryHex.MysteryGlorious.toComposeColor(),
    mysteryOn = RosaryHex.MysteryOn.toComposeColor(),
)

val LocalRosaryColors = staticCompositionLocalOf { lightRosaryColors() }
