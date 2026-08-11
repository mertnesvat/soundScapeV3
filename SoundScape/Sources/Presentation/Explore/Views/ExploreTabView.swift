import SwiftUI

struct ExploreTabView: View {
    @State private var selectedSegment: ExploreSegment = .discover

    enum ExploreSegment: String, CaseIterable {
        case discover
        case adaptive

        var localizedName: String {
            switch self {
            case .discover: return String(localized: "Discover")
            case .adaptive: return String(localized: "Adaptive")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(String(localized: "Explore"), selection: $selectedSegment) {
                    ForEach(ExploreSegment.allCases, id: \.self) { segment in
                        Text(segment.localizedName).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Group {
                    switch selectedSegment {
                    case .discover:
                        DiscoverContentView()
                    case .adaptive:
                        AdaptiveContentView()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Explore"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Discover content extracted without its own NavigationStack
private struct DiscoverContentView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var savedMixesService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var selectedCategory: CommunityCategory? = nil
    @State private var showingSavedAlert = false
    @State private var savedMixName = ""

    private let dataSource = LocalCommunityDataSource.shared
    private let allSounds = LocalSoundDataSource.shared.getAllSounds()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let featured = dataSource.featuredMix, selectedCategory == nil {
                    FeaturedMixBanner(
                        mix: featured,
                        onPlay: { playMix(featured) },
                        onSave: { saveMix(featured) }
                    )
                }

                CommunityCategoryFilterView(selected: $selectedCategory)

                if let category = selectedCategory {
                    categoryMixesGrid(for: category)
                } else {
                    allSections
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            analyticsService.logDiscoverTabOpened()
        }
        .alert(LocalizedStringKey("Saved!"), isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(savedMixName)\" has been saved to My Mixes")
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
    }

    @ViewBuilder
    private var allSections: some View {
        MixSectionView(
            title: String(localized: "Trending Now"),
            mixes: dataSource.mixes(for: .trending),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        MixSectionView(
            title: String(localized: "All-Time Popular"),
            mixes: dataSource.mixes(for: .popular),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        MixSectionView(
            title: String(localized: "For Sleep"),
            mixes: dataSource.mixes(for: .sleep),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        MixSectionView(
            title: String(localized: "For Focus"),
            mixes: dataSource.mixes(for: .focus),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        MixSectionView(
            title: String(localized: "Nature Soundscapes"),
            mixes: dataSource.mixes(for: .nature),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )
    }

    @ViewBuilder
    private func categoryMixesGrid(for category: CommunityCategory) -> some View {
        let mixes = dataSource.mixes(for: category)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.icon)
                Text(category.localizedName)
                    .fontWeight(.bold)
                Spacer()
                Text("\(mixes.count) mixes")
                    .foregroundStyle(.secondary)
            }
            .font(.title2)
            .padding(.horizontal)

            LazyVStack(spacing: 16) {
                ForEach(mixes) { mix in
                    NavigationLink(value: mix) {
                        CommunityMixCardView(
                            mix: mix,
                            onPlay: { playMix(mix) },
                            onSave: { saveMix(mix) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationDestination(for: CommunityMix.self) { mix in
            MixDetailView(mix: mix)
        }
    }

    private func playMix(_ mix: CommunityMix) {
        analyticsService.logDiscoverMixPreviewed(mixId: mix.id.uuidString, mixName: mix.name)
        audioEngine.stopAll()
        for mixSound in mix.sounds {
            if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                audioEngine.play(sound: sound)
                audioEngine.setVolume(mixSound.volume, for: sound.id)
            }
        }
    }

    private func saveMix(_ mix: CommunityMix) {
        if premiumManager.isPremiumRequired(for: .discoverSave) {
            paywallService.triggerPaywall(placement: "discover_save") {
                performSaveMix(mix)
            }
            return
        }
        performSaveMix(mix)
    }

    private func performSaveMix(_ mix: CommunityMix) {
        if savedMixesService.saveCommunityMix(mix, allSounds: allSounds) {
            savedMixName = mix.name
            showingSavedAlert = true
        }
    }
}

/// Adaptive content extracted without its own NavigationStack
private struct AdaptiveContentView: View {
    @Environment(AdaptiveSessionService.self) private var adaptiveService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService

    var body: some View {
        Group {
            if premiumManager.isPremiumRequired(for: .adaptiveMode) {
                AdaptivePremiumPreview(
                    onUnlock: {
                        paywallService.triggerPaywall(placement: "adaptive_mode") {}
                    }
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if adaptiveService.isActive {
                            ActiveAdaptiveSessionView()
                        } else {
                            modeSelectionView
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            analyticsService.logAdaptiveTabOpened()
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
    }

    private var modeSelectionView: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("Choose an Adaptive Mode"))
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AdaptiveMode.allCases) { mode in
                AdaptiveModeCardView(mode: mode) {
                    adaptiveService.start(mode: mode)
                }
            }
        }
    }
}

#Preview {
    let audioEngine = AudioEngine()
    let paywallService = PaywallService()
    ExploreTabView()
        .environment(audioEngine)
        .environment(AdaptiveSessionService(audioEngine: audioEngine))
        .environment(SavedMixesService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
