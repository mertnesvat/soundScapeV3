import Foundation

struct OnboardingProfile: Codable, Equatable {
    var sleepGoal: OnboardingSleepGoal?
    var sleepChallenges: Set<OnboardingSleepChallenge>
    var preferredCategories: Set<String>
    var hasCompletedOnboarding: Bool
    var completedAt: Date?

    init() {
        self.sleepGoal = nil
        self.sleepChallenges = []
        self.preferredCategories = []
        self.hasCompletedOnboarding = false
        self.completedAt = nil
    }
}

enum OnboardingSleepGoal: String, Codable, CaseIterable {
    case fallAsleep = "fall_asleep"
    case stayAsleep = "stay_asleep"
    case wakeRefreshed = "wake_refreshed"
    case relaxation = "relaxation"
    case focus = "focus"
    case meditation = "meditation"

    var title: String {
        switch self {
        case .fallAsleep: return "Fall asleep faster"
        case .stayAsleep: return "Stay asleep longer"
        case .wakeRefreshed: return "Wake up refreshed"
        case .relaxation: return "Relaxation & stress relief"
        case .focus: return "Focus & productivity"
        case .meditation: return "Meditation & mindfulness"
        }
    }

    var icon: String {
        switch self {
        case .fallAsleep: return "moon.zzz.fill"
        case .stayAsleep: return "bed.double.fill"
        case .wakeRefreshed: return "sunrise.fill"
        case .relaxation: return "leaf.fill"
        case .focus: return "brain.head.profile"
        case .meditation: return "figure.mind.and.body"
        }
    }
}

enum OnboardingSleepChallenge: String, Codable, CaseIterable, Hashable {
    case racingThoughts = "racing_thoughts"
    case anxiety = "anxiety"
    case noise = "noise"
    case stress = "stress"
    case irregularSchedule = "irregular_schedule"
    case screenTime = "screen_time"

    var title: String {
        switch self {
        case .racingThoughts: return "Racing thoughts"
        case .anxiety: return "Anxiety & worry"
        case .noise: return "Noise disturbances"
        case .stress: return "Stress from work/life"
        case .irregularSchedule: return "Irregular schedule"
        case .screenTime: return "Screen time before bed"
        }
    }

    var icon: String {
        switch self {
        case .racingThoughts: return "brain"
        case .anxiety: return "heart.circle"
        case .noise: return "speaker.wave.3"
        case .stress: return "flame"
        case .irregularSchedule: return "clock.arrow.2.circlepath"
        case .screenTime: return "iphone"
        }
    }
}
