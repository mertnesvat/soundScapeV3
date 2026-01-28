import SwiftUI

struct SoundsView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(FavoritesService.self) private var favoritesService
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(MotionService.self) private var motionService
    @State private var viewModel: SoundsViewModel?

    // Sheet presentation states for toolbar actions
    @State private var showMixerSheet = false
    @State private var showTimerSheet = false
    @State private var showSavedSheet = false
    @State private var showSettingsSheet = false
    @State private var showASMRInfoSheet = false

    private let asmrInfoService = ASMRInfoService()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let viewModel = viewModel {
                        // Category Filter
                        CategoryFilterView(
                            selectedCategory: Binding(
                                get: { viewModel.selectedCategory },
                                set: { viewModel.selectCategory($0) }
                            ))

                        // Favorites Section (only when favorites exist and no category filter)
                        if viewModel.selectedCategory == nil {
                            let favoriteSounds = viewModel.sounds.filter {
                                favoritesService.isFavorite($0.id)
                            }
                            if !favoriteSounds.isEmpty {
                                favoritesSection(sounds: favoriteSounds, viewModel: viewModel)
                            }
                        }

                        // All Sounds Section
                        allSoundsSection(viewModel: viewModel)
                    }
                }
            }
            .oledBackground()
            .navigationTitle("Sounds")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            showSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape")
                        }

                        // Show ASMR info button when ASMR category is selected
                        if viewModel?.selectedCategory == .asmr {
                            Button {
                                showASMRInfoSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color(red: 0.8, green: 0.6, blue: 1.0))
                            }
                        }
                    }
                }

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
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showASMRInfoSheet) {
                ASMRInfoView()
            }
            .onChange(of: viewModel?.selectedCategory) { oldValue, newValue in
                // Show ASMR info sheet on first visit to ASMR category
                if newValue == .asmr && !asmrInfoService.hasSeenInfo {
                    showASMRInfoSheet = true
                    asmrInfoService.markAsSeen()
                }
            }
            .onChange(of: audioEngine.activeSounds.count) { oldCount, newCount in
                if newCount == 0 && oldCount > 0 {
                    showMixerSheet = false
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SoundsViewModel(audioEngine: audioEngine)
                }
                viewModel?.loadSounds()
                motionService.startUpdates()
            }
            .onDisappear {
                motionService.stopUpdates()
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
        .environment(AppearanceService())
        .environment(MotionService())
        .preferredColorScheme(.dark)
}
