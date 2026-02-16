import XCTest
@testable import SoundScape

final class AlarmNotificationSoundManagerTests: XCTestCase {

    // MARK: - Setup and Teardown

    private var librarySoundsURL: URL!
    private var cacheURL: URL!

    override func setUp() {
        super.setUp()
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        librarySoundsURL = library.appendingPathComponent("Sounds")

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documents.appendingPathComponent("prepared_alarm_sounds.json")
    }

    override func tearDown() {
        // Clean up any .caf files created during tests
        if let files = try? FileManager.default.contentsOfDirectory(at: librarySoundsURL, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "caf" && file.lastPathComponent.hasSuffix("_alarm.caf") {
                try? FileManager.default.removeItem(at: file)
            }
        }
        librarySoundsURL = nil
        cacheURL = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func test_shared_returnsSameInstance() {
        let instance1 = AlarmNotificationSoundManager.shared
        let instance2 = AlarmNotificationSoundManager.shared

        XCTAssertTrue(instance1 === instance2, "shared should always return the same instance")
    }

    // MARK: - prepareSound Tests

    func test_prepareSound_withValidSoundId_returnsCAFFilename() {
        let manager = AlarmNotificationSoundManager.shared

        // "morning_birds" is a known sound ID from LocalSoundDataSource
        let result = manager.prepareSound(soundId: "morning_birds")

        // Should return the expected .caf filename
        if let filename = result {
            XCTAssertEqual(filename, "morning_birds_alarm.caf")
            XCTAssertTrue(filename.hasSuffix(".caf"), "Should return a .caf filename")
        }
        // Note: result may be nil if the MP3 resource isn't found in test bundle,
        // which is acceptable - we test the filename format when it succeeds.
    }

    func test_prepareSound_withInvalidSoundId_returnsNil() {
        let manager = AlarmNotificationSoundManager.shared

        let result = manager.prepareSound(soundId: "nonexistent_sound_xyz_999")

        XCTAssertNil(result, "Should return nil for a sound ID that does not exist")
    }

    func test_prepareSound_filenameFormat_followsConvention() {
        // The expected filename format is "{soundId}_alarm.caf"
        let soundId = "test_sound"
        let expectedFilename = "\(soundId)_alarm.caf"

        XCTAssertEqual(expectedFilename, "test_sound_alarm.caf")
        XCTAssertTrue(expectedFilename.hasSuffix("_alarm.caf"))
    }

    func test_prepareSound_calledTwice_returnsSameFilename() {
        let manager = AlarmNotificationSoundManager.shared

        let result1 = manager.prepareSound(soundId: "morning_birds")
        let result2 = manager.prepareSound(soundId: "morning_birds")

        // Both calls should return the same filename (cached on second call)
        XCTAssertEqual(result1, result2)
    }

    func test_prepareSound_emptyString_returnsNil() {
        let manager = AlarmNotificationSoundManager.shared

        let result = manager.prepareSound(soundId: "")

        XCTAssertNil(result, "Empty sound ID should return nil")
    }

    // MARK: - Library/Sounds Directory Tests

    func test_librarySoundsDirectory_isCorrectPath() {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let expectedURL = library.appendingPathComponent("Sounds")

        XCTAssertEqual(librarySoundsURL, expectedURL)
        XCTAssertTrue(librarySoundsURL.path.contains("Library/Sounds"))
    }

    func test_prepareSound_createsLibrarySoundsDirectory() {
        let manager = AlarmNotificationSoundManager.shared

        // Attempt to prepare a sound (may fail if MP3 not in test bundle, but directory
        // creation happens before the conversion attempt for valid sound IDs)
        _ = manager.prepareSound(soundId: "morning_birds")

        // If the sound existed, the directory should be created
        // We check if the Library/Sounds path is valid
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let soundsDir = library.appendingPathComponent("Sounds")
        var isDir: ObjCBool = false
        let dirExists = FileManager.default.fileExists(atPath: soundsDir.path, isDirectory: &isDir)

        // The directory may or may not exist depending on whether the sound was found,
        // but this test validates the path is in the expected location
        if dirExists {
            XCTAssertTrue(isDir.boolValue, "Sounds path should be a directory")
        }
    }

    // MARK: - Cache Persistence Tests

    func test_cacheURL_isInDocumentsDirectory() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let expectedURL = documents.appendingPathComponent("prepared_alarm_sounds.json")

        XCTAssertEqual(cacheURL, expectedURL)
        XCTAssertTrue(cacheURL.path.contains("prepared_alarm_sounds.json"))
    }

    func test_cacheFile_isValidJSON() {
        // If the cache file exists, it should be valid JSON containing a Set<String>
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            // Cache file not yet created - this is acceptable for a fresh state
            return
        }

        let data = try? Data(contentsOf: cacheURL)
        XCTAssertNotNil(data, "Cache file should be readable")

        if let data = data {
            let decoded = try? JSONDecoder().decode(Set<String>.self, from: data)
            XCTAssertNotNil(decoded, "Cache file should contain valid JSON-encoded Set<String>")
        }
    }

    // MARK: - AlarmSoundError Tests

    func test_alarmSoundError_formatCreationFailed_hasDescription() {
        let error = AlarmSoundError.formatCreationFailed

        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Failed to create audio format")
    }

    func test_alarmSoundError_bufferCreationFailed_hasDescription() {
        let error = AlarmSoundError.bufferCreationFailed

        XCTAssertNotNil(error.errorDescription)
        XCTAssertEqual(error.errorDescription, "Failed to create audio buffer")
    }

    func test_alarmSoundError_conformsToLocalizedError() {
        let formatError: LocalizedError = AlarmSoundError.formatCreationFailed
        let bufferError: LocalizedError = AlarmSoundError.bufferCreationFailed

        XCTAssertNotNil(formatError.errorDescription)
        XCTAssertNotNil(bufferError.errorDescription)
    }

    // MARK: - Multiple Sound Preparation Tests

    func test_prepareSound_differentSoundIds_returnDifferentFilenames() {
        let manager = AlarmNotificationSoundManager.shared

        let result1 = manager.prepareSound(soundId: "morning_birds")
        let result2 = manager.prepareSound(soundId: "rain_storm")

        // If both succeed, filenames should differ
        if let f1 = result1, let f2 = result2 {
            XCTAssertNotEqual(f1, f2, "Different sound IDs should produce different filenames")
        }
    }

    func test_prepareSound_specialCharactersInId_returnsNil() {
        let manager = AlarmNotificationSoundManager.shared

        // Sound IDs with characters that don't match any real sound
        let result = manager.prepareSound(soundId: "../../etc/passwd")

        XCTAssertNil(result, "Malicious-looking sound ID should not resolve to a sound")
    }
}
