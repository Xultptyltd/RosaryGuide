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

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette
    @State private var prayLaunch: PrayLaunch?

    var body: some View {
        TabView {
            HomeView(prayLaunch: $prayLaunch)
                .tabItem { Label("Home", systemImage: "house") }

            PrayHubView(prayLaunch: $prayLaunch)
                .tabItem { Label("Pray", systemImage: "hands.sparkles") }

            HowToPrayView()
                .tabItem { Label("How to Pray", systemImage: "list.bullet") }

            FeastsView()
                .tabItem { Label("Feasts", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .toolbarBackground(palette.bg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
