import SwiftUI
import Lottie

/// Native player for the Rosary Tick composition. The splash screen still uses
/// the bundled web player; that view cannot travel from the center of the
/// screen into the finish-screen icon slot.
struct RosaryTickPlayer: UIViewRepresentable {
    var plays: Bool
    var onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.backgroundBehavior = .pauseAndRestore
        return view
    }

    func updateUIView(_ view: LottieAnimationView, context: Context) {
        context.coordinator.onComplete = onComplete
        guard !context.coordinator.didStart else { return }
        context.coordinator.didStart = true

        let plays = plays
        let start: (LottieAnimation?) -> Void = { animation in
            view.animation = animation
            guard animation != nil else {
                DispatchQueue.main.async { context.coordinator.onComplete() }
                return
            }
            if plays {
                view.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce) { finished in
                    guard finished else { return }
                    DispatchQueue.main.async { context.coordinator.onComplete() }
                }
            } else {
                view.currentProgress = 1
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
        var onComplete: () -> Void
        init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }
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
