import SwiftUI
import UIKit

extension AppTheme {
    /// Values translated from rosary-background-light.html and rosary-background-dark.html.
    enum AmbientBackground {
        static let lightBase = Color.white
        static let darkBase = Color(hex: 0x090A0C)
        static let glow = AppTheme.marianBlue
        static let blur: CGFloat = 70
        static let fadeStop: CGFloat = 0.65
        static let restingOpacity = 0.85
        static let scaleTravel: CGFloat = 0.08
        static let horizontalTravel: CGFloat = 0.025
        static let verticalTravel: CGFloat = 0.015
        static let frameInterval = 1.0 / 15.0
        static let grainOpacity = 0.05
        static let grainTileSize = 160

        struct Orb {
            let diameter: CGFloat
            let x: CGFloat
            let y: CGFloat
            let viewportAnchored: Bool
            let duration: Double
            let delay: Double
            let lightOpacity: Double
            let darkOpacity: Double
        }
        // First two positions use vmax; third uses vw/vh, matching the CSS.
        static let orbs = [
            Orb(diameter: 0.90, x: -0.35, y: -0.45, viewportAnchored: false,
                duration: 16, delay: 0, lightOpacity: 0.08, darkOpacity: 0.15),
            Orb(diameter: 0.80, x: -0.40, y: -0.35, viewportAnchored: false,
                duration: 20, delay: 7, lightOpacity: 0.05, darkOpacity: 0.10),
            Orb(diameter: 0.55, x: 0.25, y: 0.35, viewportAnchored: true,
                duration: 24, delay: 12, lightOpacity: 0.035, darkOpacity: 0.07)
        ]
    }
}

/// Fixed viewport background for regular app pages; never used in prayer flow or sheets.
struct AppPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    private typealias Token = AppTheme.AmbientBackground

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (colorScheme == .dark ? Token.darkBase : Token.lightBase)
                TimelineView(.animation(minimumInterval: Token.frameInterval,
                                        paused: reduceMotion || !isVisible || scenePhase != .active)) { timeline in
                    ZStack(alignment: .topLeading) {
                        ForEach(Token.orbs.indices, id: \.self) { index in
                            orb(Token.orbs[index], index: index, size: geometry.size, date: timeline.date)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                }
                Image(uiImage: Self.grain)
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity(Token.grainOpacity)
            }
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private func orb(_ token: Token.Orb, index: Int, size: CGSize, date: Date) -> some View {
        let vmax = max(size.width, size.height)
        let diameter = token.diameter * vmax
        let phase = (date.timeIntervalSinceReferenceDate + token.delay)
            .truncatingRemainder(dividingBy: token.duration) / token.duration
        let breath = reduceMotion ? 0 : (1 - cos(phase * 2 * .pi)) / 2
        let x = token.viewportAnchored ? token.x * size.width
            : index == 1 ? size.width - token.x * vmax - diameter : token.x * vmax
        let y = token.viewportAnchored ? token.y * size.height
            : index == 1 ? size.height - token.y * vmax - diameter : token.y * vmax
        return Circle()
            .fill(RadialGradient(stops: [
                .init(color: Token.glow.opacity(colorScheme == .dark ? token.darkOpacity : token.lightOpacity), location: 0),
                .init(color: Token.glow.opacity(0), location: Token.fadeStop)
            ], center: .center, startRadius: 0, endRadius: diameter / sqrt(2)))
            .frame(width: diameter, height: diameter)
            .blur(radius: Token.blur)
            .scaleEffect(1 + Token.scaleTravel * breath)
            .opacity(reduceMotion ? 1 : Token.restingOpacity + (1 - Token.restingOpacity) * breath)
            .offset(x: x + Token.horizontalTravel * vmax * breath,
                    y: y + Token.verticalTravel * vmax * breath)
    }

    /// A small, deterministic, cached texture; animation never regenerates the grain.
    private static let grain: UIImage = {
        let side = AppTheme.AmbientBackground.grainTileSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            var seed: UInt32 = 0x524F5341
            for y in 0..<side {
                for x in 0..<side {
                    seed = 1664525 &* seed &+ 1013904223
                    let shade = CGFloat(seed >> 24) / 255
                    context.cgContext.setFillColor(UIColor(white: shade, alpha: 1).cgColor)
                    context.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }()
}
