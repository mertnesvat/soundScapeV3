import AppIntents

/// Intent for "Set sleep timer" - starts the sleep timer with a selected duration
struct SetSleepTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Sleep Timer"
    static var description = IntentDescription("Sets a timer to automatically stop sounds after a duration")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Duration", description: "How long until sounds fade out")
    var duration: SleepTimerDuration

    static var parameterSummary: some ParameterSummary {
        Summary("Set sleep timer for \(\.$duration)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ServiceContainer.shared
        let minutes = duration.minutes

        // Start the sleep timer
        container.sleepTimerService.start(minutes: minutes)

        return .result(dialog: "Sleep timer set for \(duration.displayText). Sounds will fade out and stop.")
    }
}
