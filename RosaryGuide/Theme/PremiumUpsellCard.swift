import SwiftUI

/// "Rosary Guide+" upsell row: gold crown, gold serif title, short pitch and a chevron
/// on a dark card with a warm gold hairline. Always uses the dark premium treatment,
/// in light mode too, so it reads as the same premium surface everywhere.
struct PremiumUpsellCard: View {
    var title = "Rosary Guide+"
    var subtitle = "Guided novenas, prayer tracking, full history and more."
    var action: () -> Void

    private enum Gold {
        static let light = Color(hex: 0xF3DDA6)
        static let mid = Color(hex: 0xD9B56E)
        static let deep = Color(hex: 0xA77F3E)
        static let title = Color(hex: 0xE9CF95)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Space.lg) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(LinearGradient(
                        colors: [Gold.light, Gold.mid, Gold.deep],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 48)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text(title)
                        .font(AppTheme.serif(22, opticalSize: 24, relativeTo: .title3))
                        .foregroundStyle(Gold.title)
                    Text(subtitle)
                        .font(AppTheme.sans(15, relativeTo: .subheadline))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
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
            .fill(LinearGradient(
                colors: [Color(hex: 0x1F1E1C), Color(hex: 0x111113)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay {
                // Faint diagonal sheen.
                shape.fill(LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.0), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Gold.light.opacity(0.9), Gold.deep.opacity(0.7), Gold.mid.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
    }
}
