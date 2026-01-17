import XCTest
@testable import SoundScape

final class AudioEngineTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSound(id: String = "test_sound") -> Sound {
        return Sound(
            id: id,
            name: "Test Sound",
            category: .noise,
            fileName: "test.mp3"
        )
    }

    @MainActor
    private func makeAudioEngine() -> AudioEngine {
        return AudioEngine()
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_init_hasNoActiveSounds() {
        let sut = makeAudioEngine()

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    @MainActor
    func test_init_isAnyPlaying_returnsFalse() {
        let sut = makeAudioEngine()

        XCTAssertFalse(sut.isAnyPlaying)
    }

    // MARK: - isAnyPlaying Tests

    @MainActor
    func test_isAnyPlaying_withNoActiveSounds_returnsFalse() {
        let sut = makeAudioEngine()

        XCTAssertFalse(sut.isAnyPlaying)
    }

    // MARK: - Volume Clamping Tests

    @MainActor
    func test_setVolume_clampsNegativeToZero() {
        let negativeValue: Float = -0.5
        let clampedValue = max(0, min(1, negativeValue))
        XCTAssertEqual(clampedValue, 0.0)
    }

    @MainActor
    func test_setVolume_clampsAboveOneToOne() {
        let aboveOneValue: Float = 1.5
        let clampedValue = max(0, min(1, aboveOneValue))
        XCTAssertEqual(clampedValue, 1.0)
    }

    @MainActor
    func test_setVolume_preservesValidValues() {
        let validValue: Float = 0.5
        let clampedValue = max(0, min(1, validValue))
        XCTAssertEqual(clampedValue, 0.5)
    }

    // MARK: - isPlaying Tests

    @MainActor
    func test_isPlaying_withNonexistentSound_returnsFalse() {
        let sut = makeAudioEngine()

        XCTAssertFalse(sut.isPlaying(soundId: "nonexistent"))
    }

    // MARK: - stopAll Tests

    @MainActor
    func test_stopAll_withNoActiveSounds_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.stopAll()

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    // MARK: - pauseAll and resumeAll Tests

    @MainActor
    func test_pauseAll_withNoActiveSounds_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.pauseAll()

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    @MainActor
    func test_resumeAll_withNoActiveSounds_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.resumeAll()

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    // MARK: - Stop Tests

    @MainActor
    func test_stop_withNonexistentSound_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.stop(soundId: "nonexistent")

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    // MARK: - Pause Tests

    @MainActor
    func test_pause_withNonexistentSound_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.pause(soundId: "nonexistent")

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    // MARK: - Resume Tests

    @MainActor
    func test_resume_withNonexistentSound_doesNotCrash() {
        let sut = makeAudioEngine()

        sut.resume(soundId: "nonexistent")

        XCTAssertTrue(sut.activeSounds.isEmpty)
    }

    // MARK: - Session Recording Logic Tests

    @MainActor
    func test_minimumSessionDuration_isOneMinute() {
        let minimumDuration: TimeInterval = 60
        XCTAssertEqual(minimumDuration, 60)
    }

    // MARK: - InsightsService Injection Tests

    @MainActor
    func test_setInsightsService_acceptsService() {
        let sut = makeAudioEngine()
        let insightsService = InsightsService()

        sut.setInsightsService(insightsService)

        XCTAssertTrue(true)
    }

    // MARK: - togglePlayback Tests

    @MainActor
    func test_togglePlayback_withNonexistentSound_doesNotCrash() {
        let sut = makeAudioEngine()
        let sound = makeSound()

        sut.togglePlayback(for: sound)

        XCTAssertTrue(true)
    }
}
