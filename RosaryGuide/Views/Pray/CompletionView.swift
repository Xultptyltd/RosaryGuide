import SwiftUI

/// Category colour, glyph, and papal portrait locked with the finish intention.
struct CompletionIntentionFace: Equatable {
    var accent: IntentionAccent
    var emoji: String
    var isPapal: Bool
}

/// Ceremonial end-of-rosary screen: art → symbol → label → mystery title →
/// optional intention → quote → calm space → Done → optional St Michael prayer.
/// No stats, X, or confetti — stillness as the emotional endpoint.
struct CompletionView: View {
    var mysterySet: MysterySetKind
    var intentionTitle: String?
    var intentionIsPapal: Bool = false
    /// Nil when the rosary was offered with a title but no stored intention.
    var intentionFace: CompletionIntentionFace? = nil
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

    /// Resting icon. The ring is about half the 1024 canvas, so 88pt
    /// leaves a drawn tick about the size of the old emblem.
    private static let tickRest: CGFloat = 88
    /// Screen margin around the playing composition so glow and beads stay inside.
    private static let tickMargin: CGFloat = 40
    private static let morph = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.98)

    private var resting: Bool { reduceMotion || settled }

    /// Ceremonial page ground, routed through the app palette even though this
    /// screen intentionally stays dark.
    private var pageBg: Color { palette.completionBackground }

    /// One line: "Joyful Mysteries", "Sorrowful Mysteries", and the rest.
    private var mysteryHeadline: String {
        "\(mysterySet.shortName) Mysteries"
    }

    private var hasIntention: Bool {
        guard let intentionTitle else { return false }
        return !intentionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Holy Father stays readable. Personal intentions use the fuller
    /// finish-screen phrase, not the short "Hidden" used in the prayer row.
    private var intentionIsHidden: Bool {
        hideIntentionText && !intentionIsPapal
    }

    private var displayIntentionTitle: String {
        guard let intentionTitle else { return "Hidden intention" }
        if intentionIsHidden { return "Hidden intention" }
        return intentionTitle
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
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                completionContent()
                    .padding(.horizontal, AppTheme.gutter)
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
            let fitted = min(proxy.size.width, proxy.size.height) - Self.tickMargin * 2
            // First state only. About 30% smaller than the fitted canvas; the 88pt slot is unchanged.
            let play = max(Self.tickRest, fitted * 0.7)
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
                .init(color: pageBg.opacity(0.20), location: 0),
                .init(color: pageBg.opacity(0), location: 0.16),
                .init(color: pageBg.opacity(0), location: 0.70),
                .init(color: pageBg.opacity(0.55), location: 0.86),
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
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .tracking(1.6)
                .foregroundStyle(palette.completionLabel)
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
                    .padding(.top, 24)
                    .layoutPriority(1)
            }

            Color.clear.frame(height: hasIntention ? 12 : 40)

            VStack(spacing: 8) {
                Text(quote.text)
                    .font(AppTheme.serif(18, italic: true, opticalSize: 18, relativeTo: .body))
                    .foregroundStyle(palette.completionTitle.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 8)

                Text(quote.attribution.uppercased())
                    .font(AppTheme.TypeRole.quoteAttribution)
                    .tracking(0.8)
                    .foregroundStyle(palette.completionLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .guideCard(fill: palette.surface)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(quote.text), \(quote.attribution)")
        }
    }

    /// Category icon (or Pope portrait) and title, on the shared surface.
    /// No "Offered for" label — VoiceOver still says who it was offered for.
    private var offeredForSurface: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: AppTheme.Space.sm) {
                if let intentionFace {
                    IntentionIconView(
                        accent: intentionFace.accent,
                        emoji: intentionFace.emoji,
                        size: 27,
                        usesPopePortrait: intentionFace.isPapal
                    )
                    .accessibilityHidden(true)
                }

                Text(displayIntentionTitle)
                    .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                    .foregroundStyle(intentionIsHidden ? palette.completionMeta : palette.completionMetaValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .layoutPriority(-1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .guideCard(radius: AppTheme.nestedRadius, fill: palette.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offered for \(displayIntentionTitle)")
    }

    private func actions() -> some View {
        VStack(spacing: 12) {
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
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, 0)
    }
}

private struct SlotFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 1 { value = next }
    }
}
