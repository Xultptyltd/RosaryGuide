import SwiftUI

struct HowToPrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var openStep: Int? = 1


    private let pathOverview: [(String, String)] = [
        ("Opening", "The Sign of the Cross through the Glory Be, in order."),
        ("Each decade", "The mystery, a verse, its fruit, then the beads."),
        ("Closing", "The traditional closing prayers after the fifth decade.")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, AppTheme.Space.xxl)

                pathCard
                    .padding(.bottom, AppTheme.sectionGap)

                stepsCard
                    .padding(.bottom, AppTheme.sectionGap)

                weekdayCard
                    .padding(.bottom, AppTheme.sectionGap)

                beadsCard
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xxl)
            .padding(.bottom, AppTheme.Space.section)
            .frame(maxWidth: 576, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(palette.bg)
        .guideDetailChrome("How to pray")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            GuideSectionLabel(text: "Guide", color: palette.dim)
            Text(HowToPrayContent.introduction.primary(for: settings.language))
                .font(AppTheme.serif(18, opticalSize: 18))
                .foregroundStyle(palette.dim)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .guideReveal()
    }

    private var pathCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "The path", color: palette.dim)
                .padding(.bottom, AppTheme.Space.lg)
            VStack(spacing: 0) {
                ForEach(Array(pathOverview.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(AppTheme.serif(20, opticalSize: 28))
                            .foregroundStyle(palette.ink)
                        Text(item.1)
                            .font(AppTheme.sans(15))
                            .foregroundStyle(palette.dim)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Space.lg)
                    if index < pathOverview.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .background(palette.panel, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(panelStroke, lineWidth: 1)
            }
            .guideSoftShadow(elevated: colorScheme == .light)
        }
        .guideReveal(delay: 0.05)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "Step by step", color: palette.dim)
                .padding(.bottom, AppTheme.Space.lg)
            VStack(spacing: 0) {
                ForEach(Array(HowToPrayContent.steps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step)
                    if index < HowToPrayContent.steps.count - 1 {
                        Hairline()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.vertical, 4)
            .background(palette.panel, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(panelStroke, lineWidth: 1)
            }
            .guideSoftShadow(elevated: colorScheme == .light)
        }
        .guideReveal(delay: 0.1)
    }

    private func stepRow(_ step: HowToPrayStep) -> some View {
        let isOpen = openStep == step.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticService.play(.light, enabled: settings.hapticsEnabled)
                withAnimation(reduceMotion ? nil : MotionTokens.selection) {
                    openStep = isOpen ? nil : step.id
                }
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    Text("\(step.id)")
                        .font(AppTheme.sans(13, weight: .medium))
                        .foregroundStyle(palette.faint)
                        .monospacedDigit()
                        .frame(width: 22, alignment: .leading)
                        .padding(.top, 3)

                    Text(step.title.primary(for: settings.language))
                        .font(AppTheme.serif(19, opticalSize: 28))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 11, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .padding(.top, AppTheme.Space.sm)
                }
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.title.primary(for: settings.language))
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Collapses this step" : "Expands this step")

            if isOpen {
                Text(step.body)
                    .font(AppTheme.serif(16, opticalSize: 16))
                    .foregroundStyle(palette.dim)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 36)
                    .padding(.trailing, 8)
                    .padding(.bottom, AppTheme.Space.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "When to pray which mysteries", color: palette.dim)
                .padding(.bottom, AppTheme.Space.lg)
            VStack(spacing: 0) {
                ForEach(Array(HowToPrayContent.weekdayGuide.enumerated()), id: \.element.0) { index, pair in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(pair.0)
                            .font(AppTheme.serif(18, opticalSize: 28))
                            .foregroundStyle(palette.ink)
                            .frame(width: 96, alignment: .leading)
                        Text(pair.1)
                            .font(AppTheme.sans(14))
                            .foregroundStyle(palette.dim)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, AppTheme.Space.md)
                    if index < HowToPrayContent.weekdayGuide.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .background(palette.panel, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                    .strokeBorder(panelStroke, lineWidth: 1)
            }
            .guideSoftShadow(elevated: colorScheme == .light)
        }
        .guideReveal(delay: 0.14)
    }

    private var beadsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "The beads", color: palette.dim)
                .padding(.bottom, AppTheme.Space.md)
            Text(HowToPrayContent.beadsNote)
                .font(AppTheme.serif(16, opticalSize: 16))
                .foregroundStyle(palette.dim)
                .lineSpacing(5)
                .padding(.bottom, AppTheme.Space.lg)

            RosaryBeadMapView(locus: .decadeHail(1, 1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Space.md)
                .padding(.horizontal, 8)
                .background(palette.card, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                        .strokeBorder(panelStroke, lineWidth: 1)
                }
                .guideSoftShadow(elevated: colorScheme == .light)
        }
        .guideReveal(delay: 0.18)
    }

    private var panelStroke: Color {
        colorScheme == .light ? Color(hex: 0x171512).opacity(0.07) : Color.clear
    }
}
