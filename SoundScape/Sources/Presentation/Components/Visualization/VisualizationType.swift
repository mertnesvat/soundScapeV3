import SwiftUI

/// Defines the visual style for each sound category
enum VisualizationType {
    case wave       // Ocean, rain - rolling sine waves
    case particles  // Fire, nature - rising/floating particles
    case grain      // Noise - subtle static grain
    case flow       // Wind - horizontal flowing lines
    case melody     // Music - pulsing circles

    /// Maps a SoundCategory to its visualization type
    static func from(_ category: SoundCategory) -> VisualizationType {
        switch category {
        case .weather:
            return .wave
        case .fire:
            return .particles
        case .nature:
            return .particles
        case .noise:
            return .grain
        case .music:
            return .melody
        }
    }

    /// Returns the primary color for the visualization based on category
    static func color(for category: SoundCategory) -> Color {
        switch category {
        case .noise: return .purple
        case .nature: return .green
        case .weather: return .blue
        case .fire: return .orange
        case .music: return .pink
        }
    }
}

/// Configuration for a single visualization layer
struct VisualizationLayer: Identifiable {
    let id: String
    let type: VisualizationType
    let color: Color
    let intensity: Float // 0.0 - 1.0, based on volume
    let category: SoundCategory

    init(from activeSound: ActiveSound) {
        self.id = activeSound.id
        self.type = VisualizationType.from(activeSound.sound.category)
        self.color = VisualizationType.color(for: activeSound.sound.category)
        self.intensity = activeSound.volume
        self.category = activeSound.sound.category
    }
}
