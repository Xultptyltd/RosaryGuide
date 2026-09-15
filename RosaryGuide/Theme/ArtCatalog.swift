import Foundation
import SwiftUI
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

    static func load(directory: String, name: String, ext: String) -> UIImage? {
        #if canImport(UIKit)
        var directories = [
            directory,
            directory.replacingOccurrences(of: "Resources/", with: "")
        ]
        if !directory.hasPrefix("Resources/") && !directory.hasPrefix("Art") {
            directories.append("Art/\(directory)")
        }
        if directory.hasPrefix("Art/") {
            directories.append("Resources/\(directory)")
        }
        let candidates = directories.flatMap { dir in
            [Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir)]
        } + [Bundle.main.url(forResource: name, withExtension: ext)]
        for url in candidates.compactMap({ $0 }) {
            if let image = UIImage(contentsOfFile: url.path) { return image }
        }
        #endif
        return nil
    }
}
