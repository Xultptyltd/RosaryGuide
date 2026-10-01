import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Website-faithful rosary map: crucifix pendant on the left, flat stadium loop on the right.
/// Geometry follows `buildRosary()` in rosaryguide.app (W≈330, H≈64, lx=96, lh=48).
struct RosaryBeadMapView: View {
    var locus: BeadLocus?
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
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

    private let layout = RosaryGeometry.shared

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let s = min(size.width / layout.viewW, size.height / layout.viewH)
                let ox = (size.width - layout.viewW * s) / 2
                let oy = (size.height - layout.viewH * s) / 2
                context.translateBy(x: ox, y: oy)
                context.scaleBy(x: s, y: s)
                paint(&context, phase: pulsePhase(at: timeline.date))
            }
        }
        .frame(height: 118)
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

    private func pulsePhase(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let cycle = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.35) / 1.35
        return CGFloat(cycle)
    }

    private func paint(_ context: inout GraphicsContext, phase: CGFloat) {
        let cord = mix(palette.dim, onto: palette.prayBg, amount: colorScheme == .light ? 0.55 : 0.40)
        // Draw cord only between beads (website pearls sit on top of an opaque cord gap).
        paintCordSegments(&context, color: cord)
        paintPulse(&context, phase: phase)

        for bead in layout.beads {
            let state = state(of: bead.locus)
            if bead.isSpace {
                paintSpace(&context, at: bead.point, state: state)
            } else {
                paintPearl(&context, at: bead.point, large: bead.large, state: state)
            }
        }
        paintMedal(&context, at: layout.medal, state: state(of: .closing))
        paintCrucifix(&context, at: layout.crucifix, state: state(of: .crucifix))
    }

    private func paintCordSegments(_ context: inout GraphicsContext, color: Color) {
        // Stroke the real stadium + pendant paths (website). Straight bead-to-bead
        // chords cut diagonals across the loop corners.
        context.stroke(layout.pendantPath, with: .color(color), lineWidth: 1.15)
        context.stroke(layout.loopPath, with: .color(color), lineWidth: 1.15)
    }

    private func paintPulse(_ context: inout GraphicsContext, phase: CGFloat) {
        guard let target = pulseTarget else { return }
        let wave = reduceMotion ? 0.45 : easeOutCubic(phase)
        let outerRadius = target.baseRadius + target.expansion * wave
        let innerRadius = max(target.baseRadius * 0.62, target.baseRadius - target.expansion * 0.16)
        let outerOpacity = reduceMotion ? 0.30 : 0.52 * (1 - Double(wave))
        let fillOpacity = reduceMotion ? 0.18 : 0.34 * (1 - Double(wave))

        let outer = circleRect(center: target.point, radius: outerRadius)
        let inner = circleRect(center: target.point, radius: innerRadius)
        context.fill(Path(ellipseIn: inner), with: .color(palette.beadPulseFill.opacity(fillOpacity)))
        context.stroke(Path(ellipseIn: outer), with: .color(palette.beadPulseStroke.opacity(outerOpacity)), lineWidth: target.lineWidth)
    }

    private func easeOutCubic(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return 1 - pow(1 - t, 3)
    }

    private func circleRect(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private struct PulseTarget {
        var point: CGPoint
        var baseRadius: CGFloat
        var expansion: CGFloat
        var lineWidth: CGFloat
    }

    private var pulseTarget: PulseTarget? {
        guard let locus else { return nil }
        switch locus {
        case .crucifix:
            return PulseTarget(point: layout.crucifix, baseRadius: 14, expansion: 13, lineWidth: 1.6)
        case .closing:
            return PulseTarget(point: layout.medal, baseRadius: 13, expansion: 12, lineWidth: 1.5)
        default:
            guard let bead = layout.beads.first(where: { matches(locus, $0.locus) }) else { return nil }
            if bead.isSpace {
                return PulseTarget(point: bead.point, baseRadius: 6.5, expansion: 5.2, lineWidth: 1.0)
            }
            return PulseTarget(
                point: bead.point,
                baseRadius: bead.large ? 6.6 : 4.8,
                expansion: bead.large ? 5.4 : 4.0,
                lineWidth: bead.large ? 1.05 : 0.9
            )
        }
    }

    private enum State { case future, now, done }

    private func state(of candidate: BeadLocus) -> State {
        guard let locus else { return .future }
        if matches(locus, candidate) { return .now }
        if order(candidate) < order(locus) { return .done }
        return .future
    }

    private func matches(_ a: BeadLocus, _ b: BeadLocus) -> Bool {
        if a == b { return true }
        // Glory + Fatima share the chain space on the website
        if case .decadeGlory(let d) = a, case .decadeFatima(let f) = b, d == f { return true }
        if case .decadeFatima(let d) = a, case .decadeGlory(let g) = b, d == g { return true }
        return false
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

    private func paintPearl(_ context: inout GraphicsContext, at p: CGPoint, large: Bool, state: State) {
        let r: CGFloat = large ? 3.45 : 2.25
        let disk = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        // Opaque underlay so the cord never shows through (website pearls are color-mix solids).
        context.fill(Path(ellipseIn: disk), with: .color(palette.prayBg))
        let fill = pearlColor(state)
        context.fill(Path(ellipseIn: disk), with: .color(fill))
        let sr = max(0.38, r * 0.19)
        let shine = CGRect(x: p.x - r * 0.40 - sr, y: p.y - r * 0.44 - sr, width: sr * 2, height: sr * 2)
        let shineOp: Double = state == .future
            ? (colorScheme == .light ? 0.62 : 0.38)
            : (colorScheme == .light ? 0.32 : 0.22)
        context.fill(Path(ellipseIn: shine), with: .color(palette.beadHighlight.opacity(shineOp)))
    }

    /// Website `color-mix(in srgb, var(--text) N%, var(--bg))` — opaque, not alpha.
    private func pearlColor(_ state: State) -> Color {
        let amount: CGFloat
        switch state {
        case .future: amount = 0.34
        case .now: amount = colorScheme == .light ? 0.55 : 0.48
        case .done: amount = 0.74
        }
        return mix(palette.ink, onto: palette.prayBg, amount: amount)
    }

    private func mix(_ fg: Color, onto bg: Color, amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let f = UIColor(fg)
        let b = UIColor(bg)
        var fr = CGFloat(0), fg_ = CGFloat(0), fb = CGFloat(0), fa = CGFloat(0)
        var br = CGFloat(0), bg_ = CGFloat(0), bb = CGFloat(0), ba = CGFloat(0)
        f.getRed(&fr, green: &fg_, blue: &fb, alpha: &fa)
        b.getRed(&br, green: &bg_, blue: &bb, alpha: &ba)
        let t = amount
        return Color(
            red: br + (fr - br) * t,
            green: bg_ + (fg_ - bg_) * t,
            blue: bb + (fb - bb) * t
        )
        #else
        return fg.opacity(Double(amount))
        #endif
    }

    private func paintSpace(_ context: inout GraphicsContext, at p: CGPoint, state: State) {
        switch state {
        case .future:
            return
        case .now:
            var tick = Path()
            tick.move(to: CGPoint(x: p.x - 3.4, y: p.y))
            tick.addLine(to: CGPoint(x: p.x + 3.4, y: p.y))
            context.stroke(tick, with: .color(palette.accent), lineWidth: 2.6)
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)),
                with: .color(palette.accent.opacity(0.18))
            )
        case .done:
            let r: CGFloat = 2.0
            let disk = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: disk), with: .color(palette.prayBg))
            context.fill(Path(ellipseIn: disk), with: .color(mix(palette.ink, onto: palette.prayBg, amount: 0.85)))
        }
    }

    private func paintMedal(_ context: inout GraphicsContext, at p: CGPoint, state: State) {
        let rim = CGRect(x: p.x - 9.3, y: p.y - 6.75, width: 18.6, height: 13.5)
        let field = CGRect(x: p.x - 7.4, y: p.y - 5.18, width: 14.8, height: 10.36)
        let rimFill = state == .future ? palette.beadMedalRimFuture : palette.beadMedalRim
        let fieldFill = palette.beadMedalField
        context.fill(Path(ellipseIn: rim), with: .color(rimFill))
        context.fill(Path(ellipseIn: field), with: .color(fieldFill))
        var m = Path()
        m.move(to: CGPoint(x: p.x - 2.2, y: p.y + 2.0))
        m.addLine(to: CGPoint(x: p.x - 2.2, y: p.y - 1.5))
        m.addLine(to: CGPoint(x: p.x, y: p.y + 0.55))
        m.addLine(to: CGPoint(x: p.x + 2.2, y: p.y - 1.5))
        m.addLine(to: CGPoint(x: p.x + 2.2, y: p.y + 2.0))
        context.stroke(m, with: .color(palette.beadMedalGlyph), lineWidth: 0.7)
    }

    private func paintCrucifix(_ context: inout GraphicsContext, at p: CGPoint, state: State) {
        let cxH: CGFloat = 40
        let cxW = cxH * 0.503
        context.opacity = state == .future ? (colorScheme == .light ? 0.88 : 0.80) : 1
        context.translateBy(x: p.x, y: p.y)
        context.rotate(by: .degrees(90))
        if let ui = Self.crucifixImage {
            context.draw(Image(uiImage: ui), in: CGRect(x: -cxW / 2, y: -cxH / 2, width: cxW, height: cxH))
        } else {
            let ink = palette.ink.opacity(0.9)
            context.fill(Path(CGRect(x: -1.15, y: -cxH / 2, width: 2.3, height: cxH)), with: .color(ink))
            context.fill(Path(CGRect(x: -cxW * 0.42, y: -cxH * 0.18, width: cxW * 0.84, height: 2.3)), with: .color(ink))
        }
        context.rotate(by: .degrees(-90))
        context.translateBy(x: -p.x, y: -p.y)
        context.opacity = 1
    }
}

// MARK: - Geometry (web buildRosary proportions)

private struct RosaryBead {
    var locus: BeadLocus
    var point: CGPoint
    var large: Bool
    var isSpace: Bool
}

private struct CordNode {
    var point: CGPoint
    var radius: CGFloat
}

private struct RosaryGeometry {
    static let shared = RosaryGeometry()

    let viewW: CGFloat
    let viewH: CGFloat
    let medal: CGPoint
    let crucifix: CGPoint
    let pendantPath: Path
    let loopPath: Path
    let beads: [RosaryBead]
    /// Crucifix → pendant beads → medal → loop beads → medal (for segmented cord).
    let cordNodes: [CordNode]

    init() {
        // Web constants
        let lx: CGFloat = 96
        let ly: CGFloat = 8
        let lh: CGFloat = 48
        let pad: CGFloat = 14
        let W: CGFloat = 330
        let lw = W - lx - pad
        let r = lh / 2
        let H = lh + ly * 2
        let cy = ly + r

        let rHM: CGFloat = 2.25
        let rOF: CGFloat = 3.45
        let rMedal: CGFloat = 9.3
        let gapHM: CGFloat = 1.5
        let gapOF: CGFloat = 7.2 // approximate leftover cord around OF / spaces

        // Stadium path
        var loop = Path()
        loop.move(to: CGPoint(x: lx + r, y: ly))
        loop.addLine(to: CGPoint(x: lx + lw - r, y: ly))
        loop.addArc(center: CGPoint(x: lx + lw - r, y: ly + r), radius: r,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        loop.addLine(to: CGPoint(x: lx + lw, y: ly + lh - r))
        loop.addArc(center: CGPoint(x: lx + lw - r, y: ly + lh - r), radius: r,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        loop.addLine(to: CGPoint(x: lx + r, y: ly + lh))
        loop.addArc(center: CGPoint(x: lx + r, y: ly + lh - r), radius: r,
                    startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        loop.addLine(to: CGPoint(x: lx, y: ly + r))
        loop.addArc(center: CGPoint(x: lx + r, y: ly + r), radius: r,
                    startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        loop.closeSubpath()

        // Loop bead order from join (left mid), clockwise
        var specs: [(BeadLocus, Bool, Bool)] = []
        specs.append((.decadeOurFather(1), true, false))
        for i in 1...10 { specs.append((.decadeHail(1, i), false, false)) }
        specs.append((.decadeGlory(1), false, true))
        for d in 2...5 {
            specs.append((.decadeOurFather(d), true, false))
            for i in 1...10 { specs.append((.decadeHail(d, i), false, false)) }
            specs.append((.decadeGlory(d), false, true))
        }

        func radius(large: Bool, space: Bool) -> CGFloat {
            if space { return 2.0 }
            return large ? rOF : rHM
        }

        // Place evenly with HM clustering + OF gaps, starting just past medal join
        let perimeter = 2 * (lw - 2 * r) + 2 * .pi * r
        var distances: [CGFloat] = []
        // medal → first loop bead (decade 1 Our Father)
        distances.append(rMedal + rOF + gapOF * 0.55)
        for i in 0..<(specs.count - 1) {
            let a = specs[i], b = specs[i + 1]
            let ra = radius(large: a.1, space: a.2)
            let rb = radius(large: b.1, space: b.2)
            let tight = !a.1 && !a.2 && !b.1 && !b.2
            let aroundSpace = a.2 || b.2
            let extra: CGFloat = tight ? gapHM : (aroundSpace ? gapOF * 0.55 : gapOF)
            distances.append(ra + rb + extra)
        }
        // last space → medal (unused for placement, keeps sum honest)
        let sum = distances.reduce(0, +) + rMedal + 2.0 + gapOF * 0.4
        let scale = perimeter / max(sum, 1)

        func pointOnStadium(distance: CGFloat) -> CGPoint {
            // Parameterize clockwise from left-mid (join)
            // Segments: top-left quarter-arc up, top, right arc, bottom, left-lower arc back
            let straight = lw - 2 * r
            let halfArc = .pi * r
            let leftHalf = halfArc / 2
            var d = distance.truncatingRemainder(dividingBy: perimeter)
            if d < 0 { d += perimeter }

            // From left-mid going UP (to top). SwiftUI y grows downward, so the
            // upper-left quarter uses 180° → 270° (sin goes negative / upward).
            // The old 180° → 90° path walked below the join, which put decade-1
            // Our Father + early Hail Marys on the wrong side of the loop until
            // distance cleared leftHalf and jumped onto the top rail.
            // Path: left-mid → top via upper-left arc, across top, right, bottom, lower-left arc.
            if d <= leftHalf {
                let a = .pi + (d / r) // 180° → 270°
                return CGPoint(x: lx + r + cos(a) * r, y: ly + r + sin(a) * r)
            }
            d -= leftHalf
            if d <= straight {
                return CGPoint(x: lx + r + d, y: ly)
            }
            d -= straight
            if d <= halfArc {
                let a = -.pi / 2 + (d / r)
                return CGPoint(x: lx + lw - r + cos(a) * r, y: ly + r + sin(a) * r)
            }
            d -= halfArc
            if d <= straight {
                return CGPoint(x: lx + lw - r - d, y: ly + lh)
            }
            d -= straight
            // bottom-left half arc: 90° → 180°
            let a = .pi / 2 + (d / r)
            return CGPoint(x: lx + r + cos(a) * r, y: ly + lh - r + sin(a) * r)
        }

        var loopBeads: [RosaryBead] = []
        var cursor = distances[0] * scale
        for (i, spec) in specs.enumerated() {
            let p = pointOnStadium(distance: cursor)
            loopBeads.append(RosaryBead(locus: spec.0, point: p, large: spec.1, isSpace: spec.2))
            if i + 1 < distances.count {
                cursor += distances[i + 1] * scale
            }
        }

        // Pendant: out from medal — intro glory space, HM3, HM2, HM1, opening OF.
        // The first decade's Our Father lives on the first large bead of the loop.
        let pend: [(BeadLocus, Bool, Bool)] = [
            (.openingGlory, false, true),
            (.openingHail(3), false, false),
            (.openingHail(2), false, false),
            (.openingHail(1), false, false),
            (.openingOurFather, true, false)
        ]
        var pendantBeads: [RosaryBead] = []
        var x = lx - (rMedal + rOF + gapOF * 0.7)
        for (i, item) in pend.enumerated() {
            pendantBeads.append(RosaryBead(locus: item.0, point: CGPoint(x: x, y: cy), large: item.1, isSpace: item.2))
            if i < pend.count - 1 {
                let next = pend[i + 1]
                let ra = radius(large: item.1, space: item.2)
                let rb = radius(large: next.1, space: next.2)
                let tight = !item.1 && !item.2 && !next.1 && !next.2
                let aroundSpace = item.2 || next.2
                let extra: CGFloat = tight ? gapHM : (aroundSpace ? gapOF * 0.55 : gapOF)
                x -= ra + rb + extra
            }
        }

        // Opening Our Father is the outermost pendant bead (crucifix joins to its left).
        // Use locus lookup — not a hard-coded index — so pendant count changes stay safe.
        guard let openingOF = pendantBeads.first(where: { $0.locus == .openingOurFather }) ?? pendantBeads.last else {
            preconditionFailure("Pendant must include the opening Our Father bead")
        }
        let openOF = openingOF.point.x
        let join = openOF - rOF - gapOF
        let cxH: CGFloat = 40
        let foot = join - cxH
        let crucifix = CGPoint(x: join - cxH / 2, y: cy)

        var pendant = Path()
        pendant.move(to: CGPoint(x: lx, y: cy))
        pendant.addLine(to: CGPoint(x: foot + 2, y: cy))

        // Crop viewBox like the web
        let vbX = foot - 2
        let vbW = (lx + lw + 3.6) - vbX
        func sh(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x - vbX, y: p.y) }
        func shPath(_ path: Path) -> Path {
            var out = Path()
            out.addPath(path, transform: CGAffineTransform(translationX: -vbX, y: 0))
            return out
        }

        self.viewW = vbW
        self.viewH = H
        self.medal = sh(CGPoint(x: lx, y: cy))
        self.crucifix = sh(crucifix)
        self.pendantPath = shPath(pendant)
        self.loopPath = shPath(loop)
        let allBeads = (pendantBeads + loopBeads).map {
            RosaryBead(locus: $0.locus, point: sh($0.point), large: $0.large, isSpace: $0.isSpace)
        }
        self.beads = allBeads

        func beadRadius(_ b: RosaryBead) -> CGFloat {
            if b.isSpace { return 1.2 }
            return b.large ? rOF : rHM
        }
        let pendantCount = pendantBeads.count
        var nodes: [CordNode] = [CordNode(point: self.crucifix, radius: 7)]
        // Pendant array is medal→crucifix; cord walks crucifix→medal.
        for b in allBeads.prefix(pendantCount).reversed() {
            nodes.append(CordNode(point: b.point, radius: beadRadius(b)))
        }
        nodes.append(CordNode(point: self.medal, radius: rMedal * 0.85))
        for b in allBeads.suffix(from: pendantCount) {
            nodes.append(CordNode(point: b.point, radius: beadRadius(b)))
        }
        nodes.append(CordNode(point: self.medal, radius: rMedal * 0.85))
        self.cordNodes = nodes
    }
}

// MARK: - Progress track

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
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        // Hit target ~44pt, but visual gap under ticks ≈ web 1.35rem (not 18+18).
                        .padding(.top, 14)
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(stage.label)
                .accessibilityHint(stage == current ? "Current section" : "Jumps to this section")
            }
        }
        .frame(minHeight: AppTheme.Accessibility.minHitTarget)
        // Website `.track { padding-bottom: 1.35rem }` ≈ 22pt under the ticks.
        .padding(.bottom, 14)
    }

    private func barColor(_ stage: PrayTrackStage) -> Color {
        if stage == current { return palette.ink }
        if stage.rawValue < current.rawValue { return palette.ink.opacity(0.20) }
        return palette.ink.opacity(0.08)
    }
}
