import SwiftUI

struct ContentView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SleepTimerService.self) private var sleepTimerService
    @State private var selectedTab: Tab = .sounds

    enum Tab: String, CaseIterable {
        case sounds = "Sounds"
        case mixer = "Mixer"
        case binaural = "Binaural"
        case timer = "Timer"
        case favorites = "Favorites"
        case saved = "Saved"
        case stories = "Stories"
        case alarms = "Alarms"
        case discover = "Discover"
        case adaptive = "Adaptive"

        var icon: String {
            switch self {
            case .sounds: return "waveform"
            case .mixer: return "slider.horizontal.3"
            case .binaural: return "brain.head.profile"
            case .timer: return "moon.zzz"
            case .favorites: return "heart"
            case .saved: return "folder"
            case .stories: return "book.fill"
            case .alarms: return "alarm"
            case .discover: return "globe"
            case .adaptive: return "waveform.path.ecg"
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

                MixerView()
                    .tabItem {
                        Label(Tab.mixer.rawValue, systemImage: Tab.mixer.icon)
                    }
                    .tag(Tab.mixer)

                BinauralBeatsView()
                    .tabItem {
                        Label(Tab.binaural.rawValue, systemImage: Tab.binaural.icon)
                    }
                    .tag(Tab.binaural)

                SleepTimerView()
                    .tabItem {
                        Label(Tab.timer.rawValue, systemImage: Tab.timer.icon)
                    }
                    .tag(Tab.timer)

                FavoritesView()
                    .tabItem {
                        Label(Tab.favorites.rawValue, systemImage: Tab.favorites.icon)
                    }
                    .tag(Tab.favorites)

                SavedMixesView()
                    .tabItem {
                        Label(Tab.saved.rawValue, systemImage: Tab.saved.icon)
                    }
                    .tag(Tab.saved)

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
        .preferredColorScheme(.dark)
}
