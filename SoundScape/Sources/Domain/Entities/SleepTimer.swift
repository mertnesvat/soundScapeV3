import Foundation

struct SleepTimerPreset: Identifiable {
    let id = UUID()
    let minutes: Int
    let label: String

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
