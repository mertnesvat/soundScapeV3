import SwiftUI

struct ContentView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SleepTimerService.self) private var sleepTimerService
    @Environment(SleepContentPlayerService.self) private var sleepContentPlayerService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @State private var selectedTab: Tab = .sounds
    @State private var showingSleepContentPlayer = false
    @State private var showMixerSheet = false
    @State private var tabStartTime: Date = .now

    enum Tab: String, CaseIterable {
        case sounds
        case windDown
        case insights

        var icon: String {
            switch self {
            case .sounds: return "waveform"
            case .windDown: return "moon.zzz.fill"
            case .insights: return "chart.bar.fill"
            }
        }

        var localizedName: LocalizedStringKey {
            switch self {
            case .sounds: return "Sounds"
            case .windDown: return "Wind Down"
            case .insights: return "Insights"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                SoundsView()
                    .tabItem {
                        Label(Tab.sounds.localizedName, systemImage: Tab.sounds.icon)
                    }
                    .tag(Tab.sounds)

                WindDownView()
                    .tabItem {
                        Label(Tab.windDown.localizedName, systemImage: Tab.windDown.icon)
                    }
                    .tag(Tab.windDown)

                InsightsView()
                    .tabItem {
                        Label(Tab.insights.localizedName, systemImage: Tab.insights.icon)
                    }
                    .tag(Tab.insights)
            }
            .tint(DesignTokens.accent)
            .onChange(of: selectedTab) { oldTab, newTab in
                let durationOnTab = Date().timeIntervalSince(tabStartTime)
                analyticsService.logTabSwitched(
                    fromTab: oldTab.rawValue,
                    toTab: newTab.rawValue,
                    durationOnTab: durationOnTab
                )
                tabStartTime = Date()
            }
            .onChange(of: appearanceService.isOLEDModeEnabled) { _, isOLED in
                configureTabBarAppearance(isOLED: isOLED)
            }
            .onAppear {
                configureTabBarAppearance(isOLED: appearanceService.isOLEDModeEnabled)
            }

            // Now Playing Bars above tab bar
            VStack(spacing: 8) {
                Spacer()

                // Sleep content mini player (when content is playing but full player is dismissed)
                if sleepContentPlayerService.currentContent != nil && !showingSleepContentPlayer {
                    SleepContentMiniPlayer(onTap: {
                        showingSleepContentPlayer = true
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Sound mixer now playing bar
                NowPlayingBarView(showMixer: $showMixerSheet)
            }
            .padding(.bottom, 49)  // Tab bar height
            .animation(.spring(response: 0.3), value: audioEngine.activeSounds.isEmpty)
            .animation(.spring(response: 0.3), value: sleepContentPlayerService.currentContent?.id)
            .onChange(of: audioEngine.activeSounds.count) { oldCount, newCount in
                if newCount == 0 && oldCount > 0 {
                    showMixerSheet = false
                }
            }

            // Sleep content player sheet
            .sheet(isPresented: $showingSleepContentPlayer) {
                if let content = sleepContentPlayerService.currentContent {
                    SleepContentPlayerView(
                        content: content,
                        onDismiss: { showingSleepContentPlayer = false }
                    )
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func configureTabBarAppearance(isOLED: Bool) {
        let appearance = UITabBarAppearance()
        let accent = UIColor(DesignTokens.accent)
        let surface = UIColor(DesignTokens.surface)

        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = surface

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray.withAlphaComponent(0.6)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = accent
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accent
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Placeholder Views

struct SoundsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                String(localized: "Sound Library"),
                systemImage: "waveform",
                description: Text("Browse ambient sounds here")
            )
            .navigationTitle(LocalizedStringKey("Sounds"))
        }
    }
}

struct MixerPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                String(localized: "Sound Mixer"),
                systemImage: "slider.horizontal.3",
                description: Text("Mix sounds and adjust volumes")
            )
            .navigationTitle(LocalizedStringKey("Mixer"))
        }
    }
}

struct TimerPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                String(localized: "Sleep Timer"),
                systemImage: "moon.zzz",
                description: Text("Set a timer to stop playback")
            )
            .navigationTitle(LocalizedStringKey("Timer"))
        }
    }
}

struct FavoritesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                String(localized: "Favorites"),
                systemImage: "heart",
                description: Text("Your favorite sounds")
            )
            .navigationTitle(LocalizedStringKey("Favorites"))
        }
    }
}

struct SavedMixesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                String(localized: "Saved Mixes"),
                systemImage: "folder",
                description: Text("Your saved sound combinations")
            )
            .navigationTitle(LocalizedStringKey("Saved Mixes"))
        }
    }
}

#Preview {
    @Previewable @State var audioEngine = AudioEngine()
    @Previewable @State var onboardingService = OnboardingService()
    ContentView()
        .environment(audioEngine)
        .environment(SleepTimerService(audioEngine: audioEngine))
        .environment(FavoritesService())
        .environment(SavedMixesService())
        .environment(StoryProgressService())
        .environment(BinauralBeatEngine())
        .environment(SleepRecordingService())
        .environment(AdaptiveSessionService(audioEngine: audioEngine))
        .environment(InsightsService())
        .environment(AnalyticsService())
        .environment(ReviewPromptService())
        .environment(AppearanceService())
        .environment(onboardingService)
        .preferredColorScheme(.dark)
}
