import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private struct PrayChromeButton: View {
    @Environment(\.palette) private var palette

    var system: String? = nil
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
                .foregroundStyle(palette.ink)
                .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
        .background {
            Circle()
                .fill(.clear)
                .guideFloatingGlass(in: Circle(), palette: palette)
                .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
        }
        .guidePressable()
    }

    @ViewBuilder
    private var content: some View {
        if let system {
            Image(systemName: system)
                .guideSymbol(size: 13, weight: .semibold)
        } else if let label {
            Text(label)
                .font(AppTheme.TypeRole.label(weight: .medium))
        }
    }
}

struct PrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessionStore
    @Environment(OfferStore.self) private var offer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var launch: PrayLaunch

    @State private var steps: [RosaryStep] = []
    @State private var index: Int = 0
    @State private var confirmReplace = false
    @State private var didConfigure = false
    @State private var showingMichael = false
    @State private var michaelContentHeight: CGFloat = 0
    @State private var michaelViewportHeight: CGFloat = 0
    @State private var michaelActionLocked = false
    /// Tap has started the scroll. The circle stays put until the bottom arrives.
    @State private var michaelArrowArmed = false
    @State private var michaelScrollY: CGFloat = 0
    /// Offset target. A stable anchor id is ignored on the second tap.
    @State private var michaelScrollPosition = ScrollPosition(edge: .top)
    /// Last time the prayer actually moved. A scroll that ends on the circle is not a tap.
    @State private var michaelLastDrag = Date.distantPast
    /// Shared scroll-template state for long rosary prayers (not Saint Michael).
    @State private var prayerTextHeight: CGFloat = 0
    @State private var prayerViewportHeight: CGFloat = 0
    @State private var prayerContentHeight: CGFloat = 0
    /// Last measured in-flow footer height (Next + language chips).
    @State private var prayerFooterHeight: CGFloat = 128
    @State private var prayerUsesScrollTemplate = false
    @State private var prayerActionLocked = false
    @State private var prayerArrowArmed = false
    @State private var prayerScrollY: CGFloat = 0
    @State private var prayerScrollPosition = ScrollPosition(edge: .top)
    @State private var prayerLastDrag = Date.distantPast
    /// Two-button steps only (decade Hail Marys 1–9). Next shows as a pill.
    @State private var pairNextExpanded = false
    /// Complete decade is in its slot. Follows Next out, leaves before it.
    @State private var pairSecondShown = false
    /// Bumped on every change so a stale staggered step never lands.
    @State private var pairGeneration = 0
    @State private var showingCompletion = false
    @State private var freshSetPending: MysterySetKind?

    /// Mystery set for the Rosary in progress (may differ from the calendar day).
    private var intentionSheetMysterySet: MysterySetKind {
        if let pending = freshSetPending { return pending }
        if let session = sessionStore.session { return session.mysterySet }
        return launch.mysterySet
    }
    /// How far the mystery plate text has scrolled up over the art (points).
    @State private var plateScrollY: CGFloat = 0
    @State private var plateContentHeight: CGFloat = 0
    @State private var plateViewportHeight: CGFloat = 0
    @State private var plateHintDismissed = false
    @State private var plateNearBottom = false
    @State private var plateActionLockedToNext = false
    @State private var plateArrowArmed = false
    @State private var plateScrollPosition = ScrollPosition(edge: .top)
    @State private var plateLastDrag = Date.distantPast
    /// Measured header + progress track height (safe-area content, not status bar).
    @State private var plateChromeHeight: CGFloat = 96
    @State private var chosenIntentionId: UUID?
    @State private var chosenIntentionTitle: String = ""
    @State private var chosenIntentionNote: String = ""
    @AppStorage("offer.hideIntentionText") private var hideIntentionText = false
    @State private var showIntentionSheet = false
    @State private var didRecordCarry = false
    /// Locked when entering finis so Offered for survives session.complete() / store churn.
    @State private var completionIntentionTitle: String?
    /// Icon and papal flag locked with the title. Nil for a title with no stored intention.
    @State private var completionIntentionFace: CompletionIntentionFace?
    /// Chosen before the finis screen exists so its first update does not write UserDefaults.
    @State private var completionQuote: CompletionQuote?
    /// Stops the bead TimelineView before the finis screen is inserted.
    @State private var beadTimelinePaused = false
    /// Black veil over the closing prayer. Beads keep running underneath until this covers them.
    @State private var finishBlack: Double = 0

    private var language: PrayerLanguage { settings.language }
    private var current: RosaryStep? {
        steps.indices.contains(index) ? steps[index] : nil
    }

    var body: some View {
        ZStack {
            palette.prayBg.ignoresSafeArea()
            if showingCompletion {
                finisLayer
            } else if let current {
                if current.isFinis {
                    finisLayer
                } else {
                    prayLayer(current)
                }
            }
            // Kept above the finish screen so closing Saint Michael returns
            // to the same completion state instead of leaving for Home.
            if showingMichael {
                michaelLayer
            }
            if finishBlack > 0, !showingCompletion, !showingMichael {
                Color.black
                    .opacity(finishBlack)
                    .ignoresSafeArea()
                    .allowsHitTesting(finishBlack > 0.05)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(palette.ink)
        .onAppear {
            guard !didConfigure else { return }
            didConfigure = true
            if case .fresh(let set, _) = launch, sessionStore.resumableSession != nil {
                freshSetPending = set
                confirmReplace = true
            } else {
                configure()
            }
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .gesture(
            DragGesture(minimumDistance: 50).onEnded { value in
                if showingCompletion || showingMichael || current?.isFinis == true { return }
                if value.translation.width < -40 { advance() }
                if value.translation.width > 40 { retreat() }
            }
        )
        .alert("Start a new rosary?", isPresented: $confirmReplace) {
            Button("Replace saved place", role: .destructive) {
                configure()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You already have a rosary in progress today. Starting fresh will replace it once you move past the first step.")
        }
        .sheet(isPresented: $showIntentionSheet) {
            PrayIntentionSheet(
                chosenId: $chosenIntentionId,
                chosenTitle: $chosenIntentionTitle,
                chosenNote: $chosenIntentionNote,
                mysterySet: intentionSheetMysterySet
            )
            .environment(offer)
            .environment(\.palette, palette)
            .onDisappear {
                sessionStore.updateIntention(
                    id: chosenIntentionId,
                    title: chosenIntentionTitle.isEmpty ? nil : chosenIntentionTitle
                )
            }
        }
    }

    // MARK: - Main pray column

    private func prayLayer(_ step: RosaryStep) -> some View {
        GeometryReader { geo in
            let showBeads = shouldShowBeads(step)
            let artHeight = min(geo.size.width, geo.size.height * 0.48, 520)

            if step.isPlate, let mystery = step.mystery {
                plateLayer(step, mystery: mystery, artHeight: artHeight)
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        header(step)
                        SevenStageTrack(current: step.stage) { jump(to: $0) }
                    }

                    ZStack {
                        if step.kind == .signOfTheCross {
                            edgeTapZones
                        }

                        VStack(spacing: 0) {
                            standardPrayColumn(step, scrollHeight: geo.size.height)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if showBeads, let bead = step.bead {
                                RosaryBeadMapView(locus: bead, animationPaused: beadTimelinePaused)
                                    .padding(.horizontal, AppTheme.Space.md)
                                    .padding(.top, AppTheme.Space.xl)
                                    .padding(.bottom, AppTheme.Space.sm)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        if step.kind != .signOfTheCross {
                            edgeTapZones
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    footer(step)
                }
                .overlay(alignment: .bottom) {
                    if prayerUsesScrollTemplate {
                        // Bead shelf stays in flow. The circle floats on the prayer,
                        // just above that shelf, not on a black bar.
                        prayerScrollChrome(step)
                            .padding(.bottom, showBeads ? 142 : 0)
                    }
                }
            }
        }
        .onChange(of: index) { _, _ in
            plateScrollY = 0
            plateHintDismissed = false
            plateNearBottom = false
            resetPrayerScrollState()
            plateActionLockedToNext = false
            plateArrowArmed = false
            // Do not clear content/viewport heights here — zeroing races the next
            // geometry callback and can leave the scroll cue stuck hidden.
        }
    }

    /// Mystery plate: hero is a continuous canvas under floating top chrome (no opaque header slab).
    private func plateLayer(
        _ step: RosaryStep,
        mystery: Mystery,
        artHeight: CGFloat
    ) -> some View {
        let progress = plateScrollProgress
        let chromeH = max(plateChromeHeight, 88)
        let heroHeight = artHeight + chromeH
        // Spacer clears floating chrome + visible art band before Scripture.
        let heroSpacer = heroHeight + 8
        let readingBottomPad: CGFloat = 28

        return ZStack(alignment: .top) {
            // Continuous hero under status bar + Aa/title/close + progress track.
            plateHeroImage(
                mystery: mystery,
                artHeight: heroHeight,
                underlayHeight: chromeH,
                progress: progress
            )
            .frame(height: heroHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: heroSpacer)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 0) {
                            locus(step)
                            announceBody(step)
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        .padding(.top, 4)
                        .padding(.bottom, AppTheme.Space.lg + readingBottomPad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .contain)

                        // Room so the last lines can clear the floating action.
                        Color.clear
                            .frame(height: 108)
                            .accessibilityHidden(true)
                        Color.clear
                            .frame(height: 1)
                            .id(PlateScrollAnchor.bottom)
                            .accessibilityHidden(true)
                    }
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: PlateContentHeightKey.self, value: geo.size.height)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition($plateScrollPosition)
                .background {
                    GeometryReader { geo in
                        Color.clear.preference(key: PlateViewportHeightKey.self, value: geo.size.height)
                    }
                }
                .onPreferenceChange(PlateContentHeightKey.self) { height in
                    if height > 1 { plateContentHeight = height }
                }
                .onPreferenceChange(PlateViewportHeightKey.self) { height in
                    if height > 1 { plateViewportHeight = height }
                }
                .onScrollGeometryChange(for: PlateScrollMetrics.self) { geometry in
                    PlateScrollMetrics(
                        offsetY: geometry.contentOffset.y,
                        contentHeight: geometry.contentSize.height,
                        viewportHeight: geometry.containerSize.height
                    )
                } action: { _, newValue in
                    if newValue.contentHeight > 1 {
                        plateContentHeight = max(plateContentHeight, newValue.contentHeight)
                    }
                    if newValue.viewportHeight > 1 {
                        plateViewportHeight = newValue.viewportHeight
                    }
                    let y = max(0, newValue.offsetY)
                    if abs(y - plateScrollY) > 0.5 {
                        plateLastDrag = Date()
                    }
                    plateScrollY = y
                    let contentH = newValue.contentHeight > 1 ? newValue.contentHeight : plateContentHeight
                    let viewH = newValue.viewportHeight > 1 ? newValue.viewportHeight : plateViewportHeight
                    let maxOffset = max(0, contentH - viewH)
                    let next = ScrollMorph.resolve(
                        locked: plateActionLockedToNext,
                        armed: plateArrowArmed,
                        y: y,
                        maxOffset: maxOffset
                    )
                    if next.locked != plateActionLockedToNext { plateActionLockedToNext = next.locked }
                    if next.armed != plateArrowArmed { plateArrowArmed = next.armed }
                    plateNearBottom = maxOffset > 8 && y >= maxOffset - ScrollMorph.expandGap(maxOffset)
                }
                .onScrollPhaseChange { _, phase in
                    // A finger on the text takes over from any tap scroll.
                    if phase == .interacting {
                        plateArrowArmed = false
                        plateLastDrag = Date()
                    }
                }
                .task(id: mystery.id) {
                    plateScrollY = 0
                    plateHintDismissed = false
                    plateNearBottom = false
                    plateActionLockedToNext = false
                    plateArrowArmed = false
                    plateLastDrag = .distantPast
                    plateScrollPosition = ScrollPosition(edge: .top)
                }
                // Edge taps below chrome so Aa / close / track keep priority.
                .overlay {
                    edgeTapZones
                        .padding(.top, chromeH)
                }
                .overlay(alignment: .bottom) {
                    plateActionChrome(step) {
                        guard Date().timeIntervalSince(plateLastDrag) > 0.25 else { return }
                        HapticService.play(.light, enabled: settings.hapticsEnabled)
                        let contentH = plateContentHeight
                        let viewH = plateViewportHeight
                        let maxOffset = max(0, contentH - viewH)
                        let distanceFromBottom = maxOffset - plateScrollY
                        plateArrowArmed = distanceFromBottom > 8
                        withAnimation(reduceMotion ? nil : MotionTokens.reveal, completionCriteria: .logicallyComplete) {
                            plateActionLockedToNext = true
                            if distanceFromBottom > 8 {
                                plateScrollPosition.scrollTo(y: maxOffset)
                            }
                        } completion: {
                            plateArrowArmed = false
                        }
                        disarmLater { plateArrowArmed = false }
                    }
                }

            // Fixed floating chrome — last so it composites above the hero canvas.
            plateTopChrome(step)
        }
        .background(palette.prayBg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Clip to the screen canvas only — not at an internal header/progress boundary.
        .clipped()
        .id(mystery.id)
        .transition(
            reduceMotion
                ? .opacity
                : .asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 10)),
                    removal: .opacity.combined(with: .offset(y: -6))
                )
        )
    }

    /// Floating Aa / title / close + progress — translucent scrim, not an opaque slab.
    private func plateTopChrome(_ step: RosaryStep) -> some View {
        VStack(spacing: 0) {
            header(step)
            SevenStageTrack(current: step.stage) { jump(to: $0) }
        }
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: PlateChromeHeightKey.self, value: geo.size.height)
            }
        }
        .onPreferenceChange(PlateChromeHeightKey.self) { height in
            if height > 1 { plateChromeHeight = height }
        }
        .background(alignment: .top) {
            plateTopChromeScrim
                // Cover status bar + controls + track + a little below the segments.
                .frame(height: max(plateChromeHeight, 88) + 52)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }

    /// Soft wash from page colour into the hero — no hard horizontal edge.
    private var plateTopChromeScrim: some View {
        let page = palette.prayBg
        return LinearGradient(
            stops: [
                .init(color: page.opacity(colorScheme == .light ? 0.94 : 0.90), location: 0),
                .init(color: page.opacity(colorScheme == .light ? 0.70 : 0.64), location: 0.38),
                .init(color: page.opacity(colorScheme == .light ? 0.28 : 0.24), location: 0.68),
                .init(color: page.opacity(colorScheme == .light ? 0.06 : 0.05), location: 0.88),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var plateScrollProgress: CGFloat {
        min(1, max(0, plateScrollY / 180))
    }

    /// Overflow only — geometry-based, never character count. False until measured.
    private var plateShowsScrollHint: Bool {
        guard !plateHintDismissed else { return false }
        guard plateViewportHeight > 1, plateContentHeight > 1 else { return false }
        return plateContentHeight > plateViewportHeight + 6
    }

    private func plateHeroImage(
        mystery: Mystery,
        artHeight: CGFloat,
        underlayHeight: CGFloat,
        progress: CGFloat
    ) -> some View {
        let washOverlay = progress * 0.75
        let heroOpacity = 1.0 - progress * 0.50
        let blurRadius: CGFloat = reduceMotion ? 0 : progress * 2.5
        let scale: CGFloat = reduceMotion ? 1.0 : 1.0 + progress * 0.025
        let yShift: CGFloat = reduceMotion ? 0 : -progress * 24
        // Keep the bottom dissolve in the visible art band (below floating chrome).
        let underFrac = min(0.55, max(0, underlayHeight / max(artHeight, 1)))
        let visibleClear = max(0.08, 0.52 - progress * 0.42)
        let visibleMid = max(0.22, 0.70 - progress * 0.38)
        let clearEnd = underFrac + (1 - underFrac) * visibleClear
        let midFade = underFrac + (1 - underFrac) * visibleMid
        // Extra vertical overscan so parallax/scale never flash empty edges;
        // bias upward so motion can travel behind the top chrome.
        let topOverscan: CGFloat = 40
        let bottomOverscan: CGFloat = 24

        return ZStack {
            PlateArtView(mystery: mystery, wide: true)
                .scaleEffect(scale, anchor: .center)
                .blur(radius: blurRadius)
                .opacity(heroOpacity)
                .offset(y: yShift)
                .frame(maxWidth: .infinity)
                .frame(height: artHeight + topOverscan + bottomOverscan)
                .offset(y: -(topOverscan - bottomOverscan) * 0.5)
                .clipped()

            // Scrim under the bottom fade. Light washes to white; dark uses black.
            palette.selectedControlFill
                .opacity(washOverlay)
                .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: clearEnd),
                    .init(color: palette.prayBg.opacity(0.25 + progress * 0.35), location: midFade),
                    .init(color: palette.prayBg.opacity(0.88 + progress * 0.1), location: min(1, midFade + 0.18)),
                    .init(color: palette.prayBg, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .frame(height: artHeight)
        // Contain aspect-fill overscan to the hero canvas — not to the chrome boundary.
        .clipped()
    }

    private var plateCanScrollFurther: Bool {
        plateContentHeight > plateViewportHeight + 6 && !plateActionLockedToNext
    }

    private func plateActionChrome(_ step: RosaryStep, scrollToBottom: @escaping () -> Void) -> some View {
        let nextTitle = step.nextLabel == "Continue" ? "Next" : step.nextLabel
        return scrollActionChrome(
            showScroll: plateCanScrollFurther,
            expandedTitle: nextTitle,
            scrollLabel: "Scroll to read full scripture",
            onScroll: scrollToBottom,
            onAdvance: { advance() }
        )
        .padding(.horizontal, AppTheme.gutter)
        .padding(.top, 8)
        .padding(.bottom, AppTheme.Space.lg)
    }

        /// Non-plate pray column (unchanged mid-column / Creed pin behavior).
    private func standardPrayColumn(_ step: RosaryStep, scrollHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            GeometryReader { scrollGeo in
                let pinTop = step.kind == .creed
                ScrollView {
                    VStack(spacing: 0) {
                        if !pinTop { Spacer(minLength: 0) }
                        VStack(alignment: .leading, spacing: 0) {
                            locus(step)
                            if step.kind == .signOfTheCross {
                                signOfCrossIntentionBlock
                            }
                            BilingualStack(
                                text: step.body,
                                language: language,
                                font: AppTheme.TypeRole.prayerText(scale: settings.textSize.scale),
                                pointSize: 21 * settings.textSize.scale
                            )
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        // At least 48pt from the close button to this title.
                        // The in-flow stage track already covers most of that;
                        // this pad is the rest (and never less than the old 4pt).
                        .padding(.top, prayerTitleTopPadding)
                        .padding(.bottom, AppTheme.Space.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: PrayerTextHeightKey.self, value: geo.size.height)
                            }
                        }
                        if !pinTop { Spacer(minLength: 0) }
                        if prayerUsesScrollTemplate {
                            Color.clear.frame(height: 132)
                            Color.clear.frame(height: 1).id(PrayerScrollAnchor.bottom)
                        }
                    }
                    .frame(minHeight: pinTop ? nil : scrollGeo.size.height, alignment: .top)
                    .frame(maxWidth: .infinity)
                }
                .scrollPosition($prayerScrollPosition)
                .onScrollGeometryChange(for: PlateScrollMetrics.self) { geometry in
                    PlateScrollMetrics(
                        offsetY: geometry.contentOffset.y,
                        contentHeight: geometry.contentSize.height,
                        viewportHeight: geometry.containerSize.height
                    )
                } action: { _, newValue in
                    if newValue.contentHeight > 1 {
                        prayerContentHeight = newValue.contentHeight
                    }
                    if newValue.viewportHeight > 1 {
                        prayerViewportHeight = newValue.viewportHeight
                    }
                    let y = max(0, newValue.offsetY)
                    if abs(y - prayerScrollY) > 0.5 {
                        prayerLastDrag = Date()
                    }
                    prayerScrollY = y
                    let viewH = newValue.viewportHeight > 1 ? newValue.viewportHeight : prayerViewportHeight
                    updatePrayerScrollTemplate(viewport: viewH)
                    guard prayerUsesScrollTemplate else { return }
                    let maxOffset = max(0, newValue.contentHeight - viewH)
                    let next = ScrollMorph.resolve(
                        locked: prayerActionLocked,
                        armed: prayerArrowArmed,
                        y: y,
                        maxOffset: maxOffset
                    )
                    if next.locked != prayerActionLocked { prayerActionLocked = next.locked }
                    if next.armed != prayerArrowArmed { prayerArrowArmed = next.armed }
                }
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting {
                        prayerArrowArmed = false
                        prayerLastDrag = Date()
                    }
                }
                // Fresh scroll view per step: starts at the top, measures again.
                .id(step.id)
                .onChange(of: settings.language) { resetPrayerScrollState() }
                .onChange(of: settings.textSize) { resetPrayerScrollState() }
            }
            .onPreferenceChange(PrayerTextHeightKey.self) { height in
                if height > 1 {
                    prayerTextHeight = height
                    updatePrayerScrollTemplate(viewport: prayerViewportHeight)
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                // Column height changes when the footer hides or shows.
                if height > 1 {
                    prayerViewportHeight = height
                    updatePrayerScrollTemplate(viewport: height)
                }
            }
            // Rosary shelf lives in `prayLayer`, above the in-flow footer (web phone parity).
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Outer ~15% of the pray column steps back / forward (was 25%; narrowed so body stays tappable).
    private var edgeTapZones: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: geo.size.width * 0.15)
                    .onTapGesture { retreat() }
                    .accessibilityLabel("Previous prayer")
                    .accessibilityAddTraits(.isButton)

                Spacer(minLength: 0)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: geo.size.width * 0.15)
                    .onTapGesture { advance() }
                    .accessibilityLabel("Next prayer")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .allowsHitTesting(true)
    }


    /// Top inset for a prayer title in the shared column.
    /// Header bottom pad + stage track are already between the close button and the title.
    private var prayerTitleTopPadding: CGFloat {
        let locusTop: CGFloat = 2
        let shortfall = PrayerTitleChrome.belowClose - PrayerTitleChrome.belowCloseBeforeColumn - locusTop
        // Keep the previous 4pt when the track already clears 48.
        return max(4, shortfall)
    }

    private func header(_ step: RosaryStep) -> some View {
        ZStack {
            HStack {
                // Text size lives in Settings. Close stays trailing.
                Spacer()
                roundControl(system: "xmark") { dismiss() }
                    .accessibilityLabel("Close")
            }
            progressNowLabel(step)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 52)
                .accessibilityLabel(step.progressLabel)
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.xs)
        .padding(.bottom, AppTheme.Space.xs)
    }

    /// Web `#pnow`: roman + padded middot + mystery title (`.sep` is `padding: 0 .5em`).
    @ViewBuilder
    private func progressNowLabel(_ step: RosaryStep) -> some View {
        let font = AppTheme.TypeRole.label(weight: .medium)
        if let mystery = step.mystery,
           [.first, .second, .third, .fourth, .fifth].contains(step.stage) {
            HStack(spacing: 0) {
                Text(OrdinalWord.roman(mystery.number))
                    .font(font)
                Text("·")
                    .font(font)
                    .padding(.horizontal, 10) // web `.sep` ≈ 0.5em; a bit more so it reads on device
                Text(mystery.title.english)
                    .font(font)
            }
            .foregroundStyle(palette.ink)
        } else {
            Text(step.progressLabel)
                .font(font)
                .foregroundStyle(palette.ink)
        }
    }

    private func locus(_ step: RosaryStep) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            if step.isPlate, let mystery = step.mystery {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                    Text(OrdinalWord.roman(mystery.number))
                        .font(AppTheme.TypeRole.body(weight: .medium))
                        .foregroundStyle(palette.ink.opacity(0.72))
                    Text("\(OrdinalWord.english(mystery.number)) \(mystery.set.shortName)")
                        .font(AppTheme.TypeRole.caption(weight: .medium))
                        .tracking(2.0)
                        .textCase(.uppercase)
                        .foregroundStyle(palette.faint)
                }
                // Locus VStack spacing is 6; +4 → 10pt under the mystery eyebrow.
                .padding(.bottom, 4)
            }
            // Web `.locus .k`: "1 of 10" above Hail Mary on decade beads.
            if step.kind == .hailMary,
               step.decadeNumber != nil,
               let n = step.hailMaryNumber {
                Text("\(n) of 10")
                    .font(AppTheme.TypeRole.label(weight: .medium))
                    .foregroundStyle(palette.faint)
                    // VStack spacing is 6; +4 → 10pt under "1 of 10".
                    .padding(.bottom, 4)
            }
            Text(step.title.primary(for: language))
                .font(AppTheme.TypeRole.modalTitle)
                .foregroundStyle(palette.ink)
                .tracking(-0.2)
            if !step.isPlate, language == .bilingual {
                Text(step.title.latin)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
            }
            if let intention = step.intention, step.kind != .signOfTheCross {
                let line = leadLine(intention.primary(for: language), emphasizeSuffix: emphasizeLead(for: step))
                line
                    .padding(.top, 6)
                    .padding(.bottom, 14)
                    .overlay(alignment: .bottom) { Hairline() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Website `.locus h2 { margin-top: .45rem }` after track — track already has bottom pad.
        .padding(.top, 2)
        // Sign of the Cross: Space.lg before the quiet For: row; other steps keep web spacing.
        .padding(.bottom, step.kind == .signOfTheCross ? AppTheme.Space.lg : 22)
    }




    /// Quiet inline intention metadata under the Sign of the Cross title.
    /// Optional — never blocks Next. Tap opens the picker; × clears.
    private var chosenOfferIntention: OfferIntention? {
        chosenIntentionId.flatMap { offer.intention(id: $0) }
    }

    @ViewBuilder
    private var signOfCrossIntentionBlock: some View {
        let hasIntention = !chosenIntentionTitle.isEmpty
        let resolved = chosenOfferIntention
        let displayTitle = resolved.map {
            IntentionPrivacy.displayTitle($0, hidden: hideIntentionText)
        } ?? IntentionPrivacy.displayText(chosenIntentionTitle, hidden: hideIntentionText)

        HStack(alignment: .center, spacing: AppTheme.Space.sm) {
            Text("For:")
                .font(AppTheme.TypeRole.themeSummary)
                .foregroundStyle(palette.dim)

            if hasIntention {
                Button {
                    showIntentionSheet = true
                } label: {
                    HStack(spacing: AppTheme.Space.sm) {
                        // Avatar only when we have a known intention (papal portrait / glyph).
                        if let resolved {
                            IntentionIconView(
                                accent: resolved.accent,
                                emoji: resolved.displayEmoji,
                                size: 27,
                                usesPopePortrait: resolved.isPapal
                            )
                        }
                        Text(displayTitle)
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("For: \(displayTitle)")
                .accessibilityHint("Opens intention picker")

                Button {
                    clearChosenIntention()
                } label: {
                    Image(systemName: "xmark")
                        .guideSymbol(size: 15, weight: .semibold)
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: AppTheme.Accessibility.minHitTarget, height: AppTheme.Accessibility.minHitTarget)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear intention")
                .accessibilityHint("Returns to Add an intention")
            } else {
                Button {
                    showIntentionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Add an intention")
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.accent)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .guideSymbol(size: 12, weight: .semibold)
                            .foregroundStyle(palette.accent.opacity(0.75))
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("For: Add an intention")
                .accessibilityHint("Opens intention picker")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, AppTheme.Space.xl)
    }

    private func clearChosenIntention() {
        chosenIntentionId = nil
        chosenIntentionTitle = ""
        chosenIntentionNote = ""
        sessionStore.updateIntention(id: nil, title: nil)
    }

    /// Website `.lead`: italic dim, with the virtue / "your intention" in stronger ink.
    private func emphasizeLead(for step: RosaryStep) -> String? {
        if step.kind == .signOfTheCross { return "your intention" }
        if step.kind == .hailMary, let intention = step.intention?.english {
            for v in ["faith", "hope", "charity"] where intention.lowercased().hasSuffix(v) {
                return v
            }
        }
        return nil
    }

    @ViewBuilder
    private func leadLine(_ full: String, emphasizeSuffix: String?) -> some View {
        let base = AppTheme.TypeRole.bodySmall
        if let suffix = emphasizeSuffix, let range = full.range(of: suffix, options: [.caseInsensitive, .backwards]) {
            let before = String(full[..<range.lowerBound])
            let hit = String(full[range])
            Text("\(Text(before).foregroundStyle(palette.dim))\(Text(hit).foregroundStyle(palette.ink).fontWeight(.medium))")
                .font(base)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(full)
                .font(base)
                .foregroundStyle(palette.dim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func announceBody(_ step: RosaryStep) -> some View {
        let scriptureSize = (step.isPlate ? 20.0 : 21.0) * settings.textSize.scale
        return VStack(alignment: .leading, spacing: step.isPlate ? 12 : 10) {
            BilingualStack(
                text: step.body,
                language: .english,
                font: AppTheme.sans(scriptureSize),
                pointSize: scriptureSize
            )
            if let ref = step.scriptureReference {
                Text(ref)
                    .font(AppTheme.sans(step.isPlate ? 11 : 12))
                    .foregroundStyle(palette.faint)
                    .padding(.top, step.isPlate ? 2 : 0)
            }
            if let fruit = step.subtitle {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Hairline()
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Fruit")
                            .font(AppTheme.sans(step.isPlate ? 12 : 14, weight: .medium))
                            .tracking(step.isPlate ? 0.8 : 0)
                            .foregroundStyle(palette.faint.opacity(step.isPlate ? 0.85 : 1))
                        Text(fruit.primary(for: .english))
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.ink)
                    }
                }
                .padding(.top, AppTheme.Space.lg)
            }
        }
    }

    @ViewBuilder
    private func footer(_ step: RosaryStep) -> some View {
        if prayerUsesScrollTemplate {
            EmptyView()
        } else {
            footerBar(step)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    if height > 1 { prayerFooterHeight = height }
                }
        }
    }

    private func footerBar(_ step: RosaryStep) -> some View {
        let nextTitle = step.nextLabel == "Continue" ? "Next" : step.nextLabel
        let isDecadeHailMary = step.kind == .hailMary && step.decadeNumber != nil
        let showCompleteDecade = isDecadeHailMary && step.hailMaryNumber != 10
        // Every step's Next is the secondary pill, matching the scroll circle.
        // Beside it on decade Hail Marys 1–9, Complete decade is tertiary.
        return VStack(spacing: AppTheme.Component.prayerFooterControlGap) {
            // Web `.pfoot`: Next | Complete decade side by side on Hail Marys.
            HStack(spacing: AppTheme.Component.prayerFooterButtonGap) {
                PillButton(title: nextTitle, filled: false, action: advance)
                if showCompleteDecade {
                    PillButton(title: "Complete decade", filled: false, tertiary: true) {
                        skipDecadeHailMarys()
                    }
                }
            }
            // Web `canLang`: hide on mystery plates; English only there.
            if !step.isPlate {
                languageChips
            }
        }
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.md)
        // Solid foot in document flow (web phone). No upward fade — that covered the rosary.
        .background(palette.prayBg)
    }

    private var languageChips: some View {
        // Web phone `.lang`: left-aligned under Next, fixed width (~13.25rem), shorter than Next.
        Picker("Language", selection: languageSelection) {
            ForEach(PrayerLanguage.allCases) { option in
                Text(option.chip).tag(option)
            }
        }
        .guideSegmentedControl()
        .frame(width: 220)
        .frame(maxWidth: .infinity, alignment: .leading)
        .labelsHidden()
        .accessibilityLabel("Prayer language")
    }

    private var languageSelection: Binding<PrayerLanguage> {
        Binding(
            get: { settings.language },
            set: { newValue in
                // A segmented control can emit its current value while SwiftUI
                // is updating the footer. Writing the session then invalidates
                // the same update and the main thread never comes back.
                guard newValue != settings.language else { return }
                settings.language = newValue
                if var current = sessionStore.session {
                    current.language = newValue
                    sessionStore.session = current
                }
            }
        )
    }

    private func roundControl(system: String? = nil, label: String? = nil, action: @escaping () -> Void) -> some View {
        PrayChromeButton(system: system, label: label, action: action)
            .accessibilityLabel(label ?? system ?? "Control")
    }

    private func shouldShowBeads(_ step: RosaryStep) -> Bool {
        language != .bilingual && !step.isPlate && !step.isFinis && step.kind != .completion && step.kind != .ourFather
    }

    // MARK: - Finis

    private var finisLayer: some View {
        CompletionView(
            mysterySet: launch.mysterySet,
            intentionTitle: completionIntentionTitle,
            intentionIsPapal: completionIntentionFace?.isPapal ?? completionIntentionIsPapal,
            intentionFace: completionIntentionFace,
            quote: completionQuote ?? QuoteCatalog.quote(),
            onDone: { finishRosary() },
            onMichael: {
                // Rosary is already marked complete on entering finis; Michael is optional continuation.
                showingMichael = true
                HapticService.play(.medium, enabled: settings.hapticsEnabled)
            }
        )
    }

    private var completionIntentionIsPapal: Bool {
        let id = chosenIntentionId ?? sessionStore.session?.intentionId ?? launch.intentionId
        return id.flatMap { offer.intention(id: $0)?.isPapal } ?? false
    }

    /// Resolve the display title from live state, session, or OfferStore — then freeze it.
    private func resolvedIntentionTitleForCompletion() -> String? {
        let trimmedChosen = chosenIntentionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedChosen.isEmpty { return trimmedChosen }

        if let raw = sessionStore.session?.intentionTitle {
            let sessionTitle = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !sessionTitle.isEmpty { return sessionTitle }
        }

        let id = chosenIntentionId ?? sessionStore.session?.intentionId ?? launch.intentionId
        if let id, let found = offer.intention(id: id) {
            let title = found.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { return title }
        }
        return nil
    }

    /// Snapshot the category icon at the same moment as the title.
    private func resolvedIntentionFaceForCompletion() -> CompletionIntentionFace? {
        let id = chosenIntentionId ?? sessionStore.session?.intentionId ?? launch.intentionId
        guard let id, let found = offer.intention(id: id) else { return nil }
        return CompletionIntentionFace(
            accent: found.accent,
            emoji: found.displayEmoji,
            isPapal: found.isPapal
        )
    }

    private func lockCompletionIntentionIfNeeded() {
        if completionIntentionTitle == nil {
            completionIntentionTitle = resolvedIntentionTitleForCompletion()
        }
        if completionIntentionFace == nil {
            completionIntentionFace = resolvedIntentionFaceForCompletion()
        }
        // Keep live fields aligned so carry / resume paths stay consistent.
        if let locked = completionIntentionTitle, chosenIntentionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chosenIntentionTitle = locked
        }
    }

    private var michaelCanScrollFurther: Bool {
        michaelContentHeight > michaelViewportHeight + 6 && !michaelActionLocked
    }

    /// Same chrome as a rosary prayer page: text-size, close, no stage track.
    private var michaelHeader: some View {
        HStack {
            // Text size lives in Settings. Close stays trailing.
            Spacer()
            roundControl(system: "xmark") {
                returnToFinishScreen()
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.xs)
    }

    /// Same title block as `locus` on a non-plate prayer.
    private var michaelLocus: some View {
        let prayer = PrayerCatalog.saintMichael
        return VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            Text(prayer.title.primary(for: language))
                .font(AppTheme.TypeRole.modalTitle)
                .foregroundStyle(palette.ink)
                .tracking(-0.2)
            if language == .bilingual {
                Text(prayer.title.latin)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 48pt from the close button's bottom edge to this title. No stage track on this page.
        .padding(.top, PrayerTitleChrome.belowClose)
        .padding(.bottom, 22)
    }

    private var michaelLayer: some View {
        VStack(spacing: 0) {
            michaelHeader

            VStack(spacing: 0) {
                    GeometryReader { scrollGeo in
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                VStack(alignment: .leading, spacing: 0) {
                                    michaelLocus
                                    BilingualStack(
                                        text: PrayerCatalog.saintMichael.text,
                                        language: language,
                                        font: AppTheme.TypeRole.prayerText(scale: settings.textSize.scale),
                                        pointSize: 21 * settings.textSize.scale
                                    )
                                }
                                .padding(.horizontal, AppTheme.gutter)
                                .padding(.bottom, AppTheme.Space.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer(minLength: 0)

                                // Room so the last lines can clear the floating action.
                                Color.clear
                                    .frame(height: 132)
                                Color.clear
                                    .frame(height: 1)
                                    .id(MichaelScrollAnchor.bottom)
                            }
                            .frame(minHeight: scrollGeo.size.height, alignment: .top)
                            .frame(maxWidth: .infinity)
                            .background {
                                GeometryReader { geo in
                                    Color.clear.preference(key: MichaelContentHeightKey.self, value: geo.size.height)
                                }
                            }
                        }
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: MichaelViewportHeightKey.self, value: geo.size.height)
                            }
                        }
                        .scrollPosition($michaelScrollPosition)
                        .onScrollGeometryChange(for: PlateScrollMetrics.self) { geometry in
                        PlateScrollMetrics(
                            offsetY: geometry.contentOffset.y,
                            contentHeight: geometry.contentSize.height,
                            viewportHeight: geometry.containerSize.height
                        )
                    } action: { _, newValue in
                        if newValue.contentHeight > 1 {
                            michaelContentHeight = max(michaelContentHeight, newValue.contentHeight)
                        }
                        if newValue.viewportHeight > 1 {
                            michaelViewportHeight = newValue.viewportHeight
                        }
                        let y = max(0, newValue.offsetY)
                        if abs(y - michaelScrollY) > 0.5 {
                            michaelLastDrag = Date()
                        }
                        michaelScrollY = y
                        // Live scroll range. The stored height only grows, so it
                        // can sit past the offset the scroll view can actually reach.
                        let contentH = newValue.contentHeight > 1 ? newValue.contentHeight : michaelContentHeight
                        let viewH = newValue.viewportHeight > 1 ? newValue.viewportHeight : michaelViewportHeight
                        let maxOffset = max(0, contentH - viewH)
                        // Dragging to the bottom expands the circle. A tap locks
                        // at the start of its own scroll and stays armed until it
                        // arrives, so these updates cannot cancel that motion.
                        let next = ScrollMorph.resolve(
                            locked: michaelActionLocked,
                            armed: michaelArrowArmed,
                            y: y,
                            maxOffset: maxOffset
                        )
                        if next.locked != michaelActionLocked { michaelActionLocked = next.locked }
                        if next.armed != michaelArrowArmed { michaelArrowArmed = next.armed }
                    }
                        .onScrollPhaseChange { _, phase in
                            if phase == .interacting {
                                michaelArrowArmed = false
                                michaelLastDrag = Date()
                            }
                        }
                        .onChange(of: settings.language) {
                            michaelActionLocked = false
                            michaelArrowArmed = false
                            michaelContentHeight = 0
                        }
                    }
                    .onPreferenceChange(MichaelContentHeightKey.self) { height in
                        // Only grow. A layout pass while scrolled can report the
                        // viewport, and assigning that turns the circle into Done
                        // with no tap.
                        if height > michaelContentHeight {
                            michaelContentHeight = height
                        }
                    }
                    .onPreferenceChange(MichaelViewportHeightKey.self) { height in
                        if height > 1 { michaelViewportHeight = height }
                    }
                    .overlay(alignment: .bottom) {
                        VStack(spacing: AppTheme.Component.prayerFooterControlGap) {
                            michaelActionChrome {
                                // Finger-scrolls that lift on the circle are not taps.
                                guard Date().timeIntervalSince(michaelLastDrag) > 0.25 else { return }
                                HapticService.play(.light, enabled: settings.hapticsEnabled)
                                let contentH = michaelContentHeight
                                let viewH = michaelViewportHeight
                                let maxOffset = max(0, contentH - viewH)
                                let distanceFromBottom = maxOffset - michaelScrollY
                                // One motion every tap. scrollTo(id:) of the same bottom
                                // anchor is dropped after the user drags away, which
                                // expanded Done without moving. Setting the offset again
                                // still scrolls. Already-at-bottom just expands.
                                michaelArrowArmed = distanceFromBottom > 8
                                withAnimation(reduceMotion ? nil : MotionTokens.reveal, completionCriteria: .logicallyComplete) {
                                    michaelActionLocked = true
                                    if distanceFromBottom > 8 {
                                        michaelScrollPosition.scrollTo(y: maxOffset)
                                    }
                                } completion: {
                                    michaelArrowArmed = false
                                }
                                disarmLater { michaelArrowArmed = false }
                            }
                            languageChips
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        .padding(.bottom, AppTheme.Space.lg)
                        .padding(.top, AppTheme.Space.md)
                    }
                }
        }
        .background(palette.prayBg.ignoresSafeArea())
        .onAppear {
            // Opening Saint Michael again starts as a circle at the top.
            michaelActionLocked = false
            michaelArrowArmed = false
            michaelScrollY = 0
            michaelLastDrag = .distantPast
            michaelScrollPosition = ScrollPosition(edge: .top)
        }
    }

    /// Mystery-plate circle, in the prayer footer. It becomes Done at the end of the scroll.
    private func michaelActionChrome(scrollToBottom: @escaping () -> Void) -> some View {
        scrollActionChrome(
            showScroll: michaelCanScrollFurther,
            expandedTitle: "Done",
            scrollLabel: "Scroll to read the prayer",
            onScroll: scrollToBottom,
            onAdvance: {
                // Light tap, same as the circle. Fires before the dismiss, which stays immediate.
                HapticService.play(.light, enabled: settings.hapticsEnabled)
                returnToFinishScreen()
            }
        )
    }

    /// Circle over the prayer. It becomes the step's own action once the text is at the bottom.
    /// Solid fill for the whole morph. No footer bar.
    private func scrollActionChrome(
        showScroll: Bool,
        expandedTitle: String,
        scrollLabel: String,
        onScroll: @escaping () -> Void,
        onAdvance: @escaping () -> Void
    ) -> some View {
        let animation = reduceMotion ? nil : MotionTokens.reveal
        return HStack {
            if showScroll {
                Spacer(minLength: 0)
            }
            Button {
                if showScroll {
                    onScroll()
                } else {
                    onAdvance()
                }
            } label: {
                let side = AppTheme.Component.mysteryPlateActionCircle
                ZStack {
                    Capsule()
                        .fill(palette.secondaryButtonFill)
                    if showScroll {
                        Image(systemName: "chevron.down")
                            .guideSymbol(size: 17, weight: .semibold)
                            .foregroundStyle(palette.secondaryButtonText)
                            .transition(.identity)
                    } else {
                        Text(expandedTitle)
                            .font(AppTheme.TypeRole.callout(weight: .semibold))
                            .foregroundStyle(palette.secondaryButtonText)
                            .transition(.identity)
                    }
                }
                .frame(maxWidth: showScroll ? side : .infinity)
                .frame(width: showScroll ? side : nil, height: AppTheme.Component.pillHeight)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showScroll ? scrollLabel : expandedTitle)
        }
        .animation(animation, value: showScroll)
    }

    private var prayerCanScrollFurther: Bool {
        prayerUsesScrollTemplate && !prayerActionLocked
    }

    /// Long prayers only. Short prayers keep the in-flow footer.
    /// Compares the text to the room it would have with the footer showing.
    private func updatePrayerScrollTemplate(viewport: CGFloat) {
        guard prayerTextHeight > 1, viewport > 1 else { return }
        let roomWithFooter = prayerUsesScrollTemplate ? viewport - prayerFooterHeight : viewport
        if prayerUsesScrollTemplate {
            if prayerTextHeight <= roomWithFooter - 8 {
                prayerUsesScrollTemplate = false
                prayerActionLocked = false
                prayerArrowArmed = false
            }
        } else if prayerTextHeight > roomWithFooter + 6 {
            prayerUsesScrollTemplate = true
            prayerActionLocked = false
            prayerArrowArmed = false
        }
    }

    /// Every new step, language, or text size starts as a circle at the top.
    /// The measured text height is kept: the next step re-measures it, and a
    /// zero here left the template off (a full-width button) when the height
    /// came back unchanged.
    private func resetPrayerScrollState() {
        prayerActionLocked = false
        prayerArrowArmed = false
        prayerContentHeight = 0
        prayerScrollY = 0
        prayerLastDrag = .distantPast
        prayerScrollPosition = ScrollPosition(edge: .top)
        resetPairChoreography()
    }

    /// Straight back to the circle, no animation (new step, language, size).
    private func resetPairChoreography() {
        pairGeneration &+= 1
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            pairNextExpanded = false
            pairSecondShown = false
        }
    }

    /// Expand: circle stretches into Next, then Complete decade follows.
    /// Collapse: Complete decade tucks away, then Next shrinks to the circle.
    private func runPairChoreography(expand: Bool) {
        pairGeneration &+= 1
        let generation = pairGeneration
        if reduceMotion {
            pairNextExpanded = expand
            pairSecondShown = expand
            return
        }
        if expand {
            guard !pairNextExpanded || !pairSecondShown else { return }
            withAnimation(MotionTokens.reveal) { pairNextExpanded = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + PairMotion.stagger) {
                guard generation == pairGeneration, pairNextExpanded else { return }
                withAnimation(PairMotion.secondIn) { pairSecondShown = true }
            }
        } else {
            guard pairNextExpanded || pairSecondShown else { return }
            if pairSecondShown {
                withAnimation(PairMotion.secondOut) { pairSecondShown = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + PairMotion.stagger) {
                    guard generation == pairGeneration else { return }
                    withAnimation(MotionTokens.reveal) { pairNextExpanded = false }
                }
            } else {
                withAnimation(MotionTokens.reveal) { pairNextExpanded = false }
            }
        }
    }

    /// Backstop: a tap's scroll never keeps the control from collapsing.
    private func disarmLater(_ clear: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { clear() }
    }

    private func scrollPrayerToBottom() {
        guard Date().timeIntervalSince(prayerLastDrag) > 0.25 else { return }
        HapticService.play(.light, enabled: settings.hapticsEnabled)
        let contentH = prayerContentHeight > 1 ? prayerContentHeight : prayerTextHeight + 132
        let viewH = prayerViewportHeight
        let maxOffset = max(0, contentH - viewH)
        let distanceFromBottom = maxOffset - prayerScrollY
        prayerArrowArmed = distanceFromBottom > 8
        withAnimation(reduceMotion ? nil : MotionTokens.reveal, completionCriteria: .logicallyComplete) {
            prayerActionLocked = true
            if distanceFromBottom > 8 {
                prayerScrollPosition.scrollTo(y: maxOffset)
            }
        } completion: {
            prayerArrowArmed = false
        }
        disarmLater { prayerArrowArmed = false }
    }

    @ViewBuilder
    private func prayerScrollChrome(_ step: RosaryStep) -> some View {
        let nextTitle = step.nextLabel == "Continue" ? "Next" : step.nextLabel
        let showCompleteDecade = step.kind == .hailMary && step.decadeNumber != nil && step.hailMaryNumber != 10
        VStack(spacing: AppTheme.Component.prayerFooterControlGap) {
            if showCompleteDecade {
                // Two buttons: staggered, see `runPairChoreography`.
                HStack(spacing: pairSecondShown ? AppTheme.Component.prayerFooterButtonGap : 0) {
                    scrollActionChrome(
                        showScroll: !pairNextExpanded,
                        expandedTitle: nextTitle,
                        scrollLabel: "Scroll to read the prayer",
                        onScroll: { scrollPrayerToBottom() },
                        onAdvance: { advance() }
                    )
                    // Next stays on top so Complete decade comes out from behind it.
                    .zIndex(1)
                    if pairSecondShown {
                        PillButton(title: "Complete decade", filled: false, tertiary: true) {
                            skipDecadeHailMarys()
                        }
                        .transition(.modifier(
                            active: PairSlotEffect(offset: -PairMotion.slide, cover: 1, scale: 0.96),
                            identity: PairSlotEffect(offset: 0, cover: 0, scale: 1)
                        ))
                        .zIndex(0)
                    }
                }
                .onAppear {
                    // Already expanded or not, start in the matching state.
                    var sync = Transaction()
                    sync.disablesAnimations = true
                    withTransaction(sync) {
                        pairNextExpanded = !prayerCanScrollFurther
                        pairSecondShown = !prayerCanScrollFurther
                    }
                }
                .onChange(of: prayerCanScrollFurther) { _, canScroll in
                    runPairChoreography(expand: !canScroll)
                }
            } else {
                scrollActionChrome(
                    showScroll: prayerCanScrollFurther,
                    expandedTitle: nextTitle,
                    scrollLabel: "Scroll to read the prayer",
                    onScroll: { scrollPrayerToBottom() },
                    onAdvance: { advance() }
                )
            }
            languageChips
        }
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.md)
    }

    // MARK: - Navigation

    private func markRosaryCompletedIfNeeded() {
        // Record completion when the ceremonial screen appears so St Michael
        // continuation cannot undo or re-trigger tracking.
        if !didRecordCarry, let id = chosenIntentionId {
            offer.recordCarry(id: id)
            didRecordCarry = true
        }
        if sessionStore.session != nil {
            sessionStore.complete()
        }
    }

    /// Saint Michael is a side step. Done and the close control come back here.
    private func returnToFinishScreen() {
        showingMichael = false
    }

    private func finishRosary() {
        markRosaryCompletedIfNeeded()
        dismiss()
    }

    private func configure() {
        switch launch {
        case .fresh(let set, let intentionId):
            // Do not persist yet — step 0 must not wipe a resumable session.
            freshSetPending = set
            steps = RosarySequenceBuilder.build(set: set)
            index = 0
            let resolvedId = intentionId
            let resolvedTitle = resolvedId.flatMap { offer.intention(id: $0)?.title } ?? ""
            chosenIntentionId = resolvedId
            chosenIntentionTitle = resolvedTitle
            chosenIntentionNote = resolvedId.flatMap { offer.intention(id: $0)?.note } ?? ""
            didRecordCarry = false
            completionIntentionTitle = nil
            completionIntentionFace = nil
            completionQuote = nil
            beadTimelinePaused = false
            finishBlack = 0
            showingCompletion = false
        case .resume(let session):
            freshSetPending = nil
            steps = RosarySequenceBuilder.build(set: session.mysterySet)
            index = min(session.stepIndex, max(steps.count - 1, 0))
            if var current = sessionStore.session {
                current.language = settings.language
                sessionStore.session = current
            }
            chosenIntentionId = session.intentionId
            let title = session.intentionTitle
                ?? session.intentionId.flatMap { offer.intention(id: $0)?.title }
                ?? ""
            chosenIntentionTitle = title
            chosenIntentionNote = session.intentionId.flatMap { offer.intention(id: $0)?.note } ?? ""
            didRecordCarry = false
            completionIntentionTitle = nil
            completionIntentionFace = nil
            completionQuote = nil
            beadTimelinePaused = false
            finishBlack = 0
            showingCompletion = false
        }
        playHaptic()
    }

    private func advance() {
        if current?.isFinis == true {
            finishRosary()
            return
        }

        if current?.kind == .concludingPrayer {
            showCompletionScreen()
            return
        }

        guard index < steps.count - 1 else {
            finishRosary()
            return
        }
        move(to: index + 1)
    }

    private func showCompletionScreen() {
        // Do not touch @State or UserDefaults in this button action. Device
        // scene-update logs (0x8BADF00D) show the main thread still inside
        // that update 10s later — ButtonBehavior, then Core Text variation
        // fonts — so the bead TimelineView stops with the rest of the UI.
        // Beads keep running until the fade below actually starts.
        DispatchQueue.main.async {
            let title = resolvedIntentionTitleForCompletion()
            let face = resolvedIntentionFaceForCompletion()
            let quote = QuoteCatalog.selectCompletionQuote()
            RosaryTickLibrary.preload()
            let fade = reduceMotion ? 0.01 : 0.62
            withAnimation(.easeInOut(duration: fade)) {
                finishBlack = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    if completionIntentionTitle == nil {
                        completionIntentionTitle = title
                    }
                    if completionIntentionFace == nil {
                        completionIntentionFace = face
                    }
                    completionQuote = quote
                    showingCompletion = true
                    finishBlack = 0
                }
                DispatchQueue.main.async {
                    QuoteCatalog.rememberCompletionQuote(quote)
                }
            }
        }
    }

    private func retreat() {
        guard !showingCompletion else { return }
        guard index > 0 else { return }
        move(to: index - 1)
    }

    private func move(to next: Int) {
        if let set = freshSetPending, next > 0 {
            sessionStore.start(set: set, language: settings.language, intentionId: chosenIntentionId, intentionTitle: chosenIntentionTitle.isEmpty ? nil : chosenIntentionTitle)
            freshSetPending = nil
        }
        if steps.indices.contains(next), steps[next].isFinis {
            lockCompletionIntentionIfNeeded()
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            index = next
        }
        if next > 0 {
            sessionStore.updateStep(next)
        }
        playHaptic()
    }

    private func jump(to stage: PrayTrackStage) {
        if let target = steps.firstIndex(where: { $0.stage == stage }) {
            move(to: target)
        }
    }

    private func skipDecadeHailMarys() {
        guard let step = current, let decade = step.decadeNumber else { return }
        if let target = steps.firstIndex(where: { $0.decadeNumber == decade && $0.kind == .gloryBe && $0.id > step.id }) {
            move(to: target)
        }
    }

    private func playHaptic() {
        if let current {
            HapticService.play(current.haptic, enabled: settings.hapticsEnabled)
        }
    }
}


// MARK: - Mystery plate scroll helpers

private struct PlateScrollMetrics: Equatable {
    var offsetY: CGFloat
    var contentHeight: CGFloat
    var viewportHeight: CGFloat
}

private enum PlateScrollAnchor {
    static let bottom = "plate-scroll-bottom"
}

private struct PrayerTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Two-button scroll chrome timing. Springs sit with `MotionTokens.reveal`.
private enum PairMotion {
    /// Gap between Next and Complete decade, both directions.
    static let stagger: TimeInterval = 0.1
    /// Complete decade settles in; Next eases over in the same spring.
    static let secondIn = Animation.spring(response: 0.42, dampingFraction: 0.86)
    /// Quicker out so Next can start shrinking soon after.
    static let secondOut = Animation.spring(response: 0.3, dampingFraction: 0.9)
    /// Complete decade slides out from under Next by this much.
    static let slide: CGFloat = 18
}

/// Complete decade slot. The pill stays solid the whole time: its label
/// fades up from a plain surface-coloured capsule while it slides and scales.
private struct PairSlotEffect: ViewModifier {
    @Environment(\.palette) private var palette
    var offset: CGFloat
    /// 1 = a plain surface capsule over the label, 0 = label fully shown.
    var cover: Double
    var scale: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                Capsule()
                    .fill(palette.tertiaryButtonFill)
                    .opacity(cover)
                    .allowsHitTesting(false)
            }
            .scaleEffect(scale, anchor: .leading)
            .offset(x: offset)
    }
}

private enum PrayerScrollAnchor {
    static let bottom = "prayer-scroll-bottom"
}

/// One rule for every circle-to-button control on a scrolling prayer.
/// Expand near the bottom; collapse once the reader is clearly back up.
/// Both gaps scale with the scroll range so short overflows still collapse.
enum ScrollMorph {
    static func expandGap(_ maxOffset: CGFloat) -> CGFloat {
        min(36, maxOffset * 0.2)
    }

    static func collapseGap(_ maxOffset: CGFloat) -> CGFloat {
        // Half the range, at most 112pt. Always above the expand line.
        min(112, maxOffset * 0.5)
    }

    /// New (locked, armed) after a scroll position update.
    /// `armed` is a tap's own scroll on its way down. It clears on arrival.
    static func resolve(locked: Bool, armed: Bool, y: CGFloat, maxOffset: CGFloat) -> (locked: Bool, armed: Bool) {
        guard maxOffset > 8 else { return (locked, false) }
        if y >= maxOffset - expandGap(maxOffset) {
            return (true, false)
        }
        if armed {
            return (locked, armed)
        }
        if locked, y < maxOffset - collapseGap(maxOffset) {
            return (false, false)
        }
        return (locked, armed)
    }
}

private enum PrayerTitleChrome {
    /// Prayer titles start at least this far below the close button.
    static let belowClose: CGFloat = 48
    /// `header` bottom padding (4) + `SevenStageTrack` (44pt row + 14pt bottom).
    static let belowCloseBeforeColumn: CGFloat = AppTheme.Space.xs + AppTheme.Accessibility.minHitTarget + 14
}

private enum MichaelScrollAnchor {
    static let bottom = "michael-scroll-bottom"
}

private struct MichaelContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct MichaelViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlateChromeHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlateContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlateViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PlateScrollHintBob: ViewModifier {
    var animate: Bool
    @State private var visible = false
    @State private var drift: CGFloat = 0
    @State private var runID = UUID()

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: drift)
            .onAppear {
                let id = UUID()
                runID = id
                // Avoid flashing before the delayed reveal.
                visible = false
                drift = 0
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard runID == id else { return }
                    withAnimation(.easeOut(duration: 0.35)) {
                        visible = true
                    }
                    guard animate else { return }
                    // One or two soft drifts, then rest — never a loop.
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    guard runID == id else { return }
                    withAnimation(.easeInOut(duration: 0.7)) { drift = 5 }
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    guard runID == id else { return }
                    withAnimation(.easeInOut(duration: 0.7)) { drift = 0 }
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    guard runID == id else { return }
                    withAnimation(.easeInOut(duration: 0.7)) { drift = 5 }
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    guard runID == id else { return }
                    withAnimation(.easeInOut(duration: 0.7)) { drift = 0 }
                }
            }
            .onDisappear {
                runID = UUID()
                visible = false
                drift = 0
            }
    }
}

// MARK: - Mystery plate scroll tracking

private struct PlateScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
