import Foundation
import StoreKit

@Observable
@MainActor
final class PaywallService {

    // MARK: - Published State

    #if DEBUG
    /// Debug override for testing premium features - set to true to simulate premium
    var debugPremiumOverride: Bool = true

    var isPremium: Bool {
        debugPremiumOverride
    }
    #else
    private(set) var isPremium: Bool = false
    #endif

    private(set) var isLoading: Bool = false
    private(set) var products: [Product] = []
    private(set) var purchaseError: String?

    /// Whether to show the paywall sheet
    var showPaywall: Bool = false

    // MARK: - Private Properties

    private var analyticsService: AnalyticsService?
    private var updateListenerTask: Task<Void, Error>?

    /// Product identifiers - configure these in App Store Connect
    private let productIdentifiers: Set<String> = [
        "com.studionext.soundscape.monthly",
        "com.studionext.soundscape.yearly"
    ]

    // MARK: - Initialization

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    nonisolated func cleanup() {
        // Called before deallocation if needed
    }

    // MARK: - Public Methods

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    /// Triggers the paywall presentation
    /// - Parameter placement: Analytics placement identifier
    func triggerPaywall(placement: String = "campaign_trigger") {
        analyticsService?.logPaywallShown(placement: placement)
        showPaywall = true
    }

    /// Shows paywall from settings
    func showPaywallFromSettings() {
        triggerPaywall(placement: "settings")
    }

    /// Purchase a product
    /// - Parameter product: The StoreKit Product to purchase
    /// - Returns: Whether the purchase was successful
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()

                analyticsService?.logPurchaseCompleted(placement: "paywall")
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            analyticsService?.logPaywallError(placement: "paywall", error: error.localizedDescription)
            isLoading = false
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()

            if isPremium {
                analyticsService?.logPurchaseRestored()
            }
        } catch {
            purchaseError = error.localizedDescription
            print("Restore failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// Load products from App Store
    private func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
            // Sort by price (monthly first, then yearly)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Update subscription status based on current entitlements
    func updateSubscriptionStatus() async {
        #if DEBUG
        // In debug mode, isPremium is controlled by debugPremiumOverride
        #else
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                    break
                }
            }
        }

        isPremium = hasActiveSubscription
        #endif
    }

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }

    /// Verify a transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Computed Properties

    /// Get the monthly product
    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }

    /// Get the yearly product
    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
}
