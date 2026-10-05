import SwiftUI

/// "Rosary Guide+" upsell row: thin gold crown, gold title in the app sans, short pitch
/// and a chevron on the standard surface with a faint gold hairline.
/// Dark: dark surface with warm gold. Light: light surface with a deeper, richer gold
/// so the title, crown and edge keep contrast.
struct PremiumUpsellCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var title = "Rosary Guide+"
    var subtitle = "Guided novenas, prayer tracking, full history and more."
    var action: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    /// Title and crown gold.
    private var gold: Color { isDark ? Color(hex: 0xE2C489) : Color(hex: 0x8A6322) }
    private var borderGold: Color { isDark ? Color(hex: 0xD9B56E) : Color(hex: 0xA97F35) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.lg) {
                Image(systemName: "crown")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(gold)
                    .frame(width: 36)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(title)
                        .font(AppTheme.TypeRole.body(weight: .medium))
                        .foregroundStyle(gold)
                    Text(subtitle)
                        .font(AppTheme.sans(15, relativeTo: .subheadline))
                        .foregroundStyle(palette.ink.opacity(isDark ? 0.86 : 0.78))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .guideSymbol(size: 15, weight: .semibold)
                    .foregroundStyle(palette.ink.opacity(isDark ? 0.8 : 0.55))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AppTheme.Space.xl)
            .padding(.vertical, AppTheme.Space.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { surface }
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
    }

    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
        return shape
            .fill(palette.surface)
            .overlay {
                shape.strokeBorder(borderGold.opacity(isDark ? 0.30 : 0.35), lineWidth: 1)
            }
    }
}
