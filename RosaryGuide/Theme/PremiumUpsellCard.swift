import SwiftUI

/// "Rosary Guide+" upsell: thin gold crown, gold title, pitch, and a secondary
/// "7-day free trial" pill (same style as "Offer my next Rosary"). No chevron.
/// Dark: dark surface with warm gold. Light: light surface with a deeper gold.
struct PremiumUpsellCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var title = "Rosary Guide+"
    var subtitle = "Guided novenas, prayer tracking, full history and more."
    var trialTitle = "7-day free trial"
    var action: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    private var gold: Color { isDark ? Color(hex: 0xE2C489) : Color(hex: 0x8A6322) }
    private var borderGold: Color { isDark ? Color(hex: 0xD9B56E) : Color(hex: 0xA97F35) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(alignment: .center, spacing: AppTheme.Space.lg) {
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
            }

            // Secondary pill — same token as "Offer my next Rosary".
            PillButton(title: trialTitle, filled: false, action: action)
        }
        .padding(.horizontal, AppTheme.Space.xl)
        .padding(.vertical, AppTheme.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { surface }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(subtitle)")
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

/// Shows `PremiumUpsellCard` only on the free tier. Observes the Debug
/// Premium mode switch so it hides and shows live; Release always shows it
/// until StoreKit backs `PremiumStatus`.
struct PremiumUpsellIfNeeded: View {
    var title = "Rosary Guide+"
    var subtitle = "Guided novenas, prayer tracking, full history and more."
    var action: () -> Void

    #if DEBUG
    @Bindable private var premium = PremiumDebugOverride.shared
    private var isPremium: Bool { premium.isPremium }
    #else
    private var isPremium: Bool { false }
    #endif

    @ViewBuilder
    var body: some View {
        if !isPremium {
            PremiumUpsellCard(title: title, subtitle: subtitle, action: action)
        }
    }
}
