import SwiftUI

struct CompletionView: View {
    var set: MysterySetKind
    var quote: String
    var language: PrayerLanguage
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            MysteryArtworkView(set: set, mysteryNumber: 5)
                .padding(.horizontal, 24)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.gold)
            Text(language == .latin ? "Rosárium complétum" : "Rosary complete")
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(quote)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Spacer()
            Button(action: onDone) {
                Text("Amen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.marianBlue)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
