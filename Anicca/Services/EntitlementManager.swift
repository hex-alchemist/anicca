import Foundation
import SwiftUI

@MainActor
final class EntitlementManager: ObservableObject {
    @Published private var _planTier: PlanTier = .free
 
    var planTier: PlanTier {
        get {
            if UserDefaults.standard.bool(forKey: "developer_override_pro") {
                return .pro
            }
            return _planTier
        }
        set {
            _planTier = newValue
            objectWillChange.send()
        }
    }
 
    var isPro: Bool { planTier == .pro || planTier == .bundle }
    var isBundle: Bool { planTier == .bundle }
 
    func setTier(_ tier: PlanTier) {
        self._planTier = tier
        objectWillChange.send()
    }
 
    @ViewBuilder
    func requiresPro<Content: View, Placeholder: View>(
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) -> some View {
        if isPro {
            content()
        } else {
            placeholder()
        }
    }
}

extension Notification.Name {
    static let planUpgraded = Notification.Name("anicca.planUpgraded")
}
