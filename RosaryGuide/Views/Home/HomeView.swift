import SwiftUI

struct HomeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Binding var prayLaunch: PrayLaunch?

    private var today: Date { Date() }
    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let feast = assignment.feastOverride {
                        feastBanner(feast)
                    }
                    todayCard
                    if let resumable = session.resumableSession {
                        resumeCard(resumable)
                    }
                    weekStrip
                    otherSets
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rosary Guide")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            SeasonBadge(season: assignment.season, language: settings.language)
            Text(assignment.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private func feastBanner(_ feast: DatedFeast) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feast.feast.isMarian ? "laurel.leading" : "star.circle.fill")
                .foregroundStyle(AppTheme.gold)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Today’s feast")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(feast.feast.name.primary(for: settings.language))
                    .font(.headline)
                if settings.language == .bilingual {
                    Text(feast.feast.name.latin)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.marianBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var todayCard: some View {
        let mysteries = MysteryCatalog.mysteries(for: assignment.set)
        return VStack(alignment: .leading, spacing: 16) {
            MysteryArtworkView(set: assignment.set, mysteryNumber: nil)
            HStack {
                Image(systemName: assignment.set.symbolName)
                Text("Today’s mysteries")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .foregroundStyle(assignment.set.tint)

            BilingualStack(
                text: assignment.set.name,
                language: settings.language,
                font: .largeTitle.weight(.semibold)
            )

            VStack(alignment: .leading, spacing: 10) {
                ForEach(mysteries) { mystery in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(mystery.number)")
                            .font(.caption.weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(assignment.set.tint.opacity(0.18), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mystery.title.primary(for: settings.language))
                                .font(.body.weight(.medium))
                            Text(mystery.fruit.primary(for: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button {
                prayLaunch = .fresh(assignment.set)
            } label: {
                Label("Begin today’s Rosary", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.marianBlue)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func resumeCard(_ session: PrayerSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Continue where you left off", systemImage: "arrow.clockwise.circle.fill")
                .font(.headline)
            Text("\(session.mysterySet.name.english) · step \(session.stepIndex + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Button("Resume") { prayLaunch = .resume(session) }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                    .foregroundStyle(AppTheme.deepNavy)
                Button("Discard", role: .destructive) { self.session.discard() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.title3.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MysteryCalendar.week(containing: today), id: \.0) { day, dayAssignment in
                        let isToday = Calendar.current.isDateInToday(day)
                        VStack(spacing: 8) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption.weight(.semibold))
                            Circle()
                                .fill(dayAssignment.set.tint)
                                .frame(width: 12, height: 12)
                            Text(shortSet(dayAssignment.set))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 52)
                        .padding(.vertical, 10)
                        .background(
                            isToday ? AppTheme.marianBlue.opacity(0.12) : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            if isToday {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppTheme.marianBlue.opacity(0.4), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var otherSets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pray another set")
                .font(.title3.weight(.semibold))
            ForEach(MysterySetKind.allCases) { set in
                Button {
                    prayLaunch = .fresh(set)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: set.symbolName)
                            .foregroundStyle(set.tint)
                            .frame(width: 36, height: 36)
                            .background(set.tint.opacity(0.15), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.name.primary(for: settings.language))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(set.weekdayNames)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func shortSet(_ set: MysterySetKind) -> String {
        switch set {
        case .joyful: "Joy"
        case .sorrowful: "Sor"
        case .glorious: "Glo"
        case .luminous: "Lum"
        }
    }
}
