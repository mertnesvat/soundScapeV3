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
    /// Reactive flag for sheet presentation - views can observe this to show/hide paywall
    var shouldShowPaywall: Bool = false

    private(set) var currentPaywallPlacement: String?
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

    func triggerPaywall(placement: String = "unknown", completion: @escaping () -> Void) {
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

        // Signal the view layer to present the paywall sheet
        shouldShowPaywall = true
    }

    /// Handles a successful purchase from the paywall
    func handlePurchaseSuccess() {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPurchaseCompleted(placement: placement)
            analyticsService?.logPaywallConverted(placement: placement)
        }
        shouldShowPaywall = false
        paywallCompletionHandler?()
        clearPaywallContext()
    }

    /// Handles a purchase error from the paywall
    func handlePurchaseError(_ error: Error) {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPaywallError(placement: placement, error: error.localizedDescription)
        }
        shouldShowPaywall = false
        clearPaywallContext()
    }

    /// Handles a paywall dismissal without purchase
    func handlePaywallDismissed() {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPaywallDismissed(placement: placement)
        }
        shouldShowPaywall = false
        clearPaywallContext()
    }

    /// Sets the placement context for analytics without triggering the full paywall flow.
    /// Use this when the paywall UI is presented directly (e.g., in onboarding).
    func setPaywallPlacement(_ placement: String) {
        currentPaywallPlacement = placement
        analyticsService?.logPaywallShown(placement: placement)
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
        triggerPaywall(placement: "settings") {}
    }
}
