import AppIntents

/// Duration options for sleep timer
enum SleepTimerDuration: Int, AppEnum {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30
    case fortyFiveMinutes = 45
    case oneHour = 60
    case ninetyMinutes = 90
    case twoHours = 120

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sleep Timer Duration"

    static var caseDisplayRepresentations: [SleepTimerDuration: DisplayRepresentation] = [
        .fiveMinutes: "5 minutes",
        .tenMinutes: "10 minutes",
        .fifteenMinutes: "15 minutes",
        .twentyMinutes: "20 minutes",
        .thirtyMinutes: "30 minutes",
        .fortyFiveMinutes: "45 minutes",
        .oneHour: "1 hour",
        .ninetyMinutes: "90 minutes",
        .twoHours: "2 hours"
    ]

    var minutes: Int {
        rawValue
    }

    var displayText: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .twentyMinutes: return "20 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .oneHour: return "1 hour"
        case .ninetyMinutes: return "90 minutes"
        case .twoHours: return "2 hours"
        }
    }
}
