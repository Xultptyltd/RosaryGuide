package app.rosaryguide.core.designsystem.theme

import org.junit.Assert.assertEquals
import org.junit.Test

class ThemeTokenTest {
    @Test
    fun marianBlueIs0054FF() {
        assertEquals(0xFF0054FFL, RosaryHex.MarianBlue)
    }

    @Test
    fun feastGoldMatchesIosLightAndDark() {
        assertEquals(0xFFAA7F26L, RosaryHex.FeastGoldLight)
        assertEquals(0xFFE2B75AL, RosaryHex.FeastGoldDark)
    }

    @Test
    fun groupedBackgroundAndInk() {
        assertEquals(0xFFF8F8FAL, RosaryHex.GroupedBackgroundLight)
        assertEquals(0xFF000000L, RosaryHex.BackgroundDark)
        assertEquals(0xFF5C5C5CL, RosaryHex.TextSecondaryLight)
        assertEquals(0xFFAEAEAEL, RosaryHex.TextSecondaryDark)
    }

    @Test
    fun destructiveAndSuccessStandardContrast() {
        assertEquals(0xFFC92E25L, RosaryHex.DestructiveLight)
        assertEquals(0xFFFF453AL, RosaryHex.DestructiveDark)
        assertEquals(0xFF34C759L, RosaryHex.SuccessLight)
        assertEquals(0xFF30D158L, RosaryHex.SuccessDark)
    }

    @Test
    fun darkAccentTextIsReadableBlue() {
        assertEquals(0xFF3D7DFFL, RosaryHex.MarianBlueDarkText)
    }
}
