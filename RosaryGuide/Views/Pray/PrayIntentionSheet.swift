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

    @State private var editorRoute: EditorRoute?
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false

    /// Your intentions for this set, pinned first (via OfferStore sort).
    /// The Pope's monthly intention appears only after the user has added it.
    private var listedIntentions: [OfferIntention] {
        PapalIntention.pickerIntentions(saved: offer.sortedIntentions(for: mysterySet))
    }

    private var noneSelected: Bool { chosenId == nil && chosenTitle.isEmpty }

    /// Measured height of the list (incl. its padding). Re-measured on every layout, so
    /// item count changes and multi-line titles always update the detent.
    @State private var contentHeight: CGFloat = 0
    @State private var selectedDetent: PresentationDetent = .large

    /// Inline navigation bar + grabber area above the scroll content.
    private let sheetChromeHeight: CGFloat = 64

    /// Fits the sheet to its content; falls back to `.large` (scrolling) until measured
    /// or when the content would take more than ~90% of the screen.
    private var fittedDetent: PresentationDetent {
        guard contentHeight > 0 else { return .large }
        let total = contentHeight + sheetChromeHeight
        let screen = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first ?? 800
        return total > screen * 0.9 ? .large : .height(ceil(total))
    }

    private var availableDetents: Set<PresentationDetent> {
        fittedDetent == .large ? [.large] : [fittedDetent, .large]
    }

    private let cardMinHeight: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    ForEach(listedIntentions) { item in
                        IntentionRadioRow(
                            item: item,
                            hideText: hideIntentionText,
                            selected: chosenId == item.id,
                            allowsPin: offer.sortedIntentions.count > 1,
                            cardMinHeight: cardMinHeight,
                            onChoose: { choose(item) },
                            onPin: { pinOrUnpin(item) },
                            onEdit: { editorRoute = .edit(item) },
                            onDelete: { deleteIntention(item) },
                            allowsArchive: true
                        )
                    }

                    radioCard(
                        title: "No specific intention",
                        subtitle: nil,
                        selected: noneSelected
                    ) {
                        chooseNone()
                    }

                    addIntentionCard
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.sm)
                .padding(.bottom, 28)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    contentHeight = height
                }
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
                    },
                    onDeleted: { deleted in
                        if chosenId == deleted.id {
                            chosenId = nil
                            chosenTitle = ""
                            chosenNote = ""
                        }
                    }
                )
                .environment(offer)
                .environment(\.palette, palette)
            }
        }
        .onChange(of: offer.sortedIntentions.map(\.id)) { _, ids in
            // Archived from the row menu: drop it from the selection.
            if let id = chosenId, !ids.contains(id) {
                chosenId = nil
                chosenTitle = ""
                chosenNote = ""
            }
        }
        .presentationDetents(availableDetents, selection: $selectedDetent)
        .onChange(of: fittedDetent, initial: true) { _, detent in
            selectedDetent = detent
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rows

    private var addIntentionCard: some View {
        PillButton(title: "Add an intention", filled: false) {
            editorRoute = .create
        }
        .accessibilityLabel("Add an intention")
        .padding(.top, 6)
    }

    private func radioCard(
        title: String,
        subtitle: String?,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accentText : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)
                    .guideSymbolSwap(value: selected)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    WordSafeText(title, font: AppTheme.TypeRole.bodyUIFont(weight: .semibold), color: palette.ink)
                        .multilineTextAlignment(.leading)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.TypeRole.label)
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
            .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
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

}

/// Intention radio row with trailing overflow outside the select Button so menu taps
/// do not also select the radio (same overlay pattern as CurrentIntentionHero).
struct IntentionRadioRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.pageStyle) private var pageStyle
    @Environment(OfferStore.self) private var offer: OfferStore?

    let item: OfferIntention
    let hideText: Bool
    let selected: Bool
    let allowsPin: Bool
    let cardMinHeight: CGFloat
    let onChoose: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    /// Checkbox style for the multi-select intention step; radio otherwise.
    var multiSelect = false
    /// History detail: same card, no check mark, menu or tap.
    var readOnly = false
    /// Adds the app's standard "Archive" item to the row menu.
    var allowsArchive = false
    /// Prayer-flow picker: trailing info button and a long-press menu, instead of the ellipsis.
    var usesNoteInfoAndContextMenu = false
    /// Dims selection only, so the info button and long-press menu stay available at the limit.
    var selectionDisabled = false

    @State private var showingDeleteAlert = false
    @State private var showingNoteSheet = false

    private var hidesText: Bool {
        IntentionPrivacy.hides(item, hidden: hideText)
    }

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(item, hidden: hideText)
    }

    private var subtitle: String? {
        // The Holy Father's row shows its month ("November 2026"), as on Profile.
        item.papalMonthLabel ?? item.categoryTitle
    }

    private var showsNoteInfoButton: Bool {
        usesNoteInfoAndContextMenu && IntentionNote.showsInfoButton(for: item, hideText: hideText)
    }

    var body: some View {
        Button(action: onChoose) {
            card
        }
        .buttonStyle(.plain)
        .disabled(readOnly || selectionDisabled)
        .accessibilityAddTraits(selected && !readOnly ? .isSelected : [])
        .accessibilityLabel(hidesText ? IntentionPrivacy.maskedText : item.title)
        .overlay(alignment: .trailing) {
            trailingControl
        }
        .contentShape(
            .contextMenuPreview,
            RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
        )
        .contextMenu {
            if usesNoteInfoAndContextMenu, !readOnly {
                contextMenuItems
            }
        } preview: {
            if usesNoteInfoAndContextMenu, !readOnly {
                contextMenuPreview
            }
        }
        .sheet(isPresented: $showingNoteSheet) {
            IntentionNoteSheet(intention: item, hideText: hideText)
                .environment(\.palette, palette)
                .environment(\.colorScheme, palette.scheme)
                .preferredColorScheme(palette.scheme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(palette.surface)
        }
        .alert("Delete intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(displayTitle)” from your intentions.")
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
    }

    /// Long-press snapshot. The preview host defaults to a light `ThemePalette`,
    /// which would paint a light surface behind the already-resolved `palette.ink`.
    /// Bake the current token surface and scheme into the preview instead.
    private var contextMenuPreview: some View {
        cardCore
            .background(palette.cardSurface(on: pageStyle), in: cardShape)
            .overlay {
                cardShape.stroke(palette.cardSurfaceStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
            }
            .overlay {
                cardShape.strokeBorder(
                    selected ? palette.accent.opacity(0.45) : Color.clear,
                    lineWidth: 1
                )
            }
            .environment(\.palette, palette)
            .environment(\.pageStyle, pageStyle)
            .environment(\.colorScheme, palette.scheme)
            .preferredColorScheme(palette.scheme)
    }

    private var card: some View {
        cardCore
            .guideSurface(in: cardShape)
            .overlay(
                cardShape.strokeBorder(
                    selected ? palette.accent.opacity(0.45) : Color.clear,
                    lineWidth: 1
                )
            )
            .contentShape(cardShape)
    }

    private var cardCore: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.md) {
            if !readOnly {
                Image(systemName: selected ? (multiSelect ? "checkmark.circle.fill" : "circle.inset.filled") : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accentText : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)
                    .guideSymbolSwap(value: selected)
            }

            IntentionIconView(
                accent: item.accent,
                emoji: item.displayEmoji,
                size: 40,
                usesPopePortrait: item.isPapal
            )

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                HStack(spacing: AppTheme.Space.sm) {
                    WordSafeText(displayTitle, font: AppTheme.TypeRole.bodyUIFont(weight: .semibold), color: palette.ink)
                        .multilineTextAlignment(.leading)
                    if item.isPinned, !multiSelect {
                        Image(systemName: "pin.fill")
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.accentText)
                    }
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTheme.TypeRole.label)
                        .foregroundStyle(palette.dim)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Reserve trailing space so an overlaid control sits clear of the title.
            if showsTrailingControl {
                Color.clear
                    .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
    }

    private var showsTrailingControl: Bool {
        if readOnly { return false }
        if usesNoteInfoAndContextMenu { return showsNoteInfoButton }
        return true
    }

    @ViewBuilder
    private var trailingControl: some View {
        // Outside the row Button so the control does not also select the radio.
        if usesNoteInfoAndContextMenu {
            if showsNoteInfoButton {
                Button {
                    showingNoteSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .guideSymbol(size: 20, weight: .regular)
                        .foregroundStyle(palette.accentText)
                        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .environment(\.isEnabled, true)
                .accessibilityLabel("Read note for \(displayTitle)")
                .padding(.trailing, 14)
            }
        } else if !readOnly {
            OverflowMenuButton(
                isPinned: item.isPinned,
                intentionID: allowsArchive ? item.id : nil,
                allowsPin: allowsPin,
                allowsEdit: true,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: { showingDeleteAlert = true }
            )
            .padding(.trailing, 14)
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            onEdit()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        if allowsPin {
            Button {
                onPin()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin.fill")
            }
        }
        if allowsArchive, let offer, !offer.isArchived(item.id) {
            Button {
                if Motion.isReduceMotionEnabled {
                    offer.archive(id: item.id)
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { offer.archive(id: item.id) }
                }
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

/// Half-height sheet that shows an intention's attached note in the prayer-flow picker.
struct IntentionNoteSheet: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    let intention: OfferIntention
    var hideText: Bool = false

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(intention, hidden: hideText)
    }

    private var subtitle: String? {
        intention.papalMonthLabel ?? intention.categoryTitle
    }

    private var noteText: String? {
        IntentionNote.displayNote(for: intention, hideText: hideText)
    }

    /// Extra leading on the serif note, derived from the TypeRole face rather than a raw point size.
    private static var noteLineSpacing: CGFloat {
        let ui = AppTheme.TypeRole.serifBodyUIFont
        return max(0, (ui.lineHeight * 1.15) - ui.lineHeight)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    HStack(alignment: .center, spacing: AppTheme.Space.md) {
                        IntentionIconView(
                            accent: intention.accent,
                            emoji: intention.displayEmoji,
                            size: 40,
                            usesPopePortrait: intention.isPapal
                        )
                        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                            WordSafeText(displayTitle, font: AppTheme.TypeRole.bodyUIFont(weight: .semibold), color: palette.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            if let subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(AppTheme.TypeRole.label)
                                    .foregroundStyle(palette.dim)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let noteText {
                        Text(noteText)
                            .font(Font(AppTheme.TypeRole.serifBodyUIFont))
                            .foregroundStyle(palette.ink)
                            .lineSpacing(IntentionNoteSheet.noteLineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.sm)
                .padding(.bottom, AppTheme.Space.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(palette.surface)
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                        .foregroundStyle(palette.accentText)
                        .tint(palette.accentText)
                }
            }
        }
        .environment(\.colorScheme, palette.scheme)
        .preferredColorScheme(palette.scheme)
        .presentationBackground(palette.surface)
    }
}

/// Multi-select intention list for the "Offer this Rosary for" prayer step.
/// Saved intentions only — the Pope's monthly intention appears once the user has
/// added it — up to `PrayerSession.maxIntentions`; at the limit the unselected
/// rows dim and disable. "No specific intention" clears every selection.
struct IntentionMultiSelectList: View {
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette

    @Binding var selectedIds: [UUID]
    var mysterySet: MysterySetKind
    /// Off when the host shows its own Add intention button (the prayer step's footer).
    var showsAddButton = true
    /// Each change opens the new-intention editor, so a host button can drive it.
    var addRequests = 0

    @State private var editorRoute: EditorRoute?
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false

    private let cardMinHeight: CGFloat = 64
    private var limit: Int { PrayerSession.maxIntentions }
    private var atLimit: Bool { selectedIds.count >= limit }

    private var listedIntentions: [OfferIntention] {
        PapalIntention.pickerIntentions(saved: offer.sortedIntentions(for: mysterySet))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            ForEach(listedIntentions) { item in
                let selected = selectedIds.contains(item.id)
                IntentionRadioRow(
                    item: item,
                    hideText: hideIntentionText,
                    selected: selected,
                    allowsPin: offer.sortedIntentions.count > 1,
                    cardMinHeight: cardMinHeight,
                    onChoose: { toggle(item.id) },
                    onPin: { offer.togglePin(id: item.id) },
                    onEdit: { editorRoute = .edit(item) },
                    onDelete: {
                        selectedIds.removeAll { $0 == item.id }
                        offer.delete(id: item.id)
                    },
                    multiSelect: true,
                    allowsArchive: true,
                    usesNoteInfoAndContextMenu: true,
                    selectionDisabled: atLimit && !selected
                )
                .opacity(atLimit && !selected ? 0.4 : 1)
            }

            selectCard(
                title: "No specific intention",
                subtitle: nil,
                showsPope: false,
                selected: selectedIds.isEmpty
            ) {
                selectedIds = []
            }

            if showsAddButton {
                GuideTextButton(title: "Add an intention") {
                    editorRoute = .create
                }
                .padding(.top, AppTheme.Space.xs)
            }
        }
        .onChange(of: addRequests) { _, _ in
            editorRoute = .create
        }
        .onChange(of: offer.sortedIntentions.map(\.id)) { _, ids in
            // Archived from the row menu: drop it from the selection.
            selectedIds.removeAll { !ids.contains($0) }
        }
        .sheet(item: $editorRoute) { route in
            IntentionEditorSheet(
                route: route,
                initialMystery: mysterySet,
                onSaved: { saved in
                    if !selectedIds.contains(saved.id), selectedIds.count < limit {
                        selectedIds.append(saved.id)
                    }
                },
                onDeleted: { deleted in
                    selectedIds.removeAll { $0 == deleted.id }
                }
            )
            .environment(offer)
            .environment(\.palette, palette)
        }
    }

    private func toggle(_ id: UUID) {
        if let index = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: index)
        } else if selectedIds.count < limit {
            selectedIds.append(id)
        }
    }

    private func selectCard(
        title: String,
        subtitle: String?,
        showsPope: Bool,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .guideSymbol(size: 22, weight: .regular)
                    .foregroundStyle(selected ? palette.accentText : palette.ink.opacity(0.45))
                    .frame(width: 24, height: 24)
                    .guideSymbolSwap(value: selected)

                if showsPope {
                    IntentionIconView(accent: .purple, emoji: "✝️", size: 40, usesPopePortrait: true)
                }

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    WordSafeText(title, font: AppTheme.TypeRole.bodyUIFont(weight: .semibold), color: palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.TypeRole.label)
                            .foregroundStyle(palette.dim)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .leading)
            .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(selected ? palette.accent.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
