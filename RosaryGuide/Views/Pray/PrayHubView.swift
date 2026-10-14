import SwiftUI

struct PrayHubView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Binding var prayLaunch: PrayLaunch?
    @State private var titleScrollOffset: CGFloat = 0
    @State private var expandedQuestion: LearnArticle?
    @State private var navigationPath = NavigationPath()
    @State private var pageGutter: CGFloat = AppTheme.gutter

    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: Date())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        CollapsingTitleSpacer(height: CollapsingTitleMetrics.firstComponentSpacerHeight)
                        introCard
                    }
                    .guideReveal()

                    GuideSectionBoundary(gutter: pageGutter)

                    mysteriesSection
                        .guideReveal(delay: 0.06)

                    GuideSectionBoundary(gutter: pageGutter)

                    prayersSection
                        .guideReveal(delay: 0.08)

                    GuideSectionBoundary(gutter: pageGutter)

                    optionalPrayersSection
                        .guideReveal(delay: 0.1)

                    GuideSectionBoundary(gutter: pageGutter)

                    questionsSection
                        .guideReveal(delay: 0.14)

                    GuideSectionBoundary(gutter: pageGutter)

                    prayTodayCard
                        .guideReveal(delay: 0.18)
                }
                .padding(.horizontal, pageGutter)
                .padding(.top, AppTheme.Space.sm)
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
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .collapsingTitleChrome("Learn", scrollOffset: $titleScrollOffset)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .top, spacing: AppTheme.Space.md) {
                Text("Learn the Rosary")
                    .font(AppTheme.sans(32, weight: .regular, relativeTo: .largeTitle))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "book.closed")
                    .guideSymbol(size: 30, weight: .medium)
                    .foregroundStyle(palette.accent)
                    .frame(width: 56, height: 56)
                    .background(palette.accentTint, in: Circle())
            }

            Text("Prayers, mysteries and how to pray")
                .font(AppTheme.TypeRole.callout)
                .lineSpacing(5)
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink {
                HowToPrayView()
            } label: {
                HStack {
                    Text("Begin walkthrough")
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
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

                    if index < prayers.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideRowGroup()
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

                    if index < prayers.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideRowGroup()
        }
    }

    private var mysteriesSection: some View {
        learnSection(title: "The mysteries", rows: MysterySetKind.displayOrder.map { set in
            LearnRow(
                mysterySet: set,
                title: set.displayTitle,
                detail: set.learnSummary,
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
        let set = resumable?.mysterySet ?? assignment.set

        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Text(resumable == nil ? assignment.set.displayTitle : "Resume your Rosary")
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
                    prayLaunch = .fresh(assignment.set)
                }
            } label: {
                HStack {
                    Text(cta)
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
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
                    .buttonStyle(.plain)

                    if index < rows.count - 1 {
                        Hairline().padding(.leading, 44 + AppTheme.Space.md)
                    }
                }
            }
            .guideNavList(pageGutter: pageGutter)
        }
    }

    private func prayerNavRow(prayer: Prayer) -> some View {
        NavigationLink {
            LearnPrayerDetailView(prayer: prayer)
        } label: {
            HStack(alignment: .center, spacing: AppTheme.Space.md) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(prayer.title.primary(for: settings.language))
                        .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(wherePrayerAppears(prayer))
                        .font(AppTheme.TypeRole.label)
                        .foregroundStyle(palette.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppTheme.Space.sm)

                // Same chevron as Settings navigation rows.
                Image(systemName: "chevron.right")
                    .guideSymbol(size: 12, weight: .regular)
                    .foregroundStyle(palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AppTheme.Space.lg)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(row.detail)
                    .font(AppTheme.TypeRole.label)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

        }
        .padding(.vertical, AppTheme.Space.lg)
        .contentShape(Rectangle())
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

private struct LearnPrayerDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    var prayer: Prayer
    /// Page-local language; starts from the prayer language setting, never writes it.
    @State private var language: PrayerLanguage?
    @State private var aboutOpen = false

    private var shown: PrayerLanguage { language ?? settings.language }

    var body: some View {
        @Bindable var settings = settings
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(prayer.title.english)
                        .font(AppTheme.TypeRole.screenTitle)
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if prayer.title.latin != prayer.title.english {
                        Text(prayer.title.latin)
                            .font(AppTheme.TypeRole.bodySmall())
                            .foregroundStyle(palette.dim)
                    }
                }

                Picker("Language", selection: Binding(get: { shown }, set: { language = $0 })) {
                    Text("English").tag(PrayerLanguage.english)
                    Text("Latin").tag(PrayerLanguage.latin)
                    Text("Both").tag(PrayerLanguage.bilingual)
                }
                .guideSegmentedControl()
                .labelsHidden()
                .accessibilityLabel("Prayer language")

                BilingualStack(
                    text: prayer.text,
                    language: shown,
                    font: AppTheme.TypeRole.prayerText(scale: settings.textSize.scale),
                    pointSize: AppTheme.TypeRole.prayerLineHeightReference(scale: settings.textSize.scale)
                )

                Hairline()

                if prayer.id == "sign-of-the-cross" {
                    gestureSection
                    Hairline()
                }

                aboutRow
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.sm)
            .padding(.bottom, AppTheme.Space.section)
        }
        .background(palette.bg)
        .guideDetailChrome("")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Text size", selection: $settings.textSize) {
                        ForEach(PrayerTextSize.allCases) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                } label: {
                    Text("Aa")
                        .font(AppTheme.TypeRole.callout(weight: .medium))
                        .foregroundStyle(palette.accent)
                }
                .accessibilityLabel("Text size")
            }
        }
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
                            .foregroundStyle(palette.accent)
                            .frame(width: AppTheme.Space.xxl, height: AppTheme.Space.xxl)
                            .background(palette.accent.opacity(0.15), in: Circle())
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

    private var aboutRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            Button {
                withAnimation(MotionTokens.accordion) { aboutOpen.toggle() }
            } label: {
                HStack(spacing: AppTheme.Space.md) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                        Text("About this prayer")
                            .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                            .foregroundStyle(palette.ink)
                        Text("Meaning and place in the Rosary")
                            .font(AppTheme.TypeRole.label)
                            .foregroundStyle(palette.dim)
                    }
                    Spacer(minLength: AppTheme.Space.sm)
                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .regular)
                        .foregroundStyle(palette.secondaryText)
                        .rotationEffect(.degrees(aboutOpen ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(aboutOpen ? "Expanded" : "Collapsed")

            if aboutOpen {
                Text(about)
                    .font(AppTheme.TypeRole.themeSummary)
                    .lineSpacing(5)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var about: String {
        switch prayer.id {
        case "sign-of-the-cross": "We begin and end the Rosary marked with the Cross, calling on the Holy Trinity and giving the whole prayer to God."
        case "apostles-creed": "Said on the crucifix at the start, the Creed sums up the faith of the Church that the mysteries unfold."
        case "our-father": "The prayer Jesus taught us. It opens each decade, turning our hearts to the Father before we meditate."
        case "hail-mary": "Prayed ten times in each decade. Its words come from the Angel Gabriel and Saint Elizabeth, and ask Mary to pray for us."
        case "glory-be": "Closes each decade by giving praise to the Holy Trinity."
        case "fatima": "Taught by Our Lady at Fatima in 1917. Many pray it after each Glory be, asking mercy for all souls."
        case "hail-holy-queen": "An ancient hymn to Mary, prayed after the last decade as we entrust ourselves to her care."
        case "concluding": "Closes the Rosary, asking that by meditating on these mysteries we may imitate what they contain and obtain what they promise."
        case "sacrament-most-holy": "A short prayer of praise to Jesus in the Eucharist, often said after the Fatima prayer."
        case "memorare": "A prayer of trust in Mary's intercession, often said after the Rosary."
        case "saint-michael": "Asks Saint Michael to defend us against evil. Many add it after the Rosary."
        default: "A prayer of the Church, offered with the Rosary."
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
                            Hairline().padding(.leading, 44)
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
                            .font(AppTheme.TypeRole.callout(weight: .semibold))
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

                    VStack(alignment: .leading, spacing: 4) {
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
                .padding(.leading, 44)
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
