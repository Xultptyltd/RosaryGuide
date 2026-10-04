import Foundation
import SwiftUI
import ImageIO
import UIKit
#if canImport(UIKit)
import UIKit
#endif

/// Paths match WebsiteReference/art.js, rooted at `Art/` in the app bundle.
/// Never ship a top-level `Resources/` folder — iOS codesign treats that as a macOS bundle.
enum ArtCatalog {
    static func plateSlug(for mystery: Mystery) -> String { mystery.artSlug }

    static func platePath(set: MysterySetKind, slug: String, scheme: ColorScheme, wide: Bool) -> (directory: String, name: String) {
        let theme = scheme == .dark ? "dark" : "light"
        let file = wide ? "\(slug)-wide" : slug
        return ("Art/\(theme)/\(set.rawValue)", file)
    }

    static func heroPath(set: MysterySetKind, scheme: ColorScheme, tall: Bool) -> (directory: String, name: String) {
        let theme = scheme == .dark ? "dark" : "light"
        let shape = tall ? "tall" : "wide"
        return ("Art/hero", "\(set.rawValue)-\(theme)-\(shape)")
    }

    /// Feast hero art: dedicated light/dark PNGs under `Art/feasts`, or a mapped mystery wide plate.
    static func feastHeroPath(feastId: String, scheme: ColorScheme) -> (directory: String, name: String, ext: String)? {
        if let plate = feastMysteryPlate(for: feastId) {
            let theme = scheme == .dark ? "dark" : "light"
            return ("Art/\(theme)/\(plate.set.rawValue)", "\(plate.slug)-wide", "jpg")
        }
        if dedicatedFeastHeroIDs.contains(feastId) {
            let directory = scheme == .dark ? "Art/feasts/dark" : "Art/feasts"
            return (directory, feastId, "png")
        }
        return nil
    }

    /// Feasts with dedicated PNGs under `Art/feasts/` and `Art/feasts/dark/`.
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

    static func heroTop(set: MysterySetKind, scheme: ColorScheme) -> Color {
        switch (set, scheme) {
        case (.joyful, .light): Color(hex: 0xFFFCF7)
        case (.joyful, .dark): Color(hex: 0x010101)
        case (.luminous, .light): Color(hex: 0xFFFBF9)
        case (.luminous, .dark): Color(hex: 0x000000)
        case (.sorrowful, .light): Color(hex: 0xF5F5EC)
        case (.sorrowful, .dark): Color(hex: 0x0A0907)
        case (.glorious, .light): Color(hex: 0xF6F7F1)
        case (.glorious, .dark): Color(hex: 0x050505)
        default: scheme == .light ? Color(hex: 0xF6F7F1) : Color(hex: 0x050505)
        }
    }

    static func offset(imageSize: CGSize, frame: CGSize, focus: UnitPoint) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, frame.width > 0, frame.height > 0 else {
            return .zero
        }
        let scale = max(frame.width / imageSize.width, frame.height / imageSize.height)
        let extraW = imageSize.width * scale - frame.width
        let extraH = imageSize.height * scale - frame.height
        return CGSize(width: (0.5 - focus.x) * extraW, height: (0.5 - focus.y) * extraH)
    }
}

struct FocusedRasterImage: View {
    var directory: String
    var name: String
    var ext: String = "jpg"
    var focus: UnitPoint = UnitPoint(x: 0.5, y: 0.32)

    var body: some View {
        GeometryReader { geo in
            if let image = BundleRasterImage.load(directory: directory, name: name, ext: ext) {
                let shift = ArtCatalog.offset(imageSize: image.size, frame: geo.size, focus: focus)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: shift.width, y: shift.height)
                    .clipped()
            } else {
                Color(hex: 0x17181A)
            }
        }
        .clipped()
    }
}

struct BundleRasterImage: View {
    var directory: String
    var name: String
    var ext: String = "jpg"

    var body: some View {
        if let image = Self.load(directory: directory, name: name, ext: ext) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            Color(hex: 0x17181A)
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
