import Foundation
import SwiftUI

struct SleepRecording: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var endDate: Date
    var duration: TimeInterval
    var fileURL: URL
    var events: [SoundEvent]
    var decibelSamples: [Float]
    var averageDecibels: Float
    var peakDecibels: Float
    var snoreScore: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        endDate: Date = Date(),
        duration: TimeInterval = 0,
        fileURL: URL = URL(fileURLWithPath: ""),
        events: [SoundEvent] = [],
        decibelSamples: [Float] = [],
        averageDecibels: Float = 0,
        peakDecibels: Float = 0,
        snoreScore: Int = 0
    ) {
        self.id = id
        self.date = date
        self.endDate = endDate
        self.duration = duration
        self.fileURL = fileURL
        self.events = events
        self.decibelSamples = decibelSamples
        self.averageDecibels = averageDecibels
        self.peakDecibels = peakDecibels
        self.snoreScore = snoreScore
    }

    // MARK: - Computed Properties

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(localized: "\(hours)h \(minutes)m")
        } else {
            return String(localized: "\(minutes)m")
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: date)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }

    var snoringMinutes: Double {
        let totalSeconds = events
            .filter { $0.type == .snoring }
            .reduce(0.0) { $0 + $1.duration }
        return totalSeconds / 60.0
    }

    var eventCount: Int {
        events.filter { $0.type != .silence }.count
    }

    var snoreScoreCategory: SnoreScoreCategory {
        if snoreScore <= 30 { return .quiet }
        if snoreScore <= 60 { return .moderate }
        return .loud
    }
}

// MARK: - SoundEvent

struct SoundEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: TimeInterval
    var duration: TimeInterval
    var type: SoundEventType
    var peakDecibels: Float
    var averageDecibels: Float

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval = 0,
        duration: TimeInterval = 0,
        type: SoundEventType = .silence,
        peakDecibels: Float = 0,
        averageDecibels: Float = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.type = type
        self.peakDecibels = peakDecibels
        self.averageDecibels = averageDecibels
    }

    var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        guard let date = calendar.date(from: components) else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remaining = seconds % 60
        if remaining == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(remaining)s"
    }
}

// MARK: - SoundEventType

enum SoundEventType: String, Codable, CaseIterable {
    case snoring
    case loudSound
    case talking
    case silence

    var displayName: String {
        switch self {
        case .snoring: return String(localized: "Snoring")
        case .loudSound: return String(localized: "Loud Sound")
        case .talking: return String(localized: "Talking")
        case .silence: return String(localized: "Silence")
        }
    }

    var icon: String {
        switch self {
        case .snoring: return "zzz"
        case .loudSound: return "speaker.wave.3.fill"
        case .talking: return "person.wave.2.fill"
        case .silence: return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .snoring: return .orange
        case .loudSound: return .red
        case .talking: return .blue
        case .silence: return .gray
        }
    }
}

// MARK: - RecordingStatus

enum RecordingStatus: String, Codable {
    case idle
    case recording
    case analyzing
    case complete
}

// MARK: - SnoreScoreCategory

enum SnoreScoreCategory: String {
    case quiet
    case moderate
    case loud

    var displayName: String {
        switch self {
        case .quiet: return String(localized: "Quiet")
        case .moderate: return String(localized: "Moderate")
        case .loud: return String(localized: "Loud")
        }
    }

    var color: Color {
        switch self {
        case .quiet: return .green
        case .moderate: return .yellow
        case .loud: return .red
        }
    }
}
