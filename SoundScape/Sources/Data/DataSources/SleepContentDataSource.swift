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
    static let sleepStories: [SleepContent] = [
        SleepContent(
            id: "story_moonlit_garden",
            title: "The Moonlit Garden",
            narrator: "Sarah Mitchell",
            duration: 1800,  // 30 minutes
            contentType: .sleepStory,
            description: "A peaceful journey through an enchanted garden under the soft glow of moonlight.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_ocean_voyage",
            title: "Ocean Voyage",
            narrator: "James Walker",
            duration: 2400,  // 40 minutes
            contentType: .sleepStory,
            description: "Drift off as you sail across calm seas under a starlit sky.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "story_mountain_retreat",
            title: "Mountain Retreat",
            narrator: "Emma Rose",
            duration: 1500,  // 25 minutes
            contentType: .sleepStory,
            description: "Find tranquility in a cozy cabin nestled in the mountains.",
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
