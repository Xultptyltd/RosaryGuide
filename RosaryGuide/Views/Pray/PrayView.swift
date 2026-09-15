import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PrayView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var launch: PrayLaunch

    @State private var steps: [RosaryStep] = []
    @State private var index: Int = 0
    @State private var confirmLeave = false
    @State private var didConfigure = false

    private var language: PrayerLanguage { settings.language }
    private var current: RosaryStep? {
        steps.indices.contains(index) ? steps[index] : nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let current {
                    content(for: current)
                } else {
                    ContentUnavailableView("Unable to load this rosary", systemImage: "exclamationmark.triangle")
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { confirmLeave = true }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(launch.mysterySet.name.primary(for: language))
                            .font(.headline)
                        if let current {
                            Text(current.progressLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }
            }
            .safeAreaInset(edge: .bottom) {
                if current?.kind != .completion {
                    controls
                }
            }
            .alert("Leave this rosary?", isPresented: $confirmLeave) {
                Button("Keep session") { dismiss() }
                Button("Discard session", role: .destructive) {
                    sessionStore.discard()
                    dismiss()
                }
                Button("Stay", role: .cancel) {}
            } message: {
                Text("Your place is saved on this device so you can resume later.")
            }
        }
        .onAppear {
            guard !didConfigure else { return }
            didConfigure = true
            configure()
        }
        .onDisappear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .gesture(swipe)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.width < -50 { advance() }
            if value.translation.width > 50 { retreat() }
        }
    }

    private var languageMenu: some View {
        Menu {
            ForEach(PrayerLanguage.allCases) { option in
                Button(option.title) {
                    settings.language = option
                    if var current = sessionStore.session {
                        current.language = option
                        sessionStore.session = current
                    }
                }
            }
        } label: {
            Text(language.shortTitle)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.gold.opacity(0.2), in: Capsule())
        }
        .accessibilityLabel("Prayer language")
    }

    @ViewBuilder
    private func content(for step: RosaryStep) -> some View {
        if step.kind == .completion {
            CompletionView(
                set: launch.mysterySet,
                quote: step.body.english,
                language: language
            ) {
                sessionStore.complete()
                dismiss()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    progressBar
                    if let mystery = step.mystery {
                        MysteryArtworkView(set: mystery.set, mysteryNumber: mystery.number)
                        HStack {
                            Text(mystery.title.primary(for: language))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(mystery.fruit.primary(for: language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        MysteryArtworkView(set: launch.mysterySet, mysteryNumber: nil)
                    }

                    BilingualStack(
                        text: step.title,
                        language: language,
                        font: .title.weight(.semibold)
                    )

                    if let intention = step.intention {
                        Text(intention.primary(for: language))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.gold)
                    }

                    BilingualStack(
                        text: step.body,
                        language: language,
                        font: step.kind == .mysteryAnnouncement ? .body : .title3
                    )

                    if step.kind == .hailMary, let count = step.hailMaryNumber, step.decadeNumber != nil {
                        BeadRailView(filled: count, total: 10, tint: launch.mysterySet.tint)
                            .padding(.top, 8)
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
    }

    private var progressBar: some View {
        ProgressView(value: Double(index + 1), total: Double(max(steps.count, 1)))
            .tint(launch.mysterySet.tint)
            .accessibilityLabel("Rosary progress")
            .accessibilityValue("Step \(index + 1) of \(steps.count)")
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                retreat()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(index == 0)

            Button {
                advance()
            } label: {
                Label(index >= steps.count - 2 ? "Finish" : "Next", systemImage: "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.marianBlue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func configure() {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        switch launch {
        case .fresh(let set):
            sessionStore.start(
                set: set,
                includeSaintMichael: settings.includeSaintMichael,
                language: settings.language
            )
            steps = RosarySequenceBuilder.build(set: set, includeSaintMichael: settings.includeSaintMichael)
            index = 0
        case .resume(let session):
            steps = RosarySequenceBuilder.build(set: session.mysterySet, includeSaintMichael: session.includeSaintMichael)
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
        let next = index + 1
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            index = next
        }
        sessionStore.updateStep(next)
        playHaptic()
    }

    private func retreat() {
        guard index > 0 else { return }
        let previous = index - 1
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            index = previous
        }
        sessionStore.updateStep(previous)
        HapticService.play(.light, enabled: settings.hapticsEnabled)
    }

    private func playHaptic() {
        if let current {
            HapticService.play(current.haptic, enabled: settings.hapticsEnabled)
        }
    }
}
