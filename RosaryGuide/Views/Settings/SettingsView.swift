import MessageUI
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

private enum SettingsDestination: Hashable {
    case account
    case notifications
    case aboutPremium
    case faqs
    case widgets
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

                        SettingsNavigationRow(title: "Notifications", icon: "bell", value: notificationsSummary, destination: .notifications)

                        if appIcon.supportsAlternateIcons {
                            AppIconChoices()
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

                    if auth.isSignedIn {
                        // sectionGap (44pt) above, same header as the other sections.
                        SettingsSection(title: "Manage account") {
                            SettingsActionRow(title: "Sign out", icon: "rectangle.portrait.and.arrow.right") {
                                auth.signOut()
                                dismiss()
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
        .alert("Delete prayer history?", isPresented: $confirmDeleteHistory) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                session.clearHistoryAndData()
                didDeleteHistory = true
            }
        } message: {
            Text("This clears your prayer progress and prayer history on this device and in your account. Your intentions and settings are not affected.")
        }
        .alert("Prayer history deleted", isPresented: $didDeleteHistory) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your prayer progress and prayer history have been deleted.")
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

    /// Main-row value: the reminder time, "On" for feast alerts only, or "Off".
    private var notificationsSummary: String {
        if settings.dailyReminderEnabled {
            let date = Calendar.current.date(
                byAdding: .minute,
                value: settings.dailyReminderMinutes,
                to: Calendar.current.startOfDay(for: .now)
            ) ?? .now
            return date.formatted(date: .omitted, time: .shortened)
        }
        return settings.feastAlertsEnabled ? "On" : "Off"
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
        case .account:
            SettingsAccountScreen(confirmDeleteHistory: $confirmDeleteHistory)
        case .aboutPremium:
            SettingsPremiumScreen(placeholderMessage: $placeholderMessage)
        case .faqs:
            SettingsFAQScreen()
        case .widgets:
            SettingsWidgetsScreen()
        case .notifications:
            SettingsNotificationsScreen()
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

/// The icon tiles picker (as before 7433662), as one flat row in General.
/// Picking an icon also records the synced appIcon preference
/// (AppIconService.onUserSelect -> SettingsStore.appIconChoice). Errors show as an alert
/// on SettingsView.
private struct AppIconChoices: View {
    @Environment(AppIconService.self) private var appIcon
    @Environment(\.palette) private var palette

    private let previewSize: CGFloat = 64
    private let tileSpacing = AppTheme.Space.md
    /// Leading edge of the "App icon" label: icon column + icon/label spacing.
    private let labelLeading = AppTheme.Space.xl + AppTheme.Space.lg
    @State private var tileRowWidth: CGFloat = 0

    /// Shifts the equal-width tile row right so the first tile's left edge meets
    /// the label's leading edge, without changing tile size or spacing.
    private var tileRowShift: CGFloat {
        guard tileRowWidth > 0 else { return 0 }
        let cellWidth = (tileRowWidth - tileSpacing * CGFloat(AppIconOption.allCases.count - 1))
            / CGFloat(AppIconOption.allCases.count)
        return max(0, labelLeading - (cellWidth - previewSize) / 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: AppTheme.Space.lg) {
                SettingsRowIcon(symbol: "app", tint: palette.ink)
                Text("App icon")
                    .font(AppTheme.TypeRole.settingsRow)
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
            }
            .accessibilityAddTraits(.isHeader)

            HStack(spacing: tileSpacing) {
                ForEach(AppIconOption.allCases) { option in
                    iconCell(option)
                }
            }
            .frame(maxWidth: .infinity)
            // Width stays the full row width (leading/trailing padding cancel), so
            // measuring here does not feed back into the shift.
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                tileRowWidth = width
            }
            .padding(.leading, tileRowShift)
            .padding(.trailing, -tileRowShift)
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

                SettingsActionRow(title: "Delete prayer history", icon: "trash", destructive: true) {
                    confirmDeleteHistory = true
                }
            }

            if !auth.isSignedIn, let message = auth.errorMessage {
                SettingsFootnote(message)
            }
        }
    }
}

/// The Settings Premium screen for pushing from outside Settings (e.g. the
/// Rosary Guide+ card on My prayer). Owns its own "Coming soon" alert, which
/// SettingsView otherwise provides.
struct PremiumScreen: View {
    /// Optional context line shown at the top (e.g. why the user landed here).
    var note: String? = nil
    @State private var placeholderMessage: String?

    var body: some View {
        SettingsPremiumScreen(placeholderMessage: $placeholderMessage, note: note)
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

private struct SettingsPremiumScreen: View {
    @Binding var placeholderMessage: String?
    var note: String? = nil

    var body: some View {
        SettingsDetailScaffold(title: "Premium") {
            if let note {
                SettingsFootnote(note)
            }

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

private struct SettingsNotificationsScreen: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var permissionWasDenied = false

    var body: some View {
        SettingsDetailScaffold(title: "Notifications") {
            VStack(spacing: 0) {
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
                VStack(alignment: .leading, spacing: 0) {
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
                VStack(alignment: .leading, spacing: 0) {
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
        .onChange(of: settings.notificationPlan) { _, plan in
            Task { await NotificationService.reschedule(plan) }
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

private struct SettingsAcknowledgementsScreen: View {
    var body: some View {
        SettingsDetailScaffold(title: "Acknowledgements") {
            VStack(spacing: 0) {
                ForEach(LicenseCatalog.all) { entry in
                    SettingsNavigationRow(title: entry.name, destination: .license(entry.id))
                }
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
