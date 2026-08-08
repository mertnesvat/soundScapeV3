# Shallow Modules — Deletion Test

The soundScapeV3 Data layer carries 29 Swift files across `Services/` and `DataSources/` against a Domain layer with exactly two protocols and one ViewModel. The architecture signals Clean Architecture on paper but collapses to a tangled service mesh in practice, with real depth concentrated in `AudioEngine` and shallow indirection dominating the repository and datasource tiers.

---

## Inventory

### 1. `SoundRepository` / `SoundRepositoryProtocol`

- **Files:** `Data/Repositories/SoundRepository.swift` (21 lines), `Domain/Repositories/SoundRepositoryProtocol.swift` (7 lines)
- **Interface:** `getAllSounds()`, `getSounds(byCategory:)`, `getSound(byId:)` — 3 methods
- **Implementation:** delegates entirely to `LocalSoundDataSource.shared.getAllSounds()` plus in-memory `filter`. Interface and implementation are the same depth.
- **Deletion test:** delete both — `SoundsViewModel` calls `LocalSoundDataSource.shared` directly, with identical complexity. Complexity does not scatter. One adapter = hypothetical seam, not a real one.
- **Action:** **Inline.** Remove `SoundRepository` and `SoundRepositoryProtocol`. If a remote data adapter materialises later, re-introduce the seam then.

### 2. `LocalSoundDataSource` / `LocalCommunityDataSource` / `LocalStoryDataSource`

- **Files:** `Data/DataSources/Local*.swift`
- **Interface:** one method or property returning a hardcoded Swift array literal
- **Implementation:** 245/260/130 lines of entity constructor calls — pure data, no algorithms
- **Deletion test:** delete each — the literal arrays must move (a JSON bundle file or a `+Data` extension). The class wrappers add zero leverage. `LocalSoundDataSource.shared` is additionally called from three independent callers (`SoundRepository`, `AlarmNotificationSoundManager`, `AlarmService`), re-allocating the same 38-element `[Sound]` array on each call with no shared cache.
- **Action:** **Inline to bundle JSON** decoded once at app launch. Eliminates three shallow wrappers and the redundant allocation fan-out simultaneously.

### 3. `AppearanceService`

- **File:** `Data/Services/AppearanceService.swift` (32 lines)
- **Interface:** `isOLEDModeEnabled: Bool`, `toggleOLEDMode()`, `setOLEDMode(_:)` — wraps one `UserDefaults` key
- **Implementation:** `loadSettings()` reads one bool; `saveSettings()` writes it. No business logic.
- **Deletion test:** delete it — replace with `@AppStorage("oled_mode_enabled") var isOLEDModeEnabled: Bool` at each consumer. Zero complexity scatters. Textbook shallow module.
- **Action:** **Inline to `@AppStorage`**.

### 4. `StoryProgressService`

- **File:** `Data/Services/StoryProgressService.swift` (66 lines)
- **Interface:** 8 members — get/set/clear progress plus `progressFraction(for:)`, `remainingTime(for:)`, `isCompleted(_:)`, `inProgressStoryIds`
- **Implementation:** `[String: TimeInterval]` dictionary backed by `UserDefaults`. The three derived methods are single-expression arithmetic on `progress[id]` and `story.duration`.
- **Deletion test:** delete it — `SleepContentPlayerService` (the only caller) would own the `UserDefaults` key and codec directly. The three derived properties become local one-liners. Complexity moves to one caller, not many.
- **Action:** **Deepen or split.** Keep the key-value persistence layer (genuine depth — one place for the codec and key string). Remove `progressFraction`, `remainingTime`, `isCompleted` to `SleepContent` entity extensions where they belong.

### 5. `SoundsViewModel`

- **File:** `Presentation/Sounds/ViewModels/SoundsViewModel.swift` (69 lines)
- **Interface:** 11 members; 9 of them one-line forwarding calls to `repository`, `audioEngine`, or `favoritesService`
- **Implementation:** the only non-trivial member is `filteredSounds` (a two-branch guard/filter)
- **Deletion test:** delete it — `SoundsView` holds three service references instead of one ViewModel reference. One caller. The ViewModel provides no depth.
- **Action:** **Inline into the View, or deepen.** If the ViewModel stays, it must own meaningful state (sorting, section headers, search, loading state) rather than forwarding.

### 6. `ReviewPromptService` — partial

- **File:** `Data/Services/ReviewPromptService.swift` (174 lines)
- Interface includes: `recordSuccessfulSleepSession()`, `recordMixSaved()`, `recordFavoriteAction()` — all three are aliases for `recordPositiveAction()`
- **Deletion test on full module:** complexity scatters — eligibility policy (30-day window, 3-per-year cap, session threshold) earns its keep
- **Deletion test on alias methods:** removing the three and collapsing to one `recordPositiveAction(source:)` reduces interface complexity with no leverage loss
- **Action:** **Deepen interface:** collapse three semantic aliases into one method with an enum source parameter. Remove the no-op `markAsDeclined()` body. Fix the `YOUR_APP_STORE_ID` placeholder.

### 7. `SoundScienceContent`

- **File:** `Data/DataSources/SoundScienceContent.swift`
- **Interface:** `static let sections: [ScienceSection]` — one property
- **Implementation:** static array of localised string literals wrapped in struct constructors
- **Deletion test:** delete it — move to bundle JSON or fold into `SoundScienceView` as a private constant. One caller, zero algorithmic depth.
- **Action:** **Inline to bundle JSON.** The `Data/DataSources/` location misclassifies what is presentation content.

### 8. `PaywallService` forwarding methods — partial

- **File:** `Data/Services/PaywallService.swift` (196 lines)
- `purchaseMonthly()` and `purchaseYearly()` are two-line forwarding wrappers to `SubscriptionService`
- **Full module deletion test:** fails — the session gating logic (≥2 sessions, one paywall per session) and analytics decoration are genuine depth
- **Action:** **Deepen:** remove the two forwarding purchase methods.

---

## Top 3 Highest-Impact Targets

1. **`SoundRepository` + `SoundRepositoryProtocol` — inline.** The only repository-tier protocol in the codebase, with one adapter, no tests crossing the seam, and an implementation that is three one-liners. Removing it collapses the `View → ViewModel → Repository → DataSource` chain by one full level.

2. **`AppearanceService` — inline to `@AppStorage`.** A 32-line class wrapping one `UserDefaults.bool`. Every consumer becomes a single `@AppStorage` property declaration. The purest case of a module whose interface is as complex as its implementation.

3. **`LocalSoundDataSource` / `LocalCommunityDataSource` / `LocalStoryDataSource` — convert to bundle JSON.** Three modules whose entire bodies are literal data arrays. The fan-out from `LocalSoundDataSource` to three independent callers is an active performance issue. Converting to a single decoded-once JSON removes three wrappers and eliminates redundant allocations.

---

## Modules That Look Shallow but Pass the Test (Preserve)

- **`AudioEngine`** — has 5+ concerns (playback, session tracking, analytics, Now Playing, Widget, milestone timers). Looks like a god class. Deletion test: splitting requires an orchestrator of equal complexity, because `pauseAll()` must atomically update Now Playing, widget, and milestone tracking. The interface (`AudioPlayerProtocol`, 8 methods) hides a genuine state machine. Keep unified; right improvement is extracting analytics calls behind an injectable observer interface without splitting the module boundary.

- **`AlarmNotificationSoundManager`** — 2-method interface hiding a complete MP3-to-CAF conversion pipeline: chunk-based `AVAudioFile` read/write, output directory management, and JSON cache of converted file IDs. Deletion scatters ~130 lines of audio-conversion code into `AlarmService`. Clearly passes.

- **`BinauralBeatEngine`** — 3-method interface hiding real-time `AVAudioSourceNode` DSP: dual phase accumulators, binaural/isochronic mode switching, stereo buffer writing. Deletion scatters the signal-processing algorithm into a caller. Clearly passes.

- **`InsightsService`** — owns session recording, weekly aggregation, quality calculation, recommendation generation, goal tracking, and mock data seeding behind a moderate interface. Deletion scatters to multiple views. Passes (though `generateMockDataIfEmpty()` is a development artifact that should be removed or moved behind a debug flag before shipping).

- **`SubscriptionService`** — 397 lines hiding StoreKit 2's async purchase flow, transaction listener lifecycle, cryptographic verification, status caching, and expiry detection. Interface is 4–5 public methods. Very high depth. Passes.
