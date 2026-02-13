import Foundation
import SwiftUI

@Observable
@MainActor
final class SoundsViewModel {
    // MARK: - State
    private(set) var sounds: [Sound] = []
    var selectedCategory: SoundCategory? = nil
    var showingFavorites: Bool = false

    var filteredSounds: [Sound] {
        if showingFavorites {
            guard let favoritesService = favoritesService else { return [] }
            return sounds.filter { favoritesService.isFavorite($0.id) }
        }
        if let category = selectedCategory {
            return sounds.filter { $0.category == category }
        }
        return sounds
    }

    // MARK: - Dependencies
    private let repository: SoundRepositoryProtocol
    private let audioEngine: AudioEngine
    private var favoritesService: FavoritesService?

    init(repository: SoundRepositoryProtocol = SoundRepository(), audioEngine: AudioEngine, favoritesService: FavoritesService? = nil) {
        self.repository = repository
        self.audioEngine = audioEngine
        self.favoritesService = favoritesService
    }

    func setFavoritesService(_ service: FavoritesService) {
        self.favoritesService = service
    }

    // MARK: - Actions
    func loadSounds() {
        sounds = repository.getAllSounds()
    }

    func selectCategory(_ category: SoundCategory?) {
        selectedCategory = category
        showingFavorites = false
    }

    func selectFavorites() {
        selectedCategory = nil
        showingFavorites = true
    }

    func togglePlay(for sound: Sound) {
        audioEngine.togglePlayback(for: sound)
    }

    func isPlaying(_ sound: Sound) -> Bool {
        audioEngine.isPlaying(soundId: sound.id)
    }

    // MARK: - Active Sounds Access
    var activeSounds: [ActiveSound] {
        audioEngine.activeSounds
    }

    var isAnyPlaying: Bool {
        audioEngine.isAnyPlaying
    }
}
