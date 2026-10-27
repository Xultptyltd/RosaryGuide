import SwiftUI

/// Category colour, glyph, and papal portrait locked with the finish intention.
struct CompletionIntentionFace: Equatable {
    var accent: IntentionAccent
    var emoji: String
    var isPapal: Bool
}

/// One intention offered with the Rosary, frozen when the finish screen opens.
struct CompletionIntention: Identifiable, Equatable {
    var id: Int
    var title: String
    /// Nil when the rosary was offered with a title but no stored intention.
    var face: CompletionIntentionFace?
}

/// Ceremonial end-of-rosary screen: art → symbol → label → mystery title →
/// optional intention → quote → calm space → Done → optional St Michael prayer.
/// No stats, X, or confetti — stillness as the emotional endpoint.
struct CompletionView: View {
    var mysterySet: MysterySetKind
    /// Every intention the Rosary was offered for, in the order chosen.
    var intentions: [CompletionIntention] = []
    var quote: CompletionQuote
    var onDone: () -> Void
    var onMichael: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    /// Always the dark ceremony palette. Reading the inherited palette would
    /// follow the app scheme, and forcing that scheme with preferredColorScheme
    /// is what froze the transition onto this screen.
    private var palette: ThemePalette {
        ThemePalette(scheme: .dark, contrast: colorSchemeContrast)
    }
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false

    /// True once the tick has landed in the icon slot. Reduce Motion starts here.
    @State private var settled = false
    /// Icon slot in the finish coordinate space. Written only when it actually moves.
    @State private var slot: CGRect = .zero
    /// Natural height of the intention rows; above the cap they scroll in the card.
    @State private var intentionsContentHeight: CGFloat = 0

    /// Resting icon. The ring is about half the 1024 canvas, so 88pt
    /// leaves a drawn tick about the size of the old emblem.
    private static let tickRest: CGFloat = 88
    /// Opening (centered) tick, sized so its bead circle matches the app-open
    /// splash: splash canvas 144pt with beads at radius 290/1024; the tick's
    /// beads sit at 250/1024, so 144 × 290 / 250 ≈ 167pt (circle ≈ 82pt wide).
    private static let tickPlay: CGFloat = 144 * 290 / 250
    private static let morph = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.98)

    private var resting: Bool { reduceMotion || settled }

    /// Ceremonial page ground, routed through the app palette even though this
    /// screen intentionally stays dark.
    private var pageBg: Color { palette.completionBackground }

    /// One line: "Joyful Mysteries", "Sorrowful Mysteries", and the rest.
    private var mysteryHeadline: String {
        "\(mysterySet.shortName) Mysteries"
    }

    /// Taller lists scroll inside the card so the artwork and Done keep their room.
    private static let intentionsMaxHeight: CGFloat = 264

    private var shownIntentions: [CompletionIntention] {
        intentions.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var hasIntention: Bool { !shownIntentions.isEmpty }

    /// Holy Father stays readable. Personal intentions use the fuller
    /// finish-screen phrase, not the short "Hidden" used in the prayer row.
    private func isHidden(_ intention: CompletionIntention) -> Bool {
        hideIntentionText && !(intention.face?.isPapal ?? false)
    }

    private func displayTitle(_ intention: CompletionIntention) -> String {
        isHidden(intention) ? "Hidden intention" : intention.title
    }

    var body: some View {
        // No scroll. A GeometryReader that measured itself and locked a
        // frame re-entered until the main thread never returned. The icon
        // slot is a fixed 88pt frame; its background reader does not change that size.
        ZStack {
            VStack(spacing: 0) {
                // The spare room above the tick is the artwork. It fades to
                // black at the bottom edge, so the statue reads down to just
                // above the check instead of stopping in a short top band.
                MysteryArtworkView(
                    set: mysterySet,
                    mysteryNumber: nil,
                    slug: nil,
                    kind: .heroTall
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { heroFade }
                .clipped()
                .ignoresSafeArea(edges: .top)
                .opacity(resting ? 1 : 0)
                .offset(y: resting ? 0 : 28)
                .accessibilityHidden(true)

                iconSlot
                    .padding(.top, AppTheme.Space.xs)
                    .padding(.bottom, -10)

                completionContent()
                    .padding(.horizontal, AppTheme.gutter)
                    // Laid out before the artwork, so a long intention takes
                    // room from the picture, never from its own text.
                    .layoutPriority(1)
                    .offset(y: resting ? 0 : 108)
                    .opacity(resting ? 1 : 0)

                // Exactly 36pt from the quote card to Done.
                Color.clear.frame(height: 36)

                actions()
                    .offset(y: resting ? 0 : 108)
                    .opacity(resting ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(Self.morph, value: resting)

            if !reduceMotion {
                tickJourney
            }
        }
        .coordinateSpace(name: "finis")
        .background(pageBg.ignoresSafeArea())
        .onPreferenceChange(SlotFrameKey.self) { rect in
            guard rect.width > 1, rect.height > 1 else { return }
            guard abs(rect.minX - slot.minX) > 0.5
                    || abs(rect.minY - slot.minY) > 0.5
                    || abs(rect.width - slot.width) > 0.5 else { return }
            slot = rect
        }
    }

    /// Fixed hole where the drawn emblem used to be. The same Lottie view
    /// lands here, so the resting screen does not draw a second icon.
    private var iconSlot: some View {
        Group {
            if reduceMotion {
                RosaryTickPlayer(plays: false, hapticsEnabled: false, onComplete: {})
                    .frame(width: Self.tickRest, height: Self.tickRest)
            } else {
                Color.clear
                    .frame(width: Self.tickRest, height: Self.tickRest)
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: SlotFrameKey.self,
                    value: geo.frame(in: .named("finis"))
                )
            }
        }
        .accessibilityHidden(true)
    }

    private var tickJourney: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let target = slot.width > 1
                ? CGPoint(x: slot.midX, y: slot.midY)
                : center
            let landed = resting && slot.width > 1
            // First state only. Same circle size as the splash; the 88pt slot is unchanged.
            let play = max(Self.tickRest, Self.tickPlay)
            RosaryTickPlayer(plays: true, hapticsEnabled: settings.hapticsEnabled, onComplete: morphIn)
                .frame(width: play, height: play)
                .scaleEffect(landed ? Self.tickRest / play : 1)
                .position(landed ? target : center)
                .animation(Self.morph, value: landed)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .allowsHitTesting(false)
    }

    private func morphIn() {
        guard !settled else { return }
        withAnimation(Self.morph) {
            settled = true
        }
    }

    /// Clear through most of the artwork. The dissolve is only the last
    /// stretch, so the image meets black just above the tick.
    private var heroFade: some View {
        LinearGradient(
            stops: [
                .init(color: pageBg.opacity(0.18), location: 0),
                .init(color: pageBg.opacity(0), location: 0.12),
                .init(color: pageBg.opacity(0), location: 0.46),
                .init(color: pageBg.opacity(0.16), location: 0.62),
                .init(color: pageBg.opacity(0.40), location: 0.76),
                .init(color: pageBg.opacity(0.72), location: 0.90),
                .init(color: pageBg, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func completionContent() -> some View {
        VStack(spacing: 0) {
            Text("ROSARY COMPLETE")
                .font(AppTheme.TypeRole.caption(weight: .regular))
                .tracking(1.4)
                .foregroundStyle(palette.completionMeta)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Rosary complete")

            Text(mysteryHeadline)
                .font(AppTheme.TypeRole.screenTitle)
                .foregroundStyle(palette.completionTitle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .accessibilityLabel(mysterySet.name.english)
                .padding(.top, 6)

            if hasIntention {
                offeredForSurface
                    .padding(.top, 36)
                    .layoutPriority(1)
            }

            Color.clear.frame(height: hasIntention ? 12 : 40)

            VStack(spacing: AppTheme.Space.sm) {
                Text(quote.text)
                    .font(AppTheme.TypeRole.completionQuote)
                    .foregroundStyle(palette.completionTitle.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    // Longest quote (106 chars) needs 4 lines on narrow phones.
                    .lineLimit(4)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, AppTheme.Space.sm)

                Text(quote.attribution.uppercased())
                    .font(AppTheme.TypeRole.quoteAttribution)
                    .tracking(0.8)
                    .foregroundStyle(palette.completionLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.vertical, 14)
            .guideCard(fill: palette.surface)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(quote.text), \(quote.attribution)")
        }
    }

    /// Offered-for list: one flat card, one row per intention. Every title
    /// wraps in full. A long list scrolls inside the card.
    /// No "Offered for" label — VoiceOver still says who it was offered for.
    private var offeredForSurface: some View {
        let scrolls = intentionsContentHeight > Self.intentionsMaxHeight
        return ScrollView {
            intentionRows
                // The rows' height depends only on the width, never on this
                // frame, so reading it cannot feed back into layout.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    if abs(height - intentionsContentHeight) > 0.5 {
                        intentionsContentHeight = height
                    }
                }
        }
        .scrollDisabled(!scrolls)
        .scrollBounceBehavior(.basedOnSize)
        // Flash the bar once so a clipped last row reads as "more below".
        .scrollIndicators(scrolls ? .visible : .hidden)
        .scrollIndicatorsFlash(trigger: scrolls)
        .frame(height: intentionsContentHeight > 0 ? min(intentionsContentHeight, Self.intentionsMaxHeight) : nil)
        .frame(maxWidth: .infinity)
        .guideCard(radius: AppTheme.nestedRadius, fill: palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
    }

    private var intentionRows: some View {
        let rows = shownIntentions
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, intention in
                intentionRow(intention)
                if index < rows.count - 1 {
                    Rectangle()
                        .fill(palette.completionMeta.opacity(0.22))
                        .frame(height: 0.5)
                        .padding(.leading, intention.face == nil ? 14 : 14 + 27 + AppTheme.Space.md)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func intentionRow(_ intention: CompletionIntention) -> some View {
        let hidden = isHidden(intention)
        let title = displayTitle(intention)
        return HStack(alignment: .center, spacing: AppTheme.Space.md) {
            if let face = intention.face {
                IntentionIconView(
                    accent: face.accent,
                    emoji: face.emoji,
                    size: 27,
                    usesPopePortrait: face.isPapal
                )
                .accessibilityHidden(true)
            }

            Text(title)
                .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                .foregroundStyle(hidden ? palette.completionMeta : palette.completionMetaValue)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offered for \(title)")
    }

    private func actions() -> some View {
        VStack(spacing: AppTheme.Space.md) {
            ceremonyButton(
                title: "Done",
                fill: palette.primaryButtonFill,
                text: palette.primaryButtonText,
                haptic: true,
                action: onDone
            )
            .accessibilityLabel("Done")

            if let onMichael {
                ceremonyButton(
                    title: "Saint Michael Prayer",
                    fill: palette.secondaryButtonFill,
                    text: palette.secondaryButtonText,
                    haptic: false,
                    action: onMichael
                )
                .accessibilityLabel("Saint Michael Prayer")
            }
        }
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, 0)
    }

    /// Finish-screen pills use the ceremony palette, not the inherited scheme.
    private func ceremonyButton(
        title: String,
        fill: Color,
        text: Color,
        haptic: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            if haptic {
                HapticService.play(.light, enabled: settings.hapticsEnabled)
            }
            action()
        } label: {
            Text(title)
                .font(AppTheme.TypeRole.pillLabel(weight: .semibold))
                .foregroundStyle(text)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Component.pillHeight)
                .background(fill, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityAddTraits(.isButton)
    }
}

private struct SlotFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 1 { value = next }
    }
}
