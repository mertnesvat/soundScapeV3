import SwiftUI

struct ContentView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SleepTimerService.self) private var sleepTimerService
    @State private var selectedTab: Tab = .sounds

    enum Tab: String, CaseIterable {
        case sounds = "Sounds"
        case binaural = "Binaural"
        case favorites = "Favorites"
        case stories = "Stories"
        case alarms = "Alarms"
        case discover = "Discover"
        case adaptive = "Adaptive"
        case insights = "Insights"

        var icon: String {
            switch self {
            case .sounds: return "waveform"
            case .binaural: return "brain.head.profile"
            case .favorites: return "heart"
            case .stories: return "book.fill"
            case .alarms: return "alarm"
            case .discover: return "globe"
            case .adaptive: return "waveform.path.ecg"
            case .insights: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                SoundsView()
                    .tabItem {
                        Label(Tab.sounds.rawValue, systemImage: Tab.sounds.icon)
                    }
                    .tag(Tab.sounds)

                BinauralBeatsView()
                    .tabItem {
                        Label(Tab.binaural.rawValue, systemImage: Tab.binaural.icon)
                    }
                    .tag(Tab.binaural)

                FavoritesView()
                    .tabItem {
                        Label(Tab.favorites.rawValue, systemImage: Tab.favorites.icon)
                    }
                    .tag(Tab.favorites)

                StoriesView()
                    .tabItem {
                        Label(Tab.stories.rawValue, systemImage: Tab.stories.icon)
                    }
                    .tag(Tab.stories)

                AlarmsView()
                    .tabItem {
                        Label(Tab.alarms.rawValue, systemImage: Tab.alarms.icon)
                    }
                    .tag(Tab.alarms)

                DiscoverView()
                    .tabItem {
                        Label(Tab.discover.rawValue, systemImage: Tab.discover.icon)
                    }
                    .tag(Tab.discover)

                AdaptiveView()
                    .tabItem {
                        Label(Tab.adaptive.rawValue, systemImage: Tab.adaptive.icon)
                    }
                    .tag(Tab.adaptive)

                InsightsView()
                    .tabItem {
                        Label(Tab.insights.rawValue, systemImage: Tab.insights.icon)
                    }
                    .tag(Tab.insights)
            }
            .tint(.purple)

            // Now Playing Bar above tab bar
            VStack {
                Spacer()
                NowPlayingBarView()
                    .padding(.bottom, 49) // Tab bar height
            }
            .animation(.spring(response: 0.3), value: audioEngine.activeSounds.isEmpty)
        }
    }
}

// MARK: - Placeholder Views

struct SoundsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Sound Library",
                systemImage: "waveform",
                description: Text("Browse ambient sounds here")
            )
            .navigationTitle("Sounds")
        }
    }
}

struct MixerPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Sound Mixer",
                systemImage: "slider.horizontal.3",
                description: Text("Mix sounds and adjust volumes")
            )
            .navigationTitle("Mixer")
        }
    }
}

struct TimerPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Sleep Timer",
                systemImage: "moon.zzz",
                description: Text("Set a timer to stop playback")
            )
            .navigationTitle("Timer")
        }
    }
}

struct FavoritesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Favorites",
                systemImage: "heart",
                description: Text("Your favorite sounds")
            )
            .navigationTitle("Favorites")
        }
    }
}

struct SavedMixesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Saved Mixes",
                systemImage: "folder",
                description: Text("Your saved sound combinations")
            )
            .navigationTitle("Saved Mixes")
        }
    }
}

#Preview {
    let audioEngine = AudioEngine()
    return ContentView()
        .environment(audioEngine)
        .environment(SleepTimerService(audioEngine: audioEngine))
        .environment(FavoritesService())
        .environment(SavedMixesService())
        .environment(StoryProgressService())
        .environment(BinauralBeatEngine())
        .environment(AlarmService())
        .environment(AdaptiveSessionService(audioEngine: audioEngine))
        .environment(InsightsService())
        .preferredColorScheme(.dark)
}
