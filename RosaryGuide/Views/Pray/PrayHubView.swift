import SwiftUI

struct PrayHubView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Binding var prayLaunch: PrayLaunch?

    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose a mystery set, or continue a rosary already underway.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let resumable = session.resumableSession {
                        Button {
                            prayLaunch = .resume(resumable)
                        } label: {
                            Label("Resume \(resumable.mysterySet.name.english)", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.gold)
                        .foregroundStyle(AppTheme.deepNavy)
                    }

                    Button {
                        prayLaunch = .fresh(assignment.set)
                    } label: {
                        Label("Pray today’s \(assignment.set.name.english)", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.marianBlue)

                    ForEach(MysterySetKind.allCases) { set in
                        Button {
                            prayLaunch = .fresh(set)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                MysteryArtworkView(set: set, mysteryNumber: 1, showsCaption: false)
                                    .frame(maxHeight: 140)
                                    .clipped()
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(set.name.primary(for: settings.language))
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(set.weekdayNames)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(set.tint)
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pray")
        }
    }
}
