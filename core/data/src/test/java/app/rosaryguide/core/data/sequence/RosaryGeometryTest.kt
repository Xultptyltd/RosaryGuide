package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.model.BeadLocus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RosaryGeometryTest {
    private val geom = RosaryGeometry.shared

    @Test
    fun testBeadCountAndOrder() {
        // 5 pendant + 11 first-decade (10 Hail Marys + glory space) + 4 * 12 later decades
        assertEquals(64, geom.beads.size)
        assertEquals(BeadLocus.OpeningGlory, geom.beads[0].locus)
        assertEquals(BeadLocus.OpeningHail(3), geom.beads[1].locus)
        assertEquals(BeadLocus.OpeningHail(2), geom.beads[2].locus)
        assertEquals(BeadLocus.OpeningHail(1), geom.beads[3].locus)
        assertEquals(BeadLocus.OpeningOurFather, geom.beads[4].locus)
        assertEquals(BeadLocus.DecadeHail(1, 1), geom.beads[5].locus)
        assertEquals(BeadLocus.DecadeGlory(5), geom.beads.last().locus)
        assertTrue(geom.beads.last().isSpace)
        assertTrue(geom.beads[4].large)
        assertEquals(64.0, geom.viewH, 0.001)
        assertTrue(geom.viewW > 200)
    }

    @Test
    fun testPointsSitInsideTheViewBox() {
        val pad = 12.0
        for (bead in geom.beads) {
            assertTrue("${bead.locus} x=${bead.point.x}", bead.point.x >= -pad && bead.point.x <= geom.viewW + pad)
            assertTrue("${bead.locus} y=${bead.point.y}", bead.point.y >= -pad && bead.point.y <= geom.viewH + pad)
        }
        assertTrue(geom.medal.x > geom.crucifix.x)
        assertEquals(geom.medal.y, geom.crucifix.y, 0.001)
        // First-decade Hail Marys start on the upper side of the loop (the join is at mid-left).
        val firstHail = geom.beads.first { it.locus == BeadLocus.DecadeHail(1, 1) }
        assertTrue("decade 1 Hail Mary 1 should sit on the top half, y=${firstHail.point.y}", firstHail.point.y < geom.viewH / 2)
    }
}
