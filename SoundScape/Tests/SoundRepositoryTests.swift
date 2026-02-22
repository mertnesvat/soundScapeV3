import XCTest
@testable import SoundScape

final class SoundRepositoryTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSUT() -> SoundRepository {
        return SoundRepository()
    }

    // MARK: - getAllSounds Tests

    func test_getAllSounds_returnsNonEmptyCollection() {
        let sut = makeSUT()

        let sounds = sut.getAllSounds()

        XCTAssertFalse(sounds.isEmpty, "Sound library should not be empty")
    }

    func test_getAllSounds_containsKnownSounds() {
        let sut = makeSUT()
        let sounds = sut.getAllSounds()
        let ids = sounds.map { $0.id }

        XCTAssertTrue(ids.contains("white_noise"), "Should contain white noise")
        XCTAssertTrue(ids.contains("rain_storm"), "Should contain rain storm")
        XCTAssertTrue(ids.contains("campfire"), "Should contain campfire")
    }

    func test_getAllSounds_allHaveUniqueIds() {
        let sut = makeSUT()
        let sounds = sut.getAllSounds()

        let ids = sounds.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All sound IDs should be unique")
    }

    func test_getAllSounds_allHaveNonEmptyNames() {
        let sut = makeSUT()
        let sounds = sut.getAllSounds()

        for sound in sounds {
            XCTAssertFalse(sound.name.isEmpty, "Sound \(sound.id) should have a non-empty name")
        }
    }

    func test_getAllSounds_allHaveFileNames() {
        let sut = makeSUT()
        let sounds = sut.getAllSounds()

        for sound in sounds {
            XCTAssertFalse(sound.fileName.isEmpty, "Sound \(sound.id) should have a file name")
        }
    }

    // MARK: - getSounds(byCategory:) Tests

    func test_getSoundsByCategory_returnsOnlyMatchingCategory() {
        let sut = makeSUT()

        let noiseSounds = sut.getSounds(byCategory: .noise)

        for sound in noiseSounds {
            XCTAssertEqual(sound.category, .noise, "Sound \(sound.id) should be in noise category")
        }
    }

    func test_getSoundsByCategory_eachCategoryHasSounds() {
        let sut = makeSUT()

        for category in SoundCategory.allCases {
            let sounds = sut.getSounds(byCategory: category)
            // Some categories might be empty but core ones should have sounds
            if category == .noise || category == .nature || category == .weather {
                XCTAssertFalse(sounds.isEmpty, "\(category.rawValue) category should have sounds")
            }
        }
    }

    func test_getSoundsByCategory_noise_containsExpectedSounds() {
        let sut = makeSUT()

        let noiseSounds = sut.getSounds(byCategory: .noise)
        let ids = noiseSounds.map { $0.id }

        XCTAssertTrue(ids.contains("white_noise"), "Noise category should contain white noise")
        XCTAssertTrue(ids.contains("pink_noise"), "Noise category should contain pink noise")
        XCTAssertTrue(ids.contains("brown_noise"), "Noise category should contain brown noise")
    }

    func test_getSoundsByCategory_allCategoriesCoverAllSounds() {
        let sut = makeSUT()

        let allSounds = sut.getAllSounds()
        var categorizedTotal = 0

        for category in SoundCategory.allCases {
            categorizedTotal += sut.getSounds(byCategory: category).count
        }

        XCTAssertEqual(categorizedTotal, allSounds.count, "Sum of category sounds should equal total sounds")
    }

    // MARK: - getSound(byId:) Tests

    func test_getSoundById_withValidId_returnsSound() {
        let sut = makeSUT()

        let sound = sut.getSound(byId: "white_noise")

        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.id, "white_noise")
    }

    func test_getSoundById_withInvalidId_returnsNil() {
        let sut = makeSUT()

        let sound = sut.getSound(byId: "nonexistent_sound_id")

        XCTAssertNil(sound)
    }

    func test_getSoundById_returnsCorrectProperties() {
        let sut = makeSUT()

        let sound = sut.getSound(byId: "rain_storm")

        XCTAssertNotNil(sound)
        XCTAssertEqual(sound?.category, .weather)
        XCTAssertFalse(sound?.name.isEmpty ?? true)
        XCTAssertFalse(sound?.fileName.isEmpty ?? true)
    }

    func test_getSoundById_emptyString_returnsNil() {
        let sut = makeSUT()

        let sound = sut.getSound(byId: "")

        XCTAssertNil(sound)
    }

    // MARK: - Consistency Tests

    func test_getSoundById_isConsistentWithGetAllSounds() {
        let sut = makeSUT()
        let allSounds = sut.getAllSounds()

        for sound in allSounds {
            let lookedUp = sut.getSound(byId: sound.id)
            XCTAssertEqual(lookedUp, sound, "Lookup for \(sound.id) should match getAllSounds")
        }
    }

    func test_getSoundsByCategory_isConsistentWithGetAllSounds() {
        let sut = makeSUT()
        let allSounds = sut.getAllSounds()

        for sound in allSounds {
            let categorySounds = sut.getSounds(byCategory: sound.category)
            XCTAssertTrue(categorySounds.contains(sound), "\(sound.id) should appear in its category's results")
        }
    }

    // MARK: - Sound Entity Tests

    func test_sound_equatable_sameProperties_areEqual() {
        let sound1 = Sound(id: "test", name: "Test", category: .noise, fileName: "test.mp3")
        let sound2 = Sound(id: "test", name: "Test", category: .noise, fileName: "test.mp3")

        XCTAssertEqual(sound1, sound2)
    }

    func test_sound_equatable_differentIds_areNotEqual() {
        let sound1 = Sound(id: "test1", name: "Test", category: .noise, fileName: "test.mp3")
        let sound2 = Sound(id: "test2", name: "Test", category: .noise, fileName: "test.mp3")

        XCTAssertNotEqual(sound1, sound2)
    }

    func test_sound_defaultIsFavorite_isFalse() {
        let sound = Sound(id: "test", name: "Test", category: .noise, fileName: "test.mp3")

        XCTAssertFalse(sound.isFavorite)
    }

    // MARK: - SoundCategory Tests

    func test_soundCategory_allCasesExist() {
        let allCases = SoundCategory.allCases
        XCTAssertTrue(allCases.contains(.noise))
        XCTAssertTrue(allCases.contains(.nature))
        XCTAssertTrue(allCases.contains(.weather))
        XCTAssertTrue(allCases.contains(.fire))
        XCTAssertTrue(allCases.contains(.music))
    }

    func test_soundCategory_eachHasIcon() {
        for category in SoundCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) should have an icon")
        }
    }

    func test_soundCategory_eachHasColor() {
        for category in SoundCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) should have a color")
        }
    }

    func test_soundCategory_eachHasLocalizedName() {
        for category in SoundCategory.allCases {
            XCTAssertFalse(category.localizedName.isEmpty, "\(category.rawValue) should have a localized name")
        }
    }
}
