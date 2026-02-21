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

    // MARK: - Delayed Smart Paywall

    /// Number of sessions before the paywall is shown to new users.
    static let gracePeriodSessions = 3

    /// Maximum number of free saved mixes before triggering the paywall.
    static let freeSavedMixesLimit = 3

    private let userDefaults: UserDefaults

    private static let sessionCountKey = "paywall_session_count"

    /// Current session count persisted across launches.
    private(set) var sessionCount: Int {
        didSet { userDefaults.set(sessionCount, forKey: Self.sessionCountKey) }
    }

    /// Whether the grace period is still active (user has not yet reached the session threshold).
    var isInGracePeriod: Bool {
        sessionCount < Self.gracePeriodSessions
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.sessionCount = userDefaults.integer(forKey: Self.sessionCountKey)
    }

    /// Call once per app launch to increment the session counter.
    func recordSession() {
        sessionCount += 1
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
        showPaywall = true
    }

    /// Triggers the paywall only if the grace period has elapsed.
    /// During the grace period the `onGranted` closure is called immediately,
    /// allowing new users to explore premium features freely.
    func triggerSmartPaywall(source: String, onGranted: @escaping () -> Void) {
        if isPremium {
            onGranted()
            return
        }

        if isInGracePeriod {
            onGranted()
            return
        }

        analyticsService?.logPaywallShown(placement: source)
        analyticsService?.logPaywallSource(source)

        currentPaywallPlacement = source
        paywallCompletionHandler = onGranted

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
