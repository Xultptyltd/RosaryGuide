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

/// Where the prayer footer wants the language toggle drawn.
private struct LanguageChipsAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

struct PrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessionStore
    @Environment(OfferStore.self) private var offer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var launch: PrayLaunch

    @State private var steps: [RosaryStep] = []
    @State private var index: Int = 0
    @State private var confirmReplace = false
    @State private var didConfigure = false
    @State private var showingMichael = false
    /// Saint Michael after the Rosary keeps its own English / Latin / Both choice.
    @State private var michaelLanguage: PrayerLanguage?
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
    /// Rosary bead shelf height (with its padding), measured wherever it is drawn.
    @State private var prayerBeadShelfHeight: CGFloat = 0
    @State private var prayerUsesScrollTemplate = false
    @State private var prayerActionLocked = false
    @State private var prayerArrowArmed = false
    @State private var prayerScrollY: CGFloat = 0
    /// True while content has scrolled under the top bar (shows the frosted bar).
    @State private var topBarScrolled = false
    @State private var lastAdvanceAt = Date.distantPast
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
    /// Rosary settings this Rosary was built with (fresh: Settings; resume: the saved session).
    @State private var activeConfig: RosaryConfig = .default

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
    /// Intentions offered for this Rosary, in pick order (up to `PrayerSession.maxIntentions`).
    @State private var chosenIntentionIds: [UUID] = []
    @State private var chosenIntentionTitles: [String] = []
    /// Dedicated "Offer this Rosary for" step shown between Sign of the Cross and the Creed.
    /// Not a `RosaryStep`, so saved `stepIndex` values keep their meaning.
    @State private var showingIntentionStep = false
    /// Intention step scroll / circle-to-Continue state (mirrors the prayer scroll template).
    @State private var intentionListHeight: CGFloat = 0
    @State private var intentionContentHeight: CGFloat = 0
    @State private var intentionViewportHeight: CGFloat = 0
    @State private var intentionScrollY: CGFloat = 0
    /// Bumped by the footer's Add intention button; the list opens its editor.
    @State private var intentionAddRequests = 0
    @State private var intentionActionLocked = false
    @State private var intentionArrowArmed = false
    @State private var intentionLastDrag = Date.distantPast
    @State private var intentionScrollPosition = ScrollPosition(edge: .top)
    @State private var didRecordCarry = false
    /// Chosen before the finis screen exists so its first update does not write UserDefaults.
    @State private var completionQuote: CompletionQuote?
    /// Stops the bead TimelineView before the finis screen is inserted.
    @State private var beadTimelinePaused = false
    /// Black veil over the closing prayer. Beads keep running underneath until this covers them.
    @State private var finishBlack: Double = 0
    @State private var activePrayerStart: Date?
    @State private var pendingActivePrayerTime: TimeInterval = 0
    @State private var prayerAutosaveTask: Task<Void, Never>?
    @State private var isClosingPrayerFlow = false
    @State private var plateCanvasFrame: CGRect?
    @State private var plateCanvasBottomInset: CGFloat = 0

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
                } else if showingIntentionStep {
                    intentionStepLayer(current)
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
        .onChange(of: settings.currentRosaryConfig) { _, config in
            applyLiveConfig(config)
        }
        .onAppear {
            guard !didConfigure else { return }
            didConfigure = true
            if case .fresh(let set, _, _) = launch, sessionStore.resumableSession != nil {
                freshSetPending = set
                confirmReplace = true
            } else {
                configure()
            }
            startActivePrayerTimerIfNeeded()
            startPrayerAutosave()
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            stopPrayerAutosave()
            saveActivePrayerTime(continueTiming: false)
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                startActivePrayerTimerIfNeeded()
                startPrayerAutosave()
            case .inactive, .background:
                stopPrayerAutosave()
                saveActivePrayerTime(continueTiming: false)
            @unknown default:
                stopPrayerAutosave()
                saveActivePrayerTime(continueTiming: false)
            }
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
                closePrayerFlow()
            }
        } message: {
            Text("You already have a rosary in progress today. Starting fresh will replace it once you move past the first step.")
        }
    }

    // MARK: - Main pray column

    private func prayLayer(_ step: RosaryStep) -> some View {
        GeometryReader { geo in
            let showBeads = shouldShowBeads(step)

            if step.isPlate, let mystery = step.mystery {
                // Anchor the artwork bottom below the physical screen midpoint.
                // The reading block follows with a 24pt gap.
                let liveFrame = geo.frame(in: .global)
                let frame = plateCanvasFrame ?? liveFrame
                let bottomInset = plateCanvasFrame == nil ? geo.safeAreaInsets.bottom : plateCanvasBottomInset
                let screenHeight = frame.maxY + bottomInset
                plateLayer(
                    step,
                    mystery: mystery,
                    imageBottom: screenHeight * AppTheme.rosaryMysteryArtworkBottomFraction,
                    textTop: screenHeight * AppTheme.rosaryMysteryArtworkBottomFraction + AppTheme.Space.xl,
                    scrollTop: frame.minY
                )
                .onGeometryChange(for: CGRect.self) { geometry in
                    geometry.frame(in: .global)
                } action: { frame in
                    // A cover's global origin moves during dismissal. Keep the
                    // artwork canvas fixed instead of recropping it as it slides.
                    guard !isClosingPrayerFlow else { return }
                    plateCanvasFrame = frame
                    plateCanvasBottomInset = geo.safeAreaInsets.bottom
                }
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        VStack(spacing: 0) {
                            standardPrayColumn(step, scrollHeight: geo.size.height)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            // Long (scrolling) prayers carry the shelf inside the prayer
                            // content instead, so it never sits below the language toggle.
                            if showBeads, !prayerUsesScrollTemplate, let bead = step.bead {
                                beadShelf(bead)
                            }
                        }

                        if step.kind != .signOfTheCross {
                            edgeTapZones
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .coordinateSpace(name: "prayerNavigationContent")
                    .simultaneousGesture(
                        SpatialTapGesture().onEnded { tap in
                            guard step.kind == .signOfTheCross else { return }
                            if tap.location.x >= geo.size.width * 0.85 {
                                advance()
                            } else if tap.location.x <= geo.size.width * 0.15 {
                                retreat()
                            }
                        }
                    )

                    footer(step)
                }
                // Long prayers scroll under the bar, which turns frosted once scrolled.
                .safeAreaBar(edge: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        header(step)
                        SevenStageTrack(current: step.stage) { jump(to: $0) }
                    }
                    .guideChromeBar(visible: topBarScrolled && prayerUsesScrollTemplate, prayerBackground: true)
                }
                .scrollEdgeEffectHidden(true, for: .top)
                .overlay(alignment: .bottom) {
                    if prayerUsesScrollTemplate {
                        // The circle and language toggle float on the prayer, not on a
                        // black bar. The bead shelf scrolls with the prayer text.
                        prayerScrollChrome(step)
                    }
                }
            }
        }
        .overlayPreferenceValue(LanguageChipsAnchorKey.self) { stableLanguageChips($0) }
        .onChange(of: index) { _, _ in
            // Focus stays on Next, so say where the new step is.
            if UIAccessibility.isVoiceOverRunning, let current, !current.isFinis {
                AccessibilityNotification.Announcement(current.spokenProgress).post()
            }
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
        imageBottom: CGFloat,
        textTop: CGFloat,
        scrollTop: CGFloat
    ) -> some View {
        let progress = plateScrollProgress
        let chromeH = max(plateChromeHeight, 88)
        // The hero starts at the screen top and ends where the text starts, so the
        // painting is scaled to that band and fully dissolved by the first line.
        let heroHeight = max(imageBottom, scrollTop + chromeH + 1)
        // Spacer puts the mystery text's top edge at `textTop` (below the artwork);
        // the scroll view starts at `scrollTop`; 4pt is the text block's top padding.
        let textTopPadding = AppTheme.Space.xs
        let heroSpacer = max(0, textTop - scrollTop - textTopPadding)
        let readingBottomPad = AppTheme.RosaryFlow.readingBottomPadding
        // Floating action top sits pill height + its bottom padding above the scroll bottom.
        let plateActionClearance = AppTheme.Component.pillHeight + AppTheme.Space.lg
        let plateTextToActionGap = AppTheme.Component.prayerReadingContentToActionGap
        let plateBottomAnchorHeight: CGFloat = 1
        let plateEndSpacer = max(
            0,
            plateActionClearance + plateTextToActionGap
                - (AppTheme.Space.lg + readingBottomPad) - plateBottomAnchorHeight
        )

        return ZStack(alignment: .top) {
            // A quiet top strip gives the artwork room below the Dynamic Island.
            VStack(spacing: 0) {
                palette.prayBg
                    .frame(height: AppTheme.rosaryMysteryArtworkTopInset)
                plateHeroImage(
                    mystery: mystery,
                    artHeight: max(1, heroHeight - AppTheme.rosaryMysteryArtworkTopInset),
                    readingHeight: max(1, heroHeight - AppTheme.rosaryMysteryArtworkTopInset),
                    visibleTop: max(0, scrollTop - AppTheme.rosaryMysteryArtworkTopInset),
                    progress: progress
                )
            }
            .frame(height: heroHeight)
            .frame(maxWidth: .infinity, alignment: .top)
            // Decorative: the heading below names the mystery.
            .accessibilityHidden(true)
            // Geometry starts below the status bar. Position the fixed artwork
            // canvas at the physical screen top without moving the controls.
            .offset(y: -scrollTop)
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
                        .padding(.top, textTopPadding)
                        .padding(.bottom, AppTheme.Space.lg + readingBottomPad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .contain)

                        // Room so the last line (Fruit) ends exactly `plateTextToActionGap`
                        // above the floating action when scrolled to the bottom.
                        Color.clear
                            .frame(height: plateEndSpacer)
                            .accessibilityHidden(true)
                        Color.clear
                            .frame(height: plateBottomAnchorHeight)
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
                    // The plate scroll view runs under the status bar and home indicator,
                    // so its offset rests at -contentInsets.top. Measure from that rest
                    // position so 0 is the top and maxOffset is the real bottom.
                    PlateScrollMetrics(geometry)
                } action: { _, newValue in
                    if newValue.contentHeight > 1 {
                        plateContentHeight = newValue.contentHeight
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
            // Once the mystery text scrolls up under it, the chrome gets the same frosted
            // bar as long prayers so the header never sits on top of reading text.
            plateTopChrome(step, textUnderChrome: plateScrollY > heroSpacer + textTopPadding - chromeH)
        }
        .background(palette.prayBg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The hero clips its own overscan; this container must allow artwork
        // to extend above its safe-area bounds into the status-bar region.
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
    private func plateTopChrome(_ step: RosaryStep, textUnderChrome: Bool) -> some View {
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
        .guideChromeBar(visible: textUnderChrome, prayerBackground: true)
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

    private func plateHeroImage(
        mystery: Mystery,
        artHeight: CGFloat,
        readingHeight: CGFloat,
        visibleTop: CGFloat,
        progress: CGFloat
    ) -> some View {
        let washOverlay = progress * 0.75
        let heroOpacity = 1.0 - progress * 0.50
        // No bottom fade: the artwork meets the mystery text with its own edge.
        // Scrolling only changes the darkening.
        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: artHeight)
            .overlay {
                PlateArtView(mystery: mystery, wide: true)
                    // Top anchoring keeps the raised hand clear of the progress track.
                    .scaleEffect(mystery.set == .glorious && mystery.number == 1 ? AppTheme.RosaryFlow.resurrectionArtworkScale : 1.0, anchor: .top)
                    .opacity(heroOpacity)
                    .frame(maxWidth: .infinity)
                    .frame(height: artHeight)
                    .clipped()
            }
            .overlay {
                // Scroll darkening. Light washes to white; dark uses black.
                palette.selectedControlFill
                    .opacity(washOverlay)
            }
            // Contain aspect-fill overscan to the hero canvas — not to the chrome boundary.
            .clipped()
            .allowsHitTesting(false)
    }

    private var plateCanScrollFurther: Bool {
        plateContentHeight > plateViewportHeight + ScrollMorph.minimumOffset && !plateActionLockedToNext
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
        .padding(.top, AppTheme.Space.sm)
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
                            BilingualStack(
                                text: step.body,
                                language: language,
                                font: AppTheme.TypeRole.prayerText(scale: settings.textSize.scale),
                                pointSize: AppTheme.TypeRole.prayerLineHeightReference(scale: settings.textSize.scale)
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
                        if prayerUsesScrollTemplate, shouldShowBeads(step), let bead = step.bead {
                            // Same position as on short prayers: right after the text.
                            beadShelf(bead)
                        }
                        if !pinTop { Spacer(minLength: 0) }
                        if prayerUsesScrollTemplate {
                            Color.clear.frame(height: prayerScrollTail(step))
                            Color.clear.frame(height: 1).id(PrayerScrollAnchor.bottom)
                        }
                    }
                    .frame(minHeight: pinTop ? nil : scrollGeo.size.height, alignment: .top)
                    .frame(maxWidth: .infinity)
                }
                .scrollPosition($prayerScrollPosition)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 1
                } action: { _, scrolled in
                    topBarScrolled = scrolled
                }
                .onScrollGeometryChange(for: PlateScrollMetrics.self) { geometry in
                    PlateScrollMetrics(geometry)
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

    /// Clear Next and the language selector, leaving the shared prayer reading gap,
    /// plus whatever it takes to leave a real scroll to the bottom.
    /// A prayer that only just overflows (the Closing Prayer at common text sizes) otherwise
    /// had a few points of scroll or none, below the 8pt `ScrollMorph` needs, so scrolling by
    /// hand could never reach the expand line; only a tap expanded it.
    private func prayerScrollTail(_ step: RosaryStep) -> CGFloat {
        let showsBeads = shouldShowBeads(step) && step.bead != nil
        let base = AppTheme.Component.readingScrollTail(
            actionClearance: AppTheme.Component.prayerReadingActionClearance,
            contentBottomPadding: showsBeads ? AppTheme.Space.sm : AppTheme.Space.lg,
            anchorHeight: 1
        )
        guard prayerViewportHeight > 1, prayerTextHeight > 1 else { return base }
        let beads = showsBeads ? prayerBeadShelfHeight : 0
        let range = prayerTextHeight + beads + base + 1 - prayerViewportHeight
        return base + max(0, ScrollMorph.minimumRange - range)
    }

    /// Rosary bead map under the prayer text (same spacing in both templates).
    private func beadShelf(_ bead: BeadLocus) -> some View {
        RosaryBeadMapView(locus: bead, animationPaused: beadTimelinePaused)
            .padding(.horizontal, AppTheme.Space.md)
            .padding(.top, AppTheme.Space.xl)
            .padding(.bottom, AppTheme.Space.sm)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                if height > 1 { prayerBeadShelfHeight = height }
            }
    }

    /// Outer ~15% of the pray column steps back / forward (was 25%; narrowed so body stays tappable).
    private var edgeTapZones: some View { edgeTapZones(width: nil) }

    /// `width` nil = 15% of the screen per side (standard prayers).
    private func edgeTapZones(width: CGFloat?) -> some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: width ?? geo.size.width * 0.15)
                    .onTapGesture { retreat() }

                Spacer(minLength: 0)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: width ?? geo.size.width * 0.15)
                    .onTapGesture { advance() }
            }
        }
        .allowsHitTesting(true)
        // Tap shortcuts only; VoiceOver uses the visible Previous and Next buttons.
        .accessibilityHidden(true)
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
                if index > 0 || showingIntentionStep {
                    roundControl(system: "chevron.left") { retreat() }
                        .accessibilityLabel("Previous prayer")
                }
                Spacer()
                roundControl(system: "xmark") { closePrayerFlow() }
                    .accessibilityLabel("Close")
            }
            progressNowLabel(step)
                // Accessibility sizes: two lines at word boundaries instead of truncating.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 52)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step.mystery.map { "\(step.stage.spokenName), \($0.title.english)" } ?? step.progressLabel)
                .accessibilityAddTraits(.isStaticText)
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.xs)
        .padding(.bottom, AppTheme.Space.xs)
    }

    /// Web `#pnow`: roman + padded middot + mystery title (`.sep` is `padding: 0 .5em`).
    @ViewBuilder
    private func progressNowLabel(_ step: RosaryStep) -> some View {
        let font = AppTheme.TypeRole.label(weight: .medium)
        if dynamicTypeSize.isAccessibilitySize {
            let text = step.mystery.map { mystery in
                [.first, .second, .third, .fourth, .fifth].contains(step.stage)
                    ? "\(OrdinalWord.roman(mystery.number)) · \(mystery.title.english)"
                    : step.progressLabel
            } ?? step.progressLabel
            WordSafeText(text, font: AppTheme.TypeRole.captionUIFont(weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.ink)
        } else if let mystery = step.mystery,
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
            // Eyebrow, count and title read as one heading:
            // "Hail Mary 3 of 10, first decade" / "First Joyful Mystery, The Annunciation".
            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                if step.isPlate, let mystery = step.mystery {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.md) {
                        Text(OrdinalWord.roman(mystery.number))
                            .font(AppTheme.TypeRole.body(weight: .medium))
                            .foregroundStyle(palette.textSecondary)
                        Text(mystery.set.shortName)
                            .font(AppTheme.TypeRole.caption(weight: .medium))
                            .tracking(AppTheme.RosaryFlow.eyebrowTracking)
                            .textCase(.uppercase)
                            .foregroundStyle(palette.faint)
                    }
                    // Locus VStack spacing is 6; +4 → 10pt under the mystery eyebrow.
                    .padding(.bottom, AppTheme.Space.xs)
                }
                // Web `.locus .k`: "1 of 10" above Hail Mary on decade beads.
                if step.kind == .hailMary,
                   step.decadeNumber != nil,
                   let n = step.hailMaryNumber {
                    Text("\(n) of 10")
                        .font(AppTheme.TypeRole.label(weight: .medium))
                        .foregroundStyle(palette.faint)
                        // VStack spacing is 6; +4 → 10pt under "1 of 10".
                        .padding(.bottom, AppTheme.Space.xs)
                }
                Text(step.title.primary(for: language))
                    .font(AppTheme.TypeRole.modalTitle)
                    .foregroundStyle(palette.ink)
                    .tracking(-0.2)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(step.spokenProgress)
            .accessibilityAddTraits(.isHeader)
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
        .padding(.bottom, step.isPlate || step.kind == .signOfTheCross ? AppTheme.Space.lg : AppTheme.RosaryFlow.prayerTitleBodyGap)
    }




    // MARK: - Intention step

    /// First chosen intention (category, papal flag and resume all key off it).
    private var chosenIntentionId: UUID? { chosenIntentionIds.first }

    /// "Offer this Rosary for": optional multi-select between Sign of the Cross and the Creed.
    /// Same header and stage track as a prayer; no bead map.
    private func intentionStepLayer(_ step: RosaryStep) -> some View {
        VStack(spacing: 0) {
            GeometryReader { scrollGeo in
                ScrollView {
                    VStack(spacing: 0) {
                        // Space.xxl: subtitle to the first intention.
                        VStack(alignment: .leading, spacing: AppTheme.Space.xxl) {
                            VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                                Text("Offer this Rosary for")
                                    .font(AppTheme.TypeRole.modalTitle)
                                    .foregroundStyle(palette.ink)
                                    .tracking(-0.2)
                                Text("Choose up to \(PrayerSession.maxIntentions), or continue without one")
                                    .font(AppTheme.TypeRole.bodySmall)
                                    .foregroundStyle(palette.dim)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            IntentionMultiSelectList(
                                selectedIds: intentionSelection,
                                mysterySet: intentionSheetMysterySet,
                                showsAddButton: false,
                                addRequests: intentionAddRequests
                            )
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        .padding(.top, prayerTitleTopPadding)
                        .padding(.bottom, AppTheme.Space.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            if height > 1 { intentionListHeight = height }
                        }

                        // Room under the list so the last row clears the floating action.
                        Color.clear.frame(height: intentionScrollTail)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollPosition($intentionScrollPosition)
                // Same edge zones as prayer steps, narrowed to the side gutters so
                // they never cover the intention rows.
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 1
                } action: { _, scrolled in
                    topBarScrolled = scrolled
                }
                .onScrollGeometryChange(for: PlateScrollMetrics.self) { geometry in
                    PlateScrollMetrics(geometry)
                } action: { _, newValue in
                    if newValue.contentHeight > 1 { intentionContentHeight = newValue.contentHeight }
                    if newValue.viewportHeight > 1 { intentionViewportHeight = newValue.viewportHeight }
                    let y = max(0, newValue.offsetY)
                    if abs(y - intentionScrollY) > 0.5 { intentionLastDrag = Date() }
                    intentionScrollY = y
                    let maxOffset = max(0, intentionContentHeight - intentionViewportHeight)
                    // Same rule as prayer Next / Saint Michael Done.
                    let next = ScrollMorph.resolve(
                        locked: intentionActionLocked,
                        armed: intentionArrowArmed,
                        y: y,
                        maxOffset: maxOffset
                    )
                    if next.locked != intentionActionLocked { intentionActionLocked = next.locked }
                    if next.armed != intentionArrowArmed { intentionArrowArmed = next.armed }
                }
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting {
                        intentionArrowArmed = false
                        intentionLastDrag = Date()
                    }
                }
                .overlay { edgeTapZones(width: AppTheme.gutter) }
                .onAppear {
                    if scrollGeo.size.height > 1 { intentionViewportHeight = scrollGeo.size.height }
                }
                .overlay(alignment: .bottom) {
                    // Stacked: Add intention in the grey tertiary pill (as Complete decade),
                    // Continue below it in the secondary pill (as Next).
                    VStack(spacing: AppTheme.Space.md) {
                        PillButton(title: "Add intention", filled: false, tertiary: true) {
                            intentionAddRequests += 1
                        }
                        .accessibilityLabel("Add an intention")

                        PillButton(title: "Continue", filled: false) { advance() }
                    }
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.top, AppTheme.Space.md)
                    .padding(.bottom, AppTheme.Space.lg)
                }
            }
            .onAppear { resetIntentionScrollState() }
        }
        .safeAreaBar(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                header(step)
                SevenStageTrack(current: step.stage) { jump(to: $0) }
            }
            .guideChromeBar(visible: topBarScrolled, prayerBackground: true)
        }
        .scrollEdgeEffectHidden(true, for: .top)
    }

    /// Footer room (button + its padding) the list must leave clear.
    private var intentionFooterRoom: CGFloat {
        AppTheme.Component.pillHeight * 2 + AppTheme.Space.md * 2 + AppTheme.Space.lg
    }

    private var intentionOverflows: Bool {
        intentionViewportHeight > 1 && intentionListHeight > intentionViewportHeight - intentionFooterRoom
    }

    /// Scrolling intentions leave the shared reading gap above Continue;
    /// short lists only reserve the existing footer room.
    private var intentionScrollTail: CGFloat {
        guard intentionOverflows else { return intentionFooterRoom }
        let base = AppTheme.Component.readingScrollTail(
            actionClearance: AppTheme.Component.pillHeight * 2 + AppTheme.Space.md + AppTheme.Space.lg,
            contentBottomPadding: AppTheme.Space.lg
        )
        let range = intentionListHeight + base - intentionViewportHeight
        return base + max(0, ScrollMorph.minimumRange - range)
    }

    private func resetIntentionScrollState() {
        intentionActionLocked = false
        intentionArrowArmed = false
        intentionScrollY = 0
        intentionLastDrag = .distantPast
        intentionScrollPosition = ScrollPosition(edge: .top)
    }

    private var intentionSelection: Binding<[UUID]> {
        Binding(
            get: { chosenIntentionIds },
            set: { ids in
                let limited = Array(ids.prefix(PrayerSession.maxIntentions))
                chosenIntentionIds = limited
                chosenIntentionTitles = limited.map { offer.intention(id: $0)?.title ?? "" }
                persistChosenIntentions()
            }
        )
    }

    private func persistChosenIntentions() {
        let first = chosenIntentionId.flatMap { offer.intention(id: $0) }
        sessionStore.updateIntentions(
            ids: chosenIntentionIds,
            titles: chosenIntentionTitles,
            category: first?.category,
            sourceId: first?.sourceId
        )
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
        VStack(alignment: .leading, spacing: step.isPlate ? AppTheme.Space.sm : AppTheme.RosaryFlow.announcementSpacing) {
            // Scripture can be switched off in Rosary settings.
            if !step.body.english.isEmpty {
            BilingualStack(
                text: step.body,
                language: .english,
                font: AppTheme.TypeRole.prayerText(scale: settings.textSize.scale),
                pointSize: AppTheme.TypeRole.prayerLineHeightReference(scale: settings.textSize.scale)
            )
            }
            if let ref = step.scriptureReference {
                Text(ref)
                    .font(AppTheme.TypeRole.scriptureReference(isMystery: step.isPlate))
                    .foregroundStyle(palette.faint)
            }
            if let fruit = step.subtitle {
                VStack(alignment: .leading, spacing: step.isPlate ? AppTheme.Space.sm : AppTheme.Space.md) {
                    Hairline()
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                        Text("Fruit")
                            .font(AppTheme.TypeRole.prayerFruitLabel(isMystery: step.isPlate))
                            .tracking(step.isPlate ? AppTheme.RosaryFlow.fruitTracking : 0)
                            .foregroundStyle(palette.textSecondary)
                        Text(fruit.primary(for: .english))
                            .font(AppTheme.TypeRole.bodySmall(weight: .medium))
                            .foregroundStyle(palette.ink)
                    }
                }
                .padding(.top, step.isPlate ? AppTheme.Space.sm : AppTheme.Space.lg)
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
                languageChipsSlot
            }
        }
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.md)
        // Solid foot in document flow (web phone). No upward fade — that covered the rosary.
        .background(palette.prayBg)
    }

    /// Reserves the toggle's place in whichever footer is showing. The real
    /// control is drawn once by `stableLanguageChips()`, so switching between
    /// the short-prayer footer and the long-prayer floating chrome (e.g. when
    /// Both makes the text long) does not recreate the segmented control and
    /// kill its sliding animation.
    private var languageChipsSlot: some View {
        languageChips
            .hidden()
            .anchorPreference(key: LanguageChipsAnchorKey.self, value: .bounds) { $0 }
    }

    private func stableLanguageChips(_ anchor: Anchor<CGRect>?) -> some View {
        GeometryReader { proxy in
            let rect = anchor.map { proxy[$0] } ?? .zero
            languageChips
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
                .opacity(anchor == nil ? 0 : 1)
                .allowsHitTesting(anchor != nil)
                .accessibilityHidden(anchor == nil || current?.isPlate == true)
        }
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
        language != .bilingual && !step.isPlate && !step.isFinis && step.kind != .completion
    }

    // MARK: - Finis

    private var finisLayer: some View {
        CompletionView(
            mysterySet: launch.mysterySet,
            quote: completionQuote ?? QuoteCatalog.quote(),
            onDone: { finishRosary() },
            // Saint Michael switched on in Rosary settings is already a step; no extra offer.
            onMichael: activeConfig.saintMichael ? nil : {
                // Rosary is already marked complete on entering finis; Michael is optional continuation.
                showingMichael = true
                HapticService.play(.medium, enabled: settings.hapticsEnabled)
            }
        )
        // The Rosary is recorded as complete on reaching this screen, so the count includes it.
        // Asked only once the screen has settled, never mid-prayer or over Saint Michael.
        .task {
            await ReviewPrompter.requestAfterCompletion(
                completedRosaries: sessionStore.completedSessions.count,
                isStillSettled: { !showingMichael }
            )
        }
    }

    private var michaelCanScrollFurther: Bool {
        // Same threshold as `ScrollMorph.resolve`, so a circle is only shown when scrolling
        // by hand can expand it.
        michaelContentHeight > michaelViewportHeight + ScrollMorph.minimumOffset && !michaelActionLocked
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

    /// Page-local language, like the Prayers section. Starts from the prayer
    /// language each time the page opens and never writes the setting.
    private var michaelLanguageSelection: Binding<PrayerLanguage> {
        Binding(
            get: { michaelLanguage ?? language },
            set: { newValue in
                guard newValue != (michaelLanguage ?? language) else { return }
                michaelLanguage = newValue
            }
        )
    }

    private var michaelLayer: some View {
        VStack(spacing: 0) {
            michaelHeader

            VStack(spacing: 0) {
                    GeometryReader { scrollGeo in
                        ScrollView {
                            VStack(spacing: 0) {
                                // The same block, widths and spacing as Saint Michael
                                // in the Prayers section.
                                PrayerReaderBlock(
                                    prayer: PrayerCatalog.saintMichael,
                                    language: michaelLanguageSelection
                                )
                                .frame(maxWidth: 560, alignment: .leading)
                                .padding(.horizontal, AppTheme.gutter)
                                .frame(maxWidth: .infinity)
                                .padding(.top, AppTheme.Space.lg)
                                .padding(.bottom, AppTheme.Space.lg)
                                Spacer(minLength: 0)

                                // Same content-to-action gap as every long prayer.
                                Color.clear
                                    .frame(height: AppTheme.Component.prayerReadingScrollTail)
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
                        PlateScrollMetrics(geometry)
                    } action: { _, newValue in
                        // The scroll view's own content size is authoritative and may
                        // shrink (shorter language, smaller text).
                        if newValue.contentHeight > 1 {
                            michaelContentHeight = newValue.contentHeight
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
                        .onChange(of: michaelLanguage) { resetMichaelScrollState() }
                        .onChange(of: settings.textSize) { resetMichaelScrollState() }
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
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        .padding(.bottom, AppTheme.Space.lg)
                        .padding(.top, AppTheme.Space.md)
                    }
                }
        }
        .background(palette.bg.ignoresSafeArea())
        // Opening Saint Michael again starts as a circle at the top, in the prayer language.
        .onAppear {
            michaelLanguage = nil
            resetMichaelScrollState()
        }
    }

    /// New content (appear, language, text size): re-measure from scratch so the
    /// height can shrink, and start again at the top as a circle.
    private func resetMichaelScrollState() {
        michaelActionLocked = false
        michaelArrowArmed = false
        michaelScrollY = 0
        michaelContentHeight = 0
        michaelLastDrag = .distantPast
        michaelScrollPosition = ScrollPosition(edge: .top)
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
        GuideScrollActionButton(
            showScroll: showScroll,
            title: expandedTitle,
            scrollLabel: scrollLabel,
            onScroll: onScroll,
            onAdvance: onAdvance
        )
    }

    private var prayerCanScrollFurther: Bool {
        prayerUsesScrollTemplate && !prayerActionLocked
    }

    /// Long prayers only. Short prayers keep the in-flow footer.
    /// Compares the text to the room it would have with the footer showing.
    private func updatePrayerScrollTemplate(viewport: CGFloat) {
        guard prayerTextHeight > 1, viewport > 1 else { return }
        // In the scroll template the footer and bead shelf are not below the column, so the
        // column is taller; take them off again to compare like with like (no flip-flop).
        let beadsInColumn = current.map { shouldShowBeads($0) && $0.bead != nil } ?? false
        let beadRoom = beadsInColumn ? prayerBeadShelfHeight : 0
        let roomWithFooter = prayerUsesScrollTemplate ? viewport - prayerFooterHeight - beadRoom : viewport
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
        topBarScrolled = false
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
        let contentH = prayerContentHeight > 1 ? prayerContentHeight : prayerTextHeight + AppTheme.Component.prayerReadingScrollTail
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
            languageChipsSlot
        }
        .padding(.horizontal, AppTheme.gutter)
        .padding(.bottom, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.md)
    }

    // MARK: - Navigation

    private func markRosaryCompletedIfNeeded() {
        checkpointActivePrayerTime()
        // Record completion when the ceremonial screen appears so St Michael
        // continuation cannot undo or re-trigger tracking.
        if !didRecordCarry, !chosenIntentionIds.isEmpty {
            chosenIntentionIds.forEach { offer.recordCarry(id: $0) }
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
        stopPrayerAutosave()
        dismiss()
    }

    private func closePrayerFlow() {
        isClosingPrayerFlow = true
        stopPrayerAutosave()
        saveActivePrayerTime(continueTiming: false)
        dismiss()
    }

    private func startActivePrayerTimerIfNeeded() {
        guard activePrayerStart == nil else { return }
        guard didConfigure else { return }
        guard !showingCompletion else { return }
        activePrayerStart = Date()
    }

    private func checkpointActivePrayerTime() {
        saveActivePrayerTime(continueTiming: false)
    }

    private func saveActivePrayerTime(continueTiming: Bool) {
        guard let start = activePrayerStart else { return }
        let now = Date()
        activePrayerStart = continueTiming ? now : nil
        let duration = max(0, now.timeIntervalSince(start))
        if sessionStore.session != nil {
            sessionStore.addActivePrayerTime(duration + pendingActivePrayerTime)
            pendingActivePrayerTime = 0
        } else {
            pendingActivePrayerTime += duration
        }
    }

    private func startPrayerAutosave() {
        guard prayerAutosaveTask == nil else { return }
        prayerAutosaveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    saveActivePrayerTime(continueTiming: true)
                }
            }
        }
    }

    private func stopPrayerAutosave() {
        prayerAutosaveTask?.cancel()
        prayerAutosaveTask = nil
    }

    private func flushPendingActivePrayerTimeIfNeeded() {
        guard pendingActivePrayerTime > 0, sessionStore.session != nil else { return }
        sessionStore.addActivePrayerTime(pendingActivePrayerTime)
        pendingActivePrayerTime = 0
    }

    private func configure() {
        switch launch {
        case .fresh(let set, let intentionId, _):
            freshSetPending = nil
            activeConfig = settings.currentRosaryConfig
            steps = RosarySequenceBuilder.build(set: set, config: activeConfig)
            index = launch.startIndex(in: steps)
            // A launch from an intention pre-selects it on the intention step.
            let resolvedId = intentionId.flatMap { offer.intention(id: $0) != nil ? $0 : nil }
            chosenIntentionIds = resolvedId.map { [$0] } ?? []
            chosenIntentionTitles = chosenIntentionIds.map { offer.intention(id: $0)?.title ?? "" }
            showingIntentionStep = false
            startSession(set: set)
            sessionStore.updateStep(index)
            didRecordCarry = false
            completionQuote = nil
            beadTimelinePaused = false
            finishBlack = 0
            showingCompletion = false
            pendingActivePrayerTime = 0
        case .resume(let session):
            freshSetPending = nil
            // Rebuild with the saved config, then carry the position into current Settings.
            let saved = RosarySequenceBuilder.build(set: session.mysterySet, config: session.rosaryConfig)
            let savedIndex = min(session.stepIndex, max(saved.count - 1, 0))
            activeConfig = settings.currentRosaryConfig
            steps = RosarySequenceBuilder.build(set: session.mysterySet, config: activeConfig)
            index = RosarySequenceBuilder.remap(index: savedIndex, from: saved, to: steps)
            if activeConfig != session.rosaryConfig {
                recordDecadeIfRemoved(saved.indices.contains(savedIndex) ? saved[savedIndex] : nil)
                sessionStore.updateRosaryConfig(activeConfig)
                sessionStore.updateStep(index)
            }
            if var current = sessionStore.session {
                current.language = settings.language
                if current.intentionSourceId == nil, let id = current.intentionId {
                    current.intentionSourceId = offer.intention(id: id)?.sourceId
                }
                if current.intentionCategory == nil, let id = current.intentionId {
                    current.intentionCategory = offer.intention(id: id)?.category
                }
                sessionStore.session = current
            }
            chosenIntentionIds = session.intentionIds
            chosenIntentionTitles = session.intentionIds.enumerated().map { offset, id in
                session.intentionTitles.indices.contains(offset)
                    ? session.intentionTitles[offset]
                    : offer.intention(id: id)?.title ?? ""
            }
            showingIntentionStep = false
            didRecordCarry = false
            completionQuote = nil
            beadTimelinePaused = false
            finishBlack = 0
            showingCompletion = false
            pendingActivePrayerTime = 0
        }
        playHaptic()
        startActivePrayerTimerIfNeeded()
    }

    private func advance() {
        // A double tap on Next / Continue (or a tap during the expand animation)
        // moves one step, not two.
        let now = Date()
        guard now.timeIntervalSince(lastAdvanceAt) > 0.3 else { return }
        lastAdvanceAt = now
        if showingIntentionStep {
            // Intention is optional: Continue always moves on to the next prayer.
            move(to: index + 1)
            return
        }
        if current?.kind == .signOfTheCross, current?.stage == .opening, activeConfig.intentionsStep, index < steps.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                showingIntentionStep = true
            }
            playHaptic()
            return
        }

        if current?.isFinis == true {
            finishRosary()
            return
        }

        if current?.isLastPrayer == true {
            // With the closing group off, the last prayer can also close decade five.
            recordCompletedDecadeIfNeeded()
            showCompletionScreen()
            return
        }

        guard index < steps.count - 1 else {
            finishRosary()
            return
        }
        recordCompletedDecadeIfNeeded()
        move(to: index + 1)
    }

    /// Rosary settings changed while praying: rebuild from here on, keeping the place.
    private func applyLiveConfig(_ config: RosaryConfig) {
        guard didConfigure, config != activeConfig, !steps.isEmpty,
              !showingCompletion, !showingMichael, current?.isFinis != true else { return }
        let rebuilt = RosarySequenceBuilder.build(set: launch.mysterySet, config: config)
        let newIndex = RosarySequenceBuilder.remap(index: index, from: steps, to: rebuilt)
        // Session not started yet (replace prompt open): it is created later with activeConfig.
        let ownsSession = freshSetPending == nil
        if ownsSession { recordDecadeIfRemoved(current, in: rebuilt) }
        activeConfig = config
        steps = rebuilt
        index = newIndex
        if ownsSession {
            sessionStore.updateRosaryConfig(config)
            sessionStore.updateStep(newIndex)
        }
    }

    /// A removed step that closed its decade (e.g. Fatima switched off while on it) still counts it.
    private func recordDecadeIfRemoved(_ step: RosaryStep?, in rebuilt: [RosaryStep]? = nil) {
        guard let step, step.closesDecade, let decade = step.decadeNumber else { return }
        let target = rebuilt ?? steps
        guard !target.contains(where: { $0.identity == step.identity }) else { return }
        sessionStore.recordCompletedDecadeIfNeeded(decade)
    }

    private func recordCompletedDecadeIfNeeded() {
        guard current?.closesDecade == true, let decadeNumber = current?.decadeNumber else { return }
        checkpointActivePrayerTime()
        sessionStore.recordCompletedDecadeIfNeeded(decadeNumber)
        startActivePrayerTimerIfNeeded()
    }

    private func showCompletionScreen() {
        // Do not touch @State or UserDefaults in this button action. Device
        // scene-update logs (0x8BADF00D) show the main thread still inside
        // that update 10s later — ButtonBehavior, then Core Text variation
        // fonts — so the bead TimelineView stops with the rest of the UI.
        // Beads keep running until the fade below actually starts.
        DispatchQueue.main.async {
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
        if showingIntentionStep {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                showingIntentionStep = false
            }
            // Same haptic as every other step change.
            playHaptic()
            return
        }
        guard index > 0 else { return }
        let previous = index - 1
        move(to: previous)
        // Stepping back from the Creed lands on the intention step, not past it.
        if activeConfig.intentionsStep, steps.indices.contains(previous),
           steps[previous].kind == .signOfTheCross, steps[previous].stage == .opening {
            showingIntentionStep = true
        }
    }

    private func startSession(set: MysterySetKind) {
        let first = chosenIntentionId.flatMap { offer.intention(id: $0) }
        sessionStore.start(
            set: set,
            language: settings.language,
            intentionIds: chosenIntentionIds,
            intentionTitles: chosenIntentionTitles,
            intentionCategory: first?.category,
            intentionSourceId: first?.sourceId,
            rosaryConfig: activeConfig
        )
    }

    private func move(to next: Int) {
        checkpointActivePrayerTime()
        if let set = freshSetPending, next > 0 {
            startSession(set: set)
            flushPendingActivePrayerTimeIfNeeded()
            freshSetPending = nil
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            showingIntentionStep = false
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

    /// One reading for every scroll-aware CTA: offset from the content top, clamped
    /// to the real scroll range (see `ScrollMorph.position`).
    init(_ geometry: ScrollGeometry) {
        let position = ScrollMorph.position(geometry)
        offsetY = position.y
        contentHeight = geometry.contentSize.height
        viewportHeight = geometry.containerSize.height
    }
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
    /// Every scrolling prayer leaves at least this much to scroll, so reaching the bottom
    /// by hand always crosses the expand line.
    static let minimumRange: CGFloat = 56
    /// Below this there is no scroll to speak of; `resolve` leaves the state alone.
    static let minimumOffset: CGFloat = 8

    static func expandGap(_ maxOffset: CGFloat) -> CGFloat {
        min(36, maxOffset * 0.2)
    }

    static func collapseGap(_ maxOffset: CGFloat) -> CGFloat {
        // Half the range, at most 112pt. Always above the expand line.
        min(112, maxOffset * 0.5)
    }

    /// New (locked, armed) after a scroll position update.
    /// `armed` is a tap's own scroll on its way down. It clears on arrival.
    /// Scroll position measured from the top of the content.
    /// `contentOffset` rests at `-insetTop` under a top bar, and `containerSize`
    /// already excludes the insets, so the range is `content - container`.
    /// `y` is clamped to that range: rubber-band overscroll at either end reads
    /// as the end itself, so it can't flicker the CTA.
    static func position(offsetY: CGFloat, insetTop: CGFloat, contentHeight: CGFloat, containerHeight: CGFloat) -> (y: CGFloat, maxOffset: CGFloat) {
        let maxOffset = max(0, contentHeight - containerHeight)
        let y = min(maxOffset, max(0, offsetY + insetTop))
        return (y, maxOffset)
    }

    static func position(_ geometry: ScrollGeometry) -> (y: CGFloat, maxOffset: CGFloat) {
        position(
            offsetY: geometry.contentOffset.y,
            insetTop: geometry.contentInsets.top,
            contentHeight: geometry.contentSize.height,
            containerHeight: geometry.containerSize.height
        )
    }

    static func resolve(locked: Bool, armed: Bool, y: CGFloat, maxOffset: CGFloat) -> (locked: Bool, armed: Bool) {
        guard maxOffset > minimumOffset else { return (locked, false) }
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

// MARK: - Mystery plate scroll tracking

