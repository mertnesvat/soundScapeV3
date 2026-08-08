# SoundScapeV3 — Architectural Deepening Refactor Brief

**Created:** 2026-05-18
**Status:** Draft, awaiting user input on Phase priorities
**Author:** Claude (DriftCode orchestrator) synthesizing parallel research

Research source: `/docs/research/` — 5 focused investigations.

---

## Part 1 — Coding Principles

Principles are not generic — each is bound to a real finding in this codebase. Cite the principle in PR descriptions when applying it.

### P1. The interface is the test surface

The test target is fully wired; `xcodebuild test` aborts because **one `<BuildActionEntry>` XML block** is missing from the scheme. 23 real test files sit idle. Adding the block restores the entire feedback loop. Until a test runs, refactor is unverified. (`docs/research/testability-gaps.md`)

### P2. Two adapters = real seam. One = hypothetical.

`SoundRepositoryProtocol` has one adapter and one real caller (`SoundsViewModel`); `ServiceContainer` and `AdaptiveSessionService` bypass it. `AudioPlayerProtocol` has one adapter and zero callers — every consumer holds concrete `AudioEngine`. These are hypothetical seams paying maintenance tax. Either commit to a second adapter or inline. (`docs/research/shallow-modules-deletion-test.md`, `architecture-layer-compliance.md`)

### P3. Domain imports `Foundation`, nothing else

`Story.swift` imports `SwiftUI` to provide `Color` on `StoryCategory`. A Domain entity that knows about UI cannot be tested headlessly, cannot be reused in non-UI contexts, and contradicts the layered architecture the folder structure claims. Move UI extensions to Presentation. (`architecture-layer-compliance.md`)

### P4. The composition root constructs in dependency order with constructor injection

`SoundScapeApp.swift` instantiates 19 services as `@State`, publishes them to `@Environment` un-wired, and wires cross-references in `.onAppear` via `setX(_:)` setters. Two services are `Optional` initialised to `nil` with `??` fallbacks because the order is unmanageable. Replace with a single `AppEnvironment` root that constructs in topological order via `init`. (`architecture-layer-compliance.md`, `state-and-coupling.md`)

### P5. One composition root, not two

App Intents (Siri/Shortcuts) construct a parallel service graph in `ServiceContainer.shared` with disjoint `AudioEngine`, `InsightsService`, `SavedMixesService`, `AnalyticsService` instances. Siri-triggered playback and UI playback mutate disjoint state. The composition root must be shared (or the Intent process must be explicit about which slice it owns). (`state-and-coupling.md`)

### P6. Persistence has one seam, not twelve

UserDefaults + JSON file writes appear in 8 services; `Documents/` files in 3 more; App-Group UserDefaults in 1. Only `SubscriptionService` accepts an injected `UserDefaults`. Introduce `KeyValueStore` + `DocumentStore` protocols. Tests inject in-memory adapters. Production code stops repeating the same five-line encode/decode dance. (`state-and-coupling.md`)

### P7. Business logic lives in Domain, not Data

Recommendation algorithm, sleep quality scoring, mix orchestration, and adaptive phase progression are pure computation living in Data services. The deletion test on `InsightsService` would scatter these to multiple callers — but each is a use case, not a persistence concern. Extract as `Domain/UseCases/*.swift`. Persistence stays in Data. (`architecture-layer-compliance.md`)

### P8. Two design systems = zero design system

Six surfaces use the new Editorial Light tokens; the remaining views still paint in legacy `.purple` / `.systemGray*`. The recently-introduced `Tokens.accentBrandLegacy` is referenced by zero files. Either complete the migration or rip out the editorial layer. Half-finished design systems are worse than no design system. (`view-layer-quality.md`)

### P9. Eight shared components hiding in six copies

Eight UI patterns have ≥2 inline reimplementations across the four core surfaces: `EditorialChip`, `EditorialSheet`, `TactilePressStyle`, `EditorialVolumeSlider`, `EditorialEmptyState`, `EditorialIndexNumeral`, `EditorialHairline`, `EditorialSparkline`. Two adapters = real seam — extract them. (`view-layer-quality.md`)

### P10. No production fakery

`InsightsService.generateMockDataIfEmpty()` runs on init and seeds production state with random fake sessions. Move to a debug flag or a separate `InsightsPreviewData` fixture used only by `#Preview`. (`architecture-layer-compliance.md`, `shallow-modules-deletion-test.md`)

### P11. Concurrency invariants are explicit, not assumed

Three `@Observable` services lack `@MainActor`. `AudioEngine.fadeIn`/`fadeOut` schedules 20 `asyncAfter` blocks unguarded by a cancellation token — rapid tapping interleaves fade chains and produces stuck volumes. Eight services run their own `Timer.scheduledTimer`. The codebase needs a single timer-coordinator and explicit `@MainActor` annotations on all `@Observable` types. (`state-and-coupling.md`)

### P12. Acceptance criteria are grep-able

DriftCode plans use grep / file-exists / xcodebuild-exit-0 assertions in their acceptance criteria (per the prior `editorial-redesign-core-surfaces` plan). Each issue must encode "done" as commands the verifier can run. No subjective "looks good" criteria.

---

## Part 2 — Phased Refactor Plan

Five phases. Each is independently shippable. Each ends with a green build and (after Phase 0) a green test run.

### Phase 0 — Wake the test target (smallest fix, largest unlock)

**Why first:** Without this, every subsequent phase has no verifier. The whole drift execute loop depends on `xcodebuild test` succeeding. Five test files pass with zero code changes once the scheme is patched.

**Issues:**

1. Add `<BuildActionEntry buildForTesting="YES">` for `SoundScapeTests` to `SoundScape.xcscheme`. Verify `xcodebuild test` builds the bundle. Verify `FavoritesServiceTests`, `AlarmTests`, `SleepContentTests`, `SleepRecordingTests`, `SoundRepositoryTests` all run.
2. Update `drift.config.yaml`: change test command to `xcodebuild test -only-testing:SoundScapeTests …` (so a single-failing test fails fast). Also remove or wrap the verifier `test` step so it doesn't always time out on currently-broken-by-design tests (until Phase 4 lands the missing seams).

**Acceptance criteria:** `xcodebuild test` exits 0. ≥5 test files green.

---

### Phase 1 — Inline shallow modules (high-leverage quick wins)

**Why second:** These deletions reduce the surface area before any deepening work. Less code = fewer places for refactor to go wrong.

**Issues:**

1. Inline `SoundRepository` + `SoundRepositoryProtocol`. Callers (`SoundsViewModel`) use `LocalSoundDataSource` directly. Update Tests that reference the protocol (currently `SoundRepositoryTests`).
2. Replace `AppearanceService` with `@AppStorage("oled_mode_enabled")`. Update consumers. Delete service file.
3. Convert `LocalSoundDataSource`, `LocalCommunityDataSource`, `LocalStoryDataSource`, `SoundScienceContent` to bundle JSON. Decode once at app launch into immutable arrays. Eliminate the per-call allocation fan-out.
4. Collapse `ReviewPromptService.recordSuccessfulSleepSession()`, `recordMixSaved()`, `recordFavoriteAction()` into one `recordPositiveAction(source:)` enum-tagged method. Remove `markAsDeclined()` no-op. Fix `YOUR_APP_STORE_ID` placeholder.
5. Delete `SavedMixRowView.swift` (confirmed dead code by the view-layer agent).
6. Decide on `SoundsViewModel`: either inline into `SoundsView` (preferred — saves one indirection level), or deepen by giving it real state (search/sort/sections).

**Acceptance criteria:** All `xcodebuild build` green, tests still pass, total file count reduced by ≥6.

---

### Phase 2 — Domain layer hygiene

**Why third:** Now the architecture is cleaner and tests run, we can move logic into the right layer without that work being buried under other refactors.

**Issues:**

1. Move `StoryCategory.color` (and similar UI extensions on Domain enums) to `Presentation/Stories/Extensions/StoryCategory+UI.swift`. `Story.swift` imports only `Foundation`.
2. Extract `SoundRecommendationUseCase` from `InsightsService`. Pure function: `[SleepSession] + [Sound] → [SoundRecommendation]`. Remove `Int.random` from `calculateQuality`; replace with deterministic quality-band mapping (or inject a `QualityStrategy`).
3. Extract `MixPlaybackUseCase` from `ServiceContainer.playSavedMix` / `playDefaultSleepMix`. Pure orchestration that takes an `AudioPlayerProtocol`.
4. Move `StoryProgressService`'s derived methods (`progressFraction`, `remainingTime`, `isCompleted`) onto `SleepContent` entity extensions. Keep the persistence side of the service.
5. Move `generateMockDataIfEmpty()` to `InsightsPreviewData.swift`, invoked only from `#Preview` blocks. Add a `DEBUG`-guarded debug-menu toggle for testing the populated state.

**Acceptance criteria:** `Domain/` contains zero `import SwiftUI`. `Domain/UseCases/SoundRecommendationUseCase.swift` exists with ≥1 test. No production codepath calls `generateMockDataIfEmpty`.

---

### Phase 3 — Composition root + real seams

**Why fourth:** Hardest. Touches every preview block and the App Intents process. Doing it after Phase 2 means use cases already exist to plug into the new root.

**Issues:**

1. Create `App/AppEnvironment.swift` — `@MainActor @Observable` root that constructs all services in dependency order via constructor injection.
2. Convert all `setX(_:)` setter calls to constructor parameters. Remove the setter methods.
3. Remove the `Optional @State` + `??` fallback pattern for `SleepTimerService` and `AdaptiveSessionService`.
4. Vend `AppEnvironment` via `@Environment`. Update `ContentView` and all views.
5. Update `ServiceContainer.shared` to vend the **same** singleton instance to App Intents — or document explicitly which services run cross-process and which don't.
6. Update all `#Preview` blocks (~15) to construct `AppEnvironment` with the new pattern.
7. Introduce `AudioPlayerProtocol` injection in `SleepTimerService`, `AdaptiveSessionService`, `ServiceContainer`. Real second adapter: `MockAudioEngine: AudioPlayerProtocol` in tests.

**Acceptance criteria:** `grep -r "setAnalyticsService\|setInsightsService\|setReviewPromptService" SoundScape/Sources/` returns zero. `SoundScapeApp.swift` has no `.onAppear` wiring block.

---

### Phase 4 — Testability seams + persistence seam

**Why fifth:** With composition root sane, we can introduce seams as adapters wired at the root. With seams in place, the rest of the test suite goes green.

**Issues:**

1. Introduce `KeyValueStore` protocol; refactor `FavoritesService`, `InsightsService`, `SavedMixesService` to accept it via init.
2. Introduce `DocumentStore` protocol; refactor `StoryProgressService`, `AlarmService`, `SleepRecordingService` to accept it via init.
3. Introduce `ClockProtocol`; replace inline `Date()` calls in `SleepTimerService.start()` and `InsightsService.recordSession()`.
4. Introduce `NotificationScheduler` protocol; refactor `AlarmService.scheduleNotifications` to use it. Guard `requestNotificationPermission()` behind an injectable permission requester.
5. Introduce `SoundResourceLoader` protocol wrapping `Bundle.main.url(forResource:...)`. Refactor `AudioEngine.play(sound:)` to use it.
6. Introduce `AudioSessionConfigurator` protocol wrapping `AVAudioSession.sharedInstance()` calls. Refactor `AudioEngine.init()`.
7. Get `SleepTimerServiceTests` (13 tests), `AlarmServiceTests` CRUD subset (15 tests), `InsightsServiceTests` (loose-assertion subset), and `AudioEngineTests` (empty-state subset) green.

**Acceptance criteria:** Test count green grows from 5 files to ≥10 files. Total green assertions ≥50.

---

### Phase 5 — View layer consolidation

**Why last:** The view layer churns the most during refactor; doing it last avoids fighting design changes against architectural changes simultaneously.

**Issues:**

1. Extract `EditorialChip` (Mixer X/SAVE/play/Stop, Timer DONE, SavedMixes close, NowPlayingBar chevron). 6+ call sites.
2. Extract `EditorialSheet` shell (NavigationStack + hidden nav bar + handle bar + header). 3 call sites.
3. Extract `TactilePressStyle` `ButtonStyle` to replace the 4 hand-rolled `@State isPressed + DragGesture` recipes.
4. Extract `EditorialVolumeSlider` (replacing the private in `MixerSoundRow` and the duplicate `BinauralVolumeSliderView`).
5. Extract `EditorialEmptyState`, `EditorialIndexNumeral`, `EditorialHairline`, `EditorialSparkline`.
6. Decide on legacy purple system: either migrate Insights/Discover/Alarms/Adaptive/BinauralBeats/Onboarding to Editorial Light, or revert the editorial-light pass entirely. Half-and-half ships. (Recommendation: complete the migration, since reverting wastes the recent investment.)
7. Add VoiceOver hooks to `OnboardingPaywallView` and `BinauralBeatsView` (currently zero hooks).
8. Refactor `SoundsView` (326 lines, 9 services) and `SavedMixesView` (instantiates `SoundRepository()` directly; nested `DispatchQueue.main.asyncAfter` for playback) to use the extracted components and the new use cases from Phase 2.

**Acceptance criteria:** Components Module has ≥8 new types. `grep -rn ".purple\|.indigo" SoundScape/Sources/Presentation/ | wc -l` returns 0 (or 1 — only `Tokens.swift`'s deprecated alias).

---

## Part 3 — Drift Intent (the input for `drift plan`)

```
Phase 0 of the soundScapeV3 architectural deepening refactor: wake the dormant XCTest target.

The codebase has 23 XCTest files in SoundScape/Tests/ that are fully wired in
project.pbxproj (TEST_HOST and BUNDLE_LOADER set correctly), but xcodebuild test
aborts because SoundScape.xcscheme's <BuildAction>/<BuildActionEntries> contains
only the app target — the test target is missing. Adding one <BuildActionEntry
buildForTesting="YES"> block referencing BlueprintIdentifier "FB96EB91000000Z1"
makes 5 test files (FavoritesServiceTests, AlarmTests, SleepContentTests,
SleepRecordingTests, SoundRepositoryTests) pass with zero code changes.

Reference: docs/research/testability-gaps.md for the full XML block and seam
catalog.

Constraints:
- No source changes in this plan. Only the .xcscheme file and drift.config.yaml.
- Update drift.config.yaml so its `test:` verifier command does NOT run the full
  test suite — only the five tests that are expected to pass. This unblocks
  drift's verifier for subsequent phases without failing on tests blocked by
  missing seams (those land in Phase 4).
- After this plan ships, the codebase has a working `xcodebuild test` for the
  first time. That is the entire deliverable.
```

(This is the intent text for `drift plan soundScapeV3 --auto --intent "..."`. Subsequent phases get their own drift plans with their own slugs.)

---

## Part 4 — Suggested slugs (for `.plan-notes/<slug>/`)

| Phase | Slug |
|---|---|
| 0 | `wake-xctest-target` |
| 1 | `inline-shallow-modules` |
| 2 | `domain-layer-hygiene` |
| 3 | `composition-root-deepening` |
| 4 | `testability-seams` |
| 5 | `view-layer-consolidation` |

Sequential — each plan starts only when the previous merges.

---

## Part 5 — Known risks

- **Memory note in user's MEMORY.md:** "soundScapeV3 has no XCTest target; final verifier always times out and reports aborted even when every issue ships." Phase 0 invalidates this memory — after merge, update the memory.
- **App Intents process** (`ServiceContainer.shared`) runs out-of-process; any composition-root refactor must mirror state correctly or Siri/Shortcuts will diverge. Phase 3 owns this.
- **`AudioEngine.fadeIn`/`fadeOut` cancellation token absence** causes audible glitches when refactoring playback paths. Phase 3 should introduce a `FadeTask` reference that gets cancelled on new playback events.
- **Preview blocks** (~15-20) need updating in Phase 3 — easy to miss, breaks compile.
- **Editorial Light tokens** are unfinished. Phase 5 must choose: complete or revert. Half-state is the worst outcome.
