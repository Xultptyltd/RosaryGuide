import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings = SettingsStore()
    @State private var session = SessionStore()
    @State private var auth = AuthStore()
    @State private var offer = OfferStore()
    @State private var appIcon = AppIconService()
    @State private var isShowingSplash = true
    @AppStorage("onboarding.completed") private var didCompleteOnboarding = false

    init() {
        FontRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                ZStack {
                    if didCompleteOnboarding && auth.isSignedIn {
                        RootView()
                            .transition(.opacity)
                    } else {
                        OnboardingView(startsAtSignIn: didCompleteOnboarding) {
                            withAnimation(.easeOut(duration: 0.28)) {
                                didCompleteOnboarding = true
                            }
                        }
                        .transition(.opacity)
                    }

                    if isShowingSplash {
                        LaunchSplashView {
                            withAnimation(.easeOut(duration: 0.28)) {
                                isShowingSplash = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)
                    }
                }
                .animation(.easeInOut(duration: 0.32), value: didCompleteOnboarding)
                .animation(.easeInOut(duration: 0.32), value: auth.isSignedIn)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(settings)
            .environment(session)
            .environment(offer)
            .environment(auth)
            .environment(appIcon)
            .preferredColorScheme(settings.appearance.colorScheme)
            .onOpenURL { url in
                _ = auth.handleOpenURL(url)
            }
            .task {
                offer.configureSync(for: auth.userID)
                if auth.isSignedIn {
                    didCompleteOnboarding = true
                }
            }
            .onChange(of: auth.userID) { _, userID in
                offer.configureSync(for: userID)
                if userID == nil {
                    session.clearHistoryAndData()
                } else {
                    didCompleteOnboarding = true
                }
            }
        }
    }
}
