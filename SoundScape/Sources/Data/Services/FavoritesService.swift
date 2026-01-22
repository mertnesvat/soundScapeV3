import Foundation

@Observable
final class FavoritesService {
    private let favoritesKey = "favorited_sound_ids"
    private(set) var favoritedIds: Set<String> = []
    private var analyticsService: AnalyticsService?

    init() {
        loadFavorites()
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
        // Update user property
        analyticsService?.setFavoriteCount(favoritedIds.count)
    }

    func isFavorite(_ soundId: String) -> Bool {
        favoritedIds.contains(soundId)
    }

    func toggleFavorite(_ soundId: String) {
        if favoritedIds.contains(soundId) {
            favoritedIds.remove(soundId)
            analyticsService?.logEvent(.favoriteRemove, parameters: ["sound_id": soundId])
        } else {
            favoritedIds.insert(soundId)
            analyticsService?.logEvent(.favoriteAdd, parameters: ["sound_id": soundId])
        }
        saveFavorites()
        analyticsService?.setFavoriteCount(favoritedIds.count)
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
