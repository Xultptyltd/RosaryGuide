import Foundation
import SwiftUI
import ImageIO
import UIKit
#if canImport(UIKit)
import UIKit
#endif

/// Typed artwork filenames are rooted at `Art/` in the app bundle.
/// Never ship a top-level `Resources/` folder — iOS codesign treats that as a macOS bundle.
enum ArtCatalog {

    /// One file per plate: the standard and wide plates were byte-identical, so both shapes
    /// load the same image and crop it in the view. `wide` is kept for callers' framing.
    static func platePath(set: MysterySetKind, slug: String, scheme: ColorScheme, wide: Bool) -> (directory: String, name: String) {
        let theme = scheme == .dark ? "dark" : "light"
        return ("Art/\(theme)/\(set.rawValue)", "mystery-\(slug)")
    }

    /// One file per hero: the tall and wide heroes were byte-identical; the view crops each shape.
    static func heroPath(set: MysterySetKind, scheme: ColorScheme, tall: Bool) -> (directory: String, name: String) {
        let theme = scheme == .dark ? "dark" : "light"
        return ("Art/hero", "hero-\(set.rawValue)-\(theme)")
    }

    /// Feast hero art: a dedicated light or dark file under `Art/feasts`.
    /// Mother of the Church shares the Assumption file; every other feast has its own.
    static func feastHeroPath(feastId: String, scheme: ColorScheme) -> (directory: String, name: String, ext: String)? {
        let artId = sharedFeastArt[feastId] ?? feastId
        if dedicatedFeastHeroIDs.contains(artId) {
            if scheme == .dark {
                return ("Art/feasts/dark", "feast-\(artId)", darkFeastPNGIDs.contains(artId) ? "png" : "jpg")
            }
            return ("Art/feasts", "feast-\(artId)", "jpg")
        }
        return nil
    }

    /// Dark feast art kept as lossless PNG: JPEG nudged their near-black backgrounds by one level.
    private static let darkFeastPNGIDs: Set<String> = [
        "advent-1", "carmel", "christ-the-king", "holy-saturday", "nativity-mary", "sacred-heart"
    ]

    /// The one feast that borrows another feast's dedicated art.
    private static let sharedFeastArt: [String: String] = [
        "mother-of-the-church": "assumption"
    ]

    /// Feasts with dedicated art under `Art/feasts/` (JPEG) and `Art/feasts/dark/`.
    private static let dedicatedFeastHeroIDs: Set<String> = [
        "advent-1", "all-saints", "all-souls", "annunciation", "ascension", "ash-wednesday",
        "assumption", "baptism-movable", "carmel", "christmas", "christ-the-king", "corpus-christi",
        "divine-mercy", "easter", "epiphany", "fatima", "good-friday", "guadalupe", "guardian-angels",
        "holy-cross", "holy-family", "holy-name-mary", "holy-saturday", "holy-thursday",
        "immaculate-conception", "immaculate-heart", "joachim-anne", "john-baptist", "joseph",
        "loreto", "lourdes", "mary-mother-of-god", "michael", "nativity-mary", "palm-sunday",
        "pentecost", "peter-paul", "presentation", "presentation-mary", "queenship", "rosary",
        "sacred-heart", "sorrows", "transfiguration", "trinity", "visitation"
    ]

    /// Scene slugs per set, in mystery order. Matches the files under `Art/{theme}/{set}`.
    static func plateSlugs(set: MysterySetKind) -> [String] {
        switch set {
        case .joyful: return ["01-annunciation", "02-visitation", "03-birth-of-jesus",
                              "04-presentation-of-the-baby-jesus", "05-finding-of-the-child-jesus-in-the-temple"]
        case .luminous: return ["01-baptism-of-jesus-in-the-jordan", "02-miracle-at-the-wedding-at-cana",
                                "03-proclamation-of-the-kingdom-of-god", "04-transfiguration",
                                "05-institution-of-the-holy-eucharist"]
        case .sorrowful: return ["01-agony-in-the-garden", "02-scourging-at-the-pillar", "03-crowning-with-thorns",
                                 "04-carrying-of-the-cross", "05-crucifixion"]
        case .glorious: return ["01-resurrection", "02-ascension", "03-descent-of-the-holy-spirit",
                                "04-assumption", "05-coronation"]
        }
    }

    /// Complete-screen art. Home always shows the set's hero file (`Art/hero`), so the
    /// Complete screen uses one of the set's five scene plates instead, rotating by day of year.
    /// A plate never lives in `Art/hero`, so it can never be the image Home showed.
    static func completionPlate(set: MysterySetKind, date: Date = .now, calendar: Calendar = .current) -> (number: Int, slug: String) {
        let slugs = plateSlugs(set: set)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (day - 1) % slugs.count
        return (index + 1, slugs[index])
    }

    static var crucifix: (directory: String, name: String, ext: String) {
        ("Art", "crucifix", "png")
    }

    /// CSS object-position from art.js FOCUS (tall/square plate).
    static func focus(set: MysterySetKind, number: Int) -> UnitPoint {
        let values: [CGFloat]
        switch set {
        case .joyful: values = [0.30, 0.30, 0.32, 0.34, 0.36]
        case .luminous: values = [0.38, 0.34, 0.32, 0.00, 0.34]
        case .sorrowful: values = [0.30, 0.32, 0.28, 0.28, 0.20]
        case .glorious: values = [0.22, 0.22, 0.28, 0.30, 0.30]
        }
        let y = values[max(0, min(number - 1, 4))]
        return UnitPoint(x: 0.5, y: y)
    }

    /// Home cards show a taller band, anchored toward the faces in each scene.
    /// Values position the crop within the overflow, rather than image coordinates.
    static func cardFocus(set: MysterySetKind, number: Int) -> UnitPoint {
        let values: [CGFloat]
        switch set {
        // Annunciation (0) sits at the top of the plate: dove, Gabriel, and Mary.
        case .joyful: values = [0.0, 0.0, 0.28, 0.12, 0.20]
        case .luminous: values = [0.0, 0.12, 0.15, 0.0, 0.15]
        case .sorrowful: values = [0.15, 0.12, 0.0, 0.0, 0.0]
        case .glorious: values = [0.0, 0.0, 0.0, 0.0, 0.0]
        }
        return UnitPoint(x: 0.5, y: values[max(0, min(number - 1, 4))])
    }

    /// Wide crops of the square set heroes (Pray mystery pages, devotions, feast fallback).
    /// Each value keeps the main figure's face in frame; checked in light and dark art.
    static func heroWideFocus(set: MysterySetKind) -> UnitPoint {
        switch set {
        case .joyful: UnitPoint(x: 0.5, y: 0.10)    // Mary, Joseph and the Child
        case .luminous: UnitPoint(x: 0.5, y: 0.04)  // Christ's face and raised hand
        case .sorrowful: UnitPoint(x: 0.5, y: 0.18) // both faces under the cross
        case .glorious: UnitPoint(x: 0.5, y: 0.02)  // the risen Christ's head and arms
        }
    }

    static func bandFocus(set: MysterySetKind, number: Int) -> UnitPoint {
        let values: [CGFloat]
        switch set {
        case .joyful: values = [0.51, 0.51, 0.56, 0.58, 0.58]
        case .luminous: values = [0.58, 0.58, 0.56, 0.00, 0.58]
        case .sorrowful: values = [0.51, 0.56, 0.45, 0.45, 0.22]
        case .glorious: values = [0.28, 0.28, 0.45, 0.51, 0.51]
        }
        let y = values[max(0, min(number - 1, 4))]
        return UnitPoint(x: 0.5, y: y)
    }

    static func offset(imageSize: CGSize, frame: CGSize, focus: UnitPoint, cropTop: CGFloat? = nil) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, frame.width > 0, frame.height > 0 else {
            return .zero
        }
        let scale = max(frame.width / imageSize.width, frame.height / imageSize.height)
        let extraW = imageSize.width * scale - frame.width
        let extraH = imageSize.height * scale - frame.height
        let scaledH = imageSize.height * scale
        // cropTop is where the visible window begins, as a fraction of the image.
        // The focus point is the center of that window, so it is derived from the frame.
        let focusY: CGFloat
        if let cropTop, extraH > 1, scaledH > 1 {
            let top = min(max(cropTop, 0), extraH / scaledH)
            focusY = top * scaledH / extraH
        } else {
            focusY = focus.y
        }
        return CGSize(width: (0.5 - focus.x) * extraW, height: (0.5 - focusY) * extraH)
    }

    /// Where the figure sits in a feast hero, in image points (origin at the top left).
    struct FeastSubject: Equatable {
        var bounds: CGRect
        /// Horizontal anchor in the upper band of the figure, where faces sit.
        var focusX: CGFloat
    }

    /// Uniform scale and top-leading shift that covers a frame with a feast hero.
    struct FeastCover: Equatable {
        var scale: CGFloat
        var offset: CGSize
    }

    /// The marble figure inside a 1280×720 feast file. Those files letterbox portrait
    /// statues on a flat field; this box is that figure, not the canvas.
    static func feastSubject(of image: UIImage) -> FeastSubject {
        let size = image.size
        let fallback = FeastSubject(bounds: CGRect(origin: .zero, size: size), focusX: size.width / 2)
        guard size.width > 2, size.height > 2 else { return fallback }
        if let box = objc_getAssociatedObject(image, &feastSubjectKey) as? FeastSubjectBox {
            return box.subject
        }
        let subject = detectFeastSubject(image) ?? fallback
        objc_setAssociatedObject(image, &feastSubjectKey, FeastSubjectBox(subject), .OBJC_ASSOCIATION_RETAIN)
        return subject
    }

    /// Fit the full width of a feast file and pin its top edge. Tall containers
    /// leave room below the artwork instead of enlarging it and cropping faces.
    static func feastCover(imageSize: CGSize, frame: CGSize, subject: CGRect, focusX: CGFloat) -> FeastCover {
        guard imageSize.width > 1, imageSize.height > 1, frame.width > 1, frame.height > 1 else {
            return FeastCover(scale: 1, offset: .zero)
        }
        return FeastCover(scale: frame.width / imageSize.width, offset: .zero)
    }

}

private var feastSubjectKey: UInt8 = 0

private final class FeastSubjectBox: NSObject {
    let subject: ArtCatalog.FeastSubject
    init(_ subject: ArtCatalog.FeastSubject) { self.subject = subject }
}

private extension ArtCatalog {
    /// Sampled luminance, row 0 at the top of the image.
    static func detectFeastSubject(_ image: UIImage) -> FeastSubject? {
        let sampleW = 320
        let sampleH = 180
        guard let gray = grayscale(image, width: sampleW, height: sampleH) else { return nil }
        let count = sampleW * sampleH
        guard gray.count == count else { return nil }

        let corner = 8
        var corners: [Float] = []
        corners.reserveCapacity(corner * corner * 4)
        for y in 0..<corner {
            for x in 0..<corner {
                corners.append(Float(gray[y * sampleW + x]))
                corners.append(Float(gray[y * sampleW + (sampleW - 1 - x)]))
                corners.append(Float(gray[(sampleH - 1 - y) * sampleW + x]))
                corners.append(Float(gray[(sampleH - 1 - y) * sampleW + (sampleW - 1 - x)]))
            }
        }
        let sortedCorners = corners.sorted()
        let background = percentile(sortedCorners, 0.5)
        let spread = percentile(sortedCorners, 0.9) - percentile(sortedCorners, 0.1)

        let content: (Int) -> Bool
        if spread > 30, background >= 40, background <= 180 {
            content = { _ in true }
        } else if background >= 170 {
            content = { Float(gray[$0]) < background - 12 }
        } else if background <= 45 {
            content = { Float(gray[$0]) > background + 14 }
        } else {
            content = { _ in true }
        }

        var col = [Int](repeating: 0, count: sampleW)
        var row = [Int](repeating: 0, count: sampleH)
        for y in 0..<sampleH {
            for x in 0..<sampleW {
                if content(y * sampleW + x) {
                    col[x] += 1
                    row[y] += 1
                }
            }
        }
        let colCut = 0.012 * Float(sampleH)
        let rowCut = 0.012 * Float(sampleW)
        guard let minX = col.firstIndex(where: { Float($0) > colCut }),
              let maxX = col.lastIndex(where: { Float($0) > colCut }),
              let minY = row.firstIndex(where: { Float($0) > rowCut }),
              let maxY = row.lastIndex(where: { Float($0) > rowCut }),
              maxX > minX, maxY > minY else {
            return nil
        }
        var left = minX
        var right = maxX
        var top = minY
        var bottom = maxY
        if Float(right - left) < Float(sampleW) * 0.12 || Float(bottom - top) < Float(sampleH) * 0.12 {
            left = 0
            right = sampleW - 1
            top = 0
            bottom = sampleH - 1
        }

        let bandHeight = max(1, Int((0.34 * Float(bottom - top + 1)).rounded(.down)))
        var weightSum: Float = 0
        var moment: Float = 0
        let bandBottom = min(sampleH, top + bandHeight)
        for y in top..<bandBottom {
            for x in left...right where content(y * sampleW + x) {
                weightSum += 1
                moment += Float(x)
            }
        }
        let focusSample = weightSum > 0 ? moment / weightSum : Float(left + right) / 2

        let scaleX = image.size.width / CGFloat(sampleW)
        let scaleY = image.size.height / CGFloat(sampleH)
        let padX = image.size.width * 0.006
        let padY = image.size.height * 0.006
        let x0 = max(0, CGFloat(left) * scaleX - padX)
        let y0 = max(0, CGFloat(top) * scaleY - padY)
        let x1 = min(image.size.width, CGFloat(right + 1) * scaleX + padX)
        let y1 = min(image.size.height, CGFloat(bottom + 1) * scaleY + padY)
        let bounds = CGRect(x: x0, y: y0, width: max(1, x1 - x0), height: max(1, y1 - y0))
        let focusX = min(max(CGFloat(focusSample) * scaleX, bounds.minX), bounds.maxX)
        return FeastSubject(bounds: bounds, focusX: focusX)
    }

    /// Grayscale sample, row 0 at the top (UIKit coordinates).
    static func grayscale(_ image: UIImage, width: Int, height: Int) -> [UInt8]? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        guard let cg = rendered.cgImage,
              cg.width >= width, cg.height >= height,
              let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }
        let bytesPerRow = cg.bytesPerRow
        let bytesPerPixel = max(cg.bitsPerPixel / 8, 1)
        let alpha = cg.alphaInfo
        let order = cg.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue
        let little = order == CGBitmapInfo.byteOrder32Little.rawValue || order == 0
        let alphaFirst = alpha == .premultipliedFirst || alpha == .first || alpha == .noneSkipFirst
        var gray = [UInt8](repeating: 255, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let origin = y * bytesPerRow + x * bytesPerPixel
                let r: UInt8
                let g: UInt8
                let b: UInt8
                if bytesPerPixel >= 4 && alphaFirst && little {
                    // BGRA, the layout UIGraphics uses. Row 0 is the top of the image.
                    b = bytes[origin]
                    g = bytes[origin + 1]
                    r = bytes[origin + 2]
                } else if bytesPerPixel >= 4 && alphaFirst {
                    r = bytes[origin + 1]
                    g = bytes[origin + 2]
                    b = bytes[origin + 3]
                } else if bytesPerPixel >= 3 {
                    r = bytes[origin]
                    g = bytes[origin + 1]
                    b = bytes[origin + 2]
                } else {
                    r = bytes[origin]
                    g = r
                    b = r
                }
                gray[y * width + x] = UInt8((UInt16(r) + UInt16(g) + UInt16(b)) / 3)
            }
        }
        return gray
    }

    static func percentile(_ sorted: [Float], _ p: Float) -> Float {
        guard let first = sorted.first else { return 0 }
        if sorted.count == 1 { return first }
        let index = Int((Float(sorted.count - 1) * p).rounded())
        return sorted[min(max(index, 0), sorted.count - 1)]
    }
}

struct FocusedRasterImage: View {
    @Environment(\.palette) private var palette
    var contentMode: ContentMode = .fill
    var fitAlignment: Alignment = .top
    var directory: String
    var name: String
    var ext: String = "jpg"
    var focus: UnitPoint = UnitPoint(x: 0.5, y: 0.32)
    /// When set, the top of the visible crop is this far down the image (0...1).
    var cropTop: CGFloat? = nil
    /// Feast heroes show the whole image width, top-aligned.
    /// Short cards crop only the bottom; tall heroes never zoom into the scene.
    var coversSubject: Bool = false

    var body: some View {
        GeometryReader { geo in
            if let image = BundleRasterImage.load(directory: directory, name: name, ext: ext) {
                if coversSubject {
                    subjectFill(image, in: geo.size)
                } else {
                    let shift = contentMode == .fit ? CGSize.zero : ArtCatalog.offset(imageSize: image.size, frame: geo.size, focus: focus, cropTop: cropTop)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        // Move the artwork inside the fixed crop, rather than shifting the crop itself.
                        .offset(x: shift.width, y: shift.height)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: contentMode == .fit ? fitAlignment : .center)
                        .clipped()
                }
            } else {
                palette.artworkFallbackBackground
            }
        }
        .clipped()
    }

    private func subjectFill(_ image: UIImage, in frame: CGSize) -> some View {
        let subject = ArtCatalog.feastSubject(of: image)
        let cover = ArtCatalog.feastCover(
            imageSize: image.size,
            frame: frame,
            subject: subject.bounds,
            focusX: subject.focusX
        )
        // Round up so a fractional scale cannot leave a hairline of the card along the edge.
        let width = max((image.size.width * cover.scale).rounded(.up), 1)
        let height = max((image.size.height * cover.scale).rounded(.up), 1)
        return Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
            .fixedSize()
            .overlay(alignment: .bottom) {
                if height < frame.height {
                    LinearGradient(colors: [.clear, palette.bg], startPoint: .top, endPoint: .bottom)
                        .frame(height: height * AppTheme.FeastHero.bottomFade)
                }
            }
            .offset(x: cover.offset.width, y: cover.offset.height)
            .frame(width: frame.width, height: frame.height, alignment: .topLeading)
            .background(palette.bg)
            .clipped()
    }
}

struct BundleRasterImage: View {
    @Environment(\.palette) private var palette
    var directory: String
    var name: String
    var ext: String = "jpg"

    var body: some View {
        if let image = Self.load(directory: directory, name: name, ext: ext) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            palette.artworkFallbackBackground
        }
    }

    private static let cache = NSCache<NSString, UIImage>()

    static func load(directory: String, name: String, ext: String, maxPixel: CGFloat = 1600) -> UIImage? {
        #if canImport(UIKit)
        let key = "\(directory)/\(name).\(ext)#\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        var directories = [directory]
        if !directory.hasPrefix("Art") {
            directories.append("Art/\(directory)")
        }
        let candidates = directories.compactMap {
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: $0)
        } + [Bundle.main.url(forResource: name, withExtension: ext)].compactMap { $0 }

        for url in candidates {
            if let image = downsampled(url: url, maxPixel: maxPixel) {
                cache.setObject(image, forKey: key)
                return image
            }
        }
        #endif
        return nil
    }

    #if canImport(UIKit)
    private static func downsampled(url: URL, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }
        let scale = UITraitCollection.current.displayScale
        let maxDim = max(maxPixel * scale, 1)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDim
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(cgImage: cg)
    }
    #endif
}
