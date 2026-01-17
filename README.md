# SoundScape

A wellness audio app for iOS that helps users create personalized ambient soundscapes for sleep, relaxation, focus, and meditation.

## Features

### Core Features
- **Sound Library** - 27 ambient sounds across 5 categories (Noise, Nature, Weather, Fire, Music)
- **Sound Mixing** - Play multiple sounds simultaneously with individual volume control
- **Sleep Timer** - Automatic fade-out timer with preset durations
- **Favorites** - Quick access to preferred sounds
- **Saved Mixes** - Save and recall favorite sound combinations

### Advanced Features
- **Binaural Beats** - Brainwave entrainment with Delta, Theta, Alpha, Beta, Gamma frequencies
- **Sleep Stories** - Narrated audio stories for falling asleep
- **Smart Alarms** - Wake-up alarms with gradual volume increase
- **Community Discover** - Browse and share sound mixes with other users
- **Adaptive Soundscapes** - Context-aware sounds that evolve automatically
- **Sleep Insights** - Analytics dashboard tracking sleep patterns and sound usage

## Screenshots

| Sounds | Mixer | Insights |
|--------|-------|----------|
| Browse and play ambient sounds | Mix multiple sounds with volume control | Track your sleep analytics |

## Tech Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.0
- **UI**: SwiftUI
- **Architecture**: Clean Architecture
- **Audio**: AVFoundation, AVAudioEngine

## Project Structure

```
SoundScape/
├── Sources/
│   ├── App/              # Entry point, main navigation
│   ├── Domain/           # Entities, protocols, use cases
│   ├── Data/             # Services, repositories, data sources
│   └── Presentation/     # Views, view models
└── Resources/
    ├── Sounds/           # 27 MP3 audio files
    └── Assets.xcassets/  # App icons, colors
```

## Sound Categories

| Category | Count | Examples |
|----------|-------|----------|
| Noise | 4 | White Noise, Pink Noise, Brown Noise |
| Nature | 7 | Morning Birds, Spring Birds, Meadow, Night Wildlife |
| Weather | 6 | Rain Storm, Thunder, Rainforest, Castle Wind |
| Fire | 2 | Campfire, Bonfire |
| Music | 8 | Creative Mind, Midnight Calm, Starlit Sky |

## Building

### Requirements
- Xcode 15.0+
- iOS 17.0+ Simulator or Device

### Build & Run

```bash
cd SoundScape
xcodebuild -scheme SoundScape -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Run in Simulator

```bash
xcrun simctl install "iPhone 17 Pro" build/Build/Products/Debug-iphonesimulator/SoundScape.app
xcrun simctl launch "iPhone 17 Pro" com.StudioNext.SoundScape
```

## Architecture

The app follows Clean Architecture with three layers:

- **Domain Layer**: Core business logic, entities, and protocols
- **Data Layer**: Services, repositories, and data sources
- **Presentation Layer**: SwiftUI views and view models

### Key Services

| Service | Purpose |
|---------|---------|
| AudioEngine | Multi-sound playback and volume control |
| SleepTimerService | Countdown timer with audio fade-out |
| InsightsService | Usage analytics and session recording |
| BinauralBeatEngine | Real-time tone generation |

## Recent Updates

### v1.1 - UI Refinements & Content Expansion

**Navigation Improvements**
- Consolidated Mixer, Timer, and Saved into Sounds toolbar (reduced tabs from 11 to 8)
- Cleaner tab bar with focused navigation

**Real Data Tracking**
- Insights now tracks actual usage data
- Sessions recorded when sleep timer ends or sounds stop

**New Content**
- Added Music category with 8 calming tracks
- Added 10 new ambient sounds (nature, weather, music)
- Total library expanded from 11 to 27 sounds

## License

Copyright 2024 StudioNext. All rights reserved.
