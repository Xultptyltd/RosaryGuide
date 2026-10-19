import SwiftUI

/// Full-screen Settings panel that slides in from the trailing edge, like a navigation push,
/// and slides back out to the trailing edge (back chevron, scrim tap or leading-edge swipe).
struct HomeSettingsDrawer: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool

    @State private var revealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var panelWidth: CGFloat = 390
    /// Settings' own stack. The edge swipe only closes the panel at the Settings root;
    /// on pushed pages the system back swipe pops instead.
    @State private var path = NavigationPath()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .trailing) {
                palette.scrim
                    .opacity(scrimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .accessibilityLabel("Dismiss settings")
                    .accessibilityAddTraits(.isButton)

                NavigationStack(path: $path) {
                    SettingsView(onClose: dismiss)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.bg)
                .offset(x: panelOffset(width: width))
                .gesture(dismissDrag(width: width), including: path.isEmpty ? .all : .subviews)
                .accessibilityAddTraits(.isModal)
            }
            .onAppear { panelWidth = width }
            .onChange(of: geo.size.width) { _, newWidth in
                panelWidth = newWidth
            }
        }
        .presentationBackground(.clear)
        .onAppear {
            withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                revealed = true
            }
        }
    }

    private var scrimOpacity: Double {
        guard revealed else { return 0 }
        let progress = max(0, min(1, 1 - dragOffset / max(panelWidth, 1)))
        return 0.32 * progress
    }

    private func panelOffset(width: CGFloat) -> CGFloat {
        if !revealed { return width }
        return max(0, dragOffset)
    }

    private func dismiss() {
        withAnimation(reduceMotion ? nil : MotionTokens.selection) {
            revealed = false
            dragOffset = 0
        }
        let delay = reduceMotion ? 0.0 : 0.38
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isPresented = false
            }
        }
    }

    private func dismissDrag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onChanged { value in
                // Like the system back swipe: start at the leading edge, drag toward the trailing edge.
                guard value.startLocation.x <= AppTheme.Accessibility.minHitTarget else { return }
                if value.translation.width > 0 {
                    dragOffset = value.translation.width
                } else {
                    dragOffset = 0
                }
            }
            .onEnded { value in
                guard value.startLocation.x <= AppTheme.Accessibility.minHitTarget else { return }
                let threshold = width * 0.22
                let predicted = value.predictedEndTranslation.width
                if value.translation.width > threshold || predicted > width * 0.4 {
                    dismiss()
                } else {
                    withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                        dragOffset = 0
                    }
                }
            }
    }
}
