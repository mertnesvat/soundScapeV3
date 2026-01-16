import Foundation

final class LocalCommunityDataSource {
    static let shared = LocalCommunityDataSource()

    private init() {}

    let mixes: [CommunityMix] = [
        // Featured Mix
        CommunityMix(
            id: UUID(),
            name: "Rainy Day Focus",
            creatorName: "SleepyPanda",
            sounds: [
                .init(soundId: "rain_storm", volume: 0.6),
                .init(soundId: "brown_noise", volume: 0.3)
            ],
            playCount: 12500,
            upvotes: 843,
            tags: ["focus", "rain", "productive"],
            category: .focus,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            isFeatured: true
        ),

        // Sleep category
        CommunityMix(
            id: UUID(),
            name: "Deep Sleep Sanctuary",
            creatorName: "DreamWeaver",
            sounds: [
                .init(soundId: "brown_noise_deep", volume: 0.5),
                .init(soundId: "rain_storm", volume: 0.3)
            ],
            playCount: 8920,
            upvotes: 621,
            tags: ["sleep", "deep", "relaxing"],
            category: .sleep,
            createdAt: Date().addingTimeInterval(-86400 * 14),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Midnight Calm",
            creatorName: "NightOwl42",
            sounds: [
                .init(soundId: "white_noise", volume: 0.4),
                .init(soundId: "wind_ambient", volume: 0.3)
            ],
            playCount: 5430,
            upvotes: 389,
            tags: ["sleep", "calm", "night"],
            category: .sleep,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Baby Sleep Magic",
            creatorName: "ParentLife",
            sounds: [
                .init(soundId: "pink_noise", volume: 0.5),
                .init(soundId: "rain_storm", volume: 0.2)
            ],
            playCount: 15200,
            upvotes: 1102,
            tags: ["baby", "sleep", "gentle"],
            category: .sleep,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            isFeatured: false
        ),

        // Focus category
        CommunityMix(
            id: UUID(),
            name: "Study Session",
            creatorName: "AcademicZen",
            sounds: [
                .init(soundId: "brown_noise", volume: 0.4),
                .init(soundId: "campfire", volume: 0.2)
            ],
            playCount: 7650,
            upvotes: 512,
            tags: ["study", "focus", "concentration"],
            category: .focus,
            createdAt: Date().addingTimeInterval(-86400 * 10),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Code Flow State",
            creatorName: "DevMode",
            sounds: [
                .init(soundId: "white_noise", volume: 0.3),
                .init(soundId: "rain_storm", volume: 0.4)
            ],
            playCount: 9870,
            upvotes: 723,
            tags: ["coding", "focus", "flow"],
            category: .focus,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Writer's Retreat",
            creatorName: "Wordsmith",
            sounds: [
                .init(soundId: "campfire", volume: 0.4),
                .init(soundId: "wind_ambient", volume: 0.3)
            ],
            playCount: 4320,
            upvotes: 298,
            tags: ["writing", "creative", "cozy"],
            category: .focus,
            createdAt: Date().addingTimeInterval(-86400 * 8),
            isFeatured: false
        ),

        // Nature category
        CommunityMix(
            id: UUID(),
            name: "Forest Morning",
            creatorName: "NatureLover",
            sounds: [
                .init(soundId: "morning_birds", volume: 0.5),
                .init(soundId: "wind_ambient", volume: 0.2)
            ],
            playCount: 11200,
            upvotes: 876,
            tags: ["nature", "morning", "birds"],
            category: .nature,
            createdAt: Date().addingTimeInterval(-86400 * 20),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Winter Cabin",
            creatorName: "CozyCamper",
            sounds: [
                .init(soundId: "winter_forest", volume: 0.4),
                .init(soundId: "bonfire", volume: 0.5)
            ],
            playCount: 6780,
            upvotes: 534,
            tags: ["winter", "cozy", "cabin"],
            category: .nature,
            createdAt: Date().addingTimeInterval(-86400 * 15),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Serene Garden",
            creatorName: "ZenGardener",
            sounds: [
                .init(soundId: "serene_morning", volume: 0.5),
                .init(soundId: "morning_birds", volume: 0.3)
            ],
            playCount: 3980,
            upvotes: 267,
            tags: ["garden", "peaceful", "morning"],
            category: .nature,
            createdAt: Date().addingTimeInterval(-86400 * 6),
            isFeatured: false
        ),

        // Trending category
        CommunityMix(
            id: UUID(),
            name: "Viral Sleep Hack",
            creatorName: "TrendSetter",
            sounds: [
                .init(soundId: "brown_noise_deep", volume: 0.6),
                .init(soundId: "pink_noise", volume: 0.2)
            ],
            playCount: 25600,
            upvotes: 1890,
            tags: ["viral", "sleep", "hack"],
            category: .trending,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "ASMR Storm",
            creatorName: "SoundArtist",
            sounds: [
                .init(soundId: "rain_storm", volume: 0.7),
                .init(soundId: "wind_ambient", volume: 0.4)
            ],
            playCount: 18900,
            upvotes: 1450,
            tags: ["asmr", "storm", "immersive"],
            category: .trending,
            createdAt: Date().addingTimeInterval(-86400 * 1),
            isFeatured: false
        ),

        // Popular category
        CommunityMix(
            id: UUID(),
            name: "All-Time Classic",
            creatorName: "OGMixer",
            sounds: [
                .init(soundId: "rain_storm", volume: 0.5),
                .init(soundId: "campfire", volume: 0.4)
            ],
            playCount: 45000,
            upvotes: 3200,
            tags: ["classic", "relaxing", "timeless"],
            category: .popular,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Community Favorite",
            creatorName: "SoundScapeTeam",
            sounds: [
                .init(soundId: "brown_noise", volume: 0.4),
                .init(soundId: "rain_storm", volume: 0.4),
                .init(soundId: "campfire", volume: 0.2)
            ],
            playCount: 38500,
            upvotes: 2890,
            tags: ["favorite", "community", "curated"],
            category: .popular,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            isFeatured: false
        ),
        CommunityMix(
            id: UUID(),
            name: "Ultimate Relaxation",
            creatorName: "ChillMaster",
            sounds: [
                .init(soundId: "serene_morning", volume: 0.4),
                .init(soundId: "wind_ambient", volume: 0.3),
                .init(soundId: "morning_birds", volume: 0.2)
            ],
            playCount: 32100,
            upvotes: 2340,
            tags: ["relaxation", "ultimate", "peaceful"],
            category: .popular,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            isFeatured: false
        )
    ]

    func mixes(for category: CommunityCategory) -> [CommunityMix] {
        mixes.filter { $0.category == category }
    }

    var featuredMix: CommunityMix? {
        mixes.first { $0.isFeatured }
    }

    var trendingMixes: [CommunityMix] {
        Array(mixes.sorted { $0.playCount > $1.playCount }.prefix(5))
    }
}
