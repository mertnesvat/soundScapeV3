import AppIntents

/// Intent for "Resume my sounds" - resumes paused playback
struct ResumeSoundsIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Sounds"
    static var description = IntentDescription("Resumes paused sounds")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ServiceContainer.shared

        // Check if there are any sounds to resume
        guard !container.audioEngine.activeSounds.isEmpty else {
            return .result(dialog: "No sounds to resume. Try saying 'I can't sleep' to start a calming mix.")
        }

        // Check if sounds are already playing
        if container.audioEngine.isAnyPlaying {
            return .result(dialog: "Sounds are already playing.")
        }

        // Resume all sounds
        container.audioEngine.resumeAll()

        let soundCount = container.audioEngine.activeSounds.count
        let soundText = soundCount == 1 ? "sound" : "sounds"

        return .result(dialog: "Resuming \(soundCount) \(soundText).")
    }
}
