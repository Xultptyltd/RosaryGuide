import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings = SettingsStore()
    @State private var session = SessionStore()
    @State private var offer = OfferStore()

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
            .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
