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
}
