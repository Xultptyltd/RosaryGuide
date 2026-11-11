import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - iOS 17 deployment compatibility
//
// The app's deployment target is iOS 17 so @Observable, sensoryFeedback,
// scrollTargetBehavior, and the other 17-only APIs stay in their natural form.
// iOS 26 Liquid Glass and the iOS 18 scroll-geometry APIs are reached through
// these wrappers: on iOS 26 / 18 the original API is used unchanged; older
// systems get a token-styled fallback.

/// Scroll metrics shared with `ScrollMorph` and the prayer / guide CTAs.
/// Mirrors the iOS 18 `ScrollGeometry` fields those call sites actually read.
struct GuideScrollGeometry: Equatable {
    var contentOffset: CGPoint
    var contentSize: CGSize
    var containerSize: CGSize
    var contentInsets: EdgeInsets

    @available(iOS 18.0, *)
    init(_ geometry: ScrollGeometry) {
        contentOffset = geometry.contentOffset
        contentSize = geometry.contentSize
        containerSize = geometry.containerSize
        contentInsets = geometry.contentInsets
    }

    init(
        contentOffset: CGPoint,
        contentSize: CGSize,
        containerSize: CGSize,
        contentInsets: EdgeInsets
    ) {
        self.contentOffset = contentOffset
        self.contentSize = contentSize
        self.containerSize = containerSize
        self.contentInsets = contentInsets
    }
}

/// Programmatic scroll request. `generation` bumps on every `scrollTo` so
/// repeating "go to top" still applies after the user has scrolled away
/// (the stored target may already be `.top`).
struct GuideScrollPosition: Equatable {
    enum Target: Equatable {
        case top
        case bottom
        case y(CGFloat)
    }

    var target: Target
    var generation: UInt
    /// `false` for a hard reset (page change); `true` when the CTA animates down.
    var animated: Bool

    static var top: GuideScrollPosition {
        GuideScrollPosition(target: .top, generation: 0, animated: false)
    }

    mutating func scrollTo(y: CGFloat, animated: Bool = true) {
        target = .y(y)
        self.animated = animated
        generation &+= 1
    }

    mutating func scrollTo(edge: VerticalEdge, animated: Bool? = nil) {
        target = (edge == .top) ? .top : .bottom
        self.animated = animated ?? (edge != .top)
        generation &+= 1
    }
}

/// Subset of iOS 18 `ScrollPhase` used to cancel an armed CTA scroll.
enum GuideScrollPhase: Equatable {
    case idle
    case interacting
}

extension View {
    /// iOS 26: `safeAreaBar`. Older: `safeAreaInset`, which keeps the chrome
    /// pinned to the edge without the Liquid Glass bar role.
    @ViewBuilder
    func guideSafeAreaBar<Bar: View>(
        edge: VerticalEdge,
        spacing: CGFloat = 0,
        @ViewBuilder content: () -> Bar
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: edge, spacing: spacing, content: content)
        } else {
            self.safeAreaInset(edge: edge, spacing: spacing, content: content)
        }
    }

    /// iOS 26: hides the system scroll-edge effect so our frosted chrome is
    /// the only blur. Older iOS has no edge effect; this is a no-op.
    @ViewBuilder
    func guideScrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectHidden(hidden, for: edges)
        } else {
            self
        }
    }

    func guideOnScrollGeometryChange<T: Equatable>(
        for transformType: T.Type = T.self,
        of transform: @escaping (GuideScrollGeometry) -> T,
        action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        modifier(GuideOnScrollGeometryChangeModifier(transform: transform, action: action))
    }

    func guideOnScrollPhaseChange(
        _ action: @escaping (_ oldPhase: GuideScrollPhase, _ newPhase: GuideScrollPhase) -> Void
    ) -> some View {
        modifier(GuideOnScrollPhaseChangeModifier(action: action))
    }

    func guideScrollPosition(_ position: Binding<GuideScrollPosition>) -> some View {
        modifier(GuideScrollPositionModifier(position: position))
    }

}

// MARK: - Scroll geometry

private struct GuideOnScrollGeometryChangeModifier<T: Equatable>: ViewModifier {
    let transform: (GuideScrollGeometry) -> T
    let action: (T, T) -> Void

    @State private var last: T?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: T.self) { geometry in
                transform(GuideScrollGeometry(geometry))
            } action: { oldValue, newValue in
                action(oldValue, newValue)
            }
        } else {
            content.background(
                GuideScrollProbe(
                    onGeometry: { geometry in
                        let value = transform(geometry)
                        let previous = last ?? value
                        if last == nil || previous != value {
                            last = value
                            action(previous, value)
                        }
                    }
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            )
        }
    }
}

private struct GuideOnScrollPhaseChangeModifier: ViewModifier {
    let action: (GuideScrollPhase, GuideScrollPhase) -> Void
    @State private var last: GuideScrollPhase = .idle

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { oldPhase, newPhase in
                action(Self.map(oldPhase), Self.map(newPhase))
            }
        } else {
            content.background(
                GuideScrollProbe(
                    onInteracting: { interacting in
                        let phase: GuideScrollPhase = interacting ? .interacting : .idle
                        if phase != last {
                            let previous = last
                            last = phase
                            action(previous, phase)
                        }
                    }
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            )
        }
    }

    @available(iOS 18.0, *)
    private static func map(_ phase: ScrollPhase) -> GuideScrollPhase {
        phase == .interacting ? .interacting : .idle
    }
}

private struct GuideScrollPositionModifier: ViewModifier {
    @Binding var position: GuideScrollPosition

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            GuideNativeScrollPosition(position: $position, content: content)
        } else {
            content.background(
                GuideScrollProbe(position: $position)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            )
        }
    }
}

@available(iOS 18.0, *)
private struct GuideNativeScrollPosition<Content: View>: View {
    @Binding var position: GuideScrollPosition
    let content: Content
    @State private var native = ScrollPosition(edge: .top)

    var body: some View {
        content
            .scrollPosition($native)
            .onChange(of: position.generation) { _, _ in
                apply()
            }
            .onAppear { apply() }
    }

    private func apply() {
        switch position.target {
        case .top:
            native = ScrollPosition(edge: .top)
        case .bottom:
            native = ScrollPosition(edge: .bottom)
        case .y(let y):
            native.scrollTo(y: y)
        }
    }
}

// MARK: - iOS 17 UIScrollView probe

#if canImport(UIKit)
/// Finds the nearest `UIScrollView` and reports geometry, drag state, and
/// programmatic scroll requests. Hidden from VoiceOver (zero-size, not a
/// hit target) so it does not show up in the accessibility tree.
private struct GuideScrollProbe: UIViewRepresentable {
    var onGeometry: ((GuideScrollGeometry) -> Void)?
    var onInteracting: ((Bool) -> Void)?
    var position: Binding<GuideScrollPosition>?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onGeometry = onGeometry
        coordinator.onInteracting = onInteracting
        coordinator.position = position
        uiView.coordinator = coordinator
        coordinator.attach(from: uiView)
        coordinator.applyPositionIfNeeded()
    }

    final class ProbeView: UIView {
        var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(from: self)
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            coordinator?.attach(from: self)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            coordinator?.attach(from: self)
        }
    }

    final class Coordinator: NSObject {
        var onGeometry: ((GuideScrollGeometry) -> Void)?
        var onInteracting: ((Bool) -> Void)?
        var position: Binding<GuideScrollPosition>?
        weak var scrollView: UIScrollView?
        var observations: [NSKeyValueObservation] = []
        var lastAppliedGeneration: UInt?
        private var observingPan = false

        func attach(from view: UIView) {
            guard let scroll = Self.findScrollView(from: view) else { return }
            if scrollView === scroll { return }
            teardown()
            scrollView = scroll
            observations = [
                scroll.observe(\.contentOffset, options: [.initial, .new]) { [weak self] s, _ in
                    self?.emit(s)
                },
                scroll.observe(\.contentSize, options: [.new]) { [weak self] s, _ in
                    self?.emit(s)
                },
                scroll.observe(\.bounds, options: [.new]) { [weak self] s, _ in
                    self?.emit(s)
                },
                scroll.observe(\.contentInset, options: [.new]) { [weak self] s, _ in
                    self?.emit(s)
                }
            ]
            if !observingPan {
                scroll.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
                observingPan = true
            }
            emit(scroll)
            applyPositionIfNeeded()
        }

        private func teardown() {
            observations = []
            if let scroll = scrollView, observingPan {
                scroll.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
                observingPan = false
            }
        }

        func emit(_ scroll: UIScrollView) {
            let inset = scroll.adjustedContentInset
            let geometry = GuideScrollGeometry(
                contentOffset: scroll.contentOffset,
                contentSize: scroll.contentSize,
                containerSize: scroll.bounds.size,
                contentInsets: EdgeInsets(
                    top: inset.top,
                    leading: inset.left,
                    bottom: inset.bottom,
                    trailing: inset.right
                )
            )
            DispatchQueue.main.async { [weak self] in
                self?.onGeometry?(geometry)
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let interacting: Bool
            switch gesture.state {
            case .began, .changed:
                interacting = true
            default:
                interacting = false
            }
            onInteracting?(interacting)
        }

        func applyPositionIfNeeded() {
            guard let position, let scroll = scrollView else { return }
            let request = position.wrappedValue
            if lastAppliedGeneration == request.generation { return }
            lastAppliedGeneration = request.generation
            // generation 0 is the initial `.top` and the scroll view already
            // starts at the top — skip so we don't fight first layout.
            if request.generation == 0 { return }
            apply(request, to: scroll)
        }

        private func apply(_ request: GuideScrollPosition, to scroll: UIScrollView) {
            let inset = scroll.adjustedContentInset
            let offset: CGPoint
            switch request.target {
            case .top:
                offset = CGPoint(x: -inset.left, y: -inset.top)
            case .bottom:
                let y = max(
                    -inset.top,
                    scroll.contentSize.height - scroll.bounds.height + inset.bottom
                )
                offset = CGPoint(x: -inset.left, y: y)
            case .y(let y):
                // Call sites pass the "from rest" y that ScrollMorph uses
                // (`content - container` at the bottom). Rest is -inset.top.
                offset = CGPoint(x: -inset.left, y: y - inset.top)
            }
            scroll.setContentOffset(offset, animated: request.animated)
        }

        static func findScrollView(from view: UIView) -> UIScrollView? {
            var current: UIView? = view
            while let node = current {
                if let scroll = node as? UIScrollView { return scroll }
                if let parent = node.superview {
                    if let scroll = parent as? UIScrollView { return scroll }
                    for sibling in parent.subviews where sibling !== node {
                        if let scroll = sibling as? UIScrollView { return scroll }
                        if let scroll = descendantScrollView(in: sibling) { return scroll }
                    }
                }
                current = node.superview
            }
            return nil
        }

        private static func descendantScrollView(in view: UIView) -> UIScrollView? {
            for child in view.subviews {
                if let scroll = child as? UIScrollView { return scroll }
                if let scroll = descendantScrollView(in: child) { return scroll }
            }
            return nil
        }
    }
}
#else
private struct GuideScrollProbe: View {
    var onGeometry: ((GuideScrollGeometry) -> Void)?
    var onInteracting: ((Bool) -> Void)?
    var position: Binding<GuideScrollPosition>?
    var body: some View { Color.clear }
}
#endif
