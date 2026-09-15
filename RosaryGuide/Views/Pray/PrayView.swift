import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var launch: PrayLaunch

    @State private var steps: [RosaryStep] = []
    @State private var index: Int = 0
    @State private var confirmLeave = false
    @State private var confirmReplace = false
    @State private var didConfigure = false
    @State private var showingMichael = false
    @State private var freshSetPending: MysterySetKind?

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
            if case .fresh(let set) = launch, sessionStore.resumableSession != nil {
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
        .alert("Leave this rosary?", isPresented: $confirmLeave) {
            Button("Keep place") { dismiss() }
            Button("Discard", role: .destructive) {
                sessionStore.discard()
                dismiss()
            }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Your place is kept for the rest of today.")
        }
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
    }

    // MARK: - Main pray column

    private func prayLayer(_ step: RosaryStep) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header(step)
                SevenStageTrack(current: step.stage) { jump(to: $0) }
                if step.isPlate, let mystery = step.mystery {
                    PlateArtView(mystery: mystery, wide: true)
                        .frame(maxWidth: .infinity)
                        .frame(height: min(geo.size.width, geo.size.height * 0.42, 480))
                        .clipped()
                        .padding(.bottom, 8)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        locus(step)
                        if !step.isPlate {
                            BilingualStack(
                                text: step.body,
                                language: language,
                                font: AppTheme.serif(21 * settings.textSize.scale)
                            )
                        } else {
                            announceBody(step)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
                }
                if shouldShowBeads(step), let bead = step.bead {
                    RosaryBeadMapView(locus: bead)
                        .padding(.horizontal, 12)
                }
                footer(step)
            }
        }
    }

    private func header(_ step: RosaryStep) -> some View {
        ZStack {
            HStack {
                roundControl(system: "xmark") { confirmLeave = true }
                Spacer()
                roundControl(label: "Aa") {
                    settings.textSize = settings.textSize.next
                }
            }
            Text(step.progressLabel)
                .font(AppTheme.sans(13, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .padding(.horizontal, 48)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
            .safeAreaPadding(.top)
    }

    private func locus(_ step: RosaryStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if step.isPlate, let mystery = step.mystery {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(OrdinalWord.roman(mystery.number))
                        .font(AppTheme.serif(22))
                    Text("\(OrdinalWord.english(mystery.number)) \(mystery.set.shortName)")
                        .font(AppTheme.sans(12, weight: .medium))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(palette.faint)
                }
            }
            Text(step.title.primary(for: language))
                .font(AppTheme.serif(step.isPlate ? 28 : 28))
                .foregroundStyle(palette.ink)
            if language == .bilingual {
                Text(step.title.latin)
                    .font(AppTheme.serif(18, italic: true))
                    .foregroundStyle(palette.dim)
            }
            if let intention = step.intention {
                Text(intention.primary(for: language))
                    .font(AppTheme.serif(17, italic: true))
                    .foregroundStyle(palette.dim)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) { Hairline() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func announceBody(_ step: RosaryStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            BilingualStack(
                text: step.body,
                language: .english,
                font: AppTheme.serif(21 * settings.textSize.scale)
            )
            if let ref = step.scriptureReference {
                Text(ref)
                    .font(AppTheme.sans(12))
                    .foregroundStyle(palette.faint)
            }
            if let fruit = step.subtitle {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Fruit")
                        .font(AppTheme.sans(14))
                        .foregroundStyle(palette.faint)
                    Text(fruit.primary(for: language))
                        .font(AppTheme.serif(17))
                }
                .padding(.top, 8)
            .safeAreaPadding(.top)
                .overlay(alignment: .top) { Hairline() }
            }
        }
    }

    private func footer(_ step: RosaryStep) -> some View {
        VStack(spacing: 10) {
            if step.kind == .hailMary, step.decadeNumber != nil {
                Button("Skip remaining Hail Marys") {
                    skipDecadeHailMarys()
                }
                .font(AppTheme.sans(15, weight: .medium))
                .foregroundStyle(palette.dim)
            }
            PillButton(title: step.nextLabel, filled: true, action: advance)
            HStack {
                Spacer()
                languageChips
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 8)
        .background(palette.prayBg)
    }

    private var languageChips: some View {
        HStack(spacing: 2) {
            ForEach(PrayerLanguage.allCases) { option in
                Button {
                    settings.language = option
                    if var current = sessionStore.session {
                        current.language = option
                        sessionStore.session = current
                    }
                } label: {
                    Text(option.chip)
                        .font(AppTheme.sans(13, weight: .medium))
                        .foregroundStyle(settings.language == option ? palette.ink : palette.dim)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(settings.language == option ? palette.card : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .frame(width: 148, height: 52)
        .background(palette.card2, in: Capsule())
    }

    private func roundControl(system: String? = nil, label: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let system {
                    Image(systemName: system)
                        .font(.system(size: 13, weight: .semibold))
                } else if let label {
                    Text(label)
                        .font(AppTheme.sans(13, weight: .medium))
                }
            }
            .foregroundStyle(palette.ink)
            .frame(width: 40, height: 40)
            .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func shouldShowBeads(_ step: RosaryStep) -> Bool {
        !step.isPlate && !step.isFinis && step.kind != .completion
    }

    // MARK: - Finis

    private func finisLayer(_ step: RosaryStep) -> some View {
        ZStack {
            MysteryArtworkView(set: launch.mysterySet, mysteryNumber: 5, slug: MysteryCatalog.mysteries(for: launch.mysterySet).last?.artSlug, kind: .heroTall)
                .ignoresSafeArea()
            LinearGradient(
                colors: [
                    palette.prayBg.opacity(0.2),
                    palette.prayBg.opacity(0.72),
                    palette.prayBg
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    roundControl(system: "xmark") {
                        sessionStore.complete()
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
                VStack(spacing: 14) {
                    Text("Finis")
                        .font(AppTheme.sans(16, weight: .medium))
                        .foregroundStyle(palette.dim)
                    Text(step.body.english)
                        .font(AppTheme.serif(26, italic: true))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.ink)
                    if let by = step.subtitle {
                        Text(by.english)
                            .font(AppTheme.sans(13, weight: .medium))
                            .foregroundStyle(palette.dim)
                    }
                }
                .padding(.horizontal, 28)
                Spacer()
                VStack(spacing: 10) {
                    PillButton(title: "Amen") {
                        if settings.includeSaintMichael {
                            showingMichael = true
                            HapticService.play(.medium, enabled: settings.hapticsEnabled)
                        } else {
                            sessionStore.complete()
                            dismiss()
                        }
                    }
                    Button("Saint Michael the Archangel") {
                        showingMichael = true
                    }
                    .font(AppTheme.sans(16, weight: .medium))
                    .foregroundStyle(palette.dim)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private var michaelLayer: some View {
        VStack(spacing: 0) {
            HStack {
                roundControl(system: "xmark") {
                    sessionStore.complete()
                    dismiss()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
            VStack(spacing: 16) {
                Text(PrayerCatalog.saintMichael.title.primary(for: language))
                    .font(AppTheme.serif(26))
                    .multilineTextAlignment(.center)
                BilingualStack(
                    text: PrayerCatalog.saintMichael.text,
                    language: language,
                    font: AppTheme.serif(21 * settings.textSize.scale),
                    alignment: .center
                )
            }
            .padding(.horizontal, 24)
            Spacer()
            VStack(spacing: 12) {
                languageChips
                PillButton(title: "Amen") {
                    sessionStore.complete()
                    dismiss()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(palette.prayBg.ignoresSafeArea())
    }

    // MARK: - Navigation

    private func configure() {
        switch launch {
        case .fresh(let set):
            // Do not persist yet — step 0 must not wipe a resumable session.
            freshSetPending = set
            steps = RosarySequenceBuilder.build(set: set)
            index = 0
        case .resume(let session):
            freshSetPending = nil
            steps = RosarySequenceBuilder.build(set: session.mysterySet)
            index = min(session.stepIndex, max(steps.count - 1, 0))
            settings.language = session.language
        }
        playHaptic()
    }

    private func advance() {
        guard index < steps.count - 1 else {
            sessionStore.complete()
            dismiss()
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
            sessionStore.start(set: set, language: settings.language)
            freshSetPending = nil
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
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
