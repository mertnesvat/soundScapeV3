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
            Sound(
                id: "spring_birds",
                name: "Spring Birds",
                category: .nature,
                fileName: "spring_birds.mp3"
            ),
            Sound(
                id: "meadow",
                name: "Meadow",
                category: .nature,
                fileName: "meadow.mp3"
            ),
            Sound(
                id: "night_wildlife",
                name: "Night Wildlife",
                category: .nature,
                fileName: "night_wildlife.mp3"
            ),
            Sound(
                id: "calm_ocean",
                name: "Calm Ocean",
                category: .nature,
                fileName: "calm_ocean.mp3"
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
            Sound(
                id: "rainforest",
                name: "Rainforest",
                category: .weather,
                fileName: "rainforest.mp3"
            ),
            Sound(
                id: "thunder",
                name: "Thunder",
                category: .weather,
                fileName: "thunder.mp3"
            ),
            Sound(
                id: "heavy_thunder",
                name: "Heavy Thunder",
                category: .weather,
                fileName: "heavy_thunder.mp3"
            ),
            Sound(
                id: "castle_wind",
                name: "Castle Wind",
                category: .weather,
                fileName: "castle_wind.mp3"
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
            ),

            // Music category
            Sound(
                id: "creative_mind",
                name: "Creative Mind",
                category: .music,
                fileName: "Creative Mind.mp3"
            ),
            Sound(
                id: "cinematic_piano",
                name: "Cinematic Piano",
                category: .music,
                fileName: "cinematic_piano.mp3"
            ),
            Sound(
                id: "ambient_melody",
                name: "Ambient Melody",
                category: .music,
                fileName: "ambient_melody.mp3"
            ),
            Sound(
                id: "midnight_calm",
                name: "Midnight Calm",
                category: .music,
                fileName: "Midnight Calm.mp3"
            ),
            Sound(
                id: "ocean_lullaby",
                name: "Ocean Lullaby",
                category: .music,
                fileName: "Ocean Lullaby.mp3"
            ),
            Sound(
                id: "deep_focus_flow",
                name: "Deep Focus Flow",
                category: .music,
                fileName: "Deep Focus Flow.mp3"
            ),
            Sound(
                id: "starlit_sky",
                name: "Starlit Sky",
                category: .music,
                fileName: "Starlit Sky.mp3"
            ),
            Sound(
                id: "forest_sanctuary",
                name: "Forest Sanctuary",
                category: .music,
                fileName: "Forest Sanctuary.mp3"
            )
        ]
    }
}
