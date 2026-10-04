import SwiftUI
import WebKit

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            AppTheme.marianBlue
                .ignoresSafeArea()

            if reduceMotion {
                Text("R")
                    .font(AppTheme.TypeRole.serifDisplay)
                    .foregroundStyle(.white)
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.4) {
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
          instance.addEventListener('complete', function() {
            window.webkit.messageHandlers.splashDone.postMessage('complete');
          });
          setTimeout(function() {
            window.webkit.messageHandlers.splashDone.postMessage('fallback');
          }, 7200);
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
