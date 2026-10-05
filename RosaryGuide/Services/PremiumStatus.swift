import Foundation

/// Single source of truth for Rosary Guide+ entitlement and free-tier limits.
enum PremiumStatus {
    /// Whether the user has Rosary Guide+.
    /// TODO(StoreKit): back this with the real entitlement (StoreKit 2
    /// `Transaction.currentEntitlements`) and make it observable so views refresh
    /// on purchase/restore. Until subscriptions exist, everyone is on the free tier.
    static var isPremium: Bool { false }

    /// Most intentions a free user can keep. The Pope's (papal) intentions don't count;
    /// other suggestions do. Existing intentions over the limit are kept, only adding is blocked.
    static let freeIntentionLimit = 3
}
