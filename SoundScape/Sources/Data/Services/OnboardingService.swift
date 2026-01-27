import Foundation

@Observable
@MainActor
final class OnboardingService {
    private let profileKey = "onboarding_profile"
    private(set) var profile: OnboardingProfile

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

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        profile.completedAt = Date()
        saveProfile()
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
