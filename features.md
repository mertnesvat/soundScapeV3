---
base_branch: main
max_retries: 2
continue_on_failure: true
visual_gate_enabled: true
visual_gate_threshold: 0.7
bundle_id: com.goat.SoundScape
action_logging: true
---

# Feature Queue: SoundScape Refinements

### 1. Sounds Top Bar Navigation Refinement

Consolidate sound-related features into the Sounds view by adding toolbar buttons that open Mixer, Timer, and Saved as sheet modals. This reduces tab bar clutter by grouping related functionality together.

**User Story:** As a user, I want quick access to Mixer, Timer, and Saved from the Sounds screen so I can manage my audio experience without switching tabs.

**Acceptance Criteria:**
- User sees three toolbar icons in Sounds view top bar (mixer slider, timer/moon, folder icons)
- Tapping Mixer icon opens MixerView as a sheet modal
- Tapping Timer icon opens SleepTimerView as a sheet modal
- Tapping Saved icon opens SavedMixesView as a sheet modal
- Mixer, Timer, and Saved tabs are removed from the main tab bar
- Tab bar now has fewer tabs: Sounds, Binaural, Favorites, Stories, Alarms, Discover, Adaptive, Insights (8 tabs instead of 11)
- All existing functionality of Mixer, Timer, Saved works correctly in sheet presentation

**Priority:** 1
**Dependencies:** None

---

### 2. Fix Insights Real Data Binding

The Insights view currently only shows mock data because `recordSession()` is never called. Bind real usage data so Insights reflects actual user listening behavior.

**User Story:** As a user, I want to see my actual listening statistics in Insights so I can track my sleep and sound usage patterns over time.

**Acceptance Criteria:**
- When sleep timer completes, a session is recorded with duration and sounds that were playing
- When user manually stops all sounds after playing for more than 1 minute, a session is recorded
- Insights view shows real weekly sleep chart data based on recorded sessions
- Average duration, quality, and time-to-sleep metrics reflect actual usage
- Top sounds section shows the user's actual most-played sounds
- Total sessions and total sleep time counters are accurate
- Recommendations are based on real usage patterns

**Priority:** 2
**Dependencies:** None

---

### 3. Add Calm Music Category

Add new calming music tracks as a new "Music" category in the Sounds view. These are longer, melodic tracks for relaxation.

**User Story:** As a user, I want access to calming music tracks alongside ambient sounds so I have more variety for relaxation and sleep.

**Acceptance Criteria:**
- New "Music" category appears in the Sounds view category filter
- Music category has a distinct color (e.g., pink or teal)
- The following tracks are available in the Music category:
  - Creative Mind
  - Midnight Calm
  - Ocean Lullaby
  - Deep Focus Flow
  - Starlit Sky
  - Forest Sanctuary
- Each track can be played, mixed with other sounds, and added to favorites
- Audio files are properly bundled from new_content/calm_music folder
- Duplicate files are handled (use best quality version of each track)

**Priority:** 3
**Dependencies:** None

---

### 4. Add New Background Sounds

Expand the existing sound library with additional ambient sounds from the new_content/more_backgroundSound folder. These add variety to Nature, Weather, and other categories.

**User Story:** As a user, I want more variety in ambient sounds so I can create more diverse and personalized soundscapes.

**Acceptance Criteria:**
- New sounds are added to appropriate existing categories:
  - Nature: Spring Birds, Meadow, Night Wildlife
  - Weather: Rainforest, Thunder, Heavy Thunder, Castle Wind
  - Ocean (new category or extend Nature): Calm Ocean
  - Music: Cinematic Piano, Ambient Melody
- Each new sound has appropriate metadata (name, category, icon)
- All new sounds work with mixer, favorites, and saved mixes features
- Audio files are properly bundled from new_content/more_backgroundSound folder
- Sound names are user-friendly (cleaned up from filename format)

**Priority:** 3
**Dependencies:** Feature 3 (shares Music category)

---

## New Content Files Reference

### calm_music folder:
| File | Display Name |
|------|-------------|
| Creative Mind.mp3 | Creative Mind |
| Midnight Calm.mp3 | Midnight Calm |
| Ocean Lullaby.mp3 | Ocean Lullaby |
| Deep Focus Flow.mp3 | Deep Focus Flow |
| Starlit Sky.mp3 | Starlit Sky |
| Forest Sanctuary.mp3 | Forest Sanctuary |

### more_backgroundSound folder:
| File | Display Name | Category |
|------|-------------|----------|
| 353156__tri-tachyon__soundscape-last-31-cinematic-piano.mp3 | Cinematic Piano | Music |
| 457447__innorecords__rain-sound-and-rainforest.mp3 | Rainforest | Weather |
| 527664__straget__thunder.mp3 | Thunder | Weather |
| 483479__astounded__wind_blowing_gusting_through_french_castle_tower.mp3 | Castle Wind | Weather |
| 53380__eric5335__meadow-ambience.mp3 | Meadow | Nature |
| 446753__bluedelta__heavy-thunder-strike-no-rain-quadro.mp3 | Heavy Thunder | Weather |
| 352514__inspectorj__ambience-night-wildlife-a.mp3 | Night Wildlife | Nature |
| 345852__hargissssound__spring-birds-loop-with-low-cut-new-jersey.mp3 | Spring Birds | Nature |
| 578524__samsterbirdies__calm-ocean-waves.mp3 | Calm Ocean | Nature |
| 341541__patricklieberkind__beautiful-ambient-melody.mp3 | Ambient Melody | Music |

**Skip these files:**
- 345851__hargissssound__spring-birds-raw-new-jersey.mp3 (use loop version instead)
- 639585__xkeril__the-story-youre-about-to-hear.mp3 (intro/story clip, not ambient)
- Duplicate Midnight Calm files (1)-(5) - use original only
- Duplicate Creative Mind (1), Ocean Lullaby (1), Starlit Sky (1), Forest Sanctuary (1) - use originals only
