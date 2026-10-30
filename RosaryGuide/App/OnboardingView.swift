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
            Color.black.ignoresSafeArea()

            if selection < pages.count {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, index: index, pageCount: pageCount)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .transition(.opacity)
            } else if includesSignIn {
                OnboardingSignInView(onComplete: onComplete)
                    .transition(.opacity)
            }

            VStack {
                Spacer()

                VStack(spacing: AppTheme.Space.lg) {
                    if !startsAtSignIn && selection < pages.count {
                        OnboardingDots(current: selection, count: pageCount)
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
                        .environment(\.palette, palette)
                        .accessibilityLabel(selection == pages.count - 1 ? "Begin, page \(selection + 1) of \(pageCount)" : "Continue, page \(selection + 1) of \(pageCount)")
                    }
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.bottom, AppTheme.Space.xl)
                .safeAreaPadding(.bottom)
            }
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: selection)
    }

    private var pageCount: Int {
        // The sign-in screen isn't a content page, so it isn't counted in the dots.
        pages.count
    }
}

private struct OnboardingPage: Identifiable {
    var id: String { title + body }
    var title: String
    var body: String
    var imageName: String

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Make room\nfor prayer.",
            body: "Slow down and draw closer to God\nthrough the Rosary.",
            imageName: "OnboardingRosaryDaily"
        ),
        OnboardingPage(
            title: "Every prayer,\ngently guided.",
            body: "New to the Rosary? Follow along,\none bead at a time.",
            imageName: "OnboardingBeads"
        ),
        OnboardingPage(
            title: "Bring what’s\non your heart.",
            body: "Pray for the people you love\nand the intentions you carry.",
            imageName: "OnboardingIntentions"
        )
    ]
}

private struct OnboardingPageView: View {
    var page: OnboardingPage
    var index: Int
    var pageCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var imageDrift = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(reduceMotion ? 1 : 1.018)
                    .offset(y: reduceMotion ? 0 : (imageDrift ? -5 : 5))
                    // Scoped to the drift value: a withAnimation(repeatForever) here used to
                    // capture the page's own layout as it appeared, so the screen shrank and slid.
                    .animation(reduceMotion ? nil : .easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: imageDrift)
                    .clipped()
                    .ignoresSafeArea(edges: .top)
                    .accessibilityHidden(true)

                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.18), location: 0),
                        .init(color: Color.black.opacity(0.10), location: 0.36),
                        .init(color: Color.black.opacity(0.68), location: 0.66),
                        .init(color: Color.black.opacity(0.96), location: 0.86),
                        .init(color: Color.black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(alignment: .center, spacing: AppTheme.Space.lg) {
                    Text(page.title)
                        .font(AppTheme.TypeRole.title.weight(.regular))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(page.body)
                        .font(AppTheme.TypeRole.body)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppTheme.gutter)
                .padding(.bottom, max(188, geo.safeAreaInsets.bottom + 164))
            }
        }
        .background(Color.black)
        .task {
            guard !reduceMotion else { return }
            imageDrift = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(page.title.replacingOccurrences(of: "\n", with: " ")). \(page.body.replacingOccurrences(of: "\n", with: " ")). Page \(index + 1) of \(pageCount).")
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
    static func panelHeight(screenHeight: CGFloat) -> CGFloat {
        (screenHeight * (screenHeight < 820 ? 0.45 : 0.5)).rounded()
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
    var onComplete: () -> Void

    @Environment(AuthStore.self) private var auth
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Which button last started a sign-in, so only that one shows progress.
    @State private var lastProvider: OnboardingAuthButton.Provider?
    @State private var succeeded = false
    @State private var shakes: CGFloat = 0

    private func buttonState(_ provider: OnboardingAuthButton.Provider) -> OnboardingAuthButton.Status {
        guard lastProvider == provider else { return .idle }
        if succeeded { return .done }
        let working = provider == .apple ? auth.isSigningInWithApple : auth.isSigningInWithGoogle
        return working ? .working : .idle
    }

    var body: some View {
        GeometryReader { geo in
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Marian blue panel behind the beads. It bleeds off the top of the screen and
                // the strands start above the top edge, so the rosary hangs from off screen.
                let panelHeight = SignInLayout.panelHeight(
                    screenHeight: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
                // The beads sit in an overlay so their width (which can exceed the panel's, the
                // sides being empty) doesn't widen the layout; the panel clips them.
                AppTheme.marianBlue
                    .frame(height: panelHeight)
                    .overlay(alignment: .bottom) {
                        RosaryBeadsFallPlayer(plays: !reduceMotion)
                            .aspectRatio(RosaryBeadsFallPlayer.aspectRatio, contentMode: .fit)
                            .frame(width: SignInLayout.beadsWidth(panelHeight: panelHeight))
                            .padding(.bottom, SignInLayout.loopBottomPadding)
                    }
                    // Marian blue fade under the status bar: the time, Dynamic Island and battery
                    // sit on clean blue and the strands emerge softly just below them.
                    .overlay(alignment: .top) {
                        LinearGradient(
                            stops: [.init(color: AppTheme.marianBlue, location: 0),
                                    .init(color: AppTheme.marianBlue, location: 0.4),
                                    .init(color: AppTheme.marianBlue.opacity(0), location: 1)],
                            startPoint: .top, endPoint: .bottom)
                            .frame(height: geo.safeAreaInsets.top + AppTheme.Space.xl)
                            .allowsHitTesting(false)
                    }
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: AppTheme.panelRadius,
                                                  bottomTrailingRadius: AppTheme.panelRadius,
                                                  style: .continuous))
                .padding(.horizontal, SignInLayout.panelInset)
                // Pull it up under the status bar in layout too, so the quote centres below it.
                .padding(.top, -geo.safeAreaInsets.top)
                .accessibilityHidden(true)

                Spacer(minLength: AppTheme.Space.lg)

                // Hero text: the quote alone, centred between the beads and the buttons.
                VStack(spacing: AppTheme.Space.md) {
                    // Same title style as Home's mystery-set title: H1 at the Home title size,
                    // using its compact step so the quote stays on two lines on every width.
                    GuideDisplayTitle(
                        text: OnboardingCopy.signInQuote,
                        size: SignInLayout.quoteSize,
                        color: .white
                    )
                    Text(OnboardingCopy.signInQuoteAttribution)
                        .font(AppTheme.TypeRole.body)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppTheme.gutter)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(OnboardingCopy.signInQuoteAccessibilityLabel)
                .guideReveal(delay: 0.05)

                Spacer(minLength: AppTheme.Space.xl)

                    VStack(spacing: AppTheme.Space.md) {
                        OnboardingAuthButton(title: auth.isSigningInWithApple ? "Signing in" : "Continue with Apple", systemImage: "apple.logo", filled: true, status: buttonState(.apple)) {
                            lastProvider = .apple
                            auth.signInWithApple()
                        }
                        .modifier(GuideShakeEffect(animatableData: lastProvider == .apple ? shakes : 0))
                        .disabled(auth.isWorking || succeeded)
                        .accessibilityLabel(auth.isSigningInWithApple ? "Signing in with Apple" : "Continue with Apple")

                        OnboardingAuthButton(title: auth.isSigningInWithGoogle ? "Signing in" : "Continue with Google", assetImage: "GoogleG", filled: false, status: buttonState(.google)) {
                            lastProvider = .google
                            auth.signInWithGoogle()
                        }
                        .modifier(GuideShakeEffect(animatableData: lastProvider == .google ? shakes : 0))
                        .disabled(auth.isWorking || succeeded)
                        .accessibilityLabel(auth.isSigningInWithGoogle ? "Signing in with Google" : "Continue with Google")

                        if let message = auth.errorMessage {
                            Text(message)
                                .font(AppTheme.TypeRole.caption())
                                .foregroundStyle(Color.white.opacity(0.62))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.top, AppTheme.Space.xs)
                                .transition(.opacity)
                        }

                        // Sign-in is optional: everything works on this device without an account.
                        // Always the last action, an underlined text button under the sign-in pills.
                        GuideTextButton(
                            title: OnboardingCopy.continueAsGuest,
                            accessibilityLabel: "Continue as guest. You can sign in later in Settings",
                            alignment: .center
                        ) {
                            HapticService.play(.light, enabled: settings.hapticsEnabled)
                            auth.errorMessage = nil
                            onComplete()
                        }
                        .environment(\.palette, ThemePalette(scheme: .dark))
                        .disabled(auth.isWorking)
                        .padding(.top, AppTheme.Space.xs)
                    }
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.bottom, AppTheme.Space.xl)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: auth.errorMessage)
                    .guideReveal(delay: 0.14)
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
            completeIfSignedIn()
        }
        .accessibilityElement(children: .contain)
    }

    private func completeIfSignedIn() {
        guard auth.isSignedIn else { return }
        onComplete()
    }

    /// One success haptic, a brief tick on the button, then on into the app.
    private func completeAfterSuccess() {
        guard !succeeded else { return }
        HapticService.play(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { succeeded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
    }
}

enum OnboardingCopy {
    static let continueAsGuest = "Continue as guest"
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
    var filled: Bool
    var status: Status = .idle
    var action: () -> Void

    enum Provider { case apple, google }
    enum Status { case idle, working, done }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.md) {
                if status == .working {
                    ProgressView()
                        .tint(filled ? Color.black : Color.white)
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
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(filled ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Component.pillHeight)
            .background(filled ? Color.white : Color.white.opacity(0.16), in: Capsule())
            .overlay {
                if !filled {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: AppTheme.Component.panelStrokeWidth)
                }
            }
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.2), value: status)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

private struct OnboardingDots: View {
    var current: Int
    var count: Int

    var body: some View {
        HStack(spacing: AppTheme.Space.sm) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.white : Color.white.opacity(0.28))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.22), value: current)
        .accessibilityLabel("Onboarding page \(current + 1) of \(count)")
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
