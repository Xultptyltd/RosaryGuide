import SwiftUI

struct PrayHubView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @Binding var prayLaunch: PrayLaunch?

    private var assignment: MysteryAssignment {
        MysteryCalendar.assignment(on: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pray")
                        .font(AppTheme.serif(36, opticalSize: 36))
                        .foregroundStyle(palette.ink)
                    Text("Choose a mystery set, or continue a rosary already underway today.")
                        .font(AppTheme.sans(15))
                        .foregroundStyle(palette.dim)

                    if let resumable = session.resumableSession {
                        PillButton(title: "Continue \(resumable.mysterySet.shortName)") {
                            prayLaunch = .resume(resumable)
                        }
                    }

                    PillButton(title: "Pray today’s \(assignment.set.shortName) Mysteries") {
                        prayLaunch = .fresh(assignment.set)
                    }

                    ForEach(MysterySetKind.displayOrder) { set in
                        Button {
                            prayLaunch = .fresh(set)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                MysteryArtworkView(set: set, mysteryNumber: 1, slug: MysteryCatalog.mysteries(for: set).first?.artSlug, kind: .plateWide)
                                    .frame(height: 140)
                                    .clipped()
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(set.name.primary(for: settings.language))
                                            .font(AppTheme.serif(22))
                                            .foregroundStyle(palette.ink)
                                        Text(set.days(in: assignment.season))
                                            .font(AppTheme.sans(13))
                                            .foregroundStyle(palette.dim)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.gutter)
                .padding(.bottom, 12)
            }
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
