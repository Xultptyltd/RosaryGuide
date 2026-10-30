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
        GeometryReader { geo in
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // The strands start at the composition's top edge, which sits on the screen's
                // top edge (through the status bar), so the rosary hangs from above the screen.
                RosaryBeadsChainView(animates: !reduceMotion)
                    .aspectRatio(RosaryBeadsChainView.aspectRatio, contentMode: .fit)
                    .frame(maxWidth: 380)
                    .padding(.horizontal, AppTheme.Space.lg)
                    // Pull the player up under the status bar in layout too (not just drawing),
                    // so the headline sits right under the loop.
                    .padding(.top, -geo.safeAreaInsets.top)
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
                .padding(.top, AppTheme.Space.xl)
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


/// Hero on the sign-in screen: a rosary hanging in a U from above the top edge, its chain
/// flowing slowly down the left strand, round the loop and up the right one.
///
/// Drawn procedurally rather than with Lottie so it can loop forever with no seam: the
/// bead pattern (10 Hail Mary beads, then 1 Our Father bead) repeats every `period` points
/// of arc length, and the phase is time × speed modulo that period, so every frame is a
/// shifted copy of the same endless chain and both strands are always full of beads.
/// The shape, sizes and colours match the original Lottie (600-unit-wide space, loop
/// bottom at y≈644 of 680). With Reduce Motion it draws one still frame.
struct RosaryBeadsChainView: View {
    var animates: Bool

    static let aspectRatio: CGFloat = 600.0 / 680.0
    static let space = CGSize(width: 600, height: 680)

    static let smallDiameter: CGFloat = 23
    static let largeDiameter: CGFloat = 35.65
    /// Clear string between neighbouring beads, so centre spacing is r1 + r2 + gap
    /// (41 between Hail Marys, matching the original strands).
    static let gap: CGFloat = 18
    static let beadsPerDecade = 11
    /// Units of arc length per second; the original fed about 17.
    static let speed: Double = 20

    /// Pattern index 0 is the Our Father bead, 1…10 the Hail Marys.
    static func diameter(at index: Int) -> CGFloat {
        index % beadsPerDecade == 0 ? largeDiameter : smallDiameter
    }

    static func spacing(after index: Int) -> CGFloat {
        (diameter(at: index) + diameter(at: index + 1)) / 2 + gap
    }

    /// Arc length of one decade; the chain looks identical after moving this far.
    static let period: CGFloat = (0..<beadsPerDecade).reduce(0) { $0 + spacing(after: $1) }

    static func phase(at seconds: Double) -> CGFloat {
        CGFloat((seconds * speed).truncatingRemainder(dividingBy: Double(period)))
    }

    /// Settled centre-line of the original chain (left half; the right is mirrored),
    /// extended above the top edge so beads enter and leave off screen.
    private static let leftHalf: [CGPoint] = [
        CGPoint(x: 146, y: -90), CGPoint(x: 154, y: 201), CGPoint(x: 155, y: 247), CGPoint(x: 157, y: 294),
        CGPoint(x: 161, y: 334), CGPoint(x: 166, y: 374), CGPoint(x: 172, y: 413), CGPoint(x: 179, y: 453),
        CGPoint(x: 187, y: 493), CGPoint(x: 197, y: 532), CGPoint(x: 207, y: 570), CGPoint(x: 225, y: 606),
        CGPoint(x: 255, y: 632), CGPoint(x: 300, y: 644)
    ]

    /// Dense, smoothed polyline (Catmull-Rom) with cumulative arc lengths.
    static let track: (points: [CGPoint], lengths: [CGFloat]) = {
        let half = leftHalf
        let control = half + half.dropLast().reversed().map { CGPoint(x: 600 - $0.x, y: $0.y) }
        var points: [CGPoint] = []
        for i in 0..<(control.count - 1) {
            let p0 = control[max(i - 1, 0)], p1 = control[i], p2 = control[i + 1], p3 = control[min(i + 2, control.count - 1)]
            for step in 0..<12 {
                let t = CGFloat(step) / 12, t2 = t * t, t3 = t2 * t
                func c(_ a: CGFloat, _ b: CGFloat, _ cc: CGFloat, _ d: CGFloat) -> CGFloat {
                    0.5 * (2 * b + (-a + cc) * t + (2 * a - 5 * b + 4 * cc - d) * t2 + (-a + 3 * b - 3 * cc + d) * t3)
                }
                points.append(CGPoint(x: c(p0.x, p1.x, p2.x, p3.x), y: c(p0.y, p1.y, p2.y, p3.y)))
            }
        }
        points.append(control[control.count - 1])
        var lengths: [CGFloat] = [0]
        for i in 1..<points.count {
            lengths.append(lengths[i - 1] + hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y))
        }
        return (points, lengths)
    }()

    static var trackLength: CGFloat { track.lengths.last ?? 0 }

    static func point(atArcLength s: CGFloat) -> CGPoint {
        let (points, lengths) = track
        var lo = 0, hi = lengths.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if lengths[mid] <= s { lo = mid } else { hi = mid }
        }
        let span = max(lengths[hi] - lengths[lo], 0.0001)
        let f = min(max((s - lengths[lo]) / span, 0), 1)
        return CGPoint(x: points[lo].x + (points[hi].x - points[lo].x) * f,
                       y: points[lo].y + (points[hi].y - points[lo].y) * f)
    }

    /// Arc-length positions and pattern indices of every bead on the track at a phase.
    static func beads(phase: CGFloat) -> [(s: CGFloat, index: Int)] {
        var result: [(s: CGFloat, index: Int)] = []
        let wrapped = phase.truncatingRemainder(dividingBy: period)
        var s = (wrapped < 0 ? wrapped + period : wrapped) - period
        var index = 0
        let end = trackLength + largeDiameter
        while s <= end {
            if s >= -largeDiameter { result.append((s, index)) }
            s += spacing(after: index)
            index = (index + 1) % beadsPerDecade
        }
        return result
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !animates)) { timeline in
            let seconds = animates ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { context, size in
                Self.draw(in: &context, size: size, phase: Self.phase(at: seconds))
            }
        }
    }

    private static let shading = Gradient(stops: [
        .init(color: Color(red: 1.0, green: 1.0, blue: 0.9882), location: 0),
        .init(color: Color(red: 0.9608, green: 0.949, blue: 0.9098), location: 0.3),
        .init(color: Color(red: 0.8392, green: 0.8157, blue: 0.7529), location: 0.7),
        .init(color: Color(red: 0.5412, green: 0.5216, blue: 0.4627), location: 1)
    ])

    static func draw(in context: inout GraphicsContext, size: CGSize, phase: CGFloat) {
        let scale = size.width / space.width
        context.scaleBy(x: scale, y: scale)

        var string = Path()
        string.addLines(track.points)
        context.stroke(string, with: .color(Color(red: 0.62, green: 0.65, blue: 0.72).opacity(0.85)), lineWidth: 1.5)

        for bead in beads(phase: phase) {
            let c = point(atArcLength: bead.s)
            let d = diameter(at: bead.index), r = d / 2
            let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: d, height: d))
            let light = CGPoint(x: c.x - r * 0.35, y: c.y - r * 0.4)
            context.fill(circle, with: .radialGradient(shading, center: light, startRadius: 0, endRadius: r * 1.45))
            context.stroke(circle, with: .color(Color(red: 0.42, green: 0.4, blue: 0.35).opacity(0.4)), lineWidth: 0.8)
            let glint = CGRect(x: c.x - r * 0.38 - d * 0.125, y: c.y - r * 0.44 - d * 0.085, width: d * 0.25, height: d * 0.17)
            context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(0.8)))
        }
    }
}
