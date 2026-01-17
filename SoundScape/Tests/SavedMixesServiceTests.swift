import XCTest
@testable import SoundScape

final class SavedMixesServiceTests: XCTestCase {

    // MARK: - Setup and Teardown

    private var testFileURL: URL!

    override func setUp() {
        super.setUp()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        testFileURL = documentsPath.appendingPathComponent("saved_mixes.json")
        try? FileManager.default.removeItem(at: testFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testFileURL)
        testFileURL = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func makeActiveSound(id: String = "test", volume: Float = 0.7) -> ActiveSound {
        let sound = Sound(id: id, name: "Test", category: .noise, fileName: "test.mp3")
        return ActiveSound(id: id, sound: sound, volume: volume, isPlaying: true)
    }

    // MARK: - Initial State Tests

    func test_init_startsWithEmptyMixes() {
        let sut = SavedMixesService()

        XCTAssertTrue(sut.mixes.isEmpty)
    }

    // MARK: - saveMix Tests

    func test_saveMix_addsNewMixAtIndexZero() {
        let sut = SavedMixesService()
        let sounds = [makeActiveSound(id: "sound1"), makeActiveSound(id: "sound2")]

        sut.saveMix(name: "Test Mix", sounds: sounds)

        XCTAssertEqual(sut.mixes.count, 1)
        XCTAssertEqual(sut.mixes.first?.name, "Test Mix")
    }

    func test_saveMix_newestMixIsFirst() {
        let sut = SavedMixesService()

        sut.saveMix(name: "First Mix", sounds: [makeActiveSound(id: "s1")])
        sut.saveMix(name: "Second Mix", sounds: [makeActiveSound(id: "s2")])

        XCTAssertEqual(sut.mixes.count, 2)
        XCTAssertEqual(sut.mixes[0].name, "Second Mix")
        XCTAssertEqual(sut.mixes[1].name, "First Mix")
    }

    func test_saveMix_storesSoundsCorrectly() {
        let sut = SavedMixesService()
        let sounds = [
            makeActiveSound(id: "sound1", volume: 0.5),
            makeActiveSound(id: "sound2", volume: 0.8)
        ]

        sut.saveMix(name: "Test Mix", sounds: sounds)

        let savedMix = sut.mixes.first!
        XCTAssertEqual(savedMix.sounds.count, 2)
        XCTAssertEqual(savedMix.sounds[0].soundId, "sound1")
        XCTAssertEqual(savedMix.sounds[0].volume, 0.5)
        XCTAssertEqual(savedMix.sounds[1].soundId, "sound2")
        XCTAssertEqual(savedMix.sounds[1].volume, 0.8)
    }

    // MARK: - deleteMix Tests

    func test_deleteMix_removesCorrectMixById() {
        let sut = SavedMixesService()

        sut.saveMix(name: "Mix 1", sounds: [makeActiveSound(id: "s1")])
        sut.saveMix(name: "Mix 2", sounds: [makeActiveSound(id: "s2")])

        let mixToDelete = sut.mixes[0]
        sut.deleteMix(mixToDelete)

        XCTAssertEqual(sut.mixes.count, 1)
        XCTAssertEqual(sut.mixes[0].name, "Mix 1")
    }

    func test_deleteMix_withNonexistentMix_doesNotCrash() {
        let sut = SavedMixesService()
        sut.saveMix(name: "Test Mix", sounds: [makeActiveSound()])

        let fakeMix = SavedMix(
            id: UUID(),
            name: "Fake",
            sounds: [],
            createdAt: Date()
        )

        sut.deleteMix(fakeMix)

        XCTAssertEqual(sut.mixes.count, 1)
    }

    // MARK: - renameMix Tests

    func test_renameMix_updatesNameCorrectly() {
        let sut = SavedMixesService()
        sut.saveMix(name: "Original Name", sounds: [makeActiveSound()])

        let mix = sut.mixes[0]
        sut.renameMix(mix, to: "New Name")

        XCTAssertEqual(sut.mixes[0].name, "New Name")
    }

    func test_renameMix_withNonexistentMix_doesNotCrash() {
        let sut = SavedMixesService()
        sut.saveMix(name: "Test", sounds: [makeActiveSound()])

        let fakeMix = SavedMix(
            id: UUID(),
            name: "Fake",
            sounds: [],
            createdAt: Date()
        )

        sut.renameMix(fakeMix, to: "New Name")

        XCTAssertEqual(sut.mixes[0].name, "Test")
    }

    // MARK: - Persistence Tests

    func test_mixes_persistAfterSaveLoadCycle() {
        let sut1 = SavedMixesService()
        sut1.saveMix(name: "Persistent Mix", sounds: [makeActiveSound(id: "sound1", volume: 0.6)])

        let sut2 = SavedMixesService()

        XCTAssertEqual(sut2.mixes.count, 1)
        XCTAssertEqual(sut2.mixes[0].name, "Persistent Mix")
        XCTAssertEqual(sut2.mixes[0].sounds[0].soundId, "sound1")
        XCTAssertEqual(sut2.mixes[0].sounds[0].volume, 0.6)
    }

    func test_savingMultipleMixes_maintainsCorrectOrder() {
        let sut = SavedMixesService()

        sut.saveMix(name: "Mix A", sounds: [makeActiveSound()])
        sut.saveMix(name: "Mix B", sounds: [makeActiveSound()])
        sut.saveMix(name: "Mix C", sounds: [makeActiveSound()])

        XCTAssertEqual(sut.mixes[0].name, "Mix C")
        XCTAssertEqual(sut.mixes[1].name, "Mix B")
        XCTAssertEqual(sut.mixes[2].name, "Mix A")
    }

    // MARK: - Edge Cases

    func test_saveMix_withEmptySounds_works() {
        let sut = SavedMixesService()

        sut.saveMix(name: "Empty Mix", sounds: [])

        XCTAssertEqual(sut.mixes.count, 1)
        XCTAssertTrue(sut.mixes[0].sounds.isEmpty)
    }

    func test_saveMix_withEmptyName_works() {
        let sut = SavedMixesService()

        sut.saveMix(name: "", sounds: [makeActiveSound()])

        XCTAssertEqual(sut.mixes.count, 1)
        XCTAssertEqual(sut.mixes[0].name, "")
    }
}
