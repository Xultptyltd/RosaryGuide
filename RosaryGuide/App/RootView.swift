import SwiftUI

enum PrayLaunch: Identifiable, Hashable {
    case fresh(MysterySetKind, intentionId: UUID? = nil)
    case resume(PrayerSession)

    var id: String {
        switch self {
        case .fresh(let set, let intentionId):
            let suffix = intentionId?.uuidString ?? "none"
            return "fresh-\(set.rawValue)-\(suffix)"
        case .resume:
            return "resume"
        }
    }

    var mysterySet: MysterySetKind {
        switch self {
        case .fresh(let set, _): set
        case .resume(let session): session.mysterySet
        }
    }

    var intentionId: UUID? {
        switch self {
        case .fresh(_, let intentionId): intentionId
        case .resume(let session): session.intentionId
        }
    }
}


private enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case today, pray, calendar, intentions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .pray: "Learn"
        case .calendar: "Feasts"
        case .intentions: "Intentions"
        }
    }

    var icon: String {
        switch self {
        case .today: "sun.max"
        case .pray: "book.closed"
        case .calendar: "calendar"
        case .intentions: "heart.text.square"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: "sun.max.fill"
        case .pray: "book.closed.fill"
        case .calendar: "calendar"
        case .intentions: "heart.text.square.fill"
        }
    }
}

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(\.palette) private var palette
    @State private var prayLaunch: PrayLaunch?
    @State private var tab: AppTab = .today

    var body: some View {
        TabView(selection: $tab) {
            HomeView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.today.title, systemImage: tab == .today ? AppTab.today.selectedIcon : AppTab.today.icon) }
                .tag(AppTab.today)

            PrayHubView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.pray.title, systemImage: tab == .pray ? AppTab.pray.selectedIcon : AppTab.pray.icon) }
                .tag(AppTab.pray)

            FeastsView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.calendar.title, systemImage: AppTab.calendar.icon) }
                .tag(AppTab.calendar)

            OfferView(prayLaunch: $prayLaunch)
                .tabItem { Label(AppTab.intentions.title, systemImage: tab == .intentions ? AppTab.intentions.selectedIcon : AppTab.intentions.icon) }
                .tag(AppTab.intentions)

        }
        .tint(palette.accent)
        .fullScreenCover(item: $prayLaunch) { launch in
            ThemedRoot {
                PrayView(launch: launch)
            }
            .environment(settings)
            .environment(session)
            .environment(offer)
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
    .environment(OfferStore())
}
