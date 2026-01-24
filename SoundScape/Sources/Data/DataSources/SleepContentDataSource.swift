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
            title: "Body Scan for Sleep",
            narrator: "Dr. Michael Chen",
            duration: 900,  // 15 minutes
            contentType: .guidedMeditation,
            description: "Progressive relaxation through gentle awareness of each part of your body.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "meditation_loving_kindness",
            title: "Loving Kindness",
            narrator: "Maya Thompson",
            duration: 1200,  // 20 minutes
            contentType: .guidedMeditation,
            description: "Cultivate feelings of warmth and compassion as you drift to sleep.",
            audioFileName: nil  // Coming Soon
        )
    ]

    // MARK: - Breathing Exercises (Coming Soon Placeholders)

    /// Breathing exercises for relaxation
    static let breathingExercises: [SleepContent] = [
        SleepContent(
            id: "breathing_4_7_8",
            title: "4-7-8 Breathing",
            narrator: "Guided Voice",
            duration: 300,  // 5 minutes
            contentType: .breathingExercise,
            description: "The classic relaxation breath pattern: inhale 4, hold 7, exhale 8.",
            audioFileName: nil  // Coming Soon
        ),
        SleepContent(
            id: "breathing_box",
            title: "Box Breathing",
            narrator: "Guided Voice",
            duration: 420,  // 7 minutes
            contentType: .breathingExercise,
            description: "Square breathing technique used by Navy SEALs for calm and focus.",
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
