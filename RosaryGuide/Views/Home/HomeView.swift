import SwiftUI

struct HomeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Binding var prayLaunch: PrayLaunch?

    @State private var selectedSet: MysterySetKind?

    private var today: Date { Date() }
    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: today)
    }
    private var currentSet: MysterySetKind { selectedSet ?? assignment.set }
    private var mysteries: [Mystery] { MysteryCatalog.mysteries(for: currentSet) }

    @State private var viewport = CGSize(width: 390, height: 720)
    @State private var topInset: CGFloat = 47

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero(topInset: topInset, viewport: viewport.height + topInset)
                    sheet(width: viewport.width, gutter: AppTheme.gutter(for: viewport.width))
                        .padding(.top, -AppTheme.sheetOverlap)
                }
                .padding(.bottom, 28)
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
        }
    }

    private func captureMetrics(_ geo: GeometryProxy) {
        viewport = geo.size
        topInset = geo.safeAreaInsets.top
    }

    private func hero(topInset: CGFloat, viewport: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
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
            glassTheme
                .padding(.top, topInset + 12)
                .padding(.trailing, 16)
        }
    }

    private var glassTheme: some View {
        Button {
            settings.toggleLightDark(systemIsDark: colorScheme == .dark)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: colorScheme == .light ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(colorScheme == .light ? "Light" : "Dark")
                    .font(AppTheme.sans(13, weight: .medium))
            }
            .foregroundStyle(palette.glassInk)
            .padding(.leading, 13)
            .padding(.trailing, 16)
            .frame(height: AppTheme.controlSize)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(palette.glassFill)
                    }
            }
            .overlay {
                Capsule().strokeBorder(palette.glassEdge, lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Appearance")
        .accessibilityValue(colorScheme == .light ? "Light" : "Dark")
    }

    private func sheet(width: CGFloat, gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(AppTheme.sans(14))
                .foregroundStyle(palette.dim)
                .padding(.bottom, 14)

            SeasonBadge(season: assignment.season, language: settings.language)
                .padding(.bottom, 10)

            GuideDisplayTitle(
                text: currentSet.name.primary(for: settings.language),
                size: AppTheme.homeTitleSize(width: width),
                color: palette.ink
            )

            Text(assignment.reason)
                .font(AppTheme.sans(15))
                .foregroundStyle(palette.dim)
                .lineSpacing(6)
                .padding(.top, 16)

            if let feast = assignment.feast {
                feastOffer(feast)
                    .padding(.top, 22)
            }

            setPicker
                .padding(.top, 26)

            if let resumable = session.resumableSession {
                resumeBlock(resumable)
                    .padding(.top, 20)
            }

            PillButton(title: "Pray the \(currentSet.shortName) Mysteries") {
                prayLaunch = .fresh(currentSet)
            }
            .padding(.top, 20)

            if let suggested = assignment.feastSuggestion, selectedSet == assignment.set {
                PillButton(title: "Pray the \(suggested.shortName) Mysteries for \(assignment.feast?.feast.name.english ?? "today")", filled: false) {
                    selectedSet = suggested
                    prayLaunch = .fresh(suggested)
                }
                .padding(.top, 11)
            }

            mysteryRail(gutter: gutter)
                .padding(.top, AppTheme.decadesGap)

            weekStrip
                .padding(.top, AppTheme.sectionGap)
        }
        .padding(.horizontal, gutter)
        .padding(.top, 6)
        .frame(maxWidth: 576, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func feastOffer(_ feast: DatedFeast) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GuideSectionLabel(text: "Today", color: palette.dim)
            Text(feast.feast.name.primary(for: settings.language))
                .font(AppTheme.serif(22, opticalSize: 34))
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
                    selectedSet = set
                } label: {
                    Text(set.shortName)
                        .font(AppTheme.sans(13, weight: .medium))
                        .foregroundStyle(pickerInk(for: set))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(currentSet == set ? pickerFill : Color.clear, in: Capsule())
                        .overlay(alignment: .top) {
                            if set == assignment.set {
                                Circle()
                                    .fill(currentSet == set ? pickerInk(for: set) : palette.faint)
                                    .frame(width: 3, height: 3)
                                    .offset(y: 6)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(currentSet == set ? .isSelected : [])
            }
        }
        .padding(3)
        .background(colorScheme == .light ? palette.card2 : palette.card, in: Capsule())
        .shadow(color: colorScheme == .light ? Color(hex: 0x171512).opacity(0.06) : .clear, radius: 8, y: 4)
    }

    private func pickerInk(for set: MysterySetKind) -> Color {
        guard currentSet == set else { return palette.dim }
        return colorScheme == .light ? Color.black : palette.ink
    }

    private var pickerFill: Color {
        colorScheme == .light ? .white : palette.card2
    }

    private func resumeBlock(_ item: PrayerSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Continue where you left off")
                .font(AppTheme.sans(16, weight: .semibold))
                .foregroundStyle(palette.ink)
            Text(item.mysterySet.name.english)
                .font(AppTheme.sans(14))
                .foregroundStyle(palette.dim)
            HStack {
                PillButton(title: "Continue") { prayLaunch = .resume(item) }
                Button("Restart") { session.discard() }
                    .font(AppTheme.sans(15, weight: .medium))
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func mysteryRail(gutter: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GuideSectionLabel(text: "The five mysteries", color: palette.dim)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 13) {
                    ForEach(mysteries) { mystery in
                        mysteryCard(mystery)
                    }
                }
                .padding(.vertical, 2)
                .padding(.leading, gutter)
                .padding(.trailing, gutter)
            }
            .padding(.horizontal, -gutter)
        }
    }

    private func mysteryCard(_ mystery: Mystery) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MysteryArtworkView(set: mystery.set, mysteryNumber: mystery.number, slug: mystery.artSlug, kind: .plate)
                .frame(height: 168)
                .clipped()
            VStack(alignment: .leading, spacing: 0) {
                Text(OrdinalWord.roman(mystery.number))
                    .font(AppTheme.sans(13))
                    .foregroundStyle(palette.faint)
                    .padding(.bottom, 9)
                Text(mystery.title.primary(for: settings.language))
                    .font(AppTheme.serif(22, opticalSize: 34))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(mystery.scriptureExcerpt.english)
                    .font(AppTheme.serif(17, opticalSize: 16))
                    .foregroundStyle(palette.dim)
                    .lineSpacing(8)
                    .lineLimit(5)
                    .padding(.top, 14)
                Text(mystery.scriptureReference)
                    .font(AppTheme.sans(11))
                    .foregroundStyle(palette.faint)
                    .padding(.top, 10)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Fruit")
                        .font(AppTheme.sans(12))
                        .foregroundStyle(palette.faint)
                    Text(mystery.fruit.primary(for: settings.language))
                        .font(AppTheme.serif(17, opticalSize: 16))
                        .foregroundStyle(palette.ink)
                }
                .padding(.top, 18)
                .overlay(alignment: .top) { Hairline() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .frame(width: min(max(viewport.width * 0.82, 252), 320))
        .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.featureRadius, style: .continuous))
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "This week", color: palette.dim)
                .padding(.bottom, 18)
            VStack(spacing: 0) {
                ForEach(MysteryCalendar.week(containing: today), id: \.0) { day, dayAssignment in
                    Button {
                        selectedSet = dayAssignment.set
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
                            }
                            Spacer(minLength: 8)
                            Text(dayAssignment.set.shortName)
                                .font(AppTheme.sans(15))
                                .foregroundStyle(Calendar.current.isDateInToday(day) ? palette.ink : palette.dim)
                        }
                        .padding(.vertical, 15)
                    }
                    .buttonStyle(.plain)
                    if day != MysteryCalendar.week(containing: today).last?.0 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, 18)
            .background(palette.panel, in: RoundedRectangle(cornerRadius: AppTheme.panelRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.panelRadius, style: .continuous)
                    .strokeBorder(colorScheme == .light ? Color(hex: 0x171512).opacity(0.08) : Color.clear, lineWidth: 1)
            }
        }
    }
}
