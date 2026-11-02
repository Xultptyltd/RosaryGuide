import Foundation
import StoreKit
import UIKit

/// App Store links, built from the one App Store Connect Apple ID.
enum AppStoreLinks {
    /// The numeric App Store Connect Apple ID (App Information > Apple ID).
    /// If this is ever emptied, every App Store link hides itself.
    static let appID = "6814299309"

    static var productPage: URL? {
        appID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appID)")
    }

    /// Opens the App Store's "Write a Review" sheet directly.
    static var writeReview: URL? {
        appID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }
}

/// When to ask for a review, after finished Rosaries (completions, never starts):
/// first at the 3rd. "Not now" asks once more at the 10th (or, for someone already past 10
/// when first asked, as many Rosaries later as 3 is from 10), then never. "Leave a review"
/// never asks again. Stored on this device only. No sentiment gating.
struct ReviewPromptGate {
    static let firstAskAt = 3
    static let secondAskAt = 10
    static let timesAskedKey = "review.timesAsked"
    static let firstAskedAtKey = "review.firstAskedAtCompletedRosaries"
    static let leftReviewKey = "review.leftReview"

    var defaults: UserDefaults = .standard

    func shouldPrompt(completedRosaries: Int) -> Bool {
        guard !defaults.bool(forKey: Self.leftReviewKey) else { return false }
        switch defaults.integer(forKey: Self.timesAskedKey) {
        case 0:
            return completedRosaries >= Self.firstAskAt
        case 1:
            let firstAskedAt = defaults.integer(forKey: Self.firstAskedAtKey)
            let gap = Self.secondAskAt - Self.firstAskAt
            return completedRosaries >= max(Self.secondAskAt, firstAskedAt + gap)
        default:
            return false
        }
    }

    /// The alert was shown at this many finished Rosaries.
    func markAsked(completedRosaries: Int) {
        let times = defaults.integer(forKey: Self.timesAskedKey)
        if times == 0 { defaults.set(completedRosaries, forKey: Self.firstAskedAtKey) }
        defaults.set(times + 1, forKey: Self.timesAskedKey)
    }

    func markLeftReview() {
        defaults.set(true, forKey: Self.leftReviewKey)
    }
}

/// Copy for the review alert (a native system alert on the completion screen).
enum ReviewPromptCopy {
    static let title = "Help others discover the Rosary"
    static let message = "Your review helps others find Rosary Guide and make time for prayer."
    static let leaveReview = "Leave a review"
    static let notNow = "Not now"
}

@MainActor
enum ReviewPrompter {
    /// Wait on the completion screen before asking: its entrance (about 1 s) plus about 1 s
    /// settled, so the alert never lands mid-prayer or over the finishing animation.
    static let settleDelay: Duration = .seconds(2)

    /// Call from the completion screen's task; true means show the alert now (it is then
    /// counted as asked). Cancelled, and nothing asked, if the screen goes away first;
    /// `isStillSettled` lets the caller veto it, e.g. while Saint Michael is open. The count
    /// is read after the wait, once this Rosary has been recorded.
    static func shouldAskAfterSettling(
        completedRosaries: () -> Int,
        gate: ReviewPromptGate = ReviewPromptGate(),
        isStillSettled: () -> Bool = { true }
    ) async -> Bool {
        try? await Task.sleep(for: settleDelay)
        guard !Task.isCancelled, isStillSettled() else { return false }
        let completed = completedRosaries()
        guard gate.shouldPrompt(completedRosaries: completed) else { return false }
        gate.markAsked(completedRosaries: completed)
        return true
    }

    /// "Leave a review": the App Store's write-a-review page, never asked again. Without an
    /// App Store ID, the system review prompt instead.
    static func leaveReview(gate: ReviewPromptGate = ReviewPromptGate()) {
        gate.markLeftReview()
        if let url = AppStoreLinks.writeReview {
            UIApplication.shared.open(url)
        } else if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            AppStore.requestReview(in: scene)
        }
    }
}
