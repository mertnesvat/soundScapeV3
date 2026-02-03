import SwiftUI

struct DiscoverView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var savedMixesService
    @Environment(PaywallService.self) private var paywallService
    @Environment(PremiumManager.self) private var premiumManager
    @State private var selectedCategory: CommunityCategory? = nil
    @State private var showingSavedAlert = false
    @State private var savedMixName = ""

    private let dataSource = LocalCommunityDataSource.shared
    private let allSounds = LocalSoundDataSource.shared.getAllSounds()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Featured Mix Banner
                    if let featured = dataSource.featuredMix, selectedCategory == nil {
                        FeaturedMixBanner(
                            mix: featured,
                            onPlay: { playMix(featured) },
                            onSave: { saveMix(featured) }
                        )
                    }

                    // Category Filter
                    CommunityCategoryFilterView(selected: $selectedCategory)

                    // Content based on selection
                    if let category = selectedCategory {
                        // Show filtered mixes in a grid
                        categoryMixesGrid(for: category)
                    } else {
                        // Show all sections
                        allSections
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizedStringKey("Discover"))
            .alert(LocalizedStringKey("Saved!"), isPresented: $showingSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\"\(savedMixName)\" has been saved to My Mixes")
            }
        }
    }

    @ViewBuilder
    private var allSections: some View {
        // Trending section
        MixSectionView(
            title: String(localized: "Trending Now"),
            mixes: dataSource.mixes(for: .trending),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        // Popular section
        MixSectionView(
            title: String(localized: "All-Time Popular"),
            mixes: dataSource.mixes(for: .popular),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        // Sleep section
        MixSectionView(
            title: String(localized: "For Sleep"),
            mixes: dataSource.mixes(for: .sleep),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        // Focus section
        MixSectionView(
            title: String(localized: "For Focus"),
            mixes: dataSource.mixes(for: .focus),
            onPlayMix: playMix,
            onSaveMix: saveMix
        )

        // Nature section
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
        // Stop all current sounds
        audioEngine.stopAll()

        // Play each sound in the mix
        for mixSound in mix.sounds {
            if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                audioEngine.play(sound: sound)
                audioEngine.setVolume(mixSound.volume, for: sound.id)
            }
        }
    }

    private func saveMix(_ mix: CommunityMix) {
        // Check if premium is required
        if premiumManager.isPremiumRequired(for: .discoverSave) {
            paywallService.triggerPaywall(placement: "discover_save")
            return
        }

        performSaveMix(mix)
    }

    private func performSaveMix(_ mix: CommunityMix) {
        // Convert to active sounds for saving
        var activeSounds: [ActiveSound] = []
        for mixSound in mix.sounds {
            if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                activeSounds.append(ActiveSound(
                    id: sound.id,
                    sound: sound,
                    volume: mixSound.volume,
                    isPlaying: false
                ))
            }
        }

        if !activeSounds.isEmpty {
            savedMixesService.saveMix(name: mix.name, sounds: activeSounds)
            savedMixName = mix.name
            showingSavedAlert = true
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    DiscoverView()
        .environment(AudioEngine())
        .environment(SavedMixesService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
