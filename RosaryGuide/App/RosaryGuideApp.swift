import SwiftUI

@main
struct RosaryGuideApp: App {
    @State private var settings: SettingsStore
    @State private var session: SessionStore
    @State private var auth: AuthStore
    @State private var offer: OfferStore
    @State private var appIcon: AppIconService
    @State private var sync: AccountSyncStore
    @State private var dayClock = DayClock()
    @State private var isShowingSplash = true
    /// Bumped after a sign-in: rebuilding the tabs closes every sheet and pushed page and
    /// starts on Home.
    @State private var rootGeneration = 0
    private var landing: AppLanding { AppLanding.shared }
    /// DEBUG `-RGDebugSignInTransition`: holds the sign-in screen up (even with a saved session)
    /// and plays the sign-in transition into Home, with no sign-in. Always false in release.
    @State private var previewsSignInTransition = DebugHooks.has("-RGDebugSignInTransition")
    @AppStorage("onboarding.completed") private var didCompleteOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        GuideChrome.applyAtLaunch()
        // On-device MetricKit diagnostics; registration runs off the main thread.
        MetricsCollector.shared.start()
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

    private func finishSignInTransition() {
        guard let style = landing.signInTransition else { return }
        landing.buildsHomeEarly = false
        withAnimation(style.fadeIn) { landing.signInTransition = nil }
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                ZStack {
                    // Signing in is optional (App Review 5.1.1(v)): guests use everything on this
                    // device, and an account only adds sync.
                    let showsApp = !previewsSignInTransition && LaunchGate.showsApp(
                        didCompleteOnboarding: didCompleteOnboarding, isSignedIn: auth.isSignedIn,
                        signedInThisLaunch: auth.interactiveSignIns > 0)
                    // After an onboarding sign-in, Home is built (hidden) under the sign-in screen
                    // during its success tick, so the plain cover isn't held while Home lays out.
                    if showsApp || landing.buildsHomeEarly {
                        RootView()
                            .id(rootGeneration)
                            .scaleEffect(landing.signInTransition?.homeScale ?? 1)
                            .opacity(showsApp ? 1 : 0)
                            .allowsHitTesting(showsApp)
                            .accessibilityHidden(!showsApp)
                    }
                    if !showsApp {
                        OnboardingView {
                            // A sign-in hands its cover over first, so Home opens under it.
                            withTransaction(AppLanding.still) {
                                didCompleteOnboarding = true
                                previewsSignInTransition = false
                            }
                        }
                    }

                    if let style = landing.signInTransition {
                        SignInTransitionCover(onTap: finishSignInTransition)
                            .transition(.opacity)
                            .zIndex(2)
                            .task {
                                // A beat on the plain cover while Home lays out, then Home fades in.
                                try? await Task.sleep(for: .seconds(style.hold))
                                finishSignInTransition()
                            }
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(settings)
            .environment(session)
            .environment(offer)
            .environment(auth)
            .environment(appIcon)
            .environment(sync)
            .environment(dayClock)
            .preferredColorScheme(settings.appearance.colorScheme)
            .onChange(of: settings.appearance, initial: true) { _, appearance in
                AppearanceWindowStyle.apply(appearance)
            }
            // Reschedule on any reminder/feast-alert change, from any screen or sync,
            // not only while the Notifications page is open.
            .onChange(of: settings.notificationPlan) { _, plan in
                Task { await NotificationService.reschedule(plan) }
            }
            // A new day: refresh reminder copy and the rolling feast-day window.
            .onChange(of: dayClock.today) { _, _ in
                let plan = settings.notificationPlan
                guard !plan.isEmpty else { return }
                Task { await NotificationService.reschedule(plan) }
            }
            #if DEBUG
            .task {
                if DebugHooks.has("-RGDebugSignedIn") {
                    try? await Task.sleep(for: .seconds(1))
                    auth.debugSetSignedIn(true, interactive: false)
                }
                if DebugHooks.has("-RGDebugSignIn") {
                    try? await Task.sleep(for: .seconds(8))
                    auth.debugSetSignedIn(true, interactive: true)
                }
            }
            #endif
            .onChange(of: AppLanding.shared.homeRequests) { _, _ in
                // Profile's sign-in: Home with nothing on top. Covers go first, without
                // animation, so none is left behind when the tabs are rebuilt.
                AppLanding.dismissPresentedInstantly()
                withTransaction(AppLanding.still) { rootGeneration += 1 }
            }
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
                dayClock.refresh()
                sync.sceneBecameActive()
                // Refresh reminder copy and the rolling feast-day window.
                let plan = settings.notificationPlan
                guard !plan.isEmpty else { return }
                Task { await NotificationService.reschedule(plan) }
            }
            .onChange(of: auth.userID) { previous, userID in
                // Signing out keeps data: intentions, preferences and prayer progress stay in the
                // account and on this device, and the app carries on as a guest (no sync). Another
                // account gets its own copy, so accounts never mix. Delete account clears everything.
                offer.configureSync(for: userID)
                sync.configureSync(for: userID)
                if userID != nil {
                    // A restored session skips onboarding. A sign-in from the onboarding
                    // screen finishes there, after its tick.
                    if auth.interactiveSignIns == 0 { didCompleteOnboarding = true }
                } else if LaunchGate.returnsToOnboarding(previousUserID: previous, userID: userID) {
                    // Signing out or deleting the account goes back to the sign-in screen, in
                    // place: no cross-fade (it overlapped the tab content fading out and read
                    // as a glitch).
                    // Close Settings (or any cover) first, without animation. Swapping the
                    // tabs out from under an open cover left it orphaned, and UIKit shrank
                    // it into the bottom-left corner.
                    AppLanding.dismissPresentedInstantly()
                    withTransaction(AppLanding.still) { didCompleteOnboarding = false }
                }
            }
        }
    }
}

/// Which screen the app opens on. Onboarding shows once; after that the app is always open,
/// signed in or not. Signing in (from onboarding or Settings) only turns on sync.
enum LaunchGate {
    /// Leaving an account (sign out or delete) shows onboarding again.
    static func returnsToOnboarding(previousUserID: String?, userID: String?) -> Bool {
        previousUserID != nil && userID == nil
    }

    /// A sign-in made on the onboarding screen keeps that screen up for its tick; the
    /// app opens when onboarding completes.
    static func showsApp(didCompleteOnboarding: Bool, isSignedIn: Bool, signedInThisLaunch: Bool = false) -> Bool {
        didCompleteOnboarding || (isSignedIn && !signedInThisLaunch)
    }
}

/// A sign-in or new account from Profile lands on Home with nothing on top. Sign-ins
/// from Settings stay on Settings; onboarding opens the app on Home anyway.
@MainActor @Observable
final class AppLanding {
    static let shared = AppLanding()
    private(set) var homeRequests = 0
    /// After a sign-in: the plain cover held over Home until Home fades in.
    var signInTransition: SignInTransition.Style?
    /// From an onboarding sign-in's success: build Home hidden under the sign-in screen.
    var buildsHomeEarly = false
    func requestHome() { homeRequests += 1 }

    static var still: Transaction {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        return transaction
    }

    /// Closes every sheet and full-screen cover at once, with no animation.
    static func dismissPresentedInstantly() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows where window.rootViewController?.presentedViewController != nil {
            window.rootViewController?.dismiss(animated: false)
        }
    }
}
