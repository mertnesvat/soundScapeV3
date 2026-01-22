import SwiftUI

struct SoundsView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(FavoritesService.self) private var favoritesService
    @State private var viewModel: SoundsViewModel?

    // Sheet presentation states for toolbar actions
    @State private var showMixerSheet = false
    @State private var showTimerSheet = false
    @State private var showSavedSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let viewModel = viewModel {
                        // Category Filter
                        CategoryFilterView(selectedCategory: Binding(
                            get: { viewModel.selectedCategory },
                            set: { viewModel.selectCategory($0) }
                        ))

                        // Favorites Section (only when favorites exist and no category filter)
                        if viewModel.selectedCategory == nil {
                            let favoriteSounds = viewModel.sounds.filter { favoritesService.isFavorite($0.id) }
                            if !favoriteSounds.isEmpty {
                                favoritesSection(sounds: favoriteSounds, viewModel: viewModel)
                            }
                        }

                        // All Sounds Section
                        allSoundsSection(viewModel: viewModel)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Sounds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showMixerSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }

                        Button {
                            showTimerSheet = true
                        } label: {
                            Image(systemName: "moon.zzz")
                        }

                        Button {
                            showSavedSheet = true
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMixerSheet) {
                MixerView()
            }
            .sheet(isPresented: $showTimerSheet) {
                SleepTimerView()
            }
            .sheet(isPresented: $showSavedSheet) {
                SavedMixesView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SoundsViewModel(audioEngine: audioEngine)
                }
                viewModel?.loadSounds()
            }
        }
    }

    @ViewBuilder
    private func favoritesSection(sounds: [Sound], viewModel: SoundsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Favorites")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(sounds) { sound in
                    SoundCardView(
                        sound: sound,
                        isPlaying: viewModel.isPlaying(sound),
                        isFavorite: favoritesService.isFavorite(sound.id),
                        onTogglePlay: {
                            viewModel.togglePlay(for: sound)
                        },
                        onToggleFavorite: {
                            favoritesService.toggleFavorite(sound.id, soundName: sound.name)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func allSoundsSection(viewModel: SoundsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show header only when favorites exist and no category filter
            if viewModel.selectedCategory == nil {
                let hasFavorites = viewModel.sounds.contains { favoritesService.isFavorite($0.id) }
                if hasFavorites {
                    Text("All Sounds")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                }
            }

            // Sound Grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.filteredSounds) { sound in
                    SoundCardView(
                        sound: sound,
                        isPlaying: viewModel.isPlaying(sound),
                        isFavorite: favoritesService.isFavorite(sound.id),
                        onTogglePlay: {
                            viewModel.togglePlay(for: sound)
                        },
                        onToggleFavorite: {
                            favoritesService.toggleFavorite(sound.id, soundName: sound.name)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    SoundsView()
        .environment(AudioEngine())
        .environment(FavoritesService())
        .preferredColorScheme(.dark)
}
