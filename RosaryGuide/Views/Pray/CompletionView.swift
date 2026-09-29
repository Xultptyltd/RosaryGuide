import SwiftUI

/// End-of-rosary screen: art → completion → what prayed → who for → quote → Done → optional St Michael.
struct CompletionView: View {
    var mysterySet: MysterySetKind
    var quote: String
    var attribution: String
    var intentionTitle: String?
    var onDone: () -> Void
    var onMichael: (() -> Void)?

    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private var completedDateLine: String {
        // e.g. "Tuesday, 29 September" (day-first, matching AU locale preference)
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private var mysteryLine: String {
        mysterySet.name.english
    }

    var body: some View {
        GeometryReader { geo in
            let artH = min(max(geo.size.height * 0.42, 180), geo.size.height * 0.45)
            ZStack(alignment: .top) {
                // Artwork ~40–45%, gentle fade into pray background
                MysteryArtworkView(
                    set: mysterySet,
                    mysteryNumber: 5,
                    slug: MysteryCatalog.mysteries(for: mysterySet).last?.artSlug,
                    kind: .heroTall
                )
                .frame(height: artH)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: palette.prayBg.opacity(colorScheme == .light ? 0.10 : 0.18), location: 0),
                            .init(color: palette.prayBg.opacity(colorScheme == .light ? 0.42 : 0.48), location: 0.38),
                            .init(color: palette.prayBg.opacity(colorScheme == .light ? 0.88 : 0.86), location: 0.72),
                            .init(color: palette.prayBg, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // Pull content into the lower part of the art band
                    Color.clear.frame(height: artH * 0.55)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            FinisEmblem()
                                .foregroundStyle(palette.accent.opacity(0.92))
                                .padding(.bottom, 16)

                            Text("Rosary complete")
                                .font(AppTheme.sans(22, weight: .semibold))
                                .tracking(0.12)
                                .foregroundStyle(palette.ink.opacity(0.94))
                                .multilineTextAlignment(.center)

                            VStack(spacing: 4) {
                                Text(mysteryLine)
                                    .font(AppTheme.sans(15, weight: .medium))
                                    .foregroundStyle(palette.ink.opacity(0.72))
                                Text(completedDateLine)
                                    .font(AppTheme.sans(14, weight: .regular))
                                    .foregroundStyle(palette.dim)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)

                            if let intentionTitle, !intentionTitle.isEmpty {
                                VStack(spacing: 4) {
                                    Text("Offered for")
                                        .font(AppTheme.sans(12, weight: .medium))
                                        .tracking(0.4)
                                        .foregroundStyle(palette.dim.opacity(0.9))
                                        .textCase(.uppercase)
                                    Text("For \(intentionTitle)")
                                        .font(AppTheme.sans(15, weight: .medium))
                                        .foregroundStyle(palette.ink.opacity(0.82))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 14)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Offered for \(intentionTitle)")
                            }

                            FinisOrnament()
                                .foregroundStyle(palette.accent.opacity(0.7))
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                                .frame(maxWidth: 280)

                            Text("\u{201C}\(quote)\u{201D}")
                                .font(AppTheme.sans(17))
                                .lineSpacing(5)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(palette.ink.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: 340)

                            Text(attribution)
                                .font(AppTheme.sans(12, weight: .regular))
                                .tracking(0.28)
                                .foregroundStyle(palette.dim)
                                .multilineTextAlignment(.center)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppTheme.gutter)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: 12) {
                        PillButton(title: "Done", action: onDone)

                        if let onMichael {
                            Button(action: onMichael) {
                                Text("† Continue with the Saint Michael Prayer")
                                    .font(AppTheme.sans(14, weight: .medium))
                                    .foregroundStyle(palette.dim)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .guidePressable()
                            .accessibilityLabel("Continue with the Saint Michael Prayer")
                        }
                    }
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, AppTheme.Space.md)
                    .safeAreaPadding(.bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(palette.prayBg.ignoresSafeArea())
        }
    }
}

// MARK: - Finis chrome (completed rosary emblem + ornament)

private struct FinisEmblem: View {
    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 60
            let sy = size.height / 70
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }

            let n = 22
            let r: CGFloat = 17
            let cx: CGFloat = 30
            let cy: CGFloat = 26
            for i in 0..<n {
                let a = (CGFloat(i) / CGFloat(n)) * 2 * .pi - .pi / 2
                let c = p(cx + cos(a) * r, cy + sin(a) * r)
                let rad = 1.5 * sx
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .foreground)
            }

            var star = Path()
            let sc = p(30, 26)
            let outer: CGFloat = 5.4 * sx
            let inner: CGFloat = 2.2 * sx
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 - .pi / 2
                let rad = i.isMultiple(of: 2) ? outer : inner
                let pt = CGPoint(x: sc.x + cos(a) * rad, y: sc.y + sin(a) * rad)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .foreground)

            for y in [46.5, 52.0] as [CGFloat] {
                let c = p(30, y)
                let rad = 1.5 * sx
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .foreground)
            }

            var cross = Path()
            cross.move(to: p(30, 56)); cross.addLine(to: p(30, 67))
            cross.move(to: p(25.5, 60)); cross.addLine(to: p(34.5, 60))
            ctx.stroke(cross, with: .foreground, style: StrokeStyle(lineWidth: 1.6 * sx, lineCap: .round))
        }
        .frame(width: 52, height: 60)
        .accessibilityHidden(true)
    }
}

private struct FinisOrnament: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(.primary.opacity(0.28))
                .frame(height: 1)
            Text("✦")
                .font(.system(size: 11, weight: .regular))
                .opacity(0.75)
            Rectangle()
                .fill(.primary.opacity(0.28))
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}
