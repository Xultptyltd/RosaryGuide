import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Full rosary map: crucifix tail and five decades, highlighting the current bead.
struct RosaryBeadMapView: View {
    var locus: BeadLocus?
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let crucifixImage: UIImage? = {
        #if canImport(UIKit)
        BundleRasterImage.load(
            directory: ArtCatalog.crucifix.directory,
            name: ArtCatalog.crucifix.name,
            ext: ArtCatalog.crucifix.ext,
            maxPixel: 256
        )
        #else
        nil
        #endif
    }()

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .frame(height: 168)
        .accessibilityLabel("Rosary beads")
        .accessibilityValue(valueLabel)
    }

    private var valueLabel: String {
        switch locus {
        case .crucifix: "Crucifix"
        case .openingOurFather: "Opening Our Father"
        case .openingHail(let n): "Opening Hail Mary \(n)"
        case .openingGlory: "Opening Glory Be"
        case .decadeOurFather(let d): "Decade \(d) Our Father"
        case .decadeHail(let d, let n): "Decade \(d), Hail Mary \(n)"
        case .decadeGlory(let d): "Decade \(d) Glory Be"
        case .decadeFatima(let d): "Decade \(d) Fatima prayer"
        case .closing: "Closing"
        case .none: "Rosary"
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let loop = CGRect(x: 18, y: 8, width: size.width - 36, height: size.height - 58)
        let loopCenter = CGPoint(x: loop.midX, y: loop.midY + 4)
        let rx = loop.width / 2 - 6
        let ry = loop.height / 2 - 4

        var cord = Path()
        cord.addEllipse(in: CGRect(x: loopCenter.x - rx, y: loopCenter.y - ry, width: rx * 2, height: ry * 2))
        let tailTop = CGPoint(x: cx, y: loopCenter.y + ry)
        cord.move(to: tailTop)
        cord.addLine(to: CGPoint(x: cx, y: size.height - 8))
        context.stroke(cord, with: .color(palette.dim.opacity(0.45)), lineWidth: 1.15)

        // Loop: 5 decades of 10, with OF beads at 0, 11, 22... around the oval starting at 6 o'clock going clockwise.
        let totalLoop = 55 // 5 OF + 50 Hail Marys
        for i in 0..<totalLoop {
            let t = Double(i) / Double(totalLoop)
            let angle = .pi / 2 + t * .pi * 2 // start bottom, clockwise
            let p = CGPoint(x: loopCenter.x + cos(angle) * rx, y: loopCenter.y + sin(angle) * ry)
            let decadeIndex = i / 11 + 1 // 1...5
            let posInDecade = i % 11
            let isOF = posInDecade == 0
            let state: BeadState
            if isOF {
                state = match(.decadeOurFather(decadeIndex))
            } else {
                state = match(.decadeHail(decadeIndex, posInDecade))
            }
            drawPearl(&context, at: p, large: isOF, state: state)
        }

        // Tail: medal, 3 Hail Marys, OF, crucifix (top to bottom from loop join)
        let tailYs: [CGFloat] = [
            loopCenter.y + ry + 2,
            loopCenter.y + ry + 16,
            loopCenter.y + ry + 28,
            loopCenter.y + ry + 40,
            size.height - 20
        ]
        drawMedal(&context, at: CGPoint(x: cx, y: tailYs[0]), state: match(.closing))
        drawPearl(&context, at: CGPoint(x: cx, y: tailYs[1]), large: false, state: match(.openingHail(1)))
        drawPearl(&context, at: CGPoint(x: cx, y: tailYs[2]), large: false, state: match(.openingHail(2)))
        drawPearl(&context, at: CGPoint(x: cx, y: tailYs[3]), large: false, state: match(.openingHail(3)))
        // Opening OF sits just above crucifix; Glory sits near medal.
        drawPearl(&context, at: CGPoint(x: cx - 14, y: tailYs[1] - 2), large: true, state: match(.openingOurFather))
        drawPearl(&context, at: CGPoint(x: cx + 14, y: tailYs[0] + 6), large: true, state: match(.openingGlory))
        drawCrucifix(&context, at: CGPoint(x: cx, y: size.height - 10), state: match(.crucifix))
    }

    private enum BeadState { case future, now, done }

    private func match(_ candidate: BeadLocus) -> BeadState {
        guard let locus else { return .future }
        if locus == candidate { return .now }
        if isPast(candidate, current: locus) { return .done }
        return .future
    }

    private func isPast(_ bead: BeadLocus, current: BeadLocus) -> Bool {
        order(bead) < order(current)
    }

    private func order(_ bead: BeadLocus) -> Int {
        switch bead {
        case .crucifix: 0
        case .openingOurFather: 1
        case .openingHail(let n): 1 + n
        case .openingGlory: 5
        case .decadeOurFather(let d): 100 * d
        case .decadeHail(let d, let n): 100 * d + n
        case .decadeGlory(let d): 100 * d + 11
        case .decadeFatima(let d): 100 * d + 12
        case .closing: 1000
        }
    }

    private func drawPearl(_ context: inout GraphicsContext, at p: CGPoint, large: Bool, state: BeadState) {
        let r: CGFloat = large ? 5.2 : 3.6
        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        let fill: Color
        switch state {
        case .future: fill = palette.ink.opacity(0.22)
        case .now: fill = palette.ink.opacity(0.55)
        case .done: fill = palette.ink
        }
        context.fill(Path(ellipseIn: rect), with: .color(fill))
        if state == .now {
            var ring = Path(ellipseIn: rect.insetBy(dx: -3, dy: -3))
            context.stroke(ring, with: .color(palette.accent.opacity(0.7)), lineWidth: 1)
        }
    }

    private func drawMedal(_ context: inout GraphicsContext, at p: CGPoint, state: BeadState) {
        let r: CGFloat = 6
        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .color(palette.dim.opacity(state == .future ? 0.35 : 0.85)))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 1.4, dy: 1.4)), with: .color(palette.prayBg), lineWidth: 0.8)
    }

    private func drawCrucifix(_ context: inout GraphicsContext, at p: CGPoint, state: BeadState) {
        let rect = CGRect(x: p.x - 8, y: p.y - 16, width: 16, height: 22)
        if let ui = Self.crucifixImage {
            context.opacity = state == .future ? 0.38 : 1
            context.draw(Image(uiImage: ui), in: rect)
            context.opacity = 1
        } else {
            let ink = palette.ink.opacity(state == .future ? 0.28 : 1)
            let upright = CGRect(x: p.x - 1.2, y: p.y - 9, width: 2.4, height: 14)
            let beam = CGRect(x: p.x - 4.5, y: p.y - 5, width: 9, height: 2.2)
            context.fill(Path(upright), with: .color(ink))
            context.fill(Path(beam), with: .color(ink))
        }
        if state == .now {
            context.stroke(Path(ellipseIn: CGRect(x: p.x - 10, y: p.y - 16, width: 20, height: 24)), with: .color(palette.accent.opacity(0.7)), lineWidth: 1)
        }
    }
}

struct SevenStageTrack: View {
    var current: PrayTrackStage
    var jump: (PrayTrackStage) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PrayTrackStage.allCases, id: \.rawValue) { stage in
                Button {
                    jump(stage)
                } label: {
                    Capsule()
                        .fill(barColor(stage))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(stage.label)
            }
        }
        .padding(.bottom, 4)
    }

    private func barColor(_ stage: PrayTrackStage) -> Color {
        if stage == current { return palette.ink }
        if stage.rawValue < current.rawValue { return palette.ink.opacity(0.28) }
        return palette.ink.opacity(0.12)
    }
}
