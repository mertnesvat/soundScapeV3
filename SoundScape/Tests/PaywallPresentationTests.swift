import Foundation
import Testing
@testable import SoundScape

/// Comprehensive unit tests for the reactive `shouldShowPaywall` state
/// and paywall presentation logic in PaywallService.
@Suite("Paywall Presentation Logic Tests")
@MainActor
struct PaywallPresentationTests {

    // MARK: - Initial State

    @Test("shouldShowPaywall starts as false on init")
    func shouldShowPaywallStartsFalse() {
        let service = PaywallService()
        #expect(service.shouldShowPaywall == false)
    }

    @Test("currentPaywallPlacement starts as nil on init")
    func currentPaywallPlacementStartsNil() {
        let service = PaywallService()
        #expect(service.currentPaywallPlacement == nil)
    }

    // MARK: - triggerPaywall for Non-Premium Users

    @Test("triggerPaywall sets shouldShowPaywall to true for non-premium users")
    func triggerPaywallSetsShouldShowForNonPremium() {
        let service = PaywallService()
        // No subscription service and no debug override = not premium
        service.triggerPaywall(placement: "test") {}
        #expect(service.shouldShowPaywall == true)
    }

    @Test("triggerPaywall stores placement string correctly")
    func placementStoredOnTrigger() {
        let service = PaywallService()
        service.triggerPaywall(placement: "premium_sound") {}
        #expect(service.currentPaywallPlacement == "premium_sound")
    }

    @Test("triggerPaywall with default placement uses 'unknown'")
    func defaultPlacementIsUnknown() {
        let service = PaywallService()
        service.triggerPaywall {}
        #expect(service.currentPaywallPlacement == "unknown")
    }

    @Test("triggerPaywall does NOT call completion for non-premium users")
    func triggerPaywallDoesNotCallCompletionForNonPremium() {
        let service = PaywallService()
        var completionCalled = false
        service.triggerPaywall(placement: "test") {
            completionCalled = true
        }
        #expect(completionCalled == false)
    }

    // MARK: - triggerPaywall for Premium Users

    #if DEBUG
    @Test("triggerPaywall does NOT set shouldShowPaywall for premium users")
    func triggerPaywallDoesNotShowForPremium() {
        let service = PaywallService()
        service.debugPremiumOverride = true
        service.triggerPaywall(placement: "test") {}
        #expect(service.shouldShowPaywall == false)
    }

    @Test("triggerPaywall calls completion immediately for premium users")
    func triggerPaywallCallsCompletionForPremium() {
        let service = PaywallService()
        service.debugPremiumOverride = true
        var completionCalled = false
        service.triggerPaywall(placement: "test") {
            completionCalled = true
        }
        #expect(completionCalled == true)
    }

    @Test("triggerPaywall still stores placement for premium users before returning")
    func triggerPaywallStoresPlacementForPremium() {
        let service = PaywallService()
        service.debugPremiumOverride = true
        service.triggerPaywall(placement: "premium_test") {}
        // Placement is set before the premium check returns early
        #expect(service.currentPaywallPlacement == "premium_test")
    }
    #endif

    // MARK: - handlePaywallDismissed

    @Test("handlePaywallDismissed resets shouldShowPaywall to false")
    func handleDismissedResetsShouldShow() {
        let service = PaywallService()
        service.triggerPaywall(placement: "test") {}
        #expect(service.shouldShowPaywall == true)
        service.handlePaywallDismissed()
        #expect(service.shouldShowPaywall == false)
    }

    @Test("handlePaywallDismissed clears placement")
    func placementClearedOnDismissal() {
        let service = PaywallService()
        service.triggerPaywall(placement: "premium_sound") {}
        #expect(service.currentPaywallPlacement == "premium_sound")
        service.handlePaywallDismissed()
        #expect(service.currentPaywallPlacement == nil)
    }

    @Test("handlePaywallDismissed does NOT call completion handler")
    func completionNotCalledOnDismissal() {
        let service = PaywallService()
        var completionCallCount = 0
        service.triggerPaywall(placement: "test") {
            completionCallCount += 1
        }
        service.handlePaywallDismissed()
        #expect(completionCallCount == 0)
    }

    @Test("handlePaywallDismissed is safe to call without prior trigger")
    func handleDismissedWithoutTriggerIsSafe() {
        let service = PaywallService()
        service.handlePaywallDismissed()
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
    }

    // MARK: - handlePurchaseSuccess

    @Test("handlePurchaseSuccess resets shouldShowPaywall to false")
    func handlePurchaseSuccessResetsShouldShow() {
        let service = PaywallService()
        service.triggerPaywall(placement: "test") {}
        #expect(service.shouldShowPaywall == true)
        service.handlePurchaseSuccess()
        #expect(service.shouldShowPaywall == false)
    }

    @Test("handlePurchaseSuccess clears placement")
    func handlePurchaseSuccessClearsPlacement() {
        let service = PaywallService()
        service.triggerPaywall(placement: "test") {}
        service.handlePurchaseSuccess()
        #expect(service.currentPaywallPlacement == nil)
    }

    @Test("handlePurchaseSuccess calls completion handler")
    func handlePurchaseSuccessCallsCompletion() {
        let service = PaywallService()
        var completionCallCount = 0
        service.triggerPaywall(placement: "test") {
            completionCallCount += 1
        }
        service.handlePurchaseSuccess()
        #expect(completionCallCount == 1)
    }

    @Test("handlePurchaseSuccess is safe to call without prior trigger")
    func handlePurchaseSuccessWithoutTriggerIsSafe() {
        let service = PaywallService()
        service.handlePurchaseSuccess()
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
    }

    // MARK: - handlePurchaseError

    @Test("handlePurchaseError resets shouldShowPaywall to false")
    func handlePurchaseErrorResetsShouldShow() {
        let service = PaywallService()
        service.triggerPaywall(placement: "test") {}
        #expect(service.shouldShowPaywall == true)
        service.handlePurchaseError(NSError(domain: "test", code: -1))
        #expect(service.shouldShowPaywall == false)
    }

    @Test("handlePurchaseError clears placement")
    func handlePurchaseErrorClearsPlacement() {
        let service = PaywallService()
        service.triggerPaywall(placement: "test") {}
        service.handlePurchaseError(NSError(domain: "test", code: -1))
        #expect(service.currentPaywallPlacement == nil)
    }

    @Test("handlePurchaseError does NOT call completion handler")
    func handlePurchaseErrorDoesNotCallCompletion() {
        let service = PaywallService()
        var completionCallCount = 0
        service.triggerPaywall(placement: "test") {
            completionCallCount += 1
        }
        service.handlePurchaseError(NSError(domain: "test", code: -1))
        #expect(completionCallCount == 0)
    }

    @Test("handlePurchaseError is safe to call without prior trigger")
    func handlePurchaseErrorWithoutTriggerIsSafe() {
        let service = PaywallService()
        service.handlePurchaseError(NSError(domain: "test", code: -1))
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
    }

    // MARK: - showPaywallFromSettings

    @Test("showPaywallFromSettings sets shouldShowPaywall to true")
    func showPaywallFromSettingsTriggers() {
        let service = PaywallService()
        service.showPaywallFromSettings()
        #expect(service.shouldShowPaywall == true)
    }

    @Test("showPaywallFromSettings uses 'settings' placement")
    func showPaywallFromSettingsUsesCorrectPlacement() {
        let service = PaywallService()
        service.showPaywallFromSettings()
        #expect(service.currentPaywallPlacement == "settings")
    }

    // MARK: - Multiple Triggers and Edge Cases

    @Test("Multiple rapid triggers update placement to latest value")
    func multipleRapidTriggers() {
        let service = PaywallService()
        service.triggerPaywall(placement: "first") {}
        service.triggerPaywall(placement: "second") {}
        #expect(service.shouldShowPaywall == true)
        #expect(service.currentPaywallPlacement == "second")
    }

    @Test("Full lifecycle: trigger -> dismiss resets all state")
    func fullLifecycleTriggerDismiss() {
        let service = PaywallService()
        var completionCalled = false

        // Trigger
        service.triggerPaywall(placement: "lifecycle_test") {
            completionCalled = true
        }
        #expect(service.shouldShowPaywall == true)
        #expect(service.currentPaywallPlacement == "lifecycle_test")

        // Dismiss
        service.handlePaywallDismissed()
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
        #expect(completionCalled == false)
    }

    @Test("Full lifecycle: trigger -> purchase success calls completion and resets state")
    func fullLifecycleTriggerPurchase() {
        let service = PaywallService()
        var completionCalled = false

        // Trigger
        service.triggerPaywall(placement: "purchase_test") {
            completionCalled = true
        }
        #expect(service.shouldShowPaywall == true)

        // Purchase success
        service.handlePurchaseSuccess()
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
        #expect(completionCalled == true)
    }

    @Test("Full lifecycle: trigger -> purchase error resets state without calling completion")
    func fullLifecycleTriggerError() {
        let service = PaywallService()
        var completionCalled = false

        // Trigger
        service.triggerPaywall(placement: "error_test") {
            completionCalled = true
        }
        #expect(service.shouldShowPaywall == true)

        // Error
        service.handlePurchaseError(NSError(domain: "StoreKit", code: 0))
        #expect(service.shouldShowPaywall == false)
        #expect(service.currentPaywallPlacement == nil)
        #expect(completionCalled == false)
    }

    @Test("Re-trigger after dismissal works correctly")
    func reTriggerAfterDismissal() {
        let service = PaywallService()

        // First cycle
        service.triggerPaywall(placement: "first") {}
        service.handlePaywallDismissed()
        #expect(service.shouldShowPaywall == false)

        // Second cycle
        service.triggerPaywall(placement: "second") {}
        #expect(service.shouldShowPaywall == true)
        #expect(service.currentPaywallPlacement == "second")
    }

    @Test("Completion is only called once even if handlePurchaseSuccess is called twice")
    func completionCalledOnlyOnce() {
        let service = PaywallService()
        var completionCallCount = 0

        service.triggerPaywall(placement: "test") {
            completionCallCount += 1
        }

        // First success clears the completion handler
        service.handlePurchaseSuccess()
        #expect(completionCallCount == 1)

        // Second success should NOT call completion again (handler was cleared)
        service.handlePurchaseSuccess()
        #expect(completionCallCount == 1)
    }

    @Test("Various placement strings are stored correctly",
          arguments: [
            "premium_sound",
            "unlimited_mixing",
            "premium_binaural",
            "adaptive_mode",
            "full_insights",
            "premium_winddown",
            "discover_save",
            "onboarding",
            "settings"
          ])
    func placementStringsStoredCorrectly(placement: String) {
        let service = PaywallService()
        service.triggerPaywall(placement: placement) {}
        #expect(service.currentPaywallPlacement == placement)
    }
}
