import XCTest
@testable import SoundScape

@MainActor
final class DelayedSmartPaywallTests: XCTestCase {

    // MARK: - Test Setup

    private var testUserDefaults: UserDefaults!
    private let testSuiteName = "com.soundscape.tests.delayed_paywall"

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

    // MARK: - Session Count Tests

    func test_init_sessionCountStartsAtZero() {
        let sut = PaywallService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut.sessionCount, 0)
    }

    func test_recordSession_incrementsSessionCount() {
        let sut = PaywallService(userDefaults: testUserDefaults)

        sut.recordSession()

        XCTAssertEqual(sut.sessionCount, 1)
    }

    func test_recordSession_incrementsMultipleTimes() {
        let sut = PaywallService(userDefaults: testUserDefaults)

        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        XCTAssertEqual(sut.sessionCount, 3)
    }

    func test_sessionCount_persistsAcrossInstances() {
        let sut1 = PaywallService(userDefaults: testUserDefaults)
        sut1.recordSession()
        sut1.recordSession()

        let sut2 = PaywallService(userDefaults: testUserDefaults)

        XCTAssertEqual(sut2.sessionCount, 2)
    }

    // MARK: - Grace Period Tests

    func test_isInGracePeriod_trueWhenSessionCountBelowThreshold() {
        let sut = PaywallService(userDefaults: testUserDefaults)

        XCTAssertTrue(sut.isInGracePeriod)
    }

    func test_isInGracePeriod_trueAfterOneSession() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        sut.recordSession()

        XCTAssertTrue(sut.isInGracePeriod)
    }

    func test_isInGracePeriod_trueAfterTwoSessions() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        sut.recordSession()
        sut.recordSession()

        XCTAssertTrue(sut.isInGracePeriod)
    }

    func test_isInGracePeriod_falseAfterThreeSessions() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        XCTAssertFalse(sut.isInGracePeriod)
    }

    func test_isInGracePeriod_falseAfterManySessions() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        for _ in 0..<10 {
            sut.recordSession()
        }

        XCTAssertFalse(sut.isInGracePeriod)
    }

    func test_gracePeriodSessions_isThree() {
        XCTAssertEqual(PaywallService.gracePeriodSessions, 3)
    }

    func test_freeSavedMixesLimit_isThree() {
        XCTAssertEqual(PaywallService.freeSavedMixesLimit, 3)
    }

    // MARK: - triggerSmartPaywall Grace Period Tests

    func test_triggerSmartPaywall_duringGracePeriod_callsOnGranted() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        var grantedCalled = false

        sut.triggerSmartPaywall(source: "test") {
            grantedCalled = true
        }

        XCTAssertTrue(grantedCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    func test_triggerSmartPaywall_afterGracePeriod_showsPaywall() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()
        var grantedCalled = false

        sut.triggerSmartPaywall(source: "test") {
            grantedCalled = true
        }

        XCTAssertFalse(grantedCalled)
        XCTAssertTrue(sut.showPaywall)
    }

    func test_triggerSmartPaywall_premiumUser_alwaysCallsOnGranted() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = true
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()
        var grantedCalled = false

        sut.triggerSmartPaywall(source: "test") {
            grantedCalled = true
        }

        XCTAssertTrue(grantedCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    func test_triggerSmartPaywall_storesPlacement() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "binaural_beats") {}

        XCTAssertEqual(sut.currentPaywallPlacement, "binaural_beats")
    }

    func test_triggerSmartPaywall_duringGracePeriod_doesNotSetPlacement() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif

        sut.triggerSmartPaywall(source: "test") {}

        // During grace period, paywall is not shown so no placement is set
        XCTAssertNil(sut.currentPaywallPlacement)
    }

    // MARK: - Smart Paywall Source Tracking Tests

    func test_triggerSmartPaywall_savedMixesSource() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "saved_mixes_limit") {}

        XCTAssertEqual(sut.currentPaywallPlacement, "saved_mixes_limit")
    }

    func test_triggerSmartPaywall_binauralBeatsSource() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "binaural_beats") {}

        XCTAssertEqual(sut.currentPaywallPlacement, "binaural_beats")
    }

    func test_triggerSmartPaywall_sleepStoriesSource() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "sleep_stories") {}

        XCTAssertEqual(sut.currentPaywallPlacement, "sleep_stories")
    }

    func test_triggerSmartPaywall_sleepRecordingSource() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "sleep_recording") {}

        XCTAssertEqual(sut.currentPaywallPlacement, "sleep_recording")
    }

    // MARK: - Dismiss & Purchase Flow Tests

    func test_triggerSmartPaywall_afterDismiss_canTriggerAgain() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()

        sut.triggerSmartPaywall(source: "first") {}
        XCTAssertTrue(sut.showPaywall)

        sut.handlePaywallDismissed()
        XCTAssertFalse(sut.showPaywall)

        sut.triggerSmartPaywall(source: "second") {}
        XCTAssertTrue(sut.showPaywall)
        XCTAssertEqual(sut.currentPaywallPlacement, "second")
    }

    func test_triggerSmartPaywall_afterPurchaseSuccess_callsOnGranted() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        sut.recordSession()
        sut.recordSession()
        sut.recordSession()
        var grantedCalled = false

        sut.triggerSmartPaywall(source: "test") {
            grantedCalled = true
        }
        XCTAssertFalse(grantedCalled)

        sut.handlePurchaseSuccess()
        XCTAssertTrue(grantedCalled)
        XCTAssertFalse(sut.showPaywall)
    }

    // MARK: - Grace Period Boundary Tests

    func test_isInGracePeriod_exactlyAtThreshold_isFalse() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        for _ in 0..<PaywallService.gracePeriodSessions {
            sut.recordSession()
        }

        XCTAssertFalse(sut.isInGracePeriod)
    }

    func test_isInGracePeriod_oneBeforeThreshold_isTrue() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        for _ in 0..<(PaywallService.gracePeriodSessions - 1) {
            sut.recordSession()
        }

        XCTAssertTrue(sut.isInGracePeriod)
    }

    // MARK: - Existing triggerPaywall Still Works

    func test_triggerPaywall_notAffectedByGracePeriod() {
        let sut = PaywallService(userDefaults: testUserDefaults)
        #if DEBUG
        sut.debugPremiumOverride = false
        #endif
        // Even during grace period, triggerPaywall should still show paywall
        XCTAssertTrue(sut.isInGracePeriod)

        sut.triggerPaywall(placement: "premium_sound") {}

        XCTAssertTrue(sut.showPaywall)
    }
}
