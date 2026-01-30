import Foundation
import SuperwallKit

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
        configureSuperwall()
        updateSubscriptionStatus()
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    private func configureSuperwall() {
        Superwall.configure(apiKey: "pk_Wn-vgH14oQfVvPNaCjxKz")
    }

    func updateSubscriptionStatus() {
        #if DEBUG
            // In debug mode, isPremium is controlled by debugPremiumOverride
        #else
            switch Superwall.shared.subscriptionStatus {
            case .active:
                isPremium = true
            case .inactive, .unknown:
                isPremium = false
            @unknown default:
                isPremium = false
            }
        #endif
    }

    func triggerPaywall(placement: String = "campaign_trigger", completion: @escaping () -> Void) {
        let handler = PaywallPresentationHandler()

        handler.onDismiss { [weak self] paywallInfo in
            self?.updateSubscriptionStatus()
            if self?.isPremium == true {
                self?.analyticsService?.logPurchaseCompleted(placement: placement)
            }
        }

        handler.onError { [weak self] error in
            print("Paywall error: \(error.localizedDescription)")
            self?.analyticsService?.logPaywallError(
                placement: placement, error: error.localizedDescription)
        }

        handler.onSkip { [weak self] _ in
            self?.updateSubscriptionStatus()
        }

        Superwall.shared.register(
            event: placement, params: nil, handler: handler, feature: completion)
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        let result = await Superwall.shared.restorePurchases()
        updateSubscriptionStatus()

        switch result {
        case .restored:
            analyticsService?.logPurchaseRestored()
        case .failed(let error):
            print("Restore failed: \(error?.localizedDescription ?? "Unknown error")")
        @unknown default:
            break
        }
    }

    func showPaywallFromSettings() {
        // Using campaign_trigger - make sure this event is configured in Superwall dashboard
        triggerPaywall(placement: "campaign_trigger") {}
    }
}
