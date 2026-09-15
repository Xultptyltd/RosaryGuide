import SwiftUI

struct FeastsView: View {
    @Environment(SettingsStore.self) private var settings
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
                .background(Color(.systemGroupedBackground))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsDate {
                Text(item.date.formatted(.dateTime.month(.abbreviated).day().weekday(.wide)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
            }
            Text(item.feast.name.primary(for: language))
                .font(.headline)
            HStack(spacing: 8) {
                Text(item.feast.rank.title)
                if item.feast.isMarian {
                    Text("Marian")
                }
                if let set = item.feast.suggestedMysterySet {
                    Text(set.ordinalAdjective.english)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FeastDetailView: View {
    @Environment(SettingsStore.self) private var settings
    var item: DatedFeast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(item.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                BilingualStack(
                    text: item.feast.name,
                    language: settings.language,
                    font: .largeTitle.weight(.semibold)
                )
                HStack {
                    Text(item.feast.rank.title)
                    if item.feast.isMarian {
                        Text("· Marian")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Text(item.feast.summary)
                    .font(.body)

                if let set = item.feast.suggestedMysterySet {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested mysteries")
                            .font(.headline)
                        Text(set.name.primary(for: settings.language))
                            .font(.title3.weight(.medium))
                        Text("The app uses this set automatically on major feasts such as Christmas, Easter, Good Friday, and the Assumption.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(set.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
