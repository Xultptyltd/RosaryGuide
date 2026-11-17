package app.rosaryguide.core.data.motion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ScrollMorphTest {
    @Test
    fun positionUnderHeaderBarReachesTheBottom() {
        val top = ScrollMorph.position(offsetY = -172f, insetTop = 172f, contentHeight = 1349.7f, containerHeight = 668f)
        assertEquals(0f, top.y, 0.01f)
        assertEquals(681.7f, top.maxOffset, 0.01f)
        val bottom = ScrollMorph.position(offsetY = 509.7f, insetTop = 172f, contentHeight = 1349.7f, containerHeight = 668f)
        assertEquals(bottom.maxOffset, bottom.y, 0.01f)
        assertTrue(ScrollMorph.resolve(locked = false, armed = false, y = bottom.y, maxOffset = bottom.maxOffset).locked)
    }

    @Test
    fun shortContentHasNoRange() {
        val fits = ScrollMorph.position(offsetY = -62f, insetTop = 62f, contentHeight = 812f, containerHeight = 812f)
        assertEquals(0f, fits.maxOffset, 0f)
        assertEquals(0f, fits.y, 0f)
        assertFalse(ScrollMorph.resolve(locked = false, armed = false, y = 0f, maxOffset = 0f).locked)
    }

    @Test
    fun rubberBandIsClamped() {
        val overBottom = ScrollMorph.position(offsetY = 700f, insetTop = 0f, contentHeight = 1000f, containerHeight = 600f)
        assertEquals(400f, overBottom.y, 0f)
        val overTop = ScrollMorph.position(offsetY = -90f, insetTop = 0f, contentHeight = 1000f, containerHeight = 600f)
        assertEquals(0f, overTop.y, 0f)
    }

    @Test
    fun thresholdAndHysteresis() {
        val maxOffset = 400f
        val expandAt = maxOffset - ScrollMorph.expandGap(maxOffset)
        assertTrue(ScrollMorph.resolve(locked = false, armed = false, y = expandAt, maxOffset = maxOffset).locked)
        assertFalse(ScrollMorph.resolve(locked = false, armed = false, y = expandAt - 1f, maxOffset = maxOffset).locked)
        val between = expandAt - 20f
        assertTrue(ScrollMorph.resolve(locked = true, armed = false, y = between, maxOffset = maxOffset).locked)
        assertFalse(ScrollMorph.resolve(locked = false, armed = false, y = between, maxOffset = maxOffset).locked)
        val collapseAt = maxOffset - ScrollMorph.collapseGap(maxOffset)
        assertFalse(ScrollMorph.resolve(locked = true, armed = false, y = collapseAt - 1f, maxOffset = maxOffset).locked)
    }

    @Test
    fun tinyRangeIsIgnored() {
        assertFalse(
            ScrollMorph.resolve(
                locked = false,
                armed = false,
                y = 6f,
                maxOffset = ScrollMorph.minimumOffset,
            ).locked,
        )
    }

    @Test
    fun shortOverflowCollapsesWhenScrolledBackUp() {
        val atBottom = ScrollMorph.resolve(locked = false, armed = false, y = 60f, maxOffset = 60f)
        assertTrue(atBottom.locked)
        val backUp = ScrollMorph.resolve(locked = true, armed = false, y = 0f, maxOffset = 60f)
        assertFalse(backUp.locked)
    }

    @Test
    fun tapScrollIsNotCancelledOnTheWayDown() {
        val midway = ScrollMorph.resolve(locked = true, armed = true, y = 100f, maxOffset = 600f)
        assertTrue(midway.locked)
        assertTrue(midway.armed)
        val arrived = ScrollMorph.resolve(locked = true, armed = true, y = 600f, maxOffset = 600f)
        assertTrue(arrived.locked)
        assertFalse(arrived.armed)
    }

    @Test
    fun fullCycleRepeats() {
        var state = ScrollMorph.State(locked = false, armed = false)
        repeat(3) {
            state = ScrollMorph.resolve(state.locked, state.armed, y = 400f, maxOffset = 400f)
            assertTrue(state.locked)
            state = ScrollMorph.resolve(state.locked, state.armed, y = 50f, maxOffset = 400f)
            assertFalse(state.locked)
        }
    }

    @Test
    fun tailPaddingFillsMinimumRange() {
        assertEquals(0f, ScrollMorph.tailPadding(80f), 0f)
        assertEquals(16f, ScrollMorph.tailPadding(40f), 0f)
        assertEquals(56f, ScrollMorph.tailPadding(0f), 0f)
    }
}
