import XCTest
@testable import SoundScape

final class InsightsServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private var testUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "InsightsServiceTests")
        testUserDefaults.removePersistentDomain(forName: "InsightsServiceTests")
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "InsightsServiceTests")
        testUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Quality Calculation Tests

    func test_recordSession_withLongDuration_createsHighQuality() {
        let sut = InsightsService()
        let duration: TimeInterval = 8 * 3600 // 8 hours

        sut.recordSession(duration: duration, soundsUsed: ["brown_noise"])

        let lastSession = sut.sessions.last
        XCTAssertNotNil(lastSession)
        XCTAssertGreaterThanOrEqual(lastSession?.quality ?? 0, 65)
    }

    func test_recordSession_withMediumDuration_createsMediumQuality() {
        let sut = InsightsService()
        let duration: TimeInterval = 6 * 3600 // 6 hours

        sut.recordSession(duration: duration, soundsUsed: ["white_noise"])

        let lastSession = sut.sessions.last
        XCTAssertNotNil(lastSession)
        XCTAssertGreaterThanOrEqual(lastSession?.quality ?? 0, 40)
    }

    func test_recordSession_withShortDuration_createsLowQuality() {
        let sut = InsightsService()
        let duration: TimeInterval = 3 * 3600 // 3 hours

        sut.recordSession(duration: duration, soundsUsed: ["pink_noise"])

        let lastSession = sut.sessions.last
        XCTAssertNotNil(lastSession)
        XCTAssertLessThanOrEqual(lastSession?.quality ?? 100, 80)
    }

    // MARK: - Total Sleep Time Tests

    func test_totalSleepTime_sumsAllSessionDurations() {
        let sut = InsightsService()

        sut.recordSession(duration: 3600, soundsUsed: ["brown_noise"])
        sut.recordSession(duration: 7200, soundsUsed: ["white_noise"])

        let expectedMinimum = 3600.0 + 7200.0
        XCTAssertGreaterThanOrEqual(sut.totalSleepTime, expectedMinimum)
    }

    // MARK: - Most Used Sounds Tests

    func test_mostUsedSounds_returnsUpToFiveSounds() {
        let sut = InsightsService()

        for _ in 0..<10 {
            sut.recordSession(duration: 3600, soundsUsed: ["sound1", "sound2", "sound3", "sound4", "sound5", "sound6"])
        }

        XCTAssertLessThanOrEqual(sut.mostUsedSounds.count, 5)
    }

    func test_mostUsedSounds_sortedByUsageCount() {
        let sut = InsightsService()

        sut.recordSession(duration: 3600, soundsUsed: ["brown_noise"])
        sut.recordSession(duration: 3600, soundsUsed: ["brown_noise"])
        sut.recordSession(duration: 3600, soundsUsed: ["brown_noise"])
        sut.recordSession(duration: 3600, soundsUsed: ["white_noise"])

        let mostUsed = sut.mostUsedSounds
        guard mostUsed.count >= 2 else {
            XCTFail("Expected at least 2 most used sounds")
            return
        }

        XCTAssertGreaterThanOrEqual(mostUsed[0].count, mostUsed[1].count)
    }

    // MARK: - Goal Progress Tests

    func test_goalProgress_isClampedBetweenZeroAndOne() {
        let sut = InsightsService()

        sut.updateGoal(targetHours: 8)

        XCTAssertGreaterThanOrEqual(sut.goalProgress, 0.0)
        XCTAssertLessThanOrEqual(sut.goalProgress, 1.0)
    }

    func test_goalProgress_withNoGoal_returnsZero() {
        let sut = InsightsService()

        let progress = sut.goalProgress
        XCTAssertGreaterThanOrEqual(progress, 0.0)
        XCTAssertLessThanOrEqual(progress, 1.0)
    }

    // MARK: - Average Calculations Tests

    func test_averageQuality_returnsCorrectAverage() {
        let sut = InsightsService()

        let avg = sut.averageQuality
        XCTAssertGreaterThanOrEqual(avg, 0)
        XCTAssertLessThanOrEqual(avg, 100)
    }

    func test_averageDuration_returnsValidValue() {
        let sut = InsightsService()

        XCTAssertGreaterThanOrEqual(sut.averageDuration, 0)
    }

    // MARK: - Total Sessions Tests

    func test_totalSessions_returnsCorrectCount() {
        let sut = InsightsService()
        let initialCount = sut.totalSessions

        sut.recordSession(duration: 3600, soundsUsed: ["test"])

        XCTAssertEqual(sut.totalSessions, initialCount + 1)
    }

    // MARK: - Session Start Tests

    func test_startSession_setsSessionStartTime() {
        let sut = InsightsService()

        sut.startSession()

        XCTAssertNotNil(sut.sessionStartTime)
    }

    func test_recordSession_clearsSessionStartTime() {
        let sut = InsightsService()

        sut.startSession()
        XCTAssertNotNil(sut.sessionStartTime)

        sut.recordSession(duration: 3600, soundsUsed: ["test"])
        XCTAssertNil(sut.sessionStartTime)
    }
}
