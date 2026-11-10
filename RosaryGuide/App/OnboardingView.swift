import SwiftUI
import Lottie
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingView: View {
    var startsAtSignIn = false
    var includesSignIn = true
    var onComplete: () -> Void

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsStore.self) private var settings
    @State private var selection = 0

    private let pages = OnboardingPage.pages

    init(startsAtSignIn: Bool = false, includesSignIn: Bool = true, onComplete: @escaping () -> Void) {
        self.startsAtSignIn = startsAtSignIn
        self.includesSignIn = includesSignIn
        self.onComplete = onComplete
        _selection = State(initialValue: startsAtSignIn && includesSignIn ? OnboardingPage.pages.count : 0)
        #if DEBUG
        if includesSignIn && DebugHooks.has("-RGDebugSignInScreen") { _selection = State(initialValue: OnboardingPage.pages.count) }
        #if DEBUG
        // Screenshot hook: -RGDebugOnboardingPage <n> opens content page n (0-based).
        if let n = Int(UserDefaults.standard.string(forKey: "RGDebugOnboardingPage") ?? ""), OnboardingPage.pages.indices.contains(n) {
            _selection = State(initialValue: n)
        }
        #endif
        #endif
    }

    var body: some View {
        ZStack {
            palette.bg.ignoresSafeArea()

            if selection < pages.count {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, index: index, pageCount: pageCount,
                                           titleColor: palette.ink, bodyColor: palette.dim, pageColor: palette.bg)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .transition(.opacity)
            } else if includesSignIn {
                // Onboarding opens the app; the Profile and Settings sheets just close for a guest.
                OnboardingSignInView(guestLandsOnHome: !startsAtSignIn, onComplete: onComplete)
                    .transition(.opacity)
            }

            VStack {
                Spacer()

                VStack(spacing: AppTheme.Space.lg) {
                    if !startsAtSignIn && selection < pages.count {
                        OnboardingDots(current: selection, count: pageCount,
                                       activeColor: palette.ink, inactiveColor: palette.strokeStrong)
                    }

                    if selection < pages.count {
                        PillButton(title: selection == pages.count - 1 ? "Begin" : "Continue") {
                            HapticService.play(.light, enabled: settings.hapticsEnabled)
                            if selection == pages.count - 1 && !includesSignIn {
                                onComplete()
                            } else {
                                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
                                    selection += 1
                                }
                            }
                        }
                        .accessibilityLabel(selection == pages.count - 1 ? "Begin, page \(selection + 1) of \(pageCount)" : "Continue, page \(selection + 1) of \(pageCount)")
                    }
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.bottom, AppTheme.Space.xl)
                .safeAreaPadding(.bottom)
            }
        }
        // Follows the app's appearance. The art panels (black, or Marian blue on sign-in) run
        // under the status bar, so light mode hides the bar's dark icons, like the Rosary
        // introduction.
        .statusBarHidden(palette.scheme == .light)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: selection)
    }

    private var pageCount: Int {
        // The sign-in screen isn't a content page, so it isn't counted in the dots.
        pages.count
    }
}

struct OnboardingPage: Identifiable {
    var id: String { title + body }
    var title: String
    var body: String
    var imageName: String
    /// Which part of the image stays in view when the panel crops it.
    var imageAlignment: Alignment = .top

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Make room\nfor prayer.",
            body: "Slow down and draw closer to God\nthrough the Rosary.",
            imageName: "OnboardingRosaryDaily"
        ),
        OnboardingPage(
            title: "Every prayer,\ngently guided.",
            body: "New to the Rosary? Follow along,\none bead at a time.",
            imageName: "OnboardingBeads",
            imageAlignment: .center
        ),
        OnboardingPage(
            title: "Bring what’s\non your heart.",
            body: "Pray for the people you love\nand the intentions you carry.",
            imageName: "OnboardingIntentions"
        )
    ]
}

struct OnboardingPageView: View {
    var page: OnboardingPage
    var index: Int
    var pageCount: Int
    /// Lets longer copy (e.g. the Rosary introduction) scroll at large text sizes.
    var scrollsText = true
    /// Footer space kept clear below the copy (taller when a page has two buttons).
    var controlsHeight: CGFloat = OnboardingLayout.controlsHeight
    /// Callers pass palette tokens; the art panel stays black in both appearances.
    var titleColor: Color
    var bodyColor: Color
    var pageColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var imageDrift = false

    /// Room for the page dots, Continue, and a gap after the last body line.
    /// The overlay pill grows with Dynamic Type, so accessibility sizes keep a
    /// second pill-height plus extra gap — 132 pt is only enough at default size.
    private var footerClearance: CGFloat {
        let chrome = controlsHeight + AppTheme.Space.xl
        if dynamicTypeSize.isAccessibilitySize {
            return chrome + AppTheme.Component.pillHeight + AppTheme.Space.xxl
        }
        return chrome
    }

    private var textBlock: some View {
            VStack(alignment: .center, spacing: AppTheme.Space.lg) {
                Text(page.title)
                    .font(AppTheme.TypeRole.title.weight(.regular))
                    .foregroundStyle(titleColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(page.body)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(bodyColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, AppTheme.Space.xl)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Same panel as the sign-in screen, filled black, with the page's image inside.
                OnboardingPanel(fill: .black, geo: geo) { _ in
                    Color.clear
                        .overlay(alignment: page.imageAlignment) {
                            Image(page.imageName)
                                .resizable()
                                .scaledToFill()
                                .accessibilityHidden(true)
                                .scaleEffect(reduceMotion ? 1 : 1.018)
                                .offset(y: reduceMotion ? 0 : (imageDrift ? -5 : 5))
                                // Scoped to the drift value: a withAnimation(repeatForever) here
                                // used to capture the page's own layout, so the screen slid.
                                .animation(reduceMotion ? nil : .easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: imageDrift)
                        }
                        .clipped()
                }

                Spacer(minLength: AppTheme.Space.lg)

                if scrollsText {
                    // Choose by the copy's ideal height. A maxHeight: .infinity frame
                    // made ViewThatFits treat the text as always fitting, which clipped
                    // the last body line under Continue at accessibility sizes.
                    ViewThatFits(in: .vertical) {
                        textBlock
                        ScrollView(.vertical, showsIndicators: false) { textBlock }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    textBlock
                }

                Spacer(minLength: AppTheme.Space.lg)

                // Room for the dots, a gap after the body, and the Continue button overlay.
                Color.clear.frame(height: footerClearance)
            }
        }
        .background(pageColor)
        .task {
            guard !reduceMotion else { return }
            imageDrift = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(page.title.replacingOccurrences(of: "\n", with: " ")). \(page.body.replacingOccurrences(of: "\n", with: " ")). Page \(index + 1) of \(pageCount).")
    }
}

/// Layout of the onboarding content pages.
enum OnboardingLayout {
    /// Height below the text kept clear for the page dots and the Continue button.
    static let controlsHeight: CGFloat = 132
}

/// The hero panel shared by the onboarding pages and the sign-in screen: inset from the sides,
/// running off the top of the screen under the status bar, with rounded bottom corners and a
/// fade in its fill colour behind the status bar icons.
struct OnboardingPanel<Content: View>: View {
    var fill: Color
    var geo: GeometryProxy
    var compact: Bool = false
    @ViewBuilder var content: (_ panelHeight: CGFloat) -> Content

    var body: some View {
        let panelHeight = SignInLayout.panelHeight(
            screenHeight: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom,
            compact: compact)
        fill
            .frame(height: panelHeight)
            .overlay { content(panelHeight) }
            .overlay(alignment: .top) {
                LinearGradient(
                    stops: [.init(color: fill, location: 0),
                            .init(color: fill, location: 0.4),
                            .init(color: fill.opacity(0), location: 1)],
                    startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.safeAreaInsets.top + AppTheme.Space.xl)
                    .allowsHitTesting(false)
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: AppTheme.panelRadius,
                                              bottomTrailingRadius: AppTheme.panelRadius,
                                              style: .continuous))
            .padding(.horizontal, SignInLayout.panelInset)
            // Pull it up under the status bar in layout too, so the text centres below it.
            .padding(.top, -geo.safeAreaInsets.top)
            .accessibilityHidden(true)
    }
}

/// Layout of the sign-in hero.
enum SignInLayout {
    /// Space between the bottom of the loop and the panel's bottom edge.
    static let loopBottomPadding: CGFloat = 40
    /// How far the strands' start sits above the screen's top edge, so they run off screen.
    static let strandOverflow: CGFloat = 36
    /// Outer inset of the panel from the screen edges.
    static let panelInset: CGFloat = 24
    /// Panel height measured from the screen's top edge: half the screen, or a little less on
    /// short phones (SE/mini) so the quote and buttons below don't crowd.
    static func panelHeight(screenHeight: CGFloat, compact: Bool = false) -> CGFloat {
        let fraction: CGFloat
        if compact {
            // Leave most of the screen for the quote and sign-in buttons at accessibility sizes.
            fraction = screenHeight < 820 ? 0.28 : 0.32
        } else {
            fraction = screenHeight < 820 ? 0.45 : 0.5
        }
        return (screenHeight * fraction).rounded()
    }
    /// Beads width that fills the panel: the strands start `strandOverflow` above the screen's
    /// top edge and the loop sits `loopBottomPadding` above the panel's bottom edge.
    static func beadsWidth(panelHeight: CGFloat) -> CGFloat {
        ((panelHeight - loopBottomPadding + strandOverflow) * RosaryBeadsFallPlayer.aspectRatio).rounded()
    }
    /// One design-system step below Home's compact title (38.4): the headingPrimary size (32).
    static let quoteSize: CGFloat = 32
}

private struct OnboardingSignInView: View {
    /// Continue as guest opens Home with the same fade as a sign-in (onboarding only).
    var guestLandsOnHome = false
    var onComplete: () -> Void

    @Environment(AuthStore.self) private var auth
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Which button last started a sign-in, so only that one shows progress.
    @State private var lastProvider: OnboardingAuthButton.Provider?
    @State private var succeeded = false
    @State private var shakes: CGFloat = 0
    /// After a sign-in: this screen is fading to the plain cover.
    @State private var leaving: SignInTransition.Style?
    @State private var handedOff = false


    @ViewBuilder
    private func signInLowerContent(spacious: Bool) -> some View {
        VStack(spacing: 0) {
            // Hero text: the quote alone, centred between the beads and the buttons.
            VStack(spacing: AppTheme.Space.md) {
                GuideDisplayTitle(
                    text: OnboardingCopy.signInQuote,
                    size: SignInLayout.quoteSize,
                    color: palette.ink
                )
                Text(OnboardingCopy.signInQuoteAttribution)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.dim)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppTheme.gutter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(OnboardingCopy.signInQuoteAccessibilityLabel)
            .guideReveal(delay: 0.05)

            if spacious {
                Spacer(minLength: AppTheme.Space.xl)
            } else {
                Color.clear.frame(height: AppTheme.Space.xl)
            }

            VStack(spacing: AppTheme.Space.md) {
                OnboardingAuthButton(title: auth.isSigningInWithApple ? "Signing in" : "Continue with Apple", systemImage: "apple.logo", provider: .apple, status: buttonState(.apple)) {
                    lastProvider = .apple
                    auth.signInWithApple()
                }
                .modifier(GuideShakeEffect(animatableData: lastProvider == .apple ? shakes : 0))
                .disabled(auth.isWorking || succeeded || leaving != nil)
                .accessibilityLabel(auth.isSigningInWithApple ? "Signing in with Apple" : "Continue with Apple")

                OnboardingAuthButton(title: auth.isSigningInWithGoogle ? "Signing in" : "Continue with Google", assetImage: "GoogleG", provider: .google, status: buttonState(.google)) {
                    lastProvider = .google
                    auth.signInWithGoogle()
                }
                .modifier(GuideShakeEffect(animatableData: lastProvider == .google ? shakes : 0))
                .disabled(auth.isWorking || succeeded || leaving != nil)
                .accessibilityLabel(auth.isSigningInWithGoogle ? "Signing in with Google" : "Continue with Google")

                if let message = auth.errorMessage {
                    Text(message)
                        .font(AppTheme.TypeRole.caption())
                        .foregroundStyle(palette.dim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, AppTheme.Space.xs)
                        .transition(.opacity)
                }

                GuideTextButton(
                    title: OnboardingCopy.continueAsGuest,
                    accessibilityLabel: "Continue as guest. You can sign in later in Settings",
                    alignment: .center
                ) {
                    HapticService.play(.light, enabled: settings.hapticsEnabled)
                    auth.errorMessage = nil
                    continueAsGuest()
                }
                .disabled(auth.isWorking || leaving != nil)
                .padding(.top, AppTheme.Space.xs)

                Text(OnboardingCopy.legalNotice)
                    .font(AppTheme.TypeRole.caption())
                    .foregroundStyle(palette.dim)
                    .tint(palette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppTheme.Space.sm)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, AppTheme.Space.xl)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: auth.errorMessage)
            .guideReveal(delay: 0.14)
        }
        .frame(maxWidth: .infinity)
    }

    private func buttonState(_ provider: OnboardingAuthButton.Provider) -> OnboardingAuthButton.Status {
        guard lastProvider == provider else { return .idle }
        if succeeded { return .done }
        let working = provider == .apple ? auth.isSigningInWithApple : auth.isSigningInWithGoogle
        return working ? .working : .idle
    }

    var body: some View {
        GeometryReader { geo in
        ZStack {
            palette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Marian blue panel behind the beads. It bleeds off the top of the screen and
                // the strands start above the top edge, so the rosary hangs from off screen.
                // At accessibility sizes the panel shrinks so the quote and buttons stay reachable.
                OnboardingPanel(
                    fill: AppTheme.brandCanvas(colorScheme),
                    geo: geo,
                    compact: dynamicTypeSize.isAccessibilitySize
                ) { panelHeight in
                    // The beads sit in an overlay so their width (which can exceed the panel's,
                    // the sides being empty) doesn't widen the layout; the panel clips them.
                    RosaryBeadsFallPlayer(plays: !reduceMotion)
                        .accessibilityHidden(true)
                        .aspectRatio(RosaryBeadsFallPlayer.aspectRatio, contentMode: .fit)
                        .frame(width: SignInLayout.beadsWidth(panelHeight: panelHeight))
                        .padding(.bottom, SignInLayout.loopBottomPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        ScrollView(.vertical, showsIndicators: false) {
                            signInLowerContent(spacious: false)
                                .padding(.top, AppTheme.Space.lg)
                        }
                    } else {
                        Spacer(minLength: AppTheme.Space.lg)
                        signInLowerContent(spacious: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        }
        .onChange(of: auth.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                completeAfterSuccess()
            }
        }
        .onChange(of: auth.isWorking) { was, working in
            // A finished attempt with a message is an error. Cancel finishes with no
            // message, so it just resets quietly.
            guard was, !working, !auth.isSignedIn, auth.errorMessage != nil else { return }
            HapticService.play(.warning, enabled: settings.hapticsEnabled)
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.42)) { shakes += 1 }
        }
        .onAppear {
            #if DEBUG
            // `-RGDebugHoldSignIn` keeps this screen up on a signed-in simulator for screenshots.
            guard !DebugHooks.has("-RGDebugSignInTransition"), !DebugHooks.has("-RGDebugProfileSignInTransition"),
                  !DebugHooks.has("-RGDebugGuestTransition"), !DebugHooks.has("-RGDebugHoldSignIn") else { return }
            #endif
            completeIfSignedIn()
        }
        #if DEBUG
        // `-RGDebugSignInTransition`: plays the success and transition into Home after 10 s
        // (past the launch splash), with no sign-in. `-RGDebugProfileSignInTransition` does the
        // same from Profile's create-account sheet, 2 s after it opens.
        .task {
            let fromProfile = DebugHooks.has("-RGDebugProfileSignInTransition")
            guard fromProfile || DebugHooks.has("-RGDebugSignInTransition") else { return }
            try? await Task.sleep(for: .seconds(fromProfile ? 2 : 10))
            lastProvider = .apple
            completeAfterSuccess()
        }
        // `-RGDebugGuestTransition`: taps Continue as guest after 10 s (past the launch splash).
        .task {
            guard DebugHooks.has("-RGDebugGuestTransition") else { return }
            try? await Task.sleep(for: .seconds(10))
            continueAsGuest()
        }
        #endif
        .accessibilityElement(children: .contain)
        // The content fades out with the cover coming in, so nothing of it can show as the
        // screen goes.
        .opacity(leaving == nil ? 1 : 0)
        .overlay {
            if leaving != nil {
                SignInTransitionCover(onTap: handOff)
                    .transition(.opacity)
            }
        }
    }

    private func completeIfSignedIn() {
        guard auth.isSignedIn else { return }
        onComplete()
    }

    /// One success haptic and a brief tick on the button. Then this screen fades to the plain
    /// cover and the app root carries the cover over Home, which fades in. Timing only: Home
    /// is under the cover from the hand-off, whatever its data is doing, and a tap skips ahead.
    private func completeAfterSuccess() {
        guard !succeeded else { return }
        HapticService.play(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { succeeded = true }
        withTransaction(AppLanding.still) { AppLanding.shared.buildsHomeEarly = true }
        let style: SignInTransition.Style = reduceMotion ? .reduced : .standard
        DispatchQueue.main.asyncAfter(deadline: .now() + SignInTransition.tick) {
            withAnimation(style.fadeOut) { leaving = style }
            DispatchQueue.main.asyncAfter(deadline: .now() + style.fadeOutDuration) { handOff() }
        }
    }

    /// Guest from onboarding: no tick or success haptic (nothing succeeded; the button keeps its
    /// light tap), then the same fade into Home as a sign-in. From a sheet: just close.
    private func continueAsGuest() {
        guard guestLandsOnHome else {
            onComplete()
            return
        }
        guard leaving == nil else { return }
        withTransaction(AppLanding.still) { AppLanding.shared.buildsHomeEarly = true }
        let style: SignInTransition.Style = reduceMotion ? .reduced : .standard
        // A turn of the run loop first, so Home's hidden first layout lands before the fade starts.
        DispatchQueue.main.async {
            withAnimation(style.fadeOut) { leaving = style }
            DispatchQueue.main.asyncAfter(deadline: .now() + style.fadeOutDuration) { handOff() }
        }
    }

    private func handOff() {
        guard let leaving, !handedOff else { return }
        handedOff = true
        withTransaction(AppLanding.still) { AppLanding.shared.signInTransition = leaving }
        onComplete()
    }
}

enum OnboardingCopy {
    static let continueAsGuest = "Continue as guest"
    static let termsURL = "https://xult.ltd/terms/"
    static let privacyURL = "https://xult.ltd/privacy/"
    /// Sign-in footnote on two fixed lines; the two document names open the published pages.
    static var legalNotice: AttributedString {
        var notice = AttributedString("By continuing you agree to our\n")
        notice += (try? AttributedString(markdown: "[Terms & Conditions](\(termsURL)) and [Privacy Policy](\(privacyURL)).")) ?? AttributedString("Terms & Conditions and Privacy Policy.")
        for run in notice.runs where run.link != nil {
            notice[run.range].underlineStyle = .single
        }
        return notice
    }
    /// Rosarium Virginis Mariae §39 heading (Vatican English text).
    static let signInQuoteText = "A chain that links heaven and earth"
    /// Displayed with a fixed break so it sits on two balanced lines.
    static let signInQuote = "\u{201C}A chain that links\nheaven and earth\u{201D}"
    static let signInQuoteAuthor = "St Thérèse of Lisieux"
    static let signInQuoteAttribution = "Attributed to " + signInQuoteAuthor
    static let signInQuoteAccessibilityLabel = signInQuoteText + ", attributed to " + signInQuoteAuthor
}

private struct OnboardingAuthButton: View {
    var title: String
    var systemImage: String?
    var letter: String?
    /// Full-colour vector asset (rendered as original, not tinted).
    var assetImage: String?
    var provider: Provider
    var status: Status = .idle
    var action: () -> Void

    @Environment(\.palette) private var palette

    enum Provider { case apple, google }
    enum Status { case idle, working, done }

    private var fill: Color { provider == .apple ? palette.appleButtonFill : palette.googleButtonFill }
    private var text: Color { provider == .apple ? palette.appleButtonText : palette.googleButtonText }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.md) {
                if status == .working {
                    ProgressView()
                        .tint(text)
                        .transition(.opacity)
                } else if status == .done {
                    Image(systemName: "checkmark")
                        .guideSymbol(size: 18, weight: .semibold)
                        .transition(.opacity)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .guideSymbol(size: 18, weight: .semibold)
                } else if let assetImage {
                    Image(assetImage)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                } else if let letter {
                    Text(letter)
                        .font(AppTheme.TypeRole.body(weight: .semibold))
                }

                Text(title)
                    .font(AppTheme.TypeRole.pillLabel(weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(text)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppTheme.Component.pillHeight)
            .background(fill, in: Capsule())
            .overlay {
                if provider == .google {
                    Capsule()
                        .strokeBorder(palette.googleButtonStroke, lineWidth: 1)
                }
            }
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.2), value: status)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct OnboardingDots: View {
    var current: Int
    var count: Int
    var label = "Onboarding page"
    var activeColor: Color
    var inactiveColor: Color

    var body: some View {
        HStack(spacing: AppTheme.Space.sm) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? activeColor : inactiveColor)
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.22), value: current)
        .accessibilityLabel("\(label) \(current + 1) of \(count)")
    }
}

#Preview {
    OnboardingView {}
        .environment(SettingsStore())
        .environment(SessionStore())
        .environment(OfferStore())
        .environment(AuthStore())
}


/// Hero animation on the sign-in screen. The composition (600×680 after tools/lottie/extend_rosary_beads.py, 60 fps, frames 0–1584)
/// feeds the chain down from above the frame one bead at a time, a decade (11 beads) per
/// cycle, then a small sway eases to rest by 1584. The script makes the last frame
/// identical to frame 0, so it loops forever with no visible seam. With Reduce Motion it
/// shows that settled frame only.
struct RosaryBeadsFallPlayer: UIViewRepresentable {
    /// Composition is 600×680 after tools/lottie/extend_rosary_beads.py lengthened the strands.
    static let aspectRatio: CGFloat = 600.0 / 680.0
    static let lastFrame: AnimationFrameTime = 1584
    static let loopMode: LottieLoopMode = .loop

    var plays: Bool

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false
        container.clipsToBounds = true
        let animationView = LottieAnimationView(
            animation: LottieAnimation.named("RosaryBeadsFall", bundle: .main, subdirectory: "Animations")
        )
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundColor = .clear
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = Self.loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            animationView.setContentCompressionResistancePriority(.defaultLow, for: axis)
            animationView.setContentHuggingPriority(.defaultLow, for: axis)
        }
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        if plays {
            animationView.play(fromFrame: 0, toFrame: Self.lastFrame, loopMode: Self.loopMode)
        } else {
            animationView.currentFrame = Self.lastFrame
        }
        return container
    }

    func updateUIView(_ view: UIView, context: Context) {}
}
