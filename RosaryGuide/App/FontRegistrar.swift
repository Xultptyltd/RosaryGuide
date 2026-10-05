import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import CoreText

/// Registers Instrument Sans and Newsreader from `Fonts/` (never a top-level `Resources/` folder)
/// and resolves SwiftUI fonts via UIFont so variable-axis weight / optical size actually apply.
enum FontRegistrar {
    private static let sansCandidates = [
        "InstrumentSans-Regular",
        "Instrument Sans",
        "InstrumentSans"
    ]
    private static let serifCandidates = [
        "Newsreader16pt-Regular",
        "Newsreader 16pt",
        "Newsreader",
        "NewsreaderRoman-Regular"
    ]
    private static let serifItalicCandidates = [
        "Newsreader16pt-Italic",
        "Newsreader 16pt Italic",
        "Newsreader-Italic"
    ]

    static func register() {
        let files = ["InstrumentSans.ttf", "Newsreader.ttf", "Newsreader-Italic.ttf"]
        for file in files {
            let name = (file as NSString).deletingPathExtension
            let ext = (file as NSString).pathExtension
            guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Fonts")
                    ?? Bundle.main.url(forResource: name, withExtension: ext) else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        #if canImport(UIKit)
        Font(sansUI(size, weight: weight, textStyle: uiTextStyle(textStyle)))
        #else
        Font.custom("InstrumentSans-Regular", size: size, relativeTo: textStyle)
        #endif
    }

    static func serif(_ size: CGFloat, italic: Bool = false, opticalSize: CGFloat? = nil, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        #if canImport(UIKit)
        Font(serifUI(size, italic: italic, opticalSize: opticalSize, textStyle: uiTextStyle(textStyle)))
        #else
        Font.custom(italic ? "Newsreader16pt-Italic" : "Newsreader16pt-Regular", size: size, relativeTo: textStyle)
        #endif
    }

    #if canImport(UIKit)
    static func uiTextStyle(_ textStyle: Font.TextStyle) -> UIFont.TextStyle {
        switch textStyle {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .caption: return .caption1
        case .caption2: return .caption2
        case .footnote: return .footnote
        default: return .body
        }
    }

    static func sansUI(_ size: CGFloat, weight: Font.Weight = .regular, textStyle: UIFont.TextStyle = .body) -> UIFont {
        let weightAxis = axisWeight(weight)
        let key = cacheKey(kind: "sans", size: size, axes: "wght=\(weightAxis)", textStyle: textStyle)
        if let cached = uiFontCache[key] { return cached }
        let base = variableFont(
            names: sansCandidates,
            size: size,
            variations: ["wght": weightAxis],
            serifFallback: false
        )
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        uiFontCache[key] = scaled
        return scaled
    }

    static func serifUI(_ size: CGFloat, italic: Bool = false, opticalSize: CGFloat? = nil, textStyle: UIFont.TextStyle = .body) -> UIFont {
        let opsz = min(max(opticalSize ?? size, 6), 72)
        let key = cacheKey(kind: italic ? "serifI" : "serif", size: size, axes: "wght=400,opsz=\(opsz)", textStyle: textStyle)
        if let cached = uiFontCache[key] { return cached }
        let base = variableFont(
            names: italic ? serifItalicCandidates : serifCandidates,
            size: size,
            variations: ["wght": 400, "opsz": opsz],
            serifFallback: true
        )
        let scaled = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        uiFontCache[key] = scaled
        return scaled
    }

    /// Scene-update watchdog stacks land in `CTFontDescriptorCreateCopyWithAttributes`
    /// because every text view built a new variation font. Cache the scaled
    /// result so a pray-screen update does not re-enter Core Text.
    private static var uiFontCache: [String: UIFont] = [:]

    private static func cacheKey(kind: String, size: CGFloat, axes: String, textStyle: UIFont.TextStyle) -> String {
        let category = UIApplication.shared.preferredContentSizeCategory.rawValue
        return "\(kind)|\(size)|\(axes)|\(textStyle.rawValue)|\(category)"
    }

    private static func axisWeight(_ weight: Font.Weight) -> CGFloat {
        if weight == .ultraLight { return 200 }
        if weight == .thin || weight == .light { return 300 }
        if weight == .medium { return 500 }
        if weight == .semibold { return 600 }
        if weight == .bold { return 700 }
        if weight == .heavy || weight == .black { return 800 }
        return 400
    }

    private static func variableFont(
        names: [String],
        size: CGFloat,
        variations: [String: CGFloat],
        serifFallback: Bool
    ) -> UIFont {
        let fallback: UIFont = {
            if serifFallback, let serif = UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif) {
                return UIFont(descriptor: serif, size: size)
            }
            return UIFont.systemFont(ofSize: size, weight: .regular)
        }()
        guard let base = names.compactMap({ UIFont(name: $0, size: size) }).first else {
            return fallback
        }
        var axis: [NSNumber: CGFloat] = [:]
        for (tag, value) in variations {
            axis[NSNumber(value: fourCharCode(tag))] = value
        }
        let copy = CTFontDescriptorCreateCopyWithAttributes(
            base.fontDescriptor as CTFontDescriptor,
            [kCTFontVariationAttribute: axis] as CFDictionary
        )
        return CTFontCreateWithFontDescriptor(copy, size, nil) as UIFont
    }

    private static func fourCharCode(_ tag: String) -> UInt32 {
        var result: UInt32 = 0
        for byte in tag.utf8.prefix(4) {
            result = (result << 8) | UInt32(byte)
        }
        return result
    }
    #endif
}
