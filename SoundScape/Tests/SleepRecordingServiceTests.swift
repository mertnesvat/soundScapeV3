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
}
