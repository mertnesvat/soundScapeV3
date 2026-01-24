import AppIntents

/// Intent for "Stop the sounds" / "Pause SoundScape" - stops all playback
struct StopSoundsIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Sounds"
    static var description = IntentDescription("Stops all currently playing sounds")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ServiceContainer.shared

        // Check if any sounds are playing
        guard container.audioEngine.isAnyPlaying || !container.audioEngine.activeSounds.isEmpty else {
            return .result(dialog: "No sounds are currently playing.")
        }

        // Stop all sounds
        container.audioEngine.stopAll()

        // Also cancel any active sleep timer
        if container.sleepTimerService.isActive {
            container.sleepTimerService.cancel()
            return .result(dialog: "Stopped all sounds and cancelled the sleep timer.")
        }

        return .result(dialog: "Stopped all sounds. Sleep well.")
    }
}
