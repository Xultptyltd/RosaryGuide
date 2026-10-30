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

    /// Feast hero art: dedicated light/dark PNGs under `Art/feasts`, or a mapped mystery wide plate.
    static func feastHeroPath(feastId: String, scheme: ColorScheme) -> (directory: String, name: String, ext: String)? {
        if let plate = feastMysteryPlate(for: feastId) {
            let theme = scheme == .dark ? "dark" : "light"
            return ("Art/\(theme)/\(plate.set.rawValue)", "mystery-\(plate.slug)", "jpg")
        }
        if dedicatedFeastHeroIDs.contains(feastId) {
            if scheme == .dark {
                return ("Art/feasts/dark", "feast-\(feastId)", darkFeastPNGIDs.contains(feastId) ? "png" : "jpg")
            }
            return ("Art/feasts", "feast-\(feastId)", "jpg")
        }
        return nil
    }

    /// Dark feast art kept as lossless PNG: JPEG nudged their near-black backgrounds by one level.
    private static let darkFeastPNGIDs: Set<String> = [
        "advent-1", "carmel", "christ-the-king", "holy-saturday", "nativity-mary", "sacred-heart"
    ]

    /// Feasts with dedicated art under `Art/feasts/` (JPEG) and `Art/feasts/dark/`.
    private static let dedicatedFeastHeroIDs: Set<String> = [
        "advent-1", "all-saints", "all-souls", "ash-wednesday", "carmel", "christ-the-king",
        "epiphany", "fatima", "guadalupe", "guardian-angels", "holy-name-mary", "holy-saturday",
        "immaculate-conception", "immaculate-heart", "joseph", "lourdes", "mary-mother-of-god",
        "michael", "nativity-mary", "palm-sunday", "peter-paul", "presentation-mary", "rosary",
        "sacred-heart", "sorrows", "trinity"
    ]

    /// Feasts that reuse an existing mystery wide plate (light/dark via Art/{theme}/…).
    private static func feastMysteryPlate(for feastId: String) -> (set: MysterySetKind, slug: String)? {
        switch feastId {
        case "annunciation": return (.joyful, "01-annunciation")
        case "visitation": return (.joyful, "02-visitation")
        case "christmas": return (.joyful, "03-birth-of-jesus")
        case "presentation": return (.joyful, "04-presentation-of-the-baby-jesus")
        case "baptism-movable": return (.luminous, "01-baptism-of-jesus-in-the-jordan")
        case "holy-thursday", "corpus-christi": return (.luminous, "05-institution-of-the-holy-eucharist")
        case "good-friday": return (.sorrowful, "05-crucifixion")
        case "easter", "divine-mercy": return (.glorious, "01-resurrection")
        case "ascension": return (.glorious, "02-ascension")
        case "pentecost": return (.glorious, "03-descent-of-the-holy-spirit")
        case "assumption", "mother-of-the-church": return (.glorious, "04-assumption")
        case "queenship": return (.glorious, "05-coronation")
        default: return nil
        }
    }

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
        case .joyful: values = [0.15, 0.0, 0.28, 0.12, 0.20]
        case .luminous: values = [0.0, 0.12, 0.15, 0.0, 0.15]
        case .sorrowful: values = [0.15, 0.12, 0.0, 0.0, 0.0]
        case .glorious: values = [0.0, 0.0, 0.0, 0.0, 0.0]
        }
        return UnitPoint(x: 0.5, y: values[max(0, min(number - 1, 4))])
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

    var body: some View {
        GeometryReader { geo in
            if let image = BundleRasterImage.load(directory: directory, name: name, ext: ext) {
                let shift = contentMode == .fit ? CGSize.zero : ArtCatalog.offset(imageSize: image.size, frame: geo.size, focus: focus, cropTop: cropTop)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: contentMode == .fit ? fitAlignment : .center)
                    .offset(x: shift.width, y: shift.height)
                    .clipped()
            } else {
                palette.artworkFallbackBackground
            }
        }
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
