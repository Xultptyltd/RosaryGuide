import SwiftUI

struct CompletionView: View {
    var set: MysterySetKind
    var quote: String
    var attribution: String
    var language: PrayerLanguage
    var onAmen: () -> Void
    var onMichael: (() -> Void)?

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("Finis")
                .font(AppTheme.sans(16, weight: .medium))
                .foregroundStyle(palette.dim)
            Text(quote)
                .font(AppTheme.sans(22))
                .lineSpacing(8)
                .multilineTextAlignment(.center)
            Text(attribution)
                .font(AppTheme.sans(13, weight: .medium))
                .foregroundStyle(palette.dim)
            Spacer()
            PillButton(title: "Amen", action: onAmen)
            if let onMichael {
                Button("Saint Michael the Archangel", action: onMichael)
                    .font(AppTheme.sans(16, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.card, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(palette.hair, lineWidth: 1)
                    }
                    .buttonStyle(.plain)
                    .guidePressable()
            }
        }
        .padding(24)
    }
}
