import SwiftUI

/// Bottom sheet for choosing or creating a single Rosary intention.
struct PrayIntentionSheet: View {
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @Binding var chosenId: UUID?
    @Binding var chosenTitle: String
    @Binding var chosenNote: String
    /// Mystery set for the Rosary being prayed — drives the Suggested section for this Rosary.
    var mysterySet: MysterySetKind

    @State private var popeStore = PopeIntentionStore.shared

    private var suggestions: [SuggestedIntention] { IntentionSuggestions.forDay(popeStore: popeStore) }

    private var papalSuggestions: [SuggestedIntention] {
        suggestions.filter {
            $0.id.hasPrefix("pope-")
                || $0.sourceLabel.lowercased().contains("pope")
                || $0.sourceLabel.lowercased().contains("holy father")
        }
    }

    /// Your intentions tagged for this Rosary’s mystery set.
    private var matchingIntentions: [OfferIntention] {
        offer.sortedIntentions(for: mysterySet).filter { $0.isSuggested(on: mysterySet) }
    }

    /// Everything else you keep (not tagged for this set).
    private var otherIntentions: [OfferIntention] {
        offer.sortedIntentions(for: mysterySet).filter { !$0.isSuggested(on: mysterySet) }
    }

    private var hasSuggestedSection: Bool {
        !papalSuggestions.isEmpty || !matchingIntentions.isEmpty
    }

    private var noneSelected: Bool { chosenId == nil && chosenTitle.isEmpty }

    @State private var editorRoute: EditorRoute?

    private let cardMinHeight: CGFloat = 76

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if hasSuggestedSection {
                        suggestedSection
                    }

                    yourIntentionsSection
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(palette.bg)
            .navigationTitle("Offer for…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
    }

    // MARK: - Your intentions

    private var yourIntentionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("All intentions")

            radioCard(
                title: "No intention",
                subtitle: nil,
                selected: noneSelected
            ) {
                chosenId = nil
                chosenTitle = ""
                chosenNote = ""
                dismiss()
            }

            ForEach(otherIntentions) { item in
                radioCard(
                    title: item.title,
                    subtitle: {
                        var parts: [String] = []
                        if !item.isNew, !item.carriedLabel.isEmpty { parts.append(item.carriedLabel) }
                        if let note = item.note, !note.isEmpty { parts.append(note) }
                        return parts.isEmpty ? nil : parts.joined(separator: " · ")
                    }(),
                    selected: chosenId == item.id,
                    showsPin: item.isPinned,
                    showsNewBadge: item.isNew
                ) {
                    chosenId = item.id
                    chosenTitle = item.title
                    chosenNote = item.note ?? ""
                    dismiss()
                }
            }

            addIntentionCard
        }
    }

    private var addIntentionCard: some View {
        Button {
            editorRoute = .create
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(palette.ink.opacity(0.85))
                Text("Add intention")
                    .font(AppTheme.sans(16, weight: .medium))
                    .foregroundStyle(palette.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(
                        palette.ink.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add intention")
    }

        // MARK: - Suggested

    /// Holy Father first, then your intentions tagged for this mystery.
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Suggested")

            ForEach(papalSuggestions) { item in
                suggestionCard(item, showsPopeImage: true)
            }

            ForEach(matchingIntentions) { item in
                radioCard(
                    title: item.title,
                    subtitle: {
                        var parts: [String] = []
                        if !item.isNew, !item.carriedLabel.isEmpty { parts.append(item.carriedLabel) }
                        if let note = item.note, !note.isEmpty { parts.append(note) }
                        return parts.isEmpty ? nil : parts.joined(separator: " · ")
                    }(),
                    selected: chosenId == item.id,
                    showsPin: item.isPinned,
                    showsNewBadge: item.isNew
                ) {
                    chosenId = item.id
                    chosenTitle = item.title
                    chosenNote = item.note ?? ""
                    dismiss()
                }
            }
        }
    }

    private func suggestionCard(_ item: SuggestedIntention, showsPopeImage: Bool) -> some View {
        Button {
            adoptSuggestion(item)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                if showsPopeImage {
                    Image("PopeLeo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.sourceLabel)
                        .font(AppTheme.sans(11, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(item.title)
                        .font(AppTheme.sans(16, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = item.note, !note.isEmpty {
                        Text(note)
                            .font(AppTheme.sans(13))
                            .foregroundStyle(palette.dim)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.card)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared chrome

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.sans(13, weight: .medium))
            .foregroundStyle(palette.dim)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func radioCard(
        title: String,
        subtitle: String?,
        selected: Bool,
        showsPin: Bool = false,
        showsNewBadge: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accent : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(AppTheme.sans(16, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .multilineTextAlignment(.leading)
                        if showsPin {
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

                if showsNewBadge {
                    Text("New")
                        .font(AppTheme.sans(11, weight: .semibold))
                        .foregroundStyle(palette.ink.opacity(0.75))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(palette.ink.opacity(0.08)))
                        .accessibilityLabel("New intention")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.card)
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

    // MARK: - Composer


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
                accent: papal ? .teal : .mintGreen,
                emoji: papal ? "✝️" : nil
            )
            chosenId = created.id
            chosenTitle = created.title
            chosenNote = created.note ?? ""
        }
        dismiss()
    }

}
