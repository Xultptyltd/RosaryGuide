import SwiftUI

struct FeastsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @State private var filter: FeastFilter = .upcoming

    private var todayFeasts: [DatedFeast] {
        FeastCatalog.feasts(on: Date())
    }

    var body: some View {
        NavigationStack {
            List {
                if !todayFeasts.isEmpty && filter != .marian {
                    Section("Today") {
                        ForEach(todayFeasts) { item in
                            NavigationLink {
                                FeastDetailView(item: item)
                            } label: {
                                FeastRow(item: item, language: settings.language, showsDate: false)
                            }
                        }
                    }
                }

                Section(filter.sectionTitle) {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            FeastDetailView(item: item)
                        } label: {
                            FeastRow(item: item, language: settings.language, showsDate: true)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .guidePageChrome()
            .navigationTitle("Feasts")
            .safeAreaInset(edge: .top) {
                Picker("Filter", selection: $filter) {
                    ForEach(FeastFilter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(palette.bg)
            }
        }
    }

    private var filteredItems: [DatedFeast] {
        let year = Calendar.current.component(.year, from: Date())
        switch filter {
        case .upcoming:
            return FeastCatalog.upcoming(from: Date(), limit: 20)
        case .year:
            return FeastCatalog.dated(in: year)
        case .marian:
            return FeastCatalog.upcoming(from: Date(), limit: 40).filter(\.feast.isMarian)
        }
    }
}

private enum FeastFilter: String, CaseIterable, Identifiable {
    case upcoming
    case year
    case marian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: "Upcoming"
        case .year: "This year"
        case .marian: "Marian"
        }
    }

    var sectionTitle: String {
        switch self {
        case .upcoming: "Next observances"
        case .year: "Liturgical year"
        case .marian: "Marian feasts"
        }
    }
}

private struct FeastRow: View {
    var item: DatedFeast
    var language: PrayerLanguage
    var showsDate: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsDate {
                Text(item.date.formatted(.dateTime.month(.abbreviated).day().weekday(.wide)))
                    .font(AppTheme.sans(12, weight: .medium))
                    .foregroundStyle(palette.dim)
            }
            Text(item.feast.name.primary(for: language))
                .font(AppTheme.serif(20, opticalSize: 28))
                .foregroundStyle(palette.ink)
            HStack(spacing: 8) {
                Text(item.feast.rank.title)
                if item.feast.isMarian {
                    Text("Marian")
                }
                if let set = item.feast.suggestedMysterySet {
                    Text(set.shortName)
                }
            }
            .font(AppTheme.sans(12))
            .foregroundStyle(palette.faint)
        }
        .padding(.vertical, 4)
    }
}

struct FeastDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    var item: DatedFeast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(item.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(AppTheme.sans(14, weight: .medium))
                    .foregroundStyle(palette.dim)
                BilingualStack(
                    text: item.feast.name,
                    language: settings.language,
                    font: AppTheme.serif(34)
                )
                HStack {
                    Text(item.feast.rank.title)
                    if item.feast.isMarian {
                        Text("· Marian")
                    }
                }
                .font(AppTheme.sans(12, weight: .medium))
                .foregroundStyle(palette.faint)

                Text(item.feast.summary)
                    .font(AppTheme.serif(18))

                if let set = item.feast.suggestedMysterySet {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested mysteries")
                            .font(AppTheme.sans(12, weight: .medium))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(palette.faint)
                        Text(set.name.primary(for: settings.language))
                            .font(AppTheme.serif(22))
                        Text("The weekday set stays the default. You can pray the \(set.shortName) Mysteries for this feast if you wish.")
                            .font(AppTheme.sans(14))
                            .foregroundStyle(palette.dim)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(palette.bg)
        .toolbarBackground(palette.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}
