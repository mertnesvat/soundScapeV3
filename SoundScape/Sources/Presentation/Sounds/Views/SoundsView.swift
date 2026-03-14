import SwiftUI

struct SoundsView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(FavoritesService.self) private var favoritesService
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(MotionService.self) private var motionService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var viewModel: SoundsViewModel?

    // Sheet presentation states for toolbar actions
    @State private var showMixerSheet = false
    @State private var showTimerSheet = false
    @State private var showSavedSheet = false
    @State private var showSettingsSheet = false
    @State private var showASMRInfoSheet = false
    @State private var sheetOpenTime: Date = .now

    private let asmrInfoService = ASMRInfoService()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
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
                        CategoryFilterView(
                            selectedCategory: Binding(
                                get: { viewModel.selectedCategory },
                                set: { viewModel.selectCategory($0) }
                            ),
                            showingFavorites: viewModel.showingFavorites,
                            onSelectFavorites: {
                                viewModel.selectFavorites()
                            },
                            onSelectCategory: { category in
                                viewModel.selectCategory(category)
                            }
                        )

                        // Favorites empty state
                        if viewModel.showingFavorites && viewModel.filteredSounds.isEmpty {
                            ContentUnavailableView(
                                String(localized: "No Favorites"),
                                systemImage: "heart.slash",
                                description: Text("Tap the heart on sounds to add favorites")
                            )
                            .padding(.top, 60)
                        } else {
                            // All Sounds Section
                            allSoundsSection(viewModel: viewModel)
                        }
                    }
                }
            }
            .oledBackground()
            .navigationTitle(LocalizedStringKey("Sounds"))
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
                                    .foregroundColor(AppTheme.asmrPurple)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showMixerSheet = true
                            analyticsService.logSheetOpened(sheetName: "mixer", fromScreen: "sounds")
                            sheetOpenTime = .now
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }

                        Button {
                            showTimerSheet = true
                            analyticsService.logSheetOpened(sheetName: "timer", fromScreen: "sounds")
                            sheetOpenTime = .now
                        } label: {
                            Image(systemName: "moon.zzz")
                        }

                        Button {
                            showSavedSheet = true
                            analyticsService.logSheetOpened(sheetName: "saved_mixes", fromScreen: "sounds")
                            sheetOpenTime = .now
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMixerSheet, onDismiss: {
                analyticsService.logSheetDismissed(sheetName: "mixer", duration: Date().timeIntervalSince(sheetOpenTime))
            }) {
                MixerView()
            }
            .sheet(isPresented: $showTimerSheet, onDismiss: {
                analyticsService.logSheetDismissed(sheetName: "timer", duration: Date().timeIntervalSince(sheetOpenTime))
            }) {
                SleepTimerView()
            }
            .sheet(isPresented: $showSavedSheet, onDismiss: {
                analyticsService.logSheetDismissed(sheetName: "saved_mixes", duration: Date().timeIntervalSince(sheetOpenTime))
            }) {
                SavedMixesView()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showASMRInfoSheet) {
                ASMRInfoView()
            }
            .sheet(isPresented: Binding(
                get: { paywallService.showPaywall },
                set: { newValue in
                    if !newValue {
                        paywallService.handlePaywallDismissed()
                    }
                }
            )) {
                OnboardingPaywallView(
                    onComplete: {
                        paywallService.showPaywall = false
                    },
                    isPresented: true
                )
                .environment(onboardingService)
                .environment(paywallService)
                .environment(subscriptionService)
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
                    viewModel = SoundsViewModel(audioEngine: audioEngine, favoritesService: favoritesService)
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
    private func allSoundsSection(viewModel: SoundsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                            analyticsService.logSoundCardTapped(
                                soundId: sound.id,
                                soundName: sound.name,
                                category: sound.category.rawValue,
                                isPremium: isLocked,
                                isPlaying: viewModel.isPlaying(sound)
                            )
                            if isLocked {
                                paywallService.triggerPaywall(placement: "premium_sound") {
                                    viewModel.togglePlay(for: sound)
                                }
                            } else if wouldExceedMixerLimit(for: sound) {
                                paywallService.triggerPaywall(placement: "unlimited_mixing") {}
                            } else {
                                viewModel.togglePlay(for: sound)
                            }
                        },
                        onToggleFavorite: {
                            favoritesService.toggleFavorite(sound.id, soundName: sound.name)
                        },
                        onLockedTap: {
                            paywallService.triggerPaywall(placement: "premium_sound") {}
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
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
