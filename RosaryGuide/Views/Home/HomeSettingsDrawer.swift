import SwiftUI

/// Full-screen Settings panel that slides in from the leading edge.
struct HomeSettingsDrawer: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool

    @State private var revealed = false
    @State private var dragOffset: CGFloat = 0
    @State private var panelWidth: CGFloat = 390

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                palette.scrim
                    .opacity(scrimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .accessibilityLabel("Dismiss settings")
                    .accessibilityAddTraits(.isButton)

                NavigationStack {
                    SettingsView(onClose: dismiss)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.bg)
                .offset(x: panelOffset(width: width))
                .gesture(dismissDrag(width: width))
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
        let progress = max(0, min(1, 1 + dragOffset / max(panelWidth, 1)))
        return 0.32 * progress
    }

    private func panelOffset(width: CGFloat) -> CGFloat {
        if !revealed { return -width }
        return min(0, dragOffset)
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
                // Leading-edge drawer dismisses by dragging toward the leading edge (negative X).
                if value.translation.width < 0 {
                    dragOffset = value.translation.width
                } else {
                    dragOffset = 0
                }
            }
            .onEnded { value in
                let threshold = -width * 0.22
                let predicted = value.predictedEndTranslation.width
                if value.translation.width < threshold || predicted < -width * 0.4 {
                    dismiss()
                } else {
                    withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                        dragOffset = 0
                    }
                }
            }
    }
}
