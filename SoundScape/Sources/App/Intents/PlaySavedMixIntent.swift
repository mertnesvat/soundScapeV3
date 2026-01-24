import AppIntents

/// Intent for "Start my [mix name] mix" - plays a saved mix by name
struct PlaySavedMixIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Saved Mix"
    static var description = IntentDescription("Plays one of your saved sound mixes")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Mix")
    var mix: SavedMixEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Play \(\.$mix)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = ServiceContainer.shared

        // Find the actual saved mix by ID
        guard let savedMix = container.savedMixesService.mixes.first(where: {
            $0.id.uuidString == mix.id
        }) else {
            return .result(dialog: "I couldn't find a mix named \(mix.name). You can create one in the SoundScape app.")
        }

        // Play the mix
        container.playSavedMix(savedMix)

        let soundCount = savedMix.sounds.count
        let soundText = soundCount == 1 ? "sound" : "sounds"

        return .result(dialog: "Playing your \(mix.name) mix with \(soundCount) \(soundText).")
    }
}
