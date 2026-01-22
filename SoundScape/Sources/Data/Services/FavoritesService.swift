import Foundation

@Observable
@MainActor
final class FavoritesService {
    private let favoritesKey = "favorited_sound_ids"
    private(set) var favoritedIds: Set<String> = []
    private var analyticsService: AnalyticsService?
    private var reviewPromptService: ReviewPromptService?

    init() {
        loadFavorites()
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    func setReviewPromptService(_ service: ReviewPromptService) {
        self.reviewPromptService = service
    }

    func isFavorite(_ soundId: String) -> Bool {
        favoritedIds.contains(soundId)
    }

    func toggleFavorite(_ soundId: String, soundName: String = "") {
        if favoritedIds.contains(soundId) {
            favoritedIds.remove(soundId)
            analyticsService?.logSoundUnfavorited(soundId: soundId, soundName: soundName)
        } else {
            favoritedIds.insert(soundId)
            analyticsService?.logSoundFavorited(soundId: soundId, soundName: soundName)
            reviewPromptService?.recordFavoriteAction()
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
