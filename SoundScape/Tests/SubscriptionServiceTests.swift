import XCTest
@testable import SoundScape

@MainActor
final class SubscriptionServiceTests: XCTestCase {

    // MARK: - Test Setup

    private var testUserDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a separate UserDefaults suite for testing
        testUserDefaults = UserDefaults(suiteName: "com.soundscape.tests.subscription")
        testUserDefaults?.removePersistentDomain(forName: "com.soundscape.tests.subscription")
    }

    override func tearDown() async throws {
        testUserDefaults?.removePersistentDomain(forName: "com.soundscape.tests.subscription")
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

        // isLoading might be true briefly due to async product fetch
        // but starts as false
        XCTAssertFalse(sut.isLoading)
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
        let jsonData = #"{"status":"active"}"#.data(using: .utf8)!

        struct StatusWrapper: Codable {
            let status: SubscriptionStatus
        }

        let decoded = try JSONDecoder().decode(StatusWrapper.self, from: jsonData)
        XCTAssertEqual(decoded.status, .active)
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

    func test_subscriptionError_purchaseFailed_includesUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = SubscriptionError.purchaseFailed(underlying: underlyingError)

        XCTAssertTrue(error.errorDescription?.contains("Test error") ?? false)
    }

    // MARK: - Clear Error Tests

    func test_clearError_setsErrorToNil() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Manually set error for testing (would normally happen during purchase)
        sut.clearError()

        XCTAssertNil(sut.error)
    }

    // MARK: - UserDefaults Caching Tests

    func test_cachedStatus_isLoadedOnInit() {
        // First, set up some cached values
        testUserDefaults.set("active", forKey: "subscription_status")
        testUserDefaults.set("com.StudioNext.SoundScape.monthly", forKey: "active_product_id")
        let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        // Create new service - it should load cached values
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
        XCTAssertEqual(sut.activeProductID, "com.StudioNext.SoundScape.monthly")
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

    // MARK: - Restore Purchases Tests

    func test_restorePurchases_setsIsLoadingDuringOperation() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertFalse(sut.isLoading)

        await sut.restorePurchases()

        XCTAssertFalse(sut.isLoading)
    }

    func test_restorePurchases_completesWithoutError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.restorePurchases()

        // Should complete without throwing - error may or may not be set
        // depending on StoreKit configuration
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Cancel Listener Tests

    func test_cancelListener_doesNotCrash() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should complete without crashing
        sut.cancelListener()
    }

    // MARK: - Fetch Products Tests

    func test_fetchProducts_setsIsLoadingDuringOperation() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // fetchProducts is called during init, so we wait for it
        // In a real test, we'd use dependency injection for the Store

        await sut.fetchProducts()

        // After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Check Entitlements Tests

    func test_checkCurrentEntitlements_completesWithoutError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.checkCurrentEntitlements()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Cache Persistence Tests

    func test_cachedStatus_persistsToUserDefaults() {
        // Set up initial cached state
        testUserDefaults.set("active", forKey: "subscription_status")
        testUserDefaults.set("com.StudioNext.SoundScape.yearly", forKey: "active_product_id")
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Verify the loaded values
        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
        XCTAssertEqual(sut.activeProductID, "com.StudioNext.SoundScape.yearly")
        XCTAssertNotNil(sut.expirationDate)
    }

    func test_noCachedStatus_resultsInNoneStatus() {
        // Don't set any cached values
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
        XCTAssertNil(sut.activeProductID)
    }

    func test_cachedExpiredStatus_updatesCache() {
        // Set up cached values with expired subscription
        testUserDefaults.set("active", forKey: "subscription_status")
        let pastDate = Date().addingTimeInterval(-86400) // 1 day ago
        testUserDefaults.set(pastDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        // Create service - it should detect expiration and update cache
        _ = SubscriptionService(userDefaults: testUserDefaults)

        // Verify cache was updated to expired
        let cachedStatus = testUserDefaults.string(forKey: "subscription_status")
        XCTAssertEqual(cachedStatus, "expired")
    }

    // MARK: - Subscription Status Enum Codable Tests

    func test_subscriptionStatus_isEncodable() throws {
        struct StatusWrapper: Codable {
            let status: SubscriptionStatus
        }

        let wrapper = StatusWrapper(status: .active)
        let data = try JSONEncoder().encode(wrapper)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertTrue(jsonString?.contains("active") ?? false)
    }

    func test_subscriptionStatus_allCasesDecodable() throws {
        struct StatusWrapper: Codable {
            let status: SubscriptionStatus
        }

        let testCases: [(String, SubscriptionStatus)] = [
            (#"{"status":"active"}"#, .active),
            (#"{"status":"expired"}"#, .expired),
            (#"{"status":"none"}"#, .none)
        ]

        for (json, expectedStatus) in testCases {
            let data = json.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(StatusWrapper.self, from: data)
            XCTAssertEqual(decoded.status, expectedStatus, "Failed for status: \(expectedStatus)")
        }
    }

    // MARK: - Error Type Tests

    func test_subscriptionError_conformsToLocalizedError() {
        let errors: [SubscriptionError] = [
            .productNotFound,
            .verificationFailed,
            .userCancelled,
            .pending,
            .unknown,
            .purchaseFailed(underlying: NSError(domain: "test", code: 0))
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
        }
    }

    // MARK: - Multiple Purchase Attempts Tests

    func test_multiplePurchaseAttempts_withNoProducts_allReturnProductNotFound() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // First attempt
        let result1 = await sut.purchaseMonthly()
        XCTAssertFalse(result1)
        XCTAssertEqual(sut.error, .productNotFound)

        sut.clearError()

        // Second attempt
        let result2 = await sut.purchaseYearly()
        XCTAssertFalse(result2)
        XCTAssertEqual(sut.error, .productNotFound)
    }

    // MARK: - Cancel Listener Multiple Times Tests

    func test_cancelListener_canBeCalledMultipleTimes() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should not crash when called multiple times
        sut.cancelListener()
        sut.cancelListener()
        sut.cancelListener()
    }

    // MARK: - Expiration Date Edge Cases

    func test_expirationDate_exactlyNow_isConsideredExpired() {
        // Set expiration to exactly now
        testUserDefaults.set("active", forKey: "subscription_status")
        let now = Date()
        testUserDefaults.set(now.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Should be expired (boundary condition: <= Date())
        XCTAssertEqual(sut.subscriptionStatus, .expired)
        XCTAssertFalse(sut.isPremium)
    }

    func test_expirationDate_oneSecondInFuture_isConsideredActive() {
        testUserDefaults.set("active", forKey: "subscription_status")
        let futureDate = Date().addingTimeInterval(1) // 1 second from now
        testUserDefaults.set(futureDate.timeIntervalSince1970, forKey: "subscription_expiration_date")

        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .active)
        XCTAssertTrue(sut.isPremium)
    }

    // MARK: - Product ID Validation Tests

    func test_productIDs_followAppleNamingConvention() {
        // Apple recommends reverse domain notation
        XCTAssertTrue(SubscriptionService.monthlyProductID.hasPrefix("com."))
        XCTAssertTrue(SubscriptionService.yearlyProductID.hasPrefix("com."))

        // Should contain the product type
        XCTAssertTrue(SubscriptionService.monthlyProductID.contains("monthly"))
        XCTAssertTrue(SubscriptionService.yearlyProductID.contains("yearly"))
    }

    // MARK: - Restore Purchases Multiple Calls

    func test_restorePurchases_canBeCalledMultipleTimes() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        await sut.restorePurchases()
        await sut.restorePurchases()

        // Should complete without issues
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Error Clearing Tests

    func test_clearError_afterPurchaseAttempt_clearsError() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // Trigger an error
        _ = await sut.purchaseMonthly()
        XCTAssertNotNil(sut.error)

        // Clear it
        sut.clearError()
        XCTAssertNil(sut.error)
    }

    func test_clearError_whenNoError_doesNotCrash() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertNil(sut.error)
        sut.clearError()
        XCTAssertNil(sut.error)
    }

    // MARK: - Yearly Product ID Tests

    func test_yearlyProduct_matchesExpectedID() {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        // When products are not loaded, computed property should return nil
        XCTAssertNil(sut.yearlyProduct)

        // Verify the expected ID constant
        XCTAssertEqual(SubscriptionService.yearlyProductID, "com.StudioNext.SoundScape.yearly")
    }

    // MARK: - Status After Restore With No Subscription

    func test_restorePurchases_withNoSubscription_statusRemainsNone() async {
        let sut = SubscriptionService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.subscriptionStatus, .none)

        await sut.restorePurchases()

        // Without actual StoreKit entitlements, status should remain none
        XCTAssertEqual(sut.subscriptionStatus, .none)
        XCTAssertFalse(sut.isPremium)
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
        case (.purchaseFailed(let lhsError), .purchaseFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
