import Foundation
import Observation

/// Single source of truth for Rosary Guide+ entitlement and free-tier limits.
enum PremiumStatus {
    /// Whether the user has Rosary Guide+.
    /// TODO(StoreKit): back this with the real entitlement (StoreKit 2
    /// `Transaction.currentEntitlements`) and make it observable so views refresh
    /// on purchase/restore. Until subscriptions exist, everyone is on the free tier.
    /// Debug builds can flip it with the developer "Premium mode" switch on the
    /// Premium screen; release builds are always free.
    @MainActor
    static var isPremium: Bool {
        #if DEBUG
        PremiumDebugOverride.shared.isPremium
        #else
        false
        #endif
    }

    /// Most intentions a free user can keep. The Pope's (papal) intentions don't count;
    /// other suggestions do. Existing intentions over the limit are kept, only adding is blocked.
    static let freeIntentionLimit = 3
}

#if DEBUG
/// Developer-only "Premium mode" (Debug builds only). Observable, so anything reading
/// `PremiumStatus.isPremium` (e.g. `OfferStore.canAddIntention`, the Rosary Guide+
/// upsell) updates live; persisted in UserDefaults across launches.
@MainActor
@Observable
final class PremiumDebugOverride {
    static let shared = PremiumDebugOverride()
    private static let defaultsKey = "debug.premiumMode"

    var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: Self.defaultsKey) }
    }

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: Self.defaultsKey)
    }
}
#endif
