import AppIntents

/// Intent for "Hey Siri, I can't sleep" - starts a default calming mix
struct StartSleepMixIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep Mix"
    static var description = IntentDescription("Plays a calming soundscape to help you fall asleep")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ServiceContainer.shared

        // Play the default sleep mix
        container.playDefaultSleepMix()

        return .result(dialog: "Starting your sleep soundscape with rain and calming music. Sweet dreams.")
    }
}
