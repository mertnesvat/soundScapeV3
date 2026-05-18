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
    private let freeSoundLimit = 6

    /// The editorial "featured" category — rendered inside a full-bleed
    /// `Tokens.colorOrange` block with white type, mirroring ref01's
    /// `Nos expertises` panel. First non-noise category.
    private let featuredCategory: SoundCategory = .nature

    /// Check if adding a new sound would exceed the free user limit
    private func wouldExceedMixerLimit(for sound: Sound) -> Bool {
        if audioEngine.isPlaying(soundId: sound.id) { return false }
        if paywallService.isPremium { return false }
        return audioEngine.activeSounds.count >= freeSoundLimit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let viewModel = viewModel {
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
                        .padding(.bottom, 8)

                        sectionStack(for: viewModel)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Tokens.colorCream.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("Sounds"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            showSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(Tokens.colorInk)
                        }

                        if viewModel?.selectedCategory == .asmr {
                            Button {
                                showASMRInfoSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Tokens.colorInk)
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
                                .foregroundColor(Tokens.colorInk)
                        }

                        Button {
                            showTimerSheet = true
                            analyticsService.logSheetOpened(sheetName: "timer", fromScreen: "sounds")
                            sheetOpenTime = .now
                        } label: {
                            Image(systemName: "moon.zzz")
                                .foregroundColor(Tokens.colorInk)
                        }

                        Button {
                            showSavedSheet = true
                            analyticsService.logSheetOpened(sheetName: "saved_mixes", fromScreen: "sounds")
                            sheetOpenTime = .now
                        } label: {
                            Image(systemName: "folder")
                                .foregroundColor(Tokens.colorInk)
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

    // MARK: - Editorial section stack

    @ViewBuilder
    private func sectionStack(for viewModel: SoundsViewModel) -> some View {
        if viewModel.showingFavorites {
            if viewModel.filteredSounds.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Favorites"),
                    systemImage: "heart.slash",
                    description: Text("Tap the heart on sounds to add favorites")
                )
                .foregroundStyle(Tokens.colorInk.opacity(0.6))
                .padding(.top, 60)
            } else {
                editorialSection(
                    title: String(localized: "Favorites"),
                    sounds: viewModel.filteredSounds,
                    featured: false,
                    viewModel: viewModel
                )
            }
        } else if let category = viewModel.selectedCategory {
            editorialSection(
                title: category.localizedName,
                sounds: viewModel.filteredSounds,
                featured: category == featuredCategory,
                viewModel: viewModel
            )
        } else {
            let favoriteSounds = viewModel.sounds.filter { favoritesService.isFavorite($0.id) }
            if !favoriteSounds.isEmpty {
                editorialSection(
                    title: String(localized: "Favorites"),
                    sounds: favoriteSounds,
                    featured: false,
                    viewModel: viewModel
                )
            }

            ForEach(SoundCategory.allCases, id: \.self) { category in
                let categorySounds = viewModel.sounds.filter { $0.category == category }
                if !categorySounds.isEmpty {
                    editorialSection(
                        title: category.localizedName,
                        sounds: categorySounds,
                        featured: category == featuredCategory,
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func editorialSection(
        title: String,
        sounds: [Sound],
        featured: Bool,
        viewModel: SoundsViewModel
    ) -> some View {
        let foreground: Color = featured ? .white : Tokens.colorInk

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: Tokens.headlineSize,
                                  weight: .black,
                                  design: .default))
                    .foregroundColor(foreground)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(foreground)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)

            Rectangle()
                .fill(foreground.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 24)

            LazyVStack(spacing: 0) {
                ForEach(Array(sounds.enumerated()), id: \.element.id) { offset, sound in
                    soundRow(for: sound, index: offset + 1, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(featured ? Tokens.colorOrange : Color.clear)
    }

    @ViewBuilder
    private func soundRow(for sound: Sound, index: Int, viewModel: SoundsViewModel) -> some View {
        let isLocked = premiumManager.isPremiumRequired(for: .sound(id: sound.id))

        SoundCardView(
            sound: sound,
            isPlaying: viewModel.isPlaying(sound),
            isFavorite: favoritesService.isFavorite(sound.id),
            isLocked: isLocked,
            index: index,
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
        .padding(.vertical, 4)
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
}
