import XCTest
@testable import SoundScape

final class StoryProgressServiceTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "story_progress")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "story_progress")
        super.tearDown()
    }

    private func makeSUT() -> StoryProgressService {
        return StoryProgressService()
    }

    private func makeStory(id: String = "story_1", duration: TimeInterval = 600) -> Story {
        return Story(
            id: id,
            title: "Test Story",
            narrator: "Test Narrator",
            duration: duration,
            category: .fiction,
            description: "A test story",
            audioFileName: "test.mp3"
        )
    }

    // MARK: - Initial State Tests

    func test_init_hasEmptyProgress() {
        let sut = makeSUT()

        XCTAssertTrue(sut.progress.isEmpty)
    }

    func test_init_inProgressStoryIdsIsEmpty() {
        let sut = makeSUT()

        XCTAssertTrue(sut.inProgressStoryIds.isEmpty)
    }

    // MARK: - Get Progress Tests

    func test_getProgress_forUnknownStory_returnsZero() {
        let sut = makeSUT()

        XCTAssertEqual(sut.getProgress(for: "nonexistent"), 0)
    }

    func test_getProgress_afterSetProgress_returnsCorrectValue() {
        let sut = makeSUT()

        sut.setProgress(120, for: "story_1")

        XCTAssertEqual(sut.getProgress(for: "story_1"), 120)
    }

    // MARK: - Set Progress Tests

    func test_setProgress_storesValue() {
        let sut = makeSUT()

        sut.setProgress(300, for: "story_1")

        XCTAssertEqual(sut.progress["story_1"], 300)
    }

    func test_setProgress_updatesExistingValue() {
        let sut = makeSUT()

        sut.setProgress(100, for: "story_1")
        sut.setProgress(200, for: "story_1")

        XCTAssertEqual(sut.getProgress(for: "story_1"), 200)
    }

    func test_setProgress_multipleStories_tracksIndependently() {
        let sut = makeSUT()

        sut.setProgress(100, for: "story_1")
        sut.setProgress(200, for: "story_2")

        XCTAssertEqual(sut.getProgress(for: "story_1"), 100)
        XCTAssertEqual(sut.getProgress(for: "story_2"), 200)
    }

    // MARK: - Clear Progress Tests

    func test_clearProgress_removesSpecificStory() {
        let sut = makeSUT()

        sut.setProgress(100, for: "story_1")
        sut.setProgress(200, for: "story_2")

        sut.clearProgress(for: "story_1")

        XCTAssertEqual(sut.getProgress(for: "story_1"), 0)
        XCTAssertEqual(sut.getProgress(for: "story_2"), 200)
    }

    func test_clearProgress_forNonexistentStory_doesNotCrash() {
        let sut = makeSUT()

        sut.clearProgress(for: "nonexistent")

        XCTAssertTrue(sut.progress.isEmpty)
    }

    func test_clearAllProgress_removesEverything() {
        let sut = makeSUT()

        sut.setProgress(100, for: "story_1")
        sut.setProgress(200, for: "story_2")

        sut.clearAllProgress()

        XCTAssertTrue(sut.progress.isEmpty)
    }

    // MARK: - In Progress Story IDs Tests

    func test_inProgressStoryIds_returnsOnlyStoriesWithPositiveProgress() {
        let sut = makeSUT()

        sut.setProgress(100, for: "story_1")
        sut.setProgress(0, for: "story_2")
        sut.setProgress(50, for: "story_3")

        let ids = sut.inProgressStoryIds
        XCTAssertEqual(Set(ids), Set(["story_1", "story_3"]))
    }

    func test_inProgressStoryIds_excludesZeroProgress() {
        let sut = makeSUT()

        sut.setProgress(0, for: "story_1")

        XCTAssertTrue(sut.inProgressStoryIds.isEmpty)
    }

    // MARK: - Progress Fraction Tests

    func test_progressFraction_withNoProgress_returnsZero() {
        let sut = makeSUT()
        let story = makeStory(duration: 600)

        XCTAssertEqual(sut.progressFraction(for: story), 0)
    }

    func test_progressFraction_atHalfway_returnsPointFive() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(300, for: "story_1")

        XCTAssertEqual(sut.progressFraction(for: story), 0.5, accuracy: 0.001)
    }

    func test_progressFraction_atCompletion_returnsOne() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(600, for: "story_1")

        XCTAssertEqual(sut.progressFraction(for: story), 1.0, accuracy: 0.001)
    }

    func test_progressFraction_beyondDuration_clampedToOne() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(1200, for: "story_1")

        XCTAssertEqual(sut.progressFraction(for: story), 1.0, accuracy: 0.001)
    }

    func test_progressFraction_withZeroDuration_returnsZero() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 0)

        sut.setProgress(100, for: "story_1")

        XCTAssertEqual(sut.progressFraction(for: story), 0)
    }

    // MARK: - Remaining Time Tests

    func test_remainingTime_withNoProgress_returnsDuration() {
        let sut = makeSUT()
        let story = makeStory(duration: 600)

        XCTAssertEqual(sut.remainingTime(for: story), 600)
    }

    func test_remainingTime_atHalfway_returnsHalf() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(300, for: "story_1")

        XCTAssertEqual(sut.remainingTime(for: story), 300, accuracy: 0.001)
    }

    func test_remainingTime_atCompletion_returnsZero() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(600, for: "story_1")

        XCTAssertEqual(sut.remainingTime(for: story), 0)
    }

    func test_remainingTime_beyondDuration_neverNegative() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(1200, for: "story_1")

        XCTAssertEqual(sut.remainingTime(for: story), 0)
    }

    // MARK: - Completion Tests

    func test_isCompleted_withNoProgress_returnsFalse() {
        let sut = makeSUT()
        let story = makeStory(duration: 600)

        XCTAssertFalse(sut.isCompleted(story))
    }

    func test_isCompleted_atHalfway_returnsFalse() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(300, for: "story_1")

        XCTAssertFalse(sut.isCompleted(story))
    }

    func test_isCompleted_at94Percent_returnsFalse() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        // 94% of 600 = 564
        sut.setProgress(564, for: "story_1")

        XCTAssertFalse(sut.isCompleted(story))
    }

    func test_isCompleted_at95Percent_returnsTrue() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        // 95% of 600 = 570
        sut.setProgress(570, for: "story_1")

        XCTAssertTrue(sut.isCompleted(story))
    }

    func test_isCompleted_at100Percent_returnsTrue() {
        let sut = makeSUT()
        let story = makeStory(id: "story_1", duration: 600)

        sut.setProgress(600, for: "story_1")

        XCTAssertTrue(sut.isCompleted(story))
    }

    // MARK: - Persistence Tests

    func test_progress_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.setProgress(300, for: "story_1")

        let sut2 = makeSUT()

        XCTAssertEqual(sut2.getProgress(for: "story_1"), 300)
    }

    func test_clearProgress_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.setProgress(300, for: "story_1")
        sut1.clearProgress(for: "story_1")

        let sut2 = makeSUT()

        XCTAssertEqual(sut2.getProgress(for: "story_1"), 0)
    }

    func test_clearAllProgress_persistsAcrossInstances() {
        let sut1 = makeSUT()
        sut1.setProgress(100, for: "story_1")
        sut1.setProgress(200, for: "story_2")
        sut1.clearAllProgress()

        let sut2 = makeSUT()

        XCTAssertTrue(sut2.progress.isEmpty)
    }

    // MARK: - Story Entity Tests

    func test_story_formattedDuration_lessThanOneHour() {
        let story = makeStory(duration: 600) // 10 minutes
        XCTAssertEqual(story.formattedDuration, "10 min")
    }

    func test_story_formattedDuration_exactlyOneHour() {
        let story = Story(
            id: "test", title: "Test", narrator: "Narrator",
            duration: 3600, category: .fiction, description: "Test",
            audioFileName: "test.mp3"
        )
        XCTAssertEqual(story.formattedDuration, "1h")
    }

    func test_story_formattedDuration_overOneHour() {
        let story = Story(
            id: "test", title: "Test", narrator: "Narrator",
            duration: 5400, category: .fiction, description: "Test",
            audioFileName: "test.mp3"
        )
        XCTAssertEqual(story.formattedDuration, "1h 30m")
    }

    func test_story_formattedDuration_zeroMinutes() {
        let story = makeStory(duration: 0) // 0 minutes
        XCTAssertEqual(story.formattedDuration, "0 min")
    }
}
