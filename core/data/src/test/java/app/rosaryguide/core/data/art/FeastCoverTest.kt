package app.rosaryguide.core.data.art

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class FeastCoverTest {
    private fun nearly(expected: Float, actual: Float, accuracy: Float = 0.0001f) {
        assertTrue("expected $expected ± $accuracy, got $actual", abs(expected - actual) <= accuracy)
    }

    @Test
    fun chromeShiftIsCappedAndIgnoresInfinity() {
        assertEquals(0f, FeastCoverMath.feastChromeShift(0f, 330f))
        assertEquals(8f, FeastCoverMath.feastChromeShift(8f, 330f))
        assertEquals(0f, FeastCoverMath.feastChromeShift(-20f, 330f))
        nearly(132f, FeastCoverMath.feastChromeShift(500f, 330f))
        assertEquals(0f, FeastCoverMath.feastChromeShift(Float.POSITIVE_INFINITY, 330f))
    }

    @Test
    fun fullSubjectCoversByHeightWithNoVerticalOffset() {
        val image = SizeF(1280f, 720f)
        val frame = SizeF(200f, 400f)
        val subject = FeastSubject(0f, 0f, 1280f, 720f, focusX = 640f)
        val cover = FeastCoverMath.feastCover(image, frame, subject, focusX = 640f)
        nearly(frame.height / image.height, cover.scale)
        assertTrue(image.width * cover.scale >= frame.width)
        nearly(0f, cover.offsetY)
    }

    @Test
    fun horizontalOverflowCentersOnFocus() {
        val image = SizeF(1280f, 720f)
        val frame = SizeF(200f, 400f)
        val subject = FeastSubject(400f, 80f, 480f, 600f, focusX = 640f)
        val cover = FeastCoverMath.feastCover(image, frame, subject, focusX = 640f)
        assertCoversFrame(cover, image, frame, subject)
        val visible = visibleOrigin(cover)
        val visibleWidth = frame.width / cover.scale
        nearly(80f, visible.second, 0.5f)
        nearly(640f, visible.first + visibleWidth / 2f, 0.5f)
        assertTrue(visible.first > 0f)
        assertWindowFillsFrame(visible.first, visible.second, cover, image, frame)

        val leftSubject = FeastSubject(0f, 40f, 400f, 640f, focusX = 80f)
        val left = FeastCoverMath.feastCover(image, frame, leftSubject, focusX = 80f)
        val leftVisible = visibleOrigin(left)
        nearly(40f, leftVisible.second, 0.5f)
        nearly(0f, leftVisible.first, 0.5f)
        assertTrue(80f <= leftVisible.first + frame.width / left.scale)

        val rightSubject = FeastSubject(900f, 40f, 360f, 640f, focusX = 1200f)
        val right = FeastCoverMath.feastCover(image, frame, rightSubject, focusX = 1200f)
        val rightVisible = visibleOrigin(right)
        val rightWidth = frame.width / right.scale
        nearly(40f, rightVisible.second, 0.5f)
        assertTrue(1200f >= rightVisible.first - 0.5f)
        assertTrue(1200f <= rightVisible.first + rightWidth + 0.5f)
        assertWindowFillsFrame(rightVisible.first, rightVisible.second, right, image, frame)
    }

    @Test
    fun homeCardCropsLeadingLetterboxFlushToTheTop() {
        val image = SizeF(1280f, 720f)
        val frame = SizeF(358f, 176f)
        val subject = FeastSubject(200f, 58f, 880f, 650f, focusX = 640f)
        val cover = FeastCoverMath.feastCover(image, frame, subject, focusX = 640f)
        assertCoversFrame(cover, image, frame, subject)
        nearly(frame.width / image.width, cover.scale)
        val visible = visibleOrigin(cover)
        nearly(58f, visible.second, 0.5f)
        nearly(0f, visible.first, 0.5f)
        assertWindowFillsFrame(visible.first, visible.second, cover, image, frame)
    }

    @Test
    fun leadingLetterboxIsCappedAtThirtyPercent() {
        val image = SizeF(1280f, 720f)
        val frame = SizeF(358f, 176f)
        val subject = FeastSubject(200f, 400f, 880f, 300f, focusX = 640f)
        nearly(216f, FeastCoverMath.feastContentTop(400f, 300f, 720f))
        val cover = FeastCoverMath.feastCover(image, frame, subject, focusX = 640f)
        assertCoversFrame(cover, image, frame, subject)
        val visible = visibleOrigin(cover)
        nearly(216f, visible.second, 0.5f)
        assertWindowFillsFrame(visible.first, visible.second, cover, image, frame)
    }

    private fun visibleOrigin(cover: FeastCover): Pair<Float, Float> =
        (-cover.offsetX / cover.scale) to (-cover.offsetY / cover.scale)

    private fun assertCoversFrame(cover: FeastCover, image: SizeF, frame: SizeF, subject: FeastSubject) {
        val contentTop = FeastCoverMath.feastContentTop(subject.y, subject.height, image.height)
        val usable = maxOf(image.height - contentTop, 1f)
        val scale = maxOf(frame.width / image.width, frame.height / usable)
        nearly(scale, cover.scale)
        val maxVisY = maxOf(0f, image.height * scale - frame.height)
        nearly(-minOf(contentTop * scale, maxVisY), cover.offsetY)
    }

    private fun assertWindowFillsFrame(
        visibleX: Float,
        visibleY: Float,
        cover: FeastCover,
        image: SizeF,
        frame: SizeF,
    ) {
        assertTrue(visibleX >= -0.5f)
        assertTrue(visibleY >= -0.5f)
        assertTrue(visibleX + frame.width / cover.scale <= image.width + 0.5f)
        assertTrue(visibleY + frame.height / cover.scale <= image.height + 0.5f)
        assertTrue(image.width * cover.scale >= frame.width - 0.5f)
        assertTrue(image.height * cover.scale >= frame.height - 0.5f)
    }
}
