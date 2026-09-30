import SwiftUI

struct PrayHubView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Binding var prayLaunch: PrayLaunch?
    @State private var titleScrollOffset: CGFloat = 0
    @State private var expandedPrayerId: String?
    @State private var expandedQuestion: LearnArticle?
    @State private var navigationPath = NavigationPath()
    @State private var pageGutter: CGFloat = AppTheme.gutter

    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: Date())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                        VStack(alignment: .leading, spacing: 0) {
                            CollapsingTitleSpacer()
                            introCard
                                .padding(.top, AppTheme.Space.sm)
                        }
                        .guideReveal()

                        prayersSection
                            .guideReveal(delay: 0.06)

                        mysteriesSection
                            .guideReveal(delay: 0.1)

                        questionsSection
                            .guideReveal(delay: 0.14)

                        prayTodayCard
                            .guideReveal(delay: 0.18)
                    }
                    .padding(.horizontal, pageGutter)
                    .padding(.top, AppTheme.Space.sm)
                    .padding(.bottom, 108)
                    .frame(width: proxy.size.width, alignment: .topLeading)
                    .onAppear { pageGutter = AppTheme.gutter(for: proxy.size.width) }
                    .onChange(of: proxy.size.width) { _, w in pageGutter = AppTheme.gutter(for: w) }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
            }
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
                    .font(AppTheme.sans(40, weight: .regular))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "book.closed")
                    .guideSymbol(size: 30, weight: .medium)
                    .foregroundStyle(palette.accent)
                    .frame(width: 58, height: 58)
                    .background(palette.accentTint, in: Circle())
            }

            Text("A simple path through the prayers, mysteries, and tradition behind it.")
                .font(AppTheme.sans(16))
                .lineSpacing(5)
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink {
                HowToPrayView()
            } label: {
                HStack {
                    Text("Begin walkthrough")
                        .font(AppTheme.sans(16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(AppTheme.sans(14, weight: .semibold))
                }
                .foregroundStyle(palette.onAccent)
                .padding(.horizontal, AppTheme.Space.lg)
                .frame(height: 56)
                .background(palette.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
        }
        .padding(AppTheme.Space.xl)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.panel)
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

        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "The prayers", color: palette.dim)

            VStack(spacing: 0) {
                ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                    prayerAccordionRow(prayer: prayer)

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
                icon: set.learnIcon,
                title: set.displayTitle,
                detail: set.learnSummary,
                destination: .mystery(set)
            )
        })
    }

    private var questionsSection: some View {
        let questions: [LearnArticle] = [.whatIsRosary, .beads, .oneDecade, .losePlace, .repetition, .mary]

        return VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "Common questions", color: palette.dim)

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
                .font(AppTheme.sans(24, weight: .semibold))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(resumable == nil ? "Use what you’ve learnt and pray today’s mysteries." : "\(set.shortName) Mysteries are waiting where you left off.")
                .font(AppTheme.sans(15))
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
                        .font(AppTheme.sans(16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(AppTheme.sans(14, weight: .semibold))
                }
                .foregroundStyle(palette.onAccent)
                .padding(.horizontal, AppTheme.Space.lg)
                .frame(height: 54)
                .background(palette.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
            .padding(.top, AppTheme.Space.xs)
        }
        .padding(AppTheme.Space.xl)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.panel)
    }

    private func learnSection(title: String, rows: [LearnRow]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: title, color: palette.dim)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    NavigationLink {
                        destination(for: row.destination)
                    } label: {
                        learnRow(row)
                    }
                    .buttonStyle(.plain)

                    if index < rows.count - 1 {
                        Hairline().padding(.leading, 58)
                    }
                }
            }
            .guideNavList(pageGutter: pageGutter)
        }
    }

    private func prayerAccordionRow(prayer: Prayer) -> some View {
        let isOpen = expandedPrayerId == prayer.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedPrayerId = isOpen ? nil : prayer.id
                }
            } label: {
                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prayer.title.primary(for: settings.language))
                            .font(AppTheme.sans(19, weight: .semibold))
                            .foregroundStyle(palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(wherePrayerAppears(prayer))
                            .font(AppTheme.sans(14))
                            .foregroundStyle(palette.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(AppTheme.sans(11, weight: .semibold))
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.vertical, AppTheme.Space.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prayer.title.primary(for: settings.language))
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Collapses the prayer" : "Expands the prayer")

            if isOpen {
                Text(prayer.text.primary(for: settings.language))
                    .font(AppTheme.sans(18))
                    .lineSpacing(7)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, AppTheme.Space.sm)
                    .padding(.bottom, AppTheme.Space.xl)
                    .transition(.opacity)
            }
        }
    }

    private func wherePrayerAppears(_ prayer: Prayer) -> String {
        switch prayer.id {
        case "sign-of-the-cross": "Used at the beginning and end."
        case "apostles-creed": "Prayed on the crucifix at the start."
        case "our-father": "Prayed on each large bead."
        case "hail-mary": "Prayed on the small beads."
        case "glory-be": "Prayed after each decade."
        case "hail-holy-queen": "Prayed near the close."
        case "concluding": "The last prayer of the Rosary."
        default: "Part of the traditional Rosary."
        }
    }

    private func questionAccordionRow(_ article: LearnArticle) -> some View {
        let isOpen = expandedQuestion == article

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedQuestion = isOpen ? nil : article
                }
            } label: {
                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    Text(article.title)
                        .font(AppTheme.sans(19, weight: .semibold))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(AppTheme.sans(11, weight: .semibold))
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.vertical, AppTheme.Space.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(article.title)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Collapses the answer" : "Expands the answer")

            if isOpen {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    ForEach(article.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(AppTheme.sans(18))
                            .lineSpacing(7)
                            .foregroundStyle(palette.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.trailing, AppTheme.Space.sm)
                .padding(.bottom, AppTheme.Space.xl)
                .transition(.opacity)
            }
        }
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
            Image(systemName: row.icon)
                .guideSymbol(size: 17, weight: .medium)
                .foregroundStyle(palette.accent)
                .frame(width: 34, height: 34)
                .background(palette.accentTint, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(AppTheme.sans(19, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(row.detail)
                    .font(AppTheme.sans(14))
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(AppTheme.sans(11, weight: .semibold))
                .foregroundStyle(palette.faint)
        }
        .padding(.vertical, AppTheme.Space.lg)
        .contentShape(Rectangle())
    }
}

private struct LearnRow: Identifiable {
    let id = UUID()
    var icon: String
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
        case .mary: "Why pray with the Blessed Virgin Mary?"
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
                "The Rosary is a way of praying with the Blessed Virgin Mary while meditating on the life, death, and glory of Jesus.",
                "Its repeated prayers are not meant to fill silence with noise. They create a steady rhythm so the heart can stay with each mystery.",
                "A full Rosary is usually five decades. Each decade focuses on one mystery from the Gospel and ends by returning praise to the Trinity."
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
                    .font(AppTheme.sans(36, weight: .regular))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                    ForEach(article.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(AppTheme.sans(18))
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                GuideSectionLabel(text: "Prayer", color: palette.dim)
                Text(prayer.title.primary(for: settings.language))
                    .font(AppTheme.sans(36, weight: .regular))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(whereItAppears)
                    .font(AppTheme.sans(15))
                    .lineSpacing(6)
                    .foregroundStyle(palette.dim)
                    .padding(AppTheme.Space.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.panel, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))

                Text(prayer.text.primary(for: settings.language))
                    .font(AppTheme.sans(19))
                    .lineSpacing(9)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, 80)
        }
        .background(palette.bg)
        .guideDetailChrome(prayer.title.primary(for: settings.language))
    }

    private var whereItAppears: String {
        switch prayer.id {
        case "sign-of-the-cross": "Used at the beginning and end of the Rosary."
        case "apostles-creed": "Prayed on the crucifix at the start."
        case "our-father": "Prayed on each large bead, before every decade."
        case "hail-mary": "Prayed on the small beads, especially the ten beads of each decade."
        case "glory-be": "Prayed after each decade."
        case "hail-holy-queen": "Prayed near the close of the Rosary."
        case "concluding": "The last prayer of the Rosary."
        default: "Part of the traditional flow of the Rosary."
        }
    }
}

private struct LearnMysteryDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    var set: MysterySetKind
    @Binding var prayLaunch: PrayLaunch?

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
                        .font(AppTheme.sans(36, weight: .regular))
                        .foregroundStyle(palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(set.learnDescription)
                        .font(AppTheme.sans(18))
                        .lineSpacing(8)
                        .foregroundStyle(palette.dim)
                }

                VStack(spacing: 0) {
                    ForEach(Array(MysteryCatalog.mysteries(for: set).enumerated()), id: \.element.id) { index, mystery in
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                            Text("\(index + 1)")
                                .font(AppTheme.sans(13, weight: .semibold))
                                .foregroundStyle(palette.dim)
                                .frame(width: 28, height: 28)
                                .background(palette.card, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mystery.title.primary(for: settings.language))
                                    .font(AppTheme.sans(17, weight: .semibold))
                                    .foregroundStyle(palette.ink)
                                Text(mystery.fruit.primary(for: settings.language))
                                    .font(AppTheme.sans(13))
                                    .foregroundStyle(palette.dim)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, AppTheme.Space.md)

                        if index < MysteryCatalog.mysteries(for: set).count - 1 {
                            Hairline().padding(.leading, 44)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Space.lg)
                .guideCard(radius: AppTheme.containerRadius, fill: palette.panel)

                Button {
                    prayLaunch = .fresh(set)
                } label: {
                    HStack {
                        Text("Pray these mysteries")
                            .font(AppTheme.sans(16, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(AppTheme.sans(14, weight: .semibold))
                    }
                    .foregroundStyle(palette.onAccent)
                    .padding(.horizontal, AppTheme.Space.lg)
                    .frame(height: 56)
                    .background(palette.accent, in: Capsule())
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

    var learnIcon: String {
        switch self {
        case .joyful: "sparkles"
        case .luminous: "sun.max.fill"
        case .sorrowful: "cross.fill"
        case .glorious: "crown.fill"
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
