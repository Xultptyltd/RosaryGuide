import SwiftUI

enum PrayLaunch: Identifiable, Hashable {
    case fresh(MysterySetKind)
    case resume(PrayerSession)

    var id: String {
        switch self {
        case .fresh(let set): "fresh-\(set.rawValue)"
        case .resume: "resume"
        }
    }

    var mysterySet: MysterySetKind {
        switch self {
        case .fresh(let set): set
        case .resume(let session): session.mysterySet
        }
    }
}

private enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, pray, how, feasts, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .pray: "Pray"
        case .how: "How to Pray"
        case .feasts: "Feasts"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .pray: "hands.sparkles"
        case .how: "list.bullet"
        case .feasts: "calendar"
        case .settings: "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: "house.fill"
        case .pray: "hands.sparkles"
        case .how: "list.bullet"
        case .feasts: "calendar"
        case .settings: "gearshape.fill"
        }
    }
}

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @State private var prayLaunch: PrayLaunch?
    @State private var tab: AppTab = .home

    var body: some View {
        tabRoot
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppTabBar(selection: $tab)
                    .background(palette.bg.ignoresSafeArea(edges: .bottom))
            }
            .fullScreenCover(item: $prayLaunch) { launch in
                ThemedRoot {
                    PrayView(launch: launch)
                }
                .environment(settings)
                .environment(session)
                .preferredColorScheme(settings.appearance.colorScheme)
            }
    }

    @ViewBuilder
    private var tabRoot: some View {
        switch tab {
        case .home:
            HomeView(prayLaunch: $prayLaunch)
        case .pray:
            PrayHubView(prayLaunch: $prayLaunch)
        case .how:
            HowToPrayView()
        case .feasts:
            FeastsView()
        case .settings:
            SettingsView()
        }
    }
}

private struct AppTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selection == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20, weight: .regular))
                        Text(tab.title)
                            .font(AppTheme.sans(10, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selection == tab ? palette.ink : palette.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .background(palette.bg)
        .overlay(alignment: .top) { Hairline() }
        .shadow(color: colorScheme == .light ? Color(hex: 0x171512).opacity(0.06) : Color.black.opacity(0.35), radius: 12, y: -2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabs")
    }
}

#Preview {
    ThemedRoot {
        RootView()
    }
    .environment(SettingsStore())
    .environment(SessionStore())
}
