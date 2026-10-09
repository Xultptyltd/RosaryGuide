import SwiftUI

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
                    .ignoresSafeArea()
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
            withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true)) {
                imageDrift = true
            }
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
    @State private var imageDrift = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                Image("OnboardingSignIn")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(reduceMotion ? 1 : 1.018)
                    .offset(y: geo.size.height * 0.10 + (reduceMotion ? 0 : (imageDrift ? -5 : 5)))
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.96), location: 0),
                        .init(color: Color.black.opacity(0.72), location: 0.26),
                        .init(color: Color.black.opacity(0.40), location: 0.54),
                        .init(color: Color.black.opacity(0.78), location: 0.70),
                        .init(color: Color.black.opacity(0.96), location: 0.86),
                        .init(color: Color.black, location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.095)

                    VStack(spacing: AppTheme.Space.lg) {
                        Image("IconPreviewWhite")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
                            .accessibilityHidden(true)

                        Text("Begin with\nRosary Guide.")
                            .font(AppTheme.TypeRole.title.weight(.regular))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .accessibilityAddTraits(.isHeader)

                        Text("Sign in to keep your Rosary Guide\naccount across your devices.")
                            .font(AppTheme.TypeRole.body)
                            .foregroundStyle(Color.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.horizontal, AppTheme.Space.lg)
                    }
                    .accessibilityElement(children: .combine)

                    Spacer(minLength: 0)

                    VStack(spacing: AppTheme.Space.md) {
                        OnboardingAuthButton(title: auth.isSigningInWithApple ? "Signing in..." : "Continue with Apple", systemImage: "apple.logo", filled: true) {
                            HapticService.play(.medium, enabled: settings.hapticsEnabled)
                            auth.signInWithApple()
                        }
                        .disabled(auth.isWorking)
                        .accessibilityLabel(auth.isSigningInWithApple ? "Signing in with Apple" : "Continue with Apple")

                        OnboardingAuthButton(title: auth.isSigningInWithGoogle ? "Signing in..." : "Continue with Google", letter: "G", filled: false) {
                            HapticService.play(.medium, enabled: settings.hapticsEnabled)
                            auth.signInWithGoogle()
                        }
                        .disabled(auth.isWorking)
                        .accessibilityLabel(auth.isSigningInWithGoogle ? "Signing in with Google" : "Continue with Google")

                        if let message = auth.errorMessage {
                            Text(message)
                                .font(AppTheme.TypeRole.caption())
                                .foregroundStyle(Color.white.opacity(0.62))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.top, AppTheme.Space.xs)
                            }
                    }
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.bottom, AppTheme.Space.xl)
                    .safeAreaPadding(.bottom)
                }
            }
        }
        .onChange(of: auth.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                completeIfSignedIn()
            }
        }
        .onAppear {
            completeIfSignedIn()
        }
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                imageDrift = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func completeIfSignedIn() {
        guard auth.isSignedIn else { return }
        HapticService.play(.medium, enabled: settings.hapticsEnabled)
        onComplete()
    }
}

private struct OnboardingAuthButton: View {
    var title: String
    var systemImage: String?
    var letter: String?
    var filled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .guideSymbol(size: 18, weight: .semibold)
                } else if let letter {
                    Text(letter)
                        .font(AppTheme.TypeRole.body(weight: .semibold))
                }

                Text(title)
                    .font(AppTheme.TypeRole.callout(weight: .semibold))
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
