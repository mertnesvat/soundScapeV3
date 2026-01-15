import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .sounds

    enum Tab: String, CaseIterable {
        case sounds = "Sounds"
        case mixer = "Mixer"
        case timer = "Timer"
        case favorites = "Favorites"
        case saved = "Saved"

        var icon: String {
            switch self {
            case .sounds: return "waveform"
            case .mixer: return "slider.horizontal.3"
            case .timer: return "moon.zzz"
            case .favorites: return "heart"
            case .saved: return "folder"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SoundsPlaceholderView()
                .tabItem {
                    Label(Tab.sounds.rawValue, systemImage: Tab.sounds.icon)
                }
                .tag(Tab.sounds)

            MixerPlaceholderView()
                .tabItem {
                    Label(Tab.mixer.rawValue, systemImage: Tab.mixer.icon)
                }
                .tag(Tab.mixer)

            TimerPlaceholderView()
                .tabItem {
                    Label(Tab.timer.rawValue, systemImage: Tab.timer.icon)
                }
                .tag(Tab.timer)

            FavoritesPlaceholderView()
                .tabItem {
                    Label(Tab.favorites.rawValue, systemImage: Tab.favorites.icon)
                }
                .tag(Tab.favorites)

            SavedMixesPlaceholderView()
                .tabItem {
                    Label(Tab.saved.rawValue, systemImage: Tab.saved.icon)
                }
                .tag(Tab.saved)
        }
        .tint(.purple)
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
    ContentView()
        .preferredColorScheme(.dark)
}
