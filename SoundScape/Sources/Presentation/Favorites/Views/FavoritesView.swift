import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesService.self) private var favoritesService
    @Environment(AudioEngine.self) private var audioEngine

    private let repository: SoundRepositoryProtocol

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(repository: SoundRepositoryProtocol = SoundRepository()) {
        self.repository = repository
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
                                SoundCardView(
                                    sound: sound,
                                    isPlaying: audioEngine.isPlaying(soundId: sound.id),
                                    isFavorite: favoritesService.isFavorite(sound.id),
                                    onTogglePlay: {
                                        audioEngine.togglePlayback(for: sound)
                                    },
                                    onToggleFavorite: {
                                        favoritesService.toggleFavorite(sound.id)
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
    FavoritesView()
        .environment(FavoritesService())
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
