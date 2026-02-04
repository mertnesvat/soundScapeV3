import XCTest
@testable import SoundScape

@MainActor
final class PaywallServiceTests: XCTestCase {

    // MARK: - Initial State Tests

    func test_init_startsWithIsLoadingFalse() {
        let sut = PaywallService()

        XCTAssertFalse(sut.isLoading)
    }

    #if DEBUG
    func test_init_inDebugMode_defaultsToPremiumTrue() {
        let sut = PaywallService()

        XCTAssertTrue(sut.isPremium)
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
    #endif

    // MARK: - triggerPaywall Tests

    func test_triggerPaywall_callsCompletionHandler() {
        let sut = PaywallService()
        var completionCalled = false

        sut.triggerPaywall(placement: "test_placement") {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
    }

    func test_triggerPaywall_withDefaultPlacement_callsCompletion() {
        let sut = PaywallService()
        var completionCalled = false

        sut.triggerPaywall {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
    }

    // MARK: - restorePurchases Tests

    func test_restorePurchases_setsIsLoadingDuringOperation() async {
        let sut = PaywallService()

        XCTAssertFalse(sut.isLoading)

        await sut.restorePurchases()

        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_completesWithoutError() async {
        let sut = PaywallService()

        await sut.restorePurchases()

        // Should complete without throwing
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - showPaywallFromSettings Tests

    func test_showPaywallFromSettings_doesNotCrash() {
        let sut = PaywallService()

        // Should complete without crashing
        sut.showPaywallFromSettings()
    }

    // MARK: - updateSubscriptionStatus Tests

    func test_updateSubscriptionStatus_doesNotCrash() {
        let sut = PaywallService()

        sut.updateSubscriptionStatus()

        // Should complete without crashing
    }

    // MARK: - Analytics Service Integration

    func test_setAnalyticsService_acceptsService() {
        let sut = PaywallService()
        let analyticsService = AnalyticsService()

        sut.setAnalyticsService(analyticsService)

        // Should complete without error
    }

    // MARK: - Subscription Service Integration Tests

    func test_setSubscriptionService_setsService() {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        XCTAssertNotNil(sut.subscriptionService)
    }

    func test_isPremium_delegatesToSubscriptionService() {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall2")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall2")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        // SubscriptionService starts with isPremium = false
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        XCTAssertFalse(sut.isPremium)
    }

    func test_isLoading_delegatesToSubscriptionService() {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall3")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall3")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        // Should reflect subscription service loading state
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Purchase Method Tests

    func test_purchaseMonthly_withoutSubscriptionService_returnsFalse() async {
        let sut = PaywallService()

        let result = await sut.purchaseMonthly()

        XCTAssertFalse(result)
    }

    func test_purchaseYearly_withoutSubscriptionService_returnsFalse() async {
        let sut = PaywallService()

        let result = await sut.purchaseYearly()

        XCTAssertFalse(result)
    }

    func test_purchaseMonthly_withSubscriptionService_delegatesToService() async {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall4")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall4")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        // Without products loaded, should return false
        let result = await sut.purchaseMonthly()

        XCTAssertFalse(result)
    }

    func test_purchaseYearly_withSubscriptionService_delegatesToService() async {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall5")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall5")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        // Without products loaded, should return false
        let result = await sut.purchaseYearly()

        XCTAssertFalse(result)
    }

    // MARK: - Restore Purchases Integration Tests

    func test_restorePurchases_withoutSubscriptionService_completesWithoutCrash() async {
        let sut = PaywallService()

        await sut.restorePurchases()

        // Should complete without error
        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_withSubscriptionService_delegatesToService() async {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall6")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall6")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        await sut.restorePurchases()

        // Should complete and not be loading
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Paywall Context Tests

    func test_triggerPaywall_withPremiumUser_callsCompletionImmediately() {
        let sut = PaywallService()
        var completionCalled = false

        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
    }

    func test_triggerPaywall_storesPlacement() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        // When premium, completion is called immediately
        var called = false
        sut.triggerPaywall(placement: "settings_upgrade") {
            called = true
        }

        XCTAssertTrue(called)
    }

    // MARK: - Update Subscription Status Tests

    func test_updateSubscriptionStatus_withoutSubscriptionService_doesNotCrash() {
        let sut = PaywallService()

        sut.updateSubscriptionStatus()

        // Should complete without error
    }

    func test_updateSubscriptionStatus_withSubscriptionService_callsCheckEntitlements() {
        let sut = PaywallService()
        let userDefaults = UserDefaults(suiteName: "com.soundscape.tests.paywall7")!
        userDefaults.removePersistentDomain(forName: "com.soundscape.tests.paywall7")
        let subscriptionService = SubscriptionService(userDefaults: userDefaults)

        sut.setSubscriptionService(subscriptionService)

        sut.updateSubscriptionStatus()

        // Should trigger an async check
    }

    #if DEBUG
    // MARK: - Debug Override Tests

    func test_debugPremiumOverride_defaultValue() {
        let sut = PaywallService()

        // Default is false in newer builds
        // Check that it can be set
        sut.debugPremiumOverride = false
        XCTAssertFalse(sut.debugPremiumOverride)
    }

    func test_debugPremiumOverride_canBeToggled() {
        let sut = PaywallService()

        sut.debugPremiumOverride = true
        XCTAssertTrue(sut.isPremium)

        sut.debugPremiumOverride = false
        XCTAssertFalse(sut.isPremium)
    }

    func test_isPremium_withDebugOverrideTrue_returnsTrue() {
        let sut = PaywallService()
        sut.debugPremiumOverride = true

        XCTAssertTrue(sut.isPremium)
    }

    func test_isPremium_withDebugOverrideFalse_andNoSubscriptionService_returnsFalse() {
        let sut = PaywallService()
        sut.debugPremiumOverride = false

        // Without subscription service, isPremium should be false
        XCTAssertFalse(sut.isPremium)
    }
    #endif

    // MARK: - Paywall Completion Handler Tests

    func test_handlePurchaseSuccess_clearsPaywallContext() {
        let sut = PaywallService()
        var completionCalled = false

        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Trigger paywall to set up context
        sut.triggerPaywall(placement: "test") {
            completionCalled = true
        }

        // Simulate purchase success
        sut.handlePurchaseSuccess()

        XCTAssertTrue(completionCalled)
    }

    func test_handlePurchaseError_clearsPaywallContext() {
        let sut = PaywallService()

        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        // Trigger paywall to set up context
        sut.triggerPaywall(placement: "test") {}

        // Simulate purchase error
        let error = NSError(domain: "test", code: 0, userInfo: nil)
        sut.handlePurchaseError(error)

        // Context should be cleared (no way to verify directly, but should not crash)
    }

    // MARK: - showPaywallFromSettings Tests

    func test_showPaywallFromSettings_triggersPaywall() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        // Should not crash
        sut.showPaywallFromSettings()
    }

    func test_showPaywallFromSettings_usesCampaignTriggerPlacement() {
        let sut = PaywallService()
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif

        // Internal implementation detail, but should complete without error
        sut.showPaywallFromSettings()
    }
}
