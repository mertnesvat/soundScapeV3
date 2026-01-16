import Foundation

struct Sound: Identifiable, Equatable {
    let id: String
    let name: String
    let category: SoundCategory
    let fileName: String
    var isFavorite: Bool = false
}

enum SoundCategory: String, CaseIterable {
    case noise = "Noise"
    case nature = "Nature"
    case weather = "Weather"
    case fire = "Fire"
    case music = "Music"

    var icon: String {
        switch self {
        case .noise: return "waveform.path"
        case .nature: return "leaf.fill"
        case .weather: return "cloud.rain.fill"
        case .fire: return "flame.fill"
        case .music: return "music.note"
        }
    }

    var color: String {
        switch self {
        case .noise: return "purple"
        case .nature: return "green"
        case .weather: return "blue"
        case .fire: return "orange"
        case .music: return "pink"
        }
    }
}
