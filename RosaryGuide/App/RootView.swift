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
    @State private var prayLaunch: PrayLaunch?

    var body: some View {
        TabView {
            HomeView(prayLaunch: $prayLaunch)
                .tabItem { Label("Home", systemImage: "house.fill") }

            PrayHubView(prayLaunch: $prayLaunch)
                .tabItem { Label("Pray", systemImage: "hands.sparkles.fill") }

            HowToPrayView()
                .tabItem { Label("How to Pray", systemImage: "list.number") }

            FeastsView()
                .tabItem { Label("Feasts", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(AppTheme.gold)
        .fullScreenCover(item: $prayLaunch) { launch in
            PrayView(launch: launch)
                .environment(settings)
                .environment(session)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}

#Preview {
    RootView()
        .environment(SettingsStore())
        .environment(SessionStore())
}
