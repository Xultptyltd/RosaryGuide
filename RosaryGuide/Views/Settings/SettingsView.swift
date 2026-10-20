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
    case appIcon
    case legal(LegalDocumentKind)
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
        .guideDetailChrome("Settings")
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
                            SettingsNavigationRow(title: "App icon", icon: "app", destination: .appIcon)
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

                    if auth.isSignedIn, let message = sync.syncErrorMessage {
                        SyncNotice(message)
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
                        SettingsNavigationRow(title: "Terms of service", icon: "doc.text", destination: .legal(.terms))
                        SettingsNavigationRow(title: "Privacy", icon: "hand.raised", destination: .legal(.privacy))
                        SettingsNavigationRow(title: "Acknowledgements", icon: "heart", destination: .acknowledgements)
                    }

                    if auth.isSignedIn {
                        GuideSectionBoundary()
                        DividedRows {
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
        case .appIcon:
            SettingsAppIconScreen()
        case .legal(let document):
            SettingsLegalDocumentScreen(document: document)
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

/// Settings > App icon: a home screen preview with the chosen icon, then one flat card per
/// icon. Picking an icon also records the synced appIcon preference
/// (AppIconService.onUserSelect -> SettingsStore.appIconChoice).
private struct SettingsAppIconScreen: View {
    @Environment(AppIconService.self) private var appIcon
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette

    private let thumbnailSize: CGFloat = 56

    var body: some View {
        SettingsDetailScaffold(title: "App icon") {
            AppIconHomePreview(selected: appIcon.current)

            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                GuideSectionLabel(text: "Available", prominence: .strong)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: AppTheme.Space.sm) {
                    ForEach(AppIconOption.allCases) { option in
                        row(option)
                    }
                }
            }
        }
        .onAppear { appIcon.refreshFromSystem() }
        // Pushed pages don't show SettingsView's alerts, so surface errors here.
        .alert("App icon not changed", isPresented: Binding(
            get: { appIcon.lastErrorMessage != nil },
            set: { if !$0 { appIcon.clearError() } }
        )) {
            Button("OK", role: .cancel) { appIcon.clearError() }
        } message: {
            Text(appIcon.lastErrorMessage ?? "Try again.")
        }
    }

    private func row(_ option: AppIconOption) -> some View {
        let selected = appIcon.current == option
        return Button {
            guard !selected else { return }
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            appIcon.select(option)
        } label: {
            HStack(spacing: AppTheme.Space.lg) {
                AppIconThumbnail(option: option, size: thumbnailSize)
                Text(option.title)
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                Spacer(minLength: AppTheme.Space.sm)
                if selected {
                    Image(systemName: "checkmark")
                        .font(AppTheme.TypeRole.settingsRow.weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
            }
            .padding(AppTheme.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .guideCard()
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(option.title) app icon")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// An icon preview image with the home screen's continuous corner.
private struct AppIconThumbnail: View {
    @Environment(\.palette) private var palette
    let option: AppIconOption
    let size: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
        Image(option.previewImageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay { shape.strokeBorder(palette.selectionStroke, lineWidth: AppTheme.Component.panelStrokeWidth) }
    }
}

/// A phone outline, cropped at the bottom, showing the chosen icon as "Rosary Guide" in the
/// first slot beside neutral placeholder apps (plain tiles with SF Symbols).
private struct AppIconHomePreview: View {
    @Environment(\.palette) private var palette
    let selected: AppIconOption

    private let tile: CGFloat = 52
    private let visibleHeight: CGFloat = 236
    private static let placeholders: [(symbol: String, title: String)] = [
        ("calendar", "Calendar"), ("photo", "Photos"), ("camera", "Camera"),
        ("envelope", "Mail"), ("note.text", "Notes"), ("checklist", "Reminders"), ("clock", "Clock")
    ]

    var body: some View {
        let frameShape = UnevenRoundedRectangle(topLeadingRadius: 44, topTrailingRadius: 44, style: .continuous)
        let screenShape = UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36, style: .continuous)
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Space.md), count: 4)

        LazyVGrid(columns: columns, spacing: AppTheme.Space.lg) {
            slot(title: "Rosary Guide") { AppIconThumbnail(option: selected, size: tile) }
            ForEach(Self.placeholders, id: \.title) { app in
                slot(title: app.title) {
                    RoundedRectangle(cornerRadius: tile * 0.225, style: .continuous)
                        .fill(palette.surface)
                        .frame(width: tile, height: tile)
                        .overlay {
                            Image(systemName: app.symbol)
                                .font(.system(size: tile * 0.42, weight: .regular))
                                .foregroundStyle(palette.dim)
                        }
                }
            }
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.top, AppTheme.Space.xl)
        .frame(maxWidth: .infinity, minHeight: visibleHeight, alignment: .top)
        .background(palette.bg, in: screenShape)
        .clipShape(screenShape)
        .padding([.horizontal, .top], AppTheme.Space.sm)
        .overlay { frameShape.strokeBorder(palette.selectionStroke, lineWidth: 2) }
        .padding(.horizontal, AppTheme.Space.xl)
        .padding(.top, AppTheme.Space.lg)
        .frame(height: visibleHeight, alignment: .top)
        .clipped()
        .frame(maxWidth: .infinity)
        .guideCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Home screen preview with the \(selected.title) Rosary Guide icon")
    }

    private func slot<Icon: View>(title: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: AppTheme.Space.xs) {
            icon()
            Text(title)
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
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

// Full legal text retrieved from Xult on 20 October 2026; preserve wording.
private enum LegalDocumentKind: String, Hashable, Identifiable {
    case terms, privacy
    var id: String { rawValue }
    var title: String { self == .terms ? "Terms of service" : "Privacy" }
    struct Block: Identifiable {
        let id: Int
        let kind: String
        let text: String
    }
    var blocks: [Block] {
        switch self {
        case .terms: return [
            Block(id: 0, kind: "h1", text: "Terms of Use"),
            Block(id: 1, kind: "p", text: "These Terms of Use are a binding agreement between you and Xult. Please read them carefully, together with our [Privacy Policy](https://xult.ltd/privacy/)."),
            Block(id: 2, kind: "p", text: "Effective date: September 5, 2026 · Last updated: September 5, 2026"),
            Block(id: 3, kind: "p", text: "These Terms of Use (the “**Terms**”) constitute a legally binding agreement between you and Xult (“**Xult**,” “**we**,” “**us**,” or “**our**”) governing your access to and use of xult.ltd, xult.com, rosaryguide.app, the Rosary Guide iOS application, and related websites, content, and support channels (collectively, the “**Services**”)."),
            Block(id: 4, kind: "p", text: "By accessing or using the Services, you agree to these Terms and to the [Privacy Policy](https://xult.ltd/privacy/), which is incorporated by reference. If you do not agree, you may not use the Services. If you are under the age of majority where you live, you may use the Services only with the consent of a parent or legal guardian who agrees to these Terms on your behalf."),
            Block(id: 5, kind: "p", text: "**IMPORTANT:** Section 16 contains a binding arbitration agreement and a class-action waiver that affect your legal rights, except where prohibited by law and except if you opt out as described in that section."),
            Block(id: 6, kind: "h2", text: "1. The Services"),
            Block(id: 7, kind: "p", text: "Xult publishes software for personal prayer. **Rosary Guide** provides a bead-by-bead guide to the Holy Rosary, including mysteries associated with a given day, related Scripture and art, and related features described on the product pages. The Services are licensed, not sold, and are offered for your personal, non-commercial use unless we agree otherwise in a signed writing."),
            Block(id: 8, kind: "p", text: "We may modify, suspend, or discontinue all or any part of the Services at any time, with or without notice. We will use reasonable efforts not to remove core prayer texts without cause, but we do not warrant continuous availability, uninterrupted operation, or that any particular feature will remain available."),
            Block(id: 9, kind: "h2", text: "2. Eligibility and accounts"),
            Block(id: 10, kind: "p", text: "You represent that you have the legal capacity to enter into these Terms. If you use the Services on behalf of an organization, you represent that you have authority to bind that organization, in which case “you” includes that organization."),
            Block(id: 11, kind: "p", text: "The current web experience does not require an Xult account. If we later offer accounts or Sign in with Apple, you are responsible for all activity under your credentials, for maintaining their confidentiality, and for notifying us promptly of unauthorized use. We may refuse, suspend, or terminate access where we reasonably believe these Terms have been violated or that continued access presents a legal, security, or operational risk."),
            Block(id: 12, kind: "p", text: "The Services are not directed to children under thirteen (13) as an account product. Parents and guardians may use Rosary Guide with their families for personal devotion. See the [Privacy Policy](https://xult.ltd/privacy/) for how we treat children’s information."),
            Block(id: 13, kind: "h2", text: "3. License"),
            Block(id: 14, kind: "p", text: "Subject to your compliance with these Terms, Xult grants you a limited, revocable, non-exclusive, non-transferable, non-sublicensable license to access and use the Services for your personal, non-commercial purposes, and, for the iOS application, only on an Apple-branded device that you own or control, as permitted by the App Store Terms of Service and any applicable Usage Rules."),
            Block(id: 15, kind: "p", text: "Except as expressly permitted, you may not copy, modify, distribute, sell, lease, reverse engineer, decompile, or disassemble the Services or any substantial portion of their design, except to the extent such restriction is prohibited by applicable law. All rights not expressly granted are reserved by Xult and its licensors."),
            Block(id: 16, kind: "h2", text: "4. Spiritual, pastoral, and informational content"),
            Block(id: 17, kind: "p", text: "Prayers, mystery titles, feast designations, Scripture citations, sacred art, and similar materials are provided as a convenience for personal devotion. They are not a substitute for the teaching, sacraments, liturgy, or pastoral care of the Church, nor for the advice of a priest, deacon, spiritual director, or other qualified counselor."),
            Block(id: 18, kind: "p", text: "Mystery selections follow a traditional weekly cycle and, where implemented, certain Marian feasts. Calendars, local custom, and particular law vary. We do not warrant that any selection will match every diocese, rite, religious community, or personal custom. Traditional prayers may appear in commonly used English or Latin forms. Scripture may appear in short cited lines. If you believe a text is in error, notify us through the [Contact form](https://xult.ltd/contact/)."),
            Block(id: 19, kind: "p", text: "The Services are not medical, psychological, or mental-health services and are not intended to diagnose, treat, or prevent any condition. If you are in distress, seek appropriate professional or emergency help."),
            Block(id: 20, kind: "p", text: "Statements on our marketing pages about accessibility, design, or similar goals describe our intentions and are not warranties. Nothing in the Services constitutes a representation that the Services meet any particular accessibility certification or legal standard in every respect."),
            Block(id: 21, kind: "h2", text: "5. App Store and purchases"),
            Block(id: 22, kind: "p", text: "If you download Rosary Guide from the Apple App Store, Apple’s terms, including the Licensed Application End User License Agreement and the App Store Terms of Service, also apply. If those terms conflict with these Terms on a point required by Apple, Apple’s required terms control for that point as to the iOS application."),
            Block(id: 23, kind: "p", text: "If we offer paid features, they will be billed by Apple when purchased through the App Store. Prices, taxes, auto-renewal, free trials, and cancellation for App Store purchases are governed by Apple’s terms and your Apple ID settings. Refunds for App Store purchases are handled by Apple. We will assist where we reasonably can if you use the [Contact form](https://xult.ltd/contact/), but we cannot override Apple’s refund determinations."),
            Block(id: 24, kind: "p", text: "Unless a separate writing states otherwise, all sales are final except as required by Apple or by mandatory consumer law. We may change prices for future periods with notice as required by Apple or applicable law. A purchase grants a license to use the applicable feature, not ownership of the software."),
            Block(id: 25, kind: "h2", text: "6. Additional terms required by Apple"),
            Block(id: 26, kind: "p", text: "The following terms apply to the Rosary Guide application obtained from the Apple App Store (the “**App**”). “**Apple**” means Apple Inc. and, as applicable, its subsidiaries."),
            Block(id: 27, kind: "li", text: "1. These Terms are concluded between you and Xult only, and not with Apple. Apple is not responsible for the App or its content."),
            Block(id: 28, kind: "li", text: "2. The App is licensed to you on a limited, non-exclusive, non-transferable, non-sublicensable basis, solely for use in connection with the Services for your private, personal, non-commercial use, on Apple-branded products that you own or control, and as permitted by the Usage Rules set forth in the App Store Terms of Service (including as the App may be accessed and used by other accounts associated with you via Family Sharing or volume purchasing, if applicable)."),
            Block(id: 29, kind: "li", text: "3. Apple has no obligation to furnish any maintenance or support services with respect to the App. Xult is solely responsible for providing any support, as described at [xult.ltd/support](https://xult.ltd/support/)."),
            Block(id: 30, kind: "li", text: "4. To the extent any warranty applies and is not effectively disclaimed, if the App fails to conform to that warranty, you may notify Apple, and Apple may refund the purchase price (if any) of the App. To the maximum extent permitted by law, Apple has no other warranty obligation with respect to the App, and any other claims, losses, liabilities, damages, costs, or expenses attributable to any failure to conform to any warranty are Xult’s responsibility."),
            Block(id: 31, kind: "li", text: "5. Xult, not Apple, is responsible for addressing any claims by you or a third party relating to the App or your possession and use of the App, including product-liability claims, any claim that the App fails to conform to applicable legal or regulatory requirements, and claims arising under consumer-protection, privacy, or similar legislation."),
            Block(id: 32, kind: "li", text: "6. In the event of a third-party claim that the App or your possession and use of the App infringes that third party’s intellectual-property rights, Xult, not Apple, is responsible for the investigation, defense, settlement, and discharge of that claim, to the extent required by these Terms."),
            Block(id: 33, kind: "li", text: "7. You represent and warrant that you are not located in a country subject to a U.S. Government embargo or designated by the U.S. Government as a “terrorist supporting” country, and that you are not listed on any U.S. Government list of prohibited or restricted parties."),
            Block(id: 34, kind: "li", text: "8. You will comply with applicable third-party terms when using the App."),
            Block(id: 35, kind: "li", text: "9. Apple and Apple’s subsidiaries are third-party beneficiaries of these Terms as they relate to the App. Upon your acceptance of these Terms, Apple will have the right (and will be deemed to have accepted the right) to enforce these Terms against you as a third-party beneficiary."),
            Block(id: 36, kind: "h2", text: "7. Acceptable use"),
            Block(id: 37, kind: "p", text: "You agree that you will not, and will not permit others to:"),
            Block(id: 38, kind: "li", text: "• use the Services in violation of any applicable law, regulation, or third-party right;"),
            Block(id: 39, kind: "li", text: "• interfere with, disrupt, or attempt to gain unauthorized access to the Services, accounts, or related systems;"),
            Block(id: 40, kind: "li", text: "• probe, scan, or test the vulnerability of the Services, except with our prior written consent;"),
            Block(id: 41, kind: "li", text: "• introduce malware, or impose an unreasonable load on our infrastructure;"),
            Block(id: 42, kind: "li", text: "• scrape, crawl, harvest, or use automated means to extract content or data from the Services, except as allowed by a written robots protocol we publish or by mandatory law;"),
            Block(id: 43, kind: "li", text: "• copy, redistribute, publicly display, or create derivative works from the Services or their unique interface, except as permitted by these Terms or mandatory law;"),
            Block(id: 44, kind: "li", text: "• remove or alter proprietary notices;"),
            Block(id: 45, kind: "li", text: "• use the Services to send spam, phishing, or unlawful content;"),
            Block(id: 46, kind: "li", text: "• impersonate Xult or any other person or entity, or suggest that we endorse any product, service, or statement that we have not endorsed; or"),
            Block(id: 47, kind: "li", text: "• use the Services for any commercial purpose without our prior written consent."),
            Block(id: 48, kind: "p", text: "A violation of this section is grounds for immediate suspension or termination of access."),
            Block(id: 49, kind: "h2", text: "8. Intellectual property"),
            Block(id: 50, kind: "p", text: "The Services, including the Xult name and marks, site and application design, software, compilation, and original text and graphics, are owned by Xult or its licensors and are protected by copyright, trademark, and other laws. Traditional prayers and Scripture are not claimed as Xult’s original literary works. Where a translation, recording, or artwork is used under license or fair-use or similar doctrines, rights remain with the applicable rights holder."),
            Block(id: 51, kind: "p", text: "You may not use the Xult name, mark, or trade dress in a manner that is likely to cause confusion as to source, sponsorship, or affiliation. Feedback you send does not transfer ownership of your pre-existing intellectual property, but you grant the license in Section 9."),
            Block(id: 52, kind: "h2", text: "9. Communications and feedback"),
            Block(id: 53, kind: "p", text: "If you send ideas, suggestions, or other feedback, you grant Xult a perpetual, irrevocable, worldwide, royalty-free, transferable, and sublicensable license to use, reproduce, modify, and otherwise exploit that feedback for any purpose, without compensation or attribution, to the extent permitted by law. You represent that you have the right to grant that license and that the feedback does not infringe third-party rights."),
            Block(id: 54, kind: "p", text: "You are responsible for the content of messages you send to us. You represent that they are accurate to the best of your knowledge and that you have the right to send them. We may retain correspondence as described in the Privacy Policy."),
            Block(id: 55, kind: "h2", text: "10. Third-party services and links"),
            Block(id: 56, kind: "p", text: "The Services may link to or rely on third-party services, including Apple, hosting providers, form processors, and font or content-delivery networks. We do not control those services and are not responsible for their content, availability, or practices. Your use of third-party services is subject to their terms and privacy policies. We are not a party to your agreement with Apple or any other platform."),
            Block(id: 57, kind: "h2", text: "11. Copyright complaints"),
            Block(id: 58, kind: "p", text: "If you believe that material available through the Services infringes your copyright, send a notice that complies with the Digital Millennium Copyright Act, 17 U.S.C. § 512, through the [Contact form](https://xult.ltd/contact/), including: (a) a physical or electronic signature of a person authorized to act for the copyright owner; (b) identification of the copyrighted work; (c) identification of the material claimed to be infringing and information reasonably sufficient to permit us to locate it; (d) your contact information; (e) a statement that you have a good-faith belief that the use is not authorized by the owner, its agent, or the law; and (f) a statement, under penalty of perjury, that the information in the notice is accurate and that you are authorized to act for the owner."),
            Block(id: 59, kind: "p", text: "We may remove or disable access to material in appropriate circumstances and may terminate repeat infringers. If you believe material was removed by mistake, you may send a counter-notification meeting the statutory requirements to the same address."),
            Block(id: 60, kind: "h2", text: "12. Disclaimers"),
            Block(id: 61, kind: "p", text: "THE SERVICES AND ALL CONTENT ARE PROVIDED “AS IS” AND “AS AVAILABLE.” TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, XULT AND ITS OFFICERS, DIRECTORS, EMPLOYEES, CONTRACTORS, LICENSORS, AND SUPPLIERS (THE “**XULT PARTIES**”) DISCLAIM ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, QUIET ENJOYMENT, AND NON-INFRINGEMENT, AND ANY WARRANTIES ARISING FROM COURSE OF DEALING OR USAGE OF TRADE."),
            Block(id: 62, kind: "p", text: "THE XULT PARTIES DO NOT WARRANT THAT THE SERVICES WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE; THAT DEFECTS WILL BE CORRECTED; THAT MYSTERY SELECTIONS, FEAST DAYS, OR TEXTS WILL BE COMPLETE, CURRENT, OR CONSISTENT WITH EVERY LOCAL CUSTOM OR CALENDAR; OR THAT THE SERVICES WILL MEET YOUR REQUIREMENTS. YOU USE THE SERVICES AT YOUR OWN RISK."),
            Block(id: 63, kind: "p", text: "SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF CERTAIN WARRANTIES. IN THOSE JURISDICTIONS, THE FOREGOING EXCLUSIONS APPLY TO THE MAXIMUM EXTENT PERMITTED."),
            Block(id: 64, kind: "h2", text: "13. Limitation of liability"),
            Block(id: 65, kind: "p", text: "TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE XULT PARTIES WILL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES, OR FOR ANY LOSS OF PROFITS, REVENUE, DATA, GOODWILL, OR BUSINESS INTERRUPTION, ARISING OUT OF OR RELATED TO THE SERVICES OR THESE TERMS, WHETHER BASED IN CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY, OR ANY OTHER THEORY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES."),
            Block(id: 66, kind: "p", text: "TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE XULT PARTIES’ TOTAL LIABILITY FOR ALL CLAIMS ARISING OUT OF OR RELATED TO THE SERVICES OR THESE TERMS WILL NOT EXCEED THE GREATER OF (A) THE AMOUNTS YOU PAID TO XULT FOR THE SERVICES IN THE TWELVE (12) MONTHS BEFORE THE CLAIM OR (B) ONE HUNDRED U.S. DOLLARS (US $100). IF YOU HAVE PAID NOTHING TO XULT IN THAT PERIOD, YOUR SOLE AND EXCLUSIVE REMEDY IS TO STOP USING THE SERVICES."),
            Block(id: 67, kind: "p", text: "THE FOREGOING LIMITATIONS DO NOT APPLY TO LIABILITY THAT CANNOT BE LIMITED UNDER APPLICABLE LAW, INCLUDING LIABILITY FOR DEATH OR PERSONAL INJURY CAUSED BY NEGLIGENCE, OR FOR FRAUD OR FRAUDULENT MISREPRESENTATION, IN JURISDICTIONS WHERE SUCH LIMITATIONS ARE PROHIBITED. THEY ALSO DO NOT LIMIT ANY NON-WAIVABLE RIGHTS YOU MAY HAVE AS A CONSUMER IN YOUR COUNTRY OF RESIDENCE."),
            Block(id: 68, kind: "h2", text: "14. Indemnification"),
            Block(id: 69, kind: "p", text: "You will defend, indemnify, and hold harmless the Xult Parties from and against any claims, damages, losses, liabilities, costs, and expenses (including reasonable attorneys’ fees) arising out of or related to: (a) your use of the Services in violation of these Terms or applicable law; (b) content or information you submit to us; or (c) your infringement or misappropriation of a third party’s rights. We will use reasonable efforts to notify you of an indemnified claim using contact information you have provided. This obligation does not apply to the extent a claim is caused by the Xult Parties’ willful misconduct or gross negligence."),
            Block(id: 70, kind: "h2", text: "15. Termination"),
            Block(id: 71, kind: "p", text: "You may stop using the Services at any time. We may suspend or terminate access immediately if you materially breach these Terms, if we are required to do so by law, or if we discontinue the Services. Upon termination, the license in Section 3 ends. Sections that by their nature should survive (including 4, 6, 8–18) will survive."),
            Block(id: 72, kind: "h2", text: "16. Dispute resolution; arbitration; class-action waiver"),
            Block(id: 73, kind: "p", text: "Please read this section carefully. It requires binding individual arbitration of most disputes and waives class actions, except as stated below."),
            Block(id: 74, kind: "p", text: "**Informal resolution.** Before filing a claim, you and Xult agree to attempt in good faith to resolve the dispute informally. Use the [Contact form](https://xult.ltd/contact/), choose General, and include “Dispute” in the message with a description of the claim. If the dispute is not resolved within thirty (30) days after we receive a complete notice, either party may commence arbitration (or a permitted court action)."),
            Block(id: 75, kind: "p", text: "**Arbitration.** Except for the claims excluded below, any dispute, claim, or controversy arising out of or relating to these Terms or the Services, including their formation, interpretation, breach, or termination, will be resolved by binding arbitration administered by the American Arbitration Association (“**AAA**”) under its Consumer Arbitration Rules then in effect. The Federal Arbitration Act governs the interpretation and enforcement of this agreement to arbitrate. The arbitration will be conducted in English, by a single arbitrator, and may proceed by video or telephone. If an in-person hearing is required, it will be held in the United States county of your residence, or another mutually agreed location. Judgment on the award may be entered in any court of competent jurisdiction. For claims under US $75,000, we will pay AAA filing and arbitrator fees to the extent required by the AAA Consumer Rules, unless the arbitrator finds your claim frivolous."),
            Block(id: 76, kind: "p", text: "**Exceptions.** Either party may bring an individual action in small-claims court if the claim qualifies. Either party may seek injunctive or other equitable relief in any court of competent jurisdiction to prevent actual or threatened infringement, misappropriation, or violation of intellectual-property or proprietary rights. This arbitration agreement does not apply where prohibited by the mandatory consumer-protection laws of your country of residence (including, where applicable, the EEA and the United Kingdom)."),
            Block(id: 77, kind: "p", text: "**Class-action and jury waiver.** YOU AND XULT AGREE THAT EACH MAY BRING CLAIMS AGAINST THE OTHER ONLY IN AN INDIVIDUAL CAPACITY, AND NOT AS A PLAINTIFF OR CLASS MEMBER IN ANY PURPORTED CLASS, COLLECTIVE, CONSOLIDATED, OR REPRESENTATIVE PROCEEDING. IF THIS CLASS-ACTION WAIVER IS FOUND UNENFORCEABLE AS TO A PARTICULAR CLAIM, THEN THE ARBITRATION AGREEMENT WILL NOT APPLY TO THAT CLAIM, AND THAT CLAIM MUST BE BROUGHT IN COURT AS SET FORTH BELOW. TO THE EXTENT A CLAIM PROCEEDS IN COURT RATHER THAN IN ARBITRATION, YOU AND XULT WAIVE ANY RIGHT TO A JURY TRIAL TO THE MAXIMUM EXTENT PERMITTED BY LAW."),
            Block(id: 78, kind: "p", text: "**Opt-out.** You may opt out of this arbitration agreement through the [Contact form](https://xult.ltd/contact/) within thirty (30) days after you first accept these Terms, with your name, a contact email address, and a clear statement that you opt out of arbitration. If you opt out, or if this arbitration agreement does not apply, exclusive venue for judicial proceedings (other than qualifying small-claims actions, which may be brought in any court of competent jurisdiction) will be the state or federal courts located in the United States in the state of Xult’s principal place of business, and you and Xult consent to personal jurisdiction there, except that you may have additional rights to sue in your home jurisdiction that we will honor where required by law."),
            Block(id: 79, kind: "p", text: "This Section 16 will survive termination of these Terms. If the class-action waiver is found unenforceable and as a result the arbitration agreement is void as to a claim, the remainder of these Terms will remain in effect."),
            Block(id: 80, kind: "h2", text: "17. Governing law"),
            Block(id: 81, kind: "p", text: "These Terms are governed by the Federal Arbitration Act, applicable federal law of the United States, and, to the extent not preempted, the laws of the state of Xult’s principal place of business, without regard to conflict-of-laws rules. Mandatory consumer-protection laws of your country of residence remain unaffected."),
            Block(id: 82, kind: "h2", text: "18. General"),
            Block(id: 83, kind: "p", text: "**Entire agreement.** These Terms and the Privacy Policy are the entire agreement between you and Xult regarding the Services and supersede prior or contemporaneous agreements on that subject. Additional terms may apply to a specific feature if we present them to you; those terms control for that feature if they conflict with these Terms."),
            Block(id: 84, kind: "p", text: "**Changes.** We may revise these Terms from time to time. The “Last updated” date will change when we do. Material changes will be posted on this page and, where appropriate, noticed in the application or by email if we have your address. Except where applicable law requires a different method of acceptance, continued use after the effective date constitutes acceptance. If you do not agree, stop using the Services. The version in effect when we first received actual notice of a dispute will apply to that dispute."),
            Block(id: 85, kind: "p", text: "**Assignment.** You may not assign or transfer these Terms without our prior written consent. We may assign these Terms in connection with a merger, acquisition, corporate reorganization, or sale of assets, or by operation of law."),
            Block(id: 86, kind: "p", text: "**Severability and waiver.** If any provision is held unenforceable, it will be modified to the minimum extent necessary to make it enforceable, or if modification is not possible, severed, and the remaining provisions will remain in effect. A failure to enforce a provision is not a waiver."),
            Block(id: 87, kind: "p", text: "**Force majeure.** We are not liable for delay or failure caused by events beyond our reasonable control, including acts of God, labor disputes, failures of third-party networks or platforms (including Apple), or governmental action."),
            Block(id: 88, kind: "p", text: "**Export.** You will not use, export, or re-export the Services except as authorized by United States law and the laws of the jurisdiction in which the Services were obtained."),
            Block(id: 89, kind: "p", text: "**Notices.** We may provide notices by posting to the Services or by email to an address you have provided. Notices to Xult must be sent through the [Contact form](https://xult.ltd/contact/)."),
            Block(id: 90, kind: "p", text: "**No third-party beneficiaries.** Except for Apple and Apple’s subsidiaries as stated in Section 6, and except for the Xult Parties with respect to the disclaimer, limitation, and indemnity provisions, these Terms create no third-party beneficiary rights."),
            Block(id: 91, kind: "p", text: "**Interpretation.** Headings are for convenience only. “Including” means “including without limitation.” These Terms do not create a partnership, joint venture, or employment relationship."),
            Block(id: 92, kind: "p", text: "**Government rights.** If you are a U.S. government end user, the Services are “commercial computer software” and “commercial computer software documentation” as those terms are used in 48 C.F.R. § 12.212, and are provided with only those rights customarily provided to the public under these Terms."),
            Block(id: 93, kind: "h2", text: "19. Contact"),
            Block(id: 94, kind: "p", text: "Xult [Support](https://xult.ltd/contact/)"),
        ]
        case .privacy: return [
            Block(id: 0, kind: "h1", text: "Privacy Policy"),
            Block(id: 1, kind: "p", text: "This Privacy Policy describes how Xult collects, uses, discloses, and protects information in connection with the Services. Please read it together with our [Terms of Use](https://xult.ltd/terms/)."),
            Block(id: 2, kind: "p", text: "Effective date: September 5, 2026 · Last updated: September 5, 2026"),
            Block(id: 3, kind: "p", text: "Xult (“**Xult**,” “**we**,” “**us**,” or “**our**”) operates [xult.ltd](https://xult.ltd/) and [xult.com](https://xult.com/), publishes **Rosary Guide** at [rosaryguide.app](https://rosaryguide.app/), and is the developer of the Rosary Guide application distributed through the Apple App Store (together with related pages and support channels, the “**Services**”)."),
            Block(id: 4, kind: "p", text: "This Privacy Policy applies to Personal Data we process as a controller when you visit our websites, use Rosary Guide, contact us, or otherwise interact with the Services. It does not govern Apple, Formsubmit, Google, hosting providers, or other independent third parties, each of which processes information under its own terms and policies."),
            Block(id: 5, kind: "p", text: "We do **not** sell Personal Data. We do not share Personal Data for cross-context behavioral advertising. We do not use prayer activity to build advertising profiles. We do not require an account to pray with the current web experience."),
            Block(id: 6, kind: "p", text: "Questions and privacy requests: use the [Contact form](https://xult.ltd/contact/)."),
            Block(id: 7, kind: "h2", text: "1. Definitions"),
            Block(id: 8, kind: "p", text: "“**Personal Data**” means information that identifies, relates to, describes, or could reasonably be linked with an individual, and includes “personal information” and “personally identifiable information” under applicable law."),
            Block(id: 9, kind: "p", text: "“**Process**” means any operation performed on Personal Data, including collection, storage, use, disclosure, and deletion."),
            Block(id: 10, kind: "p", text: "“**Service Providers**” (also called processors) are parties that Process Personal Data on our behalf under instructions, solely to provide services to us."),
            Block(id: 11, kind: "h2", text: "2. Categories of Personal Data we collect"),
            Block(id: 12, kind: "p", text: "The categories below describe Personal Data we collect and have collected in the preceding twelve (12) months, the purposes, typical examples, and the categories of recipients."),
            Block(id: 13, kind: "h3", text: "Identifiers and contact data"),
            Block(id: 14, kind: "p", text: "**Examples:** name, email address, and the contents of a support or contact message, if you write to us or use the contact form. **Purpose:** to respond, keep a record of the correspondence, and handle privacy or legal requests. **Recipients:** Service Providers that host email or process forms (including Formsubmit, which receives submissions from the contact form); Xult personnel who handle the request."),
            Block(id: 15, kind: "h3", text: "Internet, device, and technical data"),
            Block(id: 16, kind: "p", text: "**Examples:** IP address, browser or operating-system type, device type, language, referring URL, requested pages, and timestamps. **Purpose:** to operate, secure, and diagnose the Services, prevent abuse, and keep hosting available. **Recipients:** hosting and content-delivery Service Providers. Our sites load fonts from Google Fonts; Google may receive your IP address and related technical data when those fonts are requested, under Google’s policies."),
            Block(id: 17, kind: "h3", text: "Device preferences stored locally"),
            Block(id: 18, kind: "p", text: "**Examples:** a light- or dark-theme preference stored in your browser’s local storage on xult.ltd and xult.com. **Purpose:** to remember your display preference. **Recipients:** none. This value remains on your device and is not used to identify you across sites."),
            Block(id: 19, kind: "h3", text: "On-device application state"),
            Block(id: 20, kind: "p", text: "**Examples:** prayer progress and similar state that Rosary Guide is designed to keep on your device. **Purpose:** to provide the guide. **Recipients:** none, unless a future version transmits such data, in which case we will update this Policy before collecting new categories."),
            Block(id: 21, kind: "h3", text: "Commercial and transaction data (if you purchase through Apple)"),
            Block(id: 22, kind: "p", text: "**Examples:** limited purchase or subscription status (for example, that a product was purchased) that Apple may provide so we can honor entitlements. **Purpose:** to fulfill and restore App Store purchases. **Recipients:** Apple. We do not receive your full payment-card number. Apple’s processing is governed by Apple’s terms and privacy policy."),
            Block(id: 23, kind: "h3", text: "Inferences, advertising, and precise location"),
            Block(id: 24, kind: "p", text: "We do not collect precise geolocation. We do not create advertising profiles. We do not sell or share Personal Data with data brokers or advertising networks."),
            Block(id: 25, kind: "h3", text: "Sensitive Personal Data"),
            Block(id: 26, kind: "p", text: "We do not require you to provide religious affiliation, health information, or other sensitive Personal Data as a condition of using Rosary Guide. If you include religious, spiritual, or other sensitive details in a message to us, we Process that content only to handle your request. We do not collect or Process sensitive Personal Data for the purpose of inferring characteristics about you, and we do not use or disclose sensitive Personal Data except for purposes permitted under applicable law (including California Civil Code regulations section 7027(m), where applicable)."),
            Block(id: 27, kind: "h2", text: "3. Sources"),
            Block(id: 28, kind: "p", text: "We collect Personal Data:"),
            Block(id: 29, kind: "li", text: "• directly from you, when you submit the contact form or otherwise communicate with us;"),
            Block(id: 30, kind: "li", text: "• automatically from your device and browser when you use the Services (and from Service Providers that operate our infrastructure); and"),
            Block(id: 31, kind: "li", text: "• from Apple, if you download, purchase, or use the iOS application through the App Store."),
            Block(id: 32, kind: "h2", text: "4. How we use Personal Data"),
            Block(id: 33, kind: "p", text: "We use Personal Data to:"),
            Block(id: 34, kind: "li", text: "• provide, operate, maintain, and secure the Services;"),
            Block(id: 35, kind: "li", text: "• respond to support, privacy, press, and other inquiries;"),
            Block(id: 36, kind: "li", text: "• honor App Store purchases and restore entitlements;"),
            Block(id: 37, kind: "li", text: "• detect, investigate, and prevent fraud, abuse, and security incidents;"),
            Block(id: 38, kind: "li", text: "• comply with law, enforce our Terms of Use, and protect the rights, property, and safety of Xult, users, and others; and"),
            Block(id: 39, kind: "li", text: "• establish, exercise, or defend legal claims."),
            Block(id: 40, kind: "p", text: "If we intend to Process Personal Data for a new purpose that is materially different, unrelated, or incompatible with the purposes described here, we will provide notice as described in Section 14 and, where required, obtain consent."),
            Block(id: 41, kind: "p", text: "We do not engage in automated decision-making that produces legal or similarly significant effects concerning you."),
            Block(id: 42, kind: "h2", text: "5. Legal bases (EEA, United Kingdom, and Switzerland)"),
            Block(id: 43, kind: "p", text: "Where the GDPR, UK GDPR, or Swiss law applies, we Process Personal Data on the following bases:"),
            Block(id: 44, kind: "li", text: "• **Contract.** To provide the Services you request and to respond to support you initiate (Art. 6(1)(b) GDPR)."),
            Block(id: 45, kind: "li", text: "• **Legitimate interests.** To operate and secure the Services, prevent abuse, improve reliability, and communicate about requests you have made, where those interests are not overridden by your rights (Art. 6(1)(f))."),
            Block(id: 46, kind: "li", text: "• **Legal obligation.** To comply with applicable law, including responding to lawful requests (Art. 6(1)(c))."),
            Block(id: 47, kind: "li", text: "• **Consent.** Where we ask for it, or where you voluntarily send us information that we would not otherwise collect (Art. 6(1)(a)). You may withdraw consent at any time without affecting the lawfulness of Processing before withdrawal."),
            Block(id: 48, kind: "p", text: "If a message you send includes special-category data (for example, information about religious belief), we Process it only as needed to handle your request, typically on the basis of your explicit consent by sending the communication, or as otherwise permitted by Art. 9 GDPR."),
            Block(id: 49, kind: "h2", text: "6. Disclosure"),
            Block(id: 50, kind: "p", text: "We disclose Personal Data only as follows:"),
            Block(id: 51, kind: "li", text: "• **Service Providers.** Hosting, content delivery, email, and form-processing providers, including Formsubmit for the website contact form. They may Process Personal Data only to perform services for us."),
            Block(id: 52, kind: "li", text: "• **Apple.** When you download, purchase, or use the iOS application through the App Store."),
            Block(id: 53, kind: "li", text: "• **Professional advisers and authorities.** Counsel, auditors, or public authorities where we are legally required to disclose information, or where disclosure is necessary to protect against serious harm, fraud, or abuse."),
            Block(id: 54, kind: "li", text: "• **Business transfers.** If we sell, merge, reorganize, or transfer all or part of our business, Personal Data may transfer to the successor as part of that transaction, subject to this Policy or a successor policy providing equivalent protection. We will use reasonable efforts to provide notice before your information becomes subject to a materially different policy."),
            Block(id: 55, kind: "p", text: "We may create aggregated, de-identified, or anonymized data that cannot reasonably identify you, and we may use and disclose that data for lawful purposes, including analysis and improvement of the Services."),
            Block(id: 56, kind: "h2", text: "7. Retention"),
            Block(id: 57, kind: "p", text: "We retain Personal Data only as long as reasonably necessary for the purposes described in this Policy, including to complete a support conversation, comply with legal or security obligations, resolve disputes, and enforce agreements."),
            Block(id: 58, kind: "p", text: "As a general practice: support emails and form submissions are retained for the duration of the matter and typically up to two (2) years thereafter, unless a longer period is required by law or needed to address a security or legal issue; server logs are retained on our host’s ordinary rotation schedule; local-storage preferences remain until you clear site data; and on-device application state remains on your device until you delete the application or clear its data."),
            Block(id: 59, kind: "p", text: "When retention ends, we delete or de-identify Personal Data, except where we must keep a limited record to comply with law."),
            Block(id: 60, kind: "h2", text: "8. Security"),
            Block(id: 61, kind: "p", text: "We implement administrative, technical, and organizational measures appropriate to the nature of the Personal Data we Process, including transmission over HTTPS and access limited to personnel and Service Providers who need it. No method of transmission or storage is completely secure. You use the Services at your own risk. If we become aware of a breach affecting your Personal Data, we will notify you and regulators as required by applicable law. If you believe your information has been compromised, use the [Contact form](https://xult.ltd/contact/)."),
            Block(id: 62, kind: "h2", text: "9. Children"),
            Block(id: 63, kind: "p", text: "Rosary Guide may be used by families for personal devotion. We do not knowingly collect Personal Data from children under thirteen (13) years of age in the United States (or under sixteen (16) in the European Economic Area or United Kingdom, or the age of digital consent in the child’s country) for marketing, profiling, or account creation. The current web experience does not require an Xult account."),
            Block(id: 64, kind: "p", text: "If you are a parent or guardian and believe a child has provided Personal Data to us, use the [Contact form](https://xult.ltd/contact/). We will delete the information, except where we must retain a limited record to comply with law. We do not sell or share the Personal Data of consumers we know to be under sixteen (16)."),
            Block(id: 65, kind: "h2", text: "10. Your privacy rights"),
            Block(id: 66, kind: "p", text: "Depending on where you live, you may have the right to:"),
            Block(id: 67, kind: "li", text: "• know, access, and receive a copy of Personal Data we hold about you;"),
            Block(id: 68, kind: "li", text: "• correct inaccurate Personal Data;"),
            Block(id: 69, kind: "li", text: "• delete Personal Data, subject to legal exceptions;"),
            Block(id: 70, kind: "li", text: "• export Personal Data in a portable format;"),
            Block(id: 71, kind: "li", text: "• opt out of sale or sharing of Personal Data (we do not sell or share);"),
            Block(id: 72, kind: "li", text: "• limit use and disclosure of sensitive Personal Data (we do not use it to infer characteristics);"),
            Block(id: 73, kind: "li", text: "• object to or restrict certain Processing;"),
            Block(id: 74, kind: "li", text: "• withdraw consent where Processing is based on consent;"),
            Block(id: 75, kind: "li", text: "• appeal a denial of a request; and"),
            Block(id: 76, kind: "li", text: "• lodge a complaint with a supervisory authority (for example, your EU or UK data-protection authority)."),
            Block(id: 77, kind: "p", text: "To exercise these rights, use the [Contact form](https://xult.ltd/contact/) and include an address we can reasonably associate with the request. We may need additional information to verify your identity. You may use an authorized agent where the law permits; we may require proof of authorization and identity. We will not discriminate against you for exercising these rights."),
            Block(id: 78, kind: "p", text: "We will respond within the time required by applicable law (generally forty-five (45) days under California law, extendable as permitted, and one (1) month under the GDPR, extendable as permitted). If we deny a request, we will explain the reasons and how to appeal, where an appeal right applies."),
            Block(id: 79, kind: "h3", text: "California and other U.S. state privacy laws"),
            Block(id: 80, kind: "p", text: "Residents of California and of other U.S. states with comprehensive privacy laws (including, as applicable, Virginia, Colorado, Connecticut, Utah, Texas, Oregon, Montana, Delaware, Iowa, Nebraska, New Hampshire, New Jersey, Tennessee, Minnesota, Maryland, and similar enactments) have the rights described above to the extent provided by those laws."),
            Block(id: 81, kind: "p", text: "In the preceding twelve (12) months we have not sold Personal Data and have not shared Personal Data for cross-context behavioral advertising. We have no actual knowledge of selling or sharing Personal Data of consumers under sixteen (16). We do not use or disclose sensitive Personal Data for purposes other than those permitted by law for providing the Services, security, and short-term transient use."),
            Block(id: 82, kind: "p", text: "California residents may also request information about our disclosure of Personal Data to third parties for those parties’ direct marketing, under California’s “Shine the Light” law. We do not make such disclosures. Requests may be sent through the [Contact form](https://xult.ltd/contact/)."),
            Block(id: 83, kind: "h2", text: "11. International transfers"),
            Block(id: 84, kind: "p", text: "Xult is based in the United States. If you use the Services from another country, your Personal Data may be Processed in the United States and in other countries where our Service Providers operate. Those countries may not provide the same level of data protection as your home country."),
            Block(id: 85, kind: "p", text: "Where required, we rely on transfer mechanisms recognized under applicable law, which may include Standard Contractual Clauses approved by the European Commission, the UK International Data Transfer Addendum, an adequacy decision, or another lawful mechanism."),
            Block(id: 86, kind: "h2", text: "12. Cookies, local storage, and signals"),
            Block(id: 87, kind: "p", text: "The Xult website uses local storage to remember your theme preference. We do not currently use advertising cookies or cross-site tracking pixels on xult.ltd or xult.com. Third parties we load for functionality (including Google Fonts) may set or read their own cookies or receive technical data as described in their policies."),
            Block(id: 88, kind: "p", text: "Our sites do not currently respond to browser Do Not Track signals. Where a legally recognized opt-out preference signal such as the Global Privacy Control is required to be honored as a request to opt out of sale or sharing, we will treat it as such. Because we do not sell or share Personal Data for cross-context advertising, no additional action is required for that purpose."),
            Block(id: 89, kind: "h2", text: "13. Third-party sites and services"),
            Block(id: 90, kind: "p", text: "The Services may link to third-party sites, including rosaryguide.app (when operated as a separate origin), Apple’s App Store, and other resources. We are not responsible for the privacy practices of those third parties. Review their policies before providing them information."),
            Block(id: 91, kind: "h2", text: "14. Changes"),
            Block(id: 92, kind: "p", text: "We may update this Privacy Policy from time to time. The “Last updated” date will change when we do. If we make a material change, we will provide additional notice as appropriate, such as a notice on the website or in the application. Your continued use of the Services after the effective date of a revised Policy constitutes acceptance of the revised Policy, except where applicable law requires a different method of consent. If you do not agree, discontinue use of the Services and use the [Contact form](https://xult.ltd/contact/) to exercise applicable deletion rights."),
            Block(id: 93, kind: "h2", text: "15. Contact"),
            Block(id: 94, kind: "p", text: "The data controller is Xult. [Support](https://xult.ltd/contact/)"),
            Block(id: 95, kind: "p", text: "If you are in the EEA, United Kingdom, or Switzerland, you may also lodge a complaint with your local supervisory authority. We invite you to use the [Contact form](https://xult.ltd/contact/) first so that we may attempt to resolve the matter."),
        ]
        }
    }
}

private struct SettingsLegalDocumentScreen: View {
    @Environment(\.palette) private var palette
    let document: LegalDocumentKind
    @State private var relatedDocument: LegalDocumentKind?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                ForEach(document.blocks) { block in
                    Text(attributed(block.text))
                        .font(font(for: block.kind))
                        .foregroundStyle(palette.ink)
                        .lineSpacing(AppTheme.Space.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, block.kind == "h2" ? AppTheme.Space.lg : 0)
                        .accessibilityAddTraits(isHeading(block.kind) ? .isHeader : [])
                }
            }
            .textSelection(.enabled)
            .frame(maxWidth: 640, alignment: .leading)
            .padding(.horizontal, AppTheme.gutter)
            .frame(maxWidth: .infinity)
            .padding(.top, GuideDetailChrome.contentTop)
            .padding(.bottom, AppTheme.tabBarContentClearance)
        }
        .background(palette.bg)
        .tint(palette.ink)
        .guideDetailChrome(document.title)
        .navigationDestination(item: $relatedDocument) { SettingsLegalDocumentScreen(document: $0) }
        .environment(\.openURL, OpenURLAction { url in
            if ["xult.ltd", "www.xult.ltd"].contains(url.host ?? "") {
                if url.path.hasPrefix("/terms") { relatedDocument = .terms; return .handled }
                if url.path.hasPrefix("/privacy") { relatedDocument = .privacy; return .handled }
            }
            return .systemAction
        })
    }

    private func isHeading(_ kind: String) -> Bool { ["h1", "h2", "h3"].contains(kind) }

    private func font(for kind: String) -> Font {
        switch kind {
        case "h1": AppTheme.TypeRole.screenTitle
        case "h2", "h3": AppTheme.TypeRole.headline
        default: AppTheme.TypeRole.bodySmall
        }
    }

    private func attributed(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}
