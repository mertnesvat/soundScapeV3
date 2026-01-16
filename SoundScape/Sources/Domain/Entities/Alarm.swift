import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date  // Only time component matters
    var repeatDays: Set<Weekday>
    var soundId: String
    var volumeRampMinutes: Int
    var snoozeMinutes: Int
    var isEnabled: Bool
    var label: String

    init(
        id: UUID = UUID(),
        time: Date = Date(),
        repeatDays: Set<Weekday> = [],
        soundId: String = "morning_birds",
        volumeRampMinutes: Int = 5,
        snoozeMinutes: Int = 10,
        isEnabled: Bool = true,
        label: String = "Alarm"
    ) {
        self.id = id
        self.time = time
        self.repeatDays = repeatDays
        self.soundId = soundId
        self.volumeRampMinutes = volumeRampMinutes
        self.snoozeMinutes = snoozeMinutes
        self.isEnabled = isEnabled
        self.label = label
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var repeatDescription: String {
        if repeatDays.isEmpty { return "Once" }
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays == [.saturday, .sunday] { return "Weekends" }
        if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        return repeatDays.sorted().map { $0.shortName }.joined(separator: " ")
    }
}

enum Weekday: Int, Codable, CaseIterable, Comparable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    // Display order: Mon-Sun for UI
    var displayOrder: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }

    static var orderedForDisplay: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
