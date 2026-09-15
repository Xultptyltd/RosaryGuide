import Foundation
import Observation

@Observable
final class SettingsStore {
    private enum Keys {
        static let language = "settings.language"
        static let appearance = "settings.appearance"
        static let saintMichael = "settings.includeSaintMichael"
        static let haptics = "settings.hapticsEnabled"
    }

    var language: PrayerLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var appearance: AppearancePreference {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var includeSaintMichael: Bool {
        didSet { UserDefaults.standard.set(includeSaintMichael, forKey: Keys.saintMichael) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    init(defaults: UserDefaults = .standard) {
        language = PrayerLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        appearance = AppearancePreference(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        includeSaintMichael = defaults.object(forKey: Keys.saintMichael) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }
}
