import Foundation
import SwiftUI

// MARK: - Recording Status

enum RecordingStatus: Equatable {
    case idle
    case recording
    case analyzing
    case complete
}

// MARK: - Sound Event Type

enum SoundEventType: String, Codable, CaseIterable, Equatable {
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
        case .talking: return "mouth.fill"
        case .silence: return "speaker.slash.fill"
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

// MARK: - Sound Event

struct SoundEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: TimeInterval
    let duration: TimeInterval
    let type: SoundEventType
    let peakDecibels: Float
    let averageDecibels: Float

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        duration: TimeInterval,
        type: SoundEventType,
        peakDecibels: Float,
        averageDecibels: Float
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
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hours):\(String(format: "%02d", minutes))"
    }

    var formattedDuration: String {
        if duration < 60 {
            return String(localized: "\(Int(duration))s")
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if seconds == 0 {
                return String(localized: "\(minutes)m")
            }
            return String(localized: "\(minutes)m \(seconds)s")
        }
    }
}

// MARK: - Sleep Recording

struct SleepRecording: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let endDate: Date
    let duration: TimeInterval
    let fileURL: URL
    var events: [SoundEvent]
    var decibelSamples: [Float]
    var averageDecibels: Float
    var peakDecibels: Float
    var snoreScore: Int

    init(
        id: UUID = UUID(),
        date: Date,
        endDate: Date,
        duration: TimeInterval,
        fileURL: URL,
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

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(localized: "\(hours)h \(minutes)m")
        }
        return String(localized: "\(minutes)m")
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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
        events
            .filter { $0.type == .snoring }
            .reduce(0.0) { $0 + $1.duration } / 60.0
    }

    var eventCount: Int {
        events.count
    }

    var snoreScoreCategory: String {
        switch snoreScore {
        case 0...30: return String(localized: "Quiet")
        case 31...60: return String(localized: "Moderate")
        default: return String(localized: "Loud")
        }
    }
}
