package app.rosaryguide.core.data.motion

/**
 * One rule for every circle-to-button control on a scrolling prayer, ported
 * from iOS `ScrollMorph` in `PrayView.swift`.
 *
 * Expand near the bottom; collapse once the reader is clearly back up.
 * Both gaps scale with the scroll range so short overflows still collapse.
 */
object ScrollMorph {
    /** Every scrolling prayer leaves at least this much to scroll (points/dp). */
    const val minimumRange: Float = 56f

    /** Below this there is no scroll to speak of; [resolve] leaves the state alone. */
    const val minimumOffset: Float = 8f

    fun expandGap(maxOffset: Float): Float = minOf(36f, maxOffset * 0.2f)

    fun collapseGap(maxOffset: Float): Float = minOf(112f, maxOffset * 0.5f)

    data class Position(val y: Float, val maxOffset: Float)

    data class State(val locked: Boolean, val armed: Boolean)

    /**
     * Scroll position measured from the top of the content.
     * `offsetY` rests at `-insetTop` under a top bar, and `containerHeight`
     * already excludes the insets, so the range is `content - container`.
     * `y` is clamped to that range: rubber-band overscroll at either end reads
     * as the end itself, so it can't flicker the CTA.
     */
    fun position(
        offsetY: Float,
        insetTop: Float,
        contentHeight: Float,
        containerHeight: Float,
    ): Position {
        val maxOffset = maxOf(0f, contentHeight - containerHeight)
        val y = minOf(maxOffset, maxOf(0f, offsetY + insetTop))
        return Position(y, maxOffset)
    }

    /**
     * New (locked, armed) after a scroll position update.
     * `armed` is a tap's own scroll on its way down. It clears on arrival.
     */
    fun resolve(locked: Boolean, armed: Boolean, y: Float, maxOffset: Float): State {
        if (maxOffset <= minimumOffset) return State(locked, false)
        if (y >= maxOffset - expandGap(maxOffset)) return State(locked = true, armed = false)
        if (armed) return State(locked, armed)
        if (locked && y < maxOffset - collapseGap(maxOffset)) return State(locked = false, armed = false)
        return State(locked, armed)
    }

    /** Extra trailing space so a scrolling prayer always has at least [minimumRange]. */
    fun tailPadding(range: Float): Float = maxOf(0f, minimumRange - range)
}
