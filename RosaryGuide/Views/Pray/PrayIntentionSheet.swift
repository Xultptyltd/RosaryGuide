import SwiftUI

/// Bottom sheet for choosing or creating a single Rosary intention.
/// Selecting a row dismisses immediately — no Save/Done.
struct PrayIntentionSheet: View {
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @Binding var chosenId: UUID?
    @Binding var chosenTitle: String
    @Binding var chosenNote: String
    /// Mystery set for the Rosary being prayed — drives ordering for this Rosary.
    var mysterySet: MysterySetKind

    @State private var popeStore = PopeIntentionStore.shared
    @State private var editorRoute: EditorRoute?

    private var suggestions: [SuggestedIntention] { IntentionSuggestions.forDay(popeStore: popeStore) }

    private var papalSuggestions: [SuggestedIntention] {
        suggestions.filter {
            $0.id.hasPrefix("pope-")
                || $0.sourceLabel.lowercased().contains("pope")
                || $0.sourceLabel.lowercased().contains("holy father")
        }
    }

    /// Your intentions for this set, pinned/current first (via OfferStore sort), then suggested, then recent.
    /// Includes adopted papal intentions so they can be pinned/edited like any other row.
    private var listedIntentions: [OfferIntention] {
        offer.sortedIntentions(for: mysterySet)
    }

    /// Papal suggestion cards only when not yet saved — once adopted, they appear in `listedIntentions`.
    private var unadoptedPapalSuggestions: [SuggestedIntention] {
        papalSuggestions.filter { suggestion in
            !offer.sortedIntentions.contains {
                $0.sourceId == suggestion.id
                    || $0.title.compare(suggestion.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
        }
    }

    private var noneSelected: Bool { chosenId == nil && chosenTitle.isEmpty }

    /// Four or more saved intentions need the full-height sheet so the list is usable.
    private var prefersLargeDetent: Bool { offer.sortedIntentions.count >= 4 }

    private let cardMinHeight: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    radioCard(
                        title: "No specific intention",
                        subtitle: nil,
                        selected: noneSelected
                    ) {
                        chooseNone()
                    }

                    ForEach(unadoptedPapalSuggestions) { item in
                        papalRadioCard(item)
                    }

                    ForEach(listedIntentions) { item in
                        IntentionRadioRow(
                            item: item,
                            selected: chosenId == item.id,
                            allowsPin: offer.sortedIntentions.count > 1,
                            cardMinHeight: cardMinHeight,
                            onChoose: { choose(item) },
                            onPin: { pinOrUnpin(item) },
                            onEdit: { editorRoute = .edit(item) },
                            onDelete: { deleteIntention(item) }
                        )
                    }

                    addIntentionCard
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(palette.bg)
            .navigationTitle("Offer this Rosary for")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
            .sheet(item: $editorRoute) { route in
                IntentionEditorSheet(
                    route: route,
                    initialMystery: mysterySet,
                    onSaved: { saved in
                        chosenId = saved.id
                        chosenTitle = saved.title
                        chosenNote = saved.note ?? ""
                        dismiss()
                    }
                )
                .environment(offer)
                .environment(\.palette, palette)
            }
            .task {
                await popeStore.refreshIfNeeded()
            }
        }
        .presentationDetents(prefersLargeDetent ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rows

    private var addIntentionCard: some View {
        Button {
            editorRoute = .create
        } label: {
            Text("Add an intention")
                .font(AppTheme.sans(16, weight: .semibold))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(palette.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Add an intention")
        .padding(.top, 6)
    }

    private func papalRadioCard(_ item: SuggestedIntention) -> some View {
        let existing = offer.sortedIntentions.first(where: {
            $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        })
        let selected = existing.map { chosenId == $0.id }
            ?? (chosenTitle.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame)

        return Button {
            adoptSuggestion(item)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accent : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)

                IntentionIconView(
                    accent: .purple,
                    emoji: "✝️",
                    size: 36,
                    usesPopePortrait: true
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Holy Father’s Intention")
                        .font(AppTheme.sans(11, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(item.title)
                        .font(AppTheme.sans(16, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? palette.accent.opacity(0.45) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("Holy Father: \(item.title)")
    }

    private func radioCard(
        title: String,
        subtitle: String?,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accent : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTheme.sans(16, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.sans(13))
                            .foregroundStyle(palette.dim)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? palette.accent.opacity(0.45) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Actions

    private func pinOrUnpin(_ item: OfferIntention) {
        // Exclusive pin / clear unpin — handled in OfferStore.togglePin.
        offer.togglePin(id: item.id)
    }

    private func deleteIntention(_ item: OfferIntention) {
        if chosenId == item.id {
            chosenId = nil
            chosenTitle = ""
            chosenNote = ""
        }
        offer.delete(id: item.id)
    }

    private func chooseNone() {
        chosenId = nil
        chosenTitle = ""
        chosenNote = ""
        dismiss()
    }

    private func choose(_ item: OfferIntention) {
        chosenId = item.id
        chosenTitle = item.title
        chosenNote = item.note ?? ""
        dismiss()
    }

    private func adoptSuggestion(_ item: SuggestedIntention) {
        let papal = item.id.hasPrefix("pope-")
            || item.sourceLabel.lowercased().contains("pope")
            || item.sourceLabel.lowercased().contains("holy father")
        if let existing = offer.sortedIntentions.first(where: {
            $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
            if papal, existing.sourceId == nil {
                var locked = existing
                locked.sourceId = item.id
                locked.category = .world
                offer.update(locked)
            }
            chosenId = existing.id
            chosenTitle = existing.title
            chosenNote = existing.note ?? item.note ?? ""
        } else {
            let created = offer.add(
                title: item.title,
                note: item.note,
                sourceId: papal ? item.id : nil,
                category: papal ? .world : .personal,
                accent: papal ? .purple : .mintGreen,
                emoji: papal ? "✝️" : nil
            )
            chosenId = created.id
            chosenTitle = created.title
            chosenNote = created.note ?? ""
        }
        dismiss()
    }
}

/// Intention radio row with trailing overflow outside the select Button so menu taps
/// do not also select the radio (same overlay pattern as CurrentIntentionHero).
private struct IntentionRadioRow: View {
    @Environment(\.palette) private var palette

    let item: OfferIntention
    let selected: Bool
    let allowsPin: Bool
    let cardMinHeight: CGFloat
    let onChoose: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    private var subtitle: String? {
        var parts: [String] = []
        if item.isPapal { parts.append(item.categoryTitle) }
        if !item.isNew, !item.carriedLabel.isEmpty { parts.append(item.carriedLabel) }
        if let note = item.note, !note.isEmpty { parts.append(note) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: onChoose) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accent : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)

                IntentionIconView(
                    accent: item.accent,
                    emoji: item.displayEmoji,
                    size: 36,
                    usesPopePortrait: item.isPapal
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(AppTheme.sans(16, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .multilineTextAlignment(.leading)
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(palette.accent)
                        }
                    }
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.sans(13))
                            .foregroundStyle(palette.dim)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Reserve trailing space so the overlaid overflow sits clear of the title.
                Color.clear
                    .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? palette.accent.opacity(0.45) : Color.clear,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(item.title)
        .overlay(alignment: .trailing) {
            // Outside the row Button so menu taps do not also select the radio.
            OverflowMenuButton(
                isPinned: item.isPinned,
                allowsPin: allowsPin,
                allowsEdit: true,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: { showingDeleteAlert = true }
            )
            .padding(.trailing, 14)
        }
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(item.title)” from your intentions.")
        }
    }
}
