package app.rosaryguide.core.designsystem.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ThemePaletteTest {
    private fun argb(color: Color): Long = color.toArgb().toLong() and 0xFFFFFFFFL

    @Test
    fun testGroupedSurfaceAliasesUseSingleToken() {
        val palette = ThemePalette.Light
        assertEquals(argb(palette.surface), argb(palette.panel))
        assertEquals(argb(palette.surface), argb(palette.card))
        assertEquals(argb(palette.surface), argb(palette.card2))
    }

    @Test
    fun testSurfaceAndButtonColorTokens() {
        val light = ThemePalette.Light
        val dark = ThemePalette.Dark
        assertEquals(0xFFEBEBEDL, argb(light.surface))
        assertEquals(0xFF1C1C1EL, argb(dark.surface))
        assertEquals(0xFFFFFFFFL, argb(light.bg))
        assertEquals(0xFFF8F8FAL, argb(light.groupedBackground))
        assertEquals(argb(dark.bg), argb(dark.groupedBackground))
        assertEquals(0xFFFFFFFFL, argb(light.cardSurface(PageStyle.Grouped)))
        assertEquals(0xFFF2F3F7L, argb(light.cardSurface(PageStyle.Plain)))
        assertEquals(argb(dark.surface), argb(dark.cardSurface(PageStyle.Plain)))
        assertEquals(argb(dark.surface), argb(dark.cardSurface(PageStyle.Grouped)))
        assertEquals(argb(dark.surface), argb(dark.sectionDivider))
        assertEquals(0xFF000000L, argb(dark.bg))
        assertEquals(0xFF0054FFL, argb(light.mysteryIconFill))
        assertEquals(0xFF0054FFL, argb(dark.mysteryIconFill))
        assertEquals(0xFFFFFFFFL, argb(light.emphasisSegmentThumb))
        assertEquals(argb(light.ink), argb(light.emphasisSegmentTitle))
        assertEquals(argb(dark.ink), argb(dark.emphasisSegmentThumb))
        assertEquals(argb(dark.bg), argb(dark.emphasisSegmentTitle))
        assertEquals(argb(light.bg), argb(light.prayBg))
        assertEquals(argb(dark.bg), argb(dark.prayBg))
        assertEquals(0xFF0054FFL, argb(light.primaryButtonFill))
        assertEquals(0xFF0054FFL, argb(dark.primaryButtonFill))
        assertEquals(0xFF000000L, argb(light.secondaryButtonFill))
        assertEquals(0xFFFFFFFFL, argb(dark.secondaryButtonFill))
        assertEquals(0xFFFFFFFFL, argb(light.secondaryButtonText))
        assertEquals(0xFF000000L, argb(dark.secondaryButtonText))
        assertEquals(argb(light.secondaryButtonFill), argb(light.learnMoreButtonFill))
        assertEquals(argb(dark.secondaryButtonFill), argb(dark.learnMoreButtonFill))
        assertEquals(argb(light.secondaryButtonText), argb(light.learnMoreButtonText))
        assertEquals(argb(dark.secondaryButtonText), argb(dark.learnMoreButtonText))
        assertEquals(argb(light.surface), argb(light.tertiaryButtonFill))
        assertEquals(0xFF2C2C2EL, argb(dark.tertiaryButtonFill))
        assertEquals(argb(light.surface), argb(light.buttonTertiaryFill))
        assertEquals(argb(dark.tertiaryButtonFill), argb(dark.buttonTertiaryFill))
    }

    @Test
    fun testSignInButtonsFollowProviderBranding() {
        val light = ThemePalette.Light
        val dark = ThemePalette.Dark
        assertEquals(0xFF000000L, argb(light.appleButtonFill))
        assertEquals(0xFFFFFFFFL, argb(light.appleButtonText))
        assertEquals(0xFFFFFFFFL, argb(dark.appleButtonFill))
        assertEquals(0xFF000000L, argb(dark.appleButtonText))
        assertEquals(0xFFFFFFFFL, argb(light.googleButtonFill))
        assertEquals(0xFF747775L, argb(light.googleButtonStroke))
        assertEquals(0xFF1F1F1FL, argb(light.googleButtonText))
        assertEquals(0xFF131314L, argb(dark.googleButtonFill))
        assertEquals(0xFF8E918FL, argb(dark.googleButtonStroke))
        assertEquals(0xFFE3E3E3L, argb(dark.googleButtonText))
        for (palette in listOf(light, dark)) {
            assertTrue(Contrast.contrastRatio(palette.googleButtonText, palette.googleButtonFill) >= 4.5)
            assertTrue(Contrast.contrastRatio(palette.appleButtonText, palette.appleButtonFill) >= 4.5)
            assertTrue(Contrast.contrastRatio(palette.dim, palette.bg) >= 4.5)
        }
    }

    @Test
    fun testDarkSelectedTabLabelOnGlassPill() {
        assertTrue(Contrast.contrastRatio(ThemePalette.Dark.tabSelected, Color(0xFF3D3E3F)) >= 4.5)
    }

    @Test
    fun testDarkBrandCanvasIsPageBlack() {
        assertEquals(argb(ThemePalette.marianBlue), argb(ThemePalette.brandCanvas(isDark = false)))
        assertEquals(0xFF000000L, argb(ThemePalette.brandCanvas(isDark = true)))
        assertNotEquals(argb(ThemePalette.marianBlue), argb(ThemePalette.brandCanvas(isDark = true)))
    }

    @Test
    fun testLaunchCanvasIsMarianBlueInLightAndDark() {
        assertEquals(argb(ThemePalette.marianBlue), argb(ThemePalette.launchCanvas))
        assertEquals(0xFF0054FFL, argb(ThemePalette.launchCanvas))
    }

    @Test
    fun testFillsKeepMarianBlue() {
        assertEquals(0xFF0054FFL, argb(ThemePalette.Dark.accent))
        assertEquals(0xFF3D7DFFL, argb(ThemePalette.Dark.accentText))
        assertEquals(0xFF0054FFL, argb(ThemePalette.Light.accentText))
        assertEquals(0xFF5C5C5CL, argb(ThemePalette.Light.textSecondary))
        assertEquals(0xFFC92E25L, argb(ThemePalette.Light.destructive))
    }

    @Test
    fun testSuccessMatchesSystemGreen() {
        assertEquals(0xFF34C759L, argb(ThemePalette.Light.success))
        assertEquals(0xFF30D158L, argb(ThemePalette.Dark.success))
    }
}

class ContrastTokenTest {
    private val palettes = ThemePalette.allStandardAndHighContrast

    @Test
    fun testTextTokensReachFourAndAHalf() {
        for (p in palettes) {
            for (bg in listOf(p.bg, p.groupedBackground, p.surface)) {
                val where = "${p.isDark} ${p.contrast}"
                assertTrue("ink $where", Contrast.contrastRatio(p.ink, bg) >= 4.5)
                assertTrue("secondary $where", Contrast.contrastRatio(p.textSecondary, bg) >= 4.5)
                assertTrue("accent text $where", Contrast.contrastRatio(p.accentText, bg) >= 4.5)
                assertTrue("destructive $where", Contrast.contrastRatio(p.destructive, bg) >= 4.5)
            }
            assertTrue("button text", Contrast.contrastRatio(p.onAccent, p.accent) >= 4.5)
            for (page in listOf(p.bg, p.groupedBackground, p.cardSurface(PageStyle.Grouped), p.cardSurface(PageStyle.Plain))) {
                assertTrue("step number", Contrast.contrastRatio(p.stepNumberText, p.stepNumberFill, under = page) >= 4.5)
            }
            assertTrue("tertiary button", Contrast.contrastRatio(p.tertiaryButtonText, p.tertiaryButtonFill) >= 4.5)
            assertTrue("completion meta", Contrast.contrastRatio(p.completionMeta, p.completionBackground) >= 4.5)
        }
    }

    @Test
    fun testIconTokensReachThree() {
        for (p in palettes) {
            for (bg in listOf(p.bg, p.surface)) {
                assertTrue("crown ${p.isDark}", Contrast.contrastRatio(p.feastIndicator, bg) >= 3)
                assertTrue("glyph on tint ${p.isDark}", Contrast.contrastRatio(p.accentText, p.accentTint, under = bg) >= 3)
                assertTrue("mystery icon ${p.isDark}", Contrast.contrastRatio(p.mysteryIconGlyph, p.mysteryIconFill, under = bg) >= 3)
            }
        }
    }

    @Test
    fun testFutureDayTextMeetsContrast() {
        for (isDark in listOf(false, true)) {
            val palette = ThemePalette(isDark)
            assertTrue("future day $isDark", Contrast.contrastRatio(palette.futureDayText, palette.bg) >= 4.5)
            assertTrue("future day on surface $isDark", Contrast.contrastRatio(palette.futureDayText, palette.surface) >= 4.5)
        }
    }

    @Test
    fun testCompletionFollowsPrayerAppearance() {
        for (palette in palettes) {
            assertEquals(palette.prayBg, palette.completionBackground)
            assertEquals(palette.textPrimary, palette.completionTitle)
            assertTrue(Contrast.contrastRatio(palette.completionLabel, palette.completionBackground) >= 4.5)
            assertTrue(Contrast.contrastRatio(palette.completionMetaValue, palette.surface) >= 4.5)
        }
    }
}
