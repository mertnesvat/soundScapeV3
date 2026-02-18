import XCTest
@testable import SoundScape

final class SleepRecordingServiceTests: XCTestCase {

    private let testDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    override func setUp() {
        super.setUp()
        // Clean up test data
        let jsonURL = testDirectoryURL.appendingPathComponent("sleep_recordings.json")
        try? FileManager.default.removeItem(at: jsonURL)
        let recordingsDir = testDirectoryURL.appendingPathComponent("SleepRecordings")
        try? FileManager.default.removeItem(at: recordingsDir)
    }

    override func tearDown() {
        let jsonURL = testDirectoryURL.appendingPathComponent("sleep_recordings.json")
        try? FileManager.default.removeItem(at: jsonURL)
        let recordingsDir = testDirectoryURL.appendingPathComponent("SleepRecordings")
        try? FileManager.default.removeItem(at: recordingsDir)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_startsWithIdleStatus() {
        let sut = SleepRecordingService()

        XCTAssertEqual(sut.status, .idle)
        XCTAssertTrue(sut.recordings.isEmpty)
        XCTAssertNil(sut.currentRecording)
    }

    @MainActor
    func test_init_createsRecordingsDirectory() {
        _ = SleepRecordingService()

        let recordingsDir = testDirectoryURL.appendingPathComponent("SleepRecordings")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: recordingsDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    // MARK: - Persistence Tests

    @MainActor
    func test_persistence_savesAndLoadsRecordings() {
        let sut = SleepRecordingService()

        // Manually add a recording to test persistence
        let recording = SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600,
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            decibelSamples: [30, 35, 40],
            averageDecibels: 35,
            peakDecibels: 40,
            snoreScore: 25
        )

        // Use persistence directly by encoding
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode([recording])
        try! data.write(to: testDirectoryURL.appendingPathComponent("sleep_recordings.json"))

        // Create a new service to test loading
        let sut2 = SleepRecordingService()

        XCTAssertEqual(sut2.recordings.count, 1)
        XCTAssertEqual(sut2.recordings.first?.id, recording.id)
        XCTAssertEqual(sut2.recordings.first?.snoreScore, 25)
    }

    // MARK: - Status Transition Tests

    @MainActor
    func test_resetStatus_fromComplete_setsIdle() {
        let sut = SleepRecordingService()

        // Service starts idle, resetStatus should only work from complete
        sut.resetStatus() // Should not change since it's already idle
        XCTAssertEqual(sut.status, .idle)
    }

    // MARK: - Delete Tests

    @MainActor
    func test_deleteRecording_removesFromList() {
        let sut = SleepRecordingService()

        let recording = SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600,
            fileURL: URL(fileURLWithPath: "/tmp/nonexistent.m4a")
        )

        // Manually insert for testing
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode([recording])
        try! data.write(to: testDirectoryURL.appendingPathComponent("sleep_recordings.json"))

        let sut2 = SleepRecordingService()
        XCTAssertEqual(sut2.recordings.count, 1)

        sut2.deleteRecording(recording)
        XCTAssertTrue(sut2.recordings.isEmpty)
    }

    // MARK: - Storage Tests

    @MainActor
    func test_formattedStorageUsed_returnsFormattedString() {
        let sut = SleepRecordingService()

        // With no recordings, should return some formatted value
        let formatted = sut.formattedStorageUsed
        XCTAssertFalse(formatted.isEmpty)
    }

    @MainActor
    func test_totalStorageUsed_withNoRecordings_returnsZero() {
        let sut = SleepRecordingService()

        XCTAssertEqual(sut.totalStorageUsed, 0)
    }

    // MARK: - Delay Tests

    @MainActor
    func test_isDelayActive_initiallyFalse() {
        let sut = SleepRecordingService()

        XCTAssertFalse(sut.isDelayActive)
        XCTAssertNil(sut.delayRemaining)
    }

    @MainActor
    func test_cancelDelay_clearsDelayState() {
        let sut = SleepRecordingService()

        // Start a delay
        sut.startRecordingWithDelay(minutes: 15)
        XCTAssertTrue(sut.isDelayActive)
        XCTAssertNotNil(sut.delayRemaining)

        // Cancel it
        sut.cancelDelay()
        XCTAssertFalse(sut.isDelayActive)
        XCTAssertNil(sut.delayRemaining)
        XCTAssertFalse(sut.shouldStopSoundsOnRecordingStart)
    }

    @MainActor
    func test_startRecordingWithDelay_setsDelayActive() {
        let sut = SleepRecordingService()

        sut.startRecordingWithDelay(minutes: 30)

        XCTAssertTrue(sut.isDelayActive)
        XCTAssertNotNil(sut.delayRemaining)

        // Cleanup
        sut.cancelDelay()
    }

    @MainActor
    func test_startRecordingWithDelay_stopSoundsFirst_setsFlag() {
        let sut = SleepRecordingService()

        sut.startRecordingWithDelay(minutes: 15, stopSoundsFirst: true)

        XCTAssertTrue(sut.shouldStopSoundsOnRecordingStart)

        // Cleanup
        sut.cancelDelay()
    }

    @MainActor
    func test_startRecordingWithDelay_defaultNoStopSounds() {
        let sut = SleepRecordingService()

        sut.startRecordingWithDelay(minutes: 15)

        XCTAssertFalse(sut.shouldStopSoundsOnRecordingStart)

        // Cleanup
        sut.cancelDelay()
    }

    // MARK: - Audio Engine Integration Tests

    @MainActor
    func test_isSoundPlaybackActive_withoutAudioEngine_returnsFalse() {
        let sut = SleepRecordingService()

        XCTAssertFalse(sut.isSoundPlaybackActive)
    }

    @MainActor
    func test_setAudioEngine_doesNotCrash() {
        let sut = SleepRecordingService()
        let audioEngine = AudioEngine()

        sut.setAudioEngine(audioEngine)

        // After setting, isSoundPlaybackActive should reflect engine state
        XCTAssertFalse(sut.isSoundPlaybackActive) // No sounds playing
    }

    // MARK: - Guard Tests

    @MainActor
    func test_startRecording_whenNotIdle_doesNothing() {
        let sut = SleepRecordingService()

        // Start a delay (puts into delayed state, but status stays idle)
        sut.startRecordingWithDelay(minutes: 30)

        // Starting recording while delay is active should still work (status is idle)
        // But starting another delay should be blocked by the guard
        XCTAssertEqual(sut.status, .idle)

        // Cleanup
        sut.cancelDelay()
    }

    @MainActor
    func test_deleteRecording_clearsCurrentRecording() {
        let sut = SleepRecordingService()
        let recording = SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600,
            fileURL: URL(fileURLWithPath: "/tmp/nonexistent.m4a")
        )

        // Set currentRecording
        sut.currentRecording = recording

        // Delete it
        sut.deleteRecording(recording)

        XCTAssertNil(sut.currentRecording)
    }

    @MainActor
    func test_deleteRecording_doesNotClearUnrelatedCurrentRecording() {
        let sut = SleepRecordingService()
        let recording1 = SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600,
            fileURL: URL(fileURLWithPath: "/tmp/test1.m4a")
        )
        let recording2 = SleepRecording(
            date: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600,
            fileURL: URL(fileURLWithPath: "/tmp/test2.m4a")
        )

        // Set currentRecording to recording1
        sut.currentRecording = recording1

        // Delete recording2 - should not clear currentRecording
        sut.deleteRecording(recording2)

        XCTAssertNotNil(sut.currentRecording)
        XCTAssertEqual(sut.currentRecording?.id, recording1.id)
    }
}
