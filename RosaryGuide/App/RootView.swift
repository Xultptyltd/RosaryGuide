import SwiftUI

enum PrayLaunch: Identifiable, Hashable {
    case fresh(MysterySetKind, intentionId: UUID? = nil, startingDecade: Int? = nil)
    case resume(PrayerSession)

    var id: String {
        switch self {
        case .fresh(let set, let intentionId, let decade):
            let suffix = intentionId?.uuidString ?? "none"
            return "fresh-\(set.rawValue)-\(suffix)-\(decade ?? 0)"
        case .resume:
            return "resume"
        }
    }

    func startIndex(in steps: [RosaryStep]) -> Int {
        guard case .fresh(_, _, let decade) = self, let decade else { return 0 }
        return steps.firstIndex { $0.decadeNumber == decade && $0.kind == .mysteryAnnouncement } ?? 0
    }

    var mysterySet: MysterySetKind {
        switch self {
        case .fresh(let set, _, _): set
        case .resume(let session): session.mysterySet
        }
    }

    var intentionId: UUID? {
        switch self {
        case .fresh(_, let intentionId, _): intentionId
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
        case .pray: "Pray"
        case .calendar: "Feasts"
        case .intentions: "Profile"
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

    /// SF Symbol (outline; ".fill" when selected) used instead of an asset.
    var systemSymbol: String? {
        self == .intentions ? "person.crop.circle" : nil
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
    @State private var tab: AppTab = DebugHooks.once("-RGDebugProfileTab") ? .intentions : .today

    var body: some View {
        rootTabs
            .task {
                // Screenshot hook (DebugHooks is DEBUG-only): opens the Rosary's settings sheet.
                guard DebugHooks.has("-RGDebugRosaryFlowSettings") else { return }
                try? await Task.sleep(for: .seconds(3))
                prayLaunch = .fresh(.joyful)
            }
            .fullScreenCover(item: $prayLaunch) { launch in
                ThemedRoot {
                    PrayView(launch: launch)
                }
                .environment(settings)
                .environment(session)
                .environment(offer)
                .environment(auth)
                .preferredColorScheme(settings.appearance.colorScheme)
                // VoiceOver stays inside the prayer flow, not on Home behind it.
                .accessibilityAddTraits(.isModal)
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
            if let symbol = item.systemSymbol {
                Image(systemName: tab == item ? "\(symbol).fill" : symbol)
            } else {
                Image(tab == item ? item.selectedIconAsset : item.iconAsset)
                    .renderingMode(.template)
            }
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
    .environment(DayClock())
}

/// Launch-argument hooks for reproducing transitions in the simulator. Always false in release.
enum DebugHooks {
    static func has(_ flag: String) -> Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(flag)
        #else
        false
        #endif
    }

    #if DEBUG
    nonisolated(unsafe) private static var used: Set<String> = []
    #endif
    /// True only the first time it's asked, so a rebuilt view starts from its real default.
    static func once(_ flag: String) -> Bool {
        #if DEBUG
        guard has(flag), !used.contains(flag) else { return false }
        used.insert(flag)
        return true
        #else
        false
        #endif
    }
}
