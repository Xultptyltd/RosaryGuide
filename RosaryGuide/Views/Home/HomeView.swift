import SwiftUI

private struct HomeCTABottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var prayLaunch: PrayLaunch?

    @State private var selectedSet: MysterySetKind?
    @State private var showIntentionSheet = false
    @State private var chosenIntentionId: UUID?
    /// Pinned intention filled in automatically on appear (not a user choice).
    @State private var autoPinnedIntentionId: UUID?
    @State private var chosenIntentionTitle = ""
    @State private var chosenIntentionNote = ""
    @State private var intentionSelectionExplicit = false
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false
    @State private var openFeastID: String?
    @State private var weekFeastInfo: DatedFeast?
    @State private var pendingFeastDetail: DatedFeast?
    @State private var selectedMysteryDetail: Mystery?
    @State private var pendingMysteryPrayer: PrayLaunch?
    @State private var mysteryScrollID: String?
    @State private var selectedLiturgicalVerse: LiturgicalVerse?
    @State private var navigationPath = NavigationPath()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Archived pending a product decision: keep the Home Daily Scripture implementation
    // and its detail sheet recoverable without showing the section in the current Home UI.
    private static let showDailyScriptureOnHome = false

    @Environment(DayClock.self) private var dayClock
    /// Reads the day clock so Home redraws when the day rolls over.
    private var today: Date { _ = dayClock.today; return Date() }
    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: today)
    }
    /// A hand-picked set wins; otherwise a feast's recommended set, or the weekday set.
    private var currentSet: MysterySetKind {
        assignment.shownSet(manual: selectedSet, prefersWeekday: dayClock.prefersWeekdaySet)
    }
    private var mysteries: [Mystery] { MysteryCatalog.mysteries(for: currentSet) }
    /// Only an intention the user picked here pre-selects on the intention step.
    /// The auto-shown pinned intention does not; a new Rosary starts with none.
    private var explicitLaunchIntentionId: UUID? {
        guard let chosenIntentionId, chosenIntentionId != autoPinnedIntentionId else { return nil }
        return chosenIntentionId
    }

    private var currentIntention: OfferIntention? {
        if let chosenIntentionId {
            return offer.intention(id: chosenIntentionId)
        }
        if intentionSelectionExplicit {
            return nil
        }
        return offer.sortedIntentions.first(where: \.isPinned)
    }
    private var nextRelevantFeast: DatedFeast? {
        if let feast = assignment.feast { return feast }
        return FeastCatalog.upcoming(from: today, limit: 12).first {
            !Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
    /// Highest-ranked FeastCatalog entry for calendar today, if any.
    private var todaysCatalogFeast: DatedFeast? {
        FeastCatalog.feasts(on: today)
            .sorted { feastRankScore($0.feast.rank) > feastRankScore($1.feast.rank) }
            .first
    }
    /// Future feasts only (excludes today) for the secondary list under the featured card.
    private var upcomingPreviewFeasts: [DatedFeast] {
        Array(
            FeastCatalog.upcoming(from: today, limit: 16)
                .filter { !Calendar.current.isDate($0.date, inSameDayAs: today) }
                .prefix(3)
        )
    }
    /// Featured card: today's feast when present, otherwise the next upcoming feast.
    private var feastDaysFeatured: DatedFeast? {
        todaysCatalogFeast ?? upcomingPreviewFeasts.first ?? nextRelevantFeast
    }
    private func feastRankScore(_ rank: FeastRank) -> Int {
        switch rank {
        case .solemnity: return 5
        case .feast: return 4
        case .memorial: return 3
        case .optionalMemorial: return 2
        case .seasonal: return 1
        }
    }

    @State private var viewport = CGSize(width: 390, height: 720)
    @State private var topInset: CGFloat = 47
    @State private var bottomInset: CGFloat = 83
    @State private var measuredCTABottom: CGFloat = 0
    @State private var collapseHeroTopBand = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(topInset: topInset, viewport: viewport.height + topInset)
                            .frame(width: viewport.width)
                            .id("home-top")
                        sheet(width: viewport.width, gutter: AppTheme.gutter(for: viewport.width))
                            .padding(.top, -36)
                            .frame(width: viewport.width)
                    }
                    .frame(width: viewport.width, alignment: .top)
                    // Match Feasts/Learn/Intentions: clear the tab bar and allow
                    // scrolled content to show through liquid glass.
                    .padding(.bottom, AppTheme.tabBarContentClearance)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                .onPreferenceChange(HomeCTABottomPreferenceKey.self) { value in
                    measuredCTABottom = value
                    updateHeroTopBandIfNeeded()
                }
            }
            .background(palette.bg)
            .ignoresSafeArea(edges: .top)
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DatedFeast.self) { item in
                FeastDetailView(prayLaunch: $prayLaunch, item: item)
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { captureMetrics(geo) }
                    .onChange(of: geo.size) { _, _ in captureMetrics(geo) }
            }
        }
        .onAppear {
            syncCurrentIntentionIfNeeded()
        }
        .onChange(of: dayClock.today) { _, _ in
            // A new day starts on its own default set.
            selectedSet = nil
        }
        .onChange(of: currentSet) { _, _ in
            mysteryScrollID = mysteries.first?.id
        }
        .onChange(of: chosenIntentionId) { _, _ in
            intentionSelectionExplicit = true
        }
        .onChange(of: showIntentionSheet) { _, showing in
            // Any choice made in the sheet counts as the user's, even the pinned one.
            if showing { autoPinnedIntentionId = nil }
        }
        .sheet(isPresented: $showIntentionSheet) {
            PrayIntentionSheet(
                chosenId: $chosenIntentionId,
                chosenTitle: $chosenIntentionTitle,
                chosenNote: $chosenIntentionNote,
                mysterySet: currentSet
            )
            .environment(offer)
            .environment(\.palette, palette)
        }
        .sheet(item: $weekFeastInfo, onDismiss: {
            if let item = pendingFeastDetail {
                pendingFeastDetail = nil
                navigationPath.append(item)
            }
        }) { item in
            weekFeastSheet(item)
                .presentationDetents([.height(weekFeastSheetHeight(for: item)), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.containerRadius)
        }
        .sheet(item: $selectedMysteryDetail, onDismiss: {
            if let launch = pendingMysteryPrayer {
                pendingMysteryPrayer = nil
                prayLaunch = launch
            }
        }) { mystery in
            mysteryDetailSheet(mystery)
                .presentationDetents([.height(mysteryDetailSheetHeight(for: mystery)), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.containerRadius)
        }
        .sheet(item: $selectedLiturgicalVerse) { verse in
            liturgicalVerseSheet(verse)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.containerRadius)
        }

    }

    private func captureMetrics(_ geo: GeometryProxy) {
        viewport = geo.size
        topInset = geo.safeAreaInsets.top
        bottomInset = geo.safeAreaInsets.bottom
        updateHeroTopBandIfNeeded()
    }

    private func updateHeroTopBandIfNeeded() {
        guard measuredCTABottom > 0, viewport.height > 0 else { return }
        let visibleBottom = viewport.height - bottomInset - AppTheme.tabBarContentClearance
        let shouldCollapse = measuredCTABottom > visibleBottom
        guard shouldCollapse != collapseHeroTopBand else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            collapseHeroTopBand = shouldCollapse
        }
    }

    private func hero(topInset: CGFloat, viewport: CGFloat) -> some View {
        // Top band above the artwork: 60% of the status-bar inset.
        let artworkTop = collapseHeroTopBand ? 0 : (topInset * 0.6).rounded()
        return ZStack(alignment: .top) {
            palette.bg
            MysteryArtworkView(set: currentSet, kind: .heroTall)
                .frame(height: AppTheme.homeHeroHeight(viewport: viewport) + topInset)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: palette.bg.opacity(colorScheme == .light ? 0.18 : 0.34), location: 0),
                            .init(color: .clear, location: 0.22),
                            .init(color: palette.bg.opacity(0.55), location: 0.64),
                            .init(color: palette.bg, location: 0.86),
                            .init(color: palette.bg, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .padding(.top, artworkTop)
            HStack(spacing: AppTheme.Space.md) {
                Spacer(minLength: 0)
                glassTheme
            }
            .padding(.top, topInset)
            .padding(.horizontal, AppTheme.gutter)
        }
        .frame(height: AppTheme.homeHeroHeight(viewport: viewport) + topInset + artworkTop)
    }

    private var glassTheme: some View {
        return Button {
            settings.toggleLightDark(systemIsDark: colorScheme == .dark)
        } label: {
            Label(colorScheme == .light ? "Day" : "Night", systemImage: colorScheme == .light ? "sun.max.fill" : "moon.fill")
                .labelStyle(.titleAndIcon)
                .font(AppTheme.TypeRole.label(weight: .medium))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: AppTheme.Accessibility.minHitTarget)
                .background {
                    Capsule()
                        .fill(.clear)
                        .guideFloatingGlass(in: Capsule(), palette: palette)
                }
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Appearance")
        .accessibilityValue(colorScheme == .light ? "Day" : "Night")
    }

    /// Small centred tertiary pill at the end of Home that opens the share sheet.
    /// No App Store listing exists yet, so it shares the website.
    private var shareAppButton: some View {
        ShareLink(
            item: URL(string: "https://rosaryguide.app")!,
            subject: Text("Rosary Guide"),
            message: Text("I've been praying the Rosary with Rosary Guide. Take a look:"),
            // Share sheet header shows the blue icon (IconPreviewBlue is the same artwork as
            // the AppIconBlue alternate icon) instead of the site's preview.
            preview: SharePreview("Rosary Guide", image: Image("IconPreviewBlue"))
        ) {
            HStack(spacing: AppTheme.Space.sm) {
                Image(systemName: "square.and.arrow.up")
                    .guideSymbol(size: 15, weight: .medium)
                Text("Share Rosary Guide")
                    .font(AppTheme.TypeRole.callout)
                    .lineLimit(1)
            }
            .foregroundStyle(palette.tertiaryButtonText)
            .padding(.horizontal, AppTheme.Space.lg)
            .frame(height: AppTheme.Accessibility.minHitTarget)
            .background(palette.tertiaryButtonFill, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
        })
        .accessibilityLabel("Share Rosary Guide")
    }

    private func sheet(width: CGFloat, gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(AppTheme.TypeRole.label)
                .foregroundStyle(palette.dim)
                .padding(.bottom, AppTheme.Space.md)
                .guideReveal(delay: 0.02)

            GuideDisplayTitle(
                text: homeMysteryTitle,
                size: AppTheme.homeTitleSize(width: width),
                color: palette.ink
            )
            .contentTransition(reduceMotion ? .identity : .opacity)
            .animation(reduceMotion ? nil : MotionTokens.selection, value: currentSet)

            // On a feast with its own set, the feast paragraph takes the subtitle's place.
            if let feast = assignment.feast, showsFeastLine {
                feastOffer(feast)
                    .padding(.top, AppTheme.Space.md)
                    .guideReveal(delay: 0.08)
            } else {
                Text(currentSet.themeSummary)
                    .guideThemeSummaryStyle()
                    .padding(.top, AppTheme.Space.md)
                    .contentTransition(reduceMotion ? .identity : .opacity)
                    .animation(reduceMotion ? nil : MotionTokens.selection, value: currentSet)
                    .guideReveal(delay: 0.08)
            }

            setPicker
                .padding(.top, AppTheme.Space.xl)
                .guideReveal(delay: 0.1)

            primaryTodayCTA
                .padding(.top, AppTheme.Space.lg)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: HomeCTABottomPreferenceKey.self,
                            value: geometry.frame(in: .global).maxY
                        )
                    }
                }
                .guideReveal(delay: 0.14)

            GuideSectionBoundary(gutter: gutter)

            mysteryRail(gutter: gutter)

            if Self.showDailyScriptureOnHome {
                liturgicalVerseSection
                    .padding(.top, AppTheme.sectionGap)
            }

            GuideSectionBoundary(gutter: gutter)

            VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
                GuideSectionLabel(text: "Upcoming feast days", prominence: .strong)
                comingUpSection
            }

            GuideSectionBoundary(gutter: gutter)

            VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
                GuideSectionLabel(text: "This week", prominence: .strong)
                weekGlance
            }

            shareAppButton
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.sectionGap)
        }
        .padding(.horizontal, gutter)
        .padding(.top, AppTheme.Space.sm)
        .padding(.bottom, AppTheme.Space.xxl)
        .frame(maxWidth: 576, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func syncCurrentIntentionIfNeeded() {
        guard chosenIntentionId == nil, chosenIntentionTitle.isEmpty else { return }
        guard let pinned = offer.sortedIntentions.first(where: \.isPinned) else { return }
        chosenIntentionId = pinned.id
        autoPinnedIntentionId = pinned.id
        chosenIntentionTitle = pinned.title
        chosenIntentionNote = pinned.note ?? ""
        intentionSelectionExplicit = false
    }

    private var primaryTodayCTA: some View {
        PillButton(title: primaryPrayerTitle) {
            if let resumable = matchingResumableSession {
                prayLaunch = .resume(resumable)
            } else {
                prayLaunch = .fresh(currentSet, intentionId: explicitLaunchIntentionId)
            }
        }
    }

    private var primaryPrayerTitle: String {
        if let resumable = matchingResumableSession {
            return resumable.continueCTATitle
        }
        if session.completedToday(currentSet) {
            return "Pray again"
        }
        return isShowingTodayMysteries ? "Pray today's mysteries" : "Pray the \(currentSet.shortName) Mysteries"
    }

    private var matchingResumableSession: PrayerSession? {
        guard let resumable = session.resumableSession, resumable.mysterySet == currentSet else { return nil }
        return resumable
    }

    private var liturgicalVerseSection: some View {
        let verse = LiturgicalVerseCatalog.verse(for: today)
        return Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            selectedLiturgicalVerse = verse
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                GuideSectionLabel(text: "Daily Scripture", prominence: .strong)

                Text(verse.homeDisplayExcerpt)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(6)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(verse.reference)
                            .font(AppTheme.TypeRole.label(weight: .semibold))
                            .foregroundStyle(palette.ink)
                        if let secondaryCitation = verse.secondaryCitation {
                            Text(secondaryCitation)
                                .font(AppTheme.TypeRole.caption)
                                .foregroundStyle(palette.secondaryText)
                        }
                    }
                    Spacer(minLength: AppTheme.Space.sm)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily scripture. \(verse.homeExcerpt). \(verse.citationLine)")
        .accessibilityHint("Shows the fuller Scripture passage")
    }

    private func liturgicalVerseSheet(_ verse: LiturgicalVerse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                GuideSectionLabel(text: "Daily Scripture", prominence: .strong)

                Text(verse.reference)
                    .font(AppTheme.TypeRole.sectionTitle)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let secondaryCitation = verse.secondaryCitation {
                    Text(secondaryCitation)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.secondaryText)
                }

                Text(verse.fullText)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(palette.bg)
    }

    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let featured = feastDaysFeatured {
                feastFeatureCard(featured)
            }
        }
    }

    private func feastFeatureCard(_ featured: DatedFeast) -> some View {
        let isToday = Calendar.current.isDate(featured.date, inSameDayAs: today)
        // Secondary rows are always future feasts; when today is featured, take the first two upcoming.
        let remaining = Array(
            (isToday ? upcomingPreviewFeasts : Array(upcomingPreviewFeasts.dropFirst()))
                .prefix(2)
        )
        return VStack(spacing: 0) {
            NavigationLink {
                FeastDetailView(prayLaunch: $prayLaunch, item: featured)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        if let path = ArtCatalog.feastHeroPath(feastId: featured.feast.id, scheme: colorScheme) {
                            FocusedRasterImage(
                                directory: path.directory,
                                name: path.name,
                                ext: path.ext,
                                focus: UnitPoint(x: 0.5, y: 0.42)
                            )
                        } else {
                            MysteryArtworkView(set: featured.feast.suggestedMysterySet ?? .glorious, mysteryNumber: 5, kind: .plateWide)
                        }
                    }
                    .frame(height: 176)
                    .clipped()
                    .overlay {
                        PartialCardStroke(
                            edges: [.top, .leading, .trailing],
                            radius: AppTheme.featureRadius,
                            color: palette.cardStroke,
                            lineWidth: AppTheme.Component.panelStrokeWidth
                        )
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        if isToday {
                            // Match This week calendar weekRow TODAY pill (colors, font, padding, Capsule).
                            Text("TODAY")
                                .font(AppTheme.TypeRole.caption(weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(palette.todayPillText)
                                .padding(.horizontal, AppTheme.Space.sm)
                                .padding(.vertical, AppTheme.Space.xs)
                                .background(palette.todayPillFill, in: Capsule())
                        } else {
                            feastDateText(featured.date)
                        }
                        Text(featured.feast.shortTitle)
                            .font(AppTheme.TypeRole.headingSecondary)
                            .foregroundStyle(palette.ink)
                            .lineLimit(3)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Space.xl)
                    .padding(.vertical, AppTheme.Component.feastPreviewTextPadding)

                }
            }
            .buttonStyle(.plain)

            ForEach(remaining) { item in
                Hairline()
                    .padding(.horizontal, AppTheme.Space.xl)
                NavigationLink {
                    FeastDetailView(prayLaunch: $prayLaunch, item: item)
                } label: {
                    HStack(alignment: .top, spacing: AppTheme.Space.md) {
                        feastDateText(item.date)
                            .frame(width: 64, alignment: .leading)
                        Text(item.feast.shortTitle)
                            .font(AppTheme.TypeRole.bodySmall)
                            .foregroundStyle(palette.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Space.xl)
                    .padding(.vertical, AppTheme.Space.md)
                }
                .buttonStyle(.plain)
            }
        }
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
        .guideSoftShadow(elevated: colorScheme == .light)
    }

    private func feastDateText(_ date: Date) -> some View {
        Text(date.formatted(.dateTime.day().month(.abbreviated)))
            .font(AppTheme.TypeRole.label(weight: .medium))
            .tracking(0)
            .textCase(.uppercase)
            .foregroundStyle(palette.dim)
    }

    private var weekGlance: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                ForEach(Array(MysteryCalendar.week(containing: today).enumerated()), id: \.element.0) { index, entry in
                    let day = entry.0
                    let item = entry.1
                    weekRow(day: day, assignment: item)

                    if index < MysteryCalendar.week(containing: today).count - 1 {
                        Hairline()
                        }
                }
            }
            .padding(.vertical, AppTheme.Space.sm)
        }
    }

    private func weekRow(day: Date, assignment: MysteryAssignment) -> some View {
        let prayed = session.prayed(on: day)
        let isToday = Calendar.current.isDateInToday(day)

        return HStack(alignment: .center, spacing: AppTheme.Space.sm) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                HStack(spacing: AppTheme.Space.sm) {
                    Text(day.formatted(.dateTime.day().month(.abbreviated)))
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.textSecondary)
                    if let feast = assignment.feast {
                        Button {
                            HapticService.play(.light, enabled: settings.hapticsEnabled)
                            weekFeastInfo = feast
                        } label: {
                            Image(systemName: "crown.fill")
                                .guideSymbol(size: 12, weight: .regular)
                                .foregroundStyle(palette.feastIndicator)
                                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                                .contentShape(Rectangle())
                                .padding(-16)
                        }
                        .buttonStyle(.plain)
                        .zIndex(1)
                        .accessibilityLabel("Feast day")
                        .accessibilityValue(feast.feast.shortTitle)
                        .accessibilityHint("Shows feast details")
                    }
                    if isToday {
                        Text("Today")
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.todayPillText)
                            .padding(.horizontal, AppTheme.Space.sm)
                            .padding(.vertical, 2)
                            .background(palette.todayPillFill, in: Capsule())
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(assignment.set.shortName)
                .font(AppTheme.TypeRole.callout)
                .foregroundStyle(isToday ? palette.textPrimary : palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if prayed {
                Image(systemName: "checkmark.circle.fill")
                    .guideSymbol(size: 16, weight: .regular)
                    .foregroundStyle(palette.accent)
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, AppTheme.Space.sm)
        .frame(minHeight: 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(weekAccessibilityLabel(day: day, assignment: assignment, prayed: prayed))
        .accessibilityValue(prayed ? "Prayed" : "Not yet prayed")
    }

    private func weekAccessibilityLabel(day: Date, assignment: MysteryAssignment, prayed: Bool) -> String {
        var parts = [
            day.formatted(.dateTime.weekday(.wide)),
            "\(assignment.set.shortName) Mysteries"
        ]
        if prayed {
            parts.append("prayed")
        }
        if let feast = assignment.feast {
            parts.append(feast.feast.shortTitle)
        }
        return parts.joined(separator: ", ")
    }

    private func weekFeastSheet(_ item: DatedFeast) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                        Image(systemName: "crown.fill")
                            .guideSymbol(size: 12, weight: .regular)
                            .foregroundStyle(palette.feastIndicator)
                        Text("\(item.feast.rank.title) · \(item.date.formatted(.dateTime.day().month(.wide).year()))")
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(item.feast.shortTitle)
                        .font(AppTheme.TypeRole.headingPrimary)
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(weekFeastDescription(for: item.feast))
                    .font(AppTheme.TypeRole.body)
                    .lineSpacing(5)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PillButton(title: "Explore this feast", filled: false) {
                pendingFeastDetail = item
                weekFeastInfo = nil
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.vertical, AppTheme.Space.lg)
            .background(palette.bg)
        }
        .background(palette.bg)
    }

    private func weekFeastSheetHeight(for item: DatedFeast) -> CGFloat {
        let titleLines = item.feast.shortTitle.count > 28 ? 2 : 1
        let description = weekFeastDescription(for: item.feast)
        let descriptionLines = CGFloat(max(3, Int(ceil(Double(description.count) / 42.0))))
        let estimated = 184 + CGFloat(titleLines * 40) + descriptionLines * 25 + AppTheme.Component.pillHeight
        return dynamicTypeSize.isAccessibilitySize ? 640 : min(max(estimated, 460), 640)
    }

    private func weekFeastDescription(for feast: Feast) -> String {
        switch feast.id {
        case "michael":
            return "The Church celebrates the three archangels named in Scripture: Michael, defender against evil; Gabriel, messenger of the Annunciation; and Raphael, healer and guide. This feast honors God’s angelic servants and their work in salvation history."
        case "guardian-angels":
            return "The Church gives thanks for the guardian angels, whom God entrusts to watch over and guide His people. This memorial celebrates God’s personal care for each soul through these unseen companions."
        default:
            if let narrative = FeastNarratives.narrative(for: feast.id) {
                return narrative.about
            }
            return feast.summary
        }
    }

    private static let feastSetURL = URL(string: "rosaryguide-home://feast-set")!
    private static let weekdaySetURL = URL(string: "rosaryguide-home://weekday-set")!

    /// On a feast with its own recommended set, one paragraph that wraps naturally. With the
    /// feast's set showing it ends in "Back to today"; with the weekday set showing, the set
    /// name links back to the feast's set.
    /// The feast line shows while the feast's set or the weekday set is on screen.
    private var showsFeastLine: Bool {
        guard assignment.feastLine != nil, let suggested = assignment.feastSuggestion else { return false }
        return currentSet == suggested || currentSet == assignment.set
    }

    @ViewBuilder
    private func feastOffer(_ feast: DatedFeast) -> some View {
        if let line = assignment.feastLine, let suggested = assignment.feastSuggestion, showsFeastLine {
            let showingFeastSet = currentSet == suggested
            Text(feastLineText(line, showingFeastSet: showingFeastSet))
                .font(AppTheme.TypeRole.themeSummary)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.openURL, OpenURLAction { url in
                    switch url {
                    case Self.feastSetURL: chooseFeastSet(true)
                    case Self.weekdaySetURL: chooseFeastSet(false)
                    default: return .systemAction
                    }
                    return .handled
                })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(line.text)
                .accessibilityAction(named: showingFeastSet
                                     ? "Back to today's \(assignment.set.shortName) Mysteries"
                                     : "Pray the \(line.setName)") {
                    chooseFeastSet(!showingFeastSet)
                }
        }
    }

    private func feastLineText(_ line: FeastLine, showingFeastSet: Bool) -> AttributedString {
        var text = AttributedString(line.lead)
        var setName = AttributedString(line.setName)
        if !showingFeastSet {
            setName.link = Self.feastSetURL
            setName.foregroundColor = palette.textPrimary
            setName.underlineStyle = .single
        }
        text += setName
        text += AttributedString(line.tail)
        if showingFeastSet {
            var back = AttributedString(FeastLine.backToTodayTitle)
            back.link = Self.weekdaySetURL
            back.foregroundColor = palette.textPrimary
            back.underlineStyle = .single
            text += AttributedString(" ")
            text += back
        }
        return text
    }

    private func chooseFeastSet(_ feastSet: Bool) {
        HapticService.play(.light, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : MotionTokens.selection) {
            selectedSet = nil
            dayClock.prefersWeekdaySet = !feastSet
        }
    }

    /// The same system segmented control as the English/Latin/Both toggle (height, Liquid
    /// Glass, sliding thumb). UIKit segments are equal width, so the weekday dot is overlaid on
    /// its segment: bright while that set is showing, faint otherwise.
    private var setPicker: some View {
        Picker("Mystery set", selection: mysterySetSelection) {
            ForEach(MysterySetKind.displayOrder) { set in
                Text(set.shortName).tag(set)
            }
        }
        .guideSegmentedControl()
        .overlay {
            HStack(spacing: 0) {
                ForEach(MysterySetKind.displayOrder) { set in
                    VStack {
                        if set == assignment.pickerDotSet {
                            Circle()
                                .fill(currentSet == set ? palette.ink : palette.faint)
                                .frame(width: AppTheme.Space.xs, height: AppTheme.Space.xs)
                                .padding(.top, AppTheme.Space.sm)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .accessibilityLabel("Mystery set")
        .accessibilityHint("Today's weekday set is the \(assignment.pickerDotSet.shortName) Mysteries")
    }

    private var mysterySetSelection: Binding<MysterySetKind> {
        Binding(
            get: { currentSet },
            set: { newValue in
                HapticService.play(.light, enabled: settings.hapticsEnabled)
                withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                    selectedSet = newValue
                }
            }
        )
    }

    private var homeMysteryTitle: String {
        "\(currentSet.shortName)\nMysteries"
    }


    private func mysteryRail(gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: mysteryRailTitle, prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
            GeometryReader { geo in
                let cardWidth = min(286, max(252, geo.size.width * 0.74))
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppTheme.Space.md) {
                        ForEach(mysteries) { mystery in
                            mysteryCard(mystery)
                                .frame(width: cardWidth)
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1 : 0.965)
                                        .opacity(phase.isIdentity ? 1 : 0.86)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, gutter)
                    .padding(.vertical, AppTheme.Space.xs)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $mysteryScrollID)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .frame(width: geo.size.width)
                .clipped()
            }
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 550 : 386)
            .padding(.horizontal, -gutter)

            mysteryPageDots
                .padding(.top, AppTheme.Space.xs)
        }
    }

    private var mysteryPageDots: some View {
        GuidePageDots(current: currentMysteryIndex, count: mysteries.count)
            .accessibilityLabel("Mystery card \(currentMysteryIndex + 1) of \(mysteries.count)")
    }

    private var currentMysteryIndex: Int {
        guard let mysteryScrollID,
              let index = mysteries.firstIndex(where: { $0.id == mysteryScrollID }) else {
            return 0
        }
        return index
    }

    private var mysteryRailTitle: String {
        isShowingTodayMysteries ? "Today's mysteries" : currentSet.name.primary(for: settings.language)
    }

    /// Today's set as offered by default (the feast's set, or the weekday set if chosen).
    private var todaysSet: MysterySetKind {
        assignment.defaultSet(prefersWeekday: dayClock.prefersWeekdaySet)
    }

    private var isShowingTodayMysteries: Bool {
        currentSet == todaysSet
    }

    private func mysteryCard(_ mystery: Mystery) -> some View {
        Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            selectedMysteryDetail = mystery
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                MysteryArtworkView(set: mystery.set, mysteryNumber: mystery.number, slug: mystery.artSlug, kind: .plate, bottomFade: false, cardFraming: true)
                    .aspectRatio(1.5, contentMode: .fit)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    Text(mystery.title.primary(for: settings.language))
                        .font(AppTheme.TypeRole.cardTitle)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    GuideTextButtonLabel(title: "Read more")
                        .padding(.top, AppTheme.Space.sm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                .padding(.horizontal, AppTheme.Space.xl)
                .padding(.top, AppTheme.Space.lg)
                .padding(.bottom, AppTheme.Space.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 366, alignment: .top)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
            .guideSoftShadow(elevated: colorScheme == .light)
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mysteryAccessibilityLabel(mystery))
        .accessibilityHint("Read more about this mystery, its Scripture, and fruit")
    }

    private func mysteryAccessibilityLabel(_ mystery: Mystery) -> String {
        "Mystery \(mystery.number), \(mystery.title.primary(for: settings.language))."
    }

    private func mysteryDetailSheet(_ mystery: Mystery) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text("\(OrdinalWord.english(mystery.number)) mystery · \(mystery.set.name.primary(for: settings.language))")
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.dim)
                    Text(mystery.title.primary(for: settings.language))
                        .font(AppTheme.TypeRole.headingPrimary)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(MysteryScripture.display(for: mystery, translation: settings.rosaryConfig.translation, language: settings.language))
                        .font(AppTheme.TypeRole.body)
                        .lineSpacing(5)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(mystery.scriptureReference)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.dim)
                }

                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    GuideSectionLabel(text: "Fruit of this mystery", prominence: .strong)
                    Text(mystery.fruit.primary(for: settings.language))
                        .font(AppTheme.TypeRole.body)
                        .foregroundStyle(palette.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PillButton(title: "Pray this decade", filled: false) {
                pendingMysteryPrayer = .fresh(mystery.set, intentionId: explicitLaunchIntentionId,
                                             startingDecade: mystery.number)
                selectedMysteryDetail = nil
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.vertical, AppTheme.Space.lg)
            .background(palette.bg)
        }
        .background(palette.bg)
    }

    private func mysteryDetailSheetHeight(for mystery: Mystery) -> CGFloat {
        let title = mystery.title.primary(for: settings.language)
        let excerpt = MysteryScripture.display(for: mystery, translation: settings.rosaryConfig.translation, language: settings.language)
        let titleLines = title.count > 28 ? 2 : 1
        let excerptLines = CGFloat(max(3, Int(ceil(Double(excerpt.count) / 42.0))))
        let estimated = 240 + CGFloat(titleLines * 40) + excerptLines * 25 + AppTheme.Component.pillHeight
        return dynamicTypeSize.isAccessibilitySize ? 640 : min(max(estimated, 460), 640)
    }

    private var upcomingMarian: [DatedFeast] {
        Array(
            FeastCatalog.upcoming(from: today, limit: 40)
                .filter(\.feast.isMarian)
                .prefix(3)
        )
    }

    private var weekDays: [(Date, MysteryAssignment)] {
        MysteryCalendar.week(containing: today)
    }



    private var upcomingMarianSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "Upcoming Marian feasts", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
            VStack(spacing: 0) {
                ForEach(Array(upcomingMarian.enumerated()), id: \.element.id) { index, item in
                    let isOpen = openFeastID == item.id
                    Button {
                        do {
                            openFeastID = isOpen ? nil : item.id
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: AppTheme.Space.lg) {
                                VStack(spacing: AppTheme.Space.xs) {
                                    Text(item.date.formatted(.dateTime.day()))
                                        .font(AppTheme.TypeRole.serifTitle)
                                        .foregroundStyle(palette.ink)
                                    Text(item.date.formatted(.dateTime.month(.abbreviated)))
                                        .font(AppTheme.TypeRole.caption(weight: .medium))
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                        .foregroundStyle(palette.faint)
                                }
                                .frame(width: 44)

                                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                                    Text(item.feast.shortTitle)
                                        .font(AppTheme.TypeRole.serifBody)
                                        .foregroundStyle(palette.ink)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.92)
                                    if Calendar.current.isDateInToday(item.date) {
                                        Text("Today")
                                            .font(AppTheme.TypeRole.caption(weight: .medium))
                                            .tracking(0.66)
                                            .textCase(.uppercase)
                                            .foregroundStyle(palette.todayPillText)
                                            .padding(.horizontal, AppTheme.Space.sm)
                                            .padding(.vertical, 3)
                                            .background(palette.todayPillFill, in: Capsule())
                                    }
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.down")
                                    .guideSymbol(size: 12, weight: .semibold)
                                    .foregroundStyle(palette.faint)
                                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                            }
                            .padding(.vertical, AppTheme.Space.md)

                            Text(item.feast.summary)
                                .font(AppTheme.TypeRole.serifBody)
                                .foregroundStyle(palette.dim)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, AppTheme.Space.lg)
                                // Keep text mounted and reveal its height without fading.
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxHeight: isOpen ? nil : 0, alignment: .top)
                                .clipped()
                                .accessibilityHidden(!isOpen)
                        }
                        .clipped()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .guideAccordion(isExpanded: isOpen)
                    if index < upcomingMarian.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
        }
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.element.0) { index, pair in
                    let day = pair.0
                    let dayAssignment = pair.1
                    Button {
                        selectedSet = dayAssignment.set
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.xs) {
                                Text(day.formatted(.dateTime.weekday(.wide)))
                                    .font(AppTheme.TypeRole.serifBody)
                                    .foregroundStyle(palette.ink)
                                if Calendar.current.isDateInToday(day) {
                                    Text("Today")
                                        .font(AppTheme.TypeRole.caption(weight: .medium))
                                        .tracking(0.66)
                                        .textCase(.uppercase)
                                        .foregroundStyle(palette.todayPillText)
                                        .padding(.horizontal, AppTheme.Space.sm)
                                        .padding(.vertical, 3)
                                        .background(palette.todayPillFill, in: Capsule())
                                }
                                if dayAssignment.feast != nil {
                                    Image(systemName: "crown.fill")
                                        .guideSymbol(size: 12, weight: .semibold, relativeTo: .caption)
                                        .foregroundStyle(palette.feastIndicator)
                                        .accessibilityLabel(dayAssignment.feast?.feast.name.english ?? "Feast")
                                }
                            }
                            Spacer(minLength: 8)
                            Text(dayAssignment.set.shortName)
                                .font(AppTheme.TypeRole.themeSummary)
                                .foregroundStyle(Calendar.current.isDateInToday(day) ? palette.ink : palette.dim)
                            Group {
                                if session.prayed(on: day) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .guideSymbol(size: 14, weight: .medium)
                                        .foregroundStyle(palette.dim)
                                        .accessibilityLabel("Prayed")
                                } else {
                                    Color.clear
                                        .frame(width: 16, height: 16)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(width: 20, alignment: .trailing)
                        }
                        .padding(.vertical, 15)
                    }
                    .guidePressable()
                    if index < weekDays.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
        }
    }
}

private struct PartialCardStroke: View {
    var edges: Edge.Set
    var radius: CGFloat
    var color: Color
    var lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Path { path in
                if edges.contains(.top) {
                    path.move(to: CGPoint(x: radius, y: lineWidth / 2))
                    path.addLine(to: CGPoint(x: size.width - radius, y: lineWidth / 2))
                }
                if edges.contains(.leading) {
                    path.move(to: CGPoint(x: lineWidth / 2, y: radius))
                    path.addLine(to: CGPoint(x: lineWidth / 2, y: size.height))
                }
                if edges.contains(.trailing) {
                    path.move(to: CGPoint(x: size.width - lineWidth / 2, y: radius))
                    path.addLine(to: CGPoint(x: size.width - lineWidth / 2, y: size.height))
                }
            }
            .stroke(color, lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
