import SwiftUI
import UIKit

/// A short, illustrated introduction before the detailed reference guide,
/// built from the onboarding template (panel art, centred copy, dots, pill button).
struct RosaryWalkthroughView: View {
    var onClose: () -> Void
    /// "Begin my first Rosary": closes the walkthrough and starts today's mysteries.
    var onBegin: () -> Void = {}
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(SettingsStore.self) private var settings
    @State private var page = 0

    init(onClose: @escaping () -> Void, onBegin: @escaping () -> Void = {}) {
        self.onClose = onClose
        self.onBegin = onBegin
        #if DEBUG
        // Screenshot hook: -RGDebugIntroPage <n> opens introduction page n (0-based).
        if let n = Int(UserDefaults.standard.string(forKey: "RGDebugIntroPage") ?? ""), Self.pages.indices.contains(n) {
            _page = State(initialValue: n)
        }
        #endif
    }

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "What is the Rosary?",
            body: "The Rosary is a way to draw closer to God through prayer and reflection on the life of Jesus, with Mary. You don’t need to know the prayers—we’ll guide you.",
            imageName: "WalkthroughRosaryIntro",
            imageAlignment: .center
        ),
        OnboardingPage(
            title: "A moment to reflect",
            body: "Each “mystery” is a moment in the lives of Jesus and Mary. For example, imagine Mary hearing that she will become Jesus’ mother. As you pray, think about trusting God when life feels uncertain.",
            imageName: "MysteryJoyful"
        ),
        OnboardingPage(
            title: "One decade at a time",
            body: "A decade is a group of ten Hail Marys, beginning with an Our Father and ending with a Glory Be. While you say these prayers, reflect on one mystery.",
            imageName: "WalkthroughRosaryDecade",
            imageAlignment: .center
        ),
        OnboardingPage(
            title: "Start with a little time",
            body: "You can begin with just one decade. Take your time, and if your mind wanders, gently return to prayer. You don’t need to do it perfectly.",
            imageName: "WalkthroughRosaryStructure",
            imageAlignment: .center
        ),
        OnboardingPage(
            title: "We’ll guide you",
            body: "No rosary beads or memorised prayers needed. We’ll show you every prayer and mystery, one step at a time. Begin with the opening prayers, then follow along at your own pace.",
            imageName: "WalkthroughMary"
        )
    ]

    private var pages: [OnboardingPage] { Self.pages }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item, index: index, pageCount: pages.count, scrollsText: true)
                        .tag(index)
                        .accessibilityIdentifier("rosary-walkthrough-page-\(index + 1)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                Spacer()
                VStack(spacing: AppTheme.Space.lg) {
                    OnboardingDots(current: page, count: pages.count, label: "Introduction page")
                    PillButton(title: page == pages.count - 1 ? "Begin my first Rosary" : "Continue") {
                        HapticService.play(.light, enabled: settings.hapticsEnabled)
                        if page == pages.count - 1 {
                            onBegin()
                        } else {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) { page += 1 }
                        }
                    }
                    .environment(\.palette, palette)
                    .accessibilityLabel(page == pages.count - 1 ? "Begin my first Rosary, page \(page + 1) of \(pages.count)" : "Continue, page \(page + 1) of \(pages.count)")
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.bottom, AppTheme.Space.xl)
                .safeAreaPadding(.bottom)
            }

            VStack {
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
                .padding(.horizontal, AppTheme.gutter + AppTheme.Space.sm)
                .padding(.top, AppTheme.Space.xs)
                Spacer()
            }
        }
        // Same as onboarding: the template is designed on black in both appearances.
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: page)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
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
    static let textToButtonGap = AppTheme.Component.readingContentToActionGap
    static let dotHeight: CGFloat = 6
    static let fadeHeight: CGFloat = 160
    static let mysteryLabelScrimOpacity: Double = 0.70
    static let mysteryLabelScrimPosition: CGFloat = 0.55
    static var bottomPadding: CGFloat { AppTheme.Space.lg + 16 }
    static var actionClearance: CGFloat {
        AppTheme.Component.pillHeight + bottomPadding + textToButtonGap
    }
}

/// Each page owns its scroll state so offscreen pages cannot change the current action.
private struct GuideWalkthroughPage<Content: View>: View {
    var index: Int
    var isActive: Bool
    var contentOpacity: Double
    var isLast: Bool
    var isMysteryGrid: Bool
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
        .scrollClipDisabled(isMysteryGrid)
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: GuideReadingMetrics.self) { geometry in
            let position = ScrollMorph.position(geometry)
            return GuideReadingMetrics(y: position.y, maxOffset: position.maxOffset)
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
        // Only reading content fades; footer controls stay fully visible.
        .opacity(contentOpacity)
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
            .guideFooterBackdrop(prayerBackground: true)
        }
        .onChange(of: isActive) { _, active in
            guard active else { return }
            arrowArmed = false
            actionLocked = false
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { scrollPosition.scrollTo(edge: .top) }
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
