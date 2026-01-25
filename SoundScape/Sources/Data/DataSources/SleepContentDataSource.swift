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
            duration: 293,  // 4:53
            contentType: .yogaNidra,
            description: "A brief but powerful yoga nidra session perfect for short breaks or when you need quick relaxation.",
            audioFileName: "yoga_nidra_sleep_5min.mp3",
            coverImageName: "yoga_nidra_sleep_5min_cover"
        ),
        SleepContent(
            id: "yoga_nidra_8min",
            title: "Extended Yoga Nidra",
            narrator: "Guided Voice",
            duration: 438,  // 7:18
            contentType: .yogaNidra,
            description: "A deeper yoga nidra experience with extended body scan and visualization.",
            audioFileName: "yoga_nidra_sleep_8min.mp3",
            coverImageName: "yoga_nidra_sleep_8min_cover"
        ),
        SleepContent(
            id: "yoga_nidra_10min",
            title: "Complete Yoga Nidra",
            narrator: "Guided Voice",
            duration: 767,  // 12:47
            contentType: .yogaNidra,
            description: "The full yoga nidra journey. Perfect for bedtime relaxation and deep restoration.",
            audioFileName: "yoga_nidra_sleep_10min.mp3",
            coverImageName: "yoga_nidra_sleep_10min_cover"
        )
    ]

    // MARK: - Sleep Stories

    /// Sleep stories - calming narratives for sleep
    static let sleepStories: [SleepContent] = [
        SleepContent(
            id: "story_clockmakers_gift",
            title: "The Clockmaker's Final Gift",
            narrator: "AI Narrator",
            duration: 430,  // 7:10
            contentType: .sleepStory,
            description: "In a quiet village nestled between rolling hills, there lived an old clockmaker whose hands had grown too tired to wind the clocks he once loved.",
            audioFileName: "the_clockmakers_final_gift.mp3",
            coverImageName: "the_clockmakers_final_gift_cover"
        ),
        SleepContent(
            id: "story_garden_between_stars",
            title: "The Garden Between Stars",
            narrator: "AI Narrator",
            duration: 445,  // 7:25
            contentType: .sleepStory,
            description: "High above the world, where the sky turns from blue to endless black, there exists a garden that no telescope has ever found.",
            audioFileName: "the_garden_between_stars.mp3",
            coverImageName: "the_garden_between_stars_cover"
        ),
        SleepContent(
            id: "story_last_lighthouse_keeper",
            title: "The Last Lighthouse Keeper",
            narrator: "AI Narrator",
            duration: 419,  // 6:59
            contentType: .sleepStory,
            description: "On the edge of a rocky coast where the Atlantic meets the sky, there stands a lighthouse that has guided ships for two hundred years.",
            audioFileName: "the_last_lighthouse_keeper.mp3",
            coverImageName: "the_last_lighthouse_keeper_cover"
        ),
        SleepContent(
            id: "story_mountain_learned_to_rest",
            title: "The Mountain That Learned to Rest",
            narrator: "AI Narrator",
            duration: 545,  // 9:05
            contentType: .sleepStory,
            description: "Long ago, when the world was still learning to be still, there was a mountain who had forgotten how to rest.",
            audioFileName: "the_mountain_that_learned_to_rest.mp3",
            coverImageName: "the_mountain_that_learned_to_rest_cover"
        ),
        SleepContent(
            id: "story_rivers_secret",
            title: "The River's Secret",
            narrator: "AI Narrator",
            duration: 501,  // 8:21
            contentType: .sleepStory,
            description: "Deep in the heart of an ancient forest, there flows a river that knows a secret—a secret about sleep, about dreams, and about letting go.",
            audioFileName: "the_rivers_secret.mp3",
            coverImageName: "the_rivers_secret_cover"
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
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "meditation_floating",
            title: "Floating on Clouds",
            narrator: "Maya Thompson",
            duration: 900,  // 15 min
            contentType: .guidedMeditation,
            description: "Visualize yourself floating on soft clouds, drifting peacefully toward sleep.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "meditation_gratitude",
            title: "Gratitude for Sleep",
            narrator: "Dr. Emily Chen",
            duration: 600,  // 10 min
            contentType: .guidedMeditation,
            description: "End your day with gratitude, reflecting on positive moments as you prepare for restful sleep.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "meditation_garden",
            title: "Peaceful Garden Walk",
            narrator: "James Rivers",
            duration: 1080,  // 18 min
            contentType: .guidedMeditation,
            description: "Walk through a beautiful, serene garden as evening falls, finding your inner peace.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
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
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "breathing_box",
            title: "Box Breathing",
            narrator: "Guided Voice",
            duration: 420,  // 7 min
            contentType: .breathingExercise,
            description: "Equal counts of inhale, hold, exhale, hold. Used by Navy SEALs for stress relief and focus.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "breathing_deep_sleep",
            title: "Deep Sleep Breath",
            narrator: "Guided Voice",
            duration: 600,  // 10 min
            contentType: .breathingExercise,
            description: "Extended exhale breathing designed specifically to activate your parasympathetic nervous system.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        ),
        SleepContent(
            id: "breathing_relaxing",
            title: "Relaxing Exhale",
            narrator: "Guided Voice",
            duration: 480,  // 8 min
            contentType: .breathingExercise,
            description: "Focus on long, slow exhales to release tension and prepare for restful sleep.",
            audioFileName: nil,  // Coming Soon
            coverImageName: nil
        )
    ]

    // MARK: - Sleep Hypnosis

    /// Sleep hypnosis sessions for deep relaxation
    static let sleepHypnosis: [SleepContent] = [
        SleepContent(
            id: "hypnosis_floating",
            title: "Floating Into Dreams",
            narrator: "AI Voice Guide",
            duration: 327,  // 5:27
            contentType: .sleepHypnosis,
            description: "Close your eyes. Find yourself floating gently, weightlessly, as the world below becomes softer and more distant.",
            audioFileName: "sleep_hypnosis_floating.mp3",
            coverImageName: "sleep_hypnosis_floating_cover"
        ),
        SleepContent(
            id: "hypnosis_ocean",
            title: "Ocean Depths Journey",
            narrator: "AI Voice Guide",
            duration: 307,  // 5:07
            contentType: .sleepHypnosis,
            description: "You are walking along a quiet beach at twilight. The sky is painted in soft shades of violet and deep blue.",
            audioFileName: "sleep_hypnosis_ocean.mp3",
            coverImageName: "sleep_hypnosis_ocean_cover"
        ),
        SleepContent(
            id: "hypnosis_staircase",
            title: "The Velvet Staircase",
            narrator: "AI Voice Guide",
            duration: 320,  // 5:20
            contentType: .sleepHypnosis,
            description: "Imagine you're standing at the top of a beautiful staircase. The carpet beneath your feet is the softest velvet.",
            audioFileName: "sleep_hypnosis_staircase.mp3",
            coverImageName: "sleep_hypnosis_staircase_cover"
        )
    ]

    // MARK: - Affirmations

    /// Bedtime affirmations
    static let affirmations: [SleepContent] = [
        SleepContent(
            id: "affirmation_gratitude",
            title: "Gratitude Affirmations",
            narrator: "AI Voice Guide",
            duration: 185,  // 3:05
            contentType: .affirmations,
            description: "Let your heart fill with gratitude as these gentle words guide you peacefully into sleep.",
            audioFileName: "bedtime_gratitude_affirmations.mp3",
            coverImageName: "bedtime_gratitude_affirmations_cover"
        ),
        SleepContent(
            id: "affirmation_peace",
            title: "Peace Affirmations",
            narrator: "AI Voice Guide",
            duration: 177,  // 2:57
            contentType: .affirmations,
            description: "Settle into your bed and let these calming words wash over you as you drift toward peaceful sleep.",
            audioFileName: "bedtime_peace_affirmations.mp3",
            coverImageName: "bedtime_peace_affirmations_cover"
        ),
        SleepContent(
            id: "affirmation_release",
            title: "Release Affirmations",
            narrator: "AI Voice Guide",
            duration: 185,  // 3:05
            contentType: .affirmations,
            description: "Let go of the day's tension as these gentle affirmations help you release and surrender to rest.",
            audioFileName: "bedtime_release_affirmations.mp3",
            coverImageName: "bedtime_release_affirmations_cover"
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
