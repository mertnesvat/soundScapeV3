import XCTest
@testable import SoundScape

@MainActor
final class PremiumManagerTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSUT(isPremium: Bool = false) -> PremiumManager {
        let paywallService = PaywallService()
        // Note: PaywallService defaults to isPremium = false
        // For premium tests, we rely on the PremiumManager checking paywallService.isPremium
        return PremiumManager(paywallService: paywallService)
    }

    // MARK: - Sound Access Tests (80% Free)

    func test_freeSounds_allNoiseCategory_areFree() {
        let sut = makeSUT()

        // All 4 noise sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "white_noise")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "pink_noise")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "brown_noise")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "brown_noise_deep")))
    }

    func test_freeSounds_allNatureCategory_areFree() {
        let sut = makeSUT()

        // All 7 nature sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "morning_birds")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "winter_forest")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "serene_morning")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "spring_birds")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "meadow")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "night_wildlife")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "calm_ocean")))
    }

    func test_freeSounds_allWeatherCategory_areFree() {
        let sut = makeSUT()

        // All 6 weather sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "rain_storm")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "wind_ambient")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "rainforest")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "thunder")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "heavy_thunder")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "castle_wind")))
    }

    func test_freeSounds_allFireCategory_areFree() {
        let sut = makeSUT()

        // All 2 fire sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "campfire")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "bonfire")))
    }

    func test_freeSounds_mostMusicCategory_areFree() {
        let sut = makeSUT()

        // 6 of 8 music sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "creative_mind")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "cinematic_piano")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "ambient_melody")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "midnight_calm")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "ocean_lullaby")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "deep_focus_flow")))
    }

    func test_premiumSounds_twoMusicTracks_requirePremium() {
        let sut = makeSUT()

        // 2 premium music sounds
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "starlit_sky")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "forest_sanctuary")))
    }

    func test_freeSounds_someASMR_areFree() {
        let sut = makeSUT()

        // 4 of 11 ASMR sounds should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "page_turning")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "gentle_tapping")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "mechanical_keyboard")))
        XCTAssertFalse(sut.isPremiumRequired(for: .sound(id: "winter_forest_walk")))
    }

    func test_premiumSounds_mostASMR_requirePremium() {
        let sut = makeSUT()

        // 7 premium ASMR sounds (updated from 6 since gentle_brush_strokes should be premium)
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "gentle_brush_strokes")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "gentle_tapping_2")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "gentle_tapping_3")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "nail_tapping")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "mechanical_keyboard_2")))
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "slime_squelching")))
    }

    func test_freeSoundCount_isApproximately80Percent() {
        let sut = makeSUT()

        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        let freeSoundCount = allSounds.filter { !sut.isPremiumRequired(for: .sound(id: $0.id)) }.count
        let totalCount = allSounds.count

        let freePercentage = Double(freeSoundCount) / Double(totalCount)

        // Should be approximately 80% free (allowing 75-85% range)
        XCTAssertGreaterThanOrEqual(freePercentage, 0.75, "Free sounds should be at least 75%")
        XCTAssertLessThanOrEqual(freePercentage, 0.85, "Free sounds should be at most 85%")
    }

    // MARK: - Wind Down Content Tests (80% Free)

    func test_freeWindDown_mostYogaNidra_areFree() {
        let sut = makeSUT()

        // 2 of 3 yoga nidra sessions should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "yoga_nidra_5min")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "yoga_nidra_8min")))
    }

    func test_premiumWindDown_completeYogaNidra_requiresPremium() {
        let sut = makeSUT()

        // The longest yoga nidra is premium
        XCTAssertTrue(sut.isPremiumRequired(for: .windDownContent(id: "yoga_nidra_10min")))
    }

    func test_freeWindDown_mostStories_areFree() {
        let sut = makeSUT()

        // 4 of 5 stories should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "story_clockmakers_gift")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "story_garden_between_stars")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "story_last_lighthouse_keeper")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "story_mountain_learned_to_rest")))
    }

    func test_premiumWindDown_oneStory_requiresPremium() {
        let sut = makeSUT()

        // 1 premium story
        XCTAssertTrue(sut.isPremiumRequired(for: .windDownContent(id: "story_rivers_secret")))
    }

    func test_freeWindDown_mostHypnosis_areFree() {
        let sut = makeSUT()

        // 2 of 3 hypnosis sessions should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "hypnosis_floating")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "hypnosis_ocean")))
    }

    func test_premiumWindDown_oneHypnosis_requiresPremium() {
        let sut = makeSUT()

        // 1 premium hypnosis
        XCTAssertTrue(sut.isPremiumRequired(for: .windDownContent(id: "hypnosis_staircase")))
    }

    func test_freeWindDown_allAffirmations_areFree() {
        let sut = makeSUT()

        // All 3 affirmations should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "affirmation_gratitude")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "affirmation_peace")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "affirmation_release")))
    }

    func test_freeWindDown_allBreathingExercises_areFree() {
        let sut = makeSUT()

        // All breathing exercises (by prefix) should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "breathing_478")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "breathing_box")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "breathing_deep_sleep")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "breathing_relaxing")))
        XCTAssertFalse(sut.isPremiumRequired(for: .windDownContent(id: "breathing_anything")))
    }

    // MARK: - Brainwave State Tests (80% Free)

    func test_freeBrainwaveStates_fourOfFive_areFree() {
        let sut = makeSUT()

        // 4 of 5 brainwave states should be free
        XCTAssertFalse(sut.isPremiumRequired(for: .binauralBeat(state: .alpha)))
        XCTAssertFalse(sut.isPremiumRequired(for: .binauralBeat(state: .beta)))
        XCTAssertFalse(sut.isPremiumRequired(for: .binauralBeat(state: .theta)))
        XCTAssertFalse(sut.isPremiumRequired(for: .binauralBeat(state: .delta)))
    }

    func test_premiumBrainwaveState_gamma_requiresPremium() {
        let sut = makeSUT()

        // Only gamma is premium
        XCTAssertTrue(sut.isPremiumRequired(for: .binauralBeat(state: .gamma)))
    }

    // MARK: - Feature Gating Tests

    func test_unlimitedMixing_requiresPremium() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isPremiumRequired(for: .unlimitedMixing))
    }

    func test_adaptiveMode_requiresPremium() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isPremiumRequired(for: .adaptiveMode))
    }

    func test_fullInsights_requiresPremium() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isPremiumRequired(for: .fullInsights))
    }

    func test_discoverSave_requiresPremium() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isPremiumRequired(for: .discoverSave))
    }

    // MARK: - Convenience Method Tests

    func test_isSoundFree_returnsCorrectValue() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isSoundFree("white_noise"))
        XCTAssertTrue(sut.isSoundFree("campfire"))
        XCTAssertFalse(sut.isSoundFree("starlit_sky"))
        XCTAssertFalse(sut.isSoundFree("forest_sanctuary"))
    }

    func test_isBrainwaveStateFree_returnsCorrectValue() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isBrainwaveStateFree(.alpha))
        XCTAssertTrue(sut.isBrainwaveStateFree(.beta))
        XCTAssertTrue(sut.isBrainwaveStateFree(.theta))
        XCTAssertTrue(sut.isBrainwaveStateFree(.delta))
        XCTAssertFalse(sut.isBrainwaveStateFree(.gamma))
    }

    func test_isWindDownContentFree_returnsCorrectValue() {
        let sut = makeSUT()

        XCTAssertTrue(sut.isWindDownContentFree("yoga_nidra_5min"))
        XCTAssertTrue(sut.isWindDownContentFree("affirmation_gratitude"))
        XCTAssertTrue(sut.isWindDownContentFree("breathing_478"))
        XCTAssertFalse(sut.isWindDownContentFree("yoga_nidra_10min"))
        XCTAssertFalse(sut.isWindDownContentFree("story_rivers_secret"))
    }

    // MARK: - Unknown Content Tests

    func test_unknownSoundId_requiresPremium() {
        let sut = makeSUT()

        // Unknown sounds should default to premium (safer approach)
        XCTAssertTrue(sut.isPremiumRequired(for: .sound(id: "unknown_sound_id")))
    }

    func test_unknownWindDownContent_requiresPremium() {
        let sut = makeSUT()

        // Unknown wind down content should default to premium
        XCTAssertTrue(sut.isPremiumRequired(for: .windDownContent(id: "unknown_content_id")))
    }

    // MARK: - Business Rule Verification

    func test_premiumContent_totalCount_isApproximately20Percent() {
        let sut = makeSUT()

        // Verify sounds: should have ~20% premium
        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        let premiumSoundCount = allSounds.filter { sut.isPremiumRequired(for: .sound(id: $0.id)) }.count

        // Premium sounds should be 8 out of 38 (~21%)
        XCTAssertEqual(premiumSoundCount, 8, "Expected exactly 8 premium sounds")

        // Verify brainwave states: should have 1 premium (gamma)
        let premiumBrainwaveCount = BrainwaveState.allCases.filter {
            sut.isPremiumRequired(for: .binauralBeat(state: $0))
        }.count

        XCTAssertEqual(premiumBrainwaveCount, 1, "Expected exactly 1 premium brainwave state (gamma)")
    }
}
