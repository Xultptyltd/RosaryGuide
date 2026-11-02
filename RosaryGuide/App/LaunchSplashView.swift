import SwiftUI
import WebKit

/// After a sign-in or new account: the sign-in screen fades to the plain page background
/// (black in dark mode, white in light), holds a beat while Home builds underneath, then Home
/// fades in. The sign-in screen plays the fade out; the app root holds the same plain cover
/// over the new Home and fades it away, so the hand-off is invisible. Timing only, never data.
enum SignInTransition {
    /// Success tick on the sign-in button before the screen fades.
    static let tick: Double = 0.3

    /// Opacity only, never scale or offset: Home measures its call to action in global space
    /// to place the hero, so a transform during the fade moved the artwork.
    enum Style: Equatable {
        case standard
        /// Reduce Motion: shorter fades, no scale.
        case reduced

        var fadeOut: Animation { .easeInOut(duration: self == .standard ? 0.35 : 0.2) }
        var fadeOutDuration: Double { self == .standard ? 0.35 : 0.2 }
        /// On the plain cover, with Home built underneath.
        var hold: Double { self == .standard ? 0.15 : 0.1 }
        var fadeIn: Animation { .easeInOut(duration: self == .standard ? 0.65 : 0.3) }
    }
}

/// The plain page background between the sign-in screen and Home. A tap skips ahead.
struct SignInTransitionCover: View {
    var onTap: () -> Void = {}
    @Environment(\.palette) private var palette

    var body: some View {
        palette.background
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityHidden(true)
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
