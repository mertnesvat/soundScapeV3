import Foundation

final class LocalSoundDataSource {
    static let shared = LocalSoundDataSource()

    private init() {}

    func getAllSounds() -> [Sound] {
        return [
            // Noise category
            Sound(
                id: "white_noise",
                name: "White Noise",
                category: .noise,
                fileName: "white_noise.mp3"
            ),
            Sound(
                id: "pink_noise",
                name: "Pink Noise",
                category: .noise,
                fileName: "pink_noise.mp3"
            ),
            Sound(
                id: "brown_noise",
                name: "Brown Noise",
                category: .noise,
                fileName: "brown_noise.mp3"
            ),
            Sound(
                id: "brown_noise_deep",
                name: "Deep Brown Noise",
                category: .noise,
                fileName: "brown_noise_deep.mp3"
            ),

            // Nature category
            Sound(
                id: "morning_birds",
                name: "Morning Birds",
                category: .nature,
                fileName: "morning_birds.mp3"
            ),
            Sound(
                id: "winter_forest",
                name: "Winter Forest",
                category: .nature,
                fileName: "winter_forest.mp3"
            ),
            Sound(
                id: "serene_morning",
                name: "Serene Morning",
                category: .nature,
                fileName: "serene_morning.mp3"
            ),

            // Weather category
            Sound(
                id: "rain_storm",
                name: "Rain Storm",
                category: .weather,
                fileName: "rain_storm.mp3"
            ),
            Sound(
                id: "wind_ambient",
                name: "Wind Ambient",
                category: .weather,
                fileName: "wind_ambient.mp3"
            ),

            // Fire category
            Sound(
                id: "campfire",
                name: "Campfire",
                category: .fire,
                fileName: "campfire.mp3"
            ),
            Sound(
                id: "bonfire",
                name: "Bonfire",
                category: .fire,
                fileName: "bonfire.mp3"
            )
        ]
    }
}
