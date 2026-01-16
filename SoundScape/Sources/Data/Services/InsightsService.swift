import Foundation

@Observable
final class InsightsService {
    private let sessionsKey = "sleep_sessions"
    private let goalKey = "sleep_goal"
    private(set) var sessions: [SleepSession] = []
    private(set) var sleepGoal: SleepGoal?

    // Track when user starts using sounds (for time-to-sleep estimation)
    private(set) var sessionStartTime: Date?

    // Sound name lookup
    private let soundNames: [String: String] = [
        "white_noise": "White Noise",
        "pink_noise": "Pink Noise",
        "brown_noise": "Brown Noise",
        "brown_noise_deep": "Deep Brown Noise",
        "morning_birds": "Morning Birds",
        "winter_forest": "Winter Forest",
        "serene_morning": "Serene Morning",
        "rain_storm": "Rain Storm",
        "wind_ambient": "Wind Ambient",
        "campfire": "Campfire",
        "bonfire": "Bonfire"
    ]

    init() {
        loadSessions()
        loadGoal()
        generateMockDataIfEmpty()
    }

    // MARK: - Session Recording

    /// Called when sleep timer ends or user stops sounds at night
    func recordSession(duration: TimeInterval, soundsUsed: [String]) {
        let session = SleepSession(
            id: UUID(),
            date: Date(),
            duration: duration,
            quality: calculateQuality(duration: duration),
            soundsUsed: soundsUsed,
            timeToSleep: sessionStartTime.map { Date().timeIntervalSince($0) } ?? 600
        )
        sessions.append(session)
        saveSessions()
        sessionStartTime = nil
    }

    func startSession() {
        sessionStartTime = Date()
    }

    // MARK: - Analytics

    var weeklyData: [(day: String, hours: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(day: String, hours: Double)] = []

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayName = dayFormatter.string(from: date)

            // Find session for this day
            let sessionForDay = sessions.first { session in
                calendar.isDate(session.date, inSameDayAs: date)
            }

            let hours = (sessionForDay?.duration ?? 0) / 3600.0
            result.append((day: dayName, hours: hours))
        }

        return result
    }

    var averageDuration: TimeInterval {
        let recentSessions = recentSessionsLast14Days
        guard !recentSessions.isEmpty else { return 0 }
        return recentSessions.map { $0.duration }.reduce(0, +) / Double(recentSessions.count)
    }

    var averageQuality: Int {
        let recentSessions = recentSessionsLast14Days
        guard !recentSessions.isEmpty else { return 0 }
        return recentSessions.map { $0.quality }.reduce(0, +) / recentSessions.count
    }

    var averageTimeToSleep: TimeInterval {
        let recentSessions = recentSessionsLast14Days
        guard !recentSessions.isEmpty else { return 0 }
        return recentSessions.map { $0.timeToSleep }.reduce(0, +) / Double(recentSessions.count)
    }

    var totalSleepTime: TimeInterval {
        sessions.map { $0.duration }.reduce(0, +)
    }

    var totalSessions: Int {
        sessions.count
    }

    private var recentSessionsLast14Days: [SleepSession] {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return sessions.filter { $0.date >= twoWeeksAgo }
    }

    var mostUsedSounds: [(soundId: String, count: Int)] {
        var soundCounts: [String: Int] = [:]

        for session in sessions {
            for soundId in session.soundsUsed {
                soundCounts[soundId, default: 0] += 1
            }
        }

        return soundCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (soundId: $0.key, count: $0.value) }
    }

    var recommendations: [SoundRecommendation] {
        var result: [SoundRecommendation] = []

        // Find best performing sounds (used with high quality sleep)
        var soundQualityScores: [String: (totalQuality: Int, count: Int)] = [:]

        for session in sessions where session.quality >= 70 {
            for soundId in session.soundsUsed {
                let current = soundQualityScores[soundId, default: (0, 0)]
                soundQualityScores[soundId] = (current.totalQuality + session.quality, current.count + 1)
            }
        }

        let topSounds = soundQualityScores
            .map { (soundId: $0.key, avgQuality: Double($0.value.totalQuality) / Double($0.value.count), count: $0.value.count) }
            .sorted { $0.avgQuality > $1.avgQuality }
            .prefix(3)

        for sound in topSounds {
            let name = soundNames[sound.soundId] ?? sound.soundId.replacingOccurrences(of: "_", with: " ").capitalized
            result.append(SoundRecommendation(
                soundId: sound.soundId,
                soundName: name,
                reason: "Associated with \(Int(sound.avgQuality))% quality sleep",
                confidence: min(1.0, Double(sound.count) / 10.0)
            ))
        }

        // If not enough data, add general recommendations
        if result.count < 3 {
            let generalRecs: [(id: String, reason: String)] = [
                ("brown_noise", "Deep tones promote relaxation"),
                ("rain_storm", "Natural sounds mask distractions"),
                ("pink_noise", "Balanced frequencies aid deep sleep")
            ]

            for rec in generalRecs where result.count < 3 {
                if !result.contains(where: { $0.soundId == rec.id }) {
                    result.append(SoundRecommendation(
                        soundId: rec.id,
                        soundName: soundNames[rec.id] ?? rec.id,
                        reason: rec.reason,
                        confidence: 0.5
                    ))
                }
            }
        }

        return result
    }

    // MARK: - Sleep Goals

    var goalProgress: Double {
        guard let goal = sleepGoal else { return 0 }
        let avgHours = averageDuration / 3600.0
        let targetHours = goal.targetDuration / 3600.0
        return min(1.0, avgHours / targetHours)
    }

    func updateGoal(targetHours: Double) {
        sleepGoal = SleepGoal(
            id: sleepGoal?.id ?? UUID(),
            targetDuration: targetHours * 3600,
            targetBedtime: sleepGoal?.targetBedtime,
            targetWakeTime: sleepGoal?.targetWakeTime
        )
        saveGoal()
    }

    // MARK: - Quality Calculation

    private func calculateQuality(duration: TimeInterval) -> Int {
        // Simple quality calculation based on duration
        let hours = duration / 3600
        if hours >= 7 && hours <= 9 { return Int.random(in: 80...95) }
        if hours >= 6 { return Int.random(in: 65...80) }
        return Int.random(in: 40...65)
    }

    // MARK: - Mock Data Generation

    private func generateMockDataIfEmpty() {
        guard sessions.isEmpty else { return }

        let calendar = Calendar.current
        let soundOptions = ["brown_noise", "rain_storm", "white_noise", "pink_noise", "campfire", "wind_ambient"]

        // Generate 14 days of mock data
        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let duration = TimeInterval.random(in: 18000...32400)  // 5-9 hours
            let sounds = soundOptions.shuffled().prefix(Int.random(in: 1...3)).map { $0 }

            sessions.append(SleepSession(
                id: UUID(),
                date: date,
                duration: duration,
                quality: calculateQuality(duration: duration),
                soundsUsed: Array(sounds),
                timeToSleep: TimeInterval.random(in: 300...1200)
            ))
        }
        saveSessions()

        // Set default goal
        if sleepGoal == nil {
            sleepGoal = SleepGoal(
                id: UUID(),
                targetDuration: 8 * 3600,  // 8 hours
                targetBedtime: nil,
                targetWakeTime: nil
            )
            saveGoal()
        }
    }

    // MARK: - Persistence

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([SleepSession].self, from: data) {
                sessions = decoded
            }
        }
    }

    private func saveSessions() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadGoal() {
        if let data = UserDefaults.standard.data(forKey: goalKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(SleepGoal.self, from: data) {
                sleepGoal = decoded
            }
        }
    }

    private func saveGoal() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(sleepGoal) {
            UserDefaults.standard.set(data, forKey: goalKey)
        }
    }
}
