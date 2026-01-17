import XCTest
@testable import SoundScape

final class SleepTimerServiceTests: XCTestCase {

    // MARK: - Test Helpers

    @MainActor
    private func makeAudioEngine() -> AudioEngine {
        return AudioEngine()
    }

    @MainActor
    private func makeSleepTimerService(audioEngine: AudioEngine) -> SleepTimerService {
        return SleepTimerService(audioEngine: audioEngine)
    }

    // MARK: - Time Formatting Tests

    @MainActor
    func test_remainingTimeFormatted_withZeroSeconds_returnsZeroFormat() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        XCTAssertEqual(sut.remainingTimeFormatted, "00:00")
    }

    @MainActor
    func test_remainingTimeFormatted_afterStart_returnsCorrectFormat() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 5)

        XCTAssertEqual(sut.remainingTimeFormatted, "05:00")
    }

    @MainActor
    func test_remainingTimeFormatted_withOneMinute_returnsCorrectFormat() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 1)

        XCTAssertEqual(sut.remainingTimeFormatted, "01:00")
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_initializesTimerState() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 10)

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.remainingSeconds, 600)
        XCTAssertEqual(sut.totalSeconds, 600)
    }

    @MainActor
    func test_start_setsCorrectTotalSeconds() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 30)

        XCTAssertEqual(sut.totalSeconds, 1800)
        XCTAssertEqual(sut.remainingSeconds, 1800)
    }

    // MARK: - Progress Tests

    @MainActor
    func test_progress_withZeroTotal_returnsZero() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        XCTAssertEqual(sut.progress, 0.0)
    }

    @MainActor
    func test_progress_atStart_returnsOne() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 10)

        XCTAssertEqual(sut.progress, 1.0)
    }

    @MainActor
    func test_progress_isBetweenZeroAndOne() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 5)

        XCTAssertGreaterThanOrEqual(sut.progress, 0.0)
        XCTAssertLessThanOrEqual(sut.progress, 1.0)
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_resetsState() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 10)
        sut.cancel()

        XCTAssertFalse(sut.isActive)
        XCTAssertEqual(sut.remainingSeconds, 0)
        XCTAssertEqual(sut.totalSeconds, 0)
    }

    @MainActor
    func test_cancel_whenNotActive_doesNothing() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.cancel()

        XCTAssertFalse(sut.isActive)
        XCTAssertEqual(sut.remainingSeconds, 0)
    }

    @MainActor
    func test_start_afterCancel_resetsCorrectly() {
        let audioEngine = makeAudioEngine()
        let sut = makeSleepTimerService(audioEngine: audioEngine)

        sut.start(minutes: 10)
        sut.cancel()
        sut.start(minutes: 5)

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.remainingSeconds, 300)
        XCTAssertEqual(sut.totalSeconds, 300)
    }
}
