import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings = SettingsStore()
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
