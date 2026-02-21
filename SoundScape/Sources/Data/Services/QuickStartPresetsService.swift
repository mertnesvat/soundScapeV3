import Foundation

@Observable
@MainActor
final class QuickStartPresetsService {
    private(set) var isCollapsed: Bool
    private(set) var activePresetId: String?
    private var analyticsService: AnalyticsService?

    private let collapsedKey = "quick_start_presets_collapsed"

    init() {
        isCollapsed = UserDefaults.standard.bool(forKey: collapsedKey)
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    var presets: [SoundPreset] {
        SoundPreset.quickStartPresets
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
        UserDefaults.standard.set(isCollapsed, forKey: collapsedKey)
    }

    func loadPreset(_ preset: SoundPreset, audioEngine: AudioEngine, allSounds: [Sound]) {
        // Stop all currently playing sounds
        audioEngine.stopAll()

        // Play each sound in the preset with its configured volume
        for config in preset.soundConfigs {
            guard let sound = allSounds.first(where: { $0.id == config.soundId }) else {
                continue
            }
            audioEngine.play(sound: sound)
            audioEngine.setVolume(config.volume, for: config.soundId)
        }

        activePresetId = preset.id
        analyticsService?.logPresetPlayed(presetName: preset.name)
    }

    func clearActivePreset() {
        activePresetId = nil
    }
}
