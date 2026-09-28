import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings = SettingsStore()
    @State private var session = SessionStore()
    @State private var offer = OfferStore()
    @State private var appIcon = AppIconService()

    init() {
        FontRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                RootView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(settings)
            .environment(session)
            .environment(offer)
            .environment(appIcon)
            .preferredColorScheme(settings.appearance.colorScheme)
            .task {
                await PopeIntentionStore.shared.refreshIfNeeded()
            }
        }
    }
}
