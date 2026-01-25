import Foundation
import SwiftUI

/// A unified content model representing all types of sleep content
/// (yoga nidra, stories, meditations, breathing exercises, hypnosis, affirmations)
struct SleepContent: Identifiable, Equatable {
    let id: String
    let title: String
    let narrator: String
    let duration: TimeInterval  // seconds
    let contentType: SleepContentType
    let description: String
    let audioFileName: String?  // nil = Coming Soon
    let coverImageName: String?  // Asset catalog image name, nil = use icon fallback

    /// Whether the content has audio available for playback
    var isAvailable: Bool {
        audioFileName != nil
    }

    /// Whether the content has a custom cover image
    var hasCoverImage: Bool {
        coverImageName != nil
    }

    /// Duration formatted as human-readable string (e.g., "5 min", "1h 30m")
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }

    /// Short duration for compact display (e.g., "5m", "1.5h")
    var compactDuration: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = Double(minutes) / 60.0
            if hours == hours.rounded() {
                return "\(Int(hours))h"
            }
            return String(format: "%.1fh", hours)
        }
        return "\(minutes)m"
    }
}

/// Types of sleep content available in the app
enum SleepContentType: String, CaseIterable, Identifiable {
    case yogaNidra = "Yoga Nidra"
    case sleepStory = "Sleep Stories"
    case guidedMeditation = "Guided Meditation"
    case breathingExercise = "Breathing"
    case sleepHypnosis = "Sleep Hypnosis"
    case affirmations = "Affirmations"

    var id: String { rawValue }

    /// SF Symbol icon for this content type
    var icon: String {
        switch self {
        case .yogaNidra:
            return "figure.mind.and.body"
        case .sleepStory:
            return "book.closed.fill"
        case .guidedMeditation:
            return "brain.head.profile"
        case .breathingExercise:
            return "wind"
        case .sleepHypnosis:
            return "sparkles"
        case .affirmations:
            return "heart.text.square.fill"
        }
    }

    /// Category color for this content type
    var color: Color {
        switch self {
        case .yogaNidra:
            return Color(red: 139/255, green: 92/255, blue: 246/255)  // Deep Purple #8B5CF6
        case .sleepStory:
            return Color(red: 99/255, green: 102/255, blue: 241/255)  // Indigo #6366F1
        case .guidedMeditation:
            return Color(red: 168/255, green: 85/255, blue: 247/255)  // Purple #A855F7
        case .breathingExercise:
            return Color(red: 20/255, green: 184/255, blue: 166/255)  // Teal #14B8A6
        case .sleepHypnosis:
            return Color(red: 59/255, green: 130/255, blue: 246/255)  // Blue #3B82F6
        case .affirmations:
            return Color(red: 236/255, green: 72/255, blue: 153/255)  // Pink #EC4899
        }
    }

    /// Short description of the content type for educational purposes
    var tagline: String {
        switch self {
        case .yogaNidra:
            return "Deep relaxation practice"
        case .sleepStory:
            return "Calming bedtime narratives"
        case .guidedMeditation:
            return "Mindful sleep preparation"
        case .breathingExercise:
            return "Relaxing breath patterns"
        case .sleepHypnosis:
            return "Subconscious relaxation"
        case .affirmations:
            return "Positive sleep intentions"
        }
    }

    /// Display order for sorting content types in UI
    var sortOrder: Int {
        switch self {
        case .yogaNidra: return 0
        case .sleepStory: return 1
        case .guidedMeditation: return 2
        case .breathingExercise: return 3
        case .sleepHypnosis: return 4
        case .affirmations: return 5
        }
    }
}
