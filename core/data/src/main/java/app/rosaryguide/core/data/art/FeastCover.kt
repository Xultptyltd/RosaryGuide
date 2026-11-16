package app.rosaryguide.core.data.art

/**
 * Leading-letterbox feast crop, ported from iOS `ArtCatalog` (11 Nov 2026).
 * 1280×720 feast files letterbox portrait statues on a flat field; the cover
 * clips that empty band from the top (capped at 30% of the file height),
 * scales to cover the frame, and horizontally centers on [focusX].
 */
data class FeastSubject(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float,
    val focusX: Float,
) {
    val minX: Float get() = x
    val minY: Float get() = y
    val maxX: Float get() = x + width
    val maxY: Float get() = y + height
}

data class FeastCover(
    val scale: Float,
    val offsetX: Float,
    val offsetY: Float,
)

data class SizeF(val width: Float, val height: Float)

object FeastCoverMath {
    /** How far down the file the visible cover may start after dropping a leading letterbox. */
    fun feastContentTop(subjectY: Float, subjectHeight: Float, imageHeight: Float): Float {
        if (imageHeight <= 1f || subjectHeight <= 1f || subjectY <= 0f) return 0f
        return minOf(maxOf(subjectY, 0f), imageHeight * 0.30f)
    }

    /**
     * Downward shift for a feast hero whose frame top sits [overlap] under translucent chrome.
     * Capped so at least 60% of the frame still shows artwork (shift ≤ 40% of frame height).
     */
    fun feastChromeShift(overlap: Float, frameHeight: Float): Float {
        if (!overlap.isFinite() || frameHeight <= 1f) return 0f
        return minOf(maxOf(overlap, 0f), frameHeight * 0.4f)
    }

    fun feastCover(imageSize: SizeF, frame: SizeF, subject: FeastSubject, focusX: Float): FeastCover {
        if (imageSize.width <= 1f || imageSize.height <= 1f || frame.width <= 1f || frame.height <= 1f) {
            return FeastCover(1f, 0f, 0f)
        }
        val boxX = subject.x.coerceIn(0f, imageSize.width)
        val boxY = subject.y.coerceIn(0f, imageSize.height)
        val boxW = (subject.maxX.coerceIn(0f, imageSize.width) - boxX).coerceAtLeast(0f)
        val boxH = (subject.maxY.coerceIn(0f, imageSize.height) - boxY).coerceAtLeast(0f)
        val contentTop = feastContentTop(boxY, boxH, imageSize.height)
        val usableHeight = maxOf(imageSize.height - contentTop, 1f)
        val scale = maxOf(frame.width / imageSize.width, frame.height / usableHeight)
        val scaledW = imageSize.width * scale
        val maxVisX = maxOf(0f, scaledW - frame.width)
        val maxVisY = maxOf(0f, imageSize.height * scale - frame.height)
        val anchor = if (boxW > 1f && boxH > 1f) {
            focusX.coerceIn(boxX, boxX + boxW)
        } else {
            focusX.coerceIn(0f, imageSize.width)
        }
        val visX = (anchor * scale - frame.width / 2f).coerceIn(0f, maxVisX)
        val visY = minOf(contentTop * scale, maxVisY)
        return FeastCover(scale, offsetX = -visX, offsetY = -visY)
    }
}

/**
 * Precomputed [FeastSubject] boxes for each light-mode feast WebP, produced with
 * the iOS `ArtCatalog.detectFeastSubject` algorithm (320×180 luminance sample).
 * Night-mode files share the same framing.
 */
object FeastSubjects {
    private val byDrawable: Map<String, FeastSubject> = mapOf(
        "feast_advent_1" to FeastSubject(140.32f, 19.68f, 979.3600000000001f, 700.32f, focusX = 636.1300527240774f),
        "feast_all_saints" to FeastSubject(16.32f, 0f, 1227.3600000000001f, 720f, focusX = 615.8756345177665f),
        "feast_all_souls" to FeastSubject(88.32f, 0f, 1075.3600000000001f, 720f, focusX = 671.1506629168341f),
        "feast_annunciation" to FeastSubject(28.32f, 0f, 1211.3600000000001f, 720f, focusX = 535.0917957544464f),
        "feast_ascension" to FeastSubject(64.32f, 0f, 1115.3600000000001f, 720f, focusX = 630.4742530197076f),
        "feast_ash_wednesday" to FeastSubject(132.32f, 11.68f, 1015.3600000000001f, 664.6400000000001f, focusX = 575.3594991572357f),
        "feast_assumption" to FeastSubject(328.32f, 0f, 627.3599999999999f, 720f, focusX = 620.5261044176707f),
        "feast_baptism_movable" to FeastSubject(200.32f, 0f, 859.3600000000001f, 720f, focusX = 694.1651131824234f),
        "feast_carmel" to FeastSubject(136.32f, 0f, 971.3600000000001f, 720f, focusX = 584.4118770619899f),
        "feast_christ_the_king" to FeastSubject(480.32f, 0f, 299.35999999999996f, 720f, focusX = 635.7961914565105f),
        "feast_christmas" to FeastSubject(36.32f, 0f, 1207.3600000000001f, 720f, focusX = 694.0905250452626f),
        "feast_corpus_christi" to FeastSubject(68.32f, 0f, 1103.3600000000001f, 720f, focusX = 640.7389893370422f),
        "feast_divine_mercy" to FeastSubject(284.32f, 0f, 667.3599999999999f, 720f, focusX = 610.6011322696861f),
        "feast_easter" to FeastSubject(52.32f, 0f, 959.3599999999999f, 720f, focusX = 587.078173374613f),
        "feast_epiphany" to FeastSubject(8.32f, 0f, 1255.3600000000001f, 720f, focusX = 667.6330821797792f),
        "feast_fatima" to FeastSubject(368.32f, 0f, 487.35999999999996f, 720f, focusX = 634.7528931245745f),
        "feast_good_friday" to FeastSubject(284.32f, 0f, 679.3599999999999f, 720f, focusX = 633.8000437541019f),
        "feast_guadalupe" to FeastSubject(136.32f, 0f, 971.3600000000001f, 720f, focusX = 584.4118770619899f),
        "feast_guardian_angels" to FeastSubject(264.32f, 0f, 671.3599999999999f, 720f, focusX = 579.724524774073f),
        "feast_holy_cross" to FeastSubject(168.32f, 0f, 887.3600000000001f, 720f, focusX = 609.6231703519153f),
        "feast_holy_family" to FeastSubject(48.32f, 0f, 1179.3600000000001f, 720f, focusX = 625.0147461829571f),
        "feast_holy_name_mary" to FeastSubject(336.32f, 0f, 587.3599999999999f, 720f, focusX = 613.4074074074074f),
        "feast_holy_saturday" to FeastSubject(184.32f, 0f, 883.3600000000001f, 720f, focusX = 588.9186046511628f),
        "feast_holy_thursday" to FeastSubject(0f, 31.68f, 1275.68f, 688.32f, focusX = 639.3636207783302f),
        "feast_immaculate_conception" to FeastSubject(388.32f, 0f, 463.35999999999996f, 720f, focusX = 613.4790220344099f),
        "feast_immaculate_heart" to FeastSubject(144.32f, 0f, 927.3600000000001f, 720f, focusX = 613.2183807439825f),
        "feast_joachim_anne" to FeastSubject(44.32f, 0f, 1203.3600000000001f, 720f, focusX = 691.9188420780564f),
        "feast_john_baptist" to FeastSubject(24.32f, 0f, 1235.3600000000001f, 720f, focusX = 663.3230457880092f),
        "feast_joseph" to FeastSubject(100.32f, 0f, 943.3600000000001f, 720f, focusX = 533.9209431345354f),
        "feast_loreto" to FeastSubject(320.32f, 0f, 623.3599999999999f, 720f, focusX = 629.8600645855759f),
        "feast_lourdes" to FeastSubject(472.32f, 0f, 307.35999999999996f, 720f, focusX = 632.8635379061371f),
        "feast_mary_mother_of_god" to FeastSubject(368.32f, 0f, 487.35999999999996f, 720f, focusX = 634.7528931245745f),
        "feast_michael" to FeastSubject(16.32f, 0f, 1239.3600000000001f, 720f, focusX = 616.161817157875f),
        "feast_nativity_mary" to FeastSubject(148.32f, 0f, 975.3600000000001f, 720f, focusX = 680.7852129153018f),
        "feast_palm_sunday" to FeastSubject(4.32f, 0f, 1263.3600000000001f, 720f, focusX = 561.22775678461f),
        "feast_pentecost" to FeastSubject(0.3200000000000003f, 0f, 1275.3600000000001f, 720f, focusX = 631.2275598086125f),
        "feast_peter_paul" to FeastSubject(88.32f, 0f, 1075.3600000000001f, 720f, focusX = 640.0332294911734f),
        "feast_presentation" to FeastSubject(0f, 0f, 1280f, 720f, focusX = 638.0f),
        "feast_presentation_mary" to FeastSubject(156.32f, 51.68f, 955.3600000000001f, 668.32f, focusX = 687.1441441441441f),
        "feast_queenship" to FeastSubject(308.32f, 0f, 655.3599999999999f, 720f, focusX = 602.9600808489135f),
        "feast_rosary" to FeastSubject(116.32f, 0f, 1031.3600000000001f, 720f, focusX = 636.6758869512928f),
        "feast_sacred_heart" to FeastSubject(116.32f, 0f, 1043.3600000000001f, 720f, focusX = 627.4340269277845f),
        "feast_sorrows" to FeastSubject(124.32f, 0f, 963.3600000000001f, 720f, focusX = 609.100646352724f),
        "feast_transfiguration" to FeastSubject(72.32f, 0f, 1139.3600000000001f, 720f, focusX = 636.172197309417f),
        "feast_trinity" to FeastSubject(60.32f, 0f, 1159.3600000000001f, 720f, focusX = 606.8518518518518f),
        "feast_visitation" to FeastSubject(108.32f, 0f, 1027.3600000000001f, 720f, focusX = 585.7855093256815f)
    )

    fun of(drawableName: String): FeastSubject? = byDrawable[drawableName]

    fun ofFeastId(feastId: String): FeastSubject? {
        val artId = app.rosaryguide.core.data.art.ArtCatalog.feastArtId(feastId) ?: feastId
        return of("feast_" + artId.replace("-", "_"))
    }
}
