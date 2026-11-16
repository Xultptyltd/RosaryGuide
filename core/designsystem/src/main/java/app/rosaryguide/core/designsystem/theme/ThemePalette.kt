package app.rosaryguide.core.designsystem.theme

import androidx.compose.ui.graphics.Color

enum class ColorSchemeContrast { Standard, Increased }

enum class PageStyle { Grouped, Plain }

/**
 * Complete iOS `ThemePalette` token set (light + dark, standard + increased contrast).
 * Packed values come from `AppTheme` / `RosaryHex`.
 */
data class ThemePalette(
    val isDark: Boolean,
    val contrast: ColorSchemeContrast = ColorSchemeContrast.Standard,
) {
    val background: Color = if (isDark) Color(RosaryHex.BackgroundDark) else Color(RosaryHex.BackgroundLight)
    val groupedBackground: Color = if (isDark) Color(RosaryHex.GroupedBackgroundDark) else Color(RosaryHex.GroupedBackgroundLight)
    fun page(style: PageStyle): Color = if (style == PageStyle.Grouped) groupedBackground else background

    val textPrimary: Color = if (isDark) Color(RosaryHex.TextPrimaryDark) else Color(RosaryHex.TextPrimaryLight)
    val textSecondary: Color = if (isDark) Color(RosaryHex.TextSecondaryDark) else Color(RosaryHex.TextSecondaryLight)
    val futureDayText: Color get() = textSecondary

    val surface: Color = if (isDark) Color(RosaryHex.SurfaceDark) else Color(RosaryHex.SurfaceLight)

    fun cardSurface(on: PageStyle): Color {
        if (isDark) return surface
        return if (on == PageStyle.Grouped) background else Color(RosaryHex.CardOnPlainLight)
    }

    val cardSurfaceStroke: Color
        get() = textPrimary.copy(alpha = if (!isDark) 0.08f else 0.07f)

    val sectionDivider: Color
        get() = if (!isDark) Color(RosaryHex.SectionDividerLight) else surface

    val accent: Color
        get() = when {
            !isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.MarianBlue)
            isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.MarianBlue)
            else -> Color(RosaryHex.MarianBlue)
        }

    val onAccent: Color = Color.White

    val appleButtonFill: Color get() = if (isDark) Color.White else Color.Black
    val appleButtonText: Color get() = if (isDark) Color.Black else Color.White
    val googleButtonFill: Color get() = if (isDark) Color(RosaryHex.GoogleButtonFillDark) else Color.White
    val googleButtonStroke: Color get() = if (isDark) Color(RosaryHex.GoogleButtonStrokeDark) else Color(RosaryHex.GoogleButtonStrokeLight)
    val googleButtonText: Color get() = if (isDark) Color(RosaryHex.GoogleButtonTextDark) else Color(RosaryHex.GoogleButtonTextLight)

    val accentText: Color
        get() = when {
            !isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.MarianBlueTextHighContrast)
            isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.MarianBlueDarkTextHighContrast)
            isDark -> Color(RosaryHex.MarianBlueDarkText)
            else -> Color(RosaryHex.MarianBlue)
        }

    val stepNumberText: Color
        get() = when {
            contrast == ColorSchemeContrast.Increased -> accentText
            isDark -> Color(RosaryHex.StepNumberDark)
            else -> Color(RosaryHex.MarianBlue)
        }

    val stepNumberFill: Color
        get() = accent.copy(alpha = if (isDark) 0.12f else 0.08f)

    val tabSelected: Color
        get() = when {
            isDark -> Color(RosaryHex.TabSelectedDark)
            contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.MarianBlueTextHighContrast)
            else -> accent
        }

    val destructive: Color
        get() = when {
            !isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.DestructiveLightHighContrast)
            isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.DestructiveDarkHighContrast)
            isDark -> Color(RosaryHex.DestructiveDark)
            else -> Color(RosaryHex.DestructiveLight)
        }

    val success: Color
        get() = when {
            !isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.SuccessLightHighContrast)
            isDark && contrast == ColorSchemeContrast.Increased -> Color(RosaryHex.SuccessDarkHighContrast)
            isDark -> Color(RosaryHex.SuccessDark)
            else -> Color(RosaryHex.SuccessLight)
        }

    val buttonPrimaryFill: Color get() = accent
    val buttonPrimaryText: Color get() = onAccent
    val buttonSecondaryFill: Color get() = if (isDark) Color.White else Color.Black
    val buttonSecondaryText: Color get() = if (isDark) Color.Black else Color.White
    val buttonTertiaryFill: Color get() = if (!isDark) surface else Color(RosaryHex.ButtonTertiaryDark)
    val buttonTertiaryText: Color get() = if (isDark) Color.White.copy(alpha = 0.96f) else Color.Black
    val todayPillFill: Color = Color.White
    val todayPillText: Color = Color.Black

    val strokeSubtle: Color get() = textPrimary.copy(alpha = if (!isDark) 0.07f else 0.12f)
    val strokeRegular: Color get() = textPrimary.copy(alpha = if (!isDark) 0.12f else 0.22f)
    val strokeStrong: Color get() = textPrimary.copy(alpha = 0.28f)
    val strokeSelected: Color get() = textPrimary.copy(alpha = 0.85f)
    val scrim: Color = Color.Black

    val prayerBackground: Color get() = background
    val artworkFallbackBackground: Color = Color(RosaryHex.ArtworkFallback)
    val feastIndicator: Color get() = if (!isDark) Color(RosaryHex.FeastGoldLight) else Color(RosaryHex.FeastGoldDark)
    val accentTint: Color get() = accent.copy(alpha = if (isDark) 0.20f else 0.12f)
    val mysteryIconFill: Color get() = accent
    val mysteryIconGlyph: Color get() = onAccent
    val segmentedControlTrack: Color get() = surface
    val selectedControlFill: Color get() = background
    val emphasisSegmentThumb: Color get() = if (!isDark) Color.White else textPrimary
    val emphasisSegmentTitle: Color get() = if (!isDark) textPrimary else background
    val selectedShadow: Color get() = accent.copy(alpha = 0.28f)

    val ceremonyBackground: Color get() = prayerBackground
    val ceremonyTextPrimary: Color get() = textPrimary
    val ceremonyTextSecondary: Color get() = textSecondary
    val ceremonyTextTertiary: Color get() = textSecondary

    val bg: Color get() = background
    val prayBg: Color get() = prayerBackground
    val ink: Color get() = textPrimary
    val dim: Color get() = textSecondary
    val card: Color get() = surface
    val card2: Color get() = surface
    val panel: Color get() = surface
    val primaryButtonFill: Color get() = buttonPrimaryFill
    val primaryButtonText: Color get() = buttonPrimaryText
    val secondaryButtonFill: Color get() = buttonSecondaryFill
    val secondaryButtonText: Color get() = buttonSecondaryText
    val tertiaryButtonFill: Color get() = buttonTertiaryFill
    val tertiaryButtonText: Color get() = buttonTertiaryText
    val learnMoreButtonFill: Color get() = buttonSecondaryFill
    val learnMoreButtonText: Color get() = buttonSecondaryText
    val buttonTertiaryFillAlias: Color get() = buttonTertiaryFill
    val completionBackground: Color get() = ceremonyBackground
    val completionLabel: Color get() = ceremonyTextSecondary
    val completionTitle: Color get() = ceremonyTextPrimary
    val completionMeta: Color get() = ceremonyTextTertiary
    val completionMetaValue: Color get() = ceremonyTextPrimary.copy(alpha = 0.94f)

    companion object {
        val Light = ThemePalette(isDark = false)
        val Dark = ThemePalette(isDark = true)
        val allStandardAndHighContrast: List<ThemePalette> = listOf(
            ThemePalette(false),
            ThemePalette(true),
            ThemePalette(false, ColorSchemeContrast.Increased),
            ThemePalette(true, ColorSchemeContrast.Increased),
        )

        fun brandCanvas(isDark: Boolean): Color =
            if (isDark) Color(RosaryHex.BackgroundDark) else Color(RosaryHex.MarianBlue)

        val launchCanvas: Color = Color(RosaryHex.MarianBlue)
        val marianBlue: Color = Color(RosaryHex.MarianBlue)
    }
}
