package app.rosaryguide.core.designsystem.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import app.rosaryguide.core.designsystem.R
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.style.LineHeightStyle

/**
 * Type scale ported from iOS `AppTheme.TypeRole`.
 *
 * Instrument Sans (UI) and Newsreader (serif body) are the bundled, SIL OFL 1.1
 * variable fonts instanced at the weights / optical sizes the iOS app requested.
 */
object RosaryFonts {
    val sans: FontFamily = FontFamily(
        Font(R.font.instrument_sans_regular, FontWeight.Normal),
        Font(R.font.instrument_sans_medium, FontWeight.Medium),
    )
    val serif: FontFamily = FontFamily(
        Font(R.font.newsreader_regular, FontWeight.Normal),
        Font(R.font.newsreader_italic, FontWeight.Normal, FontStyle.Italic),
    )
    val serifDisplay: FontFamily = FontFamily(
        Font(R.font.newsreader_display, FontWeight.Normal),
    )
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
    /**
     * Typo line height of bundled Instrument Sans (asc 970, desc −250, lineGap 0,
     * UPM 1000) — the same metrics as the iOS variable font.
     */
    fun sansLineHeightSp(sizeSp: Float): Float = sizeSp * 1.22f

    private val noFontPadding = PlatformTextStyle(includeFontPadding = false)
    private val naturalLeading = LineHeightStyle(
        alignment = LineHeightStyle.Alignment.Proportional,
        trim = LineHeightStyle.Trim.None,
    )
    /** SwiftUI `.lineSpacing` adds space between lines only, not above/below the block. */
    private val betweenLines = LineHeightStyle(
        alignment = LineHeightStyle.Alignment.Proportional,
        trim = LineHeightStyle.Trim.Both,
    )

    /**
     * Instrument Sans role with iOS metrics: `includeFontPadding = false` and
     * typo line height, plus optional SwiftUI `lineSpacing` and `tracking`.
     * Prefer these on Pray screens; the older roles below keep their historical
     * rounded line heights so approved Today / onboarding frames stay put.
     */
    fun sansRole(
        sizeSp: Float,
        weight: FontWeight = FontWeight.Normal,
        extraLineSpacingSp: Float = 0f,
        letterSpacingSp: Float = 0f,
    ): TextStyle {
        val pitch = sansLineHeightSp(sizeSp) + extraLineSpacingSp
        return TextStyle(
            fontFamily = RosaryFonts.sans,
            fontWeight = weight,
            fontSize = sizeSp.sp,
            lineHeight = pitch.sp,
            letterSpacing = letterSpacingSp.sp,
            platformStyle = noFontPadding,
            lineHeightStyle = if (extraLineSpacingSp > 0f) betweenLines else naturalLeading,
        )
    }

    /** iOS `TypeRole.body` / `callout` / `settingsRow` at Large: 16 pt, no extra lineSpacing. */
    val bodyPray = sansRole(16f)
    /** iOS `TypeRole.body` + `lineSpacing(8)` (Learn mystery intro). */
    val bodyReading = sansRole(16f, extraLineSpacingSp = 8f)
    /** iOS `TypeRole.caption` / `label` / `sectionLabel` / `quoteAttribution`. */
    val captionPray = sansRole(12f)
    val captionMediumPray = sansRole(12f, weight = FontWeight.Medium)
    /** iOS `TypeRole.modalTitle` / `headingSecondary` with `.tracking(-0.2)`. */
    val modalTitlePray = sansRole(22f, letterSpacingSp = -0.2f)
    /** iOS `TypeRole.headingSecondary` / `headline` / `cardTitle` / `title3` at 22 pt, typo 26.84. */
    val headingSecondaryPray = sansRole(22f)
    /** iOS `TypeRole.caption` / `settingsMeta` + `lineSpacing(4)`. */
    val captionReading = sansRole(12f, extraLineSpacingSp = 4f)
    /** iOS `TypeRole.headingPrimary` / `screenTitle` / `title2`. */
    val headingPrimaryPray = sansRole(32f)
    /** iOS `OnboardingPageView` title: `TypeRole.title` (32) + `.lineSpacing(2)`. */
    val headingPrimaryWalkthrough = sansRole(32f, extraLineSpacingSp = 2f)
    /** iOS `TypeRole.navigationTitleUIFont`: 17 pt medium. */
    val navigationTitlePray = sansRole(17f, weight = FontWeight.Medium)
    /** iOS Pray header `progressNowLabel`: `TypeRole.label(weight: .medium)` = 12 pt medium. */
    val progressLabel = captionMediumPray
    /** iOS `TypeRole.supportingLabel`: 15 pt. */
    val supportingLabelPray = sansRole(15f)
    /** iOS `TypeRole.segmentedControl`: 14 pt medium. */
    val segmentedControlPray = sansRole(14f, weight = FontWeight.Medium)
    /** iOS `scriptureReference(isMystery: true)`: 11 pt. */
    val scriptureReferenceMystery = sansRole(11f)
    /** iOS `guideThemeSummaryStyle`: body/callout 16 + `lineSpacing(5)`. */
    val themeSummary = sansRole(16f, extraLineSpacingSp = 5f)
    /** iOS `TypeRole.body` + `lineSpacing(7)` (feast-detail summary). */
    val bodyFeastSummary = sansRole(16f, extraLineSpacingSp = 7f)
    /** iOS `TypeRole.bodySmall` / `callout` + `lineSpacing(7)` (feast meaning). */
    val bodySmallFeast = sansRole(16f, extraLineSpacingSp = 7f)
    /** iOS `TypeRole.bodySmall` + `lineSpacing(8)` (related-prayer body). */
    val bodySmallFeastPrayer = sansRole(16f, extraLineSpacingSp = 8f)
    /** iOS `TypeRole.calendarDay` (16, regularized). */
    val calendarDay = sansRole(16f)
    /** iOS `TypeRole.calendarCaption`. */
    val calendarCaption = sansRole(12f)
    /** iOS `TypeRole.calendarCaptionMedium`. */
    val calendarCaptionMedium = sansRole(12f, weight = FontWeight.Medium)
    /** iOS `TypeRole.calendarDateNumber` (22, typo 26.84). */
    val calendarDateNumber = sansRole(22f)
    /** iOS month-row `callout(weight: .medium)`. */
    val calendarMonthTitle = sansRole(16f, weight = FontWeight.Medium)
    /** iOS timeline title `calloutUIFont(weight: .semibold)` after regularize = 16 regular. */
    val feastTimelineTitle = sansRole(16f)
    /** iOS `Component.eyebrowTracking` (2) on the timeline month abbrev. */
    val calendarMonthAbbrev = sansRole(12f, weight = FontWeight.Medium, letterSpacingSp = 2f)

        /** iOS `TypeRole.completionQuote` (`body`) + `.lineSpacing(2)`. */
    val completionQuote = sansRole(16f, extraLineSpacingSp = 2f)
    /** iOS `TypeRole.quoteAttribution` (`caption`) + `.tracking(0.8)`. */
    val quoteAttribution = sansRole(12f, letterSpacingSp = 0.8f)

    /** iOS `TypeRole.prayerText(scale: 1)` = sans max(16, 18), no extra spacing. */
    val prayerText = sansRole(18f)
    /**
     * iOS `BilingualStack` lineSpacing: `21 * 1.65 − native(21 pt Instrument Sans)`.
     * Native typo LH at 21 is 25.62, so extra is 9.03, applied on the 18 pt face
     * (native 21.96) → 30.99 pt pitch, used on every rosary prayer and the plate.
     */
    val prayerTextReading = sansRole(18f, extraLineSpacingSp = 9.03f)
    /**
     * iOS `PrayerReaderBlock` (Saint Michael): `prayerText` + `.lineSpacing(Space.sm)` = +8.
     */
    val prayerTextMichael = sansRole(18f, extraLineSpacingSp = 8f)
    /** Alias of `headingSecondary` / iOS `modalTitle` (22 / 28). */
    val modalTitle = headingSecondary
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
        fontFamily = RosaryFonts.serifDisplay,
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
