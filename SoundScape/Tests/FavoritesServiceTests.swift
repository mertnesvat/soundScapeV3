import XCTest
@testable import SoundScape

@MainActor
final class FavoritesServiceTests: XCTestCase {

    // MARK: - Setup and Teardown

    private let testKey = "favorited_sound_ids"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_init_startsWithEmptyFavorites() {
        let sut = FavoritesService()

        XCTAssertTrue(sut.favoritedIds.isEmpty)
    }

    // MARK: - isFavorite Tests

    func test_isFavorite_withUnfavoritedSound_returnsFalse() {
        let sut = FavoritesService()

        XCTAssertFalse(sut.isFavorite("unfavorited_sound"))
    }

    func test_isFavorite_afterToggle_returnsTrue() {
        let sut = FavoritesService()
        let soundId = "test_sound"

        sut.toggleFavorite(soundId)

        XCTAssertTrue(sut.isFavorite(soundId))
    }

    // MARK: - toggleFavorite Tests

    func test_toggleFavorite_addsSoundToFavorites() {
        let sut = FavoritesService()
        let soundId = "test_sound"

        XCTAssertFalse(sut.isFavorite(soundId))

        sut.toggleFavorite(soundId)

        XCTAssertTrue(sut.isFavorite(soundId))
    }

    func test_toggleFavorite_twice_returnsToOriginalState() {
        let sut = FavoritesService()
        let soundId = "test_sound"

        XCTAssertFalse(sut.isFavorite(soundId))

        sut.toggleFavorite(soundId)
        XCTAssertTrue(sut.isFavorite(soundId))

        sut.toggleFavorite(soundId)
        XCTAssertFalse(sut.isFavorite(soundId))
    }

    func test_toggleFavorite_multipleSounds_tracksAllCorrectly() {
        let sut = FavoritesService()

        sut.toggleFavorite("sound1")
        sut.toggleFavorite("sound2")
        sut.toggleFavorite("sound3")

        XCTAssertTrue(sut.isFavorite("sound1"))
        XCTAssertTrue(sut.isFavorite("sound2"))
        XCTAssertTrue(sut.isFavorite("sound3"))
        XCTAssertEqual(sut.favoritedIds.count, 3)
    }

    // MARK: - Persistence Tests

    func test_favorites_persistAfterSaveLoadCycle() {
        let soundId = "persistent_sound"

        let sut1 = FavoritesService()
        sut1.toggleFavorite(soundId)
        XCTAssertTrue(sut1.isFavorite(soundId))

        let sut2 = FavoritesService()

        XCTAssertTrue(sut2.isFavorite(soundId))
    }

    func test_favorites_persistMultipleSounds() {
        let sounds = ["sound1", "sound2", "sound3"]

        let sut1 = FavoritesService()
        for sound in sounds {
            sut1.toggleFavorite(sound)
        }

        let sut2 = FavoritesService()

        for sound in sounds {
            XCTAssertTrue(sut2.isFavorite(sound), "Expected \(sound) to be favorited")
        }
    }

    // MARK: - Edge Cases

    func test_toggleFavorite_withEmptyString_handlesGracefully() {
        let sut = FavoritesService()

        sut.toggleFavorite("")

        XCTAssertTrue(sut.isFavorite(""))
    }

    func test_isFavorite_withSpecialCharacters_works() {
        let sut = FavoritesService()
        let specialId = "sound-with_special.chars"

        sut.toggleFavorite(specialId)

        XCTAssertTrue(sut.isFavorite(specialId))
    }
}
