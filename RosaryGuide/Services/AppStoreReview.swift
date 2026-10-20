import Foundation
import StoreKit
import UIKit

/// App Store links, built from the one App Store Connect Apple ID.
enum AppStoreLinks {
    /// The numeric App Store Connect Apple ID (App Information > Apple ID).
    /// Empty until the listing exists; every App Store link is hidden while it is empty.
    static let appID = ""

    static var productPage: URL? {
        appID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appID)")
    }

    /// Opens the App Store's "Write a Review" sheet directly.
    static var writeReview: URL? {
        appID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }
}

/// When the system review prompt may be asked for: from the 3rd finished Rosary on,
/// at most once per app version.
struct ReviewPromptGate {
    static let minimumCompletedRosaries = 3
    static let lastPromptedVersionKey = "review.lastPromptedVersion"

    var defaults: UserDefaults = .standard
    var currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    func shouldPrompt(completedRosaries: Int) -> Bool {
        guard !currentVersion.isEmpty, completedRosaries >= Self.minimumCompletedRosaries else { return false }
        return defaults.string(forKey: Self.lastPromptedVersionKey) != currentVersion
    }

    func markPrompted() {
        defaults.set(currentVersion, forKey: Self.lastPromptedVersionKey)
    }
}

@MainActor
enum ReviewPrompter {
    /// Settle time on the completion screen before asking, so the prompt never lands mid-prayer
    /// or over the finishing animation.
    static let settleDelay: Duration = .seconds(2.5)

    /// Call from the completion screen's task. Cancelled (and nothing shown) if the screen goes
    /// away first; `isStillSettled` lets the caller veto it, e.g. while Saint Michael is open.
    static func requestAfterCompletion(
        completedRosaries: Int,
        gate: ReviewPromptGate = ReviewPromptGate(),
        isStillSettled: () -> Bool = { true }
    ) async {
        guard gate.shouldPrompt(completedRosaries: completedRosaries) else { return }
        try? await Task.sleep(for: settleDelay)
        guard !Task.isCancelled, isStillSettled() else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        gate.markPrompted()
        AppStore.requestReview(in: scene)
    }
}
