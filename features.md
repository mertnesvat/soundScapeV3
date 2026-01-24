# Night Agent Feature Queue - SoundScape Enhanced UX

---
base_branch: master
max_retries: 2
continue_on_failure: true
bundle_id: com.StudioNext.SoundScape
---

## Features

### 1. True Black OLED Mode
**Priority:** 1
**Dependencies:** none

Implement a true black OLED color scheme across the entire app for maximum battery efficiency and visual elegance on OLED displays.

**Requirements:**
- Background color: #000000 (pure black) for all views
- Create a centralized Theme/Colors file with:
  - Category glow colors:
    - Noise (Purple): #A855F7 → #7C3AED gradient
    - Nature (Green): #22C55E → #16A34A gradient
    - Weather (Blue): #3B82F6 → #2563EB gradient
    - Fire (Orange): #F97316 → #EA580C gradient
    - Music (Pink): #EC4899 → #DB2777 gradient
    - ASMR (Teal): #14B8A6 → #0D9488 gradient
  - UI accents: White at 90%/60%/40% opacity levels
  - Dividers: White at 10% opacity
- Update all existing views to use pure black backgrounds
- Sound cards should have subtle glow based on their category color
- Now playing bar should use category color as accent
- Tab bar and navigation should be pure black with luminous icons
- Ensure text remains readable with proper contrast

**Files to modify:**
- Sources/Presentation/Sounds/SoundsView.swift
- Sources/Presentation/Sounds/SoundCardView.swift
- Sources/Presentation/Components/NowPlayingBarView.swift
- Sources/Presentation/Mixer/MixerView.swift
- Sources/Presentation/Mixer/MixerSoundRowView.swift
- Sources/App/ContentView.swift
- All other presentation layer views

**New files to create:**
- Sources/Presentation/Theme/AppColors.swift
- Sources/Presentation/Theme/CategoryTheme.swift

---

### 2. ASMR Triggers Library
**Priority:** 2
**Dependencies:** True Black OLED Mode

Add a new ASMR category with specialized trigger sounds for deep relaxation and ASMR enthusiasts.

**Requirements:**
- Create new ASMR sound category with teal color (#14B8A6)
- Add SoundCategory.asmr case to existing Sound entity
- Add ASMR sounds to LocalSoundDataSource (using placeholder files or existing sounds as stand-ins):
  - Page Turning - SF Symbol: book.pages
  - Soft Whispers - SF Symbol: waveform
  - Gentle Tapping - SF Symbol: hand.tap
  - Keyboard Typing - SF Symbol: keyboard
  - Writing Sounds - SF Symbol: pencil
- ASMR sounds should appear in their own section/category in SoundsView
- Each ASMR sound card should match the existing card pattern but with teal glow
- Haptic feedback on interactions:
  - Toggle On: UIImpactFeedbackGenerator(.soft)
  - Toggle Off: UIImpactFeedbackGenerator(.light)
- Add informational tip at top of ASMR section: "ASMR works best with headphones at low volume"

**Files to modify:**
- Sources/Domain/Entities/Sound.swift (add .asmr category)
- Sources/Data/DataSources/LocalSoundDataSource.swift (add ASMR sounds)
- Sources/Presentation/Sounds/SoundsView.swift (show ASMR category)
- Sources/Presentation/Sounds/SoundCardView.swift (handle ASMR styling)

**Note:** Since we don't have actual ASMR audio files, use existing ambient sounds as placeholders (e.g., map to rain or wind sounds temporarily). The infrastructure will be ready for real ASMR files later.

---

### 3. Reflective Surface Card Design
**Priority:** 3
**Dependencies:** True Black OLED Mode

Add premium reflective surface effect to sound cards using device motion for a tactile, premium feel.

**Requirements:**
- Create ReflectiveCardModifier ViewModifier using Core Motion
- Use CMMotionManager to detect device tilt
- Add subtle specular highlight overlay that moves with device orientation
- Parameters:
  - Max offset: 15pt in each direction
  - Highlight size: 30% of card width
  - Highlight opacity: 15% (subtle, not distracting)
  - Smoothing factor: 0.1 (lerp for smooth, non-jerky movement)
  - Spring animation: damping 0.8, response 0.3s
- Create a shared MotionManager @Observable class to avoid multiple CMMotionManager instances
- Apply modifier to SoundCardView and MixerSoundRowView
- Graceful fallback when motion not available (static centered highlight)
- Disable effect when device is in Low Power Mode (check ProcessInfo)
- Respect reduceMotion accessibility setting

**New files to create:**
- Sources/Presentation/Components/ReflectiveCardModifier.swift
- Sources/Data/Services/MotionManager.swift

**Files to modify:**
- Sources/Presentation/Sounds/SoundCardView.swift
- Sources/Presentation/Mixer/MixerSoundRowView.swift
- Sources/App/SoundScapeApp.swift (inject MotionManager)

---

### 4. Liquid Sound Visualization
**Priority:** 4
**Dependencies:** True Black OLED Mode

Create beautiful animated liquid visualization that represents active sounds as flowing waves.

**Requirements:**
- Create LiquidSoundView component using Canvas and TimelineView for 60fps animation
- Each active sound renders as a flowing sine wave layer
- Wave properties mapped from sound state:
  - Amplitude: mapped from volume (0.0-1.0) → wave height
  - Frequency: based on sound category (slower for calm, faster for rain)
  - Color: category glow color at 40% opacity
  - Phase: continuously animating for flow effect
- Multiple active sounds create layered waves that visually blend
- Use .plusLighter blend mode for additive color mixing
- Performance optimizations:
  - Use drawingGroup() for Metal acceleration
  - Limit to 5 visible wave layers max
  - Reduce frame rate when app backgrounded
- Integrate into NowPlayingBarView as subtle animated background
- Respect reduceMotion accessibility (show static gradient instead)
- Wave should be subtle and calming, not distracting

**New files to create:**
- Sources/Presentation/Components/LiquidSoundView.swift
- Sources/Presentation/Components/WaveLayer.swift

**Files to modify:**
- Sources/Presentation/Components/NowPlayingBarView.swift

---

### 5. Sleep Buddy Service
**Priority:** 5
**Dependencies:** none

Create the data layer for the Sleep Buddy accountability feature that lets users share sleep streaks with friends.

**Requirements:**
- Create SleepBuddy entity:
  ```swift
  struct SleepBuddy: Identifiable, Codable {
      let id: UUID
      var name: String
      var pairingCode: String
      var streak: Int
      var lastSleepDate: Date?
      var lastNudgeReceived: Date?
      var lastNudgeSent: Date?
  }
  ```
- Create SleepBuddyService (@Observable class):
  - buddies: [SleepBuddy] - list of connected buddies
  - myStreak: Int - current user's streak
  - myPairingCode: String - generated code (format: DREAM-XXXX)
  - generatePairingCode() -> String (random 4 alphanumeric chars)
  - addBuddy(name: String, code: String) - add a buddy locally
  - removeBuddy(id: UUID)
  - sendNudge(to buddyId: UUID) -> Bool (returns false if rate limited)
  - canNudge(buddyId: UUID) -> Bool (1 hour rate limit)
  - incrementStreak() - called when sleep session recorded
  - resetStreak() - called if user misses a night
- Persist buddies to JSON file in documents directory
- For MVP: This is local-only simulation (no networking)
  - Buddy data stored locally
  - "Receiving" nudges simulated with local notifications
  - Streak tracking is real based on InsightsService sessions

**New files to create:**
- Sources/Domain/Entities/SleepBuddy.swift
- Sources/Data/Services/SleepBuddyService.swift

---

### 6. Sleep Buddy UI
**Priority:** 6
**Dependencies:** Sleep Buddy Service, True Black OLED Mode

Create the presentation layer for the Sleep Buddy feature integrated into the Insights tab.

**Requirements:**
- Add "Sleep Buddies" section to InsightsView (below existing stats)
- Create SleepBuddiesSection view:
  - Header: "Sleep Buddies" with person.2 SF Symbol
  - Show user's current streak prominently
  - List of connected buddies
  - "+ Add Sleep Buddy" button at bottom
- Create SleepBuddyRowView:
  - Circle avatar with first letter of name
  - Buddy name
  - Fire emoji + streak count (🔥 12)
  - Status text: "Sleeping now 💤" or "Last night at 11:23 PM"
  - "Nudge" button (SF Symbol: hand.wave)
- Create AddBuddySheet (presented as sheet):
  - Display user's pairing code in large text
  - Copy and Share buttons for the code
  - Divider with "or"
  - Text field to enter friend's code
  - Name field for the buddy
  - "Connect" button
  - Note: "Codes expire in 24 hours"
- Nudge interaction:
  - Haptic: UIImpactFeedbackGenerator(.medium)
  - Toast/overlay: "[Name] will feel a gentle nudge 💫"
  - Button disabled for 1 hour after nudging
- Use warm, supportive copy throughout
- Apply OLED theme styling

**New files to create:**
- Sources/Presentation/Insights/SleepBuddiesSection.swift
- Sources/Presentation/Insights/SleepBuddyRowView.swift
- Sources/Presentation/Insights/AddBuddySheet.swift

**Files to modify:**
- Sources/Presentation/Insights/InsightsView.swift
- Sources/App/SoundScapeApp.swift (add SleepBuddyService to environment)

---

### 7. Siri App Intents - Basic
**Priority:** 7
**Dependencies:** none

Implement basic Siri voice control using the App Intents framework for hands-free sound control in the dark.

**Requirements:**
- Create App Intents for core functionality:
  1. PlaySavedMixIntent
     - Phrases: "Play my [mix name] mix", "Start [mix name]"
     - Parameter: mix name (String)
     - Action: Find saved mix by name, play via AudioEngine
  2. StopSoundsIntent
     - Phrases: "Stop the sounds", "Pause SoundScape", "Stop playing"
     - Action: Stop all sounds via AudioEngine
  3. SetSleepTimerIntent
     - Phrases: "Set sleep timer for [duration]", "Fade out in [duration]"
     - Parameter: duration in minutes
     - Action: Set timer via SleepTimerService
  4. PlaySoundIntent
     - Phrases: "Play rain sounds", "Start [sound name]"
     - Parameter: sound name (String)
     - Action: Find sound by name, add to mix
- Create AppShortcutsProvider to register phrases
- Create SoundAppEntity conforming to AppEntity for sound lookup
- Handle errors gracefully: "I couldn't find a mix called [name]"
- Ensure intents work when app is in background

**New files to create:**
- Sources/Intents/PlaySavedMixIntent.swift
- Sources/Intents/StopSoundsIntent.swift
- Sources/Intents/SetSleepTimerIntent.swift
- Sources/Intents/PlaySoundIntent.swift
- Sources/Intents/SoundAppEntity.swift
- Sources/Intents/SoundScapeShortcuts.swift

**Files to modify:**
- Sources/App/SoundScapeApp.swift (register AppShortcutsProvider)

---

### 8. Siri App Intents - Advanced
**Priority:** 8
**Dependencies:** Siri App Intents - Basic

Add advanced natural language Siri commands for contextual and dynamic sound control.

**Requirements:**
- Create SleepHelpIntent for distress phrases:
  - Phrases: "I can't sleep", "Help me fall asleep", "I'm having trouble sleeping"
  - Action: Intelligently select a calming mix based on:
    - Time of day (night prefers rain, ocean, pink noise)
    - User's most-used sounds from InsightsService
    - Start with lower volume (60%)
  - Response: "Starting a calming soundscape to help you relax"
- Create AdjustMixIntent for dynamic adjustments:
  - "Make it more [thundery/rainy/fiery]" → boost that sound type
  - "Make it warmer" → increase fire sounds, optionally decrease rain
  - "Make it cooler" → increase rain/ocean, decrease fire
  - "Make it calmer" → reduce overall volume by 20%
  - "Turn down the [sound]" → decrease specific sound volume
  - "Add some [sound]" → add sound to current mix
- Create SemanticSoundMappings to translate adjectives to actions:
  - "thundery" → thunder, heavy thunder
  - "rainy" → rain storm, rainforest
  - "warmer" → fire category sounds
  - "natural" → nature category sounds
- Error handling with helpful suggestions

**New files to create:**
- Sources/Intents/SleepHelpIntent.swift
- Sources/Intents/AdjustMixIntent.swift
- Sources/Intents/SemanticSoundMappings.swift

**Files to modify:**
- Sources/Intents/SoundScapeShortcuts.swift (add new phrases)

---

### 9. Control Center Widget
**Priority:** 9
**Dependencies:** Siri App Intents - Basic

Create a Lock Screen widget showing current playback status for quick glance information.

**Requirements:**
- Create a Widget Extension target if not exists
- Create SoundScapeWidget for Lock Screen (WidgetFamily.accessoryRectangular):
  - Shows current mix name or "Not playing"
  - Shows timer remaining if active
  - Category icon for current primary sound
- Create widget timeline provider:
  - Update when playback state changes
  - Show relevant info based on playing state
- Widget configuration:
  - Kind: "SoundScapePlayback"
  - Description: "See your current soundscape"
- Tapping widget deep-links to app

**Note:** Full Control Center widgets with interactive controls require iOS 18. For iOS 17, we create an informational Lock Screen widget that shows playback status. Users can tap to open the app for control.

**New files to create:**
- SoundScapeWidget/SoundScapeWidget.swift
- SoundScapeWidget/PlaybackWidgetProvider.swift
- SoundScapeWidget/PlaybackWidgetView.swift

**Files to potentially modify:**
- SoundScape.xcodeproj (add widget extension target)
- May need Info.plist updates for App Groups

---

### 10. StandBy Nightstand Mode Widget
**Priority:** 10
**Dependencies:** Liquid Sound Visualization, True Black OLED Mode, Control Center Widget

Create a StandBy mode widget for iOS 17's nightstand feature.

**Requirements:**
- Create StandBy widget using WidgetFamily.systemLarge
- Layout for landscape StandBy display:
  - Large clock (current time) - SF Pro Rounded style
  - Current mix name below clock
  - Timer remaining if active
  - Simple status indicator (playing/paused)
- Visual design:
  - Pure black background (#000000)
  - White text at 60% opacity for clock
  - Category accent color for status elements
- Widget updates:
  - Timeline updates every minute for clock
  - Refresh when playback state changes
- Deep link to app when tapped
- Respect system dark/dim settings

**Note:** StandBy mode in iOS 17 uses existing widget infrastructure. The widget automatically displays in StandBy when device is charging, landscape, and locked. Full custom StandBy scenes require additional work.

**New files to create:**
- SoundScapeWidget/StandByWidget.swift
- SoundScapeWidget/StandByWidgetView.swift

**Files to modify:**
- SoundScapeWidget/SoundScapeWidget.swift (register both widgets)
