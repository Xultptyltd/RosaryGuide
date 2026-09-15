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
                .font(AppTheme.serif(26, italic: true))
                .multilineTextAlignment(.center)
            Text(attribution)
                .font(AppTheme.sans(13, weight: .medium))
                .foregroundStyle(palette.dim)
            Spacer()
            PillButton(title: "Amen", action: onAmen)
            if let onMichael {
                Button("Saint Michael the Archangel", action: onMichael)
                    .font(AppTheme.sans(16, weight: .medium))
                    .foregroundStyle(palette.dim)
            }
        }
        .padding(24)
    }
}
