import Foundation

struct SoundPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let gradientColors: [String]
    let soundConfigs: [SoundConfig]

    struct SoundConfig: Equatable {
        let soundId: String
        let volume: Float
    }

    static let quickStartPresets: [SoundPreset] = [
        SoundPreset(
            id: "deep_sleep",
            name: String(localized: "Deep Sleep"),
            subtitle: String(localized: "Brown noise & gentle rain"),
            icon: "moon.fill",
            gradientColors: ["indigo", "purple"],
            soundConfigs: [
                SoundConfig(soundId: "brown_noise", volume: 0.6),
                SoundConfig(soundId: "rain_storm", volume: 0.4),
                SoundConfig(soundId: "night_wildlife", volume: 0.2),
            ]
        ),
        SoundPreset(
            id: "focus_flow",
            name: String(localized: "Focus Flow"),
            subtitle: String(localized: "Music & white noise"),
            icon: "brain.head.profile.fill",
            gradientColors: ["orange", "pink"],
            soundConfigs: [
                SoundConfig(soundId: "deep_focus_flow", volume: 0.5),
                SoundConfig(soundId: "white_noise", volume: 0.3),
            ]
        ),
        SoundPreset(
            id: "rain_day",
            name: String(localized: "Rain Day"),
            subtitle: String(localized: "Storm & thunder ambience"),
            icon: "cloud.rain.fill",
            gradientColors: ["blue", "cyan"],
            soundConfigs: [
                SoundConfig(soundId: "rain_storm", volume: 0.7),
                SoundConfig(soundId: "thunder", volume: 0.3),
                SoundConfig(soundId: "wind_ambient", volume: 0.2),
            ]
        ),
        SoundPreset(
            id: "ocean_calm",
            name: String(localized: "Ocean Calm"),
            subtitle: String(localized: "Waves & soothing melody"),
            icon: "water.waves",
            gradientColors: ["teal", "blue"],
            soundConfigs: [
                SoundConfig(soundId: "calm_ocean", volume: 0.7),
                SoundConfig(soundId: "ocean_lullaby", volume: 0.3),
            ]
        ),
        SoundPreset(
            id: "forest_morning",
            name: String(localized: "Forest Morning"),
            subtitle: String(localized: "Birds & peaceful nature"),
            icon: "leaf.fill",
            gradientColors: ["green", "mint"],
            soundConfigs: [
                SoundConfig(soundId: "morning_birds", volume: 0.6),
                SoundConfig(soundId: "serene_morning", volume: 0.4),
                SoundConfig(soundId: "campfire", volume: 0.2),
            ]
        ),
    ]
}
