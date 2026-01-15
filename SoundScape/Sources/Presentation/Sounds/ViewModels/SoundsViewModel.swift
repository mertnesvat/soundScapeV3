import Foundation
import SwiftUI

@Observable
@MainActor
final class SoundsViewModel {
    // MARK: - State
    private(set) var sounds: [Sound] = []
    var selectedCategory: SoundCategory? = nil
    private(set) var playingSoundIds: Set<String> = []

    var filteredSounds: [Sound] {
        if let category = selectedCategory {
            return sounds.filter { $0.category == category }
        }
        return sounds
    }

    // MARK: - Dependencies
    private let repository: SoundRepositoryProtocol

    init(repository: SoundRepositoryProtocol = SoundRepository()) {
        self.repository = repository
    }

    // MARK: - Actions
    func loadSounds() {
        sounds = repository.getAllSounds()
    }

    func selectCategory(_ category: SoundCategory?) {
        selectedCategory = category
    }

    func togglePlay(for sound: Sound) {
        if playingSoundIds.contains(sound.id) {
            playingSoundIds.remove(sound.id)
        } else {
            playingSoundIds.insert(sound.id)
        }
    }

    func isPlaying(_ sound: Sound) -> Bool {
        playingSoundIds.contains(sound.id)
    }
}
