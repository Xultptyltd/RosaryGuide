import SwiftUI
import UIKit


struct OfferView: View {
    @Environment(OfferStore.self) private var offer
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.palette) private var palette
    @Binding var prayLaunch: PrayLaunch?

    @State private var editor: EditorRoute?
    @State private var papalDetail: SuggestedIntention?
    @State private var titleScrollOffset: CGFloat = 0
    @State private var navigationPath = NavigationPath()
    @State private var popeStore = PopeIntentionStore.shared
    @State private var intentionDetail: OfferIntention?
    @State private var showingPremium = false
    /// Set when Premium opens because the free intention limit was hit.
    @State private var premiumNote: String?
    /// Banking-style privacy: when true, mask personal intention titles on the list surface.
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false
    /// Space an IntentionListRow leaves under its icon (its vertical padding).
    private static let intentionRowBottomInset: CGFloat = 10
    private var todaySet: MysterySetKind {
        MysteryCalendar.assignment(on: Date()).set
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if offer.sortedIntentions.isEmpty {
                    emptyState
                } else {
                    intentionList
                }
            }
            .background(palette.bg)
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .collapsingTitleChrome(
                "My prayer",
                scrollOffset: $titleScrollOffset,
                morphEnabled: true
            )
            .sheet(item: $editor) { route in
                IntentionEditorSheet(
                    route: route,
                    onDeleted: { deleted in
                        if intentionDetail?.id == deleted.id {
                            intentionDetail = nil
                        }
                    }
                )
                    .environment(offer)
                    .environment(\.palette, palette)
            }
            .navigationDestination(item: $papalDetail) { item in
                PapalIntentionDetailView(
                    item: item,
                    isAdded: hasAdoptedSuggestion(item),
                    onAdd: { adoptSuggestion(item) }
                )
            }
            .navigationDestination(item: $intentionDetail) { item in
                IntentionDetailView(
                    intention: item,
                    hideText: hideIntentionText,
                    onPin: { offer.togglePin(id: item.id) },
                    onEdit: { editor = .edit(item) },
                    onDelete: { offer.delete(id: item.id) },
                    onPray: { prayWith(item) }
                )
            }
            .navigationDestination(isPresented: $showingPremium) {
                PremiumScreen(note: premiumNote)
            }
            .onChange(of: showingPremium) { _, showing in
                if !showing { premiumNote = nil }
            }
            .onAppear { offer.pruneExpired() }
        }
    }



    private var emptyState: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                CollapsingTitleSpacer()

                // Full-bleed illustration: outside page gutter so container is edge-to-edge;
                // image is scaledToFit inside a taller canvas so no source edge is clipped.
                emptyHandsIllustration
                    .padding(.top, AppTheme.Space.sm)

                VStack(spacing: AppTheme.Space.lg) {
                    syncWarning

                    Text("Keep the people, needs and hopes you want to remember in your Rosary.")
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.dim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, AppTheme.Space.md)

                    addIntentionButton(title: "Add your first intention", showsIcon: false)

                    emptyOrDivider

                    if let papalSuggestion = visiblePapalSuggestion {
                        EmptyPapalIntentionCard(
                            monthLine: papalEmptyMonthLine(for: papalSuggestion)
                        ) {
                            papalDetail = papalSuggestion
                        }
                    }

                    prayerJourneysSection
                        // sectionGap above (the stack already adds Space.lg).
                        .padding(.top, AppTheme.sectionGap - AppTheme.Space.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.lg)
            }
            .padding(.bottom, 108)
        }
    }

    private func addIntentionButton(
        title: String,
        isPrimary: Bool = true,
        matchesLearnStyle: Bool = false,
        showsIcon: Bool = true
    ) -> some View {
        Button {
            startAddingIntention()
        } label: {
            if matchesLearnStyle {
                Text(title)
                    .font(AppTheme.TypeRole.callout(weight: .semibold))
                    .foregroundStyle(palette.secondaryButtonText)
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.secondaryButtonFill, in: Capsule())
            } else {
                HStack(spacing: AppTheme.Space.sm) {
                    if showsIcon {
                        Image(systemName: "plus")
                            .guideSymbol(size: 15, weight: .semibold)
                    }
                    Text(title)
                }
                .font(AppTheme.TypeRole.callout(weight: .semibold))
                .foregroundStyle(isPrimary ? palette.primaryButtonText : palette.secondaryButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Component.pillHeight)
                .background(isPrimary ? palette.primaryButtonFill : palette.secondaryButtonFill, in: AppTheme.capsule)
            }
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel(title)
    }

    /// Tall full-bleed container; image scaledToFit (no crop). Fade is baked into the PNG.
    private var emptyHandsIllustration: some View {
        Image("PrayingHandsEmpty")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipped(antialiased: false)
            .accessibilityHidden(true)
    }

    private var emptyOrDivider: some View {
        HStack(spacing: AppTheme.Space.md) {
            Hairline()
            Text("or")
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.faint)
            Hairline()
        }
        .padding(.horizontal, AppTheme.Space.sm)
        .accessibilityHidden(true)
    }

    private func papalEmptyMonthLine(for item: SuggestedIntention) -> String {
        item.monthLabel ?? currentMonthTitle
    }

    private var suggestions: [SuggestedIntention] { IntentionSuggestions.forDay(popeStore: popeStore) }
    private var currentIntention: OfferIntention? {
        // Featured/current card only when something is explicitly pinned.
        offer.sortedIntentions.first(where: \.isPinned)
    }
    private var secondaryIntentions: [OfferIntention] {
        guard let currentIntention else { return offer.sortedIntentions }
        return offer.sortedIntentions.filter { $0.id != currentIntention.id }
    }
    private var papalSuggestion: SuggestedIntention? {
        suggestions.first(where: isPapalSuggestion)
    }
    /// This month's Pope's card, hidden only while this month's intention is in the
    /// user's list. Per month: the suggestion id is "pope-<yearMonth>", so October's
    /// adopted intention ("pope-2026-10") does not hide November's card.
    /// Removing it brings the card back.
    private var visiblePapalSuggestion: SuggestedIntention? {
        guard let papalSuggestion, !hasAdoptedThisMonthsPapal(papalSuggestion) else { return nil }
        return papalSuggestion
    }

    /// Matches on the month's id. A title match only counts for an untagged intention
    /// (typed by hand), so an earlier month's tagged intention with the same wording
    /// never hides a new month's card.
    private func hasAdoptedThisMonthsPapal(_ item: SuggestedIntention) -> Bool {
        offer.sortedIntentions.contains {
            $0.sourceId == item.id
                || ($0.sourceId == nil
                    && $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame)
        }
    }
    private var currentMonthTitle: String {
        Date().formatted(.dateTime.month(.wide).year())
    }

    private var titlePrivacyButton: some View {
        Button {
            settings.hideIntentionText.toggle()
        } label: {
            Group {
                if hideIntentionText {
                    ClosedEyeIcon()
                } else {
                    Image(systemName: "eye")
                        .guideSymbol(size: 17, weight: .medium)
                }
            }
            .foregroundStyle(palette.dim)
            .frame(
                width: AppTheme.Accessibility.minHitTarget,
                height: AppTheme.Accessibility.minHitTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel(hideIntentionText ? "Show intentions" : "Hide intentions")
    }
    /// "Prayer journeys" section: title, sectionTitleGap, then the Rosary Guide+ card.
    /// No entitlement flag exists yet, so the upsell always shows.
    private var prayerJourneysSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "Prayer journeys", prominence: .strong)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            PremiumUpsellCard { showingPremium = true }
                .padding(.top, AppTheme.sectionTitleGap)
        }
    }

    /// "Your intentions" section title with the hide/show intentions toggle on the right.
    /// The 44pt toggle is an overlay so it doesn't add height to the title row; it is
    /// nudged right so the eye glyph lines up with the cards' trailing edge.
    private var intentionsSectionHeader: some View {
        GuideSectionLabel(text: "Your intentions", prominence: .strong)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, AppTheme.Accessibility.minHitTarget)
            .overlay(alignment: .trailing) {
                titlePrivacyButton
                    .offset(x: 12)
            }
    }

    private var intentionList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Prayer rhythm directly beneath the page title, then the "Your intentions" section.
                VStack(alignment: .leading, spacing: 0) {
                    CollapsingTitleSpacer()

                    // Live: completedDayStarts is observed, so finishing a rosary updates it.
                    PrayerRhythmCard(rhythm: PrayerRhythm(prayedDayStarts: sessionStore.completedDayStarts))

                    intentionsSectionHeader
                        // Rhythm card to the heading: tighter than sectionGap (44) on this screen.
                        .padding(.top, 36)

                    syncWarning
                        .padding(.horizontal, AppTheme.gutter)
                }

                VStack(alignment: .leading, spacing: 0) {
                    if let currentIntention {
                        CurrentIntentionHero(
                            intention: currentIntention,
                            hideText: hideIntentionText,
                            onOpen: { intentionDetail = currentIntention },
                            onPray: { prayWith(currentIntention) },
                            onPin: { offer.togglePin(id: currentIntention.id) },
                            onEdit: { editor = .edit(currentIntention) },
                            onDelete: { offer.delete(id: currentIntention.id) },
                            allowsPin: offer.sortedIntentions.count > 1
                        )
                        .guideNavList(pageGutter: AppTheme.gutter)
                    }

                    if let papalSuggestion = visiblePapalSuggestion {
                        PapalMonthCard(
                            item: papalSuggestion,
                            isAdded: hasAdoptedSuggestion(papalSuggestion),
                            onOpen: { papalDetail = papalSuggestion },
                            onAdd: { adoptSuggestion(papalSuggestion) }
                        )
                        .guideNavList(pageGutter: AppTheme.gutter)
                        // Featured card to the Pope's card.
                        .padding(.top, currentIntention == nil ? 0 : AppTheme.Space.md)
                    }

                    // Tertiary pill, same as Complete decade in the rosary flow.
                    PillButton(title: "Add an intention", filled: false, tertiary: true) {
                        startAddingIntention()
                    }
                        .guideNavList(pageGutter: AppTheme.gutter)
                        // Featured / Pope's card to the Add button.
                        .padding(.top, (currentIntention == nil && visiblePapalSuggestion == nil) ? 0 : AppTheme.Space.md)

                    VStack(spacing: 0) {
                        ForEach(secondaryIntentions) { item in
                            IntentionSecondaryRow(
                                intention: item,
                                hideText: hideIntentionText,
                                allowsPin: offer.sortedIntentions.count > 1,
                                onPin: { offer.togglePin(id: item.id) },
                                onEdit: { editor = .edit(item) },
                                onDelete: { offer.delete(id: item.id) },
                                onPray: { prayWith(item) }
                            )

                            if item.id != secondaryIntentions.last?.id {
                                Hairline()
                                    .padding(.leading, 62)
                            }
                        }
                    }
                    .guideNavList(pageGutter: AppTheme.gutter)
                    // Add button to the secondary rows (unchanged).
                    .padding(.top, 12)
                }
                // "Your intentions" heading to the first card.
                .padding(.top, AppTheme.sectionTitleGap)

                prayerJourneysSection
                    // Visible sectionGap: intention rows carry their own bottom inset.
                    .padding(.top, AppTheme.sectionGap - (secondaryIntentions.isEmpty ? 0 : Self.intentionRowBottomInset))
            }
            .padding(.horizontal, AppTheme.gutter)
            // Same top breathing room as FeastsView before its title/control block.
            .padding(.top, AppTheme.Space.sm)
            .padding(.bottom, 108)
        }
    }

    @ViewBuilder
    private var syncWarning: some View {
        if let message = offer.syncErrorMessage {
            HStack(alignment: .top, spacing: AppTheme.Space.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .guideSymbol(size: 14, weight: .medium)
                    .foregroundStyle(palette.dim)

                Text(message)
                    .font(AppTheme.TypeRole.caption())
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private func isPapalSuggestion(_ item: SuggestedIntention) -> Bool {
        item.id.hasPrefix("pope-")
            || item.sourceLabel.lowercased().contains("pope")
            || item.sourceLabel.lowercased().contains("holy father")
    }

    private func hasAdoptedSuggestion(_ item: SuggestedIntention) -> Bool {
        offer.sortedIntentions.contains {
            $0.sourceId == item.id
                || $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private func adoptSuggestion(_ item: SuggestedIntention) {
        let papal = isPapalSuggestion(item)
        if let existing = offer.sortedIntentions.first(where: {
            $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
            if papal, existing.sourceId == nil {
                var tagged = existing
                tagged.sourceId = item.id
                tagged.category = .world
                if tagged.emoji == nil { tagged.emoji = "✝️" }
                offer.update(tagged)
            }
            // Already in the list — editable from the row menu; don't force the editor open.
        } else {
            guard papal || offer.canAddIntention else {
                showIntentionLimitPremium()
                return
            }
            _ = offer.add(
                title: item.title,
                note: item.note,
                sourceId: papal ? item.id : nil,
                category: papal ? .world : .personal,
                accent: papal ? .purple : .mintGreen,
                emoji: papal ? "✝️" : "🙏"
            )
            // Papal: add quietly. Others: open editor so they can refine.
            if !papal, let created = offer.sortedIntentions.first(where: {
                $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                editor = .edit(created)
            }
        }
    }

    private func prayWith(_ item: OfferIntention) {
        prayLaunch = .fresh(item.prayMystery(today: todaySet), intentionId: item.id)
    }

    /// Add flow entry: the editor, or Rosary Guide+ when a free user is at the limit.
    private func startAddingIntention() {
        if offer.canAddIntention {
            editor = .create
        } else {
            showIntentionLimitPremium()
        }
    }

    private func showIntentionLimitPremium() {
        premiumNote = IntentionLimit.premiumNote
        showingPremium = true
    }
}

private struct CurrentIntentionHero: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    let intention: OfferIntention
    var hideText: Bool = false
    let onOpen: () -> Void
    let onPray: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var allowsPin: Bool = true
    @State private var showingDeleteAlert = false

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(intention, hidden: hideText)
    }

    private var titleColor: Color {
        IntentionPrivacy.hides(intention, hidden: hideText) ? palette.dim : palette.ink
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                HStack(alignment: .center, spacing: AppTheme.Space.lg) {
                    IntentionIconView(
                        accent: intention.accent,
                        emoji: intention.displayEmoji,
                        size: 64,
                        usesPopePortrait: intention.isPapal
                    )

                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(displayTitle)
                            .font(AppTheme.TypeRole.body(weight: .semibold))
                            .foregroundStyle(titleColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Reserve trailing space so the overlaid overflow menu sits where the chevron was.
                    Color.clear
                        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                        .accessibilityHidden(true)
                }

                // Layout-only stand-in; real pray control is overlaid so it does not trigger navigation.
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Component.pillHeight)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.Space.lg)
            // Flat surface like every card on My prayer (no border or shadow).
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(IntentionPrivacy.hides(intention, hidden: hideText) ? "Open hidden intention" : "Open \(intention.title)")
        .overlay(alignment: .topTrailing) {
            // Outside the card Button so menu taps do not also open detail.
            OverflowMenuButton(
                isPinned: intention.isPinned,
                allowsPin: allowsPin,
                allowsEdit: true,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: { showingDeleteAlert = true }
            )
            .padding(.top, AppTheme.Space.lg + 10)
            .padding(.trailing, AppTheme.Space.lg)
        }
        .overlay(alignment: .bottom) {
            // Outside the card Button so pray does not also open detail.
            // Secondary pill, same as Next in the rosary flow.
            PillButton(title: "Offer my next Rosary", filled: false, action: onPray)
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.bottom, AppTheme.Space.lg)
        }
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(displayTitle)” from your intentions.")
        }
    }

}

private struct EmptyPapalIntentionCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    let monthLine: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                Image("PopeLeo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("Holy Father’s intention")
                        .font(AppTheme.TypeRole.caption(weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(monthLine)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .guideSymbol(size: 12, weight: .semibold)
                    .foregroundStyle(palette.faint)
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.vertical, AppTheme.Space.md)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: colorScheme == .light)
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Holy Father’s intention, \(monthLine)")
        .accessibilityHint("Opens the Pope’s intention")
    }
}

private struct PapalMonthCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    let item: SuggestedIntention
    let isAdded: Bool
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: AppTheme.Space.lg) {
                Image("PopeLeo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(item.title)
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(monthLabel)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, AppTheme.Space.lg)
                .padding(.vertical, AppTheme.Space.md)
            }
            .frame(minHeight: 96)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("\(monthLabel), \(item.title)")
        .accessibilityHint("Opens the Pope’s intention")
        .accessibilityElement(children: .combine)
    }

    private var monthLabel: String {
        item.monthLabel ?? Date().formatted(.dateTime.month(.wide).year())
    }

}

private struct PapalIntentionDetailView: View {
    @Environment(\.palette) private var palette
    let item: SuggestedIntention
    let isAdded: Bool
    let onAdd: () -> Void
    @State private var didAdd = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                hero
                heroCopy

                if let note = item.note {
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        GuideSectionLabel(text: "Intention", color: palette.dim)
                        Text(note)
                            .font(AppTheme.TypeRole.body(weight: .regular))
                            .foregroundStyle(palette.ink)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(7)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !added {
                    Button {
                        onAdd()
                        didAdd = true
                    } label: {
                        HStack {
                            Text("Add to my intentions")
                            Image(systemName: "arrow.right")
                                .guideSymbol(size: 14, weight: .semibold)
                        }
                        .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                        .foregroundStyle(palette.primaryButtonText)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Component.pillHeight)
                        .background(palette.primaryButtonFill, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 80)
            }
            // Cap content to the ScrollView's proposed width so no child
            // (hero image ideal size, long unwrapped text) can widen the page.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, 18)
            .padding(.bottom, 108)
        }
        .background(palette.bg)
        .guideDetailChrome("Holy Father’s intention")
    }

    private var hero: some View {
        // Keep the image wide and bounded by the page width so its intrinsic
        // asset size cannot widen the scroll view.
        Color.clear
            .aspectRatio(1.3, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                Image("PopeLeoWide")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            Text(monthLabel)
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .tracking(AppTheme.Component.sectionLabelTracking)
                .textCase(.uppercase)
                .foregroundStyle(palette.dim)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.title)
                .font(AppTheme.TypeRole.screenTitle)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(monthLabel), \(item.title)")
    }

    private var monthLabel: String {
        item.monthLabel ?? Date().formatted(.dateTime.month(.wide).year())
    }

    private var added: Bool {
        isAdded || didAdd
    }
}

/// Secondary row: NavigationLink for open, overflow menu overlaid outside the link
/// so Pin/Edit/Delete are not swallowed by navigation (same pattern as CurrentIntentionHero).
private struct ClosedEyeIcon: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            ClosedEyeLid()
                .stroke(
                    palette.dim,
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )

            ClosedEyeLashes()
                .stroke(
                    palette.dim,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(width: 19, height: 17)
        .accessibilityHidden(true)
    }
}

private struct ClosedEyeLid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.45))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.45),
            control: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.12)
        )
        return path
    }
}

private struct ClosedEyeLashes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.minY + rect.height * 0.64
        let lashTop = rect.minY + rect.height * 0.78
        [0.36, 0.5, 0.64].forEach { ratio in
            let x = rect.minX + rect.width * ratio
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: lashTop))
        }
        return path
    }
}

private struct IntentionSecondaryRow: View {
    let intention: OfferIntention
    var hideText: Bool = false
    var allowsPin: Bool = true
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPray: () -> Void
    @State private var showingDeleteAlert = false

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(intention, hidden: hideText)
    }

    var body: some View {
        NavigationLink {
            IntentionDetailView(
                intention: intention,
                hideText: hideText,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: onDelete,
                onPray: onPray
            )
        } label: {
            IntentionListRow(intention: intention, hideText: hideText)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            OverflowMenuButton(
                isPinned: intention.isPinned,
                allowsPin: allowsPin,
                allowsEdit: true,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: { showingDeleteAlert = true }
            )
        }
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(displayTitle)” from your intentions.")
        }
    }
}

private struct IntentionListRow: View {
    @Environment(\.palette) private var palette
    let intention: OfferIntention
    var hideText: Bool = false

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(intention, hidden: hideText)
    }

    private var titleColor: Color {
        IntentionPrivacy.hides(intention, hidden: hideText) ? palette.dim : palette.ink
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.lg) {
            IntentionIconView(
                accent: intention.accent,
                emoji: intention.displayEmoji,
                size: 44,
                usesPopePortrait: intention.isPapal
            )

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                HStack(spacing: AppTheme.Space.sm) {
                    Text(displayTitle)
                        .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                    if intention.isPinned {
                        Image(systemName: "pin.fill")
                            .guideSymbol(size: 12, weight: .semibold)
                            .foregroundStyle(palette.accent)
                    }
                }
                Text(metaLabel)
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Reserve trailing space so the overlaid overflow menu sits clear of the title.
            Color.clear
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityLabel(IntentionPrivacy.hides(intention, hidden: hideText) ? "Hidden intention, \(metaLabel)" : "\(intention.title), \(metaLabel)")
    }

    private var metaLabel: String {
        intention.createdAt.formatted(.dateTime.month(.wide).year())
    }
}

private struct IntentionDetailView: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let intention: OfferIntention
    var hideText: Bool = false
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPray: () -> Void
    @State private var showingDeleteAlert = false

    private var privacyHidesText: Bool {
        IntentionPrivacy.hides(intention, hidden: hideText)
    }

    private var displayTitle: String {
        IntentionPrivacy.displayTitle(intention, hidden: hideText)
    }

    private var hiddenTextColor: Color {
        privacyHidesText ? palette.dim : palette.ink
    }

    private var displayNoteText: String {
        guard hasNote else { return "Add Notes" }
        return privacyHidesText ? IntentionPrivacy.maskedNoteText : noteText
    }

    private var detailNavigationTitle: String {
        intention.isPapal ? "Holy Father’s intention" : intention.category.title
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                detailHeader
                    .padding(.top, 18)

                statsCard

                if shouldShowNotesField {
                    notesField
                }

                Button(action: onPray) {
                    Text("Offer a Rosary")
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                        .foregroundStyle(palette.secondaryButtonText)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Component.pillHeight)
                        .background(palette.secondaryButtonFill, in: Capsule())
                }
                .buttonStyle(.plain)

                detailSection

                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
        }
        .background(palette.bg)
        .toolbar {
            if !intention.isPapal {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", action: onEdit)
                        .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                        .foregroundStyle(palette.accent)
                }
            }
        }
        .navigationTitle(detailNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("This will delete “\(displayTitle)” from your intentions.")
        }
    }

    private var detailHeader: some View {
        // Avatar stacked above title; title spans full width. No card surface.
        // Cancel page gutter so the block sits AppTheme.gutter (16pt) from screen edges.
        // Category and Current chip live in bottom details / elsewhere — not in this header.
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            IntentionIconView(
                accent: intention.accent,
                emoji: intention.displayEmoji,
                size: 64,
                usesPopePortrait: intention.isPapal
            )

            Text(displayTitle)
                .font(AppTheme.TypeRole.modalTitle)
                .foregroundStyle(hiddenTextColor)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideNavList(pageGutter: AppTheme.gutter)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat("\(intention.timesCarried)", intention.timesCarried == 1 ? "Rosary prayed" : "Rosaries prayed")
            Divider().opacity(0.4)
            stat(lastPrayedRelative, "Last prayed")
        }
        .frame(height: 80)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.TypeRole.body(weight: .semibold))
                .foregroundStyle(palette.ink)
            Text(label)
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.dim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var lastPrayedRelative: String {
        guard let date = intention.lastCarriedAt else { return "Not yet prayed" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let startDate = calendar.startOfDay(for: date)
        let startToday = calendar.startOfDay(for: Date())
        let days = max(0, calendar.dateComponents([.day], from: startDate, to: startToday).day ?? 0)

        if (2...6).contains(days) {
            return date.formatted(.dateTime.weekday(.wide))
        }

        if days < 28 {
            let weeks = max(1, days / 7)
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }

        let components = calendar.dateComponents([.year, .month], from: startDate, to: startToday)
        if let years = components.year, years >= 1 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
        let months = max(1, components.month ?? Int(round(Double(days) / 30.0)))
        return months == 1 ? "1 month ago" : "\(months) months ago"
    }

    private var lastPrayedExact: String {
        intention.lastCarriedAt?.formatted(.dateTime.day().month(.wide).year()) ?? "Not yet prayed"
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            VStack(spacing: 0) {
                detailRow("Category", value: intention.categoryTitle)
                Hairline().padding(.leading, 18)
                detailRow("Last prayed", value: lastPrayedExact)
                Hairline().padding(.leading, 18)
                detailRow("Created", value: intention.createdAt.formatted(.dateTime.day().month(.abbreviated).year()))
            }
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private var notesField: some View {
        if hasDisplayNote {
            Text(detailDisplayNoteText)
                .font(AppTheme.TypeRole.themeSummary)
                .foregroundStyle(privacyHidesText ? palette.dim : palette.ink)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        } else {
            Button(action: onEdit) {
                HStack(alignment: .center, spacing: 12) {
                    Text(displayNoteText)
                        .font(AppTheme.TypeRole.themeSummary)
                        .foregroundStyle(palette.dim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "plus")
                        .guideSymbol(size: 14, weight: .semibold)
                        .foregroundStyle(palette.accent)
                }
                .padding(20)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var papalSource: PopeMonthIntention? {
        guard intention.isPapal,
              let sourceId = intention.sourceId,
              sourceId.hasPrefix("pope-")
        else { return nil }
        let yearMonth = String(sourceId.dropFirst("pope-".count))
        return PopeIntentionStore.shared.intentions.first { $0.yearMonth == yearMonth }
    }

    private var papalDisplayNote: String? {
        let fromStore = papalSource?.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let fromStore, !fromStore.isEmpty { return fromStore }
        let saved = intention.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let saved, !saved.isEmpty { return saved }
        return nil
    }

    private var shouldShowNotesField: Bool {
        !intention.isPapal || hasDisplayNote
    }

    private var hasDisplayNote: Bool {
        if intention.isPapal {
            return papalDisplayNote?.isEmpty == false
        }
        return hasNote
    }

    private var detailDisplayNoteText: String {
        if intention.isPapal {
            return papalDisplayNote ?? ""
        }
        return displayNoteText
    }

    private var hasNote: Bool {
        intention.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var noteText: String {
        guard hasNote, let note = intention.note else { return "Add Notes" }
        return note
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(AppTheme.TypeRole.themeSummary)
                .foregroundStyle(palette.ink)
            Spacer()
            Text(value)
                .font(AppTheme.TypeRole.label)
                .foregroundStyle(palette.dim)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.vertical, 15)
    }
}


/// Premium Holy Father suggestion — larger portrait, generous type and padding.
private struct PapalSuggestionCard: View {
    @Environment(\.palette) private var palette
    let item: SuggestedIntention

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                Image("PopeLeo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Text(item.sourceLabel)
                        .font(AppTheme.TypeRole.caption(weight: .medium))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.title)
                        .font(AppTheme.TypeRole.body(weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let note = item.note, !note.isEmpty {
                Text(note)
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(palette.dim)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AppTheme.Space.sm) {
                Text("Tap to add")
                    .font(AppTheme.TypeRole.caption(weight: .medium))
                Image(systemName: "arrow.right")
                    .guideSymbol(size: 11, weight: .semibold)
            }
            .foregroundStyle(palette.accent.opacity(0.9))
            .padding(.top, 2)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Adds the Holy Father’s intention")
    }
}

private struct IntentionRow: View {
    @Environment(\.palette) private var palette
    let intention: OfferIntention
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPray: () -> Void
    var allowsPin: Bool = true
    @State private var showingDeleteAlert = false

    private var hasDescription: Bool {
        if let note = intention.note, !note.isEmpty { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: hasDescription ? .top : .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppTheme.Space.sm) {
                        Text(intention.title)
                            .font(AppTheme.TypeRole.body(weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .multilineTextAlignment(.leading)
                        if intention.isPinned {
                            Image(systemName: "pin.fill")
                                .guideSymbol(size: 12, weight: .semibold)
                                .foregroundStyle(palette.accent)
                                .accessibilityLabel("Pinned")
                        }
                    }

                    if let note = intention.note, !note.isEmpty {
                        Text(note)
                            .font(AppTheme.TypeRole.label)
                            .foregroundStyle(palette.dim)
                            .lineLimit(2)
                    }

                    // Meta under description (or under title when there’s no note)
                    HStack(spacing: AppTheme.Space.sm) {
                        if !intention.carriedLabel.isEmpty {
                            Text(intention.carriedLabel)
                        }
                        if let suggest = intention.suggestOnLabel {
                            if !intention.carriedLabel.isEmpty {
                                Text("·")
                            }
                            Text(suggest)
                        }
                        if let durationLabel = intention.durationLabel {
                            if !intention.carriedLabel.isEmpty || intention.suggestOnLabel != nil {
                                Text("·")
                            }
                            Text(durationLabel)
                        }
                    }
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if intention.isNew {
                    Text("New")
                        .font(AppTheme.TypeRole.caption(weight: .semibold))
                        .foregroundStyle(palette.ink.opacity(0.75))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(palette.ink.opacity(0.08)))
                        .accessibilityLabel("New intention")
                }

                OverflowMenuButton(
                    isPinned: intention.isPinned,
                    allowsPin: allowsPin,
                    allowsEdit: true,
                    onPin: onPin,
                    onEdit: onEdit,
                    onDelete: { showingDeleteAlert = true }
                )
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                .accessibilityLabel("More options")
            }

            Button(action: onPray) {
                Text("Pray for this intention")
                    .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(
                Capsule()
                    .strokeBorder(palette.strongStroke, lineWidth: 1.2)
            )
            .accessibilityHint("Starts a Rosary with this intention")
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityAction(named: intention.isPinned ? "Unpin intention" : "Pin intention", onPin)
        .accessibilityAction(named: "Edit intention", onEdit)
        .accessibilityAction(named: "Pray for this intention", onPray)
        .accessibilityAction(named: "Delete intention") {
            showingDeleteAlert = true
        }
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(intention.title)” from your intentions.")
        }
    }

    private var rowAccessibilityLabel: String {
        var parts = [intention.title, intention.createdAt.formatted(.dateTime.month(.wide).year())]
        if intention.isPinned { parts.append("Current") }
        if !intention.carriedLabel.isEmpty { parts.append(intention.carriedLabel) }
        if let note = intention.note, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }
}


struct OverflowMenuButton: View {
    @Environment(\.palette) private var palette
    var isPinned: Bool
    var allowsPin: Bool = true
    var allowsEdit: Bool = true
    var onPin: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Menu {
            if allowsPin {
                Button {
                    onPin()
                } label: {
                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin.fill")
                }
            }

            if allowsEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                // Menu ignores SwiftUI icon colors; UIKit alwaysOriginal forces red trash.
                Label {
                    Text("Delete")
                } icon: {
                    Image(uiImage: OverflowMenuButton.destructiveTrashIcon)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .guideSymbol(size: 18, weight: .semibold)
                .foregroundStyle(palette.ink)
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
        }
        .accessibilityLabel("More options")
    }

    /// UIMenu keeps template SF Symbols uncolored even with role .destructive;
    /// an alwaysOriginal UIImage is the reliable tint for Menu item icons.
    /// Match UIMenu destructive title red (#FF3B30), not dynamic `UIColor.systemRed`
    /// (light #FF383C / dark #FF4245) which reads as a different red next to "Delete".
    private static let destructiveMenuTitleColor = UIColor(AppTheme.destructiveMenuRed)

    private static let destructiveTrashIcon: UIImage = {
        let base = UIImage(systemName: "trash.fill") ?? UIImage()
        return base.withTintColor(destructiveMenuTitleColor, renderingMode: .alwaysOriginal)
    }()
}


struct IntentionIconView: View {
    @Environment(\.palette) private var palette
    var accent: IntentionAccent
    var emoji: String
    var size: CGFloat = 40
    /// Shown in the picker when `emoji` is empty (e.g. "?"). List rows leave this nil.
    var emptyPlaceholder: String? = nil
    /// Holy Father intentions use the same PopeLeo art as the featured card.
    var usesPopePortrait: Bool = false

    var body: some View {
        Group {
            if usesPopePortrait {
                Image("PopeLeo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(accent.color)
                    if !emoji.isEmpty {
                        if let assetName {
                            Image(assetName)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: symbolSize, height: symbolSize)
                                .foregroundStyle(accent.onColor.opacity(0.88))
                        } else {
                            Image(systemName: symbolName)
                                .guideSymbol(size: symbolSize, weight: .semibold)
                                .foregroundStyle(accent.onColor.opacity(0.88))
                        }
                    } else if let emptyPlaceholder, !emptyPlaceholder.isEmpty {
                        Image(systemName: "plus")
                            .guideSymbol(size: size * 0.26, weight: .semibold)
                            .foregroundStyle(accent.onColor.opacity(0.78))
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }

    private var assetName: String? {
        switch emoji {
        case "👥":
            "IntentionGroupFilled"
        case "🌍", "🌎", "🌏":
            "IntentionChurchFilled"
        case "🙏":
            "IntentionHandsFilled"
        case "✝️", "✝", "†", "❤️", "❤", "♥️", "♥", "🕊️", "🕊":
            nil
        default:
            fallbackAssetName
        }
    }

    private var fallbackAssetName: String? {
        switch accent {
        case .mintGreen:
            "IntentionHandsFilled"
        case .skyBlue:
            "IntentionGroupFilled"
        case .purple:
            "IntentionChurchFilled"
        }
    }

    private var symbolName: String {
        switch emoji {
        case "✝️", "✝", "†":
            "cross.fill"
        case "👥":
            "person.fill"
        case "🌍", "🌎", "🌏":
            "building.columns.fill"
        case "❤️", "❤", "♥️", "♥":
            "heart.fill"
        case "🕊️", "🕊":
            "leaf.fill"
        case "🙏":
            "hands.clap.fill"
        default:
            fallbackSymbol
        }
    }

    private var fallbackSymbol: String {
        switch accent {
        case .mintGreen:
            "hands.clap.fill"
        case .skyBlue:
            "person.fill"
        case .purple:
            "building.columns.fill"
        }
    }

    private var symbolSize: CGFloat {
        if assetName != nil {
            min(22, size * 0.55)
        } else {
            size * 0.42
        }
    }
}

/// Copy for the free intention limit, shared by My prayer and the in-rosary sheet.
enum IntentionLimit {
    static var premiumNote: String {
        "Free accounts can keep \(PremiumStatus.freeIntentionLimit) intentions. Rosary Guide+ removes the limit. The Pope's monthly intention never counts."
    }
}

enum EditorRoute: Identifiable, Hashable {
    case create
    case edit(OfferIntention)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let intention): intention.id.uuidString
        }
    }
}

private enum RetentionChoice: String, CaseIterable, Identifiable {
    case indefinitely
    case untilDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .indefinitely: "Indefinitely"
        case .untilDate: "Until date"
        }
    }
}

private enum IntentionKindChoice: String, CaseIterable, Identifiable {
    case personal
    case someone
    case world

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal: "Personal"
        case .someone: "Someone else"
        case .world: "Church & world"
        }
    }

    var iconAsset: String {
        switch self {
        case .personal: "IntentionHandsFilled"
        case .someone: "IntentionGroupFilled"
        case .world: "IntentionChurchFilled"
        }
    }

    var accent: IntentionAccent {
        switch self {
        case .personal: .mintGreen
        case .someone: .skyBlue
        case .world: .purple
        }
    }

    var emoji: String {
        switch self {
        case .personal: "🙏"
        case .someone: "👥"
        case .world: "🌍"
        }
    }

    var category: IntentionCategory {
        switch self {
        case .personal: .personal
        case .someone: .someone
        case .world: .world
        }
    }

    init(category: IntentionCategory) {
        switch category {
        case .personal: self = .personal
        case .someone: self = .someone
        case .world: self = .world
        }
    }
}


private struct EditorSheetScrollMetrics: Equatable {
    var offsetY: CGFloat
    var maxOffsetY: CGFloat
}

private enum EditorSheetScrollAnchor {
    static let bottom = "intention-editor-bottom"
}

struct IntentionEditorSheet: View {
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let route: EditorRoute
    /// When creating from a Rosary, pre-select that mystery.
    var initialMystery: MysterySetKind? = nil
    var onSaved: ((OfferIntention) -> Void)? = nil
    var onDeleted: ((OfferIntention) -> Void)? = nil

    @State private var title = ""
    @State private var note = ""
    @State private var retention: RetentionChoice = .indefinitely
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var accent: IntentionAccent = .mintGreen
    @State private var emoji: String = "🙏"
    @State private var suggestOn: Set<MysterySetKind> = []
    @State private var kind: IntentionKindChoice = .personal
    @State private var makeCurrent = false
    @State private var isPapalIntention = false
    @State private var showingDeleteAlert = false
    @State private var keyboardVisible = false
    @State private var editorActionExpanded = false
    @Namespace private var editorActionNamespace
    @FocusState private var titleFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                    editorFieldSection(label: "Intention") {
                        TextField("For…", text: $title, axis: .vertical)
                            .font(AppTheme.TypeRole.body)
                            .foregroundStyle(palette.ink)
                            .lineLimit(2...5)
                            .focused($titleFieldFocused)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        GuideSectionLabel(text: "Category", color: palette.dim)
                        Picker("Category", selection: $kind) {
                            ForEach(IntentionKindChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .guideSegmentedControl()
                        .onChange(of: kind) { _, option in
                            accent = option.accent
                            emoji = option.emoji
                        }
                    }

                    editorFieldSection(label: "Notes") {
                        if isPapalIntention {
                            Text(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No notes" : note)
                                .font(AppTheme.TypeRole.themeSummary)
                                .foregroundStyle(
                                    note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? palette.dim
                                        : palette.ink
                                )
                                .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                                .accessibilityLabel("Notes (read-only)")
                        } else {
                            TextField("Optional", text: $note, axis: .vertical)
                                .font(AppTheme.TypeRole.themeSummary)
                                .foregroundStyle(palette.ink)
                                .lineLimit(3...6)
                                .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                        }
                    }

                    Toggle(isOn: $makeCurrent) {
                        Text("Set as primary intention")
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.ink)
                    }
                    .tint(palette.accent)
                    .padding(.horizontal, AppTheme.Space.lg)
                    .padding(.vertical, AppTheme.Space.md)
                    .guideCard(
                        radius: AppTheme.containerRadius,
                        fill: palette.surface,
                        stroke: true,
                        elevated: false
                    )
                    .accessibilityHint(
                        makeCurrent
                            ? "On. This intention will be selected for your next Rosary."
                            : "Off. Leave your current intention unchanged."
                    )

                    if let editingItem {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete intention")
                                .font(AppTheme.TypeRole.bodySmall(weight: .regular))
                                .foregroundStyle(palette.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppTheme.Space.lg)
                                .padding(.vertical, AppTheme.Space.lg)
                                .guideCard(
                                    radius: AppTheme.containerRadius,
                                    fill: palette.surface,
                                    stroke: false,
                                    elevated: false
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Deletes \(editingItem.title)")
                    }
                    }
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, AppTheme.Space.xl)
                    .padding(.bottom, AppTheme.Space.xxl + AppTheme.Space.sm)
                    .background(alignment: .bottom) {
                        Color.clear
                            .frame(height: 1)
                            .id(EditorSheetScrollAnchor.bottom)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onScrollGeometryChange(for: EditorSheetScrollMetrics.self) { geometry in
                    EditorSheetScrollMetrics(
                        offsetY: geometry.contentOffset.y,
                        maxOffsetY: max(0, geometry.contentSize.height - geometry.containerSize.height + geometry.contentInsets.bottom)
                    )
                } action: { oldValue, newValue in
                    guard keyboardVisible, !editorActionExpanded else { return }
                    let nearBottom = newValue.maxOffsetY - newValue.offsetY <= 28
                    let movedDown = newValue.offsetY > oldValue.offsetY + 6
                    if nearBottom && movedDown {
                        settleEditorAction(proxy)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    editorBottomAction { settleEditorAction(proxy) }
                }
            }
            .background(palette.bg)
            .navigationTitle(routeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(palette.scheme, for: .navigationBar)
            .tint(palette.accent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(AppTheme.TypeRole.callout(weight: .regular))
                        .foregroundStyle(palette.ink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                        .disabled(!canSaveIntention)
                }
            }
            .onAppear {
                hydrate()
                if case .create = route {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        titleFieldFocused = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardVisible = true
                editorActionExpanded = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardVisible = false
            }
            .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEditingItem()
                }
            } message: {
                Text("This will delete “\(editingItem?.title ?? "this intention")” from your intentions.")
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var canSaveIntention: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func settleEditorAction(_ proxy: ScrollViewProxy) {
        guard !editorActionExpanded else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            editorActionExpanded = true
            proxy.scrollTo(EditorSheetScrollAnchor.bottom, anchor: .bottom)
        }
        titleFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func editorBottomAction(onSettle: @escaping () -> Void) -> some View {
        let showCompact = keyboardVisible && !editorActionExpanded

        return HStack {
            if showCompact {
                Spacer(minLength: 0)
            }
            Button {
                if showCompact {
                    onSettle()
                } else {
                    save()
                }
            } label: {
                Group {
                    if showCompact {
                        Image(systemName: "chevron.down")
                            .guideSymbol(size: 17, weight: .semibold)
                            .foregroundStyle(palette.secondaryButtonText)
                            .frame(
                                width: AppTheme.Component.mysteryPlateActionCircle,
                                height: AppTheme.Component.mysteryPlateActionCircle
                            )
                    } else {
                        Text("Done")
                            .font(AppTheme.TypeRole.callout(weight: .semibold))
                            .foregroundStyle(palette.secondaryButtonText)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Component.pillHeight)
                    }
                }
                .background {
                    Capsule()
                        .fill(palette.secondaryButtonFill)
                        .matchedGeometryEffect(id: "editor-bottom-action-background", in: editorActionNamespace)
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
            .disabled(!showCompact && !canSaveIntention)
            .opacity(!showCompact && !canSaveIntention ? 0.45 : 1)
            .accessibilityLabel(showCompact ? "Scroll to bottom" : "Done")
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: showCompact)
        .padding(.horizontal, AppTheme.gutter)
        .padding(.top, 8)
        .padding(.bottom, AppTheme.Space.lg)
        .background(palette.bg.opacity(showCompact ? 0 : 1))
    }

    private var editingItem: OfferIntention? {
        if case .edit(let item) = route { return item }
        return nil
    }

    @ViewBuilder
    private func editorFieldSection<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            GuideSectionLabel(text: label, color: palette.dim)
            content()
                .padding(AppTheme.Space.lg)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .guideCard(
                    radius: AppTheme.containerRadius,
                    fill: palette.surface,
                    stroke: true,
                    elevated: false
                )
        }
    }

    private var editorHero: some View {
        ZStack(alignment: .bottomLeading) {
            MysteryArtworkView(set: .sorrowful, mysteryNumber: 1, kind: .heroTall)
                .frame(height: 340)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            palette.bg.opacity(0.05),
                            palette.bg.opacity(0.38),
                            palette.bg.opacity(0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("\"Carry one another's\nburdens, and in this\nway you will fulfil\nthe law of Christ.\"")
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(4)
                Text("GALATIANS 6:2")
                    .font(AppTheme.TypeRole.caption(weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(palette.faint)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 54)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type of intention")
                .font(AppTheme.TypeRole.label(weight: .medium))
                .foregroundStyle(palette.ink)

            HStack(spacing: AppTheme.Space.md) {
                ForEach(IntentionKindChoice.allCases) { option in
                    let selected = kind == option
                    Button {
                        kind = option
                        accent = option.accent
                        emoji = option.emoji
                    } label: {
                        VStack(spacing: 8) {
                            Image(option.iconAsset)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text(option.title)
                                .font(AppTheme.TypeRole.caption(weight: .medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)
                        }
                        .foregroundStyle(palette.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(selected ? palette.accentTint : palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous)
                                .strokeBorder(selected ? Color.clear : palette.selectionStroke, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTheme.TypeRole.label(weight: .semibold))
                .foregroundStyle(palette.ink)
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous)
                        .strokeBorder(palette.fieldStroke, lineWidth: 1)
                )
        }
    }

    private var retentionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep intention")
                .font(AppTheme.TypeRole.label(weight: .semibold))
                .foregroundStyle(palette.ink)
            Picker("Duration", selection: $retention) {
                ForEach(RetentionChoice.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            if retention == .untilDate {
                DatePicker(
                    "End date",
                    selection: $endDate,
                    in: Calendar.current.startOfDay(for: Date())...,
                    displayedComponents: .date
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
    }


    private var suggestOnCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Text("Mystery")
                .font(AppTheme.TypeRole.label(weight: .semibold))
                .foregroundStyle(palette.ink)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(MysterySetKind.displayOrder) { set in
                    let selected = suggestOn.contains(set)
                    Button {
                        // One mystery only — tap again to clear.
                        if selected { suggestOn.removeAll() } else { suggestOn = [set] }
                    } label: {
                        Text(set.shortName)
                            .font(AppTheme.TypeRole.label(weight: .semibold))
                            .foregroundStyle(selected ? palette.secondaryButtonText : palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                Capsule().fill(selected ? palette.secondaryButtonFill : palette.surface)
                            )
                            .overlay(
                                Capsule().strokeBorder(selected ? Color.clear : palette.selectionStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
    }

    private var routeTitle: String {
        switch route {
        case .create: "Add Intention"
        case .edit: "Edit Intention"
        }
    }

    private var expiry: Date? {
        guard retention == .untilDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: endDate)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)
    }

    private func hydrate() {
        switch route {
        case .create:
            title = ""
            note = ""
            retention = .indefinitely
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            accent = .mintGreen
            emoji = "🙏"
            kind = .personal
            // No featured (pinned) intention yet → ON so the new one becomes featured;
            // otherwise OFF so an existing featured intention stays put.
            makeCurrent = !offer.sortedIntentions.contains(where: \.isPinned)
            isPapalIntention = false
            suggestOn = Set(initialMystery.map { [$0] } ?? [])
        case .edit(let item):
            title = item.title
            note = item.note ?? ""
            accent = item.accent
            emoji = item.emoji ?? item.displayEmoji
            kind = IntentionKindChoice(category: item.category)
            makeCurrent = item.isPinned
            isPapalIntention = item.isPapal
            suggestOn = Set(item.suggestOn)
            if let expiresAt = item.expiresAt {
                retention = .untilDate
                endDate = expiresAt
            } else {
                retention = .indefinitely
            }
        }
    }

    private func save() {
        let glyph = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedEmoji = glyph.isEmpty ? "🙏" : glyph
        switch route {
        case .create:
            // Preserve an explicit Current when Make current is OFF.
            // Do not invent a pin from sortedIntentions.first — featured is pin-only.
            let priorCurrentId: UUID? = makeCurrent
                ? nil
                : offer.sortedIntentions.first(where: \.isPinned)?.id
            // nil when a free user is at the limit (entry points normally route to Premium first).
            guard let created = offer.add(
                title: title,
                note: note,
                pin: makeCurrent,
                expiresAt: expiry,
                category: kind.category,
                accent: accent,
                emoji: resolvedEmoji,
                suggestOn: Array(suggestOn).filter { MysterySetKind.displayOrder.contains($0) }
            ) else {
                dismiss()
                return
            }
            if let priorCurrentId {
                offer.setCurrent(id: priorCurrentId)
            }
            onSaved?(created)
        case .edit(var item):
            item.title = title
            // Papal notes stay as provided by the Holy Father suggestion.
            if !item.isPapal {
                item.note = note
            }
            item.expiresAt = expiry
            item.category = kind.category
            item.accent = accent
            item.emoji = resolvedEmoji
            item.suggestOn = Array(suggestOn).filter { MysterySetKind.displayOrder.contains($0) }
            item.isPinned = makeCurrent
            offer.update(item)
            if makeCurrent {
                offer.setCurrent(id: item.id)
            }
            onSaved?(item)
        }
        dismiss()
    }

    private func deleteEditingItem() {
        guard let item = editingItem else { return }
        offer.delete(id: item.id)
        onDeleted?(item)
        dismiss()
    }
}

/// Contact-style colour + emoji picker (preview, swatches with check).
/// Kept for a possible later restore — not presented while icons are hidden.
private struct IntentionIconPickerSheet: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var accent: IntentionAccent
    @Binding var emoji: String

    @State private var draftAccent: IntentionAccent = .mintGreen
    @State private var draftEmoji: String = ""
    /// Bumped to force the hidden UITextField to become first responder (shows keyboard).
    @State private var emojiFocusNonce: Int = 0

    private let horizontalPad: CGFloat = AppTheme.gutter
    private let swatchCount = CGFloat(IntentionAccent.pickerOrder.count)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    ZStack {
                        IntentionIconView(
                            accent: draftAccent,
                            emoji: draftEmoji,
                            size: 120,
                            emptyPlaceholder: "?"
                        )
                        // 1×1 field centred on the preview — cannot cover Save.
                        EmojiKeyboardField(text: $draftEmoji, focusNonce: emojiFocusNonce)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                    }
                    .padding(.top, 8)
                    .contentShape(Circle())
                    .onTapGesture { emojiFocusNonce += 1 }

                    VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                        Text("Intention colour")
                            .font(AppTheme.TypeRole.label(weight: .semibold))
                            .foregroundStyle(palette.ink)

                        GeometryReader { geo in
                            let spacing: CGFloat = 10
                            let totalSpacing = spacing * (swatchCount - 1)
                            let side = max(36, (geo.size.width - totalSpacing) / swatchCount)
                            HStack(spacing: spacing) {
                                ForEach(IntentionAccent.pickerOrder) { option in
                                    Button {
                                        draftAccent = option
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(option.color)
                                                .frame(width: side, height: side)
                                            if draftAccent == option {
                                                Circle()
                                                    .strokeBorder(palette.selectedSwatchStroke, lineWidth: 2.5)
                                                    .frame(width: side, height: side)
                                                Image(systemName: "checkmark")
                                                    .guideSymbol(size: max(12, side * 0.32), weight: .bold)
                                                    .foregroundStyle(option.onColor)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(option.title)
                                    .accessibilityAddTraits(draftAccent == option ? .isSelected : [])
                                }
                            }
                            .frame(width: geo.size.width, height: side)
                        }
                        .frame(height: AppTheme.Component.pillHeight)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalPad)
                }
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.never)
            // Sits flush above the keyboard; no filled bar behind the capsule.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SaveCapsuleButton(
                    title: "Save",
                    ink: UIColor(palette.primaryButtonFill),
                    labelColor: UIColor(palette.primaryButtonText)
                ) {
                    commitAndDismiss()
                }
                .frame(height: AppTheme.Component.pillHeight)
                .padding(.horizontal, horizontalPad)
                .padding(.top, 6)
                .padding(.bottom, 18) // ~12pt higher above the keyboard
            }
            .background(palette.bg)
            .navigationTitle("Choose an icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        commitAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel("Save icon")
                }
            }
            .onAppear {
                draftAccent = accent
                draftEmoji = emoji == "🙏" ? "" : emoji
                // Nested sheet: retry until the field's window is ready.
                for delay in [0.05, 0.3, 0.6, 1.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        emojiFocusNonce += 1
                    }
                }
            }
            .onChange(of: draftEmoji) { _, newValue in
                let next = Self.normalizedIconGlyph(newValue)
                if draftEmoji != next { draftEmoji = next }
            }
        }
    }

    private func commitAndDismiss() {
        // Drop keyboard first so SwiftUI/UIKit hit-testing is clean.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        accent = draftAccent
        let glyph = Self.normalizedIconGlyph(draftEmoji)
        emoji = glyph.isEmpty ? "🙏" : glyph
        dismiss()
    }

    /// One emoji, or up to two letters/numbers (letters capitalised). Backspace clears to "?".
    private static func normalizedIconGlyph(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let chars = Array(trimmed)
        let emojiChars = chars.filter(\.isIntentionEmojiCandidate)
        if let emoji = emojiChars.last {
            return String(emoji)
        }

        let monogram = chars.filter(\.isIntentionMonogramCandidate).prefix(2)
        return String(monogram).uppercased()
    }
}

/// UIKit button so Save still receives taps while the emoji field is first responder.
private struct SaveCapsuleButton: UIViewRepresentable {
    var title: String
    var ink: UIColor
    var labelColor: UIColor
    var action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(labelColor, for: .normal)
        button.backgroundColor = ink
        if #available(iOS 15.0, *) {
            button.configuration = .plain()
            button.configuration?.cornerStyle = .capsule
            button.configuration?.baseForegroundColor = labelColor
            button.configuration?.background.backgroundColor = ink
        }
        button.clipsToBounds = true
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        context.coordinator.action = action
        button.setTitle(title, for: .normal)
        button.setTitleColor(labelColor, for: .normal)
        button.backgroundColor = ink
        if #available(iOS 15.0, *) {
            button.configuration?.baseForegroundColor = labelColor
            button.configuration?.background.backgroundColor = ink
        }
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tap() { action() }
    }
}

/// Prefers the system emoji keyboard; autofocuses when attached to a window.
private final class EmojiPreferringTextField: UITextField {
    /// When true, prefer the emoji keyboard. Cleared once a letter/number is typed.
    var prefersEmojiKeyboard: Bool = true

    override var intrinsicContentSize: CGSize { CGSize(width: 1, height: 1) }

    override var textInputMode: UITextInputMode? {
        if prefersEmojiKeyboard {
            for mode in UITextInputMode.activeInputModes where mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.focusForEmojiEntry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.focusForEmojiEntry()
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { reloadInputViews() }
        return ok
    }

    func focusForEmojiEntry() {
        guard window != nil else { return }
        if !isFirstResponder {
            _ = becomeFirstResponder()
        } else {
            reloadInputViews()
        }
    }
}

/// UITextField that opens the keyboard via UIKit first-responder (not SwiftUI FocusState).
private struct EmojiKeyboardField: UIViewRepresentable {
    @Binding var text: String
    var focusNonce: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> EmojiPreferringTextField {
        let field = EmojiPreferringTextField()
        field.delegate = context.coordinator
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 12)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.keyboardType = .default
        field.returnKeyType = .done
        field.tintColor = .clear
        field.textColor = .clear
        field.backgroundColor = .clear
        field.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentHuggingPriority(.required, for: .vertical)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: EmojiPreferringTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text {
            field.text = text
        }
        if context.coordinator.lastFocusNonce != focusNonce {
            context.coordinator.lastFocusNonce = focusNonce
            DispatchQueue.main.async {
                field.focusForEmojiEntry()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                field.focusForEmojiEntry()
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiKeyboardField
        var lastFocusNonce: Int = -1

        init(_ parent: EmojiKeyboardField) { self.parent = parent }

        @objc func editingChanged(_ field: UITextField) {
            let value = field.text ?? ""
            parent.text = value
            if let emojiField = field as? EmojiPreferringTextField,
               value.contains(where: { $0.isIntentionMonogramCandidate }) {
                if emojiField.prefersEmojiKeyboard {
                    emojiField.prefersEmojiKeyboard = false
                    emojiField.reloadInputViews()
                }
            } else if value.isEmpty, let emojiField = field as? EmojiPreferringTextField {
                emojiField.prefersEmojiKeyboard = true
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

private extension Character {
    /// Emoji grapheme (excludes plain ASCII letters/digits).
    var isIntentionEmojiCandidate: Bool {
        if unicodeScalars.allSatisfy({ $0.properties.isEmojiPresentation || $0.properties.isEmoji }) {
            if unicodeScalars.count == 1, let s = unicodeScalars.first, s.isASCII, s.isAlphaNumeric {
                return false
            }
            return true
        }
        return unicodeScalars.contains { $0.properties.isEmoji }
            && !unicodeScalars.allSatisfy({ $0.isASCII && $0.isAlphaNumeric })
    }

    /// Single letter or number for a 1–2 character monogram.
    var isIntentionMonogramCandidate: Bool {
        unicodeScalars.count == 1 && (isLetter || isNumber)
    }
}

private extension Unicode.Scalar {
    var isAlphaNumeric: Bool {
        ("0"..."9").contains(self) || ("A"..."Z").contains(self) || ("a"..."z").contains(self)
    }
}
