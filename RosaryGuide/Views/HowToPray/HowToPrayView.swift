import SwiftUI

struct HowToPrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @State private var openStep: Int? = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How to pray")
                        .font(AppTheme.serif(36))
                    Text(HowToPrayContent.introduction.primary(for: settings.language))
                        .font(AppTheme.serif(18))
                        .foregroundStyle(palette.dim)

                    VStack(spacing: 0) {
                        ForEach(HowToPrayContent.steps) { step in
                            DisclosureGroup(isExpanded: expansion(step.id)) {
                                Text(step.body)
                                    .font(AppTheme.serif(17))
                                    .foregroundStyle(palette.dim)
                                    .padding(.bottom, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(step.id)")
                                        .font(AppTheme.sans(13, weight: .medium))
                                        .foregroundStyle(palette.faint)
                                        .frame(width: 24, alignment: .leading)
                                    Text(step.title.primary(for: settings.language))
                                        .font(AppTheme.serif(20))
                                        .foregroundStyle(palette.ink)
                                }
                            }
                            .tint(palette.ink)
                            Hairline()
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("When to pray which mysteries")
                            .font(AppTheme.sans(12, weight: .medium))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(palette.dim)
                            .padding(.top, 12)
                        ForEach(HowToPrayContent.weekdayGuide, id: \.0) { day, rule in
                            HStack(alignment: .top) {
                                Text(day)
                                    .font(AppTheme.sans(15, weight: .medium))
                                    .frame(width: 92, alignment: .leading)
                                Text(rule)
                                    .font(AppTheme.serif(16))
                                    .foregroundStyle(palette.dim)
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    Text(HowToPrayContent.beadsNote)
                        .font(AppTheme.serif(16))
                        .foregroundStyle(palette.dim)
                        .padding(.top, 8)

                    RosaryBeadMapView(locus: .decadeHail(1, 1))
                        .padding(.top, 4)
                }
                .padding(22)
            }
            .background(palette.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func expansion(_ id: Int) -> Binding<Bool> {
        Binding(
            get: { openStep == id },
            set: { openStep = $0 ? id : nil }
        )
    }
}
