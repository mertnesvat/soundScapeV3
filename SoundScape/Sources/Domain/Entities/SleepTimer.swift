import Foundation

struct SleepTimerPreset: Identifiable {
    let id = UUID()
    let minutes: Int
    let label: String

    var localizedLabel: String {
        switch minutes {
        case 5: return String(localized: "5 min")
        case 15: return String(localized: "15 min")
        case 30: return String(localized: "30 min")
        case 45: return String(localized: "45 min")
        case 60: return String(localized: "1 hour")
        case 90: return String(localized: "1.5 hours")
        case 120: return String(localized: "2 hours")
        default: return label
        }
    }

    static let presets: [SleepTimerPreset] = [
        SleepTimerPreset(minutes: 5, label: "5 min"),
        SleepTimerPreset(minutes: 15, label: "15 min"),
        SleepTimerPreset(minutes: 30, label: "30 min"),
        SleepTimerPreset(minutes: 45, label: "45 min"),
        SleepTimerPreset(minutes: 60, label: "1 hour"),
        SleepTimerPreset(minutes: 90, label: "1.5 hours"),
        SleepTimerPreset(minutes: 120, label: "2 hours"),
    ]
}
