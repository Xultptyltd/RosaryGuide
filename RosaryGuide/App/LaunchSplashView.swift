import SwiftUI
import WebKit

/// The moment after a sign-in or new account, before Home: the R-with-halo mark rises in on the
/// app background, its halo blooms in Marian blue, and a short welcome sits under it.
/// The sign-in screen plays the entrance; the app root shows the same view, settled, over the
/// new Home and fades it away, so the hand-off between the two is invisible.
enum SignInWelcomeMotion {
    /// Success tick on the sign-in button before the screen starts to leave.
    static let tick: Double = 0.3
    /// Sign-in content fades and scales down while the welcome fades in.
    static let leave = Animation.easeInOut(duration: 0.35)
    static let leaveScale: CGFloat = 0.96
    /// The mark rises in, then the halo blooms, then the words.
    static let markIn = MotionTokens.reveal.delay(0.12)
    static let bloom = Animation.easeOut(duration: 0.9).delay(0.2)
    static let wordsIn = MotionTokens.reveal.delay(0.42)
    /// From the start of the leave to the hand-off to Home (the bloom has settled by then).
    static let hold: Double = 1.15
    /// The welcome fades away over Home, which settles from a touch smaller.
    static let reveal = Animation.easeInOut(duration: 0.45)
    static let homeScale: CGFloat = 0.985
    /// Reduce Motion: a plain cross-fade through the app background.
    static let plainFade = Animation.easeInOut(duration: 0.25)
    static let plainHold: Double = 0.3
}

/// Hands the welcome from the sign-in screen to the app root.
struct SignInWelcome: Equatable {
    var firstName: String?
    /// Reduce Motion: background only, no mark, glow or scale.
    var plain: Bool

    var greeting: String {
        guard let firstName, !firstName.isEmpty else { return "Welcome" }
        return "Welcome, \(firstName)"
    }

    static func firstName(from displayName: String?) -> String? {
        displayName?.split(separator: " ").first.map(String.init)
    }
}

struct SignInWelcomeView: View {
    var welcome: SignInWelcome
    /// False at the app root: it appears already settled, matching the sign-in screen's last frame.
    var animatesIn = true
    var onTap: () -> Void = {}

    @Environment(\.palette) private var palette
    @State private var markShown = false
    @State private var bloomed = false
    @State private var wordsShown = false

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            if !welcome.plain {
                VStack(spacing: AppTheme.Space.xl) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.marianBlue)
                            .frame(width: 132, height: 132)
                            .scaleEffect(bloomed ? 1.3 : 0.55)
                            .blur(radius: bloomed ? 44 : 18)
                            .opacity(bloomed ? 0.5 : 0)
                        Image("LogoMark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                            .foregroundStyle(palette.ink)
                    }
                    .scaleEffect(markShown ? 1 : 0.88)
                    .opacity(markShown ? 1 : 0)

                    Text(welcome.greeting)
                        .font(AppTheme.TypeRole.headingSecondary)
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.center)
                        .opacity(wordsShown ? 1 : 0)
                        .offset(y: wordsShown ? 0 : 8)
                }
                .padding(.horizontal, AppTheme.gutter)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(welcome.greeting)
        .accessibilityAddTraits(.isStaticText)
        .onAppear {
            guard animatesIn, !welcome.plain else {
                markShown = true; bloomed = true; wordsShown = true
                return
            }
            withAnimation(SignInWelcomeMotion.markIn) { markShown = true }
            withAnimation(SignInWelcomeMotion.bloom) { bloomed = true }
            withAnimation(SignInWelcomeMotion.wordsIn) { wordsShown = true }
        }
    }
}

struct LaunchSplashView: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            AppTheme.marianBlue
                .ignoresSafeArea()

            if reduceMotion {
                Text("R")
                    .font(AppTheme.TypeRole.serifDisplay)
                    .foregroundStyle(palette.onAccent)
                    .accessibilityHidden(true)
            } else {
                LottieSplashPlayer(onFinished: onFinished)
                    .frame(width: 144, height: 144)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Rosary Guide loading")
        .onAppear {
            guard reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: onFinished)
        }
    }
}

private struct LottieSplashPlayer: UIViewRepresentable {
    var onFinished: () -> Void

    /// The 7.0 s composition plays 1.4× faster (about 5.0 s).
    static let speed = 1.4
    /// JS fallback, started when the script runs: the animation length plus the same 0.2 s
    /// margin as before.
    static let jsFallbackMilliseconds = 5200
    /// Native safety net from web view creation, in case the page never reports back. Counts
    /// from before the page loads (0.1–0.3 s), so it keeps the original 0.4 s margin.
    static let fallbackSeconds = 5.6

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "splashDone")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        webView.loadHTMLString(Self.html, baseURL: Bundle.main.resourceURL)

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fallbackSeconds) {
            context.coordinator.finish()
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private var didFinish = false
        private let onFinished: () -> Void

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            finish()
        }

        func finish() {
            guard !didFinish else { return }
            didFinish = true
            onFinished()
        }
    }

    private static var html: String {
        let player = bundledText(named: "lottie", extension: "min.js")
        let animation = bundledText(named: "rosary_loader_intro_dark", extension: "json")

        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            html, body, #animation {
              width: 100%;
              height: 100%;
              margin: 0;
              padding: 0;
              overflow: hidden;
              background: transparent;
            }
            svg { display: block; }
          </style>
        </head>
        <body>
          <div id="animation"></div>
          <script>
          \(player)
          const animationData = \(animation);
          const instance = lottie.loadAnimation({
            container: document.getElementById('animation'),
            renderer: 'svg',
            loop: false,
            autoplay: true,
            animationData: animationData
          });
          instance.setSpeed(\(speed));
          instance.addEventListener('complete', function() {
            window.webkit.messageHandlers.splashDone.postMessage('complete');
          });
          setTimeout(function() {
            window.webkit.messageHandlers.splashDone.postMessage('fallback');
          }, \(jsFallbackMilliseconds));
          </script>
        </body>
        </html>
        """
    }

    private static func bundledText(named name: String, extension ext: String) -> String {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Animations"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return ""
        }
        return text
    }
}
