# SoundScape - Rebuild Specification

A comprehensive specification for rebuilding SoundScape iOS app while maintaining the existing App Store presence and Firebase backend.

---
bundle_identifier: com.StudioNext.SoundScape
firebase_project: next-soundscape
platform: iOS only (iPhone)
---

## What is SoundScape?

SoundScape is a wellness audio app that helps users create personalized ambient soundscapes. The app serves multiple use cases:

- **Sleep & Relaxation** - Soothing sounds to fall asleep faster and sleep better
- **Study & Focus** - Ambient noise to improve concentration and mask distractions
- **Baby White Noise** - Calming sounds to help infants and toddlers sleep
- **Meditation** - Peaceful audio environments for mindfulness practices
- **Work Environments** - Background audio to mask office noise

Users can mix multiple sounds together, adjust individual volumes, save their favorite combinations, and set sleep timers for automatic fade-out.

---

## Why Rebuild?

The current app has grown complex with many advanced features. This rebuild aims to:

- Start fresh with a cleaner, simpler implementation
- Focus on core MVP functionality first
- Maintain the same App Store bundle ID and Firebase project
- Preserve compatibility with existing sound assets

---

## Assets Ready for Rebuild

All content files have been copied to `rebuild-assets/` folder:

```
rebuild-assets/
├── Sounds/                    # 11 ambient sound files
│   ├── white_noise.mp3
│   ├── pink_noise.mp3
│   ├── brown_noise.mp3
│   ├── brown_noise_deep.mp3
│   ├── morning_birds.mp3
│   ├── winter_forest.mp3
│   ├── serene_morning.mp3
│   ├── rain_storm.mp3
│   ├── wind_ambient.mp3
│   ├── campfire.mp3
│   └── bonfire.mp3
├── Firebase/
│   └── GoogleService-Info.plist
└── AppIcon/
    ├── Contents.json
    └── JuagXpUnt9nQdMaaxWn5O.png
```

### Sound Library (11 sounds)

| Category | Sounds |
|----------|--------|
| **Noise** | White Noise, Pink Noise, Brown Noise, Deep Brown Noise |
| **Nature** | Morning Birds, Winter Forest, Serene Morning |
| **Weather** | Rain Storm, Wind Ambient |
| **Fire** | Campfire, Bonfire |

### Firebase Configuration
- Project ID: `next-soundscape`
- Storage Bucket: `next-soundscape.firebasestorage.app`
- Existing Firestore collections: `stories`, `narrators`

---

## Current App Structure (6 Tabs)

The existing app has a tab-based navigation with 6 main sections:

| Tab | Name | Purpose |
|-----|------|---------|
| 1 | Sounds | Browse and mix ambient sounds |
| 2 | Discover | Explore community-shared mixes |
| 3 | Stories | Listen to narrated sleep stories |
| 4 | Adaptive | Configure context-aware soundscapes |
| 5 | Insights | View sleep analytics and trends |
| 6 | Alarms | Manage wake-up alarms |

---

## MVP Features

For the rebuild, focus on these core features first:

---

### Feature 1: Sound Library
**Screen:** Sounds Tab (Home)

The main screen where users browse and play ambient sounds.

**What users see:**
- Grid or list of all available sounds
- Sounds organized by category (Noise, Nature, Weather, Fire)
- Category filter tabs at the top
- Play/pause button on each sound card
- Visual indicator when a sound is playing

**User journey:**
1. User opens app → lands on Sounds tab
2. User scrolls through sound categories
3. User taps a sound card to start playing
4. Sound loops continuously in the background
5. User can tap again to stop the sound

---

### Feature 2: Sound Mixer
**Screen:** Now Playing / Mixer View

Allows users to layer multiple sounds and control individual volumes.

**What users see:**
- List of currently playing sounds
- Volume slider (0-100%) for each active sound
- Sound name and category label
- Remove button to stop individual sounds
- Total count of active sounds

**User journey:**
1. User plays multiple sounds from the library
2. Each playing sound appears in the mixer
3. User adjusts volume sliders to create perfect blend
4. User can remove sounds they don't want
5. Mix continues playing even when app is backgrounded

---

### Feature 3: Sleep Timer
**Screen:** Timer Sheet/Modal

Automatic shutdown timer with gradual fade-out.

**What users see:**
- Preset duration buttons: 5, 15, 30, 45 min, 1h, 1.5h, 2h
- Optional custom time picker
- Countdown display showing remaining time (MM:SS)
- Cancel button to stop timer
- Timer icon in playback controls shows active state

**User journey:**
1. User creates their sound mix
2. User taps timer button in playback controls
3. User selects duration (e.g., 30 minutes)
4. Timer starts counting down
5. When timer ends, volume gradually fades out over ~30 seconds
6. All sounds stop, user is asleep

---

### Feature 4: Saved Mixes
**Screen:** Saved Mixes List

Save and recall favorite sound combinations.

**What users see:**
- List of saved mixes with custom names
- Preview showing which sounds are in each mix
- Creation date
- Play button to instantly load the mix
- Edit and delete options (swipe or menu)
- Empty state with prompt to save first mix

**User journey - Saving:**
1. User creates a mix they like
2. User taps "Save Mix" button
3. User enters a name (e.g., "Rainy Night Study")
4. Mix is saved with all sounds and volume levels

**User journey - Loading:**
1. User opens Saved Mixes screen
2. User taps on a saved mix
3. All sounds from that mix start playing at saved volumes
4. User can further adjust if needed

---

### Feature 5: Favorites
**Screen:** Integrated into Sound Library

Quick access to preferred individual sounds.

**What users see:**
- Heart icon on each sound card
- Favorites section at top of sound library
- Filled heart for favorited sounds

**User journey:**
1. User finds a sound they use often
2. User taps heart icon to favorite it
3. Sound appears in Favorites section for quick access
4. User can unfavorite by tapping heart again

---

## Post-MVP Features

These features exist in the current app and should be added after MVP is stable:

---

### Feature 6: Sleep Stories
**Screen:** Stories Tab

Narrated audio stories designed to help users fall asleep.

**What users see:**
- Featured stories banner at top
- Story cards with cover art, title, duration
- Category filters: Fiction, Nature Journeys, Meditation, ASMR
- Narrator filter (different voice types)
- Duration filter: 10, 20, 30, 45 minutes
- Search bar
- Continue listening section for in-progress stories

**Story card shows:**
- Cover artwork
- Story title
- Narrator name
- Duration
- Progress bar (if started)

**User journey:**
1. User opens Stories tab
2. User browses or filters by category/narrator/duration
3. User taps a story to open player
4. Story plays with optional background soundscape
5. Progress is saved if user stops mid-story

---

### Feature 7: Binaural Beats
**Screen:** Dedicated section or integrated into Sounds

Brainwave entrainment audio for different mental states.

**What users see:**
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

**User journey:**
1. User wants to enhance focus while studying
2. User selects Beta (Focus) brainwave state
3. User puts on headphones
4. User adjusts intensity
5. Binaural beat plays, can be mixed with other sounds

---

### Feature 8: Smart Alarms
**Screen:** Alarms Tab

Wake-up alarms with gradual volume and smart timing.

**What users see:**
- List of configured alarms
- Add alarm button
- Each alarm shows: time, repeat days, enabled toggle
- Alarm detail screen with:
  - Time picker
  - Repeat days selector (M T W T F S S)
  - Alarm sound picker (nature sounds: birds, sunrise, ocean, etc.)
  - Volume ramp duration (wake gradually over 5-30 min)
  - Smart alarm toggle (wake during light sleep)
  - Snooze duration setting

**User journey:**
1. User creates alarm for 7:00 AM weekdays
2. User selects "Morning Birds" as alarm sound
3. User enables 15-minute volume ramp
4. User enables smart alarm with 30-min window
5. Next morning: alarm detects light sleep at 6:45 AM
6. Volume gradually increases from 6:45 to 7:00 AM
7. User wakes naturally feeling refreshed

---

### Feature 9: Community / Discover
**Screen:** Discover Tab

Browse and share sound mixes with other users.

**What users see:**
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

**User journey - Discovering:**
1. User opens Discover tab
2. User browses trending mixes
3. User taps a mix to preview
4. User likes it and saves to their library
5. User can upvote to help others find it

**User journey - Sharing:**
1. User creates a great mix
2. User taps "Share to Community"
3. User adds name, description, tags
4. User chooses visibility (public/unlisted)
5. Mix gets a share code for direct sharing

---

### Feature 10: Adaptive Soundscapes
**Screen:** Adaptive Tab

Context-aware soundscapes that evolve automatically.

**What users see:**
- Preset adaptive modes:
  - Sleep Cycle (sounds change through night)
  - Day & Night (follows time of day)
  - Weather Sync (matches local weather)
  - Heart Rate Calming (responds to HR data)
- Custom trigger configuration
- Evolution pattern selector
- Preview of how sounds will change

**User journey:**
1. User selects "Sleep Cycle" adaptive mode
2. User starts the soundscape at bedtime
3. As user falls asleep, sounds gradually shift to deeper tones
4. During night, sounds maintain low-frequency ambience
5. Near wake time, sounds shift to lighter, brighter tones

---

### Feature 11: Sleep Insights
**Screen:** Insights Tab

Analytics and recommendations based on sleep data.

**What users see:**
- Sleep duration chart (weekly/monthly)
- Sleep quality score
- Time to fall asleep average
- Deep sleep percentage
- Best performing sounds (correlation analysis)
- Personalized recommendations
- Sleep goals and progress

**User journey:**
1. User grants HealthKit access
2. App tracks sleep sessions automatically
3. After several nights, insights become available
4. User sees that "Rain + Brown Noise" gives best sleep quality
5. User adjusts habits based on recommendations

---

## Screen Flow Summary

```
App Launch
    │
    ├── Tab 1: Sounds ──────────────┐
    │   ├── Sound Library Grid      │
    │   ├── Category Filters        │
    │   └── Tap Sound → Add to Mix  │
    │                               │
    ├── Tab 2: Discover ────────────┤  (Post-MVP)
    │   ├── Featured Mixes          │
    │   ├── Category Browse         │
    │   └── Tap Mix → Preview/Save  │
    │                               │
    ├── Tab 3: Stories ─────────────┤  (Post-MVP)
    │   ├── Story Browser           │
    │   ├── Filters & Search        │
    │   └── Tap Story → Player      │
    │                               │
    ├── Tab 4: Adaptive ────────────┤  (Post-MVP)
    │   ├── Preset Modes            │
    │   └── Custom Configuration    │
    │                               │
    ├── Tab 5: Insights ────────────┤  (Post-MVP)
    │   ├── Sleep Charts            │
    │   ├── Recommendations         │
    │   └── Goals                   │
    │                               │
    └── Tab 6: Alarms ──────────────┘  (Post-MVP)
        ├── Alarm List
        └── Tap → Alarm Detail

Floating/Persistent Elements:
    ├── Now Playing Bar (bottom)
    │   ├── Shows active sounds
    │   ├── Play/Pause all
    │   ├── Timer button → Timer Sheet
    │   └── Tap → Mixer View
    │
    └── Mixer View (modal/sheet)
        ├── Active sounds list
        ├── Volume sliders
        └── Save Mix button → Name Input
```

---

## MVP vs Full App Summary

| Feature | MVP | Post-MVP |
|---------|:---:|:--------:|
| Sound Library & Playback | ✓ | |
| Multi-Sound Mixing | ✓ | |
| Volume Control per Sound | ✓ | |
| Sleep Timer with Fade | ✓ | |
| Save/Load Mixes | ✓ | |
| Favorites | ✓ | |
| Sleep Stories | | ✓ |
| Binaural Beats | | ✓ |
| Smart Alarms | | ✓ |
| Community Discover | | ✓ |
| Adaptive Soundscapes | | ✓ |
| Sleep Insights | | ✓ |

---

## Design Notes

- **Dark Mode Primary** - App is used at bedtime, dark UI reduces eye strain
- **Large Touch Targets** - Easy to tap when drowsy
- **Minimal Visual Noise** - Calming interface, no jarring colors
- **Persistent Playback** - Now playing bar always accessible
- **Smooth Animations** - Gentle transitions that don't stimulate
