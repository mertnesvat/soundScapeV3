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
    private(set) var currentPaywallPlacement: String?
    private var paywallCompletionHandler: (() -> Void)?

    /// Reactive flag for presenting the paywall sheet from views that observe PaywallService.
    /// Becomes true when triggerPaywall() is called for a non-premium user.
    /// Resets to false on dismiss, purchase success, or purchase error.
    var showPaywall: Bool = false

    // MARK: - Session-Based Paywall Controls

    private static let sessionCountKey = "app_session_count"

    /// Number of app sessions (persisted across launches)
    private(set) var appSessionCount: Int {
        get { UserDefaults.standard.integer(forKey: Self.sessionCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.sessionCountKey) }
    }

    /// Whether a paywall has already been shown in this session (resets on launch)
    private(set) var paywallShownThisSession: Bool = false

    /// Whether paywall is allowed based on session rules:
    /// - Not allowed during user's first session
    /// - Max 1 paywall per session after that
    var isPaywallAllowed: Bool {
        appSessionCount >= 2 && !paywallShownThisSession
    }

    init() {
        // SubscriptionService will be injected via setSubscriptionService
    }

    /// Called on each app launch to increment session count
    func incrementSessionCount() {
        appSessionCount += 1
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
        // Always log that a paywall trigger occurred (even if suppressed)
        analyticsService?.logPaywallTriggered(
            triggerSource: placement,
            sessionNumber: appSessionCount,
            contentId: nil
        )

        // If already premium, call completion immediately
        if isPremium {
            completion()
            return
        }

        // Check session-based paywall rules
        guard isPaywallAllowed else {
            let reason = appSessionCount < 2 ? "first_session" : "already_shown_this_session"
            analyticsService?.logPaywallSuppressed(reason: reason, triggerSource: placement)
            return
        }

        // Log paywall shown for analytics
        analyticsService?.logPaywallShown(placement: placement)

        // Store context for purchase completion
        currentPaywallPlacement = placement
        paywallCompletionHandler = completion

        // Mark that paywall has been shown this session
        paywallShownThisSession = true

        // Signal the view layer to present the paywall sheet
        showPaywall = true
    }

    /// Handles a successful purchase from the paywall
    func handlePurchaseSuccess() {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPurchaseCompleted(placement: placement)
            analyticsService?.logPaywallConverted(placement: placement)
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

    /// Handles a paywall dismissal without purchase
    func handlePaywallDismissed() {
        if let placement = currentPaywallPlacement {
            analyticsService?.logPaywallDismissed(placement: placement)
        }
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
        showPaywall = false
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
