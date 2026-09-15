import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            @Bindable var settings = settings
            List {
                Section {
                    Picker("Prayer language", selection: $settings.language) {
                        ForEach(PrayerLanguage.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppearancePreference.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Text size", selection: $settings.textSize) {
                        Text("Small").tag(PrayerTextSize.small)
                        Text("Medium").tag(PrayerTextSize.medium)
                        Text("Large").tag(PrayerTextSize.large)
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("English, Latin, or both. Appearance follows the system unless you lock Light or Dark.")
                }

                Section {
                    Toggle("Prayer to Saint Michael after Finis", isOn: $settings.includeSaintMichael)
                    Toggle("Haptics while praying", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Prayer")
                } footer: {
                    Text("Saint Michael is offered after the rosary is finished. He is never inserted into the seven-stage sequence.")
                }

                if session.resumableSession != nil {
                    Section("Session") {
                        Button("Discard saved rosary", role: .destructive) {
                            session.discard()
                        }
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "Rosary Guide")
                    LabeledContent("Bundle ID", value: "com.shasasmith.RosaryGuide")
                    Text("Cream and ink prayer guide with the website’s paintings, Instrument Sans, Newsreader, and RSV-2CE mystery readings. Everything stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(palette.dim)
                }
            }
            .scrollContentBackground(.hidden)
            .guidePageChrome()
            .navigationTitle("Settings")
        }
    }
}
