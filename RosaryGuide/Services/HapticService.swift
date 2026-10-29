import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Plays the app's haptics. Generators are kept and re-prepared after each use so the next
/// tap lands on time (a fresh generator per tap can lag on the first bead).
@MainActor
enum HapticService {
    #if canImport(UIKit)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    #endif

    /// Warm the generators, e.g. when the Rosary opens.
    static func prepare(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        soft.prepare(); light.prepare(); medium.prepare(); notification.prepare()
        #endif
    }

    static func play(_ kind: HapticKind, enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        switch kind {
        case .soft:
            soft.impactOccurred(intensity: 0.7); soft.prepare()
        case .light:
            light.impactOccurred(); light.prepare()
        case .medium:
            medium.impactOccurred(); medium.prepare()
        case .heavy:
            heavy.impactOccurred()
        case .success:
            notification.notificationOccurred(.success); notification.prepare()
        case .warning:
            notification.notificationOccurred(.warning); notification.prepare()
        }
        #endif
    }

    /// Picker and segmented choices.
    static func selection(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        selectionGenerator.selectionChanged()
        #endif
    }
}
