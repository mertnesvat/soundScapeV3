import Foundation

struct SavedMix: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let sounds: [MixSound]
    let createdAt: Date

    struct MixSound: Codable, Equatable {
        let soundId: String
        let volume: Float
    }
}
