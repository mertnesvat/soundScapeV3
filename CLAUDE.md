# SoundScape - Claude Code Context

## Project Overview

SoundScape is an iOS wellness audio app that helps users create personalized ambient soundscapes for sleep, relaxation, focus, and meditation. Users can mix multiple sounds together, adjust individual volumes, save favorite combinations, and set sleep timers.

## Tech Stack

- **Platform**: iOS 17.0+, iPhone only
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Architecture**: Clean Architecture (Domain, Data, Presentation layers)
- **State Management**: @Observable, @Environment
- **Audio**: AVFoundation, AVAudioEngine (for binaural beats)
- **Persistence**: UserDefaults, JSON files
- **Build System**: Xcode project (not SPM)

## Project Structure

```
SoundScape/
├── SoundScape.xcodeproj/
├── Sources/
│   ├── App/
│   │   ├── SoundScapeApp.swift      # App entry point, service initialization
│   │   └── ContentView.swift         # Main tab view (8 tabs)
│   ├── Domain/
│   │   ├── Entities/                 # Sound, ActiveSound, Alarm, Story, etc.
│   │   ├── Protocols/                # AudioPlayerProtocol
│   │   └── Repositories/             # SoundRepositoryProtocol
│   ├── Data/
│   │   ├── DataSources/              # LocalSoundDataSource, LocalStoryDataSource
│   │   ├── Repositories/             # SoundRepository
│   │   └── Services/                 # AudioEngine, SleepTimerService, InsightsService, etc.
│   └── Presentation/
│       ├── Sounds/                   # Main sound library view
│       ├── Mixer/                    # Active sounds mixing (sheet modal)
│       ├── Timer/                    # Sleep timer (sheet modal)
│       ├── SavedMixes/               # Saved combinations (sheet modal)
│       ├── Favorites/                # Favorited sounds
│       ├── BinauralBeats/            # Brainwave entrainment
│       ├── Stories/                  # Sleep stories
│       ├── Alarms/                   # Smart wake-up alarms
│       ├── Discover/                 # Community mixes
│       ├── Adaptive/                 # Context-aware soundscapes
│       ├── Insights/                 # Sleep analytics
│       └── Components/               # Shared UI (NowPlayingBarView)
└── Resources/
    ├── Sounds/                       # 27 MP3 audio files
    ├── Assets.xcassets/
    ├── Info.plist
    └── GoogleService-Info.plist
```

## Key Services

| Service | Purpose |
|---------|---------|
| `AudioEngine` | Multi-sound playback, volume control, session tracking |
| `SleepTimerService` | Countdown timer with fade-out |
| `InsightsService` | Usage analytics, session recording |
| `FavoritesService` | Persist favorite sounds |
| `SavedMixesService` | Save/load sound combinations |
| `BinauralBeatEngine` | Generate binaural/isochronic tones |
| `AlarmService` | Schedule wake-up alarms |
| `AdaptiveSessionService` | Context-aware sound transitions |

## Sound Categories

| Category | Color | Sounds |
|----------|-------|--------|
| Noise | Purple | White Noise, Pink Noise, Brown Noise, Deep Brown Noise |
| Nature | Green | Morning Birds, Winter Forest, Serene Morning, Spring Birds, Meadow, Night Wildlife, Calm Ocean |
| Weather | Blue | Rain Storm, Wind Ambient, Rainforest, Thunder, Heavy Thunder, Castle Wind |
| Fire | Orange | Campfire, Bonfire |
| Music | Pink | Creative Mind, Midnight Calm, Ocean Lullaby, Deep Focus Flow, Starlit Sky, Forest Sanctuary, Cinematic Piano, Ambient Melody |

## Tab Structure (8 tabs)

1. **Sounds** - Main library with Mixer/Timer/Saved as toolbar sheet modals
2. **Binaural** - Brainwave entrainment tones
3. **Favorites** - Bookmarked sounds
4. **Stories** - Narrated sleep stories
5. **Alarms** - Smart wake-up alarms
6. **Discover** - Community-curated mixes
7. **Adaptive** - Context-aware soundscapes
8. **Insights** - Sleep analytics dashboard

## Build Commands

```bash
# Build
cd SoundScape && xcodebuild -scheme SoundScape -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run in simulator
xcrun simctl install "iPhone 17 Pro" build/Build/Products/Debug-iphonesimulator/SoundScape.app
xcrun simctl launch "iPhone 17 Pro" com.StudioNext.SoundScape
```

## Adding New Sounds

1. Add MP3 file to `Resources/Sounds/`
2. Add entry to `LocalSoundDataSource.swift` with id, name, category, fileName
3. Add file reference to `SoundScape.xcodeproj/project.pbxproj`:
   - PBXBuildFile section
   - PBXFileReference section
   - Sounds group children
   - PBXResourcesBuildPhase files
4. Update `SoundCardView.swift` and `MixerSoundRowView.swift` if new category

## Key Patterns

- Services are `@Observable` classes injected via `.environment()`
- Views access services via `@Environment(ServiceName.self)`
- Sound playback is managed by `AudioEngine.activeSounds`
- Sessions recorded to `InsightsService` when timer ends or sounds stop
