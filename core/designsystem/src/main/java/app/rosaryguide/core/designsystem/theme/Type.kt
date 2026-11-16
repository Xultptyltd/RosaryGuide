package app.rosaryguide.core.designsystem.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Type scale ported from iOS `AppTheme.TypeRole`.
 *
 * Instrument Sans (UI) and Newsreader (serif body) are bundled in M1.
 * Until then the scale uses the platform sans / serif families at the same sizes.
 */
object RosaryFonts {
    val sans: FontFamily = FontFamily.SansSerif
    val serif: FontFamily = FontFamily.Serif
}

object RosaryType {
    val headingPrimary = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 32.sp,
        lineHeight = 38.sp,
    )
    val headingSecondary = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 22.sp,
        lineHeight = 28.sp,
    )
    val headingCard = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 26.sp,
        lineHeight = 32.sp,
    )
    val h1Navigation = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 44.sp,
        lineHeight = 48.sp,
    )
    val navigationTitle = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Medium,
        fontSize = 17.sp,
        lineHeight = 22.sp,
    )
    val body = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 23.sp,
    )
    val supportingLabel = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        lineHeight = 20.sp,
    )
    val caption = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
    )
    val segmentedControl = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 18.sp,
    )
    val rhythmSummary = TextStyle(
        fontFamily = RosaryFonts.sans,
        fontWeight = FontWeight.Normal,
        fontSize = 32.sp,
        lineHeight = 38.sp,
    )
    val serifBody = TextStyle(
        fontFamily = RosaryFonts.serif,
        fontWeight = FontWeight.Normal,
        fontSize = 20.sp,
        lineHeight = 29.sp,
    )
    val serifItalicBody = TextStyle(
        fontFamily = RosaryFonts.serif,
        fontWeight = FontWeight.Normal,
        fontStyle = FontStyle.Italic,
        fontSize = 16.sp,
        lineHeight = 23.sp,
    )
    val serifTitle = TextStyle(
        fontFamily = RosaryFonts.serif,
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        lineHeight = 30.sp,
    )
    val serifDisplay = TextStyle(
        fontFamily = RosaryFonts.serif,
        fontWeight = FontWeight.Normal,
        fontSize = 40.sp,
        lineHeight = 46.sp,
    )

    /** Extra line-height multiple for reading paragraphs, from TypeRole.readingLineHeight. */
    const val ReadingLineHeight = 1.45f
}

val RosaryTypography = Typography(
    displayLarge = RosaryType.serifDisplay,
    displayMedium = RosaryType.h1Navigation,
    displaySmall = RosaryType.headingPrimary,
    headlineLarge = RosaryType.headingPrimary,
    headlineMedium = RosaryType.headingCard,
    headlineSmall = RosaryType.headingSecondary,
    titleLarge = RosaryType.headingSecondary,
    titleMedium = RosaryType.navigationTitle,
    titleSmall = RosaryType.segmentedControl,
    bodyLarge = RosaryType.body,
    bodyMedium = RosaryType.supportingLabel,
    bodySmall = RosaryType.caption,
    labelLarge = RosaryType.body,
    labelMedium = RosaryType.segmentedControl,
    labelSmall = RosaryType.caption,
)
