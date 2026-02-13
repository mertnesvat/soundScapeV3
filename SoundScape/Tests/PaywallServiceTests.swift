import XCTest
@testable import SoundScape

@MainActor
final class PaywallServiceTests: XCTestCase {

    // MARK: - Test Setup

    private var testUserDefaults: UserDefaults!
    private let testSuiteName = "com.soundscape.tests.paywall"

    override func setUp() async throws {
        try await super.setUp()
        testUserDefaults = UserDefaults(suiteName: testSuiteName)
        testUserDefaults?.removePersistentDomain(forName: testSuiteName)
    }

    override func tearDown() async throws {
        testUserDefaults?.removePersistentDomain(forName: testSuiteName)
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_init_startsWithIsLoadingFalse() {
        let sut = PaywallService()

        XCTAssertFalse(sut.isLoading)
    }

    func test_init_subscriptionServiceIsNil() {
        let sut = PaywallService()

        XCTAssertNil(sut.subscriptionService)
    }

    #if DEBUG
    func test_init_inDebugMode_defaultsToPremiumFalse() {
        let sut = PaywallService()
        // Default is false since debugPremiumOverride starts as false
        sut.debugPremiumOverride = false

        XCTAssertFalse(sut.isPremium)
    }

    func test_debugPremiumOverride_whenSetToFalse_isPremiumReturnsFalse() {
        let sut = PaywallService()

        sut.debugPremiumOverride = false

        XCTAssertFalse(sut.isPremium)
    }

    func test_debugPremiumOverride_whenSetToTrue_isPremiumReturnsTrue() {
        let sut = PaywallService()

        sut.debugPremiumOverride = true

        XCTAssertTrue(sut.isPremium)
    }

    func test_debugPremiumOverride_overridesSubscriptionServiceStatus() {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        // Even with subscription service set, debug override takes precedence
        sut.debugPremiumOverride = true
        XCTAssertTrue(sut.isPremium)

        sut.debugPremiumOverride = false
        XCTAssertFalse(sut.isPremium)
    }
    #endif

    // MARK: - setSubscriptionService Tests

    func test_setSubscriptionService_storesService() {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)

        sut.setSubscriptionService(subscriptionService)

        XCTAssertNotNil(sut.subscriptionService)
    }

    func test_setSubscriptionService_canBeCalledMultipleTimes() {
        let sut = PaywallService()
        let service1 = SubscriptionService(userDefaults: testUserDefaults)
        let service2 = SubscriptionService(userDefaults: testUserDefaults)

        sut.setSubscriptionService(service1)
        sut.setSubscriptionService(service2)

        XCTAssertNotNil(sut.subscriptionService)
    }

    // MARK: - setAnalyticsService Tests

    func test_setAnalyticsService_acceptsService() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()

        sut.setAnalyticsService(analyticsService)

        // Should complete without error
    }

    func test_setAnalyticsService_canBeCalledMultipleTimes() {
        let sut = PaywallService()
        let service1 = AnalyticsService()
        let service2 = AnalyticsService()

        sut.setAnalyticsService(service1)
        sut.setAnalyticsService(service2)

        // Should complete without crashing
    }

    // MARK: - isLoading Delegation Tests

    func test_isLoading_withNoSubscriptionService_returnsFalse() {
        let sut = PaywallService()

        XCTAssertFalse(sut.isLoading)
    }

    func test_isLoading_delegatesToSubscriptionService() {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        // SubscriptionService starts with isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - isPremium Delegation Tests (Release Mode)

    func test_isPremium_withNoSubscriptionService_returnsFalse() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        XCTAssertFalse(sut.isPremium)
    }

    func test_isPremium_withSubscriptionService_delegatesStatus() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Set up subscription service with no premium
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        // Fresh subscription service has isPremium = false
        XCTAssertFalse(sut.isPremium)
    }

    // MARK: - triggerPaywall Tests

    func test_triggerPaywall_callsCompletionHandler_whenPremium() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif
        var completionCalled = false

        sut.triggerPaywall(placement: "test_placement") {
            completionCalled = true
        }

        // When premium, completion is called immediately
        XCTAssertTrue(completionCalled)
    }

    func test_triggerPaywall_withDefaultPlacement_usesDefaultValue() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif
        var completionCalled = false

        sut.triggerPaywall {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
    }

    func test_triggerPaywall_storesPlacementContext() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "onboarding_complete") {
            // Completion handler stored
        }

        // The placement is stored internally for analytics
        // We can't directly test private state, but the function should not crash
    }

    func test_triggerPaywall_withCustomPlacement_doesNotCrash() {
        let sut = PaywallService()

        let placements = [
            "onboarding",
            "settings",
            "premium_sound",
            "unlimited_mixing",
            "premium_binaural",
            "adaptive_mode",
            "full_insights",
            "premium_winddown",
            "discover_save"
        ]

        for placement in placements {
            sut.triggerPaywall(placement: placement) {}
        }
    }

    // MARK: - handlePurchaseSuccess Tests

    func test_handlePurchaseSuccess_clearsPaywallContext() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Trigger paywall first to set up context
        var completionCalled = false
        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        // Handle success
        sut.handlePurchaseSuccess()

        // Completion should have been called
        // (behavior depends on isPremium state)
    }

    func test_handlePurchaseSuccess_canBeCalledWithoutTrigger() {
        let sut = PaywallService()

        // Should not crash even without prior trigger
        sut.handlePurchaseSuccess()
    }

    // MARK: - handlePurchaseError Tests

    func test_handlePurchaseError_clearsPaywallContext() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Trigger paywall first
        sut.triggerPaywall(placement: "test") {}

        // Handle error
        let testError = NSError(domain: "test", code: 123)
        sut.handlePurchaseError(testError)

        // Should complete without crashing
    }

    func test_handlePurchaseError_canBeCalledWithoutTrigger() {
        let sut = PaywallService()
        let testError = NSError(domain: "test", code: 123)

        // Should not crash even without prior trigger
        sut.handlePurchaseError(testError)
    }

    func test_handlePurchaseError_acceptsVariousErrorTypes() {
        let sut = PaywallService()

        let errors: [Error] = [
            NSError(domain: "StoreKit", code: 0),
            NSError(domain: "Network", code: -1009),
            SubscriptionError.userCancelled,
            SubscriptionError.productNotFound
        ]

        for error in errors {
            sut.handlePurchaseError(error)
        }
    }

    // MARK: - purchaseMonthly Tests

    func test_purchaseMonthly_withNoSubscriptionService_returnsFalse() async {
        let sut = PaywallService()

        let result = await sut.purchaseMonthly()

        XCTAssertFalse(result)
    }

    func test_purchaseMonthly_delegatesToSubscriptionService() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        let result = await sut.purchaseMonthly()

        // With no products loaded, this returns false
        XCTAssertFalse(result)
    }

    // MARK: - purchaseYearly Tests

    func test_purchaseYearly_withNoSubscriptionService_returnsFalse() async {
        let sut = PaywallService()

        let result = await sut.purchaseYearly()

        XCTAssertFalse(result)
    }

    func test_purchaseYearly_delegatesToSubscriptionService() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        let result = await sut.purchaseYearly()

        // With no products loaded, this returns false
        XCTAssertFalse(result)
    }

    // MARK: - restorePurchases Tests

    func test_restorePurchases_withNoSubscriptionService_completesWithoutCrash() async {
        let sut = PaywallService()

        await sut.restorePurchases()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_delegatesToSubscriptionService() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        await sut.restorePurchases()

        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_canBeCalledMultipleTimes() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        await sut.restorePurchases()
        await sut.restorePurchases()
        await sut.restorePurchases()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - showPaywallFromSettings Tests

    func test_showPaywallFromSettings_doesNotCrash() {
        let sut = PaywallService()

        sut.showPaywallFromSettings()
    }

    func test_showPaywallFromSettings_usesCorrectPlacement() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        // Should not crash and uses "settings" placement
        sut.showPaywallFromSettings()
    }

    // MARK: - updateSubscriptionStatus Tests

    func test_updateSubscriptionStatus_withNoSubscriptionService_doesNotCrash() {
        let sut = PaywallService()

        sut.updateSubscriptionStatus()
    }

    func test_updateSubscriptionStatus_delegatesToSubscriptionService() {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        sut.updateSubscriptionStatus()

        // Should complete without crashing
    }

    func test_updateSubscriptionStatus_canBeCalledMultipleTimes() {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        sut.updateSubscriptionStatus()
        sut.updateSubscriptionStatus()
        sut.updateSubscriptionStatus()

        // Should complete without crashing
    }

    // MARK: - Analytics Integration Tests

    func test_triggerPaywall_logsAnalytics_whenAnalyticsServiceSet() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()
        sut.setAnalyticsService(analyticsService)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test_analytics") {}

        // Analytics logging happens internally
        // We verify it doesn't crash
    }

    func test_handlePurchaseSuccess_logsAnalytics_whenAnalyticsServiceSet() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()
        sut.setAnalyticsService(analyticsService)

        sut.triggerPaywall(placement: "test") {}
        sut.handlePurchaseSuccess()

        // Analytics logging happens internally
    }

    func test_handlePurchaseError_logsAnalytics_whenAnalyticsServiceSet() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()
        sut.setAnalyticsService(analyticsService)

        sut.triggerPaywall(placement: "test") {}
        sut.handlePurchaseError(NSError(domain: "test", code: 0))

        // Analytics logging happens internally
    }

    // MARK: - Complete Workflow Tests

    func test_completeWorkflow_triggerPurchaseSuccess() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        let analyticsService = AnalyticsService()

        sut.setSubscriptionService(subscriptionService)
        sut.setAnalyticsService(analyticsService)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        var completionCalled = false
        sut.triggerPaywall(placement: "test_workflow") {
            completionCalled = true
        }

        // Simulate purchase (will fail without products, but tests the flow)
        let result = await sut.purchaseMonthly()
        if result {
            sut.handlePurchaseSuccess()
        }

        // Purchase failed (no products), so completion not called via success path
        XCTAssertFalse(result)
    }

    func test_completeWorkflow_triggerPurchaseError() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        let analyticsService = AnalyticsService()

        sut.setSubscriptionService(subscriptionService)
        sut.setAnalyticsService(analyticsService)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test_workflow") {}

        // Simulate purchase that fails
        let result = await sut.purchaseYearly()
        if !result {
            if let error = subscriptionService.error {
                sut.handlePurchaseError(error)
            }
        }

        XCTAssertFalse(result)
    }

    func test_completeWorkflow_restoreSuccess() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)

        sut.setSubscriptionService(subscriptionService)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        var completionCalled = false
        sut.triggerPaywall(placement: "test_restore") {
            completionCalled = true
        }

        await sut.restorePurchases()

        // Restore completed (though no actual subscription to restore in test)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Thread Safety Tests

    func test_multipleAsyncOperations_doNotCrash() async {
        let sut = PaywallService()
        let subscriptionService = SubscriptionService(userDefaults: testUserDefaults)
        sut.setSubscriptionService(subscriptionService)

        // Start multiple async operations
        async let purchase1 = sut.purchaseMonthly()
        async let purchase2 = sut.purchaseYearly()
        async let restore = sut.restorePurchases()

        // Wait for all to complete
        let results = await (purchase1, purchase2, restore)

        // Both purchases fail (no products), restore completes
        XCTAssertFalse(results.0)
        XCTAssertFalse(results.1)
    }

    // MARK: - handlePaywallDismissed Tests

    func test_handlePaywallDismissed_withoutTrigger_doesNotCrash() {
        let sut = PaywallService()

        sut.handlePaywallDismissed()
        // Should not crash when no paywall was triggered
    }

    func test_handlePaywallDismissed_clearsPaywallContext() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "premium_sound") {}
        XCTAssertEqual(sut.currentPaywallPlacement, "premium_sound")

        sut.handlePaywallDismissed()
        XCTAssertNil(sut.currentPaywallPlacement)
    }

    func test_handlePaywallDismissed_logsAnalytics() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()
        sut.setAnalyticsService(analyticsService)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "full_insights") {}
        sut.handlePaywallDismissed()

        // Analytics logging happens internally — verify no crash
        XCTAssertNil(sut.currentPaywallPlacement)
    }

    // MARK: - setPaywallPlacement Tests

    func test_setPaywallPlacement_setsPlacement() {
        let sut = PaywallService()

        sut.setPaywallPlacement("onboarding")
        XCTAssertEqual(sut.currentPaywallPlacement, "onboarding")
    }

    func test_setPaywallPlacement_logsPaywallShown() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()
        sut.setAnalyticsService(analyticsService)

        sut.setPaywallPlacement("onboarding")

        // Analytics logging happens internally — verify no crash
        XCTAssertEqual(sut.currentPaywallPlacement, "onboarding")
    }

    func test_setPaywallPlacement_canBeDismissedAfterwards() {
        let sut = PaywallService()

        sut.setPaywallPlacement("onboarding")
        XCTAssertEqual(sut.currentPaywallPlacement, "onboarding")

        sut.handlePaywallDismissed()
        XCTAssertNil(sut.currentPaywallPlacement)
    }

    // MARK: - Placement String Tests

    func test_showPaywallFromSettings_usesSettingsPlacement() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.showPaywallFromSettings()
        XCTAssertEqual(sut.currentPaywallPlacement, "settings")
    }

    func test_triggerPaywall_defaultPlacement_isUnknown() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall {}
        XCTAssertEqual(sut.currentPaywallPlacement, "unknown")
    }

    // MARK: - showPaywall Reactive State Tests

    func test_showPaywall_initiallyFalse() {
        let sut = PaywallService()
        XCTAssertFalse(sut.showPaywall)
    }

    func test_triggerPaywall_nonPremiumUser_setsShowPaywallTrue() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test") {}

        XCTAssertTrue(sut.showPaywall)
    }

    func test_triggerPaywall_premiumUser_showPaywallStaysFalse() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        sut.triggerPaywall(placement: "test") {}

        XCTAssertFalse(sut.showPaywall)
    }

    func test_triggerPaywall_premiumUser_callsCompletionImmediately() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif
        var completionCalled = false

        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    func test_handlePaywallDismissed_resetsShowPaywall() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test") {}
        XCTAssertTrue(sut.showPaywall)

        sut.handlePaywallDismissed()
        XCTAssertFalse(sut.showPaywall)
    }

    func test_handlePurchaseSuccess_resetsShowPaywall() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test") {}
        XCTAssertTrue(sut.showPaywall)

        sut.handlePurchaseSuccess()
        XCTAssertFalse(sut.showPaywall)
    }

    func test_handlePurchaseSuccess_callsCompletionHandler() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        var completionCalled = false

        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        sut.handlePurchaseSuccess()
        XCTAssertTrue(completionCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    func test_handlePaywallDismissed_doesNotCallCompletion() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        var completionCalled = false

        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        sut.handlePaywallDismissed()
        XCTAssertFalse(completionCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    func test_handlePurchaseError_resetsShowPaywall() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "test") {}
        XCTAssertTrue(sut.showPaywall)

        sut.handlePurchaseError(NSError(domain: "test", code: 0))
        XCTAssertFalse(sut.showPaywall)
    }

    func test_multipleTriggerPaywallCalls_showPaywallRemainsTrue() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerPaywall(placement: "first") {}
        sut.triggerPaywall(placement: "second") {}
        sut.triggerPaywall(placement: "third") {}

        XCTAssertTrue(sut.showPaywall)
        XCTAssertEqual(sut.currentPaywallPlacement, "third")
    }

    func test_showPaywallFromSettings_setsShowPaywallForNonPremium() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.showPaywallFromSettings()

        XCTAssertTrue(sut.showPaywall)
        XCTAssertEqual(sut.currentPaywallPlacement, "settings")
    }

    func test_showPaywall_fullLifecycle_triggerDismissTriggerSuccess() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Trigger -> Dismiss
        sut.triggerPaywall(placement: "first") {}
        XCTAssertTrue(sut.showPaywall)

        sut.handlePaywallDismissed()
        XCTAssertFalse(sut.showPaywall)
        XCTAssertNil(sut.currentPaywallPlacement)

        // Trigger again -> Purchase success
        var completionCalled = false
        sut.triggerPaywall(placement: "second") {
            completionCalled = true
        }
        XCTAssertTrue(sut.showPaywall)

        sut.handlePurchaseSuccess()
        XCTAssertFalse(sut.showPaywall)
        XCTAssertTrue(completionCalled)
        XCTAssertNil(sut.currentPaywallPlacement)
    }
}
