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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    sheet
                }
            }
            .background(palette.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if selectedSet == nil { selectedSet = assignment.set }
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            MysteryArtworkView(set: currentSet, kind: .heroTall)
                .frame(height: 420)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: palette.bg.opacity(0.15), location: 0),
                            .init(color: .clear, location: 0.28),
                            .init(color: palette.bg.opacity(0.55), location: 0.72),
                            .init(color: palette.bg, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            glassTheme
                .padding(.top, 14)
                .padding(.trailing, 16)
        }
    }

    private var glassTheme: some View {
        Button {
            settings.toggleLightDark(systemIsDark: colorScheme == .dark)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: colorScheme == .light ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(colorScheme == .light ? "Light" : "Dark")
                    .font(AppTheme.sans(13, weight: .medium))
            }
            .foregroundStyle(palette.glassInk)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Appearance")
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(AppTheme.sans(14))
                .foregroundStyle(palette.dim)

            SeasonBadge(season: assignment.season, language: settings.language)

            Text(currentSet.name.primary(for: settings.language))
                .font(AppTheme.serif(44))
                .foregroundStyle(palette.ink)
                .padding(.top, 2)

            Text(assignment.reason)
                .font(AppTheme.sans(15))
                .foregroundStyle(palette.dim)

            if let feast = assignment.feast {
                feastOffer(feast)
            }

            setPicker

            if let resumable = session.resumableSession {
                resumeBlock(resumable)
            }

            PillButton(title: "Pray the \(currentSet.shortName) Mysteries") {
                prayLaunch = .fresh(currentSet)
            }

            if let suggested = assignment.feastSuggestion, selectedSet == assignment.set {
                PillButton(title: "Pray the \(suggested.shortName) Mysteries for \(assignment.feast?.feast.name.english ?? "today")", filled: false) {
                    selectedSet = suggested
                    prayLaunch = .fresh(suggested)
                }
            }

            mysteryRail
            weekStrip
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
        .padding(.top, 8)
    }

    private func feastOffer(_ feast: DatedFeast) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(AppTheme.sans(11, weight: .medium))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(palette.faint)
            Text(feast.feast.name.primary(for: settings.language))
                .font(AppTheme.serif(22))
            if let suggested = feast.feast.suggestedMysterySet, suggested != assignment.set {
                Text("The calendar keeps the \(assignment.set.shortName) Mysteries. You can pray the \(suggested.shortName) Mysteries for this feast instead.")
                    .font(AppTheme.sans(14))
                    .foregroundStyle(palette.dim)
            }
        }
        .padding(.vertical, 8)
    }

    private var setPicker: some View {
        HStack(spacing: 2) {
            ForEach(MysterySetKind.displayOrder) { set in
                Button {
                    selectedSet = set
                } label: {
                    Text(set.shortName)
                        .font(AppTheme.sans(13, weight: .medium))
                        .foregroundStyle(currentSet == set ? (colorScheme == .light ? Color.black : palette.ink) : palette.dim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(currentSet == set ? pickerFill : Color.clear, in: Capsule())
                        .overlay(alignment: .top) {
                            if set == assignment.set {
                                Circle()
                                    .fill(currentSet == set ? palette.ink : palette.faint)
                                    .frame(width: 3, height: 3)
                                    .offset(y: 6)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(colorScheme == .light ? palette.card2 : palette.card, in: Capsule())
    }

    private var pickerFill: Color {
        colorScheme == .light ? .white : palette.card2
    }

    private func resumeBlock(_ item: PrayerSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Continue where you left off")
                .font(AppTheme.sans(16, weight: .semibold))
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
        .padding(.bottom, 4)
    }

    private var mysteryRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The five mysteries")
                .font(AppTheme.sans(12, weight: .medium))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(palette.dim)
                .padding(.top, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mysteries) { mystery in
                        VStack(alignment: .leading, spacing: 0) {
                            MysteryArtworkView(set: mystery.set, mysteryNumber: mystery.number, slug: mystery.artSlug, kind: .plate)
                                .frame(height: 168)
                                .clipped()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(OrdinalWord.roman(mystery.number))")
                                    .font(AppTheme.sans(12))
                                    .foregroundStyle(palette.faint)
                                Text(mystery.title.primary(for: settings.language))
                                    .font(AppTheme.serif(22))
                                    .foregroundStyle(palette.ink)
                                Text(mystery.scriptureExcerpt.english)
                                    .font(AppTheme.serif(16))
                                    .foregroundStyle(palette.dim)
                                    .lineLimit(4)
                                Text(mystery.scriptureReference)
                                    .font(AppTheme.sans(12))
                                    .foregroundStyle(palette.faint)
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("Fruit")
                                        .font(AppTheme.sans(12))
                                        .foregroundStyle(palette.faint)
                                    Text(mystery.fruit.primary(for: settings.language))
                                        .font(AppTheme.serif(16))
                                }
                                .padding(.top, 6)
                                .overlay(alignment: .top) { Hairline() }
                            }
                            .padding(16)
                        }
                        .frame(width: 280)
                        .background(palette.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -22)
            .padding(.leading, 22)
        }
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("This week")
                .font(AppTheme.sans(12, weight: .medium))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(palette.dim)
                .padding(.top, 28)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                ForEach(MysteryCalendar.week(containing: today), id: \.0) { day, dayAssignment in
                    Button {
                        selectedSet = dayAssignment.set
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.formatted(.dateTime.weekday(.wide)))
                                    .font(AppTheme.serif(20))
                                    .foregroundStyle(palette.ink)
                                if Calendar.current.isDateInToday(day) {
                                    Text("Today")
                                        .font(AppTheme.sans(12, weight: .medium))
                                        .foregroundStyle(palette.faint)
                                }
                            }
                            Spacer()
                            Text(dayAssignment.set.shortName)
                                .font(AppTheme.sans(15))
                                .foregroundStyle(palette.dim)
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    if day != MysteryCalendar.week(containing: today).last?.0 {
                        Hairline()
                    }
                }
            }
        }
    }
}
