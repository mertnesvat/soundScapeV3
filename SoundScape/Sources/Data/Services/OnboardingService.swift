import Foundation

@Observable
@MainActor
final class OnboardingService {
    private let profileKey = "onboarding_profile"
    private let firstLaunchKey = "onboarding_first_launch_time"
    private let firstSoundTrackedKey = "onboarding_first_sound_tracked"
    private(set) var profile: OnboardingProfile
    private var analyticsService: AnalyticsService?

    var hasCompletedOnboarding: Bool {
        profile.hasCompletedOnboarding
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(OnboardingProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = OnboardingProfile()
        }
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    // MARK: - First Launch Tracking

    func recordFirstLaunchIfNeeded() {
        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        }
    }

    func trackFirstSoundPlayed() {
        guard !UserDefaults.standard.bool(forKey: firstSoundTrackedKey) else { return }
        guard let launchTime = UserDefaults.standard.object(forKey: firstLaunchKey) as? TimeInterval else { return }

        let elapsed = Int(Date().timeIntervalSince1970 - launchTime)
        analyticsService?.logFirstSoundPlayedTime(seconds: elapsed)
        UserDefaults.standard.set(true, forKey: firstSoundTrackedKey)
    }

    // MARK: - Onboarding Analytics

    func trackOnboardingStarted() {
        recordFirstLaunchIfNeeded()
        analyticsService?.logOnboardingStarted()
    }

    func trackStepCompleted(_ step: Int) {
        analyticsService?.logOnboardingStepCompleted(step: step)
    }

    func trackOnboardingSkipped(atStep step: Int) {
        analyticsService?.logOnboardingSkipped(atStep: step)
    }

    func trackIntentSelected(category: String) {
        analyticsService?.logIntentSelected(category: category)
    }

    func setSleepGoal(_ goal: OnboardingSleepGoal) {
        profile.sleepGoal = goal
        saveProfile()
    }

    func toggleChallenge(_ challenge: OnboardingSleepChallenge) {
        if profile.sleepChallenges.contains(challenge) {
            profile.sleepChallenges.remove(challenge)
        } else {
            profile.sleepChallenges.insert(challenge)
        }
        saveProfile()
    }

    func setPreferredCategories(_ categories: Set<String>) {
        profile.preferredCategories = categories
        saveProfile()
    }

    func setUserIntent(_ intent: UserIntent) {
        profile.userIntent = intent
        saveProfile()
    }

    func soundsForIntent(_ intent: UserIntent) -> [Sound] {
        let allSounds = LocalSoundDataSource.shared.getAllSounds()
        return intent.soundIds.compactMap { id in
            allSounds.first { $0.id == id }
        }
    }

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        profile.completedAt = Date()
        saveProfile()
        analyticsService?.logOnboardingCompleted()
    }

    func resetOnboarding() {
        profile = OnboardingProfile()
        saveProfile()
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    // Recommendation helpers based on profile
    var recommendedSoundCategories: [String] {
        var categories: [String] = []

        if profile.sleepChallenges.contains(.racingThoughts) ||
           profile.sleepChallenges.contains(.anxiety) {
            categories.append(contentsOf: ["Noise", "Weather"])
        }

        if profile.sleepChallenges.contains(.noise) {
            categories.append("Noise")
        }

        if profile.sleepChallenges.contains(.stress) {
            categories.append(contentsOf: ["Nature", "Music"])
        }

        if profile.sleepGoal == .focus {
            categories.append(contentsOf: ["Noise", "Music"])
        }

        if profile.sleepGoal == .meditation || profile.sleepGoal == .relaxation {
            categories.append(contentsOf: ["Nature", "Music"])
        }

        return Array(Set(categories))
    }
}
