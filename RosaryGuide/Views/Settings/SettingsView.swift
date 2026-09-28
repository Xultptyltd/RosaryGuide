import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Prayer") {
                Picker(selection: $settings.language) {
                    ForEach(PrayerLanguage.allCases) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    SettingsLabel(icon: "text.book.closed", title: "Prayer language")
                }

                Picker(selection: $settings.textSize) {
                    ForEach(PrayerTextSize.allCases) { option in
                        Text(option.title).tag(option)
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
            }

            Section("Appearance") {
                Picker(selection: $settings.appearance) {
                    ForEach(AppearancePreference.allCases) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    SettingsLabel(icon: "circle.lefthalf.filled", title: "Theme")
                }
            }

            if session.resumableSession != nil {
                Section("Session") {
                    Button(role: .destructive) {
                        session.discard()
                    } label: {
                        SettingsLabel(icon: "trash", title: "Discard saved Rosary", tint: .red)
                    }
                }
            }

            Section("About") {
                LabeledContent {
                    Text("Rosary Guide")
                        .foregroundStyle(palette.dim)
                } label: {
                    SettingsLabel(icon: "app", title: "App")
                }

                LabeledContent {
                    Text("com.shasasmith.RosaryGuide")
                        .foregroundStyle(palette.dim)
                        .textSelection(.enabled)
                } label: {
                    SettingsLabel(icon: "number", title: "Bundle ID")
                }

                Text("A private prayer guide for learning and praying the Rosary. Everything stays on this device.")
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(5)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(palette.bg)
        .tint(palette.accent)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(palette.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                .font(AppTheme.TypeRole.body)
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
