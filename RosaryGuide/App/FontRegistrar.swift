import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreText

enum FontRegistrar {
    static func register() {
        let files = ["InstrumentSans.ttf", "Newsreader.ttf", "Newsreader-Italic.ttf"]
        for file in files {
            let name = (file as NSString).deletingPathExtension
            let ext = (file as NSString).pathExtension
            guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Fonts")
                    ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Fonts")
                    ?? Bundle.main.url(forResource: name, withExtension: ext) else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
