import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            @Bindable var settings = settings
            Form {
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
                } header: {
                    Text("Display")
                } footer: {
                    Text("English, Latin, or both stacked on every prayer. Appearance follows the system unless you lock light or dark.")
                }

                Section {
                    Toggle("Prayer to Saint Michael", isOn: $settings.includeSaintMichael)
                    Toggle("Haptics while praying", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Prayer")
                } footer: {
                    Text("When Saint Michael is on, his prayer follows the concluding collect and precedes the final Sign of the Cross. New rosaries pick up the setting; a resumed session keeps the sequence you started.")
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
                    Text("Traditional rosary prayers in English and Latin, the twenty mysteries, a seasonal calendar including Easter, and optional Saint Michael. Everything stays on this device. No account, no network.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Scripture excerpts are Douay–Rheims (public domain). Mystery fruits follow the common USCCB listing. Sacred art is placeholder stained glass until commissioned images are added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
