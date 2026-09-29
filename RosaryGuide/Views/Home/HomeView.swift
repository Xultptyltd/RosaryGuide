import SwiftUI

struct HomeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(AppIconService.self) private var appIcon
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var prayLaunch: PrayLaunch?

    @State private var selectedSet: MysterySetKind?
    @State private var viewingTomorrow = false
    @State private var showMysterySelector = false
    @State private var showIntentionSheet = false
    @State private var chosenIntentionId: UUID?
    @State private var chosenIntentionTitle = ""
    @State private var chosenIntentionNote = ""
    @State private var intentionSelectionExplicit = false
    @State private var openFeastID: String?
    @State private var weekFeastInfo: DatedFeast?
    @State private var selectedMysteryDetail: Mystery?
    @State private var selectedLiturgicalVerse: LiturgicalVerse?
    @State private var scrollToTopRequest = 0
    @State private var showSettingsDrawer = false
    @State private var navigationPath = NavigationPath()
    @Namespace private var pickerNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var today: Date { Date() }
    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: today)
    }
    private var currentSet: MysterySetKind { selectedSet ?? assignment.set }
    private var mysteries: [Mystery] { MysteryCatalog.mysteries(for: currentSet) }
    private var currentIntention: OfferIntention? {
        if let chosenIntentionId {
            return offer.intention(id: chosenIntentionId)
        }
        if intentionSelectionExplicit {
            return nil
        }
        return offer.sortedIntentions.first(where: \.isPinned)
    }
    private var tomorrowAssignment: MysteryAssignment {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return MysteryCalendar.assignment(on: tomorrow)
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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            hero(topInset: topInset, viewport: viewport.height + topInset)
                                .frame(width: geo.size.width)
                                .id("home-top")
                            sheet(width: geo.size.width, gutter: AppTheme.gutter(for: geo.size.width))
                                .padding(.top, -36)
                                .frame(width: geo.size.width)
                        }
                        .frame(width: geo.size.width, alignment: .top)
                        .padding(.bottom, AppTheme.Space.xxl)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .onChange(of: scrollToTopRequest) { _, _ in
                        withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                            proxy.scrollTo("home-top", anchor: .top)
                        }
                    }
                }
            }
            .background(palette.bg)
            .ignoresSafeArea(edges: .top)
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { captureMetrics(geo) }
                    .onChange(of: geo.size) { _, _ in captureMetrics(geo) }
            }
        }
        .onAppear {
            if selectedSet == nil { selectedSet = assignment.set }
            syncCurrentIntentionIfNeeded()
        }
        .onChange(of: chosenIntentionId) { _, _ in
            intentionSelectionExplicit = true
        }
        .sheet(isPresented: $showMysterySelector) {
            mysterySelectorSheet
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
        .sheet(item: $weekFeastInfo) { item in
            weekFeastSheet(item)
                .presentationDetents([.height(weekFeastSheetHeight(for: item))])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.containerRadius)
        }
        .sheet(item: $selectedMysteryDetail) { mystery in
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
        .fullScreenCover(isPresented: $showSettingsDrawer) {
            HomeSettingsDrawer(isPresented: $showSettingsDrawer)
                .environment(settings)
                .environment(session)
                .environment(offer)
                .environment(appIcon)
                .environment(\.palette, palette)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }

    private func captureMetrics(_ geo: GeometryProxy) {
        viewport = geo.size
        topInset = geo.safeAreaInsets.top
    }

    private func hero(topInset: CGFloat, viewport: CGFloat) -> some View {
        ZStack(alignment: .top) {
            MysteryArtworkView(set: currentSet, kind: .heroTall)
                .frame(height: AppTheme.heroHeight(viewport: viewport) + topInset)
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
            HStack(spacing: 10) {
                menuButton
                Spacer(minLength: 0)
                glassTheme
            }
            .padding(.top, topInset + 12)
            .padding(.horizontal, 16)
        }
    }

    private var menuButton: some View {
        Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showSettingsDrawer = true
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .guideSymbol(size: 17, weight: .medium)
                .foregroundStyle(palette.ink)
                .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                .background(palette.panel.opacity(0.94), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Menu")
        .accessibilityHint("Opens settings")
    }

    private var glassTheme: some View {
        return Button {
            settings.toggleLightDark(systemIsDark: colorScheme == .dark)
        } label: {
            Label(colorScheme == .light ? "Day" : "Night", systemImage: colorScheme == .light ? "sun.max.fill" : "moon.fill")
                .labelStyle(.titleAndIcon)
                .font(AppTheme.sans(13, weight: .medium))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: AppTheme.Accessibility.minHitTarget)
                .background(palette.panel.opacity(0.94), in: Capsule())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel("Appearance")
        .accessibilityValue(colorScheme == .light ? "Day" : "Night")
    }

    private func sheet(width: CGFloat, gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(AppTheme.sans(14))
                .foregroundStyle(palette.dim)
                .padding(.bottom, AppTheme.Space.md)
                .guideReveal(delay: 0.02)

            GuideDisplayTitle(
                text: currentSet.name.primary(for: settings.language),
                size: AppTheme.homeTitleSize(width: width),
                color: palette.ink
            )
            .contentTransition(reduceMotion ? .identity : .opacity)
            .animation(reduceMotion ? nil : MotionTokens.selection, value: currentSet)

            Text(currentSet.themeSummary)
                .guideThemeSummaryStyle()
                .padding(.top, AppTheme.Space.md)
                .contentTransition(reduceMotion ? .identity : .opacity)
                .animation(reduceMotion ? nil : MotionTokens.selection, value: currentSet)
                .guideReveal(delay: 0.08)

            primaryTodayCTA
                .padding(.top, AppTheme.Space.xl)
                .guideReveal(delay: 0.1)

            tomorrowCard
                .padding(.top, AppTheme.Space.lg)
                .guideReveal(delay: 0.14)

            chooseAnotherButton
                .padding(.top, AppTheme.Space.sm)
                .guideReveal(delay: 0.16)

            mysteryRail(gutter: gutter)
                .padding(.top, AppTheme.decadesGap)

            liturgicalVerseSection
                .padding(.top, AppTheme.sectionGap)

            comingUpSection
                .padding(.top, AppTheme.sectionGap)

            weekGlance
                .padding(.top, AppTheme.sectionGap)
        }
        .padding(.horizontal, gutter)
        .padding(.top, AppTheme.Space.sm)
        .padding(.bottom, AppTheme.Space.xxl)
        .frame(maxWidth: 576, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private var mysterySelectorSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                    Text("Choose another mystery set")
                        .font(AppTheme.sans(28, weight: .regular))
                        .foregroundStyle(palette.ink)
                    Text("Today recommends the \(assignment.set.shortName) Mysteries, but you can begin any set.")
                        .font(AppTheme.sans(15))
                        .foregroundStyle(palette.dim)
                        .lineSpacing(4)

                    ForEach(MysterySetKind.displayOrder) { set in
                        Button {
                            HapticService.play(.light, enabled: settings.hapticsEnabled)
                            withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                                selectedSet = set
                                viewingTomorrow = false
                            }
                            showMysterySelector = false
                        } label: {
                            HStack(spacing: AppTheme.Space.md) {
                                MysteryArtworkView(set: set, mysteryNumber: 1, slug: MysteryCatalog.mysteries(for: set).first?.artSlug, kind: .plate)
                                    .frame(width: 82, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(set.name.primary(for: settings.language))
                                        .font(AppTheme.sans(19, weight: .semibold))
                                        .foregroundStyle(palette.ink)
                                    Text(set.days(in: assignment.season))
                                        .font(AppTheme.sans(13))
                                        .foregroundStyle(palette.dim)
                                }
                                Spacer(minLength: 8)
                                if currentSet == set {
                                    Image(systemName: "checkmark.circle.fill")
                                        .guideSymbol(size: 18, weight: .semibold)
                                        .foregroundStyle(palette.ink)
                                }
                            }
                            .padding(AppTheme.Space.md)
                            .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                                    .strokeBorder(
                                        palette.ink.opacity(colorScheme == .light ? 0.07 : 0.12),
                                        lineWidth: AppTheme.Component.panelStrokeWidth
                                    )
                            }
                            .guideSoftShadow(elevated: colorScheme == .light)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.gutter)
            }
            .background(palette.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showMysterySelector = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func syncCurrentIntentionIfNeeded() {
        guard chosenIntentionId == nil, chosenIntentionTitle.isEmpty else { return }
        guard let pinned = offer.sortedIntentions.first(where: \.isPinned) else { return }
        chosenIntentionId = pinned.id
        chosenIntentionTitle = pinned.title
        chosenIntentionNote = pinned.note ?? ""
        intentionSelectionExplicit = false
    }

    private var primaryTodayCTA: some View {
        PillButton(title: primaryPrayerTitle) {
            if let resumable = matchingResumableSession {
                prayLaunch = .resume(resumable)
            } else {
                prayLaunch = .fresh(currentSet, intentionId: chosenIntentionId ?? currentIntention?.id)
            }
        }
    }

    private var primaryPrayerTitle: String {
        if let resumable = matchingResumableSession {
            return resumable.continueCTATitle
        }
        return isShowingTodayMysteries ? "Pray today's mysteries" : "Pray the \(currentSet.shortName) Mysteries"
    }

    private var matchingResumableSession: PrayerSession? {
        guard let resumable = session.resumableSession, resumable.mysterySet == currentSet else { return nil }
        return resumable
    }

    private var chooseAnotherButton: some View {
        Button {
            showMysterySelector = true
        } label: {
            HStack(spacing: AppTheme.Space.md) {
                Text("Choose another mystery set")
                    .font(AppTheme.sans(14, weight: .medium))
                    .foregroundStyle(palette.accent)
                Spacer()
                Image(systemName: "circle.grid.3x3")
                    .guideSymbol(size: 13, weight: .medium)
                    .foregroundStyle(palette.accent)
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.vertical, AppTheme.Space.md)
        }
        .buttonStyle(.plain)
    }

    private var todayIntentionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Button {
                showIntentionSheet = true
            } label: {
                VStack(spacing: AppTheme.Space.md) {
                    HStack(alignment: .center, spacing: AppTheme.Space.md) {
                        ZStack {
                            IntentionIconView(
                                accent: currentIntention?.accent ?? .mintGreen,
                                emoji: currentIntention?.displayEmoji ?? "🙏",
                                size: 52
                            )
                        }
                        .frame(width: 52, height: 52)

                        Text("Offer this Rosary for")
                            .font(AppTheme.sans(21, weight: .semibold))
                            .foregroundStyle(palette.ink)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .guideSymbol(size: 12, weight: .semibold)
                            .foregroundStyle(palette.faint)
                    }

                    if let currentIntention {
                        Text(currentIntention.title)
                            .font(AppTheme.sans(17))
                            .foregroundStyle(palette.dim)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Space.lg)
                            .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                        HStack {
                            Text("Change intention")
                                .font(AppTheme.sans(14, weight: .medium))
                            Spacer()
                            Image(systemName: "pencil")
                                .guideSymbol(size: 13, weight: .medium)
                        }
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, AppTheme.Space.lg)
                        .padding(.vertical, AppTheme.Space.sm)
                    } else {
                        HStack {
                            Text("Add an intention")
                                .font(AppTheme.sans(14, weight: .medium))
                            Spacer()
                            Image(systemName: "plus")
                                .guideSymbol(size: 13, weight: .semibold)
                        }
                        .foregroundStyle(palette.ink)
                        .padding(AppTheme.Space.lg)
                        .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                        Text("You can also pray without a specific intention.")
                            .font(AppTheme.sans(13))
                            .foregroundStyle(palette.dim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(AppTheme.Space.lg)
                .guideCard(fill: palette.panel)
            }
            .buttonStyle(.plain)
        }
    }

    private var liturgicalVerseSection: some View {
        let verse = LiturgicalVerseCatalog.verse(for: today)
        return Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            selectedLiturgicalVerse = verse
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                Text("DAILY SCRIPTURE")
                    .font(AppTheme.TypeRole.sectionLabel)
                    .tracking(1.15)
                    .foregroundStyle(palette.dim)

                Text(verse.homeDisplayExcerpt)
                    .font(AppTheme.sans(18, relativeTo: .body))
                    .foregroundStyle(palette.dim)
                    .lineSpacing(6)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(verse.reference)
                            .font(AppTheme.sans(14, weight: .semibold, relativeTo: .subheadline))
                            .foregroundStyle(palette.ink)
                        if let secondaryCitation = verse.secondaryCitation {
                            Text(secondaryCitation)
                                .font(AppTheme.TypeRole.caption)
                                .foregroundStyle(palette.faint)
                        }
                    }
                    Spacer(minLength: AppTheme.Space.sm)
                    Image(systemName: "chevron.right")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.dim)
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
                Text("DAILY SCRIPTURE")
                    .font(AppTheme.TypeRole.sectionLabel)
                    .tracking(1.15)
                    .foregroundStyle(palette.dim)

                Text(verse.reference)
                    .font(AppTheme.sans(27, weight: .regular, relativeTo: .title2))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let secondaryCitation = verse.secondaryCitation {
                    Text(secondaryCitation)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.faint)
                }

                Text(verse.fullText)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.ink.opacity(0.86))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.Space.xl)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(palette.bg)
    }

    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            GuideSectionLabel(text: "Feast days", color: palette.dim)

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
        let dateLine = isToday
            ? "Today"
            : featured.date.formatted(.dateTime.day().month(.abbreviated))
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

                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        Text(dateLine)
                            .font(AppTheme.sans(12, weight: .medium))
                            .foregroundStyle(palette.dim)
                        Text(featured.feast.shortTitle)
                            .font(AppTheme.sans(24, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .lineLimit(3)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Space.xl)
                    .padding(.vertical, AppTheme.Space.xl)
                }
                .overlay {
                    if isToday {
                        // Soft brand-blue glow: strongest at the bottom, clear by mid-card.
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.50),
                                .init(color: palette.accent.opacity(colorScheme == .dark ? 0.14 : 0.08), location: 0.78),
                                .init(color: palette.accent.opacity(colorScheme == .dark ? 0.30 : 0.18), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)
                    }
                }
            }
            .buttonStyle(.plain)

            ForEach(remaining) { item in
                Hairline()
                NavigationLink {
                    FeastDetailView(prayLaunch: $prayLaunch, item: item)
                } label: {
                    HStack(spacing: AppTheme.Space.md) {
                        Text(item.date.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                            .font(AppTheme.sans(13, weight: .medium))
                            .foregroundStyle(palette.dim)
                            .frame(width: 62, alignment: .leading)
                        Text(item.feast.shortTitle)
                            .font(AppTheme.sans(17))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .guideSymbol(size: 11, weight: .semibold)
                            .foregroundStyle(palette.faint)
                    }
                    .padding(.horizontal, AppTheme.Space.xl)
                    .padding(.vertical, AppTheme.Space.md)
                }
                .buttonStyle(.plain)
            }
        }
        .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous)
                .strokeBorder(
                    palette.ink.opacity(colorScheme == .light ? 0.07 : 0.12),
                    lineWidth: AppTheme.Component.panelStrokeWidth
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
        .guideSoftShadow(elevated: colorScheme == .light)
    }

    private var tomorrowCard: some View {
        let cardSet = viewingTomorrow ? assignment.set : tomorrowAssignment.set
        let title = viewingTomorrow ? "Back to today" : "Tomorrow"
        let subtitle = viewingTomorrow ? "\(assignment.set.shortName) Mysteries" : "\(tomorrowAssignment.set.shortName) Mysteries"

        return Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                selectedSet = cardSet
                viewingTomorrow.toggle()
                scrollToTopRequest += 1
            }
        } label: {
            HStack(spacing: AppTheme.Space.md) {
                MysteryArtworkView(set: cardSet, mysteryNumber: 1, slug: MysteryCatalog.mysteries(for: cardSet).first?.artSlug, kind: .plate)
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTheme.sans(18, weight: .semibold))
                        .foregroundStyle(palette.ink)
                    Text(subtitle)
                        .font(AppTheme.sans(14))
                        .foregroundStyle(palette.dim)
                }
                Spacer()
                Image(systemName: viewingTomorrow ? "arrow.uturn.left" : "chevron.right")
                    .guideSymbol(size: 12, weight: .semibold)
                    .foregroundStyle(palette.faint)
                    .frame(width: 42, height: 42)
                    .background(palette.card, in: Circle())
            }
            .padding(AppTheme.Space.lg)
            .guideCard()
        }
        .buttonStyle(.plain)
    }

    private var weekGlance: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "This week", color: palette.dim)

            VStack(spacing: 0) {
                ForEach(Array(MysteryCalendar.week(containing: today).enumerated()), id: \.element.0) { index, entry in
                    let day = entry.0
                    let item = entry.1
                    weekRow(day: day, assignment: item)
                        .padding(.horizontal, AppTheme.Space.xl)

                    if index < MysteryCalendar.week(containing: today).count - 1 {
                        // Full-width under each day row (edge-to-edge inside the stroked calendar).
                        Divider()
                            .overlay(palette.hair)
                    }
                }
            }
            .padding(.vertical, AppTheme.Space.sm)
            // Subtle surface fill + outline stroke (matches mystery/feast card chrome).
            .guideCard(fill: palette.card.opacity(0.92), stroke: true)
        }
    }

    private func weekRow(day: Date, assignment: MysteryAssignment) -> some View {
        let prayed = session.prayed(on: day)
        let isToday = Calendar.current.isDateInToday(day)

        return HStack(alignment: .center, spacing: AppTheme.Space.md) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(AppTheme.sans(17))
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if isToday {
                    Text("TODAY")
                        .font(AppTheme.sans(9, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(palette.accentTint, in: Capsule())
                } else {
                    Text(day.formatted(.dateTime.day().month(.abbreviated)))
                        .font(AppTheme.sans(14))
                        .foregroundStyle(palette.dim)
                        .lineLimit(1)
                }

                if let feast = assignment.feast {
                    Button {
                        HapticService.play(.light, enabled: settings.hapticsEnabled)
                        weekFeastInfo = feast
                    } label: {
                        Image(systemName: "crown.fill")
                            .guideSymbol(size: 11, weight: .semibold)
                            .foregroundStyle(palette.accent)
                            .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Feast day")
                    .accessibilityValue(feast.feast.shortTitle)
                    .accessibilityHint("Shows feast details")
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Text(assignment.set.shortName)
                    .font(AppTheme.sans(16))
                    .foregroundStyle(palette.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if prayed {
                    Image(systemName: "checkmark.circle.fill")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.accent)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(minHeight: 50)
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
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .center, spacing: AppTheme.Space.sm) {
                Image(systemName: "crown.fill")
                    .guideSymbol(size: 14, weight: .semibold)
                    .foregroundStyle(palette.accent)
                Text(item.feast.rank.title.uppercased())
                    .font(AppTheme.sans(12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(palette.dim)
                    .offset(y: 1.5)
            }

            Text(item.feast.shortTitle)
                .font(AppTheme.sans(27, weight: .regular))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                .font(AppTheme.sans(14, weight: .medium))
                .foregroundStyle(palette.dim)

            Text(weekFeastDescription(for: item.feast))
                .font(AppTheme.sans(15))
                .lineSpacing(5)
                .foregroundStyle(palette.ink.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Space.xl)
        .padding(.top, AppTheme.Space.xxl)
        .padding(.bottom, AppTheme.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.bg)
    }

    private func weekFeastSheetHeight(for item: DatedFeast) -> CGFloat {
        let titleLines = item.feast.shortTitle.count > 34 ? 2 : 1
        let description = weekFeastDescription(for: item.feast)
        let descriptionLines = CGFloat(max(3, Int(ceil(Double(description.count) / 42.0))))
        let estimated = 162 + CGFloat(titleLines * 36) + (descriptionLines * 25)
        return min(max(estimated, 340), 520)
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

    private var quoteCard: some View {
        let quote = QuoteCatalog.quote(for: today)
        return VStack(spacing: AppTheme.Space.md) {
            Text("“")
                .font(AppTheme.sans(44, weight: .regular))
                .foregroundStyle(palette.accent.opacity(colorScheme == .light ? 0.26 : 0.42))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
            Text("“\(quote.text)”")
                .font(AppTheme.sans(16))
                .foregroundStyle(palette.dim)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Text(quote.attribution.uppercased())
                .font(AppTheme.sans(10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(palette.faint)
        }
        .padding(AppTheme.Space.xl)
        .guideCard()
    }

    private func weekDotColor(_ set: MysterySetKind) -> Color {
        switch set {
        case .joyful: Color(hex: 0x1E1A15)
        case .luminous: Color(hex: 0xEDC68D)
        case .sorrowful: Color(hex: 0xDFA05D)
        case .glorious: Color(hex: 0xD19A12)
        }
    }

    private func feastOffer(_ feast: DatedFeast) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GuideSectionLabel(text: "Today", color: palette.dim)
            Text(feast.feast.name.primary(for: settings.language))
                .font(AppTheme.sans(21, weight: .semibold))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let suggested = feast.feast.suggestedMysterySet, suggested != assignment.set {
                Text("The calendar keeps the \(assignment.set.shortName) Mysteries. You can pray the \(suggested.shortName) Mysteries for this feast instead.")
                    .font(AppTheme.sans(14))
                    .foregroundStyle(palette.dim)
                    .lineSpacing(4)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var setPicker: some View {
        HStack(spacing: 2) {
            ForEach(MysterySetKind.displayOrder) { set in
                Button {
                    HapticService.play(.light, enabled: settings.hapticsEnabled)
                    withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                        selectedSet = set
                        viewingTomorrow = false
                    }
                } label: {
                    Text(set.shortName)
                        .font(AppTheme.sans(13, weight: .semibold))
                        .foregroundStyle(pickerInk(for: set))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Space.md)
                        .background {
                            if currentSet == set {
                                Capsule()
                                    .fill(pickerFill)
                                    .matchedGeometryEffect(id: "pickerGlow", in: pickerNamespace)
                                    .guideSoftShadow(elevated: true)
                            }
                        }
                        .overlay(alignment: .top) {
                            if set == assignment.set {
                                Circle()
                                    .fill(currentSet == set ? pickerInk(for: set) : palette.faint)
                                    .frame(width: 3, height: 3)
                                    .offset(y: 5)
                            }
                        }
                }
                .guidePressable()
                .accessibilityAddTraits(currentSet == set ? .isSelected : [])
            }
        }
        .padding(3)
        .background(colorScheme == .light ? palette.card2 : palette.card, in: Capsule())
        .guideSoftShadow(elevated: colorScheme == .light)
    }

    private func pickerInk(for set: MysterySetKind) -> Color {
        guard currentSet == set else { return palette.dim }
        return colorScheme == .light ? Color.black : palette.ink
    }

    private var pickerFill: Color {
        colorScheme == .light ? .white : palette.card2
    }


    private var ctaStack: some View {
        let resumable = session.resumableSession
        let sameSet = resumable?.mysterySet == currentSet

        return VStack(spacing: AppTheme.Space.md) {
            PillButton(title: primaryCTATitle(resumable: resumable, sameSet: sameSet)) {
                primaryCTAAction(resumable: resumable, sameSet: sameSet)
            }

            if resumable != nil {
                PillButton(
                    title: secondaryCTATitle(resumable: resumable!, sameSet: sameSet),
                    filled: false
                ) {
                    secondaryCTAAction(resumable: resumable!, sameSet: sameSet)
                }
            }
        }
    }

    private func primaryCTATitle(resumable: PrayerSession?, sameSet: Bool) -> String {
        guard let resumable else {
            return isShowingTodayMysteries ? "Pray today's mysteries" : "Pray the \(currentSet.shortName)"
        }
        if sameSet { return resumable.continueCTATitle }
        return "Pray the \(currentSet.shortName)"
    }

    private func primaryCTAAction(resumable: PrayerSession?, sameSet: Bool) {
        if let resumable, sameSet {
            prayLaunch = .resume(resumable)
        } else {
            prayLaunch = .fresh(currentSet)
        }
    }

    private func secondaryCTATitle(resumable: PrayerSession, sameSet: Bool) -> String {
        if sameSet { return "Start from beginning" }
        return "Continue the \(resumable.mysterySet.shortName)"
    }

    private func secondaryCTAAction(resumable: PrayerSession, sameSet: Bool) {
        if sameSet {
            session.discard()
            prayLaunch = .fresh(currentSet)
        } else {
            prayLaunch = .resume(resumable)
        }
    }

    private func mysteryRail(gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: mysteryRailTitle, color: palette.dim)
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
                    .padding(.vertical, 4)
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .frame(width: geo.size.width)
                .clipped()
            }
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 520 : 356)
            .padding(.horizontal, -gutter)
        }
    }

    private var mysteryRailTitle: String {
        isShowingTodayMysteries ? "Today's mysteries" : currentSet.name.primary(for: settings.language)
    }

    private var isShowingTodayMysteries: Bool {
        currentSet == assignment.set && !viewingTomorrow
    }

    private func mysteryCard(_ mystery: Mystery) -> some View {
        Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            selectedMysteryDetail = mystery
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                MysteryArtworkView(set: mystery.set, mysteryNumber: mystery.number, slug: mystery.artSlug, kind: .plate, bottomFade: false)
                    .frame(height: 168)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    Text(mystery.title.primary(for: settings.language))
                        .font(AppTheme.sans(22, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, AppTheme.Space.sm)
                        .padding(.horizontal, AppTheme.Space.xl)

                    VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                        // Full-width under title (edge-to-edge inside the stroked card).
                        Hairline()
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                            Text("Fruit")
                                .font(AppTheme.TypeRole.caption)
                                .foregroundStyle(palette.faint)
                            Text(mystery.fruit.primary(for: settings.language))
                                .font(AppTheme.TypeRole.caption)
                                .foregroundStyle(palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppTheme.Space.xl)
                    }
                    .padding(.top, AppTheme.Space.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                .padding(.top, AppTheme.Space.lg)
                .padding(.bottom, AppTheme.Space.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 336, alignment: .top)
            .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous)
                    .strokeBorder(
                        palette.ink.opacity(colorScheme == .light ? 0.07 : 0.12),
                        lineWidth: AppTheme.Component.panelStrokeWidth
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
            .guideSoftShadow(elevated: colorScheme == .light)
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mysteryAccessibilityLabel(mystery))
        .accessibilityHint("Shows mystery details and fruit")
    }

    private func mysteryAccessibilityLabel(_ mystery: Mystery) -> String {
        "Mystery \(mystery.number), \(mystery.title.primary(for: settings.language)). Fruit, \(mystery.fruit.primary(for: settings.language))."
    }

    private func mysteryDetailSheet(_ mystery: Mystery) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                HStack(alignment: .center, spacing: AppTheme.Space.sm) {
                    Text(mystery.set.shortName.uppercased())
                        .font(AppTheme.sans(12, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(palette.dim)
                        .offset(y: 1.5)
                }

                Text(mystery.title.primary(for: settings.language))
                    .font(AppTheme.sans(27, weight: .regular))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(mystery.scriptureExcerpt.primary(for: settings.language))
                        .font(AppTheme.sans(15))
                        .lineSpacing(5)
                        .foregroundStyle(palette.ink.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mystery.scriptureReference)
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(palette.faint)
                }

                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Hairline()
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                        Text("Fruit")
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.faint)
                        Text(mystery.fruit.primary(for: settings.language))
                            .font(AppTheme.sans(15, weight: .medium))
                            .foregroundStyle(palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.Space.xl)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(palette.bg)
    }

    private func mysteryDetailSheetHeight(for mystery: Mystery) -> CGFloat {
        let title = mystery.title.primary(for: settings.language)
        let excerpt = mystery.scriptureExcerpt.primary(for: settings.language)
        let titleLines = title.count > 28 ? 2 : 1
        let excerptLines = CGFloat(max(3, Int(ceil(Double(excerpt.count) / 42.0))))
        let estimated = 168 + CGFloat(titleLines * 36) + (excerptLines * 25) + 72
        return min(max(estimated, 360), 560)
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
            GuideSectionLabel(text: "Upcoming Marian feasts", color: palette.dim)
                .padding(.bottom, AppTheme.Space.lg)
            VStack(spacing: 0) {
                ForEach(Array(upcomingMarian.enumerated()), id: \.element.id) { index, item in
                    let isOpen = openFeastID == item.id
                    Button {
                        withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                            openFeastID = isOpen ? nil : item.id
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: 16) {
                                VStack(spacing: 3) {
                                    Text(item.date.formatted(.dateTime.day()))
                                        .font(AppTheme.serif(24, opticalSize: 34))
                                        .foregroundStyle(palette.ink)
                                    Text(item.date.formatted(.dateTime.month(.abbreviated)))
                                        .font(AppTheme.sans(10, weight: .medium))
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                        .foregroundStyle(palette.faint)
                                }
                                .frame(width: 44)

                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(item.feast.shortTitle)
                                        .font(AppTheme.serif(17, opticalSize: 26))
                                        .foregroundStyle(palette.ink)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.92)
                                    if Calendar.current.isDateInToday(item.date) {
                                        Text("Today")
                                            .font(AppTheme.sans(11, weight: .medium))
                                            .tracking(0.66)
                                            .textCase(.uppercase)
                                            .foregroundStyle(palette.onAccent)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(palette.accent, in: Capsule())
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
                                .font(AppTheme.serif(16, opticalSize: 16))
                                .foregroundStyle(palette.dim)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, AppTheme.Space.lg)
                                // Keep in the hierarchy and clip height so collapse fades
                                // in place instead of sliding the copy up under the title.
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxHeight: isOpen ? nil : 0, alignment: .top)
                                .opacity(isOpen ? 1 : 0)
                                .clipped()
                                .accessibilityHidden(!isOpen)
                        }
                        .clipped()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < upcomingMarian.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.panel)
        }
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "This week", color: palette.dim)
                .padding(.bottom, AppTheme.Space.lg)
            VStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.element.0) { index, pair in
                    let day = pair.0
                    let dayAssignment = pair.1
                    Button {
                        selectedSet = dayAssignment.set
                        viewingTomorrow = false
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(day.formatted(.dateTime.weekday(.wide)))
                                    .font(AppTheme.serif(18, opticalSize: 28))
                                    .foregroundStyle(palette.ink)
                                if Calendar.current.isDateInToday(day) {
                                    Text("Today")
                                        .font(AppTheme.sans(11, weight: .medium))
                                        .tracking(0.66)
                                        .textCase(.uppercase)
                                        .foregroundStyle(palette.onAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(palette.accent, in: Capsule())
                                }
                                if dayAssignment.feast != nil {
                                    Image(systemName: "crown.fill")
                                        .guideSymbol(size: 12, weight: .semibold, relativeTo: .caption)
                                        .foregroundStyle(Color(hex: colorScheme == .light ? 0xC4922C : 0xE2B75A))
                                        .accessibilityLabel(dayAssignment.feast?.feast.name.english ?? "Feast")
                                }
                            }
                            Spacer(minLength: 8)
                            Text(dayAssignment.set.shortName)
                                .font(AppTheme.sans(15))
                                .foregroundStyle(Calendar.current.isDateInToday(day) ? palette.ink : palette.dim)
                            Group {
                                if session.prayed(on: day) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .guideSymbol(size: 14, weight: .medium)
                                        .foregroundStyle(palette.dim)
                                        .accessibilityLabel("Prayed")
                                } else {
                                    Color.clear
                                        .frame(width: 14, height: 14)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(width: 18, alignment: .trailing)
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
            .guideCard(radius: AppTheme.containerRadius, fill: palette.panel)
        }
    }
}
