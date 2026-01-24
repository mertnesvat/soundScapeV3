import Foundation

/// Shared container for accessing services from App Intents
/// Since App Intents run outside the normal SwiftUI environment,
/// we need a way to access the shared service instances.
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()

    // MARK: - Services

    private(set) lazy var audioEngine: AudioEngine = {
        let engine = AudioEngine()
        engine.setInsightsService(insightsService)
        engine.setAnalyticsService(analyticsService)
        return engine
    }()

    private(set) lazy var sleepTimerService: SleepTimerService = {
        let service = SleepTimerService(audioEngine: audioEngine)
        service.setAnalyticsService(analyticsService)
        return service
    }()

    private(set) lazy var savedMixesService: SavedMixesService = {
        let service = SavedMixesService()
        service.setAnalyticsService(analyticsService)
        return service
    }()

    private(set) lazy var insightsService = InsightsService()
    private(set) lazy var analyticsService = AnalyticsService()

    private init() {}

    // MARK: - Helper Methods

    /// Get all available sounds from the data source
    func getAllSounds() -> [Sound] {
        LocalSoundDataSource.shared.getAllSounds()
    }

    /// Find a sound by ID
    func getSound(byId id: String) -> Sound? {
        getAllSounds().first { $0.id == id }
    }

    /// Find a saved mix by name (case-insensitive)
    func findMix(byName name: String) -> SavedMix? {
        savedMixesService.mixes.first {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// Play a saved mix
    func playSavedMix(_ mix: SavedMix) {
        // Stop any currently playing sounds
        audioEngine.stopAll()

        // Play each sound in the mix with its saved volume
        for mixSound in mix.sounds {
            if let sound = getSound(byId: mixSound.soundId) {
                audioEngine.play(sound: sound)
                audioEngine.setVolume(mixSound.volume, for: sound.id)
            }
        }
    }

    /// Play a default calming mix for "I can't sleep"
    func playDefaultSleepMix() {
        // Stop any currently playing sounds
        audioEngine.stopAll()

        // Default calming mix: Rain Storm + low ambient music
        if let rainSound = getSound(byId: "rain_storm") {
            audioEngine.play(sound: rainSound)
            audioEngine.setVolume(0.6, for: rainSound.id)
        }

        if let musicSound = getSound(byId: "midnight_calm") {
            audioEngine.play(sound: musicSound)
            audioEngine.setVolume(0.3, for: musicSound.id)
        }
    }
}
