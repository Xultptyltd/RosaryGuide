import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette

    var body: some View {
        @Bindable var settings = settings

        List {
            Section {
                AccountManagementCard()
                    .listRowInsets(EdgeInsets(
                        top: AppTheme.Space.lg,
                        leading: AppTheme.Space.lg,
                        bottom: AppTheme.Space.md,
                        trailing: AppTheme.Space.lg
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                Picker(selection: $settings.language) {
                    ForEach(PrayerLanguage.allCases) { option in
                        Text(option.title)
                            .font(AppTheme.TypeRole.bodySmall)
                            .tag(option)
                    }
                } label: {
                    SettingsLabel(icon: "text.book.closed", title: "Prayer language")
                }

                Picker(selection: $settings.textSize) {
                    ForEach(PrayerTextSize.allCases) { option in
                        Text(option.title)
                            .font(AppTheme.TypeRole.bodySmall)
                            .tag(option)
                    }
                } label: {
                    SettingsLabel(icon: "textformat.size", title: "Text size")
                }

                Toggle(isOn: $settings.hapticsEnabled) {
                    SettingsLabel(icon: "hand.tap", title: "Haptics")
                }

                Toggle(isOn: $settings.includeSaintMichael) {
                    SettingsLabel(icon: "shield", title: "Saint Michael prayer")
                }
            } header: {
                SettingsSectionHeader(title: "Prayer")
            }

            Section {
                Picker(selection: $settings.appearance) {
                    ForEach(AppearancePreference.allCases) { option in
                        Text(option.title)
                            .font(AppTheme.TypeRole.bodySmall)
                            .tag(option)
                    }
                } label: {
                    SettingsLabel(icon: "circle.lefthalf.filled", title: "Theme")
                }

                AppIconPickerRow()
                    .listRowInsets(EdgeInsets(
                        top: AppTheme.Space.md,
                        leading: AppTheme.Space.lg,
                        bottom: AppTheme.Space.md,
                        trailing: AppTheme.Space.lg
                    ))
            } header: {
                SettingsSectionHeader(title: "Appearance")
            }

            if session.resumableSession != nil {
                Section {
                    Button(role: .destructive) {
                        session.discard()
                    } label: {
                        SettingsLabel(icon: "trash", title: "Discard saved Rosary", tint: .red)
                    }
            } header: {
                SettingsSectionHeader(title: "Session")
            }
            }

        }
        .listStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(
            top: AppTheme.Space.sm,
            leading: AppTheme.Space.lg,
            bottom: AppTheme.Space.sm,
            trailing: AppTheme.Space.lg
        ))
        .scrollContentBackground(.hidden)
        .background(palette.bg)
        .tint(palette.accent)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(palette.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

/// Placeholder account header — no account flow yet; Manage is a no-op.
private struct AccountManagementCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private let displayName = "Shasa"
    private let maskedEmail = "sh***@proton.me"
    private let avatarInitial = "S"
    private let avatarSize: CGFloat = 72

    var body: some View {
        VStack(spacing: AppTheme.Space.md) {
            ZStack {
                Circle()
                    .fill(palette.accentTint)
                Text(avatarInitial)
                    .font(AppTheme.sans(28, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(palette.accent)
            }
            .frame(width: avatarSize, height: avatarSize)
            .overlay {
                Circle()
                    .strokeBorder(
                        palette.ink.opacity(colorScheme == .light ? 0.06 : 0.14),
                        lineWidth: AppTheme.Component.panelStrokeWidth
                    )
            }
            .accessibilityHidden(true)

            VStack(spacing: AppTheme.Space.xs) {
                Text(displayName)
                    .font(AppTheme.sans(20, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(palette.ink)

                Text(maskedEmail)
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(palette.dim)
            }
            .multilineTextAlignment(.center)

            PillButton(title: "Manage my account", filled: false) {
                // Placeholder — account management flow not wired yet.
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Space.lg)
        .padding(.vertical, AppTheme.Space.xl)
        .guideCard(
            radius: AppTheme.containerRadius,
            fill: palette.panel,
            stroke: true,
            elevated: colorScheme == .light
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), \(maskedEmail)")
    }
}



private struct AppIconPickerRow: View {
    @Environment(AppIconService.self) private var appIcon
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private let previewSize: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            SettingsLabel(icon: "app.dashed", title: "App icon")

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
            }

            if let message = appIcon.lastErrorMessage {
                Text(message)
                    .font(AppTheme.TypeRole.themeSummary)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, AppTheme.Space.xs)
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
                                selected ? palette.accent : palette.ink.opacity(colorScheme == .light ? 0.08 : 0.16),
                                lineWidth: selected ? 2.5 : AppTheme.Component.panelStrokeWidth
                            )
                    }
                    .shadow(
                        color: selected ? palette.accent.opacity(0.28) : .clear,
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

private struct SettingsSectionHeader: View {
    @Environment(\.palette) private var palette
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.TypeRole.sectionLabel)
            .foregroundStyle(palette.dim)
    }
}

private struct SettingsLabel: View {
    @Environment(\.palette) private var palette
    let icon: String
    let title: String
    var tint: Color?

    var body: some View {
        Label {
            Text(title)
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(tint ?? palette.ink)
        } icon: {
            Image(systemName: icon)
                .guideSymbol(size: 20, weight: .regular)
                .foregroundStyle(tint ?? palette.ink)
                .frame(width: 28, alignment: .center)
        }
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
