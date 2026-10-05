import SwiftUI

/// The chosen prayer intention on a surface card: icon + title, or
/// "Add an intention" when none is chosen. Tapping opens the picker; × clears.
///
/// Privacy: with `hidesText`, the title is masked, except the Holy Father's
/// intention, which is never masked (`IntentionPrivacy`).
struct IntentionSurface: View {
    @Environment(\.palette) private var palette

    /// Chosen intention title; empty shows "Add an intention".
    var title: String
    /// Stored intention for the title, when known (icon, accent, papal flag).
    var intention: OfferIntention?
    var hidesText: Bool
    var onOpen: () -> Void
    var onClear: () -> Void

    private var hasIntention: Bool { !title.isEmpty }

    private var displayTitle: String {
        intention.map { IntentionPrivacy.displayTitle($0, hidden: hidesText) }
            ?? IntentionPrivacy.displayText(title, hidden: hidesText)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.sm) {
            if hasIntention {
                Button(action: onOpen) {
                    HStack(spacing: AppTheme.Space.sm) {
                        // Avatar only when we have a known intention (papal portrait / glyph).
                        if let intention {
                            IntentionIconView(
                                accent: intention.accent,
                                emoji: intention.displayEmoji,
                                size: 27,
                                usesPopePortrait: intention.isPapal
                            )
                        }
                        Text(displayTitle)
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Intention: \(displayTitle)")
                .accessibilityHint("Opens intention picker")

                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .guideSymbol(size: 15, weight: .semibold)
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear intention")
                .accessibilityHint("Returns to Add an intention")
            } else {
                Button(action: onOpen) {
                    HStack(spacing: 4) {
                        Text("Add an intention")
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.accent)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .guideSymbol(size: 12, weight: .semibold)
                            .foregroundStyle(palette.accent.opacity(0.75))
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: AppTheme.Accessibility.minHitTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add an intention")
                .accessibilityHint("Opens intention picker")
            }
        }
        .frame(minHeight: AppTheme.Accessibility.minHitTarget)
        .padding(.leading, AppTheme.Space.lg)
        // The × keeps its 44pt hit area, so its glyph already sits inset from the edge.
        .padding(.trailing, hasIntention ? AppTheme.Space.xs : AppTheme.Space.lg)
        .padding(.vertical, AppTheme.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Same surface card chrome as Home / Intentions: surface fill, container radius,
        // no stroke or shadow.
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
    }
}
