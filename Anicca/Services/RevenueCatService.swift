import Foundation
import RevenueCat

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()

    @Published var currentOfferings: Offerings?
    @Published var isPro: Bool = false
    @Published var isBundle: Bool = false
    @Published var planTier: PlanTier = .free

    private var didConfigure = false

    private init() {}

    func configure(apiKey: String) {
        guard !didConfigure else { return }
        guard !apiKey.isEmpty else { return }
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKey)
        didConfigure = true
    }

    // MARK: - Offerings

    func fetchOfferings() async {
        guard didConfigure else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOfferings = offerings
        } catch {
            self.currentOfferings = nil
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> PlanTier {
        guard didConfigure else { throw AppError.purchaseFailed("Purchases not configured.") }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { throw AppError.purchaseCancelled }
            return updateEntitlements(from: result.customerInfo)
        } catch let appError as AppError {
            throw appError
        } catch {
            throw RevenueCatErrorMapper.map(error)
        }
    }

    func restorePurchases() async throws -> PlanTier {
        guard didConfigure else { throw AppError.purchaseFailed("Purchases not configured.") }
        do {
            let info = try await Purchases.shared.restorePurchases()
            let tier = updateEntitlements(from: info)
            if tier == .free { throw AppError.nothingToRestore }
            return tier
        } catch let appError as AppError {
            throw appError
        } catch {
            throw RevenueCatErrorMapper.map(error)
        }
    }

    // MARK: - Entitlement Check

    @discardableResult
    func checkEntitlement() async -> PlanTier {
        guard didConfigure else { return .free }
        do {
            let info = try await Purchases.shared.customerInfo()
            return updateEntitlements(from: info)
        } catch {
            return .free
        }
    }

    @discardableResult
    private func updateEntitlements(from info: CustomerInfo) -> PlanTier {
        let bundle = info.entitlements["bundle"]?.isActive == true
        let pro = info.entitlements["pro"]?.isActive == true

        let tier: PlanTier
        if bundle { tier = .bundle }
        else if pro { tier = .pro }
        else { tier = .free }

        self.isPro = (tier == .pro || tier == .bundle)
        self.isBundle = (tier == .bundle)
        self.planTier = tier
        return tier
    }

    // MARK: - User identity

    func login(userId: String) async {
        guard didConfigure else { return }
        _ = try? await Purchases.shared.logIn(userId)
    }

    func logout() async {
        guard didConfigure else { return }
        guard !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
    }
}
