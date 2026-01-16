import Foundation

struct SleepSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval  // seconds
    let quality: Int  // 0-100
    let soundsUsed: [String]  // sound IDs
    let timeToSleep: TimeInterval  // seconds
}

struct InsightMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let trend: Trend
    let icon: String

    enum Trend {
        case up, down, stable
    }
}

struct SoundRecommendation: Identifiable {
    let id = UUID()
    let soundId: String
    let soundName: String
    let reason: String
    let confidence: Double  // 0-1
}

struct SleepGoal: Identifiable, Codable {
    let id: UUID
    var targetDuration: TimeInterval  // target sleep hours in seconds
    var targetBedtime: Date?
    var targetWakeTime: Date?
}
