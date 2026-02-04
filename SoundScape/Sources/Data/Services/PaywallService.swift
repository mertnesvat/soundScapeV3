import Foundation

@Observable
@MainActor
final class PaywallService {
    #if DEBUG
        /// Debug override for testing premium features - set to true to simulate premium
        var debugPremiumOverride: Bool = false

        var isPremium: Bool {
            debugPremiumOverride || (subscriptionService?.isPremium ?? false)
        }
    #else
        var isPremium: Bool {
            subscriptionService?.isPremium ?? false
        }
    #endif

    var isLoading: Bool {
        subscriptionService?.isLoading ?? false
    }

    /// The subscription service handling StoreKit 2 purchases
    private(set) var subscriptionService: SubscriptionService?

    private var analyticsService: AnalyticsService?
    private var currentPaywallPlacement: String?
    private var paywallCompletionHandler: (() -> Void)?

    init() {
        // SubscriptionService will be injected via setSubscriptionService
    }

    /// Sets the SubscriptionService dependency
    func setSubscriptionService(_ service: SubscriptionService) {
        self.subscriptionService = service
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    func updateSubscriptionStatus() {
        Task {
            await subscriptionService?.checkCurrentEntitlements()
        }
    }

    func triggerPaywall(placement: String = "campaign_trigger", completion: @escaping () -> Void) {
        // Log paywall trigger for analytics
        analyticsService?.logPaywallShown(placement: placement)

        // Store context for purchase completion
        currentPaywallPlacement = placement
        paywallCompletionHandler = completion

        // If already premium, call completion immediately
        if isPremium {
            completion()
            return
        }

        // Note: The actual paywall UI presentation should be handled by the view layer
        // This service manages the purchase flow and state
    }

    /// Handles a successful purchase from the paywall
    func handlePurchaseSuccess() {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPurchaseCompleted(placement: placement)
        }
        paywallCompletionHandler?()
        clearPaywallContext()
    }

    /// Handles a purchase error from the paywall
    func handlePurchaseError(_ error: Error) {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPaywallError(placement: placement, error: error.localizedDescription)
        }
        clearPaywallContext()
    }

    /// Clears the current paywall context
    private func clearPaywallContext() {
        currentPaywallPlacement = nil
        paywallCompletionHandler = nil
    }

    /// Purchases the monthly subscription
    func purchaseMonthly() async -> Bool {
        guard let subscriptionService = subscriptionService else { return false }

        let success = await subscriptionService.purchaseMonthly()
        if success {
            handlePurchaseSuccess()
        } else if let error = subscriptionService.error {
            handlePurchaseError(error)
        }
        return success
    }

    /// Purchases the yearly subscription
    func purchaseYearly() async -> Bool {
        guard let subscriptionService = subscriptionService else { return false }

        let success = await subscriptionService.purchaseYearly()
        if success {
            handlePurchaseSuccess()
        } else if let error = subscriptionService.error {
            handlePurchaseError(error)
        }
        return success
    }

    func restorePurchases() async {
        await subscriptionService?.restorePurchases()

        // Log restore attempt
        analyticsService?.logPurchaseRestored()

        // If restore resulted in premium, call the completion handler
        if isPremium {
            paywallCompletionHandler?()
            clearPaywallContext()
        }
    }

    func showPaywallFromSettings() {
        triggerPaywall(placement: "campaign_trigger") {}
    }
}
