import SwiftUI
import UIKit

/// A short, illustrated introduction before the detailed reference guide.
struct RosaryWalkthroughView: View {
    var onClose: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0
    @State private var contentHeights: [Int: CGFloat] = [:]
    @State private var mysteryImageHeight: CGFloat = 180

    private let pageCount = 5

    var body: some View {
        GeometryReader { geometry in
            let viewportHeight = geometry.size.height + geometry.safeAreaInsets.bottom
            let activeHeroHeight = heroHeight(for: page, viewportHeight: viewportHeight)
            ZStack(alignment: .top) {
                if page != 3 {
                    Group {
                        if page == 0 {
                            introArtwork(height: activeHeroHeight + geometry.safeAreaInsets.top)
                        } else if page == 1 {
                            structureArtwork(height: activeHeroHeight + geometry.safeAreaInsets.top)
                        } else if page == 2 {
                            structureArtwork(height: activeHeroHeight + geometry.safeAreaInsets.top, imageName: "WalkthroughRosaryDecade")
                        } else {
                            imagePlaceholder(height: activeHeroHeight + geometry.safeAreaInsets.top)
                        }
                    }
                    .offset(y: -geometry.safeAreaInsets.top)
                    .allowsHitTesting(false)
                }
                ZStack {
                    ForEach(0..<pageCount, id: \.self) { index in
                        GuideWalkthroughPage(
                            index: index,
                            isActive: page == index,
                            isLast: index == pageCount - 1,
                            heroHeight: heroHeight(for: index, viewportHeight: viewportHeight),
                            width: geometry.size.width,
                            viewportHeight: viewportHeight,
                            allowsScrolling: (contentHeights[index] ?? estimatedContentHeight(for: index)) + GuideWalkthroughLayout.actionClearance > viewportHeight,
                            onNext: advance,
                            onPrevious: retreat,
                            onContentHeight: { height in
                                if abs(height - (contentHeights[index] ?? 0)) > 0.5 {
                                    contentHeights[index] = height
                                }
                                if index == 3 {
                                    // Let the grid extend behind the floating close control;
                                    // reserve only the shared copy and footer space.
                                    let available = viewportHeight - GuideWalkthroughLayout.actionClearance - AppTheme.Space.xs
                                    let nextHeight = max(0, mysteryImageHeight + (available - height) / 2)
                                    if abs(nextHeight - mysteryImageHeight) > 0.5 {
                                        mysteryImageHeight = nextHeight
                                    }
                                }
                            }
                        ) { pageContent(index, topInset: geometry.safeAreaInsets.top) }
                        .opacity(page == index ? 1 : 0)
                        .allowsHitTesting(page == index)
                        .accessibilityHidden(page != index)
                        .accessibilityIdentifier("rosary-walkthrough-page-\(index + 1)")
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .guideSymbol(size: 13, weight: .semibold)
                            .foregroundStyle(palette.ink)
                            .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                            .guideFloatingGlass(in: Circle(), palette: palette)
                            .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close guide")
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.xs)
                .zIndex(10)
            }
        }

        .background(palette.prayBg)
        .guidePageChrome()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func estimatedContentHeight(for index: Int) -> CGFloat {
        index == 3 ? 650 : 200
    }

    private func heroHeight(for index: Int, viewportHeight: CGFloat) -> CGFloat {
        guard index != 3 else { return 0 }
        let textHeight = contentHeights[index] ?? estimatedContentHeight(for: index)
        return max(0, viewportHeight - textHeight - GuideWalkthroughLayout.actionClearance - AppTheme.Space.xs)
    }

    private func advance() {
        if page == pageCount - 1 { onClose() }
        else { withAnimation(reduceMotion ? nil : MotionTokens.soft) { page += 1 } }
    }

    private func retreat() {
        if page == 0 { onClose() }
        else { withAnimation(reduceMotion ? nil : MotionTokens.soft) { page -= 1 } }
    }

    private func introArtwork(height: CGFloat) -> some View {
        GeometryReader { geometry in
            Image("WalkthroughRosaryIntro")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, palette.prayBg], startPoint: .top, endPoint: .bottom)
                        .frame(height: min(GuideWalkthroughLayout.fadeHeight, height))
                }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func structureArtwork(height: CGFloat, imageName: String = "WalkthroughRosaryStructure") -> some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, palette.prayBg], startPoint: .top, endPoint: .bottom)
                        .frame(height: min(GuideWalkthroughLayout.fadeHeight, height))
                }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func imagePlaceholder(height: CGFloat, fadeHeight: CGFloat = GuideWalkthroughLayout.fadeHeight) -> some View {
        Rectangle()
            .fill(palette.accent)
            .overlay {
                Image(systemName: "photo")
                    .guideSymbol(size: 32, weight: .regular)
                    .foregroundStyle(palette.primaryButtonText)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, palette.prayBg], startPoint: .top, endPoint: .bottom)
                    .frame(height: min(fadeHeight, height))
            }
            .frame(height: height)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pageContent(_ index: Int, topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            if index == 3 {
                mysteryPlaceholderGrid
                    .padding(.top, 72 - topInset - AppTheme.Space.xs)
                    .padding(.bottom, AppTheme.Space.lg)
            }
            Text(title(for: index))
                .font(AppTheme.TypeRole.modalTitle)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            switch index {
            case 0:
                paragraph("The Rosary is a prayer that helps you reflect on the life of Jesus with Mary. The beads help you keep your place as you pray.")
            case 1:
                paragraph("Begin with the opening prayers, then pray five decades. Finish with the closing prayers.")
            case 2:
                paragraph("Each decade includes one Our Father, ten Hail Marys and one Glory Be, followed by the Fatima prayer. Reflect on one mystery as you pray.")
            case 3:
                paragraph("The mysteries are different moments from the Gospel to reflect on. A different set is prayed each day.")
            default:
                paragraph("Rosary Guide will show you each prayer, bead and mystery. Take your time and follow along.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mysteryPlaceholderGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AppTheme.Space.md), GridItem(.flexible(), spacing: AppTheme.Space.md)],
            alignment: .leading,
            spacing: AppTheme.Space.md
        ) {
            ForEach(MysterySetKind.displayOrder, id: \.self) { set in
                mysteryTile(set)
            }
        }
    }

    /// Full-bleed statue tile with the set name and summary over a soft scrim.
    private func mysteryTile(_ set: MysterySetKind) -> some View {
        let isDark = colorScheme == .dark
        return Image(mysteryImageName(set))
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: mysteryImageHeight + AppTheme.Space.xxl + AppTheme.Space.lg)
            .clipped()
            .overlay(alignment: .bottom) {
                // Same artwork-to-page fade as the hero art on the other walkthrough screens.
                LinearGradient(colors: [.clear, palette.prayBg], startPoint: .top, endPoint: .bottom)
                    .frame(height: min(GuideWalkthroughLayout.fadeHeight, mysteryImageHeight + AppTheme.Space.xxl + AppTheme.Space.lg))
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("\(set.shortName) Mysteries")
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                        .foregroundStyle(isDark ? Color.white : palette.textPrimary)
                    Text(mysterySummary(set))
                        .font(AppTheme.TypeRole.caption)
                        .foregroundStyle(isDark ? Color.white.opacity(0.7) : palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppTheme.Space.md)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private func mysteryImageName(_ set: MysterySetKind) -> String {
        switch set {
        case .joyful: "MysteryJoyful"
        case .luminous: "MysteryLuminous"
        case .sorrowful: "MysterySorrowful"
        case .glorious: "MysteryGlorious"
        }
    }

    private func paragraph(_ text: String) -> some View {
        let size = AppTheme.TypeRole.prayerLineHeightReference(scale: settings.textSize.scale)
        let lineFont = FontRegistrar.sansUI(size)
        let lineExtra = max(0, size * 1.65 - lineFont.lineHeight)
        return GuideWalkthroughText(
            text: text,
            font: AppTheme.TypeRole.prayerTextUIFont(scale: settings.textSize.scale),
            color: palette.ink,
            lineSpacing: lineExtra
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func title(for index: Int) -> String {
        switch index {
        case 0: "What is the Rosary?"
        case 1: "A simple rhythm of prayer"
        case 2: "One mystery. Ten Hail Marys."
        case 3: "The story you pray with"
        default: "You’re ready."
        }
    }

    private func mysterySummary(_ set: MysterySetKind) -> String {
        switch set {
        case .joyful: "The birth and early life of Jesus"
        case .luminous: "The public ministry of Jesus"
        case .sorrowful: "The Passion and death of Jesus"
        case .glorious: "The Resurrection and the glory that follows"
        }
    }
}

/// Fill each line before wrapping; short teaching paragraphs should not
/// redistribute words just to balance the last two lines.
private struct GuideWalkthroughText: UIViewRepresentable {
    var text: String
    var font: UIFont
    var color: Color
    var lineSpacing: CGFloat = 0
    var numberOfLines: Int = 0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.lineBreakStrategy = []
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.numberOfLines = numberOfLines
        label.lineBreakMode = numberOfLines == 1 ? .byTruncatingTail : .byWordWrapping
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = label.lineBreakMode
        paragraph.lineBreakStrategy = []
        paragraph.lineSpacing = lineSpacing
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor(color),
            .paragraphStyle: paragraph
        ])
        label.accessibilityLabel = text
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        uiView.preferredMaxLayoutWidth = width
        let measured = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(measured.height))
    }
}

/// One template for artwork, copy and navigation across all five teaching pages.
private enum GuideWalkthroughLayout {
    static let textToButtonGap: CGFloat = 76
    static let dotHeight: CGFloat = 6
    static let fadeHeight: CGFloat = 160
    static var bottomPadding: CGFloat { AppTheme.Space.lg + 16 }
    static var actionClearance: CGFloat {
        AppTheme.Component.pillHeight + bottomPadding + textToButtonGap
    }
}

/// Each page owns its scroll state so offscreen pages cannot change the current action.
private struct GuideWalkthroughPage<Content: View>: View {
    var index: Int
    var isActive: Bool
    var isLast: Bool
    var heroHeight: CGFloat
    var width: CGFloat
    var viewportHeight: CGFloat
    var allowsScrolling: Bool
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onContentHeight: (CGFloat) -> Void
    @ViewBuilder var content: () -> Content
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsStore.self) private var settings
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var maxOffset: CGFloat = 0
    @State private var scrollY: CGFloat = 0
    @State private var actionLocked = false
    @State private var arrowArmed = false
    @State private var lastDrag = Date.distantPast

    private var showScroll: Bool { maxOffset > ScrollMorph.minimumOffset && !actionLocked }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: heroHeight).accessibilityHidden(true)
                Spacer(minLength: 0)
                content()
                    .frame(width: max(0, width - AppTheme.gutter * 2), alignment: .leading)
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.size.height
                    } action: { height in
                        onContentHeight(height)
                    }
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, AppTheme.Space.xs)
                    .padding(.bottom, GuideWalkthroughLayout.actionClearance)
            }
            .frame(maxWidth: .infinity, minHeight: viewportHeight, alignment: .topLeading)
        }
        .scrollPosition($scrollPosition)
        .scrollDisabled(!allowsScrolling)
        .scrollClipDisabled(index == 3)
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: GuideReadingMetrics.self) { geometry in
            GuideReadingMetrics(
                y: max(0, geometry.contentOffset.y + geometry.contentInsets.top),
                maxOffset: max(0, geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height)
            )
        } action: { _, metrics in
            if abs(metrics.y - scrollY) > 0.5 { lastDrag = Date() }
            scrollY = metrics.y
            maxOffset = metrics.maxOffset
            let next = ScrollMorph.resolve(locked: actionLocked, armed: arrowArmed, y: scrollY, maxOffset: maxOffset)
            actionLocked = next.locked
            arrowArmed = next.armed
        }
        .onScrollPhaseChange { _, phase in
            if phase == .interacting { arrowArmed = false; lastDrag = Date() }
        }
        // Explicit hit regions match the rosary flow and remain tappable over
        // both the clear hero spacer and the reading content in the pager.
        .overlay {
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: width * 0.15)
                    .contentShape(Rectangle())
                    .onTapGesture { if isActive { onPrevious() } }
                    .accessibilityLabel("Previous guide screen")
                    .accessibilityAddTraits(.isButton)
                Spacer(minLength: 0)
                Color.clear
                    .frame(width: width * 0.15)
                    .contentShape(Rectangle())
                    .onTapGesture { if isActive { onNext() } }
                    .accessibilityLabel("Next guide screen")
                    .accessibilityAddTraits(.isButton)
            }
            .padding(.bottom, AppTheme.Component.pillHeight + AppTheme.Space.lg * 2)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: GuideWalkthroughLayout.textToButtonGap / 2 - GuideWalkthroughLayout.dotHeight / 2) {
                GuidePageDots(current: index, count: 5, alignment: .leading)
                GuideScrollActionButton(
                    showScroll: allowsScrolling && showScroll,
                    title: isLast ? "Done" : "Next",
                    scrollLabel: "Scroll to read the guide",
                    primary: isLast,
                    onScroll: scrollToBottom,
                    onAdvance: {
                        HapticService.play(.light, enabled: settings.hapticsEnabled)
                        onNext()
                    }
                )
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.lg)
            .padding(.bottom, GuideWalkthroughLayout.bottomPadding)
        }
        .onChange(of: isActive) { _, active in
            guard active else { return }
            arrowArmed = false
            actionLocked = false
            scrollPosition.scrollTo(edge: .top)
        }
    }

    private func scrollToBottom() {
        guard Date().timeIntervalSince(lastDrag) > 0.25 else { return }
        HapticService.play(.light, enabled: settings.hapticsEnabled)
        arrowArmed = maxOffset - scrollY > ScrollMorph.minimumOffset
        withAnimation(reduceMotion ? nil : MotionTokens.reveal, completionCriteria: .logicallyComplete) {
            actionLocked = true
            scrollPosition.scrollTo(edge: .bottom)
        } completion: {
            arrowArmed = false
        }
    }
}

private struct GuideReadingMetrics: Equatable {
    var y: CGFloat
    var maxOffset: CGFloat
}

/// The prayer flow's slim segmented track, adapted to a variable page count.
struct GuideFlowProgressTrack: View {
    var current: Int
    var count: Int
    var onSelect: (Int) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: AppTheme.Space.xs) {
            ForEach(0..<count, id: \.self) { index in
                Button { onSelect(index) } label: {
                    Capsule()
                        .fill(index == current ? palette.ink : palette.ink.opacity(index < current ? 0.20 : 0.08))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                        .padding(.bottom, AppTheme.Space.sm)
                        .frame(minHeight: AppTheme.Accessibility.minHitTarget, alignment: .top)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Guide screen \(index + 1) of \(count)")
                .accessibilityAddTraits(index == current ? .isSelected : [])
            }
        }
        .padding(.bottom, 14)
    }
}

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
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Guide", prominence: .strong)
            Text(HowToPrayContent.introduction.primary(for: settings.language))
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.dim)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .guideReveal()
    }

    private var pathCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "The path", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
            VStack(spacing: 0) {
                ForEach(Array(pathOverview.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        Text(item.0)
                            .font(AppTheme.TypeRole.serifBody)
                            .foregroundStyle(palette.ink)
                        Text(item.1)
                            .font(AppTheme.TypeRole.themeSummary)
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
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
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
            GuideSectionLabel(text: "Step by step", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
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
            .padding(.vertical, AppTheme.Space.xs)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
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
                openStep = isOpen ? nil : step.id
            } label: {
                HStack(alignment: .top, spacing: AppTheme.Space.lg) {
                    Text("\(step.id)")
                        .font(AppTheme.TypeRole.label(weight: .medium))
                        .foregroundStyle(palette.faint)
                        .monospacedDigit()
                        .frame(width: 24, alignment: .leading)
                        .padding(.top, 3)

                    Text(step.title.primary(for: settings.language))
                        .font(AppTheme.TypeRole.serifBody)
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
                    .font(AppTheme.TypeRole.serifBody)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 36)
                    .padding(.trailing, AppTheme.Space.sm)
                    .padding(.bottom, AppTheme.Space.lg)
                    .transition(MotionTokens.accordionTransition)
            }
        }
        .guideAccordion(isExpanded: isOpen)
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: "When to pray which mysteries", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
            VStack(spacing: 0) {
                ForEach(Array(HowToPrayContent.weekdayGuide.enumerated()), id: \.element.0) { index, pair in
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                        Text(pair.0)
                            .font(AppTheme.TypeRole.serifBody)
                            .foregroundStyle(palette.ink)
                            .frame(width: 96, alignment: .leading)
                        Text(pair.1)
                            .font(AppTheme.TypeRole.label)
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
            .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
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
            GuideSectionLabel(text: "The beads", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap)
            Text(HowToPrayContent.beadsNote)
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.dim)
                .lineSpacing(5)
                .padding(.bottom, AppTheme.Space.lg)

            RosaryBeadMapView(locus: .decadeHail(1, 1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Space.md)
                .padding(.horizontal, AppTheme.Space.sm)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                        .strokeBorder(panelStroke, lineWidth: 1)
                }
                .guideSoftShadow(elevated: colorScheme == .light)
        }
        .guideReveal(delay: 0.18)
    }

    private var panelStroke: Color {
        colorScheme == .light ? palette.cardStroke : .clear
    }
}
