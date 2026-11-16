package app.rosaryguide.core.data.sequence

import app.rosaryguide.core.model.BeadLocus
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

data class PointF(val x: Double, val y: Double)

data class RosaryBead(
    val locus: BeadLocus,
    val point: PointF,
    val large: Boolean,
    val isSpace: Boolean,
    val tangent: Double = 0.0,
)

data class CordNode(val point: PointF, val radius: Double)

data class PathCommand(
    val type: Type,
    val x: Double,
    val y: Double,
    val cx: Double = 0.0,
    val cy: Double = 0.0,
    val radius: Double = 0.0,
    val startAngle: Double = 0.0,
    val endAngle: Double = 0.0,
    val clockwise: Boolean = false,
) {
    enum class Type { Move, Line, Arc, Close }
}

/**
 * Virtual bead-strand geometry, ported from iOS `RosaryGeometry` in `BeadRailView.swift`.
 * Coordinates are in the cropped web view-box.
 */
class RosaryGeometry private constructor(
    val viewW: Double,
    val viewH: Double,
    val medal: PointF,
    val crucifix: PointF,
    val pendantPath: List<PathCommand>,
    val loopPath: List<PathCommand>,
    val beads: List<RosaryBead>,
    val cordNodes: List<CordNode>,
) {
    companion object {
        val shared: RosaryGeometry by lazy { RosaryGeometry() }

        const val R_HAIL_MARY = 2.25
        const val R_OUR_FATHER = 3.45
        const val R_MEDAL = 9.3
        const val GAP_HAIL_MARY = 1.5
        const val GAP_OUR_FATHER = 7.2

        private operator fun invoke(): RosaryGeometry {
            val lx = 96.0
            val ly = 8.0
            val lh = 48.0
            val pad = 14.0
            val W = 330.0
            val lw = W - lx - pad
            val r = lh / 2.0
            val H = lh + ly * 2.0
            val cy = ly + r
            val rHM = R_HAIL_MARY
            val rOF = R_OUR_FATHER
            val rMedal = R_MEDAL
            val gapHM = GAP_HAIL_MARY
            val gapOF = GAP_OUR_FATHER

            val loop = mutableListOf<PathCommand>()
            loop += PathCommand(PathCommand.Type.Move, lx + r, ly)
            loop += PathCommand(PathCommand.Type.Line, lx + lw - r, ly)
            loop += PathCommand(PathCommand.Type.Arc, 0.0, 0.0, lx + lw - r, ly + r, r, Math.toRadians(-90.0), 0.0, false)
            loop += PathCommand(PathCommand.Type.Line, lx + lw, ly + lh - r)
            loop += PathCommand(PathCommand.Type.Arc, 0.0, 0.0, lx + lw - r, ly + lh - r, r, 0.0, Math.toRadians(90.0), false)
            loop += PathCommand(PathCommand.Type.Line, lx + r, ly + lh)
            loop += PathCommand(PathCommand.Type.Arc, 0.0, 0.0, lx + r, ly + lh - r, r, Math.toRadians(90.0), Math.toRadians(180.0), false)
            loop += PathCommand(PathCommand.Type.Line, lx, ly + r)
            loop += PathCommand(PathCommand.Type.Arc, 0.0, 0.0, lx + r, ly + r, r, Math.toRadians(180.0), Math.toRadians(270.0), false)
            loop += PathCommand(PathCommand.Type.Close, 0.0, 0.0)

            val specs = mutableListOf<Triple<BeadLocus, Boolean, Boolean>>()
            for (i in 1..10) specs += Triple(BeadLocus.DecadeHail(1, i), false, false)
            specs += Triple(BeadLocus.DecadeGlory(1), false, true)
            for (d in 2..5) {
                specs += Triple(BeadLocus.DecadeOurFather(d), true, false)
                for (i in 1..10) specs += Triple(BeadLocus.DecadeHail(d, i), false, false)
                specs += Triple(BeadLocus.DecadeGlory(d), false, true)
            }

            fun radius(large: Boolean, space: Boolean): Double = if (space) 0.0 else if (large) rOF else rHM

            val perimeter = 2 * (lw - 2 * r) + 2 * PI * r
            fun gapWeight(a: Triple<BeadLocus, Boolean, Boolean>, b: Triple<BeadLocus, Boolean, Boolean>): Double {
                val tight = !a.second && !a.third && !b.second && !b.third
                return if (tight) gapHM else if (a.third || b.third) gapOF / 2.0 else gapOF
            }
            val fixedDistances = mutableListOf(rMedal + radius(specs[0].second, specs[0].third))
            val gapWeights = mutableListOf(gapOF)
            for (i in 0 until specs.size - 1) {
                val a = specs[i]
                val b = specs[i + 1]
                fixedDistances += radius(a.second, a.third) + radius(b.second, b.third)
                gapWeights += gapWeight(a, b)
            }
            val finalRadius = radius(specs.last().second, specs.last().third)
            val fixedTotal = fixedDistances.sum() + rMedal + finalRadius
            val gapTotal = gapWeights.sum() + gapOF / 2.0
            val gapScale = (perimeter - fixedTotal) / gapTotal
            val distances = fixedDistances.zip(gapWeights).map { it.first + it.second * gapScale }

            fun stadiumPointAndTangent(distance: Double): Pair<PointF, Double> {
                val straight = lw - 2 * r
                val halfArc = PI * r
                val leftHalf = halfArc / 2.0
                var d = distance % perimeter
                if (d < 0) d += perimeter
                if (d <= leftHalf) {
                    val a = PI + (d / r)
                    return PointF(lx + r + cos(a) * r, ly + r + sin(a) * r) to (a + PI / 2.0)
                }
                d -= leftHalf
                if (d <= straight) {
                    return PointF(lx + r + d, ly) to 0.0
                }
                d -= straight
                if (d <= halfArc) {
                    val a = -PI / 2.0 + (d / r)
                    return PointF(lx + lw - r + cos(a) * r, ly + r + sin(a) * r) to (a + PI / 2.0)
                }
                d -= halfArc
                if (d <= straight) {
                    return PointF(lx + lw - r - d, ly + lh) to PI
                }
                d -= straight
                val a = PI / 2.0 + (d / r)
                return PointF(lx + r + cos(a) * r, ly + lh - r + sin(a) * r) to (a + PI / 2.0)
            }

            val loopBeads = mutableListOf<RosaryBead>()
            var cursor = distances[0]
            for (i in specs.indices) {
                val spec = specs[i]
                val placed = stadiumPointAndTangent(cursor)
                loopBeads += RosaryBead(spec.first, placed.first, spec.second, spec.third, placed.second)
                if (i + 1 < distances.size) cursor += distances[i + 1]
            }

            val pend = listOf(
                Triple(BeadLocus.OpeningGlory, false, true),
                Triple(BeadLocus.OpeningHail(3), false, false),
                Triple(BeadLocus.OpeningHail(2), false, false),
                Triple(BeadLocus.OpeningHail(1), false, false),
                Triple(BeadLocus.OpeningOurFather, true, false),
            )
            val pendantBeads = mutableListOf<RosaryBead>()
            var x = lx - (rMedal + radius(pend[0].second, pend[0].third) + gapOF / 2.0 * gapScale)
            for (i in pend.indices) {
                val item = pend[i]
                pendantBeads += RosaryBead(item.first, PointF(x, cy), item.second, item.third)
                if (i < pend.size - 1) {
                    val next = pend[i + 1]
                    val ra = radius(item.second, item.third)
                    val rb = radius(next.second, next.third)
                    x -= ra + rb + gapWeight(item, next) * gapScale
                }
            }

            val openingOF = pendantBeads.firstOrNull { it.locus == BeadLocus.OpeningOurFather } ?: pendantBeads.last()
            val openOF = openingOF.point.x
            val join = openOF - rOF - gapOF * gapScale
            val cxH = 40.0
            val foot = join - cxH
            val crucifix = PointF(join - cxH / 2.0, cy)

            val pendant = listOf(
                PathCommand(PathCommand.Type.Move, lx, cy),
                PathCommand(PathCommand.Type.Line, foot + 2, cy),
            )

            val vbX = foot - 2
            val vbW = (lx + lw + 3.6) - vbX
            fun sh(p: PointF) = PointF(p.x - vbX, p.y)
            fun shPath(path: List<PathCommand>) = path.map { cmd ->
                when (cmd.type) {
                    PathCommand.Type.Move, PathCommand.Type.Line -> cmd.copy(x = cmd.x - vbX)
                    PathCommand.Type.Arc -> cmd.copy(cx = cmd.cx - vbX)
                    PathCommand.Type.Close -> cmd
                }
            }

            val medal = sh(PointF(lx, cy))
            val shiftedCrucifix = sh(crucifix)
            val allBeads = (pendantBeads + loopBeads).map {
                it.copy(point = sh(it.point))
            }

            fun beadRadius(b: RosaryBead): Double = if (b.isSpace) 1.2 else if (b.large) rOF else rHM
            val pendantCount = pendantBeads.size
            val nodes = mutableListOf(CordNode(shiftedCrucifix, 7.0))
            for (b in allBeads.take(pendantCount).reversed()) {
                nodes += CordNode(b.point, beadRadius(b))
            }
            nodes += CordNode(medal, rMedal * 0.85)
            for (b in allBeads.drop(pendantCount)) {
                nodes += CordNode(b.point, beadRadius(b))
            }
            nodes += CordNode(medal, rMedal * 0.85)

            return RosaryGeometry(
                viewW = vbW,
                viewH = H,
                medal = medal,
                crucifix = shiftedCrucifix,
                pendantPath = shPath(pendant),
                loopPath = shPath(loop),
                beads = allBeads,
                cordNodes = nodes,
            )
        }
    }

    fun radiusOf(bead: RosaryBead): Double = when {
        bead.isSpace -> 1.2
        bead.large -> R_OUR_FATHER
        else -> R_HAIL_MARY
    }
}
