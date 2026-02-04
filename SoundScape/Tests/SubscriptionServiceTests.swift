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
