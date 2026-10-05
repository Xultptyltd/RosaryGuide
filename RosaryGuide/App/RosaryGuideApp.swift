import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings: SettingsStore
    @State private var session: SessionStore
    @State private var auth: AuthStore
    @State private var offer: OfferStore
    @State private var appIcon: AppIconService
    @State private var sync: AccountSyncStore
    @State private var isShowingSplash = true
    @AppStorage("onboarding.completed") private var didCompleteOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FontRegistrar.register()
        // AuthStore configures Firebase, so it is created before anything that syncs.
        let auth = AuthStore()
        let settings = SettingsStore()
        let session = SessionStore()
        let appIcon = AppIconService()
        _auth = State(initialValue: auth)
        _settings = State(initialValue: settings)
        _session = State(initialValue: session)
        _appIcon = State(initialValue: appIcon)
        _offer = State(initialValue: OfferStore())
        _sync = State(initialValue: AccountSyncStore(settings: settings, session: session, appIcon: appIcon))
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
            .environment(sync)
            .preferredColorScheme(settings.appearance.colorScheme)
            .onOpenURL { url in
                _ = auth.handleOpenURL(url)
            }
            .task {
                offer.configureSync(for: auth.userID)
                sync.configureSync(for: auth.userID)
                if auth.isSignedIn {
                    didCompleteOnboarding = true
                }
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .background {
                    // Hand any waiting preference/progress changes to Firestore's offline queue.
                    sync.sceneWillLeaveForeground()
                }
                guard phase == .active else { return }
                sync.sceneBecameActive()
                // Refresh reminder copy and the rolling feast-day window.
                let plan = settings.notificationPlan
                guard !plan.isEmpty else { return }
                Task { await NotificationService.reschedule(plan) }
            }
            .onChange(of: auth.userID) { _, userID in
                // Signing out keeps data: intentions, preferences and prayer progress stay in the
                // account and in a per-account copy on this device. Another account gets its own
                // copy, so accounts never mix. Delete account clears everything explicitly.
                offer.configureSync(for: userID)
                sync.configureSync(for: userID)
                if userID != nil {
                    didCompleteOnboarding = true
                }
            }
        }
    }
}
