import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum HapticService {
    static func play(_ kind: HapticKind, enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }
}
