import Foundation

@Observable
@MainActor
final class PaywallService {
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

    private var analyticsService: AnalyticsService?

    init() {
        // Paywall SDK configuration will be added in a future update
        updateSubscriptionStatus()
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    func updateSubscriptionStatus() {
        #if DEBUG
            // In debug mode, isPremium is controlled by debugPremiumOverride
        #else
            // Subscription status will be checked via StoreKit in a future update
            isPremium = false
        #endif
    }

    func triggerPaywall(placement: String = "campaign_trigger", completion: @escaping () -> Void) {
        // Log paywall trigger for analytics
        analyticsService?.logPaywallShown(placement: placement)

        // Paywall presentation will be implemented with StoreKit in a future update
        // For now, just call the completion handler
        completion()
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        // Restore purchases will be implemented with StoreKit in a future update
        // For now, just update subscription status
        updateSubscriptionStatus()

        // Log restore attempt
        analyticsService?.logPurchaseRestored()
    }

    func showPaywallFromSettings() {
        triggerPaywall(placement: "campaign_trigger") {}
    }
}
