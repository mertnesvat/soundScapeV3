---
base_branch: master
max_retries: 2
continue_on_failure: true
visual_gate_enabled: true
visual_gate_threshold: 0.7
bundle_id: com.StudioNext.SoundScape
action_logging: true
---

# Feature Queue: SoundScape Wind Down Tab

Transform the existing Stories tab into a comprehensive "Wind Down" tab that combines sleep stories, yoga nidra sessions, guided meditations, breathing exercises, sleep hypnosis, and bedtime affirmations into a unified sleep content experience.

**Key Design Principle:** All audio content is bundled locally within the app (no downloads, no streaming, no network requests). Content without audio files displays a "Coming Soon" badge.

---

## Feature 1: Wind Down Tab Core Architecture

Replace the existing Stories tab with a new "Wind Down" tab that serves as the home for all sleep-inducing audio content.

**User Story:** As a user, I want to access all sleep content (stories, yoga nidra, meditations, breathing exercises) in one dedicated tab so I can easily find content to help me fall asleep.

**Acceptance Criteria:**
- User sees "Wind Down" tab in the tab bar with moon icon (moon.zzz.fill)
- User sees a welcoming header with personalized greeting based on time of day
- User sees horizontal category sections for: Featured, Yoga Nidra, Sleep Stories, Meditations, Breathing, Hypnosis, Affirmations
- User can scroll vertically through all content sections
- Each section shows horizontal scrolling cards with content previews
- Tab replaces the commented-out Stories tab in ContentView
- Tab bar icon uses a calming indigo/purple color

**Priority:** 1
**Dependencies:** None

**Technical Context:**
- Enable and rename Stories tab to WindDown in ContentView.swift
- Create new WindDownView.swift as the main tab view
- Update Tab enum: change .stories case to .windDown with moon.zzz.fill icon
- Remove commented-out Stories tab code and replace with active Wind Down tab
- Keep existing StoryProgressService for progress tracking (rename later if needed)

---

## Feature 2: Sleep Content Entity & Data Model

Create a unified content model that can represent all types of sleep content (stories, yoga nidra, meditations, etc.).

**User Story:** As a user, I want content to be organized by type so I can quickly find the specific kind of sleep content I'm looking for.

**Acceptance Criteria:**
- User sees content categorized by type (Yoga Nidra, Stories, Meditations, Breathing, Hypnosis, Affirmations)
- User sees duration displayed for each content item
- User sees narrator/guide name for voiced content
- User sees a visual indicator for content that has audio vs "Coming Soon"
- User can distinguish between different content types by their icons and colors

**Priority:** 1
**Dependencies:** Feature 1

**Technical Context:**
- Create new SleepContent.swift entity in Sources/Domain/Entities/:
  ```swift
  struct SleepContent: Identifiable, Equatable {
      let id: String
      let title: String
      let narrator: String
      let duration: TimeInterval  // seconds
      let contentType: SleepContentType
      let description: String
      let audioFileName: String?  // nil = Coming Soon
  }

  enum SleepContentType: String, CaseIterable {
      case yogaNidra = "Yoga Nidra"
      case sleepStory = "Sleep Stories"
      case guidedMeditation = "Guided Meditation"
      case breathingExercise = "Breathing"
      case sleepHypnosis = "Sleep Hypnosis"
      case affirmations = "Affirmations"

      var icon: String { ... }  // SF Symbols
      var color: Color { ... }  // Category colors
  }
  ```
- Content type colors:
  - Yoga Nidra: Deep Purple (#8B5CF6)
  - Sleep Stories: Indigo (#6366F1)
  - Guided Meditation: Purple (#A855F7)
  - Breathing: Teal (#14B8A6)
  - Sleep Hypnosis: Blue (#3B82F6)
  - Affirmations: Pink (#EC4899)
- audioFileName should be actual bundled file name (e.g., "yoga_nidra_sleep_5min.mp3") or nil for Coming Soon

---

## Feature 3: Yoga Nidra Content Integration

Add the yoga nidra sessions to the app with bundled audio files.

**User Story:** As a user, I want to listen to yoga nidra guided meditations to help me relax deeply and fall asleep.

**Acceptance Criteria:**
- User sees 3 yoga nidra sessions: 5-minute, 8-minute, and 10-minute versions
- User can tap on a yoga nidra session to open the player
- User hears actual audio playback (bundled with app, no download needed)
- User sees session progress tracked and saved
- User can resume a yoga nidra session from where they left off

**Priority:** 1
**Dependencies:** Feature 2

**Technical Context:**
- CRITICAL: Copy yoga nidra MP3 files from /yoga_nidra/ folder to SoundScape/Resources/Sounds/:
  - yoga_nidra_sleep_5min.mp3 (7 MB)
  - yoga_nidra_sleep_8min.mp3 (10.5 MB)
  - yoga_nidra_sleep_10min.mp3 (18.4 MB)
- Add all 3 files to project.pbxproj:
  - PBXBuildFile section
  - PBXFileReference section
  - Sounds group children
  - PBXResourcesBuildPhase files
- Create SleepContentDataSource.swift in Sources/Data/DataSources/ with yoga nidra entries:
  ```swift
  static let yogaNidraSessions: [SleepContent] = [
      SleepContent(
          id: "yoga_nidra_5min",
          title: "Quick Yoga Nidra",
          narrator: "Guided Voice",
          duration: 300,  // 5 minutes
          contentType: .yogaNidra,
          description: "A brief but powerful yoga nidra session perfect for short breaks or when you need quick relaxation.",
          audioFileName: "yoga_nidra_sleep_5min.mp3"
      ),
      SleepContent(
          id: "yoga_nidra_8min",
          title: "Extended Yoga Nidra",
          narrator: "Guided Voice",
          duration: 480,  // 8 minutes
          contentType: .yogaNidra,
          description: "A deeper yoga nidra experience with extended body scan and visualization.",
          audioFileName: "yoga_nidra_sleep_8min.mp3"
      ),
      SleepContent(
          id: "yoga_nidra_10min",
          title: "Complete Yoga Nidra",
          narrator: "Guided Voice",
          duration: 600,  // 10 minutes
          contentType: .yogaNidra,
          description: "The full yoga nidra journey. Perfect for bedtime relaxation and deep restoration.",
          audioFileName: "yoga_nidra_sleep_10min.mp3"
      )
  ]
  ```

---

## Feature 4: Sleep Content Player

Create a unified audio player for all sleep content that supports real audio playback with progress tracking.

**User Story:** As a user, I want a full-screen player that shows my progress and lets me control playback while listening to sleep content.

**Acceptance Criteria:**
- User sees full-screen player with calming gradient background (uses content type color)
- User sees content title, narrator, and total duration
- User sees and can interact with progress slider
- User can play/pause playback
- User can skip forward/backward 15 seconds
- User can close the player and return to browsing
- User's progress is saved when exiting (can resume later)
- Playback continues when screen is locked
- Now Playing info shows on lock screen with controls
- Player shows disabled state with "Coming Soon" message for content without audio

**Priority:** 1
**Dependencies:** Feature 3

**Technical Context:**
- Create SleepContentPlayerView.swift in Sources/Presentation/WindDown/Views/
- Create SleepContentPlayerService.swift (@Observable class) for playback:
  - Uses AVAudioPlayer for single non-looping playback (numberOfLoops = 0)
  - currentContent: SleepContent?
  - isPlaying: Bool
  - currentTime: TimeInterval
  - duration: TimeInterval
  - func play(content: SleepContent)
  - func pause()
  - func seek(to time: TimeInterval)
  - func skipForward(seconds: TimeInterval = 15)
  - func skipBackward(seconds: TimeInterval = 15)
- Configure AVAudioSession for .playback category (same as AudioEngine)
- Update Now Playing Info on lock screen (title, artist as narrator, artwork placeholder)
- Use existing StoryProgressService to save/restore progress
- Handle audio interruptions (phone calls, Siri)
- Player should NOT use AudioEngine (sleep content is single-track, not mixable)

---

## Feature 5: Sleep Stories Section with Coming Soon Badges

Display sleep stories with proper "Coming Soon" badges for mock content.

**User Story:** As a user, I want to see what sleep stories are available (or coming) so I know what content to look forward to.

**Acceptance Criteria:**
- User sees all 12 existing mock stories in the Stories section
- User sees "Coming Soon" badge overlay on stories without audio
- User can tap on "Coming Soon" stories to see details but play button is disabled
- User sees story categories: Fiction, Nature Journeys, Meditation, ASMR
- Stories are displayed in a horizontal scrolling section
- Tapping a "Coming Soon" story shows a brief toast message

**Priority:** 2
**Dependencies:** Feature 4

**Technical Context:**
- Migrate stories from LocalStoryDataSource to SleepContentDataSource
- Convert Story entities to SleepContent with contentType: .sleepStory
- Keep all 12 existing stories (all with audioFileName: nil for Coming Soon)
- Create ComingSoonBadge.swift component:
  - Overlay with "Coming Soon" text
  - Semi-transparent dark background
  - Positioned at bottom of card
- In player view, show overlay message: "This content is coming soon! We're working on bringing you amazing sleep stories."
- Disable play controls when audioFileName is nil

---

## Feature 6: Breathing Exercises Section

Add guided breathing exercises for sleep preparation.

**User Story:** As a user, I want to follow guided breathing exercises to calm my nervous system before sleep.

**Acceptance Criteria:**
- User sees breathing exercises section in Wind Down tab
- User sees 4 breathing exercise entries: 4-7-8 Breath, Box Breathing, Deep Sleep Breath, Relaxing Exhale
- User sees "Coming Soon" badges on exercises (no audio yet)
- User can tap to view exercise description and technique details
- Each breathing exercise card shows the breathing pattern

**Priority:** 2
**Dependencies:** Feature 2

**Technical Context:**
- Add breathing exercises to SleepContentDataSource:
  ```swift
  static let breathingExercises: [SleepContent] = [
      SleepContent(
          id: "breathing_478",
          title: "4-7-8 Breath",
          narrator: "Guided Voice",
          duration: 300,  // 5 min
          contentType: .breathingExercise,
          description: "The relaxing breath technique. Inhale for 4 counts, hold for 7, exhale for 8. Known to promote deep relaxation.",
          audioFileName: nil  // Coming Soon
      ),
      SleepContent(
          id: "breathing_box",
          title: "Box Breathing",
          narrator: "Guided Voice",
          duration: 420,  // 7 min
          contentType: .breathingExercise,
          description: "Equal counts of inhale, hold, exhale, hold. Used by Navy SEALs for stress relief and focus.",
          audioFileName: nil
      ),
      SleepContent(
          id: "breathing_deep_sleep",
          title: "Deep Sleep Breath",
          narrator: "Guided Voice",
          duration: 600,  // 10 min
          contentType: .breathingExercise,
          description: "Extended exhale breathing designed specifically to activate your parasympathetic nervous system.",
          audioFileName: nil
      ),
      SleepContent(
          id: "breathing_relaxing",
          title: "Relaxing Exhale",
          narrator: "Guided Voice",
          duration: 480,  // 8 min
          contentType: .breathingExercise,
          description: "Focus on long, slow exhales to release tension and prepare for restful sleep.",
          audioFileName: nil
      )
  ]
  ```
- Color: Teal (#14B8A6)
- Icon: lungs.fill

---

## Feature 7: Guided Meditations Section

Add guided sleep meditations separate from yoga nidra.

**User Story:** As a user, I want to access various guided meditations designed specifically for falling asleep.

**Acceptance Criteria:**
- User sees Guided Meditations section in Wind Down tab
- User sees 4 meditation entries: Body Scan, Floating Clouds, Gratitude for Sleep, Peaceful Garden
- User sees "Coming Soon" badges (no audio yet)
- User sees meditation duration and guide name
- Each meditation has a calming description

**Priority:** 2
**Dependencies:** Feature 2

**Technical Context:**
- Add meditations to SleepContentDataSource:
  ```swift
  static let guidedMeditations: [SleepContent] = [
      SleepContent(
          id: "meditation_body_scan",
          title: "Body Scan Relaxation",
          narrator: "Dr. Emily Chen",
          duration: 1200,  // 20 min
          contentType: .guidedMeditation,
          description: "A progressive journey through each part of your body, releasing tension as you go deeper into relaxation.",
          audioFileName: nil
      ),
      SleepContent(
          id: "meditation_floating",
          title: "Floating on Clouds",
          narrator: "Maya Thompson",
          duration: 900,  // 15 min
          contentType: .guidedMeditation,
          description: "Visualize yourself floating on soft clouds, drifting peacefully toward sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "meditation_gratitude",
          title: "Gratitude for Sleep",
          narrator: "Dr. Emily Chen",
          duration: 600,  // 10 min
          contentType: .guidedMeditation,
          description: "End your day with gratitude, reflecting on positive moments as you prepare for restful sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "meditation_garden",
          title: "Peaceful Garden Walk",
          narrator: "James Rivers",
          duration: 1080,  // 18 min
          contentType: .guidedMeditation,
          description: "Walk through a beautiful, serene garden as evening falls, finding your inner peace.",
          audioFileName: nil
      )
  ]
  ```
- Color: Purple (#A855F7)
- Icon: sparkles

---

## Feature 8: Sleep Hypnosis Section

Add sleep hypnosis content for deep relaxation.

**User Story:** As a user, I want to try sleep hypnosis sessions to help with deeper, more restorative sleep.

**Acceptance Criteria:**
- User sees Sleep Hypnosis section in Wind Down tab
- User sees 3 hypnosis sessions: Deep Sleep Hypnosis, Letting Go, Peaceful Dreams
- User sees "Coming Soon" badges (no audio yet)
- User sees session duration and hypnotist name
- Section positioned after Meditations in the UI

**Priority:** 3
**Dependencies:** Feature 2

**Technical Context:**
- Add hypnosis to SleepContentDataSource:
  ```swift
  static let sleepHypnosis: [SleepContent] = [
      SleepContent(
          id: "hypnosis_deep_sleep",
          title: "Deep Sleep Hypnosis",
          narrator: "Michael Waters",
          duration: 1800,  // 30 min
          contentType: .sleepHypnosis,
          description: "Gentle hypnotic induction designed to guide you into the deepest, most restorative sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "hypnosis_letting_go",
          title: "Letting Go",
          narrator: "Sarah Moon",
          duration: 1500,  // 25 min
          contentType: .sleepHypnosis,
          description: "Release the worries of the day through soothing hypnotic suggestions for peaceful sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "hypnosis_dreams",
          title: "Peaceful Dreams",
          narrator: "Michael Waters",
          duration: 1200,  // 20 min
          contentType: .sleepHypnosis,
          description: "Prepare your mind for beautiful, peaceful dreams as you drift off to sleep.",
          audioFileName: nil
      )
  ]
  ```
- Color: Blue (#3B82F6)
- Icon: brain.head.profile.fill

---

## Feature 9: Bedtime Affirmations Section

Add positive affirmation tracks for sleep mindset.

**User Story:** As a user, I want to listen to calming affirmations as I drift off to sleep to promote positive thoughts.

**Acceptance Criteria:**
- User sees Affirmations section in Wind Down tab
- User sees 4 affirmation tracks: Self-Love, Peaceful Sleep, Tomorrow's Promise, Releasing Anxiety
- User sees "Coming Soon" badges (no audio yet)
- User sees track duration (shorter than other content, 5-10 min)
- Section positioned at the end of the Wind Down tab

**Priority:** 3
**Dependencies:** Feature 2

**Technical Context:**
- Add affirmations to SleepContentDataSource:
  ```swift
  static let affirmations: [SleepContent] = [
      SleepContent(
          id: "affirmation_self_love",
          title: "Self-Love Affirmations",
          narrator: "Sophie White",
          duration: 420,  // 7 min
          contentType: .affirmations,
          description: "Gentle affirmations to remind yourself of your worth as you prepare for sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "affirmation_peaceful",
          title: "Peaceful Sleep Affirmations",
          narrator: "Sophie White",
          duration: 360,  // 6 min
          contentType: .affirmations,
          description: "Calming words to ease your mind and invite restful, peaceful sleep.",
          audioFileName: nil
      ),
      SleepContent(
          id: "affirmation_tomorrow",
          title: "Tomorrow's Promise",
          narrator: "Alex Kim",
          duration: 480,  // 8 min
          contentType: .affirmations,
          description: "Positive affirmations about the new day ahead, releasing today's concerns.",
          audioFileName: nil
      ),
      SleepContent(
          id: "affirmation_releasing",
          title: "Releasing Anxiety",
          narrator: "Dr. Emily Chen",
          duration: 600,  // 10 min
          contentType: .affirmations,
          description: "Soothing affirmations to help let go of anxious thoughts before sleep.",
          audioFileName: nil
      )
  ]
  ```
- Color: Pink (#EC4899)
- Icon: heart.text.square.fill

---

## Feature 10: Featured Content & Continue Listening

Show featured and recently played content at the top of Wind Down tab.

**User Story:** As a user, I want to quickly access featured content and resume my recent sessions without scrolling.

**Acceptance Criteria:**
- User sees "Featured Tonight" section at the top with a large highlighted content card
- User sees "Continue Listening" section if they have unfinished content (progress > 0 and < 95%)
- User sees progress bar on "Continue Listening" cards showing completion percentage
- Featured content highlights yoga nidra (since it has real audio)
- Time-of-day greeting: "Good Evening" before 9pm, "Ready for Sleep?" after 9pm
- Continue Listening only shows if user has incomplete sessions

**Priority:** 2
**Dependencies:** Feature 4

**Technical Context:**
- Use StoryProgressService to find incomplete sessions (filter where progress > 0 and < 0.95)
- Featured content logic:
  - Default to yoga_nidra_10min as featured
  - Can be changed to rotation logic later
- Greeting logic:
  ```swift
  var greeting: String {
      let hour = Calendar.current.component(.hour, from: Date())
      if hour >= 21 || hour < 5 {
          return "Ready for Sleep?"
      } else if hour >= 17 {
          return "Good Evening"
      } else {
          return "Wind Down"
      }
  }
  ```
- Create FeaturedContentCard.swift - larger card with gradient background
- Create ContinueListeningSection.swift - horizontal scroll with smaller cards showing progress

---

## Feature 11: Content Card Components

Create reusable card components for displaying sleep content in the tab.

**User Story:** As a user, I want content cards to be visually appealing and show me relevant information at a glance.

**Acceptance Criteria:**
- User sees content cards with title, duration, and narrator name
- User sees content type icon and color coding
- User sees progress indicator if content is partially complete
- User sees "Coming Soon" overlay for content without audio
- Cards have consistent sizing and smooth animations on tap
- Cards match the existing app's visual style (OLED-friendly dark theme)

**Priority:** 1
**Dependencies:** Feature 2

**Technical Context:**
- Create SleepContentCardView.swift in Sources/Presentation/WindDown/Components/:
  - Standard horizontal card (140pt width) for section scrolling
  - Shows: icon, title (max 2 lines), duration, narrator
  - Progress bar at bottom if progress > 0
  - Coming Soon badge overlay if audioFileName == nil
  - Category color as accent/glow
- Create LargeFeaturedCard.swift:
  - Full-width card with gradient background
  - Larger text, prominent play button
  - Shows description text
- Use existing app styling conventions (pure black background, category accent colors)
- Tap animation: slight scale down (0.97) on press

---

## Feature 12: Sleep Timer Integration for Wind Down Content

Allow users to set sleep timers while listening to wind down content.

**User Story:** As a user, I want to set a sleep timer so the content stops playing after I fall asleep.

**Acceptance Criteria:**
- User can access sleep timer from the content player (timer icon button)
- User sees timer options: 15, 30, 45, 60 minutes, or "End of Content"
- Timer shows countdown in player UI when active
- Audio fades out gradually (over 30 seconds) when timer ends
- Timer can be cancelled by tapping the timer button again
- "End of Content" option plays full content then stops

**Priority:** 2
**Dependencies:** Feature 4

**Technical Context:**
- Integrate existing SleepTimerService with SleepContentPlayerView
- Add timer button to player controls row (clock.fill icon)
- Present timer picker as bottom sheet (same style as existing TimerView)
- Add "End of Content" option that sets timer to remaining duration
- Show remaining time in player header area (e.g., "15:32 remaining")
- When timer ends:
  - Begin 30-second fade out (animate volume from current to 0)
  - Stop playback
  - Save progress
  - Optionally show gentle notification

---

## Summary

| # | Feature | Priority | Dependencies | Has Audio |
|---|---------|----------|--------------|-----------|
| 1 | Wind Down Tab Core Architecture | P1 | None | - |
| 2 | Sleep Content Entity & Data Model | P1 | F1 | - |
| 3 | Yoga Nidra Content Integration | P1 | F2 | ✅ 3 MP3s |
| 4 | Sleep Content Player | P1 | F3 | - |
| 5 | Sleep Stories with Coming Soon | P2 | F4 | ❌ Coming Soon |
| 6 | Breathing Exercises Section | P2 | F2 | ❌ Coming Soon |
| 7 | Guided Meditations Section | P2 | F2 | ❌ Coming Soon |
| 8 | Sleep Hypnosis Section | P3 | F2 | ❌ Coming Soon |
| 9 | Bedtime Affirmations Section | P3 | F2 | ❌ Coming Soon |
| 10 | Featured & Continue Listening | P2 | F4 | - |
| 11 | Content Card Components | P1 | F2 | - |
| 12 | Sleep Timer Integration | P2 | F4 | - |

**Total Features:** 12
**P1 (Critical - Core Functionality):** 4 features
**P2 (Important - Full Experience):** 5 features
**P3 (Nice to Have - Future Content):** 3 features

**Audio Files to Bundle:**
- yoga_nidra_sleep_5min.mp3 (7 MB)
- yoga_nidra_sleep_8min.mp3 (10.5 MB)
- yoga_nidra_sleep_10min.mp3 (18.4 MB)
- Total additional bundle size: ~36 MB

**Execution Order:** Night Agent will implement P1 features first (1→2→11→3→4), then P2 (5→6→7→10→12), then P3 (8→9).

**Note:** All "Coming Soon" content provides the infrastructure for future audio additions. When you have new audio files, simply:
1. Add MP3 to Resources/Sounds/
2. Add to project.pbxproj
3. Update audioFileName in SleepContentDataSource
