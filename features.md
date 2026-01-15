# SoundScape Rebuild - Feature Queue

---
base_branch: main
max_retries: 2
continue_on_failure: true
bundle_identifier: com.StudioNext.SoundScape
firebase_project: next-soundscape
platform: iOS only (iPhone)
---

## Project Context

SoundScape is a wellness audio app that helps users create personalized ambient soundscapes for:
- Sleep & Relaxation
- Study & Focus
- Baby White Noise
- Meditation
- Work Environments

Users mix multiple sounds together, adjust individual volumes, save favorite combinations, and set sleep timers.

### Assets Available

All content files are in `rebuild-assets/`:
- **Sounds/** - 11 ambient sound files (white_noise, pink_noise, brown_noise, brown_noise_deep, morning_birds, winter_forest, serene_morning, rain_storm, wind_ambient, campfire, bonfire)
- **Firebase/** - GoogleService-Info.plist (project: next-soundscape)
- **AppIcon/** - App icon assets

### Sound Categories
| Category | Sounds |
|----------|--------|
| Noise | White Noise, Pink Noise, Brown Noise, Deep Brown Noise |
| Nature | Morning Birds, Winter Forest, Serene Morning |
| Weather | Rain Storm, Wind Ambient |
| Fire | Campfire, Bonfire |

### Design Guidelines
- Dark Mode Primary (app used at bedtime)
- Large Touch Targets (easy to tap when drowsy)
- Minimal Visual Noise (calming interface)
- Persistent Playback (now playing bar always accessible)
- Smooth Animations (gentle transitions)

---

## Features

### 1. Project Foundation
**Priority:** 1
**Dependencies:** none

Set up the iOS project structure with Swift Package Manager:
- Create SoundScape Xcode project with bundle ID `com.StudioNext.SoundScape`
- Configure SPM package structure following Clean Architecture
- Set up folder structure: Domain, Data, Presentation layers
- Copy assets from `rebuild-assets/` (Sounds, Firebase config, AppIcon)
- Configure Info.plist for background audio playback
- Set deployment target iOS 17.0, iPhone only

---

### 2. Sound Library
**Priority:** 2
**Dependencies:** Project Foundation

The main screen where users browse and play ambient sounds (Sounds Tab / Home).

**Requirements:**
- Grid layout of all available sounds
- Sounds organized by category (Noise, Nature, Weather, Fire)
- Category filter tabs at the top
- Play/pause button on each sound card
- Visual indicator when a sound is playing
- Sound loops continuously in background
- Dark theme UI with calming aesthetics

**Domain Layer:**
- Sound entity (id, name, category, fileName, isFavorite)
- SoundCategory enum
- SoundRepositoryProtocol

**Data Layer:**
- Local sound data source loading from bundled MP3 files
- Sound repository implementation

**Presentation Layer:**
- SoundsView (main tab view)
- SoundCardView (individual sound tile)
- CategoryFilterView (horizontal filter tabs)
- SoundsViewModel

---

### 3. Audio Engine
**Priority:** 3
**Dependencies:** Sound Library

Core audio playback engine supporting multiple simultaneous sounds.

**Requirements:**
- Play/pause individual sounds
- Multiple sounds playing simultaneously (mixing)
- Individual volume control per sound (0-100%)
- Background audio playback (app backgrounded)
- Looping audio playback
- Smooth audio transitions

**Domain Layer:**
- AudioPlayerProtocol
- PlaybackState entity
- ActiveSound entity (sound, volume, isPlaying)

**Data Layer:**
- AVFoundation-based audio player implementation
- Audio session configuration for background playback

**Presentation Layer:**
- Integration with SoundsViewModel for play/pause actions

---

### 4. Sound Mixer
**Priority:** 4
**Dependencies:** Audio Engine

View for controlling currently playing sounds with volume sliders.

**Requirements:**
- List of currently playing sounds
- Volume slider (0-100%) for each active sound
- Sound name and category label
- Remove button to stop individual sounds
- Total count of active sounds
- Accessible from Now Playing bar

**Domain Layer:**
- MixerState entity
- GetActiveSoundsUseCase

**Presentation Layer:**
- MixerView (modal/sheet)
- MixerSoundRowView (sound with volume slider)
- MixerViewModel

---

### 5. Now Playing Bar
**Priority:** 5
**Dependencies:** Sound Mixer

Persistent mini-player bar showing playback status.

**Requirements:**
- Shows at bottom of screen when sounds are playing
- Displays count of active sounds
- Play/Pause all button
- Timer button (navigates to timer)
- Tap to expand to full Mixer view
- Animates in/out based on playback state

**Presentation Layer:**
- NowPlayingBarView
- Integration with main tab view

---

### 6. Sleep Timer
**Priority:** 6
**Dependencies:** Now Playing Bar

Automatic shutdown timer with gradual fade-out.

**Requirements:**
- Preset duration buttons: 5, 15, 30, 45 min, 1h, 1.5h, 2h
- Countdown display showing remaining time (MM:SS)
- Cancel button to stop timer
- Timer icon in Now Playing bar shows active state
- When timer ends, volume gradually fades out over ~30 seconds
- All sounds stop after fade completes

**Domain Layer:**
- SleepTimer entity (duration, remainingTime, isActive)
- SleepTimerRepositoryProtocol

**Data Layer:**
- Timer implementation with fade-out logic

**Presentation Layer:**
- SleepTimerView (sheet/modal)
- TimerButtonView (preset buttons)
- Integration with NowPlayingBarView

---

### 7. Favorites
**Priority:** 7
**Dependencies:** Sound Library

Quick access to preferred individual sounds.

**Requirements:**
- Heart icon on each sound card
- Favorites section at top of sound library (when favorites exist)
- Filled heart for favorited sounds
- Tap heart to toggle favorite status
- Persist favorites locally

**Domain Layer:**
- ToggleFavoriteUseCase
- GetFavoriteSoundsUseCase

**Data Layer:**
- UserDefaults or JSON file persistence for favorites

**Presentation Layer:**
- Update SoundCardView with favorite heart icon
- FavoritesSection in SoundsView

---

### 8. Saved Mixes
**Priority:** 8
**Dependencies:** Sound Mixer, Favorites

Save and recall favorite sound combinations.

**Requirements:**
- Save current mix with custom name
- List of saved mixes showing name, sounds, creation date
- Play button to instantly load a mix
- Edit and delete options (swipe actions)
- Empty state with prompt to save first mix
- Persist mixes locally

**Domain Layer:**
- Mix entity (id, name, sounds with volumes, createdAt)
- MixRepositoryProtocol
- SaveMixUseCase
- LoadMixUseCase
- DeleteMixUseCase

**Data Layer:**
- JSON file persistence for saved mixes

**Presentation Layer:**
- SavedMixesView (list view)
- SavedMixRowView
- SaveMixSheet (name input)
- SavedMixesViewModel

---

## Post-MVP Features

### 9. Sleep Stories
**Priority:** 9
**Dependencies:** Audio Engine

Narrated audio stories designed to help users fall asleep (Stories Tab).

**Requirements:**
- Featured stories banner at top
- Story cards with cover art, title, duration
- Category filters: Fiction, Nature Journeys, Meditation, ASMR
- Narrator filter (different voice types)
- Duration filter: 10, 20, 30, 45 minutes
- Search bar
- Continue listening section for in-progress stories
- Story player with optional background soundscape mixing
- Progress saved if user stops mid-story

**Story card shows:**
- Cover artwork
- Story title
- Narrator name
- Duration
- Progress bar (if started)

**Firebase Integration:**
- Fetch stories from Firestore `stories` collection
- Fetch narrators from Firestore `narrators` collection
- Stream audio from Firebase Storage

**Domain Layer:**
- Story entity (id, title, narrator, duration, category, coverUrl, audioUrl, progress)
- Narrator entity (id, name, voiceType, avatarUrl)
- StoryCategory enum
- StoryRepositoryProtocol
- NarratorRepositoryProtocol

**Data Layer:**
- Firebase Firestore data source for stories/narrators
- Firebase Storage for audio streaming
- Local persistence for progress tracking

**Presentation Layer:**
- StoriesView (tab view with filters)
- StoryCardView
- StoryPlayerView
- StoriesViewModel

---

### 10. Binaural Beats
**Priority:** 10
**Dependencies:** Audio Engine

Brainwave entrainment audio for different mental states.

**Requirements:**
- Brainwave state selector:
  - Delta (Deep Sleep) - 2Hz
  - Theta (Meditation) - 6Hz
  - Alpha (Relaxation) - 10Hz
  - Beta (Focus) - 20Hz
  - Gamma (Creativity) - 40Hz
- Tone type toggle: Binaural vs Isochronic
- Intensity slider
- Headphone required notice (for binaural)
- Solfeggio frequency options (528Hz, 432Hz, etc.)
- Can be mixed with other ambient sounds

**Domain Layer:**
- BrainwaveState enum (delta, theta, alpha, beta, gamma)
- ToneType enum (binaural, isochronic)
- BinauralBeat entity (state, toneType, intensity, baseFrequency)
- BinauralPlayerProtocol

**Data Layer:**
- AVAudioEngine-based tone generator for binaural beats
- Real-time audio synthesis

**Presentation Layer:**
- BinauralBeatsView (dedicated section or integrated)
- BrainwaveStateSelector
- FrequencySliderView
- BinauralBeatsViewModel

---

### 11. Smart Alarms
**Priority:** 11
**Dependencies:** Audio Engine

Wake-up alarms with gradual volume and smart timing (Alarms Tab).

**Requirements:**
- List of configured alarms
- Add alarm button
- Each alarm shows: time, repeat days, enabled toggle
- Alarm detail screen with:
  - Time picker
  - Repeat days selector (M T W T F S S)
  - Alarm sound picker (nature sounds: birds, sunrise, ocean, etc.)
  - Volume ramp duration (wake gradually over 5-30 min)
  - Smart alarm toggle (wake during light sleep within window)
  - Snooze duration setting
- Local notifications for alarm triggers
- Gradual volume increase

**Domain Layer:**
- Alarm entity (id, time, repeatDays, soundId, volumeRampMinutes, smartAlarmEnabled, smartAlarmWindow, snoozeMinutes, isEnabled)
- AlarmRepositoryProtocol
- ScheduleAlarmUseCase
- TriggerAlarmUseCase

**Data Layer:**
- Local persistence for alarms (JSON/UserDefaults)
- UNUserNotificationCenter for scheduling
- Background audio for alarm playback

**Presentation Layer:**
- AlarmsView (tab view with alarm list)
- AlarmRowView
- AlarmDetailView
- AlarmsViewModel

---

### 12. Community Discover
**Priority:** 12
**Dependencies:** Saved Mixes

Browse and share sound mixes with other users (Discover Tab).

**Requirements:**
- Featured mix of the week/month
- Category sections: Trending, New, Popular, Sleep, Focus, Nature
- Mix cards showing:
  - Mix name
  - Creator name/avatar
  - Sound count
  - Play count, upvotes, saves
  - Tags
- Search and filter options
- Share your own mix button
- Preview mix before saving
- Upvote system to help others find good mixes
- Share code for direct sharing

**Firebase Integration:**
- Firestore collection for community mixes
- User profiles for creators
- Analytics for play counts, upvotes

**Domain Layer:**
- CommunityMix entity (id, name, creatorId, creatorName, sounds, playCount, upvotes, saves, tags, createdAt)
- CommunityRepositoryProtocol
- FetchTrendingMixesUseCase
- ShareMixUseCase
- UpvoteMixUseCase

**Data Layer:**
- Firebase Firestore for community mixes
- Cloud Functions for trending algorithms (optional)

**Presentation Layer:**
- DiscoverView (tab view)
- CommunityMixCardView
- ShareMixSheet
- DiscoverViewModel

---

### 13. Adaptive Soundscapes
**Priority:** 13
**Dependencies:** Audio Engine, Sleep Timer

Context-aware soundscapes that evolve automatically (Adaptive Tab).

**Requirements:**
- Preset adaptive modes:
  - Sleep Cycle (sounds change through night phases)
  - Day & Night (follows time of day)
  - Weather Sync (matches local weather via API)
  - Heart Rate Calming (responds to HealthKit HR data)
- Custom trigger configuration
- Evolution pattern selector
- Preview of how sounds will change
- Smooth transitions between sound phases

**Domain Layer:**
- AdaptiveMode enum (sleepCycle, dayNight, weatherSync, heartRate)
- AdaptiveSession entity (mode, phases, currentPhase, triggers)
- SoundPhase entity (sounds, duration, transitionStyle)
- AdaptiveRepositoryProtocol
- WeatherServiceProtocol
- HealthKitServiceProtocol

**Data Layer:**
- Weather API integration (OpenWeatherMap or similar)
- HealthKit integration for heart rate
- Timer-based phase transitions

**Presentation Layer:**
- AdaptiveView (tab view)
- AdaptiveModeCardView
- PhasePreviewView
- AdaptiveViewModel

---

### 14. Sleep Insights
**Priority:** 14
**Dependencies:** Audio Engine, Saved Mixes

Analytics and recommendations based on sleep data (Insights Tab).

**Requirements:**
- Sleep duration chart (weekly/monthly views)
- Sleep quality score
- Time to fall asleep average
- Deep sleep percentage (if available from HealthKit)
- Best performing sounds (correlation analysis)
- Personalized recommendations based on usage patterns
- Sleep goals and progress tracking
- Export data option

**HealthKit Integration:**
- Request sleep analysis access
- Read sleep samples (inBed, asleep, awake stages)
- Correlate with app usage data

**Domain Layer:**
- SleepSession entity (date, duration, quality, soundsUsed, timeToSleep)
- SleepInsight entity (metric, value, trend, recommendation)
- InsightsRepositoryProtocol
- HealthKitSleepServiceProtocol
- AnalyzeSleepPatternsUseCase
- GenerateRecommendationsUseCase

**Data Layer:**
- HealthKit data source for sleep data
- Local persistence for app usage tracking
- Analytics engine for correlations

**Presentation Layer:**
- InsightsView (tab view)
- SleepChartView (weekly/monthly)
- InsightCardView
- RecommendationRowView
- InsightsViewModel

---
