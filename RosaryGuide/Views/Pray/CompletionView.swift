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
    var face: CompletionIntentionFace?
}

/// Copy rules for the Offered for carousel, kept out of the view so they are testable.
enum CompletionCopy {
    static let offeredLabel = "Offered for"
    static func cardLabel(index: Int, count: Int, title: String) -> String {
        count > 1 ? "Intention \(index + 1) of \(count): \(title)" : "Offered for \(title)"
    }
    /// Three lines fits the longest five-intention titles without the cards growing.
    static let titleLineLimit = 3
}

/// Ceremonial end-of-rosary screen: art → symbol → label → mystery title →
/// quote → calm space → Done → optional St Michael prayer.
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

    /// True once the tick has landed in the icon slot. Reduce Motion starts here.
    @State private var settled = false
    /// Icon slot in the finish coordinate space. Written only when it actually moves.
    @State private var slot: CGRect = .zero
    /// A moment of stillness before the tick starts drawing.
    @State private var tickStarted = false
    private static let stillness: Duration = .milliseconds(500)
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false
    /// Card in view in the Offered for carousel.
    @State private var cardID: Int?
    /// Complete-screen scene, fixed when the screen opens. Never the Home hero file.
    @State private var plate: (number: Int, slug: String)?
    @Environment(\.colorScheme) private var colorScheme

    private var shownIntentions: [CompletionIntention] {
        intentions.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func isHidden(_ intention: CompletionIntention) -> Bool {
        hideIntentionText && !(intention.face?.isPapal ?? false)
    }

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

    var body: some View {
        // No scroll. A GeometryReader that measured itself and locked a
        // frame re-entered until the main thread never returned. The icon
        // slot is a fixed 88pt frame; its background reader does not change that size.
        ZStack {
            VStack(spacing: 0) {
                // The spare room above the tick is the artwork. It fades to
                // black at the bottom edge, so the statue reads down to just
                // above the check instead of stopping in a short top band.
                completionArt
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
                    // Laid out before the artwork, so the text keeps its room
                    // and the picture takes whatever is left.
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

            if !reduceMotion && tickStarted {
                tickJourney
            }
        }
        .coordinateSpace(name: "finis")
        .task {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: Self.stillness)
            tickStarted = true
            // Failsafe: if the tick never reports back, never leave the page blank.
            try? await Task.sleep(for: .seconds(4))
            morphIn()
        }
        .background(pageBg.ignoresSafeArea())
        .onPreferenceChange(SlotFrameKey.self) { rect in
            guard rect.width > 1, rect.height > 1 else { return }
            guard abs(rect.minX - slot.minX) > 0.5
                    || abs(rect.minY - slot.minY) > 0.5
                    || abs(rect.width - slot.width) > 0.5 else { return }
            slot = rect
        }
    }

    /// A scene plate from the same set, not the hero Home shows.
    private var completionArt: some View {
        let chosen = plate ?? ArtCatalog.completionPlate(set: mysterySet)
        let path = ArtCatalog.platePath(set: mysterySet, slug: chosen.slug, scheme: .dark, wide: false)
        return FocusedRasterImage(
            directory: path.directory,
            name: path.name,
            focus: ArtCatalog.focus(set: mysterySet, number: chosen.number)
        )
        .onAppear { if plate == nil { plate = chosen } }
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

            if !shownIntentions.isEmpty {
                offeredCarousel
                    .padding(.top, 32)
                // Quote stays, under the cards, at the carousel's own spacing.
                quoteCard
                    .padding(.top, AppTheme.Space.md)
            } else {
                Color.clear.frame(height: 40)
                quoteCard
            }
        }
    }

    private var quoteCard: some View {
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

    /// Offered for: one card per intention, swiped sideways. The next card peeks in and
    /// dots sit underneath; a single intention fills the width with no dots.
    private var offeredCarousel: some View {
        let rows = shownIntentions
        let many = rows.count > 1
        let peek: CGFloat = many ? 28 : 0
        return VStack(spacing: AppTheme.Space.sm) {
            Text(CompletionCopy.offeredLabel.uppercased())
                .font(AppTheme.TypeRole.caption(weight: .regular))
                .tracking(1.2)
                .foregroundStyle(palette.completionMeta)
                // Starts on the card's leading edge.
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(CompletionCopy.offeredLabel)

            ScrollView(.horizontal) {
                LazyHStack(spacing: AppTheme.Space.sm) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, intention in
                        intentionCard(intention, index: index, count: rows.count)
                            .containerRelativeFrame(.horizontal) { width, _ in width - peek }
                            .id(intention.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $cardID)
            .scrollIndicators(.hidden)
            .scrollDisabled(!many)
            .scrollClipDisabled()
            .fixedSize(horizontal: false, vertical: true)

            if many {
                HStack(spacing: 7) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, intention in
                        Circle()
                            .fill((cardID ?? rows[0].id) == intention.id
                                  ? palette.completionTitle : palette.completionMeta.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: cardID)
                .accessibilityElement()
                .accessibilityLabel("Page \((rows.firstIndex { $0.id == (cardID ?? rows[0].id) } ?? 0) + 1) of \(rows.count)")
            }
        }
    }

    private func intentionCard(_ intention: CompletionIntention, index: Int, count: Int) -> some View {
        let hidden = isHidden(intention)
        let title = hidden ? "Hidden intention" : intention.title
        let category = intention.face.map {
            IntentionCategory.inferred(sourceId: $0.isPapal ? PapalIntention.prefix : nil, accent: $0.accent, emoji: $0.emoji).title
        }
        return HStack(alignment: .center, spacing: AppTheme.Space.md) {
            if let face = intention.face {
                IntentionIconView(accent: face.accent, emoji: face.emoji, size: 36, usesPopePortrait: face.isPapal)
                    .accessibilityHidden(true)
            }
            // A hidden full-height copy fixes every card at the same height; the real
            // text block centres inside it, level with the icon.
            ZStack(alignment: .leading) {
                if count > 1 {
                    intentionText(title, category: category, hidden: hidden, reserve: true).hidden()
                }
                intentionText(title, category: category, hidden: hidden, reserve: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard(radius: AppTheme.nestedRadius, fill: palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CompletionCopy.cardLabel(index: index, count: count, title: title))
    }

    private func intentionText(_ title: String, category: String?, hidden: Bool, reserve: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                .foregroundStyle(hidden ? palette.completionMeta : palette.completionMetaValue)
                .multilineTextAlignment(.leading)
                .lineLimit(CompletionCopy.titleLineLimit, reservesSpace: reserve)
            if let category {
                Text(category)
                    .font(AppTheme.TypeRole.caption(weight: .regular))
                    .foregroundStyle(palette.completionMeta)
            }
        }
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
