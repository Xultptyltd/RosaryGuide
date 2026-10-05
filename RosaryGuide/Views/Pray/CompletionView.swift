import SwiftUI

/// Ceremonial end-of-rosary screen: art → symbol → label → mystery title →
/// optional intention → quote → calm space → Done → optional St Michael prayer.
/// No stats, X, or confetti — stillness as the emotional endpoint.
struct CompletionView: View {
    var mysterySet: MysterySetKind
    var intentionTitle: String?
    var intentionIsPapal: Bool = false
    var quote: CompletionQuote
    var onDone: () -> Void
    var onMichael: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Always the dark ceremony palette. Reading the inherited palette would
    /// follow the app scheme, and forcing that scheme with preferredColorScheme
    /// is what froze the transition onto this screen.
    private var palette: ThemePalette {
        ThemePalette(scheme: .dark, contrast: colorSchemeContrast)
    }
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false

    @State private var contentPhase: ContentPhase = .hidden

    private enum ContentPhase: Int, Comparable {
        case hidden = 0
        case symbol = 1
        case title = 2
        case rest = 3

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Ceremonial page ground, routed through the app palette even though this
    /// screen intentionally stays dark.
    private var pageBg: Color { palette.completionBackground }

    /// Primary headline — adjective + "Mysteries" on two lines when natural.
    private var mysteryHeadline: String {
        "\(mysterySet.shortName)\nMysteries"
    }

    private var hasIntention: Bool {
        guard let intentionTitle else { return false }
        return !intentionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayIntentionTitle: String {
        guard let intentionTitle else { return IntentionPrivacy.maskedText }
        return IntentionPrivacy.displayText(
            intentionTitle,
            hidden: hideIntentionText && !intentionIsPapal
        )
    }

    private var prefersCompactType: Bool {
        // xxxLarge already scales title/quote enough to push Offered for under Done
        // on a non-scrolling layout; don't wait for accessibility sizes.
        dynamicTypeSize >= .xxxLarge
    }

    var body: some View {
        // One finite scroll. The previous layout measured itself with a
        // GeometryReader, then ignored the safe area and locked a frame to
        // that measurement. On device that re-entered body until the main
        // thread never returned (scene-update watchdog inside this getter).
        ScrollView {
            VStack(spacing: 0) {
                MysteryArtworkView(
                    set: mysterySet,
                    mysteryNumber: nil,
                    slug: nil,
                    kind: .heroTall
                )
                .frame(height: prefersCompactType ? 220 : 300)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay { heroFade }
                .accessibilityHidden(true)

                completionContent(compact: prefersCompactType)
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, prefersCompactType ? 12 : 20)

                VStack(spacing: prefersCompactType ? 12 : 18) {
                    PillButton(title: "Done", action: onDone)
                        .accessibilityLabel("Done")

                    if let onMichael {
                        Button(action: onMichael) {
                            let secondary = ThemePalette(scheme: .dark)
                            Text("Saint Michael Prayer")
                                .font(AppTheme.TypeRole.callout(weight: .semibold))
                                .foregroundStyle(secondary.secondaryButtonText)
                                .padding(.horizontal, 28)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.Component.pillHeight)
                                .background(secondary.secondaryButtonFill, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .guidePressable()
                        .accessibilityLabel("Saint Michael Prayer")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .opacity(opacity(for: .rest))
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(pageBg.ignoresSafeArea())
        .onAppear { runEntrance() }
    }

    private var heroFade: some View {
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
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func completionContent(compact: Bool) -> some View {
        VStack(spacing: 0) {
            FinisEmblem()
                .foregroundStyle(palette.accent.opacity(0.95))
                .opacity(opacity(for: .symbol))
                .offset(y: offset(for: .symbol))
                .padding(.bottom, compact ? 12 : 18)
                .accessibilityHidden(true)

            // Completion label (metadata, not headline)
            Text("ROSARY COMPLETE")
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .tracking(1.6)
                .foregroundStyle(palette.completionLabel)
                .multilineTextAlignment(.center)
                .opacity(opacity(for: .title))
                .offset(y: offset(for: .title))
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Rosary complete")

            // Mystery title
            Text(mysteryHeadline)
                .font(compact ? AppTheme.TypeRole.screenTitle : AppTheme.TypeRole.title)
                .foregroundStyle(palette.completionTitle)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .minimumScaleFactor(0.78)
                .accessibilityLabel(mysterySet.name.english)
                .padding(.top, compact ? 8 : 10)
                .opacity(opacity(for: .title))
                .offset(y: offset(for: .title))

            // Offered for — between the mystery title and quote surface.
            // Exact stored title only (never auto-prefix "For").
            if hasIntention {
                VStack(spacing: AppTheme.Space.sm) {
                    Text("OFFERED FOR")
                        .font(AppTheme.TypeRole.caption(weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(palette.completionMeta)
                        .textCase(.uppercase)

                    Text(displayIntentionTitle)
                        .font(compact ? AppTheme.TypeRole.body : AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.completionMetaValue)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, compact ? 20 : 28)
                .layoutPriority(1)
                .opacity(opacity(for: .rest))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Offered for \(displayIntentionTitle)")
            }

            // Short contemplative quote on the same surface treatment used elsewhere.
            VStack(spacing: compact ? AppTheme.Space.sm : AppTheme.Space.md) {
                Text("“\(quote.text)”")
                    .font(compact ? AppTheme.TypeRole.body : AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(quote.attribution.uppercased())
                    .font(AppTheme.TypeRole.quoteAttribution)
                    .tracking(AppTheme.Component.quoteAttributionTracking)
                    .foregroundStyle(palette.faint)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(compact ? AppTheme.Space.md : AppTheme.Space.lg)
            .guideCard(fill: palette.surface)
            .padding(.top, compact ? AppTheme.Space.xl : AppTheme.Space.xxl)
            .opacity(opacity(for: .rest))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(quote.text), \(quote.attribution)")

            // Small breathing room before the pinned actions.
            Color.clear.frame(height: compact ? 16 : 24)
        }
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
