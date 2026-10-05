import Foundation
import Observation
import UIKit

enum AppIconOption: String, CaseIterable, Identifiable, Codable {
    case black
    case white
    case blue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .black: "Black"
        case .white: "White"
        case .blue: "Blue"
        }
    }

    /// `nil` restores the primary (Black) icon.
    var alternateIconName: String? {
        switch self {
        case .black: nil
        case .white: "AppIconWhite"
        case .blue: "AppIconBlue"
        }
    }

    var previewImageName: String {
        switch self {
        case .black: "IconPreviewBlack"
        case .white: "IconPreviewWhite"
        case .blue: "IconPreviewBlue"
        }
    }

    static func from(alternateIconName name: String?) -> AppIconOption {
        switch name {
        case "AppIconWhite": .white
        case "AppIconBlue": .blue
        default: .black
        }
    }
}

@Observable
final class AppIconService {
    private(set) var current: AppIconOption
    private(set) var lastErrorMessage: String?

    /// Called when the user picks an icon and iOS accepts it (not for synced changes).
    @ObservationIgnored var onUserSelect: ((AppIconOption) -> Void)?
    /// A synced choice waiting for the app to be in the foreground (iOS requires it).
    @ObservationIgnored private var pendingSynced: AppIconOption?

    var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    init() {
        current = AppIconOption.from(alternateIconName: UIApplication.shared.alternateIconName)
    }

    func select(_ option: AppIconOption) {
        lastErrorMessage = nil
        guard option != current else { return }

        if option.alternateIconName != nil, !supportsAlternateIcons {
            lastErrorMessage = "Alternate icons aren’t supported on this device."
            return
        }

        let previous = current
        current = option
        UIApplication.shared.setAlternateIconName(option.alternateIconName) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.current = previous
                    self.lastErrorMessage = error.localizedDescription
                } else {
                    self.current = AppIconOption.from(
                        alternateIconName: UIApplication.shared.alternateIconName
                    )
                    self.onUserSelect?(self.current)
                }
            }
        }
    }

    /// Applies the icon choice from the account. iOS shows its own short "icon changed" alert.
    func applySynced(_ option: AppIconOption) {
        refreshFromSystem()
        guard option != current else {
            pendingSynced = nil
            return
        }
        guard option.alternateIconName == nil || supportsAlternateIcons else { return }
        guard UIApplication.shared.applicationState == .active else {
            pendingSynced = option
            return
        }
        pendingSynced = nil
        UIApplication.shared.setAlternateIconName(option.alternateIconName) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshFromSystem()
            }
        }
    }

    func applyPendingSyncedIcon() {
        guard let pendingSynced else { return }
        applySynced(pendingSynced)
    }

    func clearError() {
        lastErrorMessage = nil
    }

    func refreshFromSystem() {
        current = AppIconOption.from(alternateIconName: UIApplication.shared.alternateIconName)
    }
}
