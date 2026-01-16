import Foundation

struct Story: Identifiable, Equatable {
    let id: String
    let title: String
    let narrator: String
    let duration: TimeInterval  // seconds
    let category: StoryCategory
    let description: String
    let audioFileName: String?  // nil for mock stories without audio

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }
}

enum StoryCategory: String, CaseIterable {
    case fiction = "Fiction"
    case nature = "Nature Journeys"
    case meditation = "Meditation"
    case asmr = "ASMR"

    var icon: String {
        switch self {
        case .fiction: return "book.fill"
        case .nature: return "leaf.fill"
        case .meditation: return "brain.head.profile"
        case .asmr: return "waveform"
        }
    }

    var color: Color {
        switch self {
        case .fiction: return .indigo
        case .nature: return .green
        case .meditation: return .purple
        case .asmr: return .cyan
        }
    }
}

import SwiftUI
