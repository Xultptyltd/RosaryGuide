import SwiftUI

struct PrayHubView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Binding var prayLaunch: PrayLaunch?
    @State private var debugShowsRosaryPrayers = false
    @State private var searchText = ""
    @State private var showingWalkthrough = false
    @State private var expandedQuestion: LearnArticle?
    @State private var navigationPath = NavigationPath()
    @State private var pageGutter: CGFloat = AppTheme.gutter
    @Environment(DayClock.self) private var dayClock
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: dayClock.today)
    }
    /// Matches Home: a feast's recommended set unless the weekday set was chosen today.
    private var todaysSet: MysterySetKind {
        assignment.defaultSet(prefersWeekday: dayClock.prefersWeekdaySet)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    searchField
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        introCard
                            .padding(.top, AppTheme.Space.xl)
                        GuideSectionBoundary(gutter: pageGutter)
                        mysteryTilesSection
                        GuideSectionBoundary(gutter: pageGutter)
                        prayersTilesSection.id("pray-prayers")
                        if DevotionCatalog.isEnabled {
                            GuideSectionBoundary(gutter: pageGutter, verticalSpacing: 0)
                            devotionTilesSection
                        }
                        GuideSectionBoundary(gutter: pageGutter)

                        questionsSection
                        GuideSectionBoundary(gutter: pageGutter)
                        prayTodayCard
                    } else {
                        searchResults
                            .padding(.top, AppTheme.Space.xl)
                    }
                }
                .padding(.horizontal, pageGutter)
                .padding(.top, GuideRootChrome.contentTop)
                .padding(.bottom, 108)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { pageGutter = AppTheme.gutter(for: proxy.size.width) }
                            .onChange(of: proxy.size.width) { _, w in pageGutter = AppTheme.gutter(for: w) }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            #if DEBUG
            // `-RGDebugRosaryPrayers`: opens Rosary prayers for screenshots.
            .navigationDestination(isPresented: $debugShowsRosaryPrayers) { rosaryPrayersPage }
            .task {
                guard DebugHooks.has("-RGDebugRosaryPrayers") else { return }
                try? await Task.sleep(for: .seconds(2))
                debugShowsRosaryPrayers = true
            }
            // `-RGDebugPrayPrayers`: scrolls to the Prayers tiles for screenshots.
            .task {
                guard DebugHooks.has("-RGDebugPrayPrayers") else { return }
                try? await Task.sleep(for: .seconds(3))
                scrollProxy.scrollTo("pray-prayers", anchor: .center)
            }
            #endif
            }
            .guideRootChrome("Pray")
            .fullScreenCover(isPresented: $showingWalkthrough) {
                RosaryWalkthroughView(onClose: { showingWalkthrough = false })
            }
        }
    }

    private var allPrayers: [Prayer] {
        [PrayerCatalog.signOfTheCross, PrayerCatalog.apostlesCreed, PrayerCatalog.ourFather,
         PrayerCatalog.hailMary, PrayerCatalog.gloryBe, PrayerCatalog.hailHolyQueen,
         PrayerCatalog.concluding, PrayerCatalog.fatima, PrayerCatalog.sacramentMostHoly,
         PrayerCatalog.memorare, PrayerCatalog.saintMichael] + PrayerCatalog.additionalLibraryPrayers
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Space.md) {
            Image(systemName: "magnifyingglass").foregroundStyle(palette.dim)
            // The prompt carries the font so the placeholder scales with Dynamic Type too.
            TextField(
                "Search prayers and mysteries",
                text: $searchText,
                prompt: Text(dynamicTypeSize.isAccessibilitySize ? "Search" : "Search prayers and mysteries")
                    .font(AppTheme.TypeRole.bodySmall)
            )
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.ink)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(palette.dim)
                    .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .frame(minHeight: AppTheme.Component.pillHeight)
        .background(palette.surface, in: Capsule())
        .overlay { Capsule().stroke(palette.hair, lineWidth: 1) }
    }

    private var rosaryPrayersPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xxl) {
                rosaryPrayerGroup("Opening prayers", detail: "Begin on the crucifix and introductory beads.", rows: [
                    (PrayerCatalog.signOfTheCross, nil), (PrayerCatalog.apostlesCreed, nil),
                    (PrayerCatalog.ourFather, nil), (PrayerCatalog.hailMary, 3), (PrayerCatalog.gloryBe, nil)
                ])
                rosaryPrayerGroup("Each decade", detail: "Repeat for each of the five mysteries.", rows: [
                    (PrayerCatalog.ourFather, nil), (PrayerCatalog.hailMary, 10),
                    (PrayerCatalog.gloryBe, nil), (PrayerCatalog.fatima, nil)
                ])
                // Same closing sequence as the Rosary flow.
                rosaryPrayerGroup("Closing prayers", detail: "After the fifth decade.", rows: [
                    (PrayerCatalog.hailHolyQueen, nil), (PrayerCatalog.versicle, nil),
                    (PrayerCatalog.concluding, nil), (PrayerCatalog.signOfTheCross, nil)
                ])
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.tabBarContentClearance)
        }
        .background(palette.bg)
        .guideDetailChrome("Rosary prayers")
    }

    /// Heading, one-line caption, then an inset card of prayer rows.
    private func rosaryPrayerGroup(_ title: String, detail: String, rows: [(Prayer, Int?)]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
            GuideSectionLabel(text: title, prominence: .strong)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    NavigationLink { LearnPrayerDetailView(prayer: row.0) } label: {
                        HStack(spacing: AppTheme.Space.sm) {
                            Text(row.0.title.primary(for: settings.language))
                                .font(AppTheme.TypeRole.bodySmall)
                                .foregroundStyle(palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let count = row.1 {
                                Text("×\(count)")
                                    .font(AppTheme.TypeRole.bodySmall)
                                    .foregroundStyle(palette.dim)
                                    .accessibilityLabel("\(count) times")
                            }
                            Image(systemName: "chevron.right")
                                .guideSymbol(size: 12, weight: .regular)
                                .foregroundStyle(palette.secondaryText)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, AppTheme.Space.lg)
                        .padding(.vertical, AppTheme.Space.md)
                        .frame(minHeight: AppTheme.Accessibility.minHitTarget + AppTheme.Space.sm)
                        .contentShape(Rectangle())
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                    if index < rows.count - 1 { Hairline().padding(.leading, AppTheme.Space.lg) }
                }
            }
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
            .padding(.top, AppTheme.Space.sm)
        }
    }

    /// The four sets as tiles, in the feast-day mystery tile format.
    private var mysteryTilesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "The mysteries", prominence: .strong)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: AppTheme.Space.md) {
                ForEach(MysterySetKind.displayOrder, id: \.self) { set in
                    NavigationLink {
                        LearnMysteryDetailView(set: set, prayLaunch: $prayLaunch)
                    } label: {
                        learnTile(caption: set.weekdayCaption, title: "\(set.shortName) Mysteries", set: set, mysteryNumber: 1)
                    }
                    .buttonStyle(.plain)
                    .guidePressable()
                }
            }
        }
    }

    private var devotionTilesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Novenas & Rosary types", prominence: .strong)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: AppTheme.Space.md) {
                ForEach(DevotionCatalog.all) { devotion in
                    NavigationLink {
                        DevotionDetailView(devotion: devotion, prayLaunch: $prayLaunch)
                    } label: {
                        learnTile(caption: devotion.eyebrow, title: devotion.title, set: devotion.artSet, mysteryNumber: devotion.artMystery)
                    }
                    .buttonStyle(.plain)
                    .guidePressable()
                }
            }
        }
    }

    private func learnTile(caption: String, title: String, set: MysterySetKind, mysteryNumber: Int) -> some View {
        return HStack(alignment: .center, spacing: AppTheme.Space.md) {
            MysterySetIcon(set: set, size: 56)

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title)
                    .font(AppTheme.TypeRole.body(weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caption)
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .guideSymbol(size: 12, weight: .regular)
                .foregroundStyle(palette.dim)
                .accessibilityHidden(true)
        }
        .padding(AppTheme.Space.lg)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// "Prayers": two equal tiles side by side; stacked at accessibility sizes.
    private var prayersTilesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Prayers", prominence: .strong)
                .accessibilityAddTraits(.isHeader)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: AppTheme.Space.md))
                : AnyLayout(HStackLayout(alignment: .top, spacing: AppTheme.Space.md))
            layout {
                NavigationLink { rosaryPrayersPage } label: {
                    prayerTile(title: "Rosary prayers", subtitle: "Prayers used in the Rosary", icon: "PrayerIconRosary")
                }
                .buttonStyle(.plain).guidePressable()
                NavigationLink { libraryPage } label: {
                    prayerTile(title: "All prayers", subtitle: "Explore the full collection", icon: "PrayerIconAllPrayers")
                }
                .buttonStyle(.plain).guidePressable()
            }
        }
    }

    private func prayerTile(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36, alignment: .leading)
                .foregroundStyle(palette.accentText)
                .accessibilityHidden(true)
            Spacer(minLength: AppTheme.Space.sm)
            Text(title)
                .font(AppTheme.TypeRole.body(weight: .semibold))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .bottom, spacing: AppTheme.Space.sm) {
                Text(subtitle)
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .guideSymbol(size: 12, weight: .regular)
                    .foregroundStyle(palette.dim)
                    .accessibilityHidden(true)
            }
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var libraryPage: some View {
        AllPrayersView(prayers: allPrayers)
    }

    private var searchResults: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let prayers = allPrayers.filter { PrayerCatalog.matchesSearch($0, query: query) }
        let sets = MysterySetKind.displayOrder.filter { "\($0.shortName) Mysteries".localizedCaseInsensitiveContains(query) }
        let devotions = !DevotionCatalog.isEnabled ? [] : DevotionCatalog.all.filter { DevotionCatalog.matchesSearch($0, query: query) }
        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            if prayers.isEmpty && sets.isEmpty && devotions.isEmpty {
                Text("No prayers or mysteries found. Try another search.")
                    .font(AppTheme.TypeRole.bodySmall).foregroundStyle(palette.dim)
            }
            ForEach(prayers) { prayer in prayerNavRow(prayer: prayer); Hairline() }
            ForEach(sets, id: \.self) { set in
                NavigationLink { LearnMysteryDetailView(set: set, prayLaunch: $prayLaunch) } label: {
                    hubRow("\(set.shortName) Mysteries", detail: set.weekdayNames, symbol: "sparkles")
                }.guidePressable()
            }
            ForEach(devotions) { devotion in
                NavigationLink { DevotionDetailView(devotion: devotion, prayLaunch: $prayLaunch) } label: {
                    hubRow(devotion.title, detail: devotion.eyebrow, symbol: "book.closed")
                }.guidePressable()
            }
        }
    }

    private var rosaryFeature: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(session.resumableSession == nil ? "The Rosary" : "Resume your Rosary")
                        .font(AppTheme.TypeRole.headingPrimary).foregroundStyle(palette.ink)
                    Text("Meditate on the life of Jesus with Mary")
                        .font(AppTheme.TypeRole.bodySmall).foregroundStyle(palette.dim)
                }
                Spacer(minLength: 0)
                MysterySetIcon(set: todaysSet)
            }
            PillButton(title: session.resumableSession?.continueCTATitle ?? "Pray the Rosary") {
                HapticService.play(.medium, enabled: settings.hapticsEnabled)
                if let resumable = session.resumableSession { prayLaunch = .resume(resumable) }
                else { prayLaunch = .fresh(todaysSet) }
            }
        }
        .padding(AppTheme.Space.xl)
        .guideCard(fill: palette.surface)
    }

    private func hubRow(_ title: String, detail: String?, symbol: String, showsIcon: Bool = true, endsSection: Bool = false) -> some View {
        HStack(spacing: AppTheme.Space.md) {
            if showsIcon {
                Image(systemName: symbol)
                .guideSymbol(size: 24, weight: .regular)
                .foregroundStyle(palette.accentText)
                .frame(width: 52, height: 52)
                .background(palette.accentTint, in: Circle())
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(AppTheme.TypeRole.bodySmall).foregroundStyle(palette.ink)
                if let detail { Text(detail).font(AppTheme.TypeRole.caption).foregroundStyle(palette.dim) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").guideSymbol(size: 12, weight: .regular).foregroundStyle(palette.dim)
        }
        .frame(minHeight: endsSection ? 0 : 52)
        .padding(.top, AppTheme.Space.lg)
        .padding(.bottom, endsSection ? 0 : AppTheme.Space.lg)
        .contentShape(Rectangle())
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                Text("Introduction to the Rosary")
                    .font(AppTheme.TypeRole.headingPrimary)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Decorative; dropped at accessibility sizes so the title keeps whole words.
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "book.closed")
                        .guideSymbol(size: 30, weight: .medium)
                        .foregroundStyle(palette.accentText)
                        .frame(width: 56, height: 56)
                        .background(palette.accentTint, in: Circle())
                        .accessibilityHidden(true)
                }
            }

            Text("Prayers, mysteries and how to pray")
                .font(AppTheme.TypeRole.callout)
                .lineSpacing(5)
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showingWalkthrough = true
            } label: {
                HStack {
                    Text("Begin walkthrough")
                        .font(AppTheme.TypeRole.pillLabel(weight: .semibold))
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(palette.primaryButtonText)
                .padding(.horizontal, AppTheme.Space.lg)
                .multilineTextAlignment(.center)
                .frame(height: AppTheme.Component.pillHeight)
                .background(palette.primaryButtonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
        }
        .padding(AppTheme.Space.xl)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
    }

    private var prayersSection: some View {
        let prayers: [Prayer] = [
            PrayerCatalog.signOfTheCross,
            PrayerCatalog.apostlesCreed,
            PrayerCatalog.ourFather,
            PrayerCatalog.hailMary,
            PrayerCatalog.gloryBe,
            PrayerCatalog.hailHolyQueen,
            PrayerCatalog.concluding
        ]

        return VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Rosary prayers", prominence: .strong)

            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                    prayerNavRow(prayer: prayer)
                        .learnLastRowTrim(index == prayers.count - 1)

                    if index < prayers.count - 1 {
                        Hairline()
                    }
                }
            }
            // Same flat list as The mysteries (no surface).
            .guideNavList(pageGutter: pageGutter)
        }
    }

    private var optionalPrayersSection: some View {
        let prayers: [Prayer] = [
            PrayerCatalog.fatima,
            PrayerCatalog.sacramentMostHoly,
            PrayerCatalog.memorare,
            PrayerCatalog.saintMichael
        ]

        return VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Optional prayers", prominence: .strong)

            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                    prayerNavRow(prayer: prayer)
                        .learnLastRowTrim(index == prayers.count - 1)

                    if index < prayers.count - 1 {
                        Hairline()
                    }
                }
            }
            // Same flat list as The mysteries (no surface).
            .guideNavList(pageGutter: pageGutter)
        }
    }

    private var mysteriesSection: some View {
        learnSection(title: "The mysteries", rows: MysterySetKind.displayOrder.map { set in
            LearnRow(
                mysterySet: set,
                title: "\(set.shortName) Mysteries",
                detail: set.weekdayNames,
                destination: .mystery(set)
            )
        })
    }

    private var questionsSection: some View {
        let questions: [LearnArticle] = [.whatIsRosary, .beads, .oneDecade, .losePlace, .repetition, .mary]

        return VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Common questions", prominence: .strong)

            VStack(spacing: 0) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, article in
                    questionAccordionRow(article)

                    if index < questions.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideRowGroup()
        }
    }

    private var prayTodayCard: some View {
        let resumable = session.resumableSession
        let cta = resumable?.continueCTATitle ?? "Pray today’s Rosary"

        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Text(resumable == nil ? todaysSet.displayTitle : "Resume your Rosary")
                .font(AppTheme.TypeRole.cardTitle)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(resumable == nil ? "Pray today’s mysteries" : "Pick up where you left off")
                .font(AppTheme.TypeRole.themeSummary)
                .lineSpacing(5)
                .foregroundStyle(palette.dim)

            Button {
                HapticService.play(.medium, enabled: settings.hapticsEnabled)
                if let resumable {
                    prayLaunch = .resume(resumable)
                } else {
                    prayLaunch = .fresh(todaysSet)
                }
            } label: {
                HStack {
                    Text(cta)
                        .font(AppTheme.TypeRole.pillLabel(weight: .semibold))
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(palette.secondaryButtonText)
                .padding(.horizontal, AppTheme.Space.lg)
                .multilineTextAlignment(.center)
                .frame(height: AppTheme.Component.pillHeight)
                .background(palette.secondaryButtonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
            .padding(.top, AppTheme.Space.xs)
        }
        .padding(AppTheme.Space.xl)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
    }

    private func learnSection(title: String, rows: [LearnRow]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: title, prominence: .strong)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    NavigationLink {
                        destination(for: row.destination)
                    } label: {
                        learnRow(row)
                    }
                    .guidePressable()
                    .learnLastRowTrim(index == rows.count - 1)

                    if index < rows.count - 1 {
                        Hairline().padding(.leading, 44 + AppTheme.Space.md)
                    }
                }
            }
            .guideNavList(pageGutter: pageGutter)
        }
    }

    private func prayerNavRow(prayer: Prayer, endsSection: Bool = false) -> some View {
        NavigationLink {
            LearnPrayerDetailView(prayer: prayer)
        } label: {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(prayer.title.primary(for: settings.language))
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    // Experiment: captions hidden. Restore by rendering wherePrayerAppears(prayer)
                    // here (TypeRole.label, palette.dim); the caption data is kept below.
                }

                Spacer(minLength: AppTheme.Space.sm)

                // Same chevron as Settings navigation rows.
                Image(systemName: "chevron.right")
                    .guideSymbol(size: 12, weight: .regular)
                    .foregroundStyle(palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.top, AppTheme.Space.xl)
            .padding(.bottom, endsSection ? 0 : AppTheme.Space.xl)
            .frame(minHeight: endsSection ? AppTheme.Accessibility.minHitTarget : 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func wherePrayerAppears(_ prayer: Prayer) -> String {
        switch prayer.id {
        case "sign-of-the-cross": "Start and end"
        case "apostles-creed": "On the crucifix, at the start"
        case "our-father": "Start of each decade"
        case "hail-mary": "Ten times each decade"
        case "glory-be": "End of each decade"
        case "fatima": "After each Glory be"
        case "hail-holy-queen": "After the last decade"
        case "concluding": "Closes the Rosary"
        case "sacrament-most-holy": "After the Fatima prayer"
        case "memorare": "After the Rosary"
        case "saint-michael": "After the Rosary"
        default: ""
        }
    }

    private func questionAccordionRow(_ article: LearnArticle) -> some View {
        let isOpen = expandedQuestion == article

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedQuestion = isOpen ? nil : article
            } label: {
                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    Text(article.title)
                        .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(AppTheme.TypeRole.caption(weight: .semibold))
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.vertical, AppTheme.Space.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(article.title)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Collapses answer" : "Expands answer")

            if isOpen {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    ForEach(article.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(AppTheme.TypeRole.callout)
                            .lineSpacing(5)
                            .foregroundStyle(palette.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.trailing, AppTheme.Space.sm)
                .padding(.bottom, AppTheme.Space.xl)
                    .transition(MotionTokens.accordionTransition)
            }
        }
        .guideAccordion(isExpanded: isOpen)
    }

    @ViewBuilder
    private func destination(for destination: LearnDestination) -> some View {
        switch destination {
        case .walkthrough:
            HowToPrayView()
        case .article(let article):
            LearnArticleView(article: article)
        case .prayer(let prayer):
            LearnPrayerDetailView(prayer: prayer)
        case .mystery(let set):
            LearnMysteryDetailView(set: set, prayLaunch: $prayLaunch)
        }
    }

    private func learnRow(_ row: LearnRow) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Space.md) {
            MysterySetIcon(set: row.mysterySet)

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(row.title)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(row.detail)
                    .font(AppTheme.TypeRole.label)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .guideSymbol(size: 12, weight: .regular)
                .foregroundStyle(palette.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppTheme.Space.lg)
        .contentShape(Rectangle())
    }
}

private extension View {
    /// Last row of a flat Learn list: trims its bottom padding so the row-to-divider gap
    /// matches Settings' last nav row (~33pt text to divider band).
    func learnLastRowTrim(_ isLast: Bool) -> some View {
        padding(.bottom, isLast ? -AppTheme.Space.md : 0)
    }
}

private struct LearnRow: Identifiable {
    let id = UUID()
    var mysterySet: MysterySetKind
    var title: String
    var detail: String
    var destination: LearnDestination
}

private enum LearnDestination {
    case walkthrough
    case article(LearnArticle)
    case prayer(Prayer)
    case mystery(MysterySetKind)
}

private enum LearnArticle: String, Identifiable {
    case whatIsRosary
    case beads
    case oneDecade
    case losePlace
    case repetition
    case mary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .whatIsRosary: "What is the Rosary?"
        case .beads: "Do I need beads?"
        case .oneDecade: "Can I pray one decade?"
        case .losePlace: "What if I lose my place?"
        case .repetition: "Why repeat prayers?"
        case .mary: "Why pray with Mary?"
        }
    }

    var eyebrow: String {
        switch self {
        case .whatIsRosary: "Start here"
        default: "Common question"
        }
    }

    var paragraphs: [String] {
        switch self {
        case .whatIsRosary:
            [
                "The Rosary is the Gospel story told in prayer. Each decade honours a mystery in the life of Our Lord and His Blessed Mother.",
                "A decade is one Our Father, ten Hail Marys and one Glory be. Five decades are usually prayed together, meditating on one set of mysteries.",
                "Our Lady has often asked us to pray it against evil. United with her, we ask for the conversion of hearts and peace in the world."
            ]
        case .beads:
            [
                "Rosary beads help your fingers keep the place so your mind can pray. They are useful, but they are not required.",
                "You can pray with beads, with your fingers, by following the app step by step, or by praying one decade slowly from memory.",
                "The beads are a physical guide: the crucifix begins the prayer, the large beads mark Our Fathers, and the small beads mark Hail Marys."
            ]
        case .oneDecade:
            [
                "Yes. One decade is a real and worthy way to pray, especially when you are beginning or when time is limited.",
                "Choose one mystery, pray one Our Father, ten Hail Marys, and a Glory Be. Stay with that scene from the life of Christ.",
                "A small prayer prayed attentively is better than a long prayer rushed without love."
            ]
        case .losePlace:
            [
                "Do not worry. Losing your place is common, especially at the beginning.",
                "Pause, breathe, and return to the next prayer you remember. The point is not perfect counting; the point is faithful attention.",
                "The app can guide each step so you can learn the rhythm without pressure."
            ]
        case .repetition:
            [
                "The repetition of the Rosary is meant to become gentle and contemplative.",
                "Like breathing, walking, or listening to a familiar song, repeated words can make space for deeper attention.",
                "The prayers hold you steady while the mysteries invite you to look at Jesus with the Blessed Virgin Mary."
            ]
        case .mary:
            [
                "Catholics do not pray to the Blessed Virgin Mary as if she were God. We ask her to pray with us and for us.",
                "The Blessed Virgin Mary’s role is always to lead us to Jesus. The Rosary is Marian because it is deeply Christ-centered.",
                "In each mystery, the Blessed Virgin Mary helps the person praying stay close to the life of her Son."
            ]
        }
    }
}

private struct LearnArticleView: View {
    @Environment(\.palette) private var palette
    var article: LearnArticle

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                GuideSectionLabel(text: article.eyebrow, color: palette.dim)
                Text(article.title)
                    .font(AppTheme.TypeRole.screenTitle)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                    ForEach(article.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(AppTheme.TypeRole.callout)
                            .lineSpacing(8)
                            .foregroundStyle(palette.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, 80)
        }
        .background(palette.bg)
        .guideDetailChrome(article.title)
    }
}

private struct AllPrayersView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""
    let prayers: [Prayer]

    private var results: [Prayer] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return prayers
            .filter { term.isEmpty || PrayerCatalog.matchesSearch($0, query: term) }
            .sorted {
                $0.title.primary(for: settings.language)
                    .localizedStandardCompare($1.title.primary(for: settings.language)) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                HStack(spacing: AppTheme.Space.md) {
                    Image(systemName: "magnifyingglass").foregroundStyle(palette.dim)
                    TextField(
                        "Search prayers",
                        text: $query,
                        prompt: Text(dynamicTypeSize.isAccessibilitySize ? "Search" : "Search prayers")
                            .font(AppTheme.TypeRole.bodySmall)
                    )
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.ink)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(palette.dim)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, AppTheme.Space.lg)
                .frame(minHeight: AppTheme.Component.pillHeight)
                .background(palette.surface, in: Capsule())
                .overlay { Capsule().stroke(palette.hair, lineWidth: 1) }

                LazyVStack(spacing: 0) {
                    ForEach(results) { prayer in
                        NavigationLink { LearnPrayerDetailView(prayer: prayer) } label: {
                            HStack(spacing: AppTheme.Space.md) {
                                Text(prayer.title.primary(for: settings.language))
                                    .font(AppTheme.TypeRole.bodySmall)
                                    .foregroundStyle(palette.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .guideSymbol(size: 12, weight: .regular)
                                    .foregroundStyle(palette.dim)
                            }
                            .padding(.vertical, AppTheme.Space.xl)
                            .frame(minHeight: 72)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if prayer.id != results.last?.id { Hairline() }
                    }
                    if results.isEmpty {
                        Text("No prayers found. Try another search.")
                            .font(AppTheme.TypeRole.bodySmall)
                            .foregroundStyle(palette.dim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppTheme.Space.lg)
                    }
                }
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.tabBarContentClearance)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(palette.bg)
        .guideDetailChrome("All prayers")
    }
}

/// Title, English / Latin / Both control and prayer text, as one block.
/// The Prayers section and the Saint Michael page after the Rosary both use it,
/// so the two read identically.
struct PrayerReaderBlock: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var prayer: Prayer
    /// The language shown. Prayers without distinct Latin always read in English.
    @Binding var language: PrayerLanguage

    private var shown: PrayerLanguage { prayer.text.hasDistinctLatin ? language : .english }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                Text(prayer.title.english)
                    .font(AppTheme.TypeRole.screenTitle)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !prayer.title.latin.isEmpty && prayer.title.latin != prayer.title.english {
                    Text(prayer.title.latin)
                        .guideThemeSummaryStyle()
                }
            }

            if prayer.text.hasDistinctLatin {
                Picker("Language", selection: $language) {
                    Text("English").tag(PrayerLanguage.english)
                    Text("Latin").tag(PrayerLanguage.latin)
                    Text("Both").tag(PrayerLanguage.bilingual)
                }
                .guideSegmentedControl()
                .labelsHidden()
                .accessibilityLabel("Prayer language")
            }

            prayerReader
                .padding(.horizontal, AppTheme.Space.sm)
                .padding(.vertical, AppTheme.Space.lg)
        }
    }

    @ViewBuilder
    private var prayerReader: some View {
        if shown == .bilingual {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppTheme.Space.xxl) {
                    prayerColumn(prayer.text.english)
                    prayerColumn(prayer.text.latin)
                }
            } else {
                HStack(alignment: .top, spacing: AppTheme.Space.xl) {
                    prayerColumn(prayer.text.english)
                    prayerColumn(prayer.text.latin)
                }
            }
        } else {
            prayerColumn(shown == .latin ? prayer.text.latinOrEnglish : prayer.text.english)
        }
    }

    private func prayerColumn(_ text: String) -> some View {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                prayerParagraph(paragraph)
                    .font(AppTheme.TypeRole.prayerText(scale: settings.textSize.scale))
                    .lineSpacing(AppTheme.Space.sm)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prayerParagraph(_ paragraph: String) -> Text {
        if prayer.id == "litany-of-loreto" {
            let responses = [", pray for us.", ", have mercy on us.", ", spare us, O Lord.", ", graciously hear us, O Lord."]
            if let response = responses.first(where: { paragraph.hasSuffix($0) }) {
                let invocation = String(paragraph.dropLast(response.count))
                let lead = Text(invocation + ", ").foregroundColor(palette.ink)
                let answer = Text(String(response.dropFirst(2))).foregroundColor(palette.dim)
                return Text("\(lead)\(answer)")
            }
        }
        return Text(paragraph).foregroundColor(palette.ink)
    }
}

private struct LearnPrayerDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    var prayer: Prayer
    /// Page-local language; starts from the prayer language setting, never writes it.
    @State private var language: PrayerLanguage?

    @State private var showingAbout = false

    private var shown: PrayerLanguage { prayer.text.hasDistinctLatin ? (language ?? settings.language) : .english }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                PrayerReaderBlock(
                    prayer: prayer,
                    language: Binding(get: { shown }, set: { language = $0 })
                )

                if prayer.id == "sign-of-the-cross" {
                    GuideSectionBoundary()
                    // Cancel the stack's Space.xl so the gap matches other section dividers.
                    .padding(.vertical, -AppTheme.Space.xl)
                    gestureSection
                }

                GuideSectionBoundary()
                    // Cancel the stack's Space.xl so the gap matches other section dividers.
                    .padding(.vertical, -AppTheme.Space.xl)

                aboutBlock

            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, AppTheme.gutter)
            .frame(maxWidth: .infinity)
            .padding(.top, AppTheme.Space.lg)
            .padding(.bottom, AppTheme.Space.section)
        }
        .background(palette.bg)
        .guideDetailChrome("")
    }

    private static let gestureSteps: [(String, String)] = [
        ("Touch your forehead", "In the name of the Father"),
        ("Touch your chest", "and of the Son"),
        ("Touch your left shoulder", "and of the Holy Spirit"),
        ("Touch your right shoulder", "Amen")
    ]

    private var gestureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text("The gesture")
                    .font(AppTheme.TypeRole.headline)
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Using your right hand")
                    .font(AppTheme.TypeRole.bodySmall())
                    .foregroundStyle(palette.dim)
            }

            VStack(spacing: 0) {
                ForEach(Array(Self.gestureSteps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: AppTheme.Space.lg) {
                        Text("\(index + 1)")
                            .font(AppTheme.TypeRole.callout(weight: .semibold))
                            .foregroundStyle(palette.stepNumberText)
                            .frame(width: AppTheme.Space.xxl, height: AppTheme.Space.xxl)
                            .background(palette.stepNumberFill, in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                            Text(step.0)
                                .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                                .foregroundStyle(palette.ink)
                            Text(step.1)
                                .font(AppTheme.TypeRole.label)
                                .foregroundStyle(palette.dim)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, AppTheme.Space.md)
                    .accessibilityElement(children: .combine)
                    if index < Self.gestureSteps.count - 1 {
                        Hairline().padding(.leading, AppTheme.Space.xxl + AppTheme.Space.lg)
                    }
                }
            }

            Text("The Latin Catholic tradition")
                .font(AppTheme.TypeRole.label)
                .foregroundStyle(palette.dim)
        }
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            Button { showingAbout.toggle() } label: {
                HStack(spacing: AppTheme.Space.md) {
                    Text("About this prayer")
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.ink)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .regular)
                        .foregroundStyle(palette.dim)
                        .rotationEffect(.degrees(showingAbout ? 180 : 0))
                }
                .frame(minHeight: AppTheme.Accessibility.minHitTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(showingAbout ? "Expanded" : "Collapsed")
            if showingAbout {
                VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                    let information = PrayerCatalog.information(for: prayer.id) ?? (history + "\n\n" + why)
                    VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                        ForEach(Array(information.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(AppTheme.TypeRole.bodySmall)
                                .foregroundStyle(palette.dim)
                                .lineSpacing(AppTheme.Space.xs)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let notes = PrayerCatalog.libraryNotes(for: prayer.id) {
                        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                            GuideSectionLabel(text: "Sources", prominence: .strong)
                            ForEach(notes.references, id: \.url) { reference in
                                Link(destination: reference.url) {
                                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                                        Text(reference.title).font(AppTheme.TypeRole.caption)
                                        Image(systemName: "arrow.up.right").guideSymbol(size: 12, weight: .regular)
                                    }
                                    .foregroundStyle(palette.ink)
                                    .padding(.vertical, AppTheme.Space.sm)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, AppTheme.Space.lg)
            }
        }
        .guideAccordion(isExpanded: showingAbout)
    }

    private var history: String {
        if let notes = PrayerCatalog.libraryNotes(for: prayer.id) { return notes.history }
        return existingHistory
    }

    private var existingHistory: String {
        switch prayer.id {
        case "sign-of-the-cross": "Christians have marked themselves with the cross from the earliest days. Around AD 200, Tertullian wrote that believers traced it on their foreheads throughout the day. Its words echo Jesus' command to baptise in the name of the Trinity (Matthew 28:19)."
        case "apostles-creed": "The Creed grew from an early baptismal creed of the Church in Rome, known as the Old Roman Symbol. It reached its present form by the eighth century. Tradition links its twelve articles to the Apostles, though they did not write it."
        case "our-father": "Jesus himself gave us this prayer when his disciples asked him to teach them to pray (Matthew 6:9–13; Luke 11:2–4). Christians have prayed it every day since the first centuries."
        case "hail-mary": "The first half comes from Scripture: Gabriel's greeting (Luke 1:28) and Elizabeth's blessing (Luke 1:42). The name of Jesus was added in the Middle Ages. The full prayer appeared in the Roman Breviary of Pope Pius V in 1568."
        case "glory-be": "The Glory be is an ancient hymn of praise to the Holy Trinity. Its second half, \"as it was in the beginning\", was later added in the West, traditionally to answer the Arian heresy, which denied that the Son is eternal."
        case "fatima": "According to Sister Lúcia, Our Lady taught this prayer to the three children of Fatima on 13 July 1917. She asked that it be said after each decade. The local bishop approved the apparitions in 1930, and the prayer soon spread worldwide."
        case "hail-holy-queen": "The Salve Regina is one of the Church's great hymns to Mary. It is traditionally credited to Hermann of Reichenau, an 11th-century monk. Monks, especially Cistercians and Dominicans, sang it at the close of each day."
        case "concluding": "This prayer is the collect, or opening prayer, of the Mass of Our Lady of the Rosary in the 1962 Roman Missal. The feast is kept each year on 7 October. It sums up the whole Rosary."
        case "sacrament-most-holy": "No one knows who wrote this short prayer of praise to Jesus in the Eucharist, or when. It spread through Eucharistic devotion. Many people now add it after the Fatima prayer at each decade."
        case "memorare": "The Memorare is often linked to Saint Bernard of Clairvaux, but its text comes from the 15th century. In the 1600s Fr Claude Bernard, a Paris priest called \"the Poor Priest\", spread it widely among prisoners and the sick."
        case "saint-michael": "Pope Leo XIII wrote this prayer in 1886 and added it to the prayers said after Low Mass. They were said worldwide until 1965. The prayer draws on Scripture's picture of Michael as protector of God's people (Daniel 12:1; Revelation 12:7–9)."
        case "versicle": "This short versicle and response forms part of the conclusion of the Rosary in the Compendium of the Catechism of the Catholic Church."
        default: ""
        }
    }

    private var why: String {
        if let notes = PrayerCatalog.libraryNotes(for: prayer.id) { return notes.purpose }
        return existingPurpose
    }

    private var existingPurpose: String {
        switch prayer.id {
        case "sign-of-the-cross": "We begin and end the Rosary with the Sign of the Cross. In one simple gesture we profess faith in the Trinity, recall our baptism and place our whole prayer under Christ's Cross."
        case "apostles-creed": "We pray the Creed on the crucifix as the Rosary begins. Before we meditate, we stand with the whole Church and profess what we believe. The mysteries that follow unfold this faith."
        case "our-father": "The Our Father opens each decade, so every set of Hail Marys begins with the words Jesus taught. We come before God as his children, trusting him as our loving Father."
        case "hail-mary": "We pray the Hail Mary ten times in each decade. As the words repeat, our hearts rest on Jesus in each mystery. We ask Mary, who knew him best, to pray for us now and at our death."
        case "glory-be": "The Glory be closes each decade. Every mystery ends where all prayer should end, in praise of the Father, Son and Holy Spirit. It keeps our Rosary centred on God, not ourselves."
        case "fatima": "Said after each decade, this prayer asks Jesus to forgive our sins and to save all souls. It widens our prayer to the whole world, especially those most in need of mercy."
        case "hail-holy-queen": "After the last decade we turn from meditation to heartfelt petition. We entrust ourselves to Mary, our mother and advocate, and ask that we may be made worthy of Christ's promises."
        case "concluding": "This prayer gathers the whole Rosary into one request. Having meditated on the mysteries, we ask to imitate what they contain and obtain what they promise. We ask this through Christ our Lord."
        case "sacrament-most-holy": "Though not part of the traditional Rosary, this prayer joins our meditation to adoration. It reminds us that the Jesus we meet in each mystery is truly with us still in the Blessed Sacrament."
        case "memorare": "Many pray the Memorare after the Rosary. It reminds us that no one who turned to Mary has ever been left without help. We bring her our needs with a child's trust."
        case "saint-michael": "Many add this prayer after the Rosary. It reminds us that the spiritual life is a real battle. We ask Saint Michael to defend us, so that we stay faithful to God."
        case "versicle": "We ask the Mother of God to pray for us, that we may be made worthy of Christ’s promises."
        default: ""
        }
    }
}

/// Learn page for a chaplet, Rosary type or novena. Reuses the library prayers
/// and the mystery pages rather than repeating their text.
private struct DevotionDetailView: View {
    @Environment(\.palette) private var palette
    var devotion: Devotion
    @Binding var prayLaunch: PrayLaunch?

    private static let library: [Prayer] = [
        PrayerCatalog.signOfTheCross, PrayerCatalog.apostlesCreed, PrayerCatalog.ourFather,
        PrayerCatalog.hailMary, PrayerCatalog.gloryBe
    ]

    private var prayers: [Prayer] {
        devotion.prayerIDs.compactMap { id in Self.library.first { $0.id == id } }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                MysteryArtworkView(
                    set: devotion.artSet,
                    mysteryNumber: devotion.artMystery,
                    slug: MysteryCatalog.mysteries(for: devotion.artSet).first { $0.number == devotion.artMystery }?.artSlug,
                    kind: .heroWide
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Text(devotion.title)
                        .font(AppTheme.TypeRole.screenTitle)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(devotion.summary)
                        .font(AppTheme.TypeRole.body)
                        .lineSpacing(8)
                        .foregroundStyle(palette.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                stepsSection

                if let stationsTitle = devotion.stationsTitle, !devotion.stations.isEmpty {
                    stationsSection(stationsTitle)
                }

                if !devotion.passages.isEmpty {
                    passagesSection
                }

                if devotion.linksMysterySets {
                    mysterySetsSection
                }

                if !prayers.isEmpty {
                    prayersSection
                }

                aboutSection
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, AppTheme.gutter)
            .frame(maxWidth: .infinity)
            .padding(.top, AppTheme.Space.xl)
            .padding(.bottom, AppTheme.tabBarContentClearance)
        }
        .background(palette.bg)
        .guideDetailChrome(devotion.eyebrow)
    }

    private func heading(_ text: String) -> some View {
        GuideSectionLabel(text: text, prominence: .strong)
            .accessibilityAddTraits(.isHeader)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading(devotion.stepsTitle)
            VStack(spacing: 0) {
                ForEach(Array(devotion.steps.enumerated()), id: \.offset) { index, step in
                    numberedRow(index + 1, title: step.title, detail: step.detail)
                    if index < devotion.steps.count - 1 {
                        Hairline().padding(.leading, AppTheme.Space.xxl + AppTheme.Space.lg)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
        }
    }

    private func stationsSection(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading(title)
            VStack(spacing: 0) {
                ForEach(Array(devotion.stations.enumerated()), id: \.offset) { index, station in
                    numberedRow(index + 1, title: station.title, detail: station.reference)
                    if index < devotion.stations.count - 1 {
                        Hairline().padding(.leading, AppTheme.Space.xxl + AppTheme.Space.lg)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
        }
    }

    private func numberedRow(_ number: Int, title: String, detail: String) -> some View {
        HStack(spacing: AppTheme.Space.lg) {
            Text("\(number)")
                .font(AppTheme.TypeRole.callout(weight: .semibold))
                .foregroundStyle(palette.stepNumberText)
                .frame(width: AppTheme.Space.xxl, height: AppTheme.Space.xxl)
                .background(palette.stepNumberFill, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title)
                    .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(AppTheme.TypeRole.label)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, AppTheme.Space.md)
        .accessibilityElement(children: .combine)
    }

    private var passagesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading("The words")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(devotion.passages.enumerated()), id: \.offset) { index, passage in
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        GuideSectionLabel(text: passage.heading, color: palette.secondaryText)
                        Text(passage.body)
                            .font(AppTheme.TypeRole.bodySmall)
                            .foregroundStyle(palette.ink)
                            .lineSpacing(AppTheme.Space.xs)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Space.lg)
                    .accessibilityElement(children: .combine)
                    if index < devotion.passages.count - 1 { Hairline() }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
        }
    }

    private var mysterySetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading("Scripture for each mystery")
            VStack(spacing: 0) {
                ForEach(MysterySetKind.displayOrder, id: \.self) { set in
                    NavigationLink {
                        LearnMysteryDetailView(set: set, prayLaunch: $prayLaunch)
                    } label: {
                        linkRow("\(set.shortName) Mysteries", detail: set.weekdayNames)
                    }
                    .guidePressable()
                    if set != MysterySetKind.displayOrder.last { Hairline() }
                }
            }
        }
    }

    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading("Prayers you will need")
            VStack(spacing: 0) {
                ForEach(prayers) { prayer in
                    NavigationLink {
                        LearnPrayerDetailView(prayer: prayer)
                    } label: {
                        linkRow(prayer.title.english, detail: nil)
                    }
                    .guidePressable()
                    if prayer.id != prayers.last?.id { Hairline() }
                }
            }
        }
    }

    private func linkRow(_ title: String, detail: String?) -> some View {
        HStack(spacing: AppTheme.Space.md) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                Text(title).font(AppTheme.TypeRole.bodySmall).foregroundStyle(palette.ink)
                if let detail { Text(detail).font(AppTheme.TypeRole.caption).foregroundStyle(palette.dim) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .guideSymbol(size: 12, weight: .regular)
                .foregroundStyle(palette.dim)
                .accessibilityHidden(true)
        }
        .frame(minHeight: AppTheme.Accessibility.minHitTarget)
        .padding(.vertical, AppTheme.Space.sm)
        .contentShape(Rectangle())
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            heading("About")
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                ForEach(Array(devotion.about.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.dim)
                        .lineSpacing(AppTheme.Space.xs)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                GuideSectionLabel(text: "Sources", color: palette.secondaryText)
                ForEach(devotion.references, id: \.url) { reference in
                    Link(destination: reference.url) {
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                            Text(reference.title).font(AppTheme.TypeRole.caption)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "arrow.up.right").guideSymbol(size: 12, weight: .regular)
                        }
                        .foregroundStyle(palette.ink)
                        .padding(.vertical, AppTheme.Space.sm)
                    }
                }
            }
            .padding(.top, AppTheme.Space.sm)
        }
    }
}

private struct LearnMysteryDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    var set: MysterySetKind
    @Binding var prayLaunch: PrayLaunch?
    @State private var expandedMysteries: Set<String> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                MysteryArtworkView(
                    set: set,
                    mysteryNumber: 1,
                    slug: MysteryCatalog.mysteries(for: set).first?.artSlug,
                    kind: .heroWide
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Text(set.displayTitle)
                        .font(AppTheme.TypeRole.screenTitle)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(set.learnDescription)
                        .font(AppTheme.TypeRole.body)
                        .lineSpacing(8)
                        .foregroundStyle(palette.dim)
                }

                VStack(spacing: 0) {
                    ForEach(Array(MysteryCatalog.mysteries(for: set).enumerated()), id: \.element.id) { index, mystery in
                        mysteryAccordionRow(index: index, mystery: mystery)

                        if index < MysteryCatalog.mysteries(for: set).count - 1 {
                            Hairline().padding(.leading, AppTheme.Space.section)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Space.lg)
                .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)

                Button {
                    prayLaunch = .fresh(set)
                } label: {
                    HStack {
                        Text("Pray these mysteries")
                            .font(AppTheme.TypeRole.pillLabel(weight: .semibold))
                            .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .foregroundStyle(palette.primaryButtonText)
                    .padding(.horizontal, AppTheme.Space.lg)
                    .multilineTextAlignment(.center)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.primaryButtonFill, in: Capsule())
                }
                .buttonStyle(.plain)
                .guidePressable()
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xl)
            .padding(.bottom, 80)
        }
        .background(palette.bg)
        .guideDetailChrome(set.shortName)
    }

    private func mysteryAccordionRow(index: Int, mystery: Mystery) -> some View {
        let isExpanded = expandedMysteries.contains(mystery.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                if isExpanded { expandedMysteries.remove(mystery.id) } else { expandedMysteries.insert(mystery.id) }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                    Text("\(index + 1)")
                        .font(AppTheme.TypeRole.label(weight: .semibold))
                        .foregroundStyle(palette.dim)
                        .frame(width: 28, height: 28)
                        .background(palette.surface, in: Circle())

                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text(mystery.title.primary(for: settings.language))
                            .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                            .foregroundStyle(palette.ink)
                        Text(mystery.fruit.primary(for: settings.language))
                            .font(AppTheme.TypeRole.label)
                            .foregroundStyle(palette.dim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isExpanded ? .isSelected : [])
            .accessibilityHint(isExpanded ? "Collapses Scripture" : "Expands Scripture")
            .padding(.vertical, AppTheme.Space.md)

            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text(MysteryScripture.display(for: mystery, translation: settings.rosaryConfig.translation, language: settings.language))
                        .font(AppTheme.TypeRole.themeSummary)
                        .foregroundStyle(palette.dim)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                    GuideSectionLabel(text: mystery.scriptureReference, color: palette.secondaryText)
                }
                .padding(.leading, AppTheme.Space.section)
                .padding(.trailing, AppTheme.Space.sm)
                .padding(.bottom, AppTheme.Space.md)
                    .transition(MotionTokens.accordionTransition)
            }
        }
        .guideAccordion(isExpanded: isExpanded)
    }
}

private extension MysterySetKind {
    var displayTitle: String {
        switch self {
        case .joyful: "The Joyful Mysteries"
        case .luminous: "The Luminous Mysteries"
        case .sorrowful: "The Sorrowful Mysteries"
        case .glorious: "The Glorious Mysteries"
        }
    }

    var learnSummary: String { themeSummary }

    var learnDescription: String {
        switch self {
        case .joyful:
            "The Joyful Mysteries contemplate the coming of Christ: the Annunciation, Visitation, Nativity, Presentation, and Finding in the Temple."
        case .luminous:
            "The Luminous Mysteries contemplate Christ revealed in his public ministry, from his Baptism to the gift of the Eucharist."
        case .sorrowful:
            "The Sorrowful Mysteries contemplate the Passion of Jesus, staying close to his suffering, sacrifice, and love."
        case .glorious:
            "The Glorious Mysteries contemplate the Resurrection, Ascension, Pentecost, and Mary’s share in the glory of her Son."
        }
    }
}

