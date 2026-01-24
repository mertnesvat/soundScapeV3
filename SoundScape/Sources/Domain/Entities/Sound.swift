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
    case asmr = "ASMR"

    var icon: String {
        switch self {
        case .noise: return "waveform.path"
        case .nature: return "leaf.fill"
        case .weather: return "cloud.rain.fill"
        case .fire: return "flame.fill"
        case .music: return "music.note"
        case .asmr: return "hand.wave.fill"
        }
    }

    var color: String {
        switch self {
        case .noise: return "purple"
        case .nature: return "green"
        case .weather: return "blue"
        case .fire: return "orange"
        case .music: return "pink"
        case .asmr: return "lavender"
        }
    }
}
