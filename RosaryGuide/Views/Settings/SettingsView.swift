import MessageUI
import StoreKit
import SwiftUI
import UIKit

private enum SettingsDestination: Hashable {
    case account
    case aboutPremium
    case faqs
    case widgets
    case acknowledgements
}

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(AuthStore.self) private var auth
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    var onClose: (() -> Void)?

    @State private var titleScrollOffset: CGFloat = 0
    @State private var confirmDeleteHistory = false
    @State private var didDeleteHistory = false
    @State private var confirmDeleteAccount = false
    @State private var didDeleteAccount = false
    @State private var accountDeletionError: String?
    @State private var placeholderMessage: String?
    @State private var showOnboardingPreview = false
    @State private var mailDraft: SettingsMailDraft?
    @State private var showReportChoice = false

    var body: some View {
        @Bindable var settings = settings

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                VStack(alignment: .leading, spacing: 0) {
                    // Standard large-title space; the Premium card starts sectionTitleGap below the H1.
                    CollapsingTitleSpacer(height: CollapsingTitleMetrics.spacerHeight(gapBelowTitle: AppTheme.sectionTitleGap))

                    UnlockTrialCard {
                        placeholderMessage = "Premium trials will be available when subscriptions are configured."
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                    SettingsSection(title: "General") {
                        // App UI language. English is the only option for now; this is
                        // separate from the Eng/Lat/Both prayer toggle in the rosary flow,
                        // so it never reads or writes settings.language.
                        SettingsMenuRow(title: "Language", icon: "globe", value: "English") {
                            Picker("Language", selection: .constant("English")) {
                                Text("English").tag("English")
                            }
                        }

                        SettingsMenuRow(title: "Color theme", icon: "circle.lefthalf.filled", value: settings.appearance.title) {
                            Picker("Color theme", selection: $settings.appearance) {
                                ForEach(AppearancePreference.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                        }

                        SettingsActionRow(title: "Notifications", icon: "bell") {
                            placeholderMessage = "Rosary reminders and feast notifications are coming soon."
                        }
                    }

                    SettingsSection(title: "Account") {
                        SettingsNavigationRow(
                            title: auth.isSignedIn ? (auth.displayName ?? "Your account") : "Sign in",
                            icon: "person.crop.circle",
                            subtitle: auth.isSignedIn ? "Signed in with \(auth.provider.rawValue)" : nil,
                            destination: .account
                        )
                        SettingsNavigationRow(title: "Premium", icon: "crown", value: "Upgrade", destination: .aboutPremium)
                    }

                    SettingsSection(title: "Help & support") {
                        SettingsNavigationRow(title: "Frequently asked questions", icon: "questionmark.circle", destination: .faqs)
                        SettingsActionRow(title: "Report a problem", icon: "exclamationmark.bubble") {
                            showReportChoice = true
                        }
                        SettingsActionRow(title: "Suggest a feature", icon: "lightbulb", accessory: .externalLink) {
                            open("https://xult.ltd/contact/")
                        }
                        SettingsActionRow(title: "Leave a review", icon: "star") {
                            requestReview()
                        }
                    }

                    SettingsSection(title: "About") {
                        SettingsNavigationRow(title: "Widgets", icon: "square.grid.2x2", destination: .widgets)
                        SettingsActionRow(title: "Replay welcome", icon: "sparkles") {
                            showOnboardingPreview = true
                        }
                        SettingsActionRow(title: "Terms of service", icon: "doc.text", accessory: .externalLink) {
                            open("https://xult.ltd/terms/")
                        }
                        SettingsActionRow(title: "Privacy", icon: "hand.raised", accessory: .externalLink) {
                            open("https://xult.ltd/privacy/")
                        }
                        SettingsNavigationRow(title: "Acknowledgements", icon: "heart", destination: .acknowledgements)
                    }
                }
                .padding(.top, AppTheme.sectionGap - AppTheme.Space.xl)

                Text("Version \(appVersion)")
                    .font(AppTheme.TypeRole.settingsMeta)
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Space.xl)
                    .padding(.bottom, AppTheme.Space.xxl)
            }
            .padding(.horizontal, AppTheme.gutter)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .background(SettingsSwipeBackEnabler())
        .guidePageChrome()
        .toolbar(.hidden, for: .navigationBar)
        .collapsingTitleChrome("Your profile", scrollOffset: $titleScrollOffset) {
            SettingsToolbarButton(symbol: "xmark", label: "Close") {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }
        } trailing: {
            EmptyView()
        }
        .navigationTitle("Your profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SettingsDestination.self) { destination in
            destinationView(destination)
        }
        .fullScreenCover(isPresented: $showOnboardingPreview) {
            OnboardingView(includesSignIn: false) {
                showOnboardingPreview = false
            }
        }
        .sheet(item: $mailDraft) { draft in
            SettingsMailComposer(draft: draft)
        }
        .confirmationDialog("What would you like to report?", isPresented: $showReportChoice, titleVisibility: .visible) {
            Button("Bug") { composeSupportEmail(.bug) }
            Button("Translation") { composeSupportEmail(.translation) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete local data?", isPresented: $confirmDeleteHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                session.clearHistoryAndData()
                didDeleteHistory = true
            }
        } message: {
            Text("This clears prayer progress and recent prayer history from this device. Synced intentions stay in your account.")
        }
        .alert("Data deleted", isPresented: $didDeleteHistory) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Local prayer progress and recent prayer history have been deleted from this device.")
        }
        .alert("Delete account?", isPresented: $confirmDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                auth.reauthenticateForSensitiveOperation { reauthenticated in
                    guard reauthenticated else { return }
                    Task {
                        do {
                            try await offer.deleteCloudDataForCurrentUser()
                            auth.deleteAccount { success in
                                if success {
                                    session.clearHistoryAndData()
                                    offer.clearAll()
                                    didDeleteAccount = true
                                } else {
                                    offer.reconnectSync()
                                }
                            }
                        } catch {
                            accountDeletionError = "Cloud intentions could not be deleted. Your account was not deleted."
                        }
                    }
                }
            }
        } message: {
            Text("This deletes your Rosary Guide sign-in account and clears private prayer data from this device. This cannot be undone.")
        }
        .alert("Account deleted", isPresented: $didDeleteAccount) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your account was deleted and private prayer data was cleared from this device.")
        }
        .alert("Account not deleted", isPresented: Binding(
            get: { accountDeletionError != nil },
            set: { if !$0 { accountDeletionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountDeletionError ?? "Try again.")
        }
        .alert("Coming soon", isPresented: Binding(
            get: { placeholderMessage != nil },
            set: { if !$0 { placeholderMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(placeholderMessage ?? "This will be available in a future update.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func composeSupportEmail(_ kind: SettingsSupportMailKind) {
        let draft = SettingsMailDraft(kind: kind, userID: auth.userID)
        if MFMailComposeViewController.canSendMail() {
            mailDraft = draft
        } else {
            openMailFallback(draft)
        }
    }

    private func openMailFallback(_ draft: SettingsMailDraft) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = draft.recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: draft.subject),
            URLQueryItem(name: "body", value: draft.body)
        ]

        guard let url = components.url else {
            placeholderMessage = "Mail is not available on this device."
            return
        }
        openURL(url)
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        AppStore.requestReview(in: scene)
    }

    @ViewBuilder
    private func destinationView(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .account:
            SettingsAccountScreen(
                confirmDeleteHistory: $confirmDeleteHistory,
                confirmDeleteAccount: $confirmDeleteAccount,
                onSignOut: {
                    auth.signOut()
                    dismiss()
                }
            )
        case .aboutPremium:
            SettingsPremiumScreen(placeholderMessage: $placeholderMessage)
        case .faqs:
            SettingsFAQScreen()
        case .widgets:
            SettingsWidgetsScreen()
        case .acknowledgements:
            SettingsAcknowledgementsScreen(placeholderMessage: $placeholderMessage)
        }
    }
}

private enum SettingsSupportMailKind {
    case bug
    case translation
}

private struct SettingsMailDraft: Identifiable {
    let id = UUID()
    let kind: SettingsSupportMailKind
    let userID: String?

    var recipient: String { "support@xult.ltd" }

    var subject: String {
        switch kind {
        case .bug:
            "Rosary Guide bug report"
        case .translation:
            "Translation bug in Rosary Guide"
        }
    }

    var body: String {
        switch kind {
        case .bug:
            """
            Hi,

            I wanted to tell you that...

            Where in Rosary Guide is the issue:
            What happened:
            What did you expect:
            Steps to reproduce:

            Please attach a screenshot if helpful.

            \(diagnostics)
            """
        case .translation:
            """
            Hi,

            I’ve noticed a translation error. Here’s more info.

            Where in Rosary Guide is the issue:
            Which text is wrong:
            What should it be:
            Language:

            Please attach a screenshot if helpful.

            \(diagnostics)
            """
        }
    }

    private var diagnostics: String {
        """
        --
        Rosary Guide diagnostics
        Version: \(Self.appVersion)
        Build: \(Self.buildNumber)
        iOS: \(UIDevice.current.systemVersion)
        Device: \(Self.deviceModel)
        App user id: \(userID ?? "not signed in")
        """
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? UIDevice.current.model
            }
        }
    }
}

private struct SettingsMailComposer: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let draft: SettingsMailDraft

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([draft.recipient])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}

private struct SettingsToolbarButton: View {
    @Environment(\.palette) private var palette
    let symbol: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .guideSymbol(size: 16, weight: .semibold)
                .foregroundStyle(palette.ink)
                .frame(
                    width: AppTheme.Accessibility.minHitTarget,
                    height: AppTheme.Accessibility.minHitTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct UnlockTrialCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    var action: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Space.lg) {
            ZStack(alignment: .trailing) {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    Text("Unlock every prayer companion feature")
                        .font(AppTheme.TypeRole.settingsCardTitle)
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start your Rosary Guide Premium trial.")
                        .font(AppTheme.TypeRole.settingsMeta)
                        .foregroundStyle(palette.dim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, AppTheme.Component.profileHeroSymbolReserve)

                Image(systemName: "lock.open.fill")
                    .guideSymbol(size: AppTheme.Component.profileHeroSymbolSize, weight: .regular)
                    .foregroundStyle(palette.ink.opacity(AppTheme.Component.profileBackgroundSymbolOpacity))
                    .offset(x: AppTheme.Space.md, y: AppTheme.Space.lg)
                    .accessibilityHidden(true)
            }

            Button(action: action) {
                Text("Unlock free trial")
                    .font(AppTheme.TypeRole.settingsRow(weight: .semibold))
                    .foregroundStyle(palette.secondaryButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.secondaryButtonFill, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Space.xl)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, stroke: false, elevated: colorScheme == .light)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: title, prominence: .strong)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, AppTheme.sectionTitleGap)

            VStack(spacing: 0) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsActionRow: View {
    let title: String
    var icon: String?
    var destructive = false
    var accessory: SettingsRowAccessory = .chevron
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowChrome(title: title, icon: icon, value: nil, destructive: destructive, accessory: accessory)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    var icon: String?
    var subtitle: String?
    var value: String?
    let destination: SettingsDestination

    var body: some View {
        NavigationLink(value: destination) {
            SettingsRowChrome(title: title, icon: icon, subtitle: subtitle, value: value, accessory: .chevron)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsValueActionRow: View {
    let title: String
    var icon: String?
    let value: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowChrome(title: title, icon: icon, value: value, accessory: .chevron)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsMenuRow<Content: View>: View {
    let title: String
    var icon: String?
    let value: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        // The visible row is drawn outside the Menu. The Menu's own label is an
        // invisible full-row tap target on top, so when iOS lifts/hides the menu
        // source while the popover is open, the icon and label stay on screen.
        SettingsRowChrome(title: title, icon: icon, value: value, accessory: .chevron)
            .accessibilityHidden(true)
            .overlay {
                Menu {
                    content()
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(value)
            }
    }
}

private struct SettingsValueOnlyRow: View {
    let title: String
    var icon: String?
    let value: String

    var body: some View {
        SettingsRowChrome(title: title, icon: icon, value: value, accessory: .none)
    }
}

private enum SettingsRowAccessory {
    case none
    case chevron
    case externalLink
}

/// Leading line icon in a fixed-width column so every row label lines up.
private struct SettingsRowIcon: View {
    let symbol: String
    let tint: Color

    var body: some View {
        Image(systemName: symbol)
            .guideSymbol(size: 20, weight: .light)
            .foregroundStyle(tint)
            .frame(width: AppTheme.Space.xl, alignment: .center)
            .accessibilityHidden(true)
    }
}

private struct SettingsRowChrome: View {
    @Environment(\.palette) private var palette
    let title: String
    var icon: String?
    var subtitle: String?
    let value: String?
    var destructive = false
    var accessory: SettingsRowAccessory = .chevron

    var body: some View {
        let tint = destructive ? palette.destructive : palette.ink

        HStack(spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.lg) {
                if let icon {
                    SettingsRowIcon(symbol: icon, tint: tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.TypeRole.settingsRow)
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(AppTheme.Component.profileTitleMinimumScale)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.TypeRole.settingsMeta)
                            .foregroundStyle(palette.dim)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: AppTheme.Space.md)

            if let value {
                Text(value)
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(AppTheme.Component.profileValueMinimumScale)
            }

            switch accessory {
            case .none:
                EmptyView()
            case .chevron:
                Image(systemName: "chevron.right")
                    .guideSymbol(size: AppTheme.Component.profileChevronSize, weight: .semibold)
                    .foregroundStyle(palette.dim)
            case .externalLink:
                Image(systemName: AppTheme.Component.profileExternalLinkSymbol)
                    .guideSymbol(size: AppTheme.Component.profileExternalLinkSize, weight: .semibold)
                    .foregroundStyle(palette.dim)
            }
        }
        .frame(minHeight: AppTheme.Component.profileRowHeight)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { SettingsDivider() }
    }
}

/// Hairline under each row, spanning the full content width inside the page gutter.
private struct SettingsDivider: View {
    @Environment(\.palette) private var palette

    var body: some View {
        Rectangle()
            .fill(palette.hair.opacity(AppTheme.Component.profileDividerOpacity))
            .frame(height: AppTheme.Component.hairline)
    }
}

private struct SettingsDetailScaffold<Content: View>: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder var content: () -> Content

    @State private var titleScrollOffset: CGFloat = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                // Standard large-title space; the first section starts
                // sectionTitleGap below the H1 (the stack adds sectionGap).
                CollapsingTitleSpacer(
                    height: CollapsingTitleMetrics.spacerHeight(gapBelowTitle: AppTheme.sectionTitleGap) - AppTheme.sectionGap
                )

                content()
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, AppTheme.Space.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .guidePageChrome()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .collapsingTitleChrome(title, scrollOffset: $titleScrollOffset) {
            SettingsToolbarButton(symbol: "chevron.left", label: "Back") {
                dismiss()
            }
        } trailing: {
            EmptyView()
        }
        .navigationTitle(title)
    }
}

/// Keeps the edge-swipe back gesture working on Settings pages, which hide the
/// system navigation bar to use the collapsing large title. Only allows the
/// swipe when there is a page to go back to.
private struct SettingsSwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let pop = navigationController?.interactivePopGestureRecognizer else { return }
            pop.isEnabled = true
            pop.delegate = self
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

private struct SettingsAccountScreen: View {
    @Environment(AuthStore.self) private var auth
    @Environment(SettingsStore.self) private var settings
    @Binding var confirmDeleteHistory: Bool
    @Binding var confirmDeleteAccount: Bool
    var onSignOut: () -> Void

    var body: some View {
        SettingsDetailScaffold(title: "Account") {
            VStack(spacing: 0) {
                if auth.isSignedIn {
                    SettingsValueOnlyRow(title: "Name", icon: "person", value: auth.displayName ?? "Not set")
                    SettingsValueOnlyRow(title: "Signed in with", icon: "person.badge.key", value: auth.provider.rawValue)
                } else {
                    SettingsActionRow(
                        title: auth.isWorking ? "Signing in..." : "Continue with Apple",
                        icon: "apple.logo",
                        accessory: .none
                    ) {
                        HapticService.play(.medium, enabled: settings.hapticsEnabled)
                        auth.signInWithApple()
                    }
                    .disabled(auth.isWorking)

                    SettingsActionRow(title: "Continue with Google", icon: "g.circle", accessory: .none) {
                        HapticService.play(.medium, enabled: settings.hapticsEnabled)
                        auth.signInWithGoogle()
                    }
                    .disabled(auth.isWorking)
                }

                SettingsActionRow(title: "Delete local data", icon: "trash", destructive: true) {
                    confirmDeleteHistory = true
                }
            }

            if !auth.isSignedIn, let message = auth.errorMessage {
                SettingsFootnote(message)
            }

            if auth.isSignedIn {
                VStack(spacing: 0) {
                    SettingsActionRow(title: "Sign out", icon: "rectangle.portrait.and.arrow.right") {
                        onSignOut()
                    }
                    SettingsActionRow(
                        title: auth.isWorking ? "Deleting..." : "Delete account",
                        icon: "person.crop.circle.badge.xmark",
                        destructive: true
                    ) {
                        confirmDeleteAccount = true
                    }
                    .disabled(auth.isWorking)
                }

                SettingsFootnote(
                    "Sign out clears private local session data on this device. Delete account removes your synced intentions before deleting your sign-in account."
                )
            }
        }
    }
}

private struct SettingsPremiumScreen: View {
    @Binding var placeholderMessage: String?

    var body: some View {
        SettingsDetailScaffold(title: "Premium") {
            UnlockTrialCard {
                placeholderMessage = "Premium trials will be available when subscriptions are configured."
            }

            SettingsSection(title: "Premium") {
                SettingsValueActionRow(title: "Lifetime Premium", icon: "infinity", value: "save 40%") {
                    placeholderMessage = "Lifetime Premium is not available yet."
                }
                SettingsActionRow(title: "Restore purchase", icon: "arrow.clockwise") {
                    placeholderMessage = "Purchases are not configured yet."
                }
            }
        }
    }
}

private struct SettingsFAQScreen: View {
    var body: some View {
        SettingsDetailScaffold(title: "Frequently asked questions") {
            SettingsSection(title: "Rosary Guide") {
                SettingsValueOnlyRow(title: "Do intentions sync?", icon: "questionmark.circle", value: "Yes")
                SettingsValueOnlyRow(title: "Can I pray offline?", icon: "questionmark.circle", value: "Yes")
                SettingsValueOnlyRow(title: "Can I use Latin?", icon: "questionmark.circle", value: "Yes")
            }

            SettingsFootnote(
                "Signed-in intentions are privately synced to your account. Prayer progress and recent session state remain local to this device."
            )
        }
    }
}

private struct SettingsWidgetsScreen: View {
    var body: some View {
        SettingsDetailScaffold(title: "Widgets") {
            SettingsSection(title: "Widgets") {
                SettingsValueOnlyRow(title: "Daily mysteries", icon: "sun.max", value: "Coming soon")
                SettingsValueOnlyRow(title: "Feast days", icon: "calendar", value: "Coming soon")
            }

            SettingsFootnote(
                "Widgets will help you see today’s mysteries and upcoming feast days from your Home Screen."
            )
        }
    }
}

private struct SettingsAcknowledgementsScreen: View {
    @Binding var placeholderMessage: String?

    var body: some View {
        SettingsDetailScaffold(title: "Acknowledgements") {
            SettingsSection(title: "Libraries") {
                SettingsActionRow(title: "Firebase", icon: "flame") {
                    placeholderMessage = "Firebase is used for private account sign-in and synced intentions."
                }
                SettingsActionRow(title: "Google Sign-In", icon: "g.circle") {
                    placeholderMessage = "Google Sign-In is used as an optional account provider."
                }
                SettingsActionRow(title: "Lottie", icon: "play.circle") {
                    placeholderMessage = "Lottie powers launch and motion artwork."
                }
                SettingsActionRow(title: "Apple frameworks", icon: "swift") {
                    placeholderMessage = "Rosary Guide is built with SwiftUI and Apple platform frameworks."
                }
            }
        }
    }
}


private struct SettingsFootnote: View {
    @Environment(\.palette) private var palette
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(AppTheme.TypeRole.settingsMeta)
            .foregroundStyle(palette.dim)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, AppTheme.Space.lg - AppTheme.sectionGap)
    }
}
