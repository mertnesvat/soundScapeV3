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
    @State private var showBinauralSheet = false
    @State private var sheetOpenTime: Date = .now

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.padding.standard),
        GridItem(.flexible(), spacing: DesignTokens.padding.standard),
    ]

    /// Categories surfaced as filter chips, per issue #33.
    private let chipCategories: [SoundCategory] = [.noise, .nature, .weather, .fire, .music]

    private let freeSoundLimit = 6

    /// Check if adding a new sound would exceed the free user limit
    private func wouldExceedMixerLimit(for sound: Sound) -> Bool {
        if audioEngine.isPlaying(soundId: sound.id) {
            return false
        }
        if paywallService.isPremium {
            return false
        }
        return audioEngine.activeSounds.count >= freeSoundLimit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.padding.standard) {
                    if let viewModel {
                        chipRow(viewModel: viewModel)
                        soundGrid(viewModel: viewModel)
                    }
                }
                .padding(.vertical, DesignTokens.padding.standard)
            }
            .oledBackground()
            .navigationTitle(LocalizedStringKey("Sounds"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DesignTokens.padding.standard) {
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
            .sheet(isPresented: $showBinauralSheet, onDismiss: {
                analyticsService.logSheetDismissed(sheetName: "binaural", duration: Date().timeIntervalSince(sheetOpenTime))
            }) {
                BinauralBeatsView()
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
    private func chipRow(viewModel: SoundsViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.padding.compact) {
                FilterChip(
                    title: String(localized: "All"),
                    icon: "square.grid.2x2.fill",
                    tint: DesignTokens.accent,
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }

                ForEach(chipCategories, id: \.self) { category in
                    FilterChip(
                        title: category.localizedName,
                        icon: category.icon,
                        tint: DesignTokens.categoryColor(for: category),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }

                FilterChip(
                    title: String(localized: "Binaural"),
                    icon: "waveform",
                    tint: DesignTokens.accent,
                    isSelected: false
                ) {
                    showBinauralSheet = true
                    analyticsService.logSheetOpened(sheetName: "binaural", fromScreen: "sounds")
                    sheetOpenTime = .now
                }
            }
            .padding(.horizontal, DesignTokens.padding.standard)
        }
    }

    @ViewBuilder
    private func soundGrid(viewModel: SoundsViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.padding.standard) {
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
        .padding(.horizontal, DesignTokens.padding.standard)
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(DesignTokens.font.body))
                Text(title)
                    .font(.subheadline.weight(DesignTokens.font.body))
            }
            .padding(.horizontal, DesignTokens.padding.standard)
            .padding(.vertical, DesignTokens.padding.compact)
            .background(
                Capsule().fill(isSelected ? tint : tint.opacity(chipDimOpacity))
            )
            .foregroundColor(isSelected ? DesignTokens.surface : tint)
        }
        .buttonStyle(.plain)
    }

    private var chipDimOpacity: Double { 0.15 }
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
