import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
    /// Measured header + progress track height (safe-area content, not status bar).
    @State private var plateChromeHeight: CGFloat = 96
    @State private var chosenIntentionId: UUID?
    @State private var chosenIntentionTitle: String = ""
    @State private var chosenIntentionNote: String = ""
    @State private var showIntentionSheet = false
    @State private var didRecordCarry = false

    private var language: PrayerLanguage { settings.language }
    private var current: RosaryStep? {
        steps.indices.contains(index) ? steps[index] : nil
    }

    var body: some View {
        ZStack {
            palette.prayBg.ignoresSafeArea()
            if showingMichael {
                michaelLayer
            } else if let current {
                if current.isFinis {
                    finisLayer(current)
                } else {
                    prayLayer(current)
                }
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
                if showingMichael || current?.isFinis == true { return }
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                        VStack(spacing: 0) {
                            standardPrayColumn(step, scrollHeight: geo.size.height)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if showBeads, let bead = step.bead {
                                RosaryBeadMapView(locus: bead)
                                    .padding(.horizontal, AppTheme.Space.md)
                                    .padding(.top, 18)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        edgeTapZones
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    footer(step)
                }
            }
        }
        .onChange(of: index) { _, _ in
            plateScrollY = 0
            plateHintDismissed = false
            plateNearBottom = false
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
                }
                .background {
                    GeometryReader { geo in
                        Color.clear.preference(key: PlateContentHeightKey.self, value: geo.size.height)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
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
                let y = max(0, newValue.offsetY)
                plateScrollY = y
                if newValue.contentHeight > 1 {
                    plateContentHeight = max(plateContentHeight, newValue.contentHeight)
                }
                if newValue.viewportHeight > 1 {
                    plateViewportHeight = newValue.viewportHeight
                }
                if y > 18, !plateHintDismissed {
                    withAnimation(.easeOut(duration: 0.28)) {
                        plateHintDismissed = true
                    }
                }
                let contentH = max(plateContentHeight, newValue.contentHeight)
                let viewH = newValue.viewportHeight > 1 ? newValue.viewportHeight : plateViewportHeight
                let maxOffset = max(0, contentH - viewH)
                plateNearBottom = maxOffset > 8 && y >= maxOffset - 48
            }
            .task(id: mystery.id) {
                plateScrollY = 0
                plateHintDismissed = false
                plateNearBottom = false
            }
            // Edge taps below chrome so Aa / close / track keep priority.
            .overlay {
                edgeTapZones
                    .padding(.top, chromeH)
            }
            // Scripture softens into the page above the fixed Next control.
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: palette.prayBg.opacity(0), location: 0),
                        .init(color: palette.prayBg.opacity(0.85), location: 0.61),
                        .init(color: palette.prayBg, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 56)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .overlay(alignment: .bottom) {
                if plateShowsScrollHint {
                    plateScrollHint
                        .padding(.bottom, 22)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                plateNextChrome(step)
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
            (colorScheme == .light ? Color.white : Color.black)
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

    private var plateScrollHint: some View {
        Image(systemName: "chevron.down")
            .guideSymbol(size: 15, weight: .medium)
            .foregroundStyle(palette.ink.opacity(0.38))
            .modifier(PlateScrollHintBob(animate: !reduceMotion))
    }

    private func plateNextChrome(_ step: RosaryStep) -> some View {
        let nextTitle = step.nextLabel == "Continue" ? "Next" : step.nextLabel
        let near = plateNearBottom
        let lift: CGFloat = (!reduceMotion && near) ? -1.5 : 0
        let scale: CGFloat = (!reduceMotion && near) ? 1.012 : 1.0
        let opacity: Double = near ? 1.0 : 0.97

        // Fade + chevron live in the reading ZStack above; Next stays predictable here.
        return PillButton(title: nextTitle, filled: true, action: advance)
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, 8)
            .padding(.bottom, AppTheme.Space.lg)
            .scaleEffect(scale)
            .offset(y: lift)
            .opacity(opacity)
            .accessibilityLabel(nextTitle)
            .background(palette.prayBg)
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
                                font: AppTheme.sans(21 * settings.textSize.scale),
                                pointSize: 21 * settings.textSize.scale
                            )
                        }
                        .padding(.horizontal, AppTheme.gutter)
                        .padding(.top, 4)
                        .padding(.bottom, AppTheme.Space.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if !pinTop { Spacer(minLength: 0) }
                    }
                    .frame(minHeight: pinTop ? nil : scrollGeo.size.height, alignment: .top)
                    .frame(maxWidth: .infinity)
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


    private func header(_ step: RosaryStep) -> some View {
        ZStack {
            HStack {
                roundControl(label: "Aa") {
                    settings.textSize = settings.textSize.next
                }
                .accessibilityLabel("Text size")
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
        let font = AppTheme.sans(13, weight: .medium)
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
        VStack(alignment: .leading, spacing: 6) {
            if step.isPlate, let mystery = step.mystery {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(OrdinalWord.roman(mystery.number))
                        .font(AppTheme.sans(18, weight: .medium))
                        .foregroundStyle(palette.ink.opacity(0.72))
                    Text("\(OrdinalWord.english(mystery.number)) \(mystery.set.shortName)")
                        .font(AppTheme.sans(11, weight: .medium))
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
                    .font(AppTheme.sans(14, weight: .medium))
                    .foregroundStyle(palette.faint)
                    // VStack spacing is 6; +4 → 10pt under "1 of 10".
                    .padding(.bottom, 4)
            }
            // Mystery plates are English-only (no language picker).
            let titleLang: PrayerLanguage = step.isPlate ? .english : language
            Text(step.title.primary(for: titleLang))
                .font(AppTheme.sans(28, weight: .regular))
                .foregroundStyle(palette.ink)
                .tracking(-0.2)
            if !step.isPlate, language == .bilingual {
                Text(step.title.latin)
                    .font(AppTheme.sans(17))
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
        // Sign of the Cross keeps a tight gap before the quiet For: row; other steps keep web spacing.
        .padding(.bottom, step.kind == .signOfTheCross ? 8 : 22)
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

        HStack(alignment: .center, spacing: 6) {
            Text("For:")
                .font(AppTheme.sans(15))
                .foregroundStyle(palette.dim)

            if hasIntention {
                Button {
                    showIntentionSheet = true
                } label: {
                    HStack(spacing: 6) {
                        // Tiny avatar only when we have a known intention (papal portrait / glyph).
                        if let resolved {
                            IntentionIconView(
                                accent: resolved.accent,
                                emoji: resolved.displayEmoji,
                                size: 18,
                                usesPopePortrait: resolved.isPapal
                            )
                        }
                        Text(chosenIntentionTitle)
                            .font(AppTheme.sans(15, weight: .medium))
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("For: \(chosenIntentionTitle)")
                .accessibilityHint("Opens intention picker")

                Button {
                    clearChosenIntention()
                } label: {
                    Image(systemName: "xmark")
                        .guideSymbol(size: 11, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear intention")
            } else {
                Button {
                    showIntentionSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Add an intention")
                            .font(AppTheme.sans(15, weight: .medium))
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
        .padding(.bottom, AppTheme.Space.md)
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
        let base = AppTheme.sans(17)
        if let suffix = emphasizeSuffix, let range = full.range(of: suffix, options: [.caseInsensitive, .backwards]) {
            let before = String(full[..<range.lowerBound])
            let hit = String(full[range])
            (Text(before).foregroundStyle(palette.dim) + Text(hit).foregroundStyle(palette.ink).fontWeight(.medium))
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
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Fruit")
                        .font(AppTheme.sans(step.isPlate ? 12 : 14, weight: .medium))
                        .tracking(step.isPlate ? 0.8 : 0)
                        .foregroundStyle(palette.faint.opacity(step.isPlate ? 0.85 : 1))
                    Text(fruit.primary(for: .english))
                        .font(AppTheme.sans(17, weight: .medium))
                        .foregroundStyle(palette.ink)
                }
                .padding(.top, AppTheme.Space.md)
            }
        }
    }

    private func footer(_ step: RosaryStep) -> some View {
        let nextTitle = step.nextLabel == "Continue" ? "Next" : step.nextLabel
        let showCompleteDecade = step.kind == .hailMary && step.decadeNumber != nil
        return VStack(spacing: AppTheme.Space.md) {
            // Web `.pfoot`: Next | Complete decade side by side on Hail Marys.
            HStack(spacing: 10) {
                PillButton(title: nextTitle, filled: true, action: advance)
                if showCompleteDecade {
                    PillButton(title: "Complete decade", filled: false) {
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
        .padding(.top, AppTheme.Space.sm)
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
                settings.language = newValue
                if var current = sessionStore.session {
                    current.language = newValue
                    sessionStore.session = current
                }
            }
        )
    }

    private func roundControl(system: String? = nil, label: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let system {
                    Image(systemName: system)
                        .guideSymbol(size: 13, weight: .semibold)
                } else if let label {
                    Text(label)
                        .font(AppTheme.sans(13, weight: .medium))
                }
            }
            .frame(minWidth: 18, minHeight: 18)
        }
        .buttonStyle(.plain)
        .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
        .background(palette.card, in: Circle())
        .guidePressable()
        .accessibilityLabel(label ?? system ?? "Control")
    }

    private func shouldShowBeads(_ step: RosaryStep) -> Bool {
        language != .bilingual && !step.isPlate && !step.isFinis && step.kind != .completion
    }

    // MARK: - Finis

    private func finisLayer(_ step: RosaryStep) -> some View {
        GeometryReader { geo in
            let artH = min(geo.size.height * 0.62, 544)
            ZStack(alignment: .top) {
                // Web `.finis-art`: top 62% painting with veil into pray bg
                MysteryArtworkView(
                    set: launch.mysterySet,
                    mysteryNumber: 5,
                    slug: MysteryCatalog.mysteries(for: launch.mysterySet).last?.artSlug,
                    kind: .heroTall
                )
                .frame(height: artH)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: palette.prayBg.opacity(colorScheme == .light ? 0.28 : 0.38), location: 0),
                            .init(color: palette.prayBg.opacity(colorScheme == .light ? 0.88 : 0.86), location: 0.50),
                            .init(color: palette.prayBg, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                palette.prayBg
                    .ignoresSafeArea()
                    .opacity(0) // keep hit-testing clear; real fill via background below

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        roundControl(system: "xmark") {
                            finishRosary()
                        }
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, AppTheme.Space.lg)
                    .padding(.top, AppTheme.Space.xs)
                    .safeAreaPadding(.top)

                    // Web `.scroll` flex spacers: before 1.22 / after 1
                    Spacer(minLength: 12)
                        .frame(maxHeight: .infinity)
                        .layoutPriority(1)

                    VStack(spacing: 0) {
                        FinisEmblem()
                            .foregroundStyle(palette.accent.opacity(0.9))
                            .padding(.bottom, 24)

                        Text("The Rosary is complete")
                            .font(AppTheme.sans(18, weight: .medium))
                            .tracking(0.18)
                            .foregroundStyle(palette.ink.opacity(0.88))
                            .multilineTextAlignment(.center)

                        FinisOrnament()
                            .foregroundStyle(palette.accent)
                            .padding(.top, 18)
                            .padding(.bottom, 22)
                            .frame(maxWidth: 304)

                        Text("\u{201C}\(step.body.english)\u{201D}")
                            .font(AppTheme.sans(22))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.ink.opacity(0.96))
                            .frame(maxWidth: 384)

                        if let by = step.subtitle {
                            Text(by.english)
                                .font(AppTheme.sans(13, weight: .regular))
                                .tracking(0.39)
                                .foregroundStyle(palette.dim)
                                .padding(.top, 14)
                        }
                    }
                    .padding(.horizontal, AppTheme.gutter)

                    Spacer(minLength: 12)
                        .frame(maxHeight: .infinity)

                    VStack(spacing: 12) {
                        PillButton(title: "Done") {
                            finishRosary()
                        }

                        Button {
                            showingMichael = true
                            HapticService.play(.medium, enabled: settings.hapticsEnabled)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "shield")
                                    .guideSymbol(size: 15, weight: .medium)
                                Text("Saint Michael Prayer")
                                    .font(AppTheme.sans(16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .foregroundStyle(palette.ink)
                            .overlay {
                                Capsule().strokeBorder(palette.dim.opacity(0.45), lineWidth: 1)
                            }
                        }
                        .guidePressable()
                        .frame(maxWidth: 320)
                    }
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.gutter)
                    .padding(.bottom, AppTheme.Space.xl)
                    .safeAreaPadding(.bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(palette.prayBg.ignoresSafeArea())
        }
    }

    private var michaelLayer: some View {
        VStack(spacing: 0) {
            HStack {
                roundControl(system: "xmark") {
                    finishRosary()
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .padding(.top, AppTheme.Space.sm)
            Spacer()
            VStack(spacing: AppTheme.Space.lg) {
                Text(PrayerCatalog.saintMichael.title.primary(for: language))
                    .font(AppTheme.sans(26, weight: .regular))
                    .multilineTextAlignment(.center)
                BilingualStack(
                    text: PrayerCatalog.saintMichael.text,
                    language: language,
                    font: AppTheme.sans(21 * settings.textSize.scale),
                    pointSize: 21 * settings.textSize.scale,
                    alignment: .center
                )
            }
            .padding(.horizontal, AppTheme.gutter)
            Spacer()
            VStack(spacing: AppTheme.Space.md) {
                languageChips
                PillButton(title: "Amen") {
                    finishRosary()
                }
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, AppTheme.Space.xl)
        }
        .background(palette.prayBg.ignoresSafeArea())
    }

    // MARK: - Navigation

    private func finishRosary() {
        if !didRecordCarry, let id = chosenIntentionId {
            offer.recordCarry(id: id)
            didRecordCarry = true
        }
        sessionStore.complete()
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
        case .resume(let session):
            freshSetPending = nil
            steps = RosarySequenceBuilder.build(set: session.mysterySet)
            index = min(session.stepIndex, max(steps.count - 1, 0))
            settings.language = session.language
            chosenIntentionId = session.intentionId
            let title = session.intentionTitle
                ?? session.intentionId.flatMap { offer.intention(id: $0)?.title }
                ?? ""
            chosenIntentionTitle = title
            chosenIntentionNote = session.intentionId.flatMap { offer.intention(id: $0)?.note } ?? ""
            didRecordCarry = false
        }
        playHaptic()
    }

    private func advance() {
        guard index < steps.count - 1 else {
            finishRosary()
            return
        }
        move(to: index + 1)
    }

    private func retreat() {
        guard index > 0 else { return }
        move(to: index - 1)
    }

    private func move(to next: Int) {
        if let set = freshSetPending, next > 0 {
            sessionStore.start(set: set, language: settings.language, intentionId: chosenIntentionId, intentionTitle: chosenIntentionTitle.isEmpty ? nil : chosenIntentionTitle)
            freshSetPending = nil
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

// MARK: - Finis chrome (web emblem + ornament)

private struct FinisEmblem: View {
    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 60
            let sy = size.height / 70
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }

            // 22 dots on a ring
            let n = 22
            let r: CGFloat = 17
            let cx: CGFloat = 30
            let cy: CGFloat = 26
            for i in 0..<n {
                let a = (CGFloat(i) / CGFloat(n)) * 2 * .pi - .pi / 2
                let c = p(cx + cos(a) * r, cy + sin(a) * r)
                let rad = 1.5 * sx
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .foreground)
            }

            // center star (approx)
            var star = Path()
            let sc = p(30, 26)
            let outer: CGFloat = 5.4 * sx
            let inner: CGFloat = 2.2 * sx
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 - .pi / 2
                let rad = i.isMultiple(of: 2) ? outer : inner
                let pt = CGPoint(x: sc.x + cos(a) * rad, y: sc.y + sin(a) * rad)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .foreground)

            // two descending dots
            for y in [46.5, 52.0] as [CGFloat] {
                let c = p(30, y)
                let rad = 1.5 * sx
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .foreground)
            }

            // cross
            var cross = Path()
            cross.move(to: p(30, 56)); cross.addLine(to: p(30, 67))
            cross.move(to: p(25.5, 60)); cross.addLine(to: p(34.5, 60))
            ctx.stroke(cross, with: .foreground, style: StrokeStyle(lineWidth: 1.6 * sx, lineCap: .round))
        }
        .frame(width: 68, height: 79)
        .accessibilityHidden(true)
    }
}

private struct FinisOrnament: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(.primary.opacity(0.32))
                .frame(height: 1)
            FinisStar()
                .frame(width: 11, height: 11)
                .opacity(0.75)
            Rectangle()
                .fill(.primary.opacity(0.32))
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}


private struct FinisStar: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2
            let inner = outer * 0.28
            var path = Path()
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 - .pi / 2
                let rad = i.isMultiple(of: 2) ? outer : inner
                let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            ctx.fill(path, with: .foreground)
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
