import XCTest
@testable import SoundScape

final class ReviewPromptServiceTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for test isolation
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "sessions_before_review_prompt")
        defaults.removeObject(forKey: "last_review_prompt_date")
        defaults.removeObject(forKey: "user_has_rated_app")
        defaults.removeObject(forKey: "review_prompt_count")
        defaults.removeObject(forKey: "favorites_action_count")
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "sessions_before_review_prompt")
        defaults.removeObject(forKey: "last_review_prompt_date")
        defaults.removeObject(forKey: "user_has_rated_app")
        defaults.removeObject(forKey: "review_prompt_count")
        defaults.removeObject(forKey: "favorites_action_count")
        super.tearDown()
    }

    @MainActor
    private func makeSUT() -> ReviewPromptService {
        return ReviewPromptService()
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_init_sessionCountIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.sessionCount, 0)
    }

    @MainActor
    func test_init_hasNotRated() {
        let sut = makeSUT()

        XCTAssertFalse(sut.hasUserRated)
    }

    @MainActor
    func test_init_promptCountIsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.promptCount, 0)
    }

    @MainActor
    func test_init_lastPromptDateIsNil() {
        let sut = makeSUT()

        XCTAssertNil(sut.lastPromptDate)
    }

    // MARK: - Session Counting Tests

    @MainActor
    func test_recordPositiveAction_incrementsSessionCount() {
        let sut = makeSUT()

        sut.recordPositiveAction()

        XCTAssertEqual(sut.sessionCount, 1)
    }

    @MainActor
    func test_recordPositiveAction_multipleIncrements() {
        let sut = makeSUT()

        sut.recordPositiveAction()
        sut.recordPositiveAction()
        sut.recordPositiveAction()

        XCTAssertEqual(sut.sessionCount, 3)
    }

    @MainActor
    func test_recordSuccessfulSleepSession_incrementsSessionCount() {
        let sut = makeSUT()

        sut.recordSuccessfulSleepSession()

        XCTAssertEqual(sut.sessionCount, 1)
    }

    @MainActor
    func test_recordMixSaved_incrementsSessionCount() {
        let sut = makeSUT()

        sut.recordMixSaved()

        XCTAssertEqual(sut.sessionCount, 1)
    }

    // MARK: - Favorite Action Counting Tests

    @MainActor
    func test_recordFavoriteAction_doesNotIncrementSessionCountForFirstTwo() {
        let sut = makeSUT()

        sut.recordFavoriteAction()
        XCTAssertEqual(sut.sessionCount, 0)

        sut.recordFavoriteAction()
        XCTAssertEqual(sut.sessionCount, 0)
    }

    @MainActor
    func test_recordFavoriteAction_incrementsAfterThreeFavorites() {
        let sut = makeSUT()

        sut.recordFavoriteAction()
        sut.recordFavoriteAction()
        sut.recordFavoriteAction()

        XCTAssertEqual(sut.sessionCount, 1)
    }

    @MainActor
    func test_recordFavoriteAction_resetsCounterAfterThree() {
        let sut = makeSUT()

        // First batch of 3
        sut.recordFavoriteAction()
        sut.recordFavoriteAction()
        sut.recordFavoriteAction()
        XCTAssertEqual(sut.sessionCount, 1)

        // Next favorite shouldn't increment yet
        sut.recordFavoriteAction()
        XCTAssertEqual(sut.sessionCount, 1)
    }

    // MARK: - Eligibility Tests

    @MainActor
    func test_canShowReviewPrompt_withZeroSessions_returnsFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.canShowReviewPrompt())
    }

    @MainActor
    func test_canShowReviewPrompt_withFewerThanRequiredSessions_returnsFalse() {
        let sut = makeSUT()

        sut.recordPositiveAction()
        sut.recordPositiveAction()

        XCTAssertFalse(sut.canShowReviewPrompt())
    }

    @MainActor
    func test_canShowReviewPrompt_withRequiredSessions_triggersReview() {
        let sut = makeSUT()

        // recordPositiveAction internally calls checkAndPromptForReviewIfEligible,
        // which auto-triggers requestReview() once eligibility is met.
        // So after 3 actions, a review has already been requested (promptCount > 0).
        sut.recordPositiveAction()
        sut.recordPositiveAction()

        // Before the 3rd action, eligibility should not yet be met
        XCTAssertFalse(sut.canShowReviewPrompt())

        // The 3rd action triggers the auto-review
        sut.recordPositiveAction()

        // Verify the review was auto-triggered
        XCTAssertEqual(sut.promptCount, 1, "Review should have been auto-triggered after reaching required sessions")
        XCTAssertNotNil(sut.lastPromptDate, "Last prompt date should be set after auto-trigger")
    }

    @MainActor
    func test_canShowReviewPrompt_afterUserRated_returnsFalse() {
        let sut = makeSUT()

        sut.recordPositiveAction()
        sut.recordPositiveAction()
        sut.recordPositiveAction()
        sut.markAsRated()

        XCTAssertFalse(sut.canShowReviewPrompt())
    }

    @MainActor
    func test_canShowReviewPrompt_afterMaxPrompts_returnsFalse() {
        let sut = makeSUT()

        // Build up enough sessions
        for _ in 0..<10 {
            sut.recordPositiveAction()
        }

        // Simulate 3 prompts (max per year)
        sut.requestReview()
        sut.requestReview()
        sut.requestReview()

        XCTAssertFalse(sut.canShowReviewPrompt())
    }

    // MARK: - Time Between Prompts Tests

    @MainActor
    func test_canShowReviewPrompt_withinMinimumDays_returnsFalse() {
        let sut = makeSUT()

        for _ in 0..<5 {
            sut.recordPositiveAction()
        }

        // Show first prompt
        sut.requestReview()

        // Should not show again within 30 days
        XCTAssertFalse(sut.canShowReviewPrompt())
    }

    // MARK: - Request Review Tests

    @MainActor
    func test_requestReview_incrementsPromptCount() {
        let sut = makeSUT()

        let initialCount = sut.promptCount
        sut.requestReview()

        XCTAssertEqual(sut.promptCount, initialCount + 1)
    }

    @MainActor
    func test_requestReview_setsLastPromptDate() {
        let sut = makeSUT()

        sut.requestReview()

        XCTAssertNotNil(sut.lastPromptDate)
    }

    // MARK: - Mark As Rated Tests

    @MainActor
    func test_markAsRated_setsHasUserRatedToTrue() {
        let sut = makeSUT()

        sut.markAsRated()

        XCTAssertTrue(sut.hasUserRated)
    }

    // MARK: - Mark As Declined Tests

    @MainActor
    func test_markAsDeclined_doesNotSetHasUserRated() {
        let sut = makeSUT()

        sut.markAsDeclined()

        XCTAssertFalse(sut.hasUserRated)
    }

    // MARK: - Reset Tests

    @MainActor
    func test_resetPromptState_clearsAllState() {
        let sut = makeSUT()

        sut.recordPositiveAction()
        sut.recordPositiveAction()
        sut.recordPositiveAction()
        sut.requestReview()
        sut.markAsRated()

        sut.resetPromptState()

        XCTAssertEqual(sut.sessionCount, 0)
        XCTAssertNil(sut.lastPromptDate)
        XCTAssertFalse(sut.hasUserRated)
        XCTAssertEqual(sut.promptCount, 0)
    }

    // MARK: - Persistence Tests

    @MainActor
    func test_sessionCount_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.recordPositiveAction()
        sut1.recordPositiveAction()

        let sut2 = makeSUT()

        XCTAssertEqual(sut2.sessionCount, 2)
    }

    @MainActor
    func test_hasUserRated_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.markAsRated()

        let sut2 = makeSUT()

        XCTAssertTrue(sut2.hasUserRated)
    }

    @MainActor
    func test_promptCount_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.requestReview()

        let sut2 = makeSUT()

        XCTAssertEqual(sut2.promptCount, 1)
    }

    // MARK: - Analytics Service Injection Tests

    @MainActor
    func test_setAnalyticsService_doesNotCrash() {
        let sut = makeSUT()
        let analytics = AnalyticsService()

        sut.setAnalyticsService(analytics)

        // No crash is success
        XCTAssertTrue(true)
    }
}
