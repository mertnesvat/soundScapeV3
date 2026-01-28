import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesService.self) private var favoritesService
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService

    private let repository: SoundRepositoryProtocol

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let freeSoundLimit = 6

    init(repository: SoundRepositoryProtocol = SoundRepository()) {
        self.repository = repository
    }

    /// Check if adding a new sound would exceed the free user limit
    private func wouldExceedMixerLimit(for sound: Sound) -> Bool {
        // If already playing, toggling won't add a new sound
        if audioEngine.isPlaying(soundId: sound.id) {
            return false
        }
        // If premium user, no limit
        if paywallService.isPremium {
            return false
        }
        // Check if at or over limit
        return audioEngine.activeSounds.count >= freeSoundLimit
    }

    private var allSounds: [Sound] {
        repository.getAllSounds()
    }

    private var favoriteSounds: [Sound] {
        allSounds.filter { favoritesService.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteSounds.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "heart.slash",
                        description: Text("Tap the heart on sounds to add favorites")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(favoriteSounds) { sound in
                                let isLocked = premiumManager.isPremiumRequired(for: .sound(id: sound.id))
                                SoundCardView(
                                    sound: sound,
                                    isPlaying: audioEngine.isPlaying(soundId: sound.id),
                                    isFavorite: favoritesService.isFavorite(sound.id),
                                    isLocked: isLocked,
                                    onTogglePlay: {
                                        if isLocked {
                                            paywallService.triggerPaywall(placement: "campaign_trigger") {
                                                audioEngine.togglePlayback(for: sound)
                                            }
                                        } else if wouldExceedMixerLimit(for: sound) {
                                            // Mixer limit reached for free users - show paywall without action
                                            paywallService.triggerPaywall(placement: "campaign_trigger") {}
                                        } else {
                                            audioEngine.togglePlayback(for: sound)
                                        }
                                    },
                                    onToggleFavorite: {
                                        favoritesService.toggleFavorite(sound.id, soundName: sound.name)
                                    },
                                    onLockedTap: {
                                        paywallService.triggerPaywall(placement: "campaign_trigger") {}
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Favorites")
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    FavoritesView()
        .environment(FavoritesService())
        .environment(AudioEngine())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
