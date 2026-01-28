import SwiftUI

struct SoundsView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(FavoritesService.self) private var favoritesService
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(MotionService.self) private var motionService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService
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
        GridItem(.flexible(), spacing: 16)
    ]

    private let freeSoundLimit = 6

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
                    let isLocked = premiumManager.isPremiumRequired(for: .sound(id: sound.id))
                    SoundCardView(
                        sound: sound,
                        isPlaying: viewModel.isPlaying(sound),
                        isFavorite: favoritesService.isFavorite(sound.id),
                        isLocked: isLocked,
                        onTogglePlay: {
                            if isLocked {
                                paywallService.triggerPaywall(placement: "campaign_trigger") {
                                    viewModel.togglePlay(for: sound)
                                }
                            } else if wouldExceedMixerLimit(for: sound) {
                                // Mixer limit reached for free users - show paywall without action
                                paywallService.triggerPaywall(placement: "campaign_trigger") {}
                            } else {
                                viewModel.togglePlay(for: sound)
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
                    let isLocked = premiumManager.isPremiumRequired(for: .sound(id: sound.id))
                    SoundCardView(
                        sound: sound,
                        isPlaying: viewModel.isPlaying(sound),
                        isFavorite: favoritesService.isFavorite(sound.id),
                        isLocked: isLocked,
                        onTogglePlay: {
                            if isLocked {
                                paywallService.triggerPaywall(placement: "campaign_trigger") {
                                    viewModel.togglePlay(for: sound)
                                }
                            } else if wouldExceedMixerLimit(for: sound) {
                                // Mixer limit reached for free users - show paywall without action
                                // Sound will only play if user becomes premium
                                paywallService.triggerPaywall(placement: "campaign_trigger") {}
                            } else {
                                viewModel.togglePlay(for: sound)
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    SoundsView()
        .environment(AudioEngine())
        .environment(FavoritesService())
        .environment(AppearanceService())
        .environment(MotionService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
