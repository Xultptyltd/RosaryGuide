import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings = SettingsStore()
    @State private var session = SessionStore()

    init() {
        FontRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                RootView()
            }
            .environment(settings)
            .environment(session)
            .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
