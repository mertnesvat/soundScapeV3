import Foundation

enum AdaptiveMode: String, CaseIterable, Identifiable {
    case sleepCycle = "Sleep Cycle"
    case dayNight = "Day & Night"
    case weatherSync = "Weather Sync"
    case focusSession = "Focus Session"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sleepCycle: return "moon.stars.fill"
        case .dayNight: return "sun.and.horizon.fill"
        case .weatherSync: return "cloud.sun.fill"
        case .focusSession: return "timer"
        }
    }

    var description: String {
        switch self {
        case .sleepCycle: return "Sounds evolve through sleep stages"
        case .dayNight: return "Adapts to time of day"
        case .weatherSync: return "Matches weather patterns"
        case .focusSession: return "Pomodoro-style work sessions"
        }
    }

    var phases: [AdaptivePhase] {
        switch self {
        case .sleepCycle:
            return [
                AdaptivePhase(name: "Wind Down", sounds: ["serene_morning": 0.5, "pink_noise": 0.3], duration: 15),
                AdaptivePhase(name: "Drowsy", sounds: ["brown_noise": 0.5, "rain_storm": 0.3], duration: 20),
                AdaptivePhase(name: "Deep Sleep", sounds: ["brown_noise_deep": 0.6], duration: 40),
                AdaptivePhase(name: "Light Sleep", sounds: ["white_noise": 0.3], duration: 20),
            ]
        case .dayNight:
            return [
                AdaptivePhase(name: "Morning Energy", sounds: ["morning_birds": 0.6, "serene_morning": 0.4], duration: 30),
                AdaptivePhase(name: "Afternoon Calm", sounds: ["wind_ambient": 0.4, "pink_noise": 0.3], duration: 30),
                AdaptivePhase(name: "Evening Relax", sounds: ["campfire": 0.5, "rain_storm": 0.3], duration: 30),
                AdaptivePhase(name: "Night Wind Down", sounds: ["brown_noise": 0.4], duration: 30),
            ]
        case .weatherSync:
            return [
                AdaptivePhase(name: "Clear Skies", sounds: ["morning_birds": 0.5, "wind_ambient": 0.2], duration: 20),
                AdaptivePhase(name: "Cloudy", sounds: ["wind_ambient": 0.5, "pink_noise": 0.2], duration: 15),
                AdaptivePhase(name: "Rain", sounds: ["rain_storm": 0.7], duration: 25),
                AdaptivePhase(name: "Storm", sounds: ["rain_storm": 0.8, "wind_ambient": 0.4], duration: 15),
                AdaptivePhase(name: "Clearing", sounds: ["serene_morning": 0.4, "morning_birds": 0.3], duration: 15),
            ]
        case .focusSession:
            return [
                AdaptivePhase(name: "Focus", sounds: ["brown_noise": 0.5, "pink_noise": 0.2], duration: 25),
                AdaptivePhase(name: "Short Break", sounds: ["serene_morning": 0.4, "morning_birds": 0.3], duration: 5),
                AdaptivePhase(name: "Focus", sounds: ["brown_noise": 0.5, "pink_noise": 0.2], duration: 25),
                AdaptivePhase(name: "Short Break", sounds: ["campfire": 0.4], duration: 5),
                AdaptivePhase(name: "Focus", sounds: ["brown_noise_deep": 0.5], duration: 25),
                AdaptivePhase(name: "Long Break", sounds: ["rain_storm": 0.4, "wind_ambient": 0.2], duration: 15),
            ]
        }
    }
}

struct AdaptivePhase: Identifiable, Equatable {
    let id: UUID
    let name: String
    let sounds: [String: Float]  // soundId: volume
    let duration: Int  // minutes

    init(name: String, sounds: [String: Float], duration: Int) {
        self.id = UUID()
        self.name = name
        self.sounds = sounds
        self.duration = duration
    }

    static func == (lhs: AdaptivePhase, rhs: AdaptivePhase) -> Bool {
        lhs.id == rhs.id
    }
}
