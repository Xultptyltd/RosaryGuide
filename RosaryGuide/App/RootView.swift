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
        case .intentions: "Prayer"
        }
    }

    var iconAsset: String {
        switch self {
        case .today: "TabTodayOutline"
        case .pray: "TabLearnOutline"
        case .calendar: "TabFeastsOutline"
        case .intentions: "TabIntentionsOutline"
        }
    }

    var selectedIconAsset: String {
        switch self {
        case .today: "TabTodayFilled"
        case .pray: "TabLearnFilled"
        case .calendar: "TabFeastsFilled"
        case .intentions: "TabIntentionsFilled"
        }
    }
}

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(AuthStore.self) private var auth
    @Environment(\.palette) private var palette
    @State private var prayLaunch: PrayLaunch?
    @State private var tab: AppTab = .today

    var body: some View {
        rootTabs
            .tint(palette.accent)
            .fullScreenCover(item: $prayLaunch) { launch in
                ThemedRoot {
                    PrayView(launch: launch)
                }
                .environment(settings)
                .environment(session)
                .environment(offer)
                .environment(auth)
                .preferredColorScheme(settings.appearance.colorScheme)
            }
    }

    @ViewBuilder
    private var rootTabs: some View {
        let tabs = TabView(selection: $tab) {
            HomeView(prayLaunch: $prayLaunch)
                .tabItem { tabLabel(.today) }
                .tag(AppTab.today)

            PrayHubView(prayLaunch: $prayLaunch)
                .tabItem { tabLabel(.pray) }
                .tag(AppTab.pray)

            FeastsView(prayLaunch: $prayLaunch)
                .tabItem { tabLabel(.calendar) }
                .tag(AppTab.calendar)

            OfferView(prayLaunch: $prayLaunch)
                .tabItem { tabLabel(.intentions) }
                .tag(AppTab.intentions)
        }

        if #available(iOS 18.0, *) {
            tabs.tabViewStyle(.sidebarAdaptable)
        } else {
            tabs
        }
    }

    @ViewBuilder
    private func tabLabel(_ item: AppTab) -> some View {
        Label {
            Text(item.title)
        } icon: {
            Image(tab == item ? item.selectedIconAsset : item.iconAsset)
                .renderingMode(.template)
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
    .environment(AuthStore())
}
