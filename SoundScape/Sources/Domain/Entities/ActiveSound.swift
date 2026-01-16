import Foundation

struct ActiveSound: Identifiable, Equatable {
    let id: String  // Same as Sound.id
    let sound: Sound
    var volume: Float = 0.7
    var isPlaying: Bool = true
}
