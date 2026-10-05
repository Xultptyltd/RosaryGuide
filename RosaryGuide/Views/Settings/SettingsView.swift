import MessageUI
import StoreKit
import SwiftUI
import UIKit

private enum SettingsDestination: Hashable {
    case aboutYou
    case preferences
    case appearance
    case yourData
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

    var body: some View {
        @Bindable var settings = settings

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                CollapsingTitleSpacer()

                UnlockTrialCard {
                    placeholderMessage = "Premium trials will be available when subscriptions are configured."
                }

                VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                    SettingsSection(title: "Personalize") {
                        SettingsNavigationRow(title: "About you", icon: "person", destination: .aboutYou)
                        SettingsNavigationRow(title: "Preferences", icon: "slider.horizontal.3", destination: .preferences)
                        SettingsNavigationRow(title: "Appearance", icon: "circle.lefthalf.filled", value: settings.appearance.title, destination: .appearance)

                        SettingsMenuRow(title: "Language", icon: "globe", value: settings.language.title) {
                            Picker("Language", selection: $settings.language) {
                                ForEach(PrayerLanguage.appCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                        }
                    }

                    SettingsSection(title: "App icon") {
                        AppIconChoices()
                    }

                    SettingsSection(title: "Account") {
                        SettingsValueOnlyRow(title: "Signed in", icon: "person.badge.key", value: auth.provider.rawValue)
                        SettingsNavigationRow(title: "Your Data", icon: "folder", destination: .yourData)
                        SettingsActionRow(title: "Notifications", icon: "bell") {
                            placeholderMessage = "Rosary reminders and feast notifications are coming soon."
                        }
                    }

                    SettingsSection(title: "Premium") {
                        SettingsNavigationRow(title: "About Premium", icon: "crown", destination: .aboutPremium)
                        SettingsActionRow(title: "Restore Purchase", icon: "arrow.clockwise") {
                            placeholderMessage = "Purchases are not configured yet."
                        }
                    }

                    SettingsSection(title: "Help & Support") {
                        SettingsNavigationRow(title: "Frequently Asked Questions", icon: "questionmark.circle", destination: .faqs)
                        SettingsActionRow(title: "Suggest a Feature", icon: "lightbulb", accessory: .externalLink) {
                            open("https://xult.ltd/contact/")
                        }
                        SettingsActionRow(title: "Report a Bug", icon: "ladybug") {
                            composeSupportEmail(.bug)
                        }
                        SettingsActionRow(title: "Report a Translation Bug", icon: "character.bubble") {
                            composeSupportEmail(.translation)
                        }
                        SettingsActionRow(title: "Leave Review on App Store", icon: "star") {
                            requestReview()
                        }
                    }

                    SettingsSection(title: "Application") {
                        SettingsNavigationRow(title: "Widgets", icon: "square.grid.2x2", destination: .widgets)
                        SettingsActionRow(title: "Onboarding", icon: "sparkles") {
                            showOnboardingPreview = true
                        }
                        SettingsActionRow(title: "Terms of Service", icon: "doc.text", accessory: .externalLink) {
                            open("https://xult.ltd/terms/")
                        }
                        SettingsActionRow(title: "Privacy", icon: "hand.raised", accessory: .externalLink) {
                            open("https://xult.ltd/privacy/")
                        }
                        SettingsNavigationRow(title: "Acknowledgements", icon: "heart", destination: .acknowledgements)
                    }

                    SettingsSection(title: "Account Management") {
                        SettingsActionRow(title: "Sign out", icon: "rectangle.portrait.and.arrow.right") {
                            auth.signOut()
                            dismiss()
                        }
                        SettingsActionRow(title: auth.isWorking ? "Deleting..." : "Delete account", icon: "person.crop.circle.badge.xmark", destructive: true) {
                            confirmDeleteAccount = true
                        }
                        .disabled(auth.isWorking)
                    }
                }
                .padding(.top, AppTheme.sectionGap - AppTheme.Space.xl)

                Text("Rosary Guide version \(appVersion)")
                    .font(AppTheme.TypeRole.settingsMeta)
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Space.xl)
                    .padding(.bottom, AppTheme.Space.xxl)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, AppTheme.Space.xl)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .guidePageChrome()
        .toolbar(.hidden, for: .navigationBar)
        .collapsingTitleChrome("your profile.", scrollOffset: $titleScrollOffset) {
            SettingsCloseButton {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }
        } trailing: {
            EmptyView()
        }
        .navigationTitle("your profile.")
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
        case .aboutYou:
            SettingsAboutYouScreen()
        case .preferences:
            SettingsPreferencesScreen()
        case .appearance:
            SettingsAppearanceScreen(placeholderMessage: $placeholderMessage)
        case .yourData:
            SettingsDataScreen(
                confirmDeleteHistory: $confirmDeleteHistory,
                confirmDeleteAccount: $confirmDeleteAccount
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

private struct SettingsCloseButton: View {
    @Environment(\.palette) private var palette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .guideSymbol(size: 16, weight: .semibold)
                .foregroundStyle(palette.ink)
                .frame(
                    width: AppTheme.Accessibility.minHitTarget,
                    height: AppTheme.Accessibility.minHitTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
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
                Text("Unlock Free Trial")
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
    var value: String?
    let destination: SettingsDestination

    var body: some View {
        NavigationLink(value: destination) {
            SettingsRowChrome(title: title, icon: icon, value: value, accessory: .chevron)
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
        Menu {
            content()
        } label: {
            SettingsRowChrome(title: title, icon: icon, value: value, accessory: .chevron)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsToggleRow: View {
    @Environment(\.palette) private var palette
    let title: String
    var icon: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: AppTheme.Space.lg) {
                if let icon {
                    SettingsRowIcon(symbol: icon, tint: palette.ink)
                }
                Text(title)
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.ink)
            }
        }
        .tint(palette.accent)
        .frame(minHeight: AppTheme.Component.profileRowHeight)
        .overlay(alignment: .bottom) { SettingsDivider() }
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

                Text(title)
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(AppTheme.Component.profileTitleMinimumScale)
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
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                Text(title)
                    .font(AppTheme.TypeRole.settingsTitle)
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, AppTheme.Space.xl)

                content()
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, AppTheme.Space.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsAboutYouScreen: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        SettingsDetailScaffold(title: "about you.") {
            SettingsSection(title: "Account") {
                SettingsValueOnlyRow(title: "Signed in with", icon: "person.badge.key", value: auth.provider.rawValue)
                SettingsValueOnlyRow(title: "Sync", icon: "arrow.triangle.2.circlepath", value: auth.isSignedIn ? "On" : "Off")
            }

            SettingsSection(title: "Profile") {
                SettingsValueOnlyRow(title: "Name", icon: "person", value: "Not set")
                SettingsValueOnlyRow(title: "Prayer story", icon: "text.book.closed", value: "Not set")
            }

            SettingsFootnote(
                "Rosary Guide keeps your profile intentionally minimal. Future personalisation will live here without changing the private nature of your intentions."
            )
        }
    }
}

private struct SettingsPreferencesScreen: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        SettingsDetailScaffold(title: "preferences.") {
            SettingsSection(title: "Prayer") {
                SettingsMenuRow(title: "Language", icon: "globe", value: settings.language.title) {
                    Picker("Language", selection: $settings.language) {
                        ForEach(PrayerLanguage.appCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                SettingsMenuRow(title: "Text size", icon: "textformat.size", value: settings.textSize.title) {
                    Picker("Text size", selection: $settings.textSize) {
                        ForEach(PrayerTextSize.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                SettingsToggleRow(title: "Haptics", icon: "iphone.radiowaves.left.and.right", isOn: $settings.hapticsEnabled)
                SettingsToggleRow(title: "Saint Michael prayer", icon: "shield", isOn: $settings.includeSaintMichael)
            }
        }
    }
}

private struct SettingsAppearanceScreen: View {
    @Environment(SettingsStore.self) private var settings
    @Binding var placeholderMessage: String?

    var body: some View {
        @Bindable var settings = settings

        SettingsDetailScaffold(title: "appearance.") {
            SettingsSection(title: "General") {
                SettingsMenuRow(title: "Color theme", icon: "circle.lefthalf.filled", value: settings.appearance.title) {
                    Picker("Color theme", selection: $settings.appearance) {
                        ForEach(AppearancePreference.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                AppIconChoices()

                SettingsMenuRow(title: "Text size", icon: "textformat.size", value: settings.textSize.title) {
                    Picker("Text size", selection: $settings.textSize) {
                        ForEach(PrayerTextSize.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }
            }

            SettingsSection(title: "Display") {
                SettingsActionRow(title: "Rosary visual style", icon: "paintbrush") {
                    placeholderMessage = "Additional Rosary visual styles are coming soon."
                }
            }
        }
    }
}

private struct SettingsDataScreen: View {
    @Environment(AuthStore.self) private var auth
    @Binding var confirmDeleteHistory: Bool
    @Binding var confirmDeleteAccount: Bool

    var body: some View {
        SettingsDetailScaffold(title: "your data.") {
            SettingsSection(title: "Sync") {
                SettingsValueOnlyRow(title: "Cloud sync", icon: "icloud", value: auth.isSignedIn ? "On" : "Off")
                SettingsValueOnlyRow(title: "Provider", icon: "person.badge.key", value: auth.provider.rawValue)
            }

            SettingsSection(title: "Privacy") {
                SettingsActionRow(title: "Delete local data", icon: "trash", destructive: true) {
                    confirmDeleteHistory = true
                }
                SettingsActionRow(title: auth.isWorking ? "Deleting..." : "Delete account", icon: "person.crop.circle.badge.xmark", destructive: true) {
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

private struct SettingsPremiumScreen: View {
    @Binding var placeholderMessage: String?

    var body: some View {
        SettingsDetailScaffold(title: "premium.") {
            UnlockTrialCard {
                placeholderMessage = "Premium trials will be available when subscriptions are configured."
            }

            SettingsSection(title: "Premium") {
                SettingsValueActionRow(title: "Lifetime Premium", icon: "infinity", value: "save 40%") {
                    placeholderMessage = "Lifetime Premium is not available yet."
                }
                SettingsActionRow(title: "Restore Purchase", icon: "arrow.clockwise") {
                    placeholderMessage = "Purchases are not configured yet."
                }
            }
        }
    }
}

private struct SettingsFAQScreen: View {
    var body: some View {
        SettingsDetailScaffold(title: "frequently asked questions.") {
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
        SettingsDetailScaffold(title: "widgets.") {
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
        SettingsDetailScaffold(title: "acknowledgements.") {
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


private struct AppIconChoices: View {
    @Environment(AppIconService.self) private var appIcon
    @Environment(\.palette) private var palette

    private let previewSize: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
            if appIcon.supportsAlternateIcons {
                HStack(spacing: AppTheme.Space.md) {
                    ForEach(AppIconOption.allCases) { option in
                        iconCell(option)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Alternate icons aren’t available on this device.")
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let message = appIcon.lastErrorMessage {
                Text(message)
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(palette.destructive)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppTheme.Space.lg)
        .overlay(alignment: .bottom) { SettingsDivider() }
        .onAppear { appIcon.refreshFromSystem() }
        .accessibilityElement(children: .contain)
    }

    private func iconCell(_ option: AppIconOption) -> some View {
        let selected = appIcon.current == option
        return Button {
            appIcon.select(option)
        } label: {
            VStack(spacing: AppTheme.Space.sm) {
                Image(option.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: previewSize, height: previewSize)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                selected ? palette.accent : palette.selectionStroke,
                                lineWidth: selected ? 2.5 : AppTheme.Component.panelStrokeWidth
                            )
                    }
                    .shadow(
                        color: selected ? palette.selectedShadow : .clear,
                        radius: selected ? 6 : 0,
                        y: selected ? 2 : 0
                    )

                Text(option.title)
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(selected ? palette.accent : palette.dim)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) app icon")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
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

private extension PrayerTextSize {
    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }
}
