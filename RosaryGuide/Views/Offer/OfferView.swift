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
    @State private var showingJourney = false
    @State private var showingMilestones = false
    /// Pushes the All intentions screen from "See all".
    @State private var showingAllIntentions = false
    /// Set when Premium opens because the free intention limit was hit.
    @State private var premiumNote: String?
    /// Banking-style privacy: when true, mask personal intention titles on the list surface.
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false
    /// Space an IntentionListRow leaves under its icon (its vertical padding).
    private static let intentionRowBottomInset: CGFloat = 10
    /// Rows shown under the Add button; more than this shows "See all".
    private static let collapsedIntentionRowLimit = 3
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
                "Prayer",
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
                    onAdd: { adoptSuggestion(item) },
                    onPin: { pinPapalSuggestion(item) }
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
            .navigationDestination(isPresented: $showingJourney) {
                PrayerJourneyView(
                    prayedDayStarts: sessionStore.completedDayStarts,
                    completedSessions: sessionStore.completedSessions,
                    completedDecades: sessionStore.completedDecades,
                    prayerTimeByDay: sessionStore.prayerTimeByDay
                )
            }
            .navigationDestination(isPresented: $showingMilestones) {
                JourneyMilestonesView(milestones: sessionStore.journeyMilestones)
            }
            .navigationDestination(isPresented: $showingAllIntentions) {
                AllIntentionsView(
                    onEdit: { editor = .edit($0) },
                    onPray: { prayWith($0) }
                )
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
                CollapsingTitleSpacer(height: CollapsingTitleMetrics.spacerHeight(gapBelowTitle: CollapsingTitleMetrics.firstComponentGap))

                // Full-bleed illustration: outside page gutter so container is edge-to-edge;
                // image is scaledToFit inside a taller canvas so no source edge is clipped.
                emptyHandsIllustration

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
                        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
                            GuideSectionLabel(text: "Holy Father’s intention", prominence: .strong)
                                .accessibilityAddTraits(.isHeader)
                            EmptyPapalIntentionCard(
                                monthLine: papalEmptyMonthLine(for: papalSuggestion)
                            ) {
                                papalDetail = papalSuggestion
                            }
                        }
                    }

                    if PremiumStatus.isPremium {
                        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                            GuideSectionDivider()
                                .padding(.horizontal, -AppTheme.gutter)
                            milestonesSection
                        }
                    } else {
                        prayerJourneysSection
                            // sectionGap above (the stack already adds Space.lg).
                            .padding(.top, AppTheme.sectionGap - AppTheme.Space.lg)
                    }
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
                    .multilineTextAlignment(.center)
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
                .multilineTextAlignment(.center)
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
    private var hasMoreIntentionRows: Bool {
        secondaryIntentions.count > Self.collapsedIntentionRowLimit
    }
    private var visibleSecondaryIntentions: [OfferIntention] {
        Array(secondaryIntentions.prefix(Self.collapsedIntentionRowLimit))
    }
    /// Visible space under the last list row's icon, subtracted so the Prayer
    /// journeys gap reads as sectionGap.
    private var intentionListBottomInset: CGFloat {
        secondaryIntentions.isEmpty ? 0 : Self.intentionRowBottomInset
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
            IntentionPrivacyGlyph(hidden: hideIntentionText)
                .foregroundStyle(palette.ink)
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
    /// Plain text action using the shared underlined label.
    private var seeAllIntentionsButton: some View {
        Button {
            showingAllIntentions = true
        } label: {
            GuideTextButtonLabel(title: "View all \(offer.sortedIntentions.count) intentions")
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("See all intentions")
    }

    /// "Prayer journeys" section: title, sectionTitleGap, then the Rosary Guide+ card.
    /// Hidden for Rosary Guide+ users (`PremiumStatus.isPremium`).
    private var prayerJourneysSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "Prayer journeys", prominence: .strong)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            PremiumUpsellCard { showingPremium = true }
                .padding(.top, AppTheme.sectionTitleGap)
        }
    }

    /// "Your intentions" section title. The right slot keeps the hide/show intentions
    /// toggle; "See all" lives at the bottom of the visible list.
    private var intentionsSectionHeader: some View {
        GuideSectionLabel(text: "Your intentions", prominence: .strong)
            .accessibilityAddTraits(.isHeader)
            .padding(.trailing, AppTheme.Accessibility.minHitTarget * 2 + AppTheme.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Controls retain 44pt tap areas without adding height above the label.
            .overlay(alignment: .trailing) {
                HStack(spacing: AppTheme.Space.sm) {
                    titlePrivacyButton

                    Button(action: startAddingIntention) {
                        Image(systemName: "plus")
                            .guideSymbol(size: 22, weight: .regular)
                            .foregroundStyle(palette.ink)
                            .frame(
                                width: AppTheme.Accessibility.minHitTarget,
                                height: AppTheme.Accessibility.minHitTarget
                            )
                    }
                    .buttonStyle(.plain)
                    .guidePressable()
                    .accessibilityLabel("Add an intention")
                }
            }
    }

    private var rhythmPrayerDays: Set<TimeInterval> {
        sessionStore.completedDayStarts.union(sessionStore.completedDecades.map {
            Calendar.current.startOfDay(for: $0.completedAt).timeIntervalSince1970
        })
    }

    private var weeklyCompletedRosaryCount: Int {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }
        return sessionStore.completedSessions.filter { week.contains($0.completedAt) }.count
    }

    private func openJourney() {
        if PremiumStatus.isPremium {
            showingJourney = true
        } else {
            premiumNote = "Prayer rhythm is included with Rosary Guide+. It keeps a record of your prayer rhythm, history and milestones."
            showingPremium = true
        }
    }

    private var milestonesSection: some View {
        let progress = sessionStore.journeyMilestones
        return VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Milestones", prominence: .strong)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: AppTheme.Space.sm) {
                ForEach(progress.preview) { item in
                    JourneyMilestoneCard(item: item)
                }
            }

            Button {
                showingMilestones = true
            } label: {
                GuideTextButtonLabel(title: "View all milestones")
            }
            .buttonStyle(.plain)
            .guidePressable()
            .padding(.top, -AppTheme.Space.md)
        }
    }

    private var intentionList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    CollapsingTitleSpacer(height: CollapsingTitleMetrics.firstComponentSpacerHeight)

                    Button {
                        openJourney()
                    } label: {
                        MyPrayerJourneySummaryCard(
                            rhythm: PrayerRhythm(prayedDayStarts: rhythmPrayerDays),
                            prayedDayStarts: rhythmPrayerDays,
                            rosariesThisWeek: weeklyCompletedRosaryCount,
                            isLocked: !PremiumStatus.isPremium
                        )
                    }
                    .buttonStyle(JourneyCardButtonStyle())
                    .accessibilityHint(PremiumStatus.isPremium ? "Opens your prayer journey" : "Rosary Guide Plus is required")

                    syncWarning
                        .padding(.top, AppTheme.Space.md)
                        .padding(.horizontal, AppTheme.gutter)
                }

                GuideSectionBoundary()

                VStack(alignment: .leading, spacing: 0) {
                    intentionsSectionHeader
                        .guideNavList(pageGutter: AppTheme.gutter)

                    if let currentIntention {
                        NextRosaryIntentionCard(
                            intention: currentIntention,
                            hideText: hideIntentionText,
                            onOpen: { intentionDetail = currentIntention },
                            onPray: { prayWith(currentIntention) },
                            onPin: { offer.togglePin(id: currentIntention.id) },
                            onEdit: { editor = .edit(currentIntention) },
                            onDelete: { offer.delete(id: currentIntention.id) },
                            allowsPin: true
                        )
                        .guideNavList(pageGutter: AppTheme.gutter)
                        .padding(.top, AppTheme.sectionTitleGap)
                    }

                    VStack(spacing: 0) {
                        ForEach(visibleSecondaryIntentions) { item in
                            MyPrayerIntentionRow(
                                intention: item,
                                hideText: hideIntentionText,
                                allowsPin: true,
                                onPin: { offer.togglePin(id: item.id) },
                                onEdit: { editor = .edit(item) },
                                onDelete: { offer.delete(id: item.id) },
                                onPray: { prayWith(item) }
                            )
                            .padding(.bottom, item.id == visibleSecondaryIntentions.last?.id && !hasMoreIntentionRows
                                     ? -AppTheme.Space.sm : 0)

                            if item.id != visibleSecondaryIntentions.last?.id {
                                Hairline()
                                    .padding(.leading, 62)
                            }
                        }
                    }
                    .guideNavList(pageGutter: AppTheme.gutter)
                    .padding(.top, currentIntention == nil ? AppTheme.Space.md : AppTheme.Space.sm)

                    if hasMoreIntentionRows {
                        seeAllIntentionsButton
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .guideNavList(pageGutter: AppTheme.gutter)
                            .padding(.top, AppTheme.Space.xs)
                    }


                }

                if let papalSuggestion = visiblePapalSuggestion {
                    GuideSectionBoundary()
                    GuideSectionLabel(text: "Holy Father’s intention", prominence: .strong)
                        .accessibilityAddTraits(.isHeader)
                    PapalMonthCard(
                        item: papalSuggestion,
                        isAdded: hasAdoptedSuggestion(papalSuggestion),
                        onOpen: { papalDetail = papalSuggestion },
                        onAdd: { adoptSuggestion(papalSuggestion) },
                        onPin: { pinPapalSuggestion(papalSuggestion) }
                    )
                    .guideNavList(pageGutter: AppTheme.gutter)
                    .padding(.top, AppTheme.sectionTitleGap)
                }

                if PremiumStatus.isPremium {
                    GuideSectionBoundary()
                    milestonesSection
                } else {
                    prayerJourneysSection
                        // Visible sectionGap: intention rows carry their own bottom inset.
                        .padding(.top, AppTheme.sectionGap - intentionListBottomInset)
                }
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
                pin: papal && offer.sortedIntentions.isEmpty,
                sourceId: papal ? item.id : nil,
                category: papal ? .world : .personal,
                accent: papal ? .purple : .mintGreen,
                emoji: papal ? "✝️" : "❤️"
            )
            // Papal: add quietly. Others: open editor so they can refine.
            if !papal, let created = offer.sortedIntentions.first(where: {
                $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                editor = .edit(created)
            }
        }
    }

    private func pinPapalSuggestion(_ item: SuggestedIntention) {
        adoptSuggestion(item)
        if let saved = offer.sortedIntentions.first(where: {
            $0.sourceId == item.id
                || $0.title.compare(item.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }), !saved.isPinned {
            offer.togglePin(id: saved.id)
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

private struct MyPrayerJourneySummaryCard: View {
    @Environment(\.palette) private var palette
    let rhythm: PrayerRhythm
    let prayedDayStarts: Set<TimeInterval>
    let rosariesThisWeek: Int
    var isLocked: Bool = false

    private var rhythmHeadline: String {
        if rhythm.weekRun >= 2, rhythm.prayedDaysThisWeek > 0 {
            return "\(rhythm.weekRun) weeks of regular prayer"
        }
        let days = rhythm.prayedDaysThisWeek
        if days == 0 { return "Begin with a prayer this week" }
        return days == 1 ? "1 day in prayer this week" : "\(days) days in prayer this week"
    }

    private var rosaryCaption: String {
        let noun = rosariesThisWeek == 1 ? "Rosary" : "Rosaries"
        return "\(rosariesThisWeek) \(noun) offered this week"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            weeklyDots
                .padding(.vertical, AppTheme.Space.sm)

            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                    Text(rhythmHeadline)
                        .font(AppTheme.TypeRole.body(weight: .medium))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .guideSymbol(size: 13, weight: .regular)
                            .foregroundStyle(palette.dim)
                            .accessibilityHidden(true)
                    }
                }

                Text(rosaryCaption)
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your prayer rhythm, \(rhythmHeadline), \(rosaryCaption), \(rhythm.prayedDaysThisWeek) prayer days this week")
    }

    private var weeklyDots: some View {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return HStack(spacing: AppTheme.Space.sm) {
            ForEach(0..<7, id: \.self) { index in
                let day = calendar.date(byAdding: .day, value: index, to: start) ?? start
                let prayed = prayedDayStarts.contains(calendar.startOfDay(for: day).timeIntervalSince1970)
                VStack(spacing: AppTheme.Space.sm) {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[calendar.component(.weekday, from: day) - 1])
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(calendar.isDateInToday(day) ? palette.ink : palette.dim)
                    Circle()
                        .fill(prayed ? palette.accent : palette.hair)
                        .frame(width: 14, height: 14)
                        .overlay {
                            if calendar.isDateInToday(day) {
                                Circle()
                                    .stroke(palette.accent, lineWidth: 1)
                                    .padding(-3)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct NextRosaryIntentionCard: View {
    @Environment(\.palette) private var palette
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
                Text("Your next Rosary")
                    .font(AppTheme.TypeRole.caption(weight: .medium))
                    .foregroundStyle(palette.textSecondary)

                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    IntentionIconView(
                        accent: intention.accent,
                        emoji: intention.displayEmoji,
                        size: 52,
                        usesPopePortrait: intention.isPapal
                    )

                    Text(displayTitle)
                        .font(AppTheme.TypeRole.body(weight: .regular))
                        .foregroundStyle(titleColor)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                }

                Color.clear
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .frame(height: AppTheme.Component.pillHeight)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.Space.lg)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .guidePressable()
        .overlay(alignment: .topTrailing) {
            OverflowMenuButton(
                isPinned: intention.isPinned,
                allowsPin: allowsPin,
                allowsEdit: true,
                onPin: onPin,
                onEdit: onEdit,
                onDelete: { showingDeleteAlert = true }
            )
            .padding(.top, AppTheme.Space.md)
            .padding(.trailing, AppTheme.Space.md)
        }
        .overlay(alignment: .bottom) {
            PillButton(title: "Offer a Rosary", filled: false, action: onPray)
                .padding(.horizontal, AppTheme.Space.lg)
                .padding(.bottom, AppTheme.Space.lg)
        }
        .alert("Delete Intention?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will delete “\(displayTitle)” from your intentions.")
        }
        .accessibilityLabel(IntentionPrivacy.hides(intention, hidden: hideText) ? "Open hidden intention" : "Open \(intention.title)")
    }
}

private struct MyPrayerIntentionRow: View {
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
            MyPrayerIntentionRowLabel(intention: intention, hideText: hideText)
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

private struct MyPrayerIntentionRowLabel: View {
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
        HStack(alignment: .center, spacing: AppTheme.Space.md) {
            IntentionIconView(
                accent: intention.accent,
                emoji: intention.displayEmoji,
                size: 44,
                usesPopePortrait: intention.isPapal
            )

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(displayTitle)
                    .font(AppTheme.TypeRole.bodySmall(weight: .regular))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                Text(metaLabel)
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
                    .lineLimit(1)
            }
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppTheme.Space.sm)
        .contentShape(Rectangle())
        .accessibilityLabel(IntentionPrivacy.hides(intention, hidden: hideText) ? "Hidden, \(metaLabel)" : "\(intention.title), \(metaLabel)")
    }

    private var metaLabel: String {
        guard let date = intention.lastCarriedAt else {
            return intention.createdAt.formatted(.dateTime.month(.wide).year())
        }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Last prayed today" }
        if calendar.isDateInYesterday(date) { return "Last prayed yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                            to: calendar.startOfDay(for: Date())).day ?? 0
        if (2...6).contains(days) { return "Last prayed \(days) days ago" }
        return "Last prayed \(date.formatted(.dateTime.day().month(.abbreviated).year()))"
    }
}

private struct MyPrayerPapalIntentionCard: View {
    @Environment(\.palette) private var palette
    let item: SuggestedIntention
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                Image("PopeLeo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("POPE’S INTENTION · \(monthOnly.uppercased())")
                        .font(AppTheme.TypeRole.sectionLabel)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)

                    Text(item.title)
                        .font(AppTheme.TypeRole.body(weight: .regular))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "ellipsis")
                    .guideSymbol(size: 18, weight: .medium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.Space.md)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Pope’s intention, \(item.title)")
    }

    private var monthOnly: String {
        guard let monthLabel = item.monthLabel?.split(separator: " ").first else {
            return Date().formatted(.dateTime.month(.wide))
        }
        return String(monthLabel)
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
                    .multilineTextAlignment(.center)
                    .frame(height: AppTheme.Component.pillHeight)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.Space.lg)
            // Flat surface like every card on My prayer (no border or shadow).
            .guideRowGroup()
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
    let onPin: () -> Void

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
                .padding(.trailing, AppTheme.Space.lg + (isAdded ? AppTheme.Accessibility.minHitTarget : 0))
                .padding(.vertical, AppTheme.Space.md)
            }
            .frame(minHeight: 96)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .guidePressable()
        .overlay(alignment: .topTrailing) {
            if isAdded {
                Menu {
                    Button(action: onPin) { Label("Pin", systemImage: "pin.fill") }
                } label: {
                    Image(systemName: "ellipsis")
                        .guideSymbol(size: 18, weight: .regular)
                        .foregroundStyle(palette.dim)
                        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                }
                .padding(AppTheme.Space.sm)
                .accessibilityLabel("Papal intention options")
            }
        }
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
    @Environment(\.dismiss) private var dismiss
    let item: SuggestedIntention
    let isAdded: Bool
    let onAdd: () -> Void
    let onPin: () -> Void
    @State private var didAdd = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                hero
                heroCopy

                if let note = item.note {
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
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

                Button {
                    if added {
                        dismiss()
                    } else {
                        onAdd()
                        didAdd = true
                    }
                } label: {
                    Text(added ? "Done" : "Add to my intentions")
                        .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                        .foregroundStyle(added ? palette.secondaryButtonText : palette.primaryButtonText)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .frame(height: AppTheme.Component.pillHeight)
                        .background(added ? palette.secondaryButtonFill : palette.primaryButtonFill, in: Capsule())
                }
                .buttonStyle(.plain)

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
        .toolbar {
            if added {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onPin()
                    } label: { Label("Pin", systemImage: "pin") }
                }
            }
        }
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
/// Eye (shown) or closed eye (hidden) for the hide intentions toggle; takes the
/// caller's foreground style.
private struct IntentionPrivacyGlyph: View {
    let hidden: Bool

    var body: some View {
        if hidden {
            ClosedEyeIcon()
        } else {
            Image(systemName: "eye")
                .guideSymbol(size: 17, weight: .medium)
        }
    }
}

private struct ClosedEyeIcon: View {
    var body: some View {
        ZStack {
            ClosedEyeLid()
                .stroke(
                    .foreground,
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )

            ClosedEyeLashes()
                .stroke(
                    .foreground,
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

/// Every intention (featured first, via OfferStore's sort) as list rows, pushed from
/// My prayer's "See all", with the standard level-2 compact bar. Rows behave exactly as on My prayer: open detail, menu to
/// feature, edit or delete. Pops back if the list empties.
private struct AllIntentionsView: View {
    @Environment(OfferStore.self) private var offer
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    let onEdit: (OfferIntention) -> Void
    let onPray: (OfferIntention) -> Void

    private var hideText: Bool { settings.hideIntentionText }

    /// Featured/current card only when something is explicitly pinned (same as My prayer).
    private var featured: OfferIntention? {
        offer.sortedIntentions.first(where: \.isPinned)
    }

    /// Everything except the featured card, so it isn't listed twice.
    private var listItems: [OfferIntention] {
        guard let featured else { return offer.sortedIntentions }
        return offer.sortedIntentions.filter { $0.id != featured.id }
    }

    @State private var detail: OfferIntention?

    var body: some View {
        let items = listItems
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if let featured {
                    CurrentIntentionHero(
                        intention: featured,
                        hideText: hideText,
                        onOpen: { detail = featured },
                        onPray: { onPray(featured) },
                        onPin: { offer.togglePin(id: featured.id) },
                        onEdit: { onEdit(featured) },
                        onDelete: { offer.delete(id: featured.id) },
                        allowsPin: true
                    )
                }

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        IntentionSecondaryRow(
                            intention: item,
                            hideText: hideText,
                            allowsPin: true,
                            onPin: { offer.togglePin(id: item.id) },
                            onEdit: { onEdit(item) },
                            onDelete: { offer.delete(id: item.id) },
                            onPray: { onPray(item) }
                        )

                        if item.id != items.last?.id {
                            Hairline()
                                .padding(.leading, 62)
                        }
                    }
                }
                // Same gap as featured → Pope's / Add on My prayer.
                .padding(.top, featured == nil ? 0 : AppTheme.Space.md)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, 108)
        }
        .background(palette.bg)
        // Standard level-2 chrome: native inline title, system back button and edge swipe.
        .guideDetailChrome("All intentions")
        .toolbar {
            // Hide/show intention text: same setting as My prayer.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    settings.hideIntentionText.toggle()
                } label: {
                    IntentionPrivacyGlyph(hidden: hideText)
                        .foregroundStyle(palette.ink)
                }
                // Ink, like the native back chevron beside it (bar buttons
                // otherwise take the accent tint).
                .tint(palette.ink)
                .accessibilityLabel(hideText ? "Show intentions" : "Hide intentions")
            }
        }
        .navigationDestination(item: $detail) { item in
            IntentionDetailView(
                intention: item,
                hideText: hideText,
                onPin: { offer.togglePin(id: item.id) },
                onEdit: { onEdit(item); detail = nil },
                onDelete: { offer.delete(id: item.id); detail = nil },
                onPray: { onPray(item) }
            )
        }
        .onChange(of: offer.sortedIntentions.isEmpty) { _, isEmpty in
            if isEmpty { dismiss() }
        }
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
            VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                detailHeader
                    .padding(.top, 18)

                statsCard

                if shouldShowNotesField {
                    notesField
                }

                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onPray) {
                        Text("Offer a Rosary")
                            .font(AppTheme.TypeRole.callout(weight: .semibold))
                            .foregroundStyle(palette.secondaryButtonText)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .frame(height: AppTheme.Component.pillHeight)
                            .background(palette.secondaryButtonFill, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    GuideSectionBoundary()

                    detailSection
                }
                .padding(.top, shouldShowNotesField ? AppTheme.Space.lg - AppTheme.Space.md : 0)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
        }
        .background(palette.bg)
        .toolbar {
            if intention.isPapal {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onPin) {
                        Label(intention.isPinned ? "Unpin" : "Pin", systemImage: intention.isPinned ? "pin.slash" : "pin")
                    }
                }
            }
            if !intention.isPapal {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", action: onEdit)
                        .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                        .foregroundStyle(palette.accent)
                }
            }
        }
        .guideDetailChrome(detailNavigationTitle)
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
        // Keep the intention name vertically centred beside its avatar.
        HStack(alignment: .center, spacing: AppTheme.Space.lg) {
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
                        .foregroundStyle(palette.textSecondary)
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
                .guideSymbol(size: 18, weight: .regular)
                .foregroundStyle(palette.dim)
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
                        IntentionLineGlyph(glyph: AppTheme.IntentionIcon.glyph(for: emoji, accent: accent))
                            .stroke(style: AppTheme.LineIcon.strokeStyle)
                            .frame(width: symbolSize, height: symbolSize)
                            .foregroundStyle(accent.onColor)
                    } else if let emptyPlaceholder, !emptyPlaceholder.isEmpty {
                        Image(systemName: "plus")
                            .guideSymbol(size: size * 0.26, weight: .regular)
                            .foregroundStyle(accent.onColor.opacity(0.78))
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }

    private var symbolSize: CGFloat {
        size * AppTheme.LineIcon.glyphRatio
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

    var glyph: AppTheme.IntentionIcon.Glyph {
        switch self {
        case .personal: .heart
        case .someone: .people
        case .world: .church
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
        case .personal: "❤️"
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
    @State private var emoji: String = "❤️"
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
                        TextField("For my family", text: $title, axis: .vertical)
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
                            .multilineTextAlignment(.center)
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
            GuideSectionLabel(text: "Type of intention", prominence: .strong)

            HStack(spacing: AppTheme.Space.md) {
                ForEach(IntentionKindChoice.allCases) { option in
                    let selected = kind == option
                    Button {
                        kind = option
                        accent = option.accent
                        emoji = option.emoji
                    } label: {
                        VStack(spacing: 8) {
                            IntentionLineGlyph(glyph: option.glyph)
                                .stroke(style: AppTheme.LineIcon.strokeStyle)
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
            GuideSectionLabel(text: label, prominence: .strong)
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
            GuideSectionLabel(text: "Keep intention", prominence: .strong)
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
            GuideSectionLabel(text: "Mystery", prominence: .strong)

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
            emoji = "❤️"
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
        let resolvedEmoji = glyph.isEmpty ? "❤️" : glyph
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
                        GuideSectionLabel(text: "Intention colour", prominence: .strong)

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
                        .multilineTextAlignment(.center)
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
                .multilineTextAlignment(.center)
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
                draftEmoji = emoji == "❤️" ? "" : emoji
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
        emoji = glyph.isEmpty ? "❤️" : glyph
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

// MARK: - Prayer Journey

private struct JourneyCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.palette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .fill(palette.ink.opacity(configuration.isPressed ? 0.06 : 0))
            }
            .animation(reduceMotion ? nil : MotionTokens.press, value: configuration.isPressed)
    }
}

private struct PrayerJourneyView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.palette) private var palette
    @State private var selectedTab: JourneyTab = .overview
    @State private var visibleMonth: Date = Date()

    var prayedDayStarts: Set<TimeInterval>
    var completedSessions: [CompletedPrayerSession]
    var completedDecades: [CompletedDecadeSession]
    var prayerTimeByDay: [String: TimeInterval]

    private var partialDayStarts: Set<TimeInterval> {
        let calendar = Calendar.current
        return Set(completedDecades.map { calendar.startOfDay(for: $0.completedAt).timeIntervalSince1970 })
    }
    private var rhythm: PrayerRhythm { PrayerRhythm(prayedDayStarts: prayedDayStarts.union(partialDayStarts)) }
    private var month: JourneyMonth { JourneyMonth(prayedDayStarts: prayedDayStarts, partialDayStarts: partialDayStarts, now: visibleMonth) }
    private var monthSessions: [CompletedPrayerSession] {
        let interval = Calendar.current.dateInterval(of: .month, for: visibleMonth)
        return completedSessions.filter { session in
            guard let interval else { return false }
            return interval.contains(session.completedAt)
        }
    }
    private var legacyCompletedRosaryDays: Set<TimeInterval> {
        let calendar = Calendar.current
        let sessionDays = Set(completedSessions.map { calendar.startOfDay(for: $0.completedAt).timeIntervalSince1970 })
        return prayedDayStarts.filter { !sessionDays.contains($0) }
    }
    private var totalRosaries: Int { completedSessions.count + legacyCompletedRosaryDays.count }
    private var monthRosaries: Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth) else { return monthSessions.count }
        let legacyInMonth = legacyCompletedRosaryDays.filter { interval.contains(Date(timeIntervalSince1970: $0)) }.count
        return monthSessions.count + legacyInMonth
    }
    private var monthDecades: [CompletedDecadeSession] {
        let interval = Calendar.current.dateInterval(of: .month, for: visibleMonth)
        return completedDecades.filter { decade in
            guard let interval else { return false }
            return interval.contains(decade.completedAt)
        }
    }
    private var monthDecadeCount: Int {
        // Finishing a Rosary removes its partial-decade records, so they count once here.
        monthRosaries * 5 + monthDecades.count
    }
    private var totalDuration: TimeInterval {
        prayerTimeByDay.values.reduce(0) { $0 + max(0, $1) }
    }
    private var monthDuration: TimeInterval {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth) else { return 0 }
        return prayerTimeByDay.reduce(0) { total, entry in
            guard let date = SyncedProgress.date(forDayKey: entry.key), interval.contains(date) else { return total }
            return total + max(0, entry.value)
        }
    }
    private var firstPrayerDate: Date? {
        let sessionDate = completedSessions.map(\.completedAt).min()
        let legacyDate = prayedDayStarts.min().map { Date(timeIntervalSince1970: $0) }
        switch (sessionDate, legacyDate) {
        case let (session?, legacy?): return min(session, legacy)
        case let (session?, nil): return session
        case let (nil, legacy?): return legacy
        case (nil, nil): return nil
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                tabPicker
                switch selectedTab {
                case .overview:
                    monthCalendar
                        .padding(.top, AppTheme.Space.lg)
                case .history:
                    history
                        .padding(.top, AppTheme.Space.lg)
                }
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.tabBarContentClearance + AppTheme.Space.xs)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .guideDetailChrome("Prayer rhythm")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tabPicker: some View {
        Picker("Journey view", selection: $selectedTab) {
            ForEach(JourneyTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .guideSegmentedControl()
    }

    private var rhythmSummary: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.md) {
            Image(systemName: "chart.bar.fill")
                .guideSymbol(size: 28, weight: .semibold)
                .foregroundStyle(palette.accent)
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text("Prayer rhythm")
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.textSecondary)
                Text(rhythmTitle)
                    .font(AppTheme.TypeRole.body(weight: .regular))
                    .foregroundStyle(palette.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var monthCalendar: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack {
                Button {
                    shiftJourneyMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .guideSymbol(size: 14, weight: .semibold)
                        .foregroundStyle(palette.ink)
                        .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                }
                .buttonStyle(.plain)
                .guideHitTarget()
                .accessibilityLabel("Previous month")

                Spacer(minLength: 0)

                Text(month.title)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.ink)

                Spacer(minLength: 0)

                Button {
                    shiftJourneyMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .guideSymbol(size: 14, weight: .semibold)
                        .foregroundStyle(palette.ink)
                        .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                }
                .buttonStyle(.plain)
                .guideHitTarget()
                .accessibilityLabel("Next month")
            }

            VStack(spacing: AppTheme.Space.md) {
                HStack {
                    ForEach(month.weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(AppTheme.TypeRole.caption(weight: .medium))
                            .foregroundStyle(palette.dim)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(Array(month.weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: AppTheme.Space.sm) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            JourneyCalendarCell(day: day)
                        }
                    }
                }
            }

            HStack(spacing: AppTheme.Space.lg) {
                JourneyLegendDot(title: "Completed", style: .prayed)
                JourneyLegendDot(title: "Partial", style: .partial)
            }
            .padding(.top, AppTheme.Space.xs)

            Hairline()
                .padding(.top, AppTheme.Space.xs)

            HStack(spacing: 0) {
                JourneyInlineStat(value: "\(monthRosaries)", label: monthRosaries == 1 ? "Rosary" : "Rosaries")
                JourneyMetricDivider(height: AppTheme.Accessibility.minHitTarget + AppTheme.Space.xs)
                JourneyInlineStat(value: "\(monthDecadeCount)", label: monthDecadeCount == 1 ? "Decade" : "Decades")
                JourneyMetricDivider(height: AppTheme.Accessibility.minHitTarget + AppTheme.Space.xs)
                JourneyInlineStat(value: Self.durationText(monthDuration), label: "Prayer time")
            }
            .padding(.top, AppTheme.Space.xs)
        }
        .padding(AppTheme.Space.lg)
        .guideCard(fill: palette.surface)
    }

    private func shiftJourneyMonth(_ delta: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: delta, to: visibleMonth) else { return }
        withAnimation(MotionTokens.selection) {
            visibleMonth = nextMonth
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            if groupedHistoryRows.isEmpty {
                Text("Your completed Rosaries and decades will appear here.")
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Space.lg)
                    .guideCard(fill: palette.surface)
            } else {
                ForEach(groupedHistoryRows) { group in
                    VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                        GuideSectionLabel(text: group.title, prominence: .strong)
                            .accessibilityAddTraits(.isHeader)

                        VStack(spacing: AppTheme.Space.sm) {
                            ForEach(group.rows) { row in
                                JourneyHistoryRow(row: row)
                            }
                        }
                    }
                }
            }

            if let startDate = historyStartDate {
                VStack(spacing: AppTheme.Space.xs) {
                    Text("Your prayer history starts here")
                    Text(Self.footerFormatter.string(from: startDate))
                }
                .font(AppTheme.TypeRole.caption())
                .foregroundStyle(palette.dim)
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Space.sm)
            }
        }
    }

    private var historyRows: [JourneyHistoryRow.Model] {
        let recorded = completedSessions.map { session in
            JourneyHistoryRow.Model(date: session.completedAt, mystery: session.mysterySet, duration: session.duration, intentionTitle: session.intentionTitle, kind: .rosary)
        }
        let decades = completedDecades.map { decade in
            JourneyHistoryRow.Model(date: decade.completedAt, mystery: decade.mysterySet, duration: decade.duration, intentionTitle: decade.intentionTitle, kind: .decade(decade.decadeNumber))
        }
        let recordedDays = Set(recorded.map { Calendar.current.startOfDay(for: $0.date).timeIntervalSince1970 })
        let legacy = prayedDayStarts
            .filter { !recordedDays.contains($0) }
            .map { JourneyHistoryRow.Model(date: Date(timeIntervalSince1970: $0), mystery: nil, duration: nil, intentionTitle: nil, kind: .rosary) }
        return (recorded + decades + legacy).sorted { $0.date > $1.date }
    }

    private var filteredHistoryRows: [JourneyHistoryRow.Model] {
        historyRows
    }

    private var groupedHistoryRows: [JourneyHistoryGroup] {
        let grouped = Dictionary(grouping: filteredHistoryRows) { row in
            JourneyHistoryPeriod(date: row.date)
        }
        return grouped
            .map { JourneyHistoryGroup(period: $0.key, rows: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.period.sortDate > $1.period.sortDate }
    }

    private var historyStartDate: Date? {
        historyRows.map(\.date).min()
    }

    private var rhythmTitle: String {
        let unit: String
        switch rhythm.unit {
        case .day:
            unit = rhythm.bigNumber == 1 ? "day" : "days"
        case .week:
            unit = rhythm.bigNumber == 1 ? "week" : "weeks"
        }
        guard rhythm.bigNumber > 0 else { return "Start your prayer rhythm" }
        return "\(rhythm.bigNumber) \(unit) of prayer"
    }

    private static func durationParts(_ duration: TimeInterval) -> (value: String, unit: String) {
        guard duration > 0 else { return ("—", "") }
        let minutes = max(1, Int((duration / 60).rounded()))
        if minutes < 60 { return ("\(minutes)", minutes == 1 ? "min" : "mins") }
        let hours = minutes / 60
        if hours < 24 { return ("\(hours)", hours == 1 ? "hour" : "hours") }
        let days = hours / 24
        if days < 7 { return ("\(days)", days == 1 ? "day" : "days") }
        let weeks = days / 7
        if weeks < 4 { return ("\(weeks)", weeks == 1 ? "week" : "weeks") }
        let months = days / 30
        if months < 12 { return ("\(max(1, months))", max(1, months) == 1 ? "month" : "months") }
        let years = days / 365
        return ("\(max(1, years))", max(1, years) == 1 ? "year" : "years")
    }

    private static func durationText(_ duration: TimeInterval) -> String {
        let parts = durationParts(duration)
        guard !parts.unit.isEmpty else { return parts.value }
        return "\(parts.value) \(parts.unit)"
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter
    }()

    private static let footerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter
    }()
}

private enum JourneyTab: String, CaseIterable, Identifiable {
    case overview
    case history
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: "Overview"
        case .history: "History"
        }
    }
}

private struct JourneyHistoryGroup: Identifiable {
    var period: JourneyHistoryPeriod
    var rows: [JourneyHistoryRow.Model]

    var id: String { period.id }
    var title: String { period.title }
}

private struct JourneyHistoryPeriod: Hashable {
    var id: String
    var title: String
    var sortDate: Date

    init(date: Date, calendar: Calendar = .current, now: Date = Date()) {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)
        let thisMonth = calendar.dateInterval(of: .month, for: now)
        let lastMonthStart = thisMonth.flatMap { calendar.date(byAdding: .month, value: -1, to: $0.start) }
        let lastMonth = lastMonthStart.flatMap { calendar.dateInterval(of: .month, for: $0) }

        if day == today {
            id = "today"
            title = "Today"
            sortDate = today
        } else if day == yesterday {
            id = "yesterday"
            title = "Yesterday"
            sortDate = yesterday
        } else if let thisWeek, thisWeek.contains(date) {
            id = "this-week"
            title = "This week"
            sortDate = thisWeek.start
        } else if let thisMonth, thisMonth.contains(date) {
            id = "this-month"
            title = "This month"
            sortDate = thisMonth.start
        } else if let lastMonth, lastMonth.contains(date) {
            id = "last-month"
            title = "Last month"
            sortDate = lastMonth.start
        } else {
            let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? day
            let currentMonthStart = thisMonth?.start ?? today
            let monthDelta = max(2, calendar.dateComponents([.month], from: monthStart, to: currentMonthStart).month ?? 2)
            id = "month-\(monthStart.timeIntervalSince1970)"
            title = monthDelta == 1 ? "1 month ago" : "\(monthDelta) months ago"
            sortDate = monthStart
        }
    }
}

private struct JourneyMonth {
    struct Day: Hashable {
        var number: Int
        var date: Date
        var prayed: Bool
        var partial: Bool
        var isToday: Bool
        var isFuture: Bool
    }

    var title: String
    var prayedDays: Int
    var partialDays: Int
    var weekdaySymbols: [String]
    var weeks: [[Day?]]

    init(prayedDayStarts: Set<TimeInterval>, partialDayStarts: Set<TimeInterval> = [], now: Date = Date(), calendar: Calendar = .current) {
        let prayedStarts = Set(prayedDayStarts.map { calendar.startOfDay(for: Date(timeIntervalSince1970: $0)).timeIntervalSince1970 })
        let partialStarts = Set(partialDayStarts.map { calendar.startOfDay(for: Date(timeIntervalSince1970: $0)).timeIntervalSince1970 })
        let today = calendar.startOfDay(for: Date())
        title = now.formatted(.dateTime.month(.wide).year())

        var symbols = calendar.shortStandaloneWeekdaySymbols
        let shift = max(0, calendar.firstWeekday - 1)
        if shift > 0 { symbols = Array(symbols.dropFirst(shift) + symbols.prefix(shift)) }
        weekdaySymbols = symbols.map { String($0.prefix(1)).uppercased() }

        var cells: [Day?] = []
        var count = 0
        var partialCount = 0
        if let month = calendar.dateInterval(of: .month, for: now),
           let range = calendar.range(of: .day, in: .month, for: now) {
            let leading = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
            cells.append(contentsOf: Array(repeating: nil, count: leading))
            for offset in 0..<range.count {
                guard let date = calendar.date(byAdding: .day, value: offset, to: month.start) else { continue }
                let start = calendar.startOfDay(for: date).timeIntervalSince1970
                let prayed = prayedStarts.contains(start)
                let partial = !prayed && partialStarts.contains(start)
                if prayed { count += 1 }
                if partial { partialCount += 1 }
                cells.append(Day(number: offset + 1, date: date, prayed: prayed, partial: partial, isToday: calendar.isDate(date, inSameDayAs: today), isFuture: date > today))
            }
            let trailing = (7 - cells.count % 7) % 7
            cells.append(contentsOf: Array(repeating: nil, count: trailing))
        }
        prayedDays = count
        partialDays = partialCount
        weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
    }
}

private struct JourneySummaryMetric: View {
    @Environment(\.palette) private var palette
    var value: String
    var unit: String
    var label: String

    var body: some View {
        VStack(spacing: AppTheme.Space.xs) {
            Text(value)
                .font(AppTheme.TypeRole.serifTitle)
                .foregroundStyle(palette.ink)
            Text(unit)
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .foregroundStyle(palette.ink)
            Text(label)
                .font(AppTheme.TypeRole.caption())
                .foregroundStyle(palette.dim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyMetricDivider: View {
    @Environment(\.palette) private var palette
    var height: CGFloat = 86

    var body: some View {
        Rectangle()
            .fill(palette.hair.opacity(0.55))
            .frame(width: AppTheme.Component.hairline, height: height)
    }
}

private struct JourneyCalendarCell: View {
    @Environment(\.palette) private var palette
    var day: JourneyMonth.Day?

    var body: some View {
        ZStack {
            if let day {
                Circle()
                    .fill(day.prayed ? palette.accent : .clear)
                    .frame(width: day.prayed || day.partial || day.isToday ? 32 : 28, height: day.prayed || day.partial || day.isToday ? 32 : 28)
                    .overlay {
                        if day.partial || day.isToday {
                            Circle()
                                .strokeBorder(palette.accent, lineWidth: 2)
                        }
                    }
                    .opacity(day.prayed || day.partial || day.isToday ? 1 : 0)

                Text("\(day.number)")
                    .font(AppTheme.TypeRole.caption(weight: day.isToday || day.prayed || day.partial ? .semibold : .regular))
                    .foregroundStyle(foreground(for: day))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .accessibilityLabel(accessibilityLabel)
    }

    private func foreground(for day: JourneyMonth.Day) -> Color {
        if day.prayed { return palette.onAccent }
        if day.isFuture { return palette.dim.opacity(0.45) }
        return palette.ink
    }

    private var accessibilityLabel: String {
        guard let day else { return "Empty calendar day" }
        if day.prayed { return "Day \(day.number), Rosary prayed" }
        if day.partial { return "Day \(day.number), some prayer" }
        if day.isToday { return "Day \(day.number), today" }
        return "Day \(day.number), no prayer recorded"
    }
}

private struct JourneyLegendDot: View {
    enum Style { case prayed, partial }

    @Environment(\.palette) private var palette
    var title: String
    var style: Style

    var body: some View {
        HStack(spacing: AppTheme.Space.xs) {
            marker
            Text(title)
                .font(AppTheme.TypeRole.caption())
                .foregroundStyle(palette.dim)
        }
    }

    @ViewBuilder
    private var marker: some View {
        switch style {
        case .prayed:
            Circle().fill(palette.accent).frame(width: 12, height: 12)
        case .partial:
            Circle().strokeBorder(palette.accent, lineWidth: 2).frame(width: 12, height: 12)
        }
    }
}

private struct JourneyInlineStat: View {
    @Environment(\.palette) private var palette
    var value: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            Text(value)
                .font(AppTheme.TypeRole.body(weight: .regular))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyStatTile: View {
    @Environment(\.palette) private var palette
    var symbol: String
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: AppTheme.Space.sm) {
            Image(systemName: symbol)
                .guideSymbol(size: 18, weight: .medium)
                .foregroundStyle(palette.ink)
                .frame(height: 24)

            Text(value)
                .font(AppTheme.TypeRole.serifSmall)
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(label)
                .font(AppTheme.TypeRole.caption())
                .foregroundStyle(palette.dim)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 104)
        .padding(.vertical, AppTheme.Space.md)
        .padding(.horizontal, AppTheme.Space.xs)
        .guideCard(fill: palette.surface)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyMilestonesView: View {
    @Environment(\.palette) private var palette
    let milestones: JourneyMilestones

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                summaryCard
                ForEach(milestones.orderedCategories) { category in
                    GuideSectionBoundary()
                    VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                        GuideSectionLabel(text: category.rawValue, prominence: .strong)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(milestones.items.filter { $0.category == category }) { item in
                            JourneyMilestoneCard(item: item)
                        }
                    }
                }
                Text("Completed milestones stay saved on this device when older history expires. Deleting prayer data clears them.")
                    .font(AppTheme.TypeRole.caption())
                    .foregroundStyle(palette.dim)
                    .padding(.top, AppTheme.Space.xl)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.tabBarContentClearance)
        }
        .background(palette.bg.ignoresSafeArea())
        .guideDetailChrome("Milestones")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text("Milestones completed")
                    .font(AppTheme.TypeRole.caption(weight: .medium))
                    .foregroundStyle(palette.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                    Text("\(milestones.earnedCount)")
                        .font(AppTheme.TypeRole.headingPrimary)
                        .foregroundStyle(palette.ink)
                    Text("of \(milestones.items.count)")
                        .font(AppTheme.TypeRole.callout)
                        .foregroundStyle(palette.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(milestones.earnedCount) of \(milestones.items.count) milestones completed")
            }

            ProgressView(value: Double(milestones.earnedCount), total: Double(max(1, milestones.items.count)))
                .tint(palette.accent)
                .accessibilityHidden(true)

            Text("Small moments of faithfulness.")
                .font(AppTheme.TypeRole.callout)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Space.xl)
        .guideCard(fill: palette.surface)
    }

}

private struct JourneyMilestoneCard: View {
    @Environment(\.palette) private var palette
    let item: JourneyMilestones.Item

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                ZStack {
                    Circle().fill(item.completed ? palette.accentTint : palette.bg)
                    MilestoneLineGlyph(glyph: AppTheme.MilestoneIcon.glyph(for: item.id))
                        .stroke(style: AppTheme.LineIcon.strokeStyle)
                        .frame(width: AppTheme.MysteryIcon.glyphSize, height: AppTheme.MysteryIcon.glyphSize)
                        .foregroundStyle(item.completed ? palette.accent : palette.textSecondary)
                }
                .frame(width: AppTheme.MysteryIcon.circleSize, height: AppTheme.MysteryIcon.circleSize)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(item.title)
                        .font(AppTheme.TypeRole.callout(weight: .medium))
                        .foregroundStyle(palette.ink)
                    if let date = item.earnedAt {
                        Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTheme.TypeRole.caption())
                            .foregroundStyle(palette.textSecondary)
                    } else {
                        Text(item.count == 0 ? "When you’re ready · \(item.progressText)" : item.progressText)
                            .font(AppTheme.TypeRole.caption())
                            .foregroundStyle(palette.textSecondary)
                        ProgressView(value: item.progress)
                            .tint(palette.accent)
                            .accessibilityLabel(item.title)
                            .accessibilityValue(item.progressText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if item.completed {
                    Image(systemName: "checkmark")
                        .guideSymbol(size: 12, weight: .medium)
                        .foregroundStyle(palette.accent)
                        .accessibilityLabel("Completed")
                        .padding(.top, AppTheme.Space.xs)
                }
            }

        }
        .padding(AppTheme.Space.lg)
        .guideCard(fill: palette.surface)
        .accessibilityElement(children: .combine)
    }
}

private struct JourneyHistoryRow: View {
    struct Model: Hashable, Identifiable {
        enum Kind: Hashable {
            case rosary
            case decade(Int)
        }

        var date: Date
        var mystery: MysterySetKind?
        var duration: TimeInterval?
        var intentionTitle: String?
        var kind: Kind

        var id: String {
            let mysteryId = mystery?.rawValue ?? "legacy"
            return "\(date.timeIntervalSince1970)-\(mysteryId)-\(kind.identity)"
        }
    }

    @Environment(\.palette) private var palette
    var row: Model

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Space.md) {
            historyIcon

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title)
                    .font(AppTheme.TypeRole.body(weight: .regular))
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(statusText)
                    .font(AppTheme.TypeRole.caption())
                    .foregroundStyle(palette.textSecondary)

                if let intentionTitle = normalizedIntentionTitle {
                    Text(intentionTitle)
                        .font(AppTheme.TypeRole.caption())
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusMark
        }
        .padding(AppTheme.Space.lg)
        .guideCard(fill: palette.surface)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        guard let mystery = row.mystery else { return "Rosary prayed" }
        return "\(mystery.shortName) Mysteries"
    }

    private var statusText: String {
        switch row.kind {
        case .rosary:
            return "Rosary completed"
        case .decade(let number):
            return "Decade \(OrdinalWord.roman(number)) prayed"
        }
    }

    private var normalizedIntentionTitle: String? {
        let trimmed = row.intentionTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    @ViewBuilder
    private var historyIcon: some View {
        if let mystery = row.mystery {
            MysterySetIcon(set: mystery)
        } else {
            ZStack {
                Circle().fill(palette.accentTint)
                Image(systemName: row.kind == .rosary ? "circle.dotted" : "circle.grid.2x2")
                    .guideSymbol(size: 19, weight: .regular)
                    .foregroundStyle(palette.ink)
            }
            .frame(width: AppTheme.MysteryIcon.circleSize, height: AppTheme.MysteryIcon.circleSize)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var statusMark: some View {
        switch row.kind {
        case .rosary:
            ZStack {
                Circle()
                    .fill(palette.accent)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .guideSymbol(size: 11, weight: .semibold)
                    .foregroundStyle(palette.onAccent)
            }
            .accessibilityLabel("Completed")
        case .decade:
            Circle()
                .fill(palette.accent)
                .frame(width: 12, height: 12)
                .accessibilityLabel("Partial prayer")
        }
    }


}

private extension JourneyHistoryRow.Model.Kind {
    var identity: String {
        switch self {
        case .rosary:
            return "rosary"
        case .decade(let number):
            return "decade-\(number)"
        }
    }
}
