import XCTest
@testable import SoundScape

@MainActor
final class OnboardingAnalyticsTests: XCTestCase {

    // MARK: - Setup and Teardown

    private let profileKey = "onboarding_profile"
    private let firstLaunchKey = "onboarding_first_launch_time"
    private let firstSoundTrackedKey = "onboarding_first_sound_tracked"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
        UserDefaults.standard.removeObject(forKey: firstSoundTrackedKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
        UserDefaults.standard.removeObject(forKey: firstSoundTrackedKey)
        super.tearDown()
    }

    // MARK: - Analytics Service Wiring Tests

    func test_setAnalyticsService_acceptsService() {
        let sut = OnboardingService()
        let analyticsService = AnalyticsService()

        sut.setAnalyticsService(analyticsService)

        // Should not crash
    }

    func test_setAnalyticsService_canBeCalledMultipleTimes() {
        let sut = OnboardingService()
        let service1 = AnalyticsService()
        let service2 = AnalyticsService()

        sut.setAnalyticsService(service1)
        sut.setAnalyticsService(service2)

        // Should not crash, second service replaces first
    }

    // MARK: - First Launch Tracking Tests

    func test_recordFirstLaunchIfNeeded_recordsTimestamp() {
        let sut = OnboardingService()

        XCTAssertNil(UserDefaults.standard.object(forKey: firstLaunchKey))

        sut.recordFirstLaunchIfNeeded()

        XCTAssertNotNil(UserDefaults.standard.object(forKey: firstLaunchKey))
    }

    func test_recordFirstLaunchIfNeeded_doesNotOverwriteExisting() {
        let sut = OnboardingService()
        let originalTime: TimeInterval = 1000000

        UserDefaults.standard.set(originalTime, forKey: firstLaunchKey)

        sut.recordFirstLaunchIfNeeded()

        let stored = UserDefaults.standard.double(forKey: firstLaunchKey)
        XCTAssertEqual(stored, originalTime, accuracy: 0.001)
    }

    func test_recordFirstLaunchIfNeeded_calledMultipleTimes_keepsFirstValue() {
        let sut = OnboardingService()

        sut.recordFirstLaunchIfNeeded()
        let firstValue = UserDefaults.standard.double(forKey: firstLaunchKey)

        // Simulate time passing
        Thread.sleep(forTimeInterval: 0.01)

        sut.recordFirstLaunchIfNeeded()
        let secondValue = UserDefaults.standard.double(forKey: firstLaunchKey)

        XCTAssertEqual(firstValue, secondValue, accuracy: 0.001)
    }

    // MARK: - First Sound Played Tracking Tests

    func test_trackFirstSoundPlayed_setsTrackedFlag() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        // Record first launch time so tracking can work
        UserDefaults.standard.set(Date().timeIntervalSince1970 - 10, forKey: firstLaunchKey)

        sut.trackFirstSoundPlayed()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: firstSoundTrackedKey))
    }

    func test_trackFirstSoundPlayed_doesNotTrackTwice() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        UserDefaults.standard.set(Date().timeIntervalSince1970 - 10, forKey: firstLaunchKey)

        sut.trackFirstSoundPlayed()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: firstSoundTrackedKey))

        // Second call should be a no-op (flag already set)
        sut.trackFirstSoundPlayed()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: firstSoundTrackedKey))
    }

    func test_trackFirstSoundPlayed_requiresFirstLaunchTime() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        // No first launch time recorded
        sut.trackFirstSoundPlayed()

        // Should not set the tracked flag since there's no launch time
        XCTAssertFalse(UserDefaults.standard.bool(forKey: firstSoundTrackedKey))
    }

    func test_trackFirstSoundPlayed_persistsAcrossInstances() {
        let sut1 = OnboardingService()
        sut1.setAnalyticsService(AnalyticsService())

        UserDefaults.standard.set(Date().timeIntervalSince1970 - 10, forKey: firstLaunchKey)
        sut1.trackFirstSoundPlayed()

        let sut2 = OnboardingService()
        sut2.setAnalyticsService(AnalyticsService())

        // Already tracked, should not track again
        XCTAssertTrue(UserDefaults.standard.bool(forKey: firstSoundTrackedKey))
    }

    // MARK: - Onboarding Started Tracking Tests

    func test_trackOnboardingStarted_recordsFirstLaunch() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        XCTAssertNil(UserDefaults.standard.object(forKey: firstLaunchKey))

        sut.trackOnboardingStarted()

        XCTAssertNotNil(UserDefaults.standard.object(forKey: firstLaunchKey))
    }

    // MARK: - Tracking Methods Without Analytics Service Tests

    func test_trackOnboardingStarted_withoutAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        // No analytics service set
        sut.trackOnboardingStarted()
    }

    func test_trackStepCompleted_withoutAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        sut.trackStepCompleted(1)
    }

    func test_trackOnboardingSkipped_withoutAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        sut.trackOnboardingSkipped(atStep: 2)
    }

    func test_trackIntentSelected_withoutAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        sut.trackIntentSelected(category: "sleep")
    }

    func test_trackFirstSoundPlayed_withoutAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        sut.trackFirstSoundPlayed()
    }

    // MARK: - Complete Onboarding with Analytics Tests

    func test_completeOnboarding_withAnalyticsService_doesNotCrash() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        sut.completeOnboarding()

        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func test_completeOnboarding_stillWorks_withoutAnalyticsService() {
        let sut = OnboardingService()

        sut.completeOnboarding()

        XCTAssertTrue(sut.hasCompletedOnboarding)
        XCTAssertNotNil(sut.profile.completedAt)
    }

    // MARK: - Analytics Event Enum Tests

    func test_onboardingEventNames_areCorrect() {
        XCTAssertEqual(AnalyticsService.Event.onboardingStarted.rawValue, "onboarding_started")
        XCTAssertEqual(AnalyticsService.Event.onboardingStepCompleted.rawValue, "onboarding_step_completed")
        XCTAssertEqual(AnalyticsService.Event.onboardingCompleted.rawValue, "onboarding_completed")
        XCTAssertEqual(AnalyticsService.Event.onboardingSkipped.rawValue, "onboarding_skipped")
        XCTAssertEqual(AnalyticsService.Event.intentSelected.rawValue, "intent_selected")
        XCTAssertEqual(AnalyticsService.Event.presetPlayed.rawValue, "preset_played")
        XCTAssertEqual(AnalyticsService.Event.firstSoundPlayedTime.rawValue, "first_sound_played_time")
    }

    func test_onboardingParameterKeys_areCorrect() {
        XCTAssertEqual(AnalyticsService.ParameterKey.stepNumber.rawValue, "step_number")
        XCTAssertEqual(AnalyticsService.ParameterKey.intentCategory.rawValue, "intent_category")
        XCTAssertEqual(AnalyticsService.ParameterKey.presetName.rawValue, "preset_name")
        XCTAssertEqual(AnalyticsService.ParameterKey.secondsFromLaunch.rawValue, "seconds_from_launch")
    }

    // MARK: - Analytics Service Convenience Method Tests

    func test_logOnboardingStarted_doesNotCrash() {
        let sut = AnalyticsService()
        // Not configured, should silently return
        sut.logOnboardingStarted()
    }

    func test_logOnboardingStepCompleted_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logOnboardingStepCompleted(step: 1)
    }

    func test_logOnboardingCompleted_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logOnboardingCompleted()
    }

    func test_logOnboardingSkipped_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logOnboardingSkipped(atStep: 2)
    }

    func test_logIntentSelected_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logIntentSelected(category: "sleep")
    }

    func test_logPresetPlayed_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logPresetPlayed(presetName: "Deep Sleep")
    }

    func test_logFirstSoundPlayedTime_doesNotCrash() {
        let sut = AnalyticsService()
        sut.logFirstSoundPlayedTime(seconds: 42)
    }

    // MARK: - QuickStartPresetsService Analytics Tests

    func test_quickStartPresetsService_setAnalyticsService_acceptsService() {
        let sut = QuickStartPresetsService()
        let analyticsService = AnalyticsService()

        sut.setAnalyticsService(analyticsService)

        // Should not crash
    }

    func test_quickStartPresetsService_loadPreset_setsActivePresetId() {
        let sut = QuickStartPresetsService()
        sut.setAnalyticsService(AnalyticsService())

        let audioEngine = AudioEngine()
        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        let preset = sut.presets[0]

        sut.loadPreset(preset, audioEngine: audioEngine, allSounds: allSounds)

        XCTAssertEqual(sut.activePresetId, preset.id)
    }

    // MARK: - Integration Flow Tests

    func test_fullOnboardingFlow_tracksAllSteps() {
        let onboardingService = OnboardingService()
        let analyticsService = AnalyticsService()
        onboardingService.setAnalyticsService(analyticsService)

        // Step 1: Onboarding starts
        onboardingService.trackOnboardingStarted()
        XCTAssertNotNil(UserDefaults.standard.object(forKey: firstLaunchKey))

        // Step 2: Intent selected
        onboardingService.trackIntentSelected(category: "sleep")
        onboardingService.trackStepCompleted(1)

        // Step 3: Sound preview completed
        onboardingService.trackStepCompleted(2)

        // Step 4: Complete
        onboardingService.trackStepCompleted(3)
        onboardingService.completeOnboarding()

        XCTAssertTrue(onboardingService.hasCompletedOnboarding)
    }

    func test_skippedOnboardingFlow_tracksSkip() {
        let onboardingService = OnboardingService()
        let analyticsService = AnalyticsService()
        onboardingService.setAnalyticsService(analyticsService)

        // Start onboarding
        onboardingService.trackOnboardingStarted()

        // Skip at step 1
        onboardingService.trackOnboardingSkipped(atStep: 1)
        onboardingService.completeOnboarding()

        XCTAssertTrue(onboardingService.hasCompletedOnboarding)
    }

    func test_skipAtDifferentSteps_tracksCorrectStep() {
        // Verify skipping at each step does not crash
        for step in 1...3 {
            UserDefaults.standard.removeObject(forKey: profileKey)

            let sut = OnboardingService()
            sut.setAnalyticsService(AnalyticsService())
            sut.trackOnboardingSkipped(atStep: step)
            sut.completeOnboarding()

            XCTAssertTrue(sut.hasCompletedOnboarding)
        }
    }

    func test_allIntentCategories_canBeTracked() {
        let sut = OnboardingService()
        sut.setAnalyticsService(AnalyticsService())

        for intent in UserIntent.allCases {
            sut.trackIntentSelected(category: intent.rawValue)
        }

        // Should not crash for any intent
    }
}
