import Foundation

final class LocalStoryDataSource {
    static let stories: [Story] = [
        // Fiction
        Story(
            id: "story1",
            title: "The Sleepy Forest",
            narrator: "Sarah Moon",
            duration: 1200, // 20 min
            category: .fiction,
            description: "A gentle tale of woodland creatures preparing for winter. Follow a young fox as she discovers the magic of the forest at twilight.",
            audioFileName: nil
        ),
        Story(
            id: "story2",
            title: "The Dream Lighthouse",
            narrator: "Thomas Gray",
            duration: 1500, // 25 min
            category: .fiction,
            description: "A lighthouse keeper guides ships through a sea of stars in this whimsical bedtime story.",
            audioFileName: nil
        ),
        Story(
            id: "story3",
            title: "The Cloud Wanderer",
            narrator: "Sarah Moon",
            duration: 1080, // 18 min
            category: .fiction,
            description: "Float among the clouds with a curious child who discovers a world above the world.",
            audioFileName: nil
        ),

        // Nature Journeys
        Story(
            id: "story4",
            title: "Ocean Waves Journey",
            narrator: "James Rivers",
            duration: 1500, // 25 min
            category: .nature,
            description: "Float along peaceful ocean currents. Let the rhythm of gentle waves carry you to a place of deep relaxation.",
            audioFileName: nil
        ),
        Story(
            id: "story5",
            title: "Mountain Meadow Walk",
            narrator: "Emma Stone",
            duration: 1320, // 22 min
            category: .nature,
            description: "Wander through alpine meadows filled with wildflowers, breathing in the crisp mountain air.",
            audioFileName: nil
        ),
        Story(
            id: "story6",
            title: "Rainy Forest Path",
            narrator: "James Rivers",
            duration: 1440, // 24 min
            category: .nature,
            description: "Walk through an ancient forest as gentle rain falls through the canopy above.",
            audioFileName: nil
        ),

        // Meditation
        Story(
            id: "story7",
            title: "Breathing Into Sleep",
            narrator: "Dr. Emily Chen",
            duration: 900, // 15 min
            category: .meditation,
            description: "Guided breathing exercises for deep relaxation. Release the day and prepare your mind for restful sleep.",
            audioFileName: nil
        ),
        Story(
            id: "story8",
            title: "Body Scan Relaxation",
            narrator: "Dr. Emily Chen",
            duration: 1200, // 20 min
            category: .meditation,
            description: "A progressive relaxation journey through each part of your body, releasing tension as you go.",
            audioFileName: nil
        ),
        Story(
            id: "story9",
            title: "Starlight Meditation",
            narrator: "Maya Thompson",
            duration: 1080, // 18 min
            category: .meditation,
            description: "Visualize yourself floating among the stars in this peaceful guided meditation.",
            audioFileName: nil
        ),

        // ASMR
        Story(
            id: "story10",
            title: "Library Whispers",
            narrator: "Alex Kim",
            duration: 1800, // 30 min
            category: .asmr,
            description: "Soft whispers and gentle page turning in a cozy library. Perfect for triggering relaxation.",
            audioFileName: nil
        ),
        Story(
            id: "story11",
            title: "Rainy Window",
            narrator: "Alex Kim",
            duration: 2400, // 40 min
            category: .asmr,
            description: "Rain tapping on windows with soft whispered narration about finding peace.",
            audioFileName: nil
        ),
        Story(
            id: "story12",
            title: "Cozy Cottage Night",
            narrator: "Sophie White",
            duration: 2100, // 35 min
            category: .asmr,
            description: "Crackling fire, soft rain, and gentle whispers guide you through a peaceful evening.",
            audioFileName: nil
        )
    ]

    static var featuredStory: Story {
        stories.first!
    }

    static func stories(for category: StoryCategory) -> [Story] {
        stories.filter { $0.category == category }
    }
}
