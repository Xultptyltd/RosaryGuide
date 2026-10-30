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
        pages.count + (includesSignIn ? 1 : 0)
    }
}

private struct OnboardingPage: Identifiable {
    var id: String { title + body }
    var title: String
    var body: String
    var imageName: String

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "The Rosary,\nwith you each day.",
            body: "Pray the mysteries of the day,\none bead at a time.",
            imageName: "OnboardingRosaryDaily"
        ),
        OnboardingPage(
            title: "Simply follow\nthe beads.",
            body: "Every prayer and mystery is here,\nfrom beginning to end.",
            imageName: "OnboardingBeads"
        ),
        OnboardingPage(
            title: "Bring your\nintentions to prayer.",
            body: "Offer your Rosary for the people\nand intentions closest to your heart.",
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

                VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                    Text(page.title)
                        .font(AppTheme.TypeRole.title.weight(.regular))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Text(page.body)
                        .font(AppTheme.TypeRole.body)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // The strands start at the composition's top edge, which sits on the screen's
                // top edge (through the status bar), so the rosary hangs from above the screen.
                RosaryBeadsFallPlayer(plays: !reduceMotion)
                    .aspectRatio(RosaryBeadsFallPlayer.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: 380)
                    .padding(.horizontal, AppTheme.Space.lg)
                    .ignoresSafeArea(edges: .top)
                    .accessibilityHidden(true)

                VStack(spacing: AppTheme.Space.md) {
                    Text(OnboardingCopy.signInHeadline)
                        .font(AppTheme.TypeRole.serifDisplay)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(OnboardingCopy.signInSupporting)
                        .font(AppTheme.TypeRole.body)
                        .foregroundStyle(Color.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.xl + 48)
                .accessibilityElement(children: .combine)
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

                        OnboardingAuthButton(title: auth.isSigningInWithGoogle ? "Signing in" : "Continue with Google", letter: "G", filled: false, status: buttonState(.google)) {
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
    static let signInHeadline = "Make room for prayer"
    static let signInSupporting = "The Rosary each day, one bead at a time"
}

private struct OnboardingAuthButton: View {
    var title: String
    var systemImage: String?
    var letter: String?
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


/// Hero animation on the sign-in screen. The composition (600×500, 60 fps, frames 0–1584)
/// feeds the chain down from above the frame one bead at a time until it settles around
/// frame 1494, then a small sway eases to rest by 1584. It has no idle loop, so it plays
/// once and holds the settled last frame. With Reduce Motion it shows that frame only.
struct RosaryBeadsFallPlayer: UIViewRepresentable {
    static let aspectRatio: CGFloat = 600.0 / 500.0
    static let lastFrame: AnimationFrameTime = 1584

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
        animationView.loopMode = .playOnce
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
            animationView.play(fromFrame: 0, toFrame: Self.lastFrame, loopMode: .playOnce) { _ in
                animationView.currentFrame = Self.lastFrame
            }
        } else {
            animationView.currentFrame = Self.lastFrame
        }
        return container
    }

    func updateUIView(_ view: UIView, context: Context) {}
}
