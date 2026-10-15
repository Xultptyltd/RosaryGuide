import MessageUI
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

private enum SettingsDestination: Hashable {
    case notifications
    case rosary
    case aboutPremium
    case faqs
    case acknowledgements
    case license(String)
}

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(OfferStore.self) private var offer
    @Environment(AuthStore.self) private var auth
    @Environment(AccountSyncStore.self) private var sync
    @Environment(AppIconService.self) private var appIcon
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    var onClose: (() -> Void)?

    @State private var confirmClearAppHistory = false
    @State private var didClearAppHistory = false
    @State private var confirmDeleteAccount = false
    @State private var didDeleteAccount = false
    @State private var accountDeletionError: String?
    @State private var placeholderMessage: String?
    @State private var showOnboardingPreview = false
    @State private var mailDraft: SettingsMailDraft?
    @State private var showReportChoice = false

    var body: some View {
        profileScroll
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        // Same compact bar as every pushed page, with a back chevron on the left.
        .guideDetailChrome("Your profile")
        .toolbar { backToolbarItem }
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
        .alert("Clear app history?", isPresented: $confirmClearAppHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAppHistory()
                didClearAppHistory = true
            }
        } message: {
            Text("This clears your prayer progress, prayer history, intentions and settings on this device. When signed in, the wipe also reaches your account. Your sign-in stays.")
        }
        .alert("App history cleared", isPresented: $didClearAppHistory) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your prayer progress, intentions and settings have been cleared from this device.")
        }
        .alert("Delete account?", isPresented: $confirmDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(deleteAccountConfirmationMessage)
        }
        .alert("Account deleted", isPresented: $didDeleteAccount) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your account and everything synced to it (intentions, prayer history and settings) were deleted, and your prayer data was cleared from this device.")
        }
        .alert("Account not deleted", isPresented: Binding(
            get: { accountDeletionError != nil },
            set: { if !$0 { accountDeletionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountDeletionError ?? "Try again.")
        }
        .alert("App icon not changed", isPresented: Binding(
            get: { appIcon.lastErrorMessage != nil },
            set: { if !$0 { appIcon.clearError() } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appIcon.lastErrorMessage ?? "Try again.")
        }
        .onAppear { appIcon.refreshFromSystem() }
        .alert("Coming soon", isPresented: Binding(
            get: { placeholderMessage != nil },
            set: { if !$0 { placeholderMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(placeholderMessage ?? "This will be available in a future update.")
        }
    }

    /// Settings root content, split out of `body` to keep type-checking fast.
    private var profileScroll: some View {
        @Bindable var settings = settings

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                PremiumUpsellIfNeeded {
                    placeholderMessage = "Premium trials will be available when subscriptions are configured."
                }

                VStack(alignment: .leading, spacing: 0) {
                    SettingsSection(title: "General") {
                        SettingsNavigationRow(title: "Customise rosary", icon: "slider.horizontal.3", destination: .rosary)

                        SettingsMenuRow(title: "Color theme", icon: "circle.lefthalf.filled", value: settings.appearance.title) {
                            Picker("Color theme", selection: $settings.appearance) {
                                ForEach(AppearancePreference.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                        }

                        SettingsNavigationRow(title: "Notifications", icon: "bell", destination: .notifications)

                        if appIcon.supportsAlternateIcons {
                            AppIconChoices()
                        }
                    }


                    GuideSectionBoundary()

                    SettingsSection(title: "Account") {
                        if auth.isSignedIn {
                            SettingsValueOnlyRow(
                                title: "Signed in with",
                                icon: "person.badge.key",
                                value: auth.provider.rawValue
                            )
                        } else {
                            SettingsActionRow(
                                title: auth.isSigningInWithApple ? "Signing in..." : "Continue with Apple",
                                icon: "apple.logo",
                                accessory: .none
                            ) {
                                HapticService.play(.medium, enabled: settings.hapticsEnabled)
                                auth.signInWithApple()
                            }
                            .disabled(auth.isWorking)

                            SettingsActionRow(title: auth.isSigningInWithGoogle ? "Signing in..." : "Continue with Google", icon: "g.circle", accessory: .none) {
                                HapticService.play(.medium, enabled: settings.hapticsEnabled)
                                auth.signInWithGoogle()
                            }
                            .disabled(auth.isWorking)
                        }

                        SettingsNavigationRow(title: "Premium", icon: "crown", destination: .aboutPremium)
                    }

                    if !auth.isSignedIn, let message = auth.errorMessage {
                        SettingsFootnote(message)
                            .padding(.top, AppTheme.Space.lg)
                    }

                    GuideSectionBoundary()

                    SettingsSection(title: "Help & support") {
                        SettingsNavigationRow(title: "Frequently asked questions", icon: "questionmark.circle", destination: .faqs)
                        SettingsActionRow(title: "Report a problem", icon: "exclamationmark.bubble", accessory: .externalLink) {
                            showReportChoice = true
                        }
                        SettingsActionRow(title: "Suggest a feature", icon: "lightbulb", accessory: .externalLink) {
                            open("https://xult.ltd/contact/")
                        }
                        SettingsActionRow(title: "Leave a review", icon: "star", accessory: .externalLink) {
                            requestReview()
                        }
                    }

                    GuideSectionBoundary()

                    SettingsSection(title: "About") {
                        SettingsActionRow(title: "Replay welcome", icon: "sparkles", accessory: .navigation) {
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

                    if auth.isSignedIn {
                        GuideSectionBoundary()
                        SettingsSection(title: "Manage account") {
                            SettingsActionRow(title: "Sign out", icon: "rectangle.portrait.and.arrow.right") {
                                auth.signOut()
                                dismiss()
                            }
                            SettingsActionRow(title: "Clear app history", icon: "trash", destructive: true) {
                                confirmClearAppHistory = true
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
                    }
                }
                .padding(.top, AppTheme.sectionGap - AppTheme.Space.xl)

                VStack(spacing: AppTheme.Space.md) {
                    Image("LogoMark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 52)
                        .foregroundStyle(palette.ink)
                        .accessibilityHidden(true)

                    Text("Version \(appVersion)")
                        .font(AppTheme.TypeRole.settingsMeta)
                        .foregroundStyle(palette.dim)
                }
                .frame(maxWidth: .infinity)
                // 40pt from the last row's divider to the top of the logo (the stack adds Space.xl).
                .padding(.top, 40 - AppTheme.Space.xl)
                .padding(.bottom, AppTheme.Space.xxl)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
        }
    }

    /// Settings root is the root of the drawer's own NavigationStack, so there is
    /// no native back button. This toolbar chevron mirrors it (same symbol, glass
    /// circle and colour) and closes the drawer.
    @ToolbarContentBuilder
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: close) {
                Image(systemName: "chevron.backward")
                    .fontWeight(.medium)
                    .foregroundStyle(palette.ink)
            }
            // Ink, like the native back chevron on pushed pages (bar buttons
            // otherwise take the accent tint).
            .tint(palette.ink)
            .accessibilityLabel("Back")
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
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

    private var deleteAccountConfirmationMessage: String {
        let provider = auth.provider == .anonymous ? "your sign-in provider" : auth.provider.rawValue
        return "This permanently deletes your Rosary Guide account and everything synced to it (intentions, prayer history and settings), then clears your prayer data from this device. You'll confirm with \(provider) first. This can't be undone."
    }

    /// Re-authenticate, delete cloud preferences/progress and intentions, delete the Auth account,
    /// then clear local data. Any failure leaves the account and its data in place and explains why.
    /// Preferences and progress go first: deleting intentions also shuts down Firestore's cache.
    /// Full local wipe: prayers/streak, in-progress rosary, intentions, and preferences
    /// (icon on the Home Screen is kept). Same behaviour as the former Account page.
    private func clearAppHistory() {
        session.clearHistoryAndData()
        offer.clearAll()
        settings.resetLocalPreferences(keepingAppIcon: appIcon.current)
        Task {
            await NotificationService.reschedule(settings.notificationPlan)
        }
    }

    private func deleteAccount() {
        auth.reauthenticateForSensitiveOperation { reauthenticated in
            guard reauthenticated else {
                // A cancelled Apple/Google sheet leaves no message, so nothing is shown.
                if let message = auth.errorMessage {
                    accountDeletionError = message
                    auth.errorMessage = nil
                }
                return
            }
            let deletingUID = auth.userID
            Task {
                do {
                    try await sync.deleteCloudDataForCurrentUser()
                    try await offer.deleteCloudDataForCurrentUser()
                } catch {
                    auth.cancelPendingAccountDeletion()
                    sync.restoreCloudDataAfterFailedDeletion()
                    offer.restoreCloudDataAfterFailedDeletion()
                    accountDeletionError = "Your synced data could not be deleted, so your account was not deleted. Check your connection and try again."
                    return
                }
                auth.deleteAccount { success in
                    if success {
                        offer.finishAccountDeletion(uid: deletingUID)
                        sync.finishAccountDeletion(uid: deletingUID)
                        didDeleteAccount = true
                    } else {
                        sync.restoreCloudDataAfterFailedDeletion()
                        offer.restoreCloudDataAfterFailedDeletion()
                        accountDeletionError = auth.errorMessage ?? "Your account could not be deleted. Try again."
                        auth.errorMessage = nil
                    }
                }
            }
        }
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
        case .aboutPremium:
            SettingsPremiumScreen()
        case .faqs:
            SettingsFAQScreen()
        case .notifications:
            SettingsNotificationsScreen()
        case .rosary:
            SettingsRosaryScreen()
        case .acknowledgements:
            SettingsAcknowledgementsScreen()
        case .license(let id):
            if let entry = LicenseCatalog.entry(id: id) {
                SettingsLicenseScreen(entry: entry)
            }
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

private struct SettingsSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GuideSectionLabel(text: title, prominence: .strong, icon: icon)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, AppTheme.sectionTitleGap)

            DividedRows {
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
    let destination: SettingsDestination

    // Rows that push a page show only a trailing chevron, never a value.
    var body: some View {
        NavigationLink(value: destination) {
            SettingsRowChrome(title: title, icon: icon, subtitle: subtitle, value: nil, accessory: .navigation)
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
    /// Row pushes another page: always draws a trailing chevron.
    case navigation
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
    @Environment(\.showsRowDivider) private var showsRowDivider
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
                EmptyView()
            case .externalLink:
                // Row leaves the app: link-out arrow, styled like the navigation chevron.
                Image(systemName: "arrow.up.right")
                    .guideSymbol(size: 12, weight: .regular)
                    .foregroundStyle(palette.secondaryText)
                    .accessibilityHidden(true)
            case .navigation:
                // Same chevron as the Learn tab rows.
                Image(systemName: "chevron.right")
                    .guideSymbol(size: 12, weight: .regular)
                    .foregroundStyle(palette.secondaryText)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: AppTheme.Component.profileRowHeight)
        .padding(.bottom, showsRowDivider ? 0 : -AppTheme.Space.lg)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) { SettingsDivider() }
    }
}

/// The icon tiles picker (as before 7433662), as one flat row in General.
/// Picking an icon also records the synced appIcon preference
/// (AppIconService.onUserSelect -> SettingsStore.appIconChoice). Errors show as an alert
/// on SettingsView.
private struct AppIconChoices: View {
    @Environment(AppIconService.self) private var appIcon
    @Environment(\.palette) private var palette
    @Environment(\.showsRowDivider) private var showsRowDivider

    private let previewSize: CGFloat = 64
    private let tileSpacing = AppTheme.Space.md

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            HStack(spacing: AppTheme.Space.lg) {
                SettingsRowIcon(symbol: "app", tint: palette.ink)
                Text("App icon")
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
            }
            .accessibilityAddTraits(.isHeader)

            // Icon choices sit in the standard flat card.
            HStack(spacing: tileSpacing) {
                ForEach(AppIconOption.allCases) { option in
                    iconCell(option)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Space.lg)
            .guideCard()
        }
        .padding(.vertical, AppTheme.Space.lg)
        // As the last row, trim so the card sits Space.lg above the section band.
        // Measured untrimmed card-to-band gap was ~52pt (row padding, boundary padding
        // and the boundary's empty frame); trim measured in render to leave Space.lg + Space.xs (reads as 16 beside the divider's curved ends). The trim lives
        // in a child view so it reads `showsRowDivider` after DividedRows sets it.
        .modifier(SettingsLastRowBottomTrim(amount: AppTheme.Space.lg + AppTheme.Space.sm))
        .overlay(alignment: .bottom) { SettingsDivider() }
        .onAppear { appIcon.refreshFromSystem() }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func iconCell(_ option: AppIconOption) -> some View {
        let selected = appIcon.current == option
        Button {
            if !selected { appIcon.select(option) }
        } label: {
            iconLabel(option, selected: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) app icon")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func iconLabel(_ option: AppIconOption, selected: Bool) -> some View {
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
}

/// Hairline under each row, spanning the full content width inside the page gutter.
/// Hidden on the last row of a section (`DividedRows` sets `showsRowDivider`).
private struct SettingsDivider: View {
    @Environment(\.palette) private var palette
    @Environment(\.showsRowDivider) private var showsRowDivider

    var body: some View {
        if showsRowDivider {
            Rectangle()
                .fill(palette.hair.opacity(AppTheme.Component.profileDividerOpacity))
                .frame(height: AppTheme.Component.hairline)
        }
    }
}

/// Settings level-2 pages: standard compact bar (`guideDetailChrome`), sections
/// sectionGap apart starting `GuideDetailChrome.contentTop` under the bar.
private struct SettingsDetailScaffold<Content: View>: View {
    @Environment(\.palette) private var palette
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionGap) {
                content()
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.Space.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(palette.bg.ignoresSafeArea())
        .guideDetailChrome(title)
    }
}

/// The Settings Premium screen for pushing from outside Settings (e.g. the
/// Rosary Guide+ card on My prayer). Owns its own "Coming soon" alert, which
/// SettingsView otherwise provides.
struct PremiumScreen: View {
    /// Optional context line shown at the top (e.g. why the user landed here).
    var note: String? = nil

    var body: some View {
        SettingsPremiumScreen(note: note)
    }
}

private struct SettingsPremiumScreen: View {
    var note: String? = nil
    // Own the alert so it presents on this page when pushed from Settings
    // (root SettingsView alerts only appear after swipe-back).
    @State private var placeholderMessage: String?

    var body: some View {
        SettingsDetailScaffold(title: "Premium") {
            if let note {
                SettingsFootnote(note)
            }

            PremiumUpsellIfNeeded {
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

            #if DEBUG
            PremiumModeDebugSection()
            #endif
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
}

#if DEBUG
/// Developer switch between the free tier and Rosary Guide+ (Debug builds only).
private struct PremiumModeDebugSection: View {
    @Bindable private var premium = PremiumDebugOverride.shared

    var body: some View {
        SettingsSection(title: "Developer") {
            SettingsToggleRow(title: "Premium mode", icon: "hammer", isOn: $premium.isPremium)
        }

        SettingsFootnote("For testing only. Switches the app between free and Rosary Guide+.")
    }
}
#endif

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

private struct SettingsNotificationsScreen: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var permissionWasDenied = false

    var body: some View {
        SettingsDetailScaffold(title: "Notifications") {
            DividedRows {
                SettingsToggleRow(
                    title: "Daily rosary reminder",
                    icon: "bell",
                    isOn: permissionGatedBinding(\.dailyReminderEnabled)
                )

                if settings.dailyReminderEnabled {
                    SettingsTimeRow(
                        title: "Reminder time",
                        icon: "clock",
                        minutes: Binding(
                            get: { settings.dailyReminderMinutes },
                            set: { settings.dailyReminderMinutes = $0 }
                        )
                    )
                }

                SettingsToggleRow(
                    title: "Feast day alerts",
                    icon: "calendar",
                    isOn: permissionGatedBinding(\.feastAlertsEnabled)
                )

                if settings.feastAlertsEnabled {
                    SettingsTimeRow(
                        title: "Alert time",
                        icon: "clock",
                        minutes: Binding(
                            get: { settings.feastAlertMinutes },
                            set: { settings.feastAlertMinutes = $0 }
                        )
                    )
                }
            }

            if status == .notDetermined && !settings.notificationPlan.isEmpty {
                // Reminders restored from the account on a device that has not been asked yet.
                DividedRows(alignment: .leading) {
                    SettingsActionRow(title: "Allow notifications", icon: "bell.badge") {
                        Task {
                            _ = await NotificationService.requestPermission()
                            status = await NotificationService.authorizationStatus()
                            await NotificationService.reschedule(settings.notificationPlan)
                        }
                    }
                }
                SettingsFootnote("Your reminders came from your account. Allow notifications on this iPhone so they can be shown.")
            } else if status == .denied && (permissionWasDenied || !settings.notificationPlan.isEmpty) {
                DividedRows(alignment: .leading) {
                    SettingsActionRow(title: "Turn on in iOS Settings", icon: "gear", accessory: .externalLink) {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                SettingsFootnote("Notifications are turned off for Rosary Guide in iOS Settings, so reminders can't be shown.")
            } else {
                SettingsFootnote("The daily reminder names that day's mysteries. Feast day alerts arrive at your chosen time on feast days in the Rosary Guide calendar.")
            }
        }
        .task { status = await NotificationService.authorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { status = await NotificationService.authorizationStatus() }
        }
    }

    /// Turning a toggle on asks for notification permission first; if it's refused,
    /// the toggle stays off and the iOS Settings row appears.
    private func permissionGatedBinding(_ keyPath: ReferenceWritableKeyPath<SettingsStore, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                guard newValue else {
                    settings[keyPath: keyPath] = false
                    return
                }
                Task {
                    let allowed = await NotificationService.requestPermission()
                    status = await NotificationService.authorizationStatus()
                    if allowed {
                        settings[keyPath: keyPath] = true
                        permissionWasDenied = false
                    } else {
                        permissionWasDenied = true
                    }
                }
            }
        )
    }
}

private struct SettingsToggleRow: View {
    @Environment(\.palette) private var palette
    let title: String
    var icon: String?
    @Binding var isOn: Bool

    var body: some View {
        // The ZStack makes the trim a child view, so it sees `showsRowDivider` (see below).
        ZStack {
            SettingsLastRowTrim {
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
                .tint(Color(uiColor: .systemGreen))
                .frame(minHeight: AppTheme.Component.profileRowHeight)
            }
        }
        .overlay(alignment: .bottom) { SettingsDivider() }
    }
}

/// Last row of a group lays out Space.lg shorter (content stays put, top-aligned), so the gap
/// to the next section divider matches a group ending in `SettingsRowChrome`.
/// `DividedRows` sets `showsRowDivider` on each row's resolved subview, so the row struct and
/// modifiers in its own body chain still read the default (true). It must be read by a child
/// view inside a container (like `SettingsRowChrome` inside a NavigationLink label).
/// Checked with sizeThatFits: row-struct env 112pt vs child-in-ZStack 96pt for two 56pt rows.
private struct SettingsLastRowBottomTrim: ViewModifier {
    let amount: CGFloat
    func body(content: Content) -> some View {
        ZStack { SettingsLastRowBottomTrimBody(amount: amount) { content } }
    }
}

private struct SettingsLastRowBottomTrimBody<Inner: View>: View {
    @Environment(\.showsRowDivider) private var showsRowDivider
    let amount: CGFloat
    @ViewBuilder var inner: Inner
    var body: some View { inner.padding(.bottom, showsRowDivider ? 0 : -amount) }
}

private struct SettingsLastRowTrim<Content: View>: View {
    @Environment(\.showsRowDivider) private var showsRowDivider
    @ViewBuilder var content: Content

    var body: some View {
        content.frame(height: showsRowDivider ? nil : AppTheme.Component.profileRowHeight - AppTheme.Space.lg, alignment: .top)
    }
}

/// Row with a trailing compact time picker; time is stored as minutes after midnight.
private struct SettingsTimeRow: View {
    @Environment(\.palette) private var palette
    let title: String
    var icon: String?
    @Binding var minutes: Int

    var body: some View {
        HStack(spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.lg) {
                if let icon {
                    SettingsRowIcon(symbol: icon, tint: palette.ink)
                }
                Text(title)
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.ink)
            }
            Spacer(minLength: AppTheme.Space.md)
            DatePicker(title, selection: dateBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(palette.accent)
        }
        .frame(minHeight: AppTheme.Component.profileRowHeight)
        .overlay(alignment: .bottom) { SettingsDivider() }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(byAdding: .minute, value: minutes, to: Calendar.current.startOfDay(for: .now)) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}

/// Rosary settings: prayer text, scripture, optional prayers and intentions.
/// Changes also apply live to a Rosary in progress (see `RosarySequenceBuilder.remap`).
private struct SettingsRosaryScreen: View {
    @Environment(SettingsStore.self) private var settings
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings
        SettingsDetailScaffold(title: "Customise rosary") {
            VStack(alignment: .leading, spacing: 0) {
                DividedRows {
                    SettingsToggleRow(title: "Choose intentions", isOn: $settings.rosaryConfig.intentionsStep)
                }

                GuideSectionBoundary()

                SettingsSection(title: "Each decade", icon: "repeat") {
                    SettingsMenuRow(title: "Bible translation", value: settings.rosaryConfig.translation.title) {
                        Picker("Bible translation", selection: $settings.rosaryConfig.translation) {
                            ForEach(BibleTranslation.allCases) { translation in
                                Text(translation.title).tag(translation)
                            }
                        }
                    }
                    SettingsToggleRow(title: "Fatima prayer", isOn: $settings.rosaryConfig.fatimaPrayer)
                    SettingsToggleRow(title: "O Sacrament most holy", isOn: $settings.rosaryConfig.oSacrament)
                }

                GuideSectionBoundary()

                SettingsSection(title: "Closing prayers", icon: "moon.stars") {
                    SettingsToggleRow(title: "Hail, holy Queen", isOn: $settings.rosaryConfig.closingPrayers)
                    SettingsToggleRow(title: "Memorare", isOn: $settings.rosaryConfig.memorare)
                }

                // Same grey tertiary pill as "Complete decade" in the prayer flow.
                PillButton(title: "Reset to default", filled: false, tertiary: true) {
                    confirmReset = true
                }
                .padding(.top, AppTheme.Space.xl)
            }
        }
        .alert("Reset to default?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                // Same store as the toggles, so an open Rosary remaps live.
                settings.rosaryConfig = .default
            }
            Button("Cancel", role: .cancel) {}
        }
    }

}

private struct SettingsAcknowledgementsScreen: View {
    var body: some View {
        SettingsDetailScaffold(title: "Acknowledgements") {
            DividedRows {
                ForEach(LicenseCatalog.all) { entry in
                    SettingsNavigationRow(title: entry.name, destination: .license(entry.id))
                }
            }

            SettingsSection(title: "Scripture") {
                SettingsValueOnlyRow(title: "RSV-2CE", value: "Ignatius Press")
                SettingsValueOnlyRow(title: "Douay-Rheims (Challoner, 1899)", value: "Public domain")
                SettingsValueOnlyRow(title: "Clementine Vulgate", value: "Public domain")
            }
        }
    }
}

private struct SettingsLicenseScreen: View {
    @Environment(\.palette) private var palette
    let entry: LicenseEntry

    var body: some View {
        SettingsDetailScaffold(title: entry.name) {
            Text(LicenseText.reflow(entry.license))
                .font(AppTheme.TypeRole.settingsMeta)
                .foregroundStyle(palette.dim)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

/// A third-party package licence bundled in Licenses.json (generated by
/// scripts/generate_licenses.py from the Swift Package checkouts).
struct LicenseEntry: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let version: String
    let url: String
    let license: String
}

enum LicenseCatalog {
    static let all: [LicenseEntry] = {
        guard
            let url = Bundle.main.url(forResource: "Licenses", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([LicenseEntry].self, from: data)
        else { return [] }
        return entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()

    static func entry(id: String) -> LicenseEntry? {
        all.first { $0.id == id }
    }
}

/// Reflows hard-wrapped licence text for a proportional font: lines inside a
/// paragraph are joined, while titles, list items, separators and short
/// intentional breaks keep their own line. The source text is never altered.
enum LicenseText {
    private static let listMarker = try! Regex(#"^(\(?\d+[.)]|\([A-Za-z0-9]{1,4}\)|[A-Za-z][.)](?=\s)|[-*•])\s"#)
    private static let separator = try! Regex(#"^[=\-*_#~]{3,}$"#)

    static func reflow(_ raw: String) -> String {
        let lines = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let lengths = lines.filter { !$0.isEmpty }.map(\.count).sorted()
        guard !lengths.isEmpty else { return "" }
        // Typical wrap width, ignoring the odd overlong line.
        let wrapWidth = lengths[max(0, Int(Double(lengths.count) * 0.9) - 1)]
        let joinThreshold = Double(wrapWidth) * 0.65

        var paragraphs: [[String]] = []
        var current: [String] = []
        for line in lines {
            if line.isEmpty {
                if !current.isEmpty {
                    paragraphs.append(current)
                    current = []
                }
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty { paragraphs.append(current) }

        return paragraphs.map { paragraph in
            var result: [String] = []
            var previous = ""
            for line in paragraph {
                let joins = !result.isEmpty
                    && Double(previous.count) >= joinThreshold
                    && !previous.hasPrefix("Copyright")
                    && !isStandalone(line)
                    && !isStandalone(result[result.count - 1])
                    && line.firstMatch(of: listMarker) == nil
                if joins {
                    result[result.count - 1] += " " + line
                } else {
                    result.append(line)
                }
                previous = line
            }
            return result.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private static func isStandalone(_ line: String) -> Bool {
        line.hasPrefix("#") || line.wholeMatch(of: separator) != nil
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
