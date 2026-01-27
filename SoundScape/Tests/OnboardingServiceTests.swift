import XCTest
@testable import SoundScape

@MainActor
final class OnboardingServiceTests: XCTestCase {

    // MARK: - Setup and Teardown

    private let testKey = "onboarding_profile"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_init_startsWithDefaultProfile() {
        let sut = OnboardingService()

        XCTAssertNil(sut.profile.sleepGoal)
        XCTAssertTrue(sut.profile.sleepChallenges.isEmpty)
        XCTAssertTrue(sut.profile.preferredCategories.isEmpty)
        XCTAssertFalse(sut.profile.hasCompletedOnboarding)
        XCTAssertNil(sut.profile.completedAt)
    }

    func test_hasCompletedOnboarding_initiallyFalse() {
        let sut = OnboardingService()

        XCTAssertFalse(sut.hasCompletedOnboarding)
    }

    // MARK: - Sleep Goal Tests

    func test_setSleepGoal_updatesProfile() {
        let sut = OnboardingService()

        sut.setSleepGoal(.fallAsleep)

        XCTAssertEqual(sut.profile.sleepGoal, .fallAsleep)
    }

    func test_setSleepGoal_canChangeGoal() {
        let sut = OnboardingService()

        sut.setSleepGoal(.fallAsleep)
        XCTAssertEqual(sut.profile.sleepGoal, .fallAsleep)

        sut.setSleepGoal(.focus)
        XCTAssertEqual(sut.profile.sleepGoal, .focus)
    }

    func test_setSleepGoal_persistsAcrossInstances() {
        let sut1 = OnboardingService()
        sut1.setSleepGoal(.meditation)

        let sut2 = OnboardingService()

        XCTAssertEqual(sut2.profile.sleepGoal, .meditation)
    }

    // MARK: - Sleep Challenge Tests

    func test_toggleChallenge_addsChallenge() {
        let sut = OnboardingService()

        sut.toggleChallenge(.racingThoughts)

        XCTAssertTrue(sut.profile.sleepChallenges.contains(.racingThoughts))
    }

    func test_toggleChallenge_removesExistingChallenge() {
        let sut = OnboardingService()

        sut.toggleChallenge(.anxiety)
        XCTAssertTrue(sut.profile.sleepChallenges.contains(.anxiety))

        sut.toggleChallenge(.anxiety)
        XCTAssertFalse(sut.profile.sleepChallenges.contains(.anxiety))
    }

    func test_toggleChallenge_multipleChallenges() {
        let sut = OnboardingService()

        sut.toggleChallenge(.racingThoughts)
        sut.toggleChallenge(.stress)
        sut.toggleChallenge(.noise)

        XCTAssertEqual(sut.profile.sleepChallenges.count, 3)
        XCTAssertTrue(sut.profile.sleepChallenges.contains(.racingThoughts))
        XCTAssertTrue(sut.profile.sleepChallenges.contains(.stress))
        XCTAssertTrue(sut.profile.sleepChallenges.contains(.noise))
    }

    func test_toggleChallenge_allChallenges() {
        let sut = OnboardingService()

        for challenge in OnboardingSleepChallenge.allCases {
            sut.toggleChallenge(challenge)
        }

        XCTAssertEqual(sut.profile.sleepChallenges.count, OnboardingSleepChallenge.allCases.count)
    }

    func test_toggleChallenge_persistsAcrossInstances() {
        let sut1 = OnboardingService()
        sut1.toggleChallenge(.anxiety)
        sut1.toggleChallenge(.stress)

        let sut2 = OnboardingService()

        XCTAssertTrue(sut2.profile.sleepChallenges.contains(.anxiety))
        XCTAssertTrue(sut2.profile.sleepChallenges.contains(.stress))
    }

    // MARK: - Preferred Categories Tests

    func test_setPreferredCategories_updatesProfile() {
        let sut = OnboardingService()
        let categories: Set<String> = ["Nature", "Music"]

        sut.setPreferredCategories(categories)

        XCTAssertEqual(sut.profile.preferredCategories, categories)
    }

    func test_setPreferredCategories_replacesExisting() {
        let sut = OnboardingService()

        sut.setPreferredCategories(["Nature"])
        XCTAssertEqual(sut.profile.preferredCategories, ["Nature"])

        sut.setPreferredCategories(["Music", "Noise"])
        XCTAssertEqual(sut.profile.preferredCategories, ["Music", "Noise"])
    }

    // MARK: - Complete Onboarding Tests

    func test_completeOnboarding_setsFlag() {
        let sut = OnboardingService()

        XCTAssertFalse(sut.hasCompletedOnboarding)

        sut.completeOnboarding()

        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func test_completeOnboarding_setsCompletedAt() {
        let sut = OnboardingService()

        XCTAssertNil(sut.profile.completedAt)

        sut.completeOnboarding()

        XCTAssertNotNil(sut.profile.completedAt)
    }

    func test_completeOnboarding_persistsAcrossInstances() {
        let sut1 = OnboardingService()
        sut1.completeOnboarding()

        let sut2 = OnboardingService()

        XCTAssertTrue(sut2.hasCompletedOnboarding)
    }

    // MARK: - Reset Onboarding Tests

    func test_resetOnboarding_clearsAllData() {
        let sut = OnboardingService()
        sut.setSleepGoal(.focus)
        sut.toggleChallenge(.stress)
        sut.setPreferredCategories(["Nature"])
        sut.completeOnboarding()

        sut.resetOnboarding()

        XCTAssertNil(sut.profile.sleepGoal)
        XCTAssertTrue(sut.profile.sleepChallenges.isEmpty)
        XCTAssertTrue(sut.profile.preferredCategories.isEmpty)
        XCTAssertFalse(sut.profile.hasCompletedOnboarding)
        XCTAssertNil(sut.profile.completedAt)
    }

    func test_resetOnboarding_persistsReset() {
        let sut1 = OnboardingService()
        sut1.completeOnboarding()
        sut1.resetOnboarding()

        let sut2 = OnboardingService()

        XCTAssertFalse(sut2.hasCompletedOnboarding)
    }

    // MARK: - Recommended Categories Tests

    func test_recommendedSoundCategories_withRacingThoughts_includesNoiseAndWeather() {
        let sut = OnboardingService()
        sut.toggleChallenge(.racingThoughts)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Noise"))
        XCTAssertTrue(recommended.contains("Weather"))
    }

    func test_recommendedSoundCategories_withAnxiety_includesNoiseAndWeather() {
        let sut = OnboardingService()
        sut.toggleChallenge(.anxiety)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Noise"))
        XCTAssertTrue(recommended.contains("Weather"))
    }

    func test_recommendedSoundCategories_withNoise_includesNoise() {
        let sut = OnboardingService()
        sut.toggleChallenge(.noise)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Noise"))
    }

    func test_recommendedSoundCategories_withStress_includesNatureAndMusic() {
        let sut = OnboardingService()
        sut.toggleChallenge(.stress)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Nature"))
        XCTAssertTrue(recommended.contains("Music"))
    }

    func test_recommendedSoundCategories_withFocusGoal_includesNoiseAndMusic() {
        let sut = OnboardingService()
        sut.setSleepGoal(.focus)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Noise"))
        XCTAssertTrue(recommended.contains("Music"))
    }

    func test_recommendedSoundCategories_withMeditationGoal_includesNatureAndMusic() {
        let sut = OnboardingService()
        sut.setSleepGoal(.meditation)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Nature"))
        XCTAssertTrue(recommended.contains("Music"))
    }

    func test_recommendedSoundCategories_withRelaxationGoal_includesNatureAndMusic() {
        let sut = OnboardingService()
        sut.setSleepGoal(.relaxation)

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.contains("Nature"))
        XCTAssertTrue(recommended.contains("Music"))
    }

    func test_recommendedSoundCategories_withNoSelections_isEmpty() {
        let sut = OnboardingService()

        let recommended = sut.recommendedSoundCategories

        XCTAssertTrue(recommended.isEmpty)
    }

    func test_recommendedSoundCategories_noDuplicates() {
        let sut = OnboardingService()
        sut.toggleChallenge(.racingThoughts)
        sut.toggleChallenge(.anxiety)
        sut.toggleChallenge(.noise)

        let recommended = sut.recommendedSoundCategories

        // Should contain unique values even though Noise appears in multiple conditions
        let uniqueCount = Set(recommended).count
        XCTAssertEqual(recommended.count, uniqueCount)
    }
}
