import Foundation

@Observable
final class FavoritesService {
    private let favoritesKey = "favorited_sound_ids"
    private(set) var favoritedIds: Set<String> = []

    init() {
        loadFavorites()
    }

    func isFavorite(_ soundId: String) -> Bool {
        favoritedIds.contains(soundId)
    }

    func toggleFavorite(_ soundId: String) {
        if favoritedIds.contains(soundId) {
            favoritedIds.remove(soundId)
        } else {
            favoritedIds.insert(soundId)
        }
        saveFavorites()
    }

    private func loadFavorites() {
        if let ids = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoritedIds = Set(ids)
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoritedIds), forKey: favoritesKey)
    }
}
