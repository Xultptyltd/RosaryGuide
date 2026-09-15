import SwiftUI

struct BeadRailView: View {
    var filled: Int
    var total: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { bead in
                Circle()
                    .fill(bead <= filled ? tint : tint.opacity(0.18))
                    .frame(width: bead == filled ? 16 : 12, height: bead == filled ? 16 : 12)
                    .overlay {
                        Circle().strokeBorder(tint.opacity(bead <= filled ? 0.9 : 0.25), lineWidth: 1)
                    }
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Decade beads")
        .accessibilityValue("\(filled) of \(total)")
    }
}
