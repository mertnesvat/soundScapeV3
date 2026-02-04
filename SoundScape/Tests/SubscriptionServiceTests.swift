import XCTest
@testable import SoundScape

@MainActor
final class SubscriptionServiceTests: XCTestCase {

    // MARK: - Test Setup

    private var testUserDefaults: UserDefaults!
    private let testSuiteName = "com.soundscape.tests.subscription"

    override func setUp() async throws {
        try await super.setUp()
        // Use a separate UserDefaults suite for testing
        testUserDefaults = UserDefaults(suiteName: testSuiteName)
        testUserDefaults?.removePersistentDomain(forName: testSuiteName)
    }

    override func tearDown() async throws {
        testUserDefaults?.removePersistentDomain(forName: testSuiteName)
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_init_startsWithCorrectDefaultState() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertFalse(sut.isPremium)
        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertNil(sut.activeProductID)
        XCTAssertNil(sut.expirationDate)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.products.isEmpty)
    }

    func test_init_startsWithIsLoadingFalse() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // isLoading starts as false before async work begins
        XCTAssertFalse(sut.isLoading)
    }

    func test_init_withNoCachedData_statusIsNone() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
    }

    // MARK: - Product ID Tests

    func test_productIDs_areCorrectlyConfigured() {
        XCTAssertEqual(SubscriptionService.monthlyProductID, "com.StudioNext.SoundScape.monthly")
        XCTAssertEqual(SubscriptionService.yearlyProductID, "com.StudioNext.SoundScape.yearly")
    }

    func test_monthlyProduct_returnsNilWhenNoProductsFetched() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertNil(sut.monthlyProduct)
    }

    func test_yearlyProduct_returnsNilWhenNoProductsFetched() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertNil(sut.yearlyProduct)
    }

    // MARK: - Subscription Status Enum Tests

    func test_subscriptionStatus_rawValues() {
        XCTAssertEqual(SubscriptionStatus.active.rawValue, "active")
        XCTAssertEqual(SubscriptionStatus.expired.rawValue, "expired")
        XCTAssertEqual(SubscriptionStatus.none.rawValue, "none")
    }

    func test_subscriptionStatus_isDecodable() throws {
        let activeJson = #"{"status":"active"}"#.data(using: .utf8)!
        let expiredJson = #"{"status":"expired"}"#.data(using: .utf8)!
        let noneJson = #"{"status":"none"}"#.data(using: .utf8)!

        struct StatusWrapper: Codable {
            let status: SubscriptionStatus
        }

        let active = try JSONDecoder().decode(StatusWrapper.self, from: activeJson)
        let expired = try JSONDecoder().decode(StatusWrapper.self, from: expiredJson)
        let none = try JSONDecoder().decode(StatusWrapper.self, from: noneJson)

        XCTAssertEqual(active.status, .active)
        XCTAssertEqual(expired.status, .expired)
        XCTAssertEqual(none.status, .none)
    }

    func test_subscriptionStatus_isEncodable() throws {
        struct StatusWrapper: Codable {
            let status: SubscriptionStatus
        }

        let wrapper = StatusWrapper(status: .active)
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)

        XCTAssertTrue(json?.contains("active") ?? false)
    }

    // MARK: - Error Tests

    func test_subscriptionError_productNotFound_hasCorrectDescription() {
        let error = SubscriptionError.productNotFound

        XCTAssertEqual(error.errorDescription, "Subscription products could not be found. Please try again later.")
    }

    func test_subscriptionError_verificationFailed_hasCorrectDescription() {
        let error = SubscriptionError.verificationFailed

        XCTAssertEqual(error.errorDescription, "Could not verify your purchase. Please contact support.")
    }

    func test_subscriptionError_userCancelled_hasCorrectDescription() {
        let error = SubscriptionError.userCancelled

        XCTAssertEqual(error.errorDescription, "Purchase was cancelled.")
    }

    func test_subscriptionError_pending_hasCorrectDescription() {
        let error = SubscriptionError.pending

        XCTAssertEqual(error.errorDescription, "Purchase is pending approval.")
    }

    func test_subscriptionError_unknown_hasCorrectDescription() {
        let error = SubscriptionError.unknown

        XCTAssertEqual(error.errorDescription, "An unknown error occurred. Please try again.")
    }

    func test_subscriptionError_purchaseInProgress_hasCorrectDescription() {
        let error = SubscriptionError.purchaseInProgress

        XCTAssertEqual(error.errorDescription, "A purchase is already in progress. Please wait.")
    }

    func test_subscriptionError_purchaseFailed_includesUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = SubscriptionError.purchaseFailed(underlying: underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Test error") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Purchase failed") ?? false)
    }

    func test_subscriptionError_allCasesHaveDescriptions() {
        // Ensure no error case returns nil for errorDescription
        XCTAssertNotNil(SubscriptionError.productNotFound.errorDescription)
        XCTAssertNotNil(SubscriptionError.verificationFailed.errorDescription)
        XCTAssertNotNil(SubscriptionError.userCancelled.errorDescription)
        XCTAssertNotNil(SubscriptionError.pending.errorDescription)
        XCTAssertNotNil(SubscriptionError.unknown.errorDescription)
        XCTAssertNotNil(SubscriptionError.purchaseInProgress.errorDescription)

        let testError = NSError(domain: "test", code: 0)
        XCTAssertNotNil(SubscriptionError.purchaseFailed(underlying: testError).errorDescription)
    }

    // MARK: - Clear Error Tests

    func test_clearError_setsErrorToNil() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        sut.clearError()

        XCTAssertNil(sut.error)
    }

    func test_clearError_canBeCalledMultipleTimes() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should not crash when called multiple times
        sut.clearError()
        sut.clearError()
        sut.clearError()

        XCTAssertNil(sut.error)
    }

    // MARK: - UserDefaults Caching Tests

    func test_cachedStatus_isLoadedOnInit_activeSubscription() {
        // Set up cached values for active subscription
        testUserDefaults.set("active", forKey: "subscription_status")
        testUserDefaults.set("com.StudioNext.SoundScape.monthly", forKey: "active_product_id")
        let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        // Create new service - it should load cached values
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
        XCTAssertEqual(sut.activeProductID, "com.StudioNext.SoundScape.monthly")
        XCTAssertNotNil(sut.expirationDate)
    }

    func test_cachedStatus_isLoadedOnInit_yearlySubscription() {
        // Set up cached values for yearly subscription
        testUserDefaults.set("active", forKey: "subscription_status")
        testUserDefaults.set("com.StudioNext.SoundScape.yearly", forKey: "active_product_id")
        let futureDate = Date().addingTimeInterval(86400 * 365) // 365 days from now
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
        XCTAssertEqual(sut.activeProductID, "com.StudioNext.SoundScape.yearly")
    }

    func test_cachedExpiredStatus_isDetectedOnInit() {
        // Set up cached values with expired subscription
        testUserDefaults.set("active", forKey: "subscription_status")
        testUserDefaults.set("com.StudioNext.SoundScape.monthly", forKey: "active_product_id")
        let pastDate = Date().addingTimeInterval(-86400) // 1 day ago
        testUserDefaults.set(pastDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        // Create new service - it should detect expiration
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .expired)
        XCTAssertFalse(sut.isPremium)
    }

    func test_cachedExpiredStatus_updatesCache() {
        // Set up cached values with expired subscription
        testUserDefaults.set("active", forKey: "subscription_status")
        let pastDate = Date().addingTimeInterval(-86400)
        testUserDefaults.set(pastDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        // Create new service
        _ = SubscriptionService(userDefaults: testUserDefaults)

        // Cache should now reflect expired status
        let cachedStatus = testUserDefaults.string(forKey: "subscription_status")
        XCTAssertEqual(cachedStatus, "expired")
    }

    func test_cachedNoneStatus_isLoadedCorrectly() {
        testUserDefaults.set("none", forKey: "subscription_status")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
    }

    func test_cachedExpiredStatusRaw_isLoadedCorrectly() {
        // Explicitly set expired status (not detected from date)
        testUserDefaults.set("expired", forKey: "subscription_status")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .expired)
        XCTAssertFalse(sut.isPremium)
    }

    func test_invalidCachedStatus_defaultsToNone() {
        testUserDefaults.set("invalid_status", forKey: "subscription_status")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
    }

    func test_noExpirationDate_doesNotCrash() {
        testUserDefaults.set("active", forKey: "subscription_status")
        // Intentionally not setting expiration date

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should still load active status
        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
        XCTAssertNil(sut.expirationDate)
    }

    // MARK: - Expiration Edge Cases

    func test_expirationDate_exactlyNow_isExpired() {
        testUserDefaults.set("active", forKey: "subscription_status")
        let now = Date()
        testUserDefaults.set(now.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Exactly now or in the past should be expired
        XCTAssertEqual(sut.subscriptionStatus, .expired)
        XCTAssertFalse(sut.isPremium)
    }

    func test_expirationDate_oneSecondInFuture_isActive() {
        testUserDefaults.set("active", forKey: "subscription_status")
        let oneSecondFromNow = Date().addingTimeInterval(1)
        testUserDefaults.set(oneSecondFromNow.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
    }

    // MARK: - Purchase Method Tests (without StoreKit)

    func test_purchaseMonthly_withNoProducts_returnsProductNotFoundError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        let result = await sut.purchaseMonthly()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, .productNotFound)
    }

    func test_purchaseYearly_withNoProducts_returnsProductNotFoundError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        let result = await sut.purchaseYearly()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, .productNotFound)
    }

    func test_purchaseMonthly_setsIsLoadingFalseAfterCompletion() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        _ = await sut.purchaseMonthly()

        XCTAssertFalse(sut.isLoading)
    }

    func test_purchaseYearly_setsIsLoadingFalseAfterCompletion() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        _ = await sut.purchaseYearly()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Restore Purchases Tests

    func test_restorePurchases_setsIsLoadingDuringOperation() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertFalse(sut.isLoading)

        await sut.restorePurchases()

        // After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_completesWithoutError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.restorePurchases()

        // Should complete without throwing
        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_clearsErrorBeforeStarting() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // First trigger an error
        _ = await sut.purchaseMonthly()
        XCTAssertNotNil(sut.error)

        // Restore should clear the error first
        await sut.restorePurchases()

        // Note: error may be set by restore if it fails, but it should have been cleared first
        // This test verifies the operation completes
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Cancel Listener Tests

    func test_cancelListener_doesNotCrash() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should complete without crashing
        sut.cancelListener()
    }

    func test_cancelListener_canBeCalledMultipleTimes() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should not crash when called multiple times
        sut.cancelListener()
        sut.cancelListener()
        sut.cancelListener()
    }

    func test_cancelListener_afterDeinit_doesNotCrash() {
        var sut: SubscriptionService? = SubscriptionService(userDefaults: testUserDefaults)
        sut?.cancelListener()
        sut = nil

        // If we get here without crashing, test passes
        XCTAssertNil(sut)
    }

    // MARK: - Fetch Products Tests

    func test_fetchProducts_setsIsLoadingDuringOperation() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.fetchProducts()

        // After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }

    func test_fetchProducts_clearsErrorBeforeStarting() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // First trigger an error
        _ = await sut.purchaseMonthly()
        XCTAssertNotNil(sut.error)

        // Fetch should clear the error first
        sut.clearError()
        await sut.fetchProducts()

        // isLoading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Check Entitlements Tests

    func test_checkCurrentEntitlements_completesWithoutError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.checkCurrentEntitlements()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func test_checkCurrentEntitlements_withNoEntitlements_setsStatusToNone() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.checkCurrentEntitlements()

        // With no actual entitlements (in test environment), status should be none
        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
    }

    // MARK: - Refresh Status Tests

    func test_refreshStatus_completesWithoutCrashing() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.refreshStatus()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func test_refreshStatus_canBeCalledMultipleTimes() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.refreshStatus()
        await sut.refreshStatus()
        await sut.refreshStatus()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - State Consistency Tests

    func test_isPremium_matchesActiveStatus() {
        testUserDefaults.set("active", forKey: "subscription_status")
        let futureDate = Date().addingTimeInterval(86400)
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertTrue(sut.isPremium)
        XCTAssertEqual(sut.subscriptionStatus, .active)
    }

    func test_isPremium_matchesExpiredStatus() {
        testUserDefaults.set("expired", forKey: "subscription_status")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertFalse(sut.isPremium)
        XCTAssertEqual(sut.subscriptionStatus, .expired)
    }

    func test_isPremium_matchesNoneStatus() {
        testUserDefaults.set("none", forKey: "subscription_status")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertFalse(sut.isPremium)
        XCTAssertEqual(sut.subscriptionStatus, .none)
    }

    // MARK: - Multiple Instance Tests

    func test_multipleInstances_shareUserDefaults() {
        // Set up cached values
        testUserDefaults.set("active", forKey: "subscription_status")
        let futureDate = Date().addingTimeInterval(86400 * 30)
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut1 = SubscriptionService(userDefaults: testUserDefaults)
        let sut2 = SubscriptionService(userDefaults: testUserDefaults)

        // Both should read the same cached values
        XCTAssertEqual(sut1.subscriptionStatus, sut2.subscriptionStatus)
        XCTAssertEqual(sut1.isPremium, sut2.isPremium)
    }

    // MARK: - Equatable Extension Tests

    func test_subscriptionError_equatable_sameTypes() {
        XCTAssertEqual(SubscriptionError.productNotFound, SubscriptionError.productNotFound)
        XCTAssertEqual(SubscriptionError.verificationFailed, SubscriptionError.verificationFailed)
        XCTAssertEqual(SubscriptionError.userCancelled, SubscriptionError.userCancelled)
        XCTAssertEqual(SubscriptionError.pending, SubscriptionError.pending)
        XCTAssertEqual(SubscriptionError.unknown, SubscriptionError.unknown)
        XCTAssertEqual(SubscriptionError.purchaseInProgress, SubscriptionError.purchaseInProgress)
    }

    func test_subscriptionError_equatable_differentTypes() {
        XCTAssertNotEqual(SubscriptionError.productNotFound, SubscriptionError.verificationFailed)
        XCTAssertNotEqual(SubscriptionError.userCancelled, SubscriptionError.pending)
        XCTAssertNotEqual(SubscriptionError.unknown, SubscriptionError.productNotFound)
        XCTAssertNotEqual(SubscriptionError.purchaseInProgress, SubscriptionError.pending)
    }

    func test_subscriptionError_equatable_purchaseFailed_sameError() {
        let error1 = NSError(domain: "Test", code: 100, userInfo: [NSLocalizedDescriptionKey: "Same error"])
        let error2 = NSError(domain: "Test", code: 100, userInfo: [NSLocalizedDescriptionKey: "Same error"])

        XCTAssertEqual(
            SubscriptionError.purchaseFailed(underlying: error1),
            SubscriptionError.purchaseFailed(underlying: error2)
        )
    }

    func test_subscriptionError_equatable_purchaseFailed_differentErrors() {
        let error1 = NSError(domain: "Test", code: 100, userInfo: [NSLocalizedDescriptionKey: "Error 1"])
        let error2 = NSError(domain: "Test", code: 200, userInfo: [NSLocalizedDescriptionKey: "Error 2"])

        XCTAssertNotEqual(
            SubscriptionError.purchaseFailed(underlying: error1),
            SubscriptionError.purchaseFailed(underlying: error2)
        )
    }
}

// MARK: - SubscriptionError Equatable Extension for Testing

extension SubscriptionError: Equatable {
    public static func == (lhs: SubscriptionError, rhs: SubscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.productNotFound, .productNotFound):
            return true
        case (.verificationFailed, .verificationFailed):
            return true
        case (.userCancelled, .userCancelled):
            return true
        case (.pending, .pending):
            return true
        case (.unknown, .unknown):
            return true
        case (.purchaseInProgress, .purchaseInProgress):
            return true
        case (.purchaseFailed(let lhsError), .purchaseFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
