import Foundation

enum BrainwaveState: String, CaseIterable, Identifiable {
    case delta = "Delta"
    case theta = "Theta"
    case alpha = "Alpha"
    case beta = "Beta"
    case gamma = "Gamma"

    var id: String { rawValue }

    var frequency: Float {
        switch self {
        case .delta: return 2.0
        case .theta: return 6.0
        case .alpha: return 10.0
        case .beta: return 20.0
        case .gamma: return 40.0
        }
    }

    var localizedName: String {
        switch self {
        case .delta: return String(localized: "Delta")
        case .theta: return String(localized: "Theta")
        case .alpha: return String(localized: "Alpha")
        case .beta: return String(localized: "Beta")
        case .gamma: return String(localized: "Gamma")
        }
    }

    var description: String {
        switch self {
        case .delta: return "Deep Sleep"
        case .theta: return "Meditation"
        case .alpha: return "Relaxation"
        case .beta: return "Focus"
        case .gamma: return "Creativity"
        }
    }

    var localizedDescription: String {
        switch self {
        case .delta: return String(localized: "Deep sleep")
        case .theta: return String(localized: "Meditation")
        case .alpha: return String(localized: "Relaxed focus")
        case .beta: return String(localized: "Alertness")
        case .gamma: return String(localized: "Creativity")
        }
    }

    var icon: String {
        switch self {
        case .delta: return "moon.zzz.fill"
        case .theta: return "brain.head.profile"
        case .alpha: return "leaf.fill"
        case .beta: return "bolt.fill"
        case .gamma: return "sparkles"
        }
    }

    var colorName: String {
        switch self {
        case .delta: return "indigo"
        case .theta: return "purple"
        case .alpha: return "green"
        case .beta: return "orange"
        case .gamma: return "yellow"
        }
    }
}

enum ToneType: String, CaseIterable, Identifiable {
    case binaural = "Binaural"
    case isochronic = "Isochronic"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .binaural: return String(localized: "Binaural")
        case .isochronic: return String(localized: "Isochronic")
        }
    }

    var description: String {
        switch self {
        case .binaural: return "Requires headphones - different frequencies in each ear"
        case .isochronic: return "Works with speakers - rhythmic pulses"
        }
    }

    var localizedDescription: String {
        switch self {
        case .binaural: return String(localized: "Requires headphones - different frequencies in each ear")
        case .isochronic: return String(localized: "Works with speakers - rhythmic pulses")
        }
    }
}

enum BaseFrequency: Float, CaseIterable, Identifiable {
    case low = 200.0
    case medium = 300.0
    case high = 400.0

    var id: Float { rawValue }

    var displayName: String {
        "\(Int(rawValue)) Hz"
    }
}
