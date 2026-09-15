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
        case .how: "How to"
        case .feasts: "Feasts"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .pray: "hands.sparkles"
        case .how: "book.closed"
        case .feasts: "calendar"
        case .settings: "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: "house.fill"
        case .pray: "hands.sparkles"
        case .how: "book.closed.fill"
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
        TabView(selection: $tab) {
            HomeView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            PrayHubView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.pray.title, systemImage: AppTab.pray.icon) }
                .tag(AppTab.pray)

            HowToPrayView()
                .tabItem { Label(AppTab.how.title, systemImage: AppTab.how.icon) }
                .tag(AppTab.how)

            FeastsView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.feasts.title, systemImage: AppTab.feasts.icon) }
                .tag(AppTab.feasts)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(palette.ink)
        .fullScreenCover(item: $prayLaunch) { launch in
            ThemedRoot {
                PrayView(launch: launch)
            }
            .environment(settings)
            .environment(session)
            .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}

#Preview {
    ThemedRoot {
        RootView()
    }
    .environment(SettingsStore())
    .environment(SessionStore())
}
