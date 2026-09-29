import SwiftUI

/// Ceremonial end-of-rosary screen: art → symbol → label → mystery title →
/// quote → optional intention → calm space → Done → optional St Michael prayer.
/// No stats, X, or confetti — stillness as the emotional endpoint.
struct CompletionView: View {
    var mysterySet: MysterySetKind
    var intentionTitle: String?
    var onDone: () -> Void
    var onMichael: (() -> Void)?

    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var contentPhase: ContentPhase = .hidden

    private enum ContentPhase: Int, Comparable {
        case hidden = 0
        case symbol = 1
        case title = 2
        case rest = 3

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Near-black page ground for this ceremonial screen (independent of light chrome elsewhere).
    private var pageBg: Color { Color.black }

    /// Primary headline — adjective + "Mysteries" on two lines when natural.
    private var mysteryHeadline: String {
        "\(mysterySet.shortName)\nMysteries"
    }

    private var hasIntention: Bool {
        guard let intentionTitle else { return false }
        return !intentionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var completionQuote: CompletionQuote {
        QuoteCatalog.quote()
    }

    private var prefersCompactType: Bool {
        dynamicTypeSize >= .accessibility1
    }

    var body: some View {
        GeometryReader { geo in
            let artH = artHeight(for: geo.size.height)
            ZStack(alignment: .top) {
                pageBg.ignoresSafeArea()

                // 1. Hero artwork — full bleed, under status bar, soft fade into black.
                MysteryArtworkView(
                    set: mysterySet,
                    mysteryNumber: nil,
                    slug: nil,
                    kind: .heroTall
                )
                .frame(height: artH)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: pageBg.opacity(0.12), location: 0),
                            .init(color: pageBg.opacity(0.28), location: 0.35),
                            .init(color: pageBg.opacity(0.72), location: 0.68),
                            .init(color: pageBg.opacity(0.94), location: 0.88),
                            .init(color: pageBg, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .top)
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // Sit the emblem near the art → black transition.
                    Color.clear.frame(height: max(artH * 0.58, 120))

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // 2. Completion symbol
                            FinisEmblem()
                                .foregroundStyle(palette.accent.opacity(0.95))
                                .opacity(opacity(for: .symbol))
                                .offset(y: offset(for: .symbol))
                                .padding(.bottom, 18)
                                .accessibilityHidden(true)

                            // 3. Completion label (metadata, not headline)
                            Text("ROSARY COMPLETE")
                                .font(AppTheme.sans(prefersCompactType ? 12 : 11, weight: .medium, relativeTo: .caption))
                                .tracking(1.6)
                                .foregroundStyle(Color.white.opacity(0.48))
                                .multilineTextAlignment(.center)
                                .opacity(opacity(for: .title))
                                .offset(y: offset(for: .title))
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityLabel("Rosary complete")

                            // 4. Mystery title
                            VStack(spacing: 0) {
                                Text(mysteryHeadline)
                                    .font(AppTheme.sans(prefersCompactType ? 34 : 40, weight: .regular, relativeTo: .largeTitle))
                                    .foregroundStyle(Color.white.opacity(0.96))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                    .minimumScaleFactor(0.78)
                                    .accessibilityLabel(mysterySet.name.english)
                            }
                            .padding(.top, 10)
                            .opacity(opacity(for: .title))
                            .offset(y: offset(for: .title))

                            // 5. Short contemplative quote on the same surface treatment used elsewhere.
                            VStack(spacing: AppTheme.Space.md) {
                                Text("“\(completionQuote.text)”")
                                    .font(prefersCompactType ? AppTheme.sans(18, relativeTo: .body) : AppTheme.TypeRole.bodySmall)
                                    .foregroundStyle(palette.dim)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(completionQuote.attribution.uppercased())
                                    .font(AppTheme.TypeRole.quoteAttribution)
                                    .tracking(AppTheme.Component.quoteAttributionTracking)
                                    .foregroundStyle(palette.faint)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Space.lg)
                            .guideCard(fill: palette.panel, stroke: true)
                            .padding(.top, AppTheme.Space.xl)
                            .opacity(opacity(for: .rest))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(completionQuote.text), \(completionQuote.attribution)")

                            // 6. Intention (optional only — omit entirely when absent)
                            if hasIntention, let intentionTitle {
                                VStack(spacing: 6) {
                                    Text("OFFERED FOR")
                                        .font(AppTheme.sans(11, weight: .medium, relativeTo: .caption))
                                        .tracking(1.4)
                                        .foregroundStyle(Color.white.opacity(0.42))
                                        .textCase(.uppercase)

                                    // Exact stored title — never auto-prefix "For".
                                    Text(intentionTitle)
                                        .font(AppTheme.sans(prefersCompactType ? 18 : 17, weight: .regular, relativeTo: .body))
                                        .foregroundStyle(Color.white.opacity(0.90))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 28)
                                .opacity(opacity(for: .rest))
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Offered for \(intentionTitle)")
                            }

                            // 7. Intentional negative space before actions
                            Spacer(minLength: prefersCompactType ? 28 : 44)
                                .frame(height: prefersCompactType ? 28 : 52)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppTheme.gutter)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 8 + 9. Actions — Done primary, St Michael optional secondary CTA
                    VStack(spacing: 18) {
                        PillButton(title: "Done", action: onDone)
                            .environment(\.colorScheme, .dark)
                            .accessibilityLabel("Done")

                        if let onMichael {
                            Button(action: onMichael) {
                                Text("Saint Michael Prayer")
                                    .font(AppTheme.sans(16, weight: .semibold, relativeTo: .callout))
                                    .foregroundStyle(palette.ink)
                                    .padding(.horizontal, 28)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(palette.panel, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .guidePressable()
                            .accessibilityLabel("Saint Michael Prayer")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .opacity(opacity(for: .rest))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, 4)
                    .padding(.bottom, AppTheme.Space.md)
                    .safeAreaPadding(.bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .preferredColorScheme(.dark)
        }
        .onAppear { runEntrance() }
    }

    private func artHeight(for screenHeight: CGFloat) -> CGFloat {
        // ~42–46% of screen; floor so small phones keep subjects visible.
        let ratio: CGFloat = prefersCompactType ? 0.36 : 0.44
        return min(max(screenHeight * ratio, 168), screenHeight * 0.46)
    }

    private func opacity(for phase: ContentPhase) -> Double {
        contentPhase >= phase ? 1 : 0
    }

    private func offset(for phase: ContentPhase) -> CGFloat {
        if reduceMotion { return 0 }
        return contentPhase >= phase ? 0 : 8
    }

    private func runEntrance() {
        guard !reduceMotion else {
            contentPhase = .rest
            return
        }
        contentPhase = .hidden
        withAnimation(.easeOut(duration: 0.45).delay(0.12)) {
            contentPhase = .symbol
        }
        withAnimation(.easeOut(duration: 0.50).delay(0.32)) {
            contentPhase = .title
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.52)) {
            contentPhase = .rest
        }
    }
}

// MARK: - Finis chrome (completed rosary emblem)

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
        .frame(width: 48, height: 56)
        .accessibilityHidden(true)
    }
}
