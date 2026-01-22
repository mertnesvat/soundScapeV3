import Foundation

@Observable
final class FavoritesService {
    private let favoritesKey = "favorited_sound_ids"
    private(set) var favoritedIds: Set<String> = []

    private var analyticsService: AnalyticsService?
    private var appReviewService: AppReviewService?

    init() {
        loadFavorites()
    }

    func setServices(analytics: AnalyticsService, appReview: AppReviewService) {
        self.analyticsService = analytics
        self.appReviewService = appReview
    }

    func isFavorite(_ soundId: String) -> Bool {
        favoritedIds.contains(soundId)
    }

    func toggleFavorite(_ soundId: String, soundName: String) {
        if favoritedIds.contains(soundId) {
            favoritedIds.remove(soundId)
            analyticsService?.logFavoriteRemoved(soundId: soundId, soundName: soundName)
        } else {
            favoritedIds.insert(soundId)
            analyticsService?.logFavoriteAdded(soundId: soundId, soundName: soundName)

            // Request review after adding favorites (positive action)
            if let analytics = analyticsService {
                appReviewService?.onFavoriteAdded(favoriteCount: favoritedIds.count, analyticsService: analytics)
            }
        }
        saveFavorites()
    }

    // Keep old method for backward compatibility
    func toggleFavorite(_ soundId: String) {
        toggleFavorite(soundId, soundName: soundId)
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
