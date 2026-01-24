import XCTest
@testable import SoundScape

final class LocalSoundDataSourceTests: XCTestCase {

    // MARK: - Properties

    private var sut: LocalSoundDataSource!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        sut = LocalSoundDataSource.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - getAllSounds Tests

    func test_getAllSounds_returnsNonEmptyArray() {
        let sounds = sut.getAllSounds()

        XCTAssertFalse(sounds.isEmpty)
    }

    func test_getAllSounds_containsAllCategories() {
        let sounds = sut.getAllSounds()
        let categories = Set(sounds.map { $0.category })

        XCTAssertTrue(categories.contains(.noise), "Should contain noise category")
        XCTAssertTrue(categories.contains(.nature), "Should contain nature category")
        XCTAssertTrue(categories.contains(.weather), "Should contain weather category")
        XCTAssertTrue(categories.contains(.fire), "Should contain fire category")
        XCTAssertTrue(categories.contains(.music), "Should contain music category")
        XCTAssertTrue(categories.contains(.asmr), "Should contain ASMR category")
    }

    // MARK: - ASMR Category Tests

    func test_getAllSounds_containsASMRSounds() {
        let sounds = sut.getAllSounds()
        let asmrSounds = sounds.filter { $0.category == .asmr }

        XCTAssertFalse(asmrSounds.isEmpty, "Should contain ASMR sounds")
        XCTAssertEqual(asmrSounds.count, 10, "Should contain exactly 10 ASMR sounds")
    }

    func test_asmrSounds_haveUniqueIds() {
        let sounds = sut.getAllSounds()
        let asmrSounds = sounds.filter { $0.category == .asmr }
        let ids = asmrSounds.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All ASMR sound IDs should be unique")
    }

    func test_asmrSounds_haveValidFileNames() {
        let sounds = sut.getAllSounds()
        let asmrSounds = sounds.filter { $0.category == .asmr }

        for sound in asmrSounds {
            XCTAssertFalse(sound.fileName.isEmpty, "ASMR sound \(sound.id) should have a file name")
            XCTAssertTrue(sound.fileName.hasSuffix(".mp3"), "ASMR sound \(sound.id) should have .mp3 extension")
        }
    }

    func test_asmrSounds_containsExpectedSounds() {
        let sounds = sut.getAllSounds()
        let asmrSounds = sounds.filter { $0.category == .asmr }
        let asmrIds = Set(asmrSounds.map { $0.id })

        let expectedIds: Set<String> = [
            "page_turning",
            "gentle_brush_strokes",
            "gentle_tapping",
            "gentle_tapping_2",
            "gentle_tapping_3",
            "nail_tapping",
            "mechanical_keyboard",
            "mechanical_keyboard_2",
            "slime_squelching",
            "winter_forest_walk"
        ]

        XCTAssertEqual(asmrIds, expectedIds, "ASMR sounds should contain all expected IDs")
    }

    func test_asmrSounds_haveCorrectFileNamesMapping() {
        let sounds = sut.getAllSounds()
        let asmrSounds = sounds.filter { $0.category == .asmr }

        let expectedMappings: [String: String] = [
            "page_turning": "ASMR-page-turn.mp3",
            "gentle_brush_strokes": "ASMR-page-turn-2.mp3",
            "gentle_tapping": "ASMR-gentle-tap.mp3",
            "gentle_tapping_2": "ASMR-gentle-tap-2.mp3",
            "gentle_tapping_3": "ASMR-gentle-tap-3.mp3",
            "nail_tapping": "ASMR-nail-tap.mp3",
            "mechanical_keyboard": "ASMR-mechanical-keyboard.mp3",
            "mechanical_keyboard_2": "ASMR-mechanical-keyboard-2.mp3",
            "slime_squelching": "ASMR-wet-slime-squelching.mp3",
            "winter_forest_walk": "ASMR-winter-forrest-walk.mp3"
        ]

        for sound in asmrSounds {
            let expectedFileName = expectedMappings[sound.id]
            XCTAssertEqual(sound.fileName, expectedFileName, "Sound \(sound.id) should have file name \(expectedFileName ?? "nil")")
        }
    }

    // MARK: - Sound Entity Tests

    func test_allSounds_haveUniqueIds() {
        let sounds = sut.getAllSounds()
        let ids = sounds.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All sound IDs should be unique")
    }

    func test_allSounds_haveNonEmptyNames() {
        let sounds = sut.getAllSounds()

        for sound in sounds {
            XCTAssertFalse(sound.name.isEmpty, "Sound \(sound.id) should have a non-empty name")
        }
    }

    func test_allSounds_haveNonEmptyFileNames() {
        let sounds = sut.getAllSounds()

        for sound in sounds {
            XCTAssertFalse(sound.fileName.isEmpty, "Sound \(sound.id) should have a non-empty file name")
        }
    }

    func test_allSounds_defaultToNotFavorite() {
        let sounds = sut.getAllSounds()

        for sound in sounds {
            XCTAssertFalse(sound.isFavorite, "Sound \(sound.id) should default to not favorite")
        }
    }

    // MARK: - Category Distribution Tests

    func test_noiseCategory_containsExpectedCount() {
        let sounds = sut.getAllSounds()
        let noiseSounds = sounds.filter { $0.category == .noise }

        XCTAssertEqual(noiseSounds.count, 4, "Should contain 4 noise sounds")
    }

    func test_fireCategory_containsExpectedCount() {
        let sounds = sut.getAllSounds()
        let fireSounds = sounds.filter { $0.category == .fire }

        XCTAssertEqual(fireSounds.count, 2, "Should contain 2 fire sounds")
    }
}
