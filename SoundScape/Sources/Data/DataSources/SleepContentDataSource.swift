import Foundation

/// Data source for sleep content including yoga nidra, stories, meditations, etc.
final class SleepContentDataSource {

    // MARK: - Yoga Nidra Sessions

    /// Yoga nidra sessions - guided deep relaxation for sleep
    static let yogaNidraSessions: [SleepContent] = [
        SleepContent(
            id: "yoga_nidra_5min",
            title: "Quick Yoga Nidra",
            narrator: "Guided Voice",
            duration: 300,  // 5 minutes
            contentType: .yogaNidra,
            description: "A brief but powerful yoga nidra session perfect for short breaks or when you need quick relaxation.",
            audioFileName: "yoga_nidra_sleep_5min.mp3"
        ),
        SleepContent(
            id: "yoga_nidra_8min",
            title: "Extended Yoga Nidra",
            narrator: "Guided Voice",
            duration: 480,  // 8 minutes
            contentType: .yogaNidra,
            description: "A deeper yoga nidra experience with extended body scan and visualization.",
            audioFileName: "yoga_nidra_sleep_8min.mp3"
        ),
        SleepContent(
            id: "yoga_nidra_10min",
            title: "Complete Yoga Nidra",
            narrator: "Guided Voice",
            duration: 600,  // 10 minutes
            contentType: .yogaNidra,
            description: "The full yoga nidra journey. Perfect for bedtime relaxation and deep restoration.",
            audioFileName: "yoga_nidra_sleep_10min.mp3"
        )
    ]

    // MARK: - Sleep Stories (Coming Soon Placeholders)

    /// Sleep stories - calming narratives for sleep
    /// Migrated from LocalStoryDataSource with all 12 original stories
    /// Categories: Fiction, Nature Journeys, Meditation, ASMR
    static let sleepStories: [SleepContent] = [
        // Fiction Stories
        SleepContent(
            id: "story_sleepy_forest",
            title: "The Sleepy Forest",
            narrator: "Sarah Moon",
            duration: 1200,  // 20 min
            contentType: .sleepStory,
            description: "A gentle tale of woodland creatures preparing for winter. Follow a young fox as she discovers the magic of the forest at twilight.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_dream_lighthouse",
            title: "The Dream Lighthouse",
            narrator: "Thomas Gray",
            duration: 1500,  // 25 min
            contentType: .sleepStory,
            description: "A lighthouse keeper guides ships through a sea of stars in this whimsical bedtime story.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_cloud_wanderer",
            title: "The Cloud Wanderer",
            narrator: "Sarah Moon",
            duration: 1080,  // 18 min
            contentType: .sleepStory,
            description: "Float among the clouds with a curious child who discovers a world above the world.",
            audioFileName: nil  // Coming Soon
        ),

        // Nature Journey Stories
        SleepContent(
            id: "story_ocean_waves_journey",
            title: "Ocean Waves Journey",
            narrator: "James Rivers",
            duration: 1500,  // 25 min
            contentType: .sleepStory,
            description: "Float along peaceful ocean currents. Let the rhythm of gentle waves carry you to a place of deep relaxation.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_mountain_meadow_walk",
            title: "Mountain Meadow Walk",
            narrator: "Emma Stone",
            duration: 1320,  // 22 min
            contentType: .sleepStory,
            description: "Wander through alpine meadows filled with wildflowers, breathing in the crisp mountain air.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_rainy_forest_path",
            title: "Rainy Forest Path",
            narrator: "James Rivers",
            duration: 1440,  // 24 min
            contentType: .sleepStory,
            description: "Walk through an ancient forest as gentle rain falls through the canopy above.",
            audioFileName: nil  // Coming Soon
        ),

        // Meditation Stories
        SleepContent(
            id: "story_breathing_into_sleep",
            title: "Breathing Into Sleep",
            narrator: "Dr. Emily Chen",
            duration: 900,  // 15 min
            contentType: .sleepStory,
            description: "Guided breathing exercises for deep relaxation. Release the day and prepare your mind for restful sleep.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_body_scan_relaxation",
            title: "Body Scan Relaxation",
            narrator: "Dr. Emily Chen",
            duration: 1200,  // 20 min
            contentType: .sleepStory,
            description: "A progressive relaxation journey through each part of your body, releasing tension as you go.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_starlight_meditation",
            title: "Starlight Meditation",
            narrator: "Maya Thompson",
            duration: 1080,  // 18 min
            contentType: .sleepStory,
            description: "Visualize yourself floating among the stars in this peaceful guided meditation.",
            audioFileName: nil  // Coming Soon
        ),

        // ASMR Stories
        SleepContent(
            id: "story_library_whispers",
            title: "Library Whispers",
            narrator: "Alex Kim",
            duration: 1800,  // 30 min
            contentType: .sleepStory,
            description: "Soft whispers and gentle page turning in a cozy library. Perfect for triggering relaxation.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_rainy_window",
            title: "Rainy Window",
            narrator: "Alex Kim",
            duration: 2400,  // 40 min
            contentType: .sleepStory,
            description: "Rain tapping on windows with soft whispered narration about finding peace.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_cozy_cottage_night",
            title: "Cozy Cottage Night",
            narrator: "Sophie White",
            duration: 2100,  // 35 min
            contentType: .sleepStory,
            description: "Crackling fire, soft rain, and gentle whispers guide you through a peaceful evening.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Guided Meditations (Coming Soon Placeholders)

    /// Guided meditations for sleep preparation
    static let guidedMeditations: [SleepContent] = [
        SleepContent(
            id: "meditation_body_scan",
            title: "Body Scan Relaxation",
            narrator: "Dr. Emily Chen",
            duration: 1200,  // 20 min
            contentType: .guidedMeditation,
            description: "A progressive journey through each part of your body, releasing tension as you go deeper into relaxation.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "meditation_floating",
            title: "Floating on Clouds",
            narrator: "Maya Thompson",
            duration: 900,  // 15 min
            contentType: .guidedMeditation,
            description: "Visualize yourself floating on soft clouds, drifting peacefully toward sleep.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "meditation_gratitude",
            title: "Gratitude for Sleep",
            narrator: "Dr. Emily Chen",
            duration: 600,  // 10 min
            contentType: .guidedMeditation,
            description: "End your day with gratitude, reflecting on positive moments as you prepare for restful sleep.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "meditation_garden",
            title: "Peaceful Garden Walk",
            narrator: "James Rivers",
            duration: 1080,  // 18 min
            contentType: .guidedMeditation,
            description: "Walk through a beautiful, serene garden as evening falls, finding your inner peace.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Breathing Exercises (Coming Soon Placeholders)

    /// Breathing exercises for relaxation
    static let breathingExercises: [SleepContent] = [
        SleepContent(
            id: "breathing_478",
            title: "4-7-8 Breath",
            narrator: "Guided Voice",
            duration: 300,  // 5 min
            contentType: .breathingExercise,
            description: "The relaxing breath technique. Inhale for 4 counts, hold for 7, exhale for 8. Known to promote deep relaxation.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "breathing_box",
            title: "Box Breathing",
            narrator: "Guided Voice",
            duration: 420,  // 7 min
            contentType: .breathingExercise,
            description: "Equal counts of inhale, hold, exhale, hold. Used by Navy SEALs for stress relief and focus.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "breathing_deep_sleep",
            title: "Deep Sleep Breath",
            narrator: "Guided Voice",
            duration: 600,  // 10 min
            contentType: .breathingExercise,
            description: "Extended exhale breathing designed specifically to activate your parasympathetic nervous system.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "breathing_relaxing",
            title: "Relaxing Exhale",
            narrator: "Guided Voice",
            duration: 480,  // 8 min
            contentType: .breathingExercise,
            description: "Focus on long, slow exhales to release tension and prepare for restful sleep.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Sleep Hypnosis (Coming Soon Placeholders)

    /// Sleep hypnosis sessions
    static let sleepHypnosis: [SleepContent] = [
        SleepContent(
            id: "hypnosis_deep_sleep",
            title: "Deep Sleep Hypnosis",
            narrator: "Dr. Sarah Williams",
            duration: 2700,  // 45 minutes
            contentType: .sleepHypnosis,
            description: "Gentle suggestions guide your subconscious mind toward restful sleep.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "hypnosis_insomnia_relief",
            title: "Insomnia Relief",
            narrator: "Dr. Sarah Williams",
            duration: 3600,  // 60 minutes
            contentType: .sleepHypnosis,
            description: "Specialized hypnotherapy session designed to help overcome sleeplessness.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Affirmations (Coming Soon Placeholders)

    /// Bedtime affirmations
    static let affirmations: [SleepContent] = [
        SleepContent(
            id: "affirmations_peaceful_sleep",
            title: "Peaceful Sleep",
            narrator: "Emma Rose",
            duration: 600,  // 10 minutes
            contentType: .affirmations,
            description: "Positive affirmations to release the day and embrace restful sleep.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "affirmations_self_love",
            title: "Self-Love & Rest",
            narrator: "Maya Thompson",
            duration: 720,  // 12 minutes
            contentType: .affirmations,
            description: "Gentle affirmations nurturing self-compassion as you drift off.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Aggregated Content

    /// All sleep content organized by type
    static func allContent() -> [SleepContentType: [SleepContent]] {
        return [
            .yogaNidra: yogaNidraSessions,
            .sleepStory: sleepStories,
            .guidedMeditation: guidedMeditations,
            .breathingExercise: breathingExercises,
            .sleepHypnosis: sleepHypnosis,
            .affirmations: affirmations
        ]
    }

    /// All content flattened into a single array
    static func allContentFlat() -> [SleepContent] {
        return yogaNidraSessions + sleepStories + guidedMeditations +
               breathingExercises + sleepHypnosis + affirmations
    }

    /// Get content by ID
    static func content(withId id: String) -> SleepContent? {
        return allContentFlat().first { $0.id == id }
    }

    /// Get all available content (has audio file)
    static func availableContent() -> [SleepContent] {
        return allContentFlat().filter { $0.isAvailable }
    }

    /// Get content for a specific type
    static func content(for type: SleepContentType) -> [SleepContent] {
        return allContent()[type] ?? []
    }
}
