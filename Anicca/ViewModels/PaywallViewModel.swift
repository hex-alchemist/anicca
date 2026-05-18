import Foundation
import RevenueCat

enum SubscriptionInterval: String {
    case monthly
    case annual
}

enum SelectedPlan: String {
    case pro
    case bundle
}

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedInterval: SubscriptionInterval = .annual
    @Published var isWorking: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseCompleted: Bool = false

    @Published var packages: [Package] = []

    private let revenueCat = RevenueCatService.shared
    private let auth = AuthService.shared

    var proMonthlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == "anicca_pro_monthly" }
    }
    var proAnnualPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == "anicca_pro_annual" }
    }
    var bundleMonthlyPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == "anicca_bundle_monthly" }
    }
    var bundleAnnualPackage: Package? {
        packages.first { $0.storeProduct.productIdentifier == "anicca_bundle_annual" }
    }

    var proPriceString: String {
        let pkg = (selectedInterval == .monthly ? proMonthlyPackage : proAnnualPackage)
        return formatPackage(pkg, fallback: selectedInterval == .monthly ? "$4.99/mo" : "$3.33/mo, billed annually")
    }

    var bundlePriceString: String {
        let pkg = (selectedInterval == .monthly ? bundleMonthlyPackage : bundleAnnualPackage)
        return formatPackage(pkg, fallback: selectedInterval == .monthly ? "$8.99/mo" : "$5.83/mo, billed annually")
    }

    private func formatPackage(_ pkg: Package?, fallback: String) -> String {
        guard let pkg else { return fallback }
        let price = pkg.storeProduct.localizedPriceString
        switch selectedInterval {
        case .monthly: return "\(price)/mo"
        case .annual:  return "\(price)/yr"
        }
    }

    // MARK: - Load

    func load() async {
        await revenueCat.fetchOfferings()
        if let current = revenueCat.currentOfferings?.current {
            self.packages = current.availablePackages
        } else {
            self.packages = []
        }
    }

    // MARK: - Purchase

    func buy(_ plan: SelectedPlan) async {
        let package: Package?
        switch (plan, selectedInterval) {
        case (.pro, .monthly): package = proMonthlyPackage
        case (.pro, .annual): package = proAnnualPackage
        case (.bundle, .monthly): package = bundleMonthlyPackage
        case (.bundle, .annual): package = bundleAnnualPackage
        }
        guard let package else {
            errorMessage = Strings.Paywall.purchaseFailed
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let tier = try await revenueCat.purchase(package: package)
            await auth.updatePlanTier(tier)
            purchaseCompleted = true
            NotificationCenter.default.post(name: .planUpgraded, object: nil)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = Strings.Paywall.purchaseFailed
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let tier = try await revenueCat.restorePurchases()
            await auth.updatePlanTier(tier)
            purchaseCompleted = true
            NotificationCenter.default.post(name: .planUpgraded, object: nil)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = Strings.Paywall.purchaseFailed
        }
    }
}
