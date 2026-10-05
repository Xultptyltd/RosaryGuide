import SwiftUI
import Lottie
#if canImport(UIKit)
import UIKit
#endif

/// Native player for the Rosary Tick composition. The splash screen still uses
/// the bundled web player; that view cannot travel from the center of the
/// screen into the finish-screen icon slot.
struct RosaryTickPlayer: UIViewRepresentable {
    /// Last frame where the tick and ring are still fully drawn.
    /// The composition fades every layer out by frame 96; holding frame 82
    /// keeps the tick on screen so it can travel into the icon slot.
    static let holdProgress: AnimationProgressTime = 82.0 / 96.0
    /// Trim of the tick stroke reaches 100% at frame 70 (30 fps).
    static let strokeDoneProgress: AnimationProgressTime = 70.0 / 96.0

    var plays: Bool
    var hapticsEnabled: Bool
    var onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false
        // Plain UIView has no intrinsic size. The Lottie view's 1024×1024
        // composition must not become the SwiftUI layout size.
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundColor = .clear
        animationView.isUserInteractionEnabled = false
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        animationView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        animationView.setContentHuggingPriority(.defaultLow, for: .vertical)
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        context.coordinator.animationView = animationView
        return container
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.onComplete = onComplete
        guard !context.coordinator.didStart else { return }
        context.coordinator.didStart = true

        guard let animationView = context.coordinator.animationView else { return }
        let plays = plays
        let start: (LottieAnimation?) -> Void = { animation in
            animationView.animation = animation
            guard animation != nil else {
                DispatchQueue.main.async { context.coordinator.onComplete() }
                return
            }
            if plays {
                context.coordinator.prepareTickHaptic()
                animationView.play(
                    fromProgress: 0,
                    toProgress: RosaryTickPlayer.strokeDoneProgress,
                    loopMode: .playOnce
                ) { finished in
                    guard finished else { return }
                    context.coordinator.playTickHaptic(enabled: hapticsEnabled)
                    animationView.play(
                        fromProgress: RosaryTickPlayer.strokeDoneProgress,
                        toProgress: RosaryTickPlayer.holdProgress,
                        loopMode: .playOnce
                    ) { finished in
                        guard finished else { return }
                        animationView.currentProgress = RosaryTickPlayer.holdProgress
                        DispatchQueue.main.async { context.coordinator.onComplete() }
                    }
                }
            } else {
                animationView.currentProgress = RosaryTickPlayer.holdProgress
            }
        }

        if let cached = RosaryTickLibrary.cachedAnimation() {
            start(cached)
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let animation = RosaryTickLibrary.load()
                DispatchQueue.main.async { start(animation) }
            }
        }
    }

    final class Coordinator {
        var didStart = false
        var didTickHaptic = false
        var animationView: LottieAnimationView?
        var onComplete: () -> Void
        #if canImport(UIKit)
        private let tickHaptic = UIImpactFeedbackGenerator(style: .light)
        #endif
        init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }

        func prepareTickHaptic() {
            #if canImport(UIKit)
            tickHaptic.prepare()
            #endif
        }

        /// One light tap when the tick stroke finishes. Not a buzz.
        func playTickHaptic(enabled: Bool) {
            guard enabled, !didTickHaptic else { return }
            didTickHaptic = true
            #if canImport(UIKit)
            tickHaptic.impactOccurred(intensity: 0.7)
            #endif
        }
    }
}

enum RosaryTickLibrary {
    private static let lock = NSLock()
    private static var cached: LottieAnimation?

    /// Decode off the button action and off the view update. The fade gives
    /// this a head start so the first frame is not spent parsing the file.
    static func preload() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = load()
        }
    }

    static func cachedAnimation() -> LottieAnimation? {
        lock.lock()
        defer { lock.unlock() }
        return cached
    }

    static func load() -> LottieAnimation? {
        lock.lock()
        if let cached {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let animation = LottieAnimation.named(
            "RosaryTick",
            bundle: .main,
            subdirectory: "Animations",
            animationCache: nil
        )
        lock.lock()
        if cached == nil { cached = animation }
        lock.unlock()
        return animation
    }
}
