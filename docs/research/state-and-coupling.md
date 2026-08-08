# State Management & Service Coupling — soundScapeV3

## Headline

soundScapeV3 currently runs **22 `@Observable` services as a flat, app-scoped graph** glued together through SwiftUI's `.environment(_:)` and a hand-wired post-init phase inside `SoundScapeApp.body.onAppear`. There is essentially **one Module** — every service knows it can be reached by every view, and several services know each other through `weak`/optional concrete references injected via `set…Service` methods rather than through Interfaces. Two Interfaces exist on paper (`AudioPlayerProtocol`, `SoundRepositoryProtocol`), but each has exactly one Adapter, so they are **hypothetical seams, not real seams**. The result is a tightly coupled core where `AudioEngine` is the de facto God Object — touched by 6+ services and ~10 views — and the only Adapter-substitution capability that exists today (tests) lives on top of zero real seams.

## Service Inventory

| Service | Lines | MainActor | Holds Mutable State | Read From | Written From | Concrete Couplings (out) | Adapter Count |
|---|---|---|---|---|---|---|---|
| `AudioEngine` | 505 | yes | `players`, `activeSounds`, `sessionStartTime`, `listeningMilestonesHit` | 10+ views, `SoundsViewModel`, 3 App Intents, `SleepTimerService`, `AdaptiveSessionService`, `SleepRecordingService` | 5+ views, 3 App Intents, `SleepTimerService`, `AdaptiveSessionService`, `SleepRecordingService`, `ServiceContainer` | `InsightsService?`, `AnalyticsService?`, `ReviewPromptService?`, `WidgetSharedState` (static), `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`, `AVAudioSession` | 1 (`AudioPlayerProtocol`) — hypothetical |
| `SleepTimerService` | 129 | yes | `isActive`, `remainingSeconds`, `originalVolumes` | `SleepTimerView` | `SleepTimerView`, `SetSleepTimerIntent` | `AudioEngine` (concrete, ctor), `AnalyticsService?`, `WidgetSharedState` (static) | 0 — concrete dep on `AudioEngine` |
| `AdaptiveSessionService` | 139 | yes | `isActive`, `currentMode`, `phaseTimeRemaining` | `AdaptiveView` | `AdaptiveView` | `AudioEngine` (concrete, ctor), `SoundRepository` (concrete default) | 0 — concrete deps |
| `InsightsService` | 278 | no (!) | `sessions`, `sleepGoal`, `sessionStartTime` | `InsightsView`, `SleepBuddyService` | `AudioEngine`, `InsightsView` | UserDefaults | 0 |
| `FavoritesService` | 49 | yes | `favoritedIds: Set<String>` | many views, `SoundsViewModel` | many views | `AnalyticsService?`, `ReviewPromptService?` | 0 |
| `SavedMixesService` | 71 | yes | `mixes: [SavedMix]` | many views, App Intents | many views | `AnalyticsService?`, `ReviewPromptService?`, FileManager | 0 |
| `StoryProgressService` | 66 | no (!) | `progress: [String:TimeInterval]` | `SleepContentPlayerService`, views | `SleepContentPlayerService`, views | UserDefaults | 0 |
| `BinauralBeatEngine` | 211 | yes | `isPlaying`, `brainwaveState`, phase accumulators | `BinauralBeatsView` | `BinauralBeatsView` | none cross-service | 0 |
| `AlarmService` | 442 | yes | `alarms`, `ringingAlarm`, `audioPlayer`, `currentVolume` | `AlarmsView`, `AlarmRingingView` | views, AppDelegate (via NotificationCenter) | `AlarmNotificationSoundManager.shared`, `LocalSoundDataSource.shared` (direct!), `UNUserNotificationCenter`, `AVAudioSession` | 0 |
| `SubscriptionService` | 403 | yes | `products`, `subscriptionStatus`, `isPremium`, `isPurchaseInProgress` | `PaywallService`, many views | StoreKit, internal | StoreKit `Product`/`Transaction`, UserDefaults | 0 |
| `PaywallService` | 196 | yes | `showPaywall`, `paywallShownThisSession`, `appSessionCount` | many views, `PremiumManager` | views, `SoundScapeApp.onAppear` | `SubscriptionService?` (concrete), `AnalyticsService?`, UserDefaults | 0 |
| `PremiumManager` | 208 | yes | (pure policy, no state) | many views | none | `PaywallService` (ctor, concrete) | 0 |
| `OnboardingService` | 85 | yes | `profile` | views | views | UserDefaults | 0 |
| `SleepRecordingService` | 385 | yes | `status`, `recordings`, `currentRecording`, `currentDecibels` | recording views | views | `AudioEngine?`, `AnalyticsService?`, `SoundEventDetector` (constructed inline), FileManager | 0 |
| `SleepContentPlayerService` | 534 | yes (NSObject) | `currentContent`, `isPlaying`, `currentTime`, `isTimerActive` | `ContentView`, content views | views | `StoryProgressService?`, `AnalyticsService?`, `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`, `AVAudioSession` | 0 |
| `SleepBuddyService` | 323 | no (!) | `buddy`, `myProfile`, `pendingInvite` | views | views | `weak InsightsService?` | 0 |
| `AnalyticsService` | 1040 | yes | (event log only; Firebase-side state) | every service, every view | every service, every view | Firebase Analytics global | 0 |
| `ReviewPromptService` | 174 | yes | `sessionCount`, `lastPromptDate`, `hasUserRated` | services | `AudioEngine`, `FavoritesService`, `SavedMixesService` | `AnalyticsService?`, `SKStoreReviewController`, UserDefaults | 0 |
| `MotionService` | 110 | yes | `roll`, `pitch`, `isUpdating` | views (e.g. parallax) | views | `CMMotionManager` | 0 |
| `AppearanceService` | 32 | yes | `isOLEDModeEnabled` | views, `ContentView` | views | UserDefaults | 0 |
| `WidgetSharedState` | 107 | n/a (static) | (App Group UserDefaults) | widget, app | `AudioEngine`, `SleepTimerService` | App Group UserDefaults, `WidgetCenter.shared` | 0 |
| `SoundRepository` | 22 | no | (pure) | `AdaptiveSessionService`, `SoundsViewModel`, `LocalSoundDataSource.shared` directly elsewhere | none | `LocalSoundDataSource.shared` | 1 (`SoundRepositoryProtocol`) — hypothetical |

Notes captured during the read:
- `InsightsService`, `StoryProgressService`, `SleepBuddyService` are **not annotated `@MainActor`** despite being `@Observable` and consumed from `@MainActor` views and services. They're called from `AudioEngine` (which is `@MainActor`) without isolation hopping, which works in practice but is a future Swift 6 strict-concurrency footgun.
- `AlarmService` and `SleepRecordingService` both declare `nonisolated(unsafe) private var ... observer: Any?` to hold NotificationCenter tokens — explicit acknowledgement of an isolation gap.
- `SleepContentPlayerService` extends `NSObject` with `nonisolated` AVAudioPlayerDelegate callbacks that thunk back via `Task { @MainActor in ... }`. Pattern works but is duplicated in `AudioEngine`.

## Hypothetical vs Real Seams

> **Rule:** one Adapter = hypothetical seam. Two Adapters = real seam.

### Hypothetical seams (Interface exists, single Adapter)

1. **`AudioPlayerProtocol` → `AudioEngine`.** The protocol exists (`Sources/Domain/Protocols/AudioPlayerProtocol.swift`), but every dependent (`SleepTimerService`, `AdaptiveSessionService`, `SleepRecordingService`, every view that injects audio, and the `ServiceContainer` for App Intents) holds the concrete `AudioEngine`. Worse, the protocol covers only the playback subset — clients also call `audioEngine.activeSounds` (vended by the protocol), but the timer reads `audioEngine.setVolume(...)` and reaches in for state cleanup that isn't on the protocol. The Interface exists but no caller actually depends on it.
2. **`SoundRepositoryProtocol` → `SoundRepository`.** `SoundsViewModel` depends on the protocol in its initializer signature, but the default-argument concrete (`SoundRepository()`) is what production uses. `AdaptiveSessionService` takes the concrete `SoundRepository` directly. The Interface exists and has exactly one user with one Adapter.

### Missing seams (where a real seam *should* exist but does not)

3. **Persistence.** Twelve services persist independently via `UserDefaults.standard.*` or per-service JSON files in `Documents/`. There is **no** `KeyValueStore`, `KeyedFileStore`, or `Persistence` Interface. Tests cannot inject an in-memory store; they must register a custom `UserDefaults(suiteName:)` (which only `SubscriptionService` accepts via ctor — the only persistence-aware seam in the codebase) and clear it between runs, or live with cross-test bleed. **One concrete Adapter (UserDefaults.standard or fileURL), zero seam.**
4. **Analytics sink.** Every service holds a `private var analyticsService: AnalyticsService?` set via `setAnalyticsService(_:)`, but the Implementation depends on Firebase. There's no `AnalyticsRecorder` Interface, so the only way to unit-test "did service X emit event Y?" is by stubbing Firebase at the SDK level. **One concrete coupling per service, no seam.**
5. **Review prompt sink.** Same shape as analytics — three services (`AudioEngine`, `FavoritesService`, `SavedMixesService`) hold `var reviewPromptService: ReviewPromptService?`. No Interface. **Hypothetical seam waiting to be born.**
6. **Widget bridge.** `WidgetSharedState` is a static struct used by both `AudioEngine` and `SleepTimerService`. From the audio side, calls go through five static `update*` methods that internally `load() → mutate → save() → WidgetCenter.shared.reloadAllTimelines()`. **No injected Interface; no way to test that AudioEngine "publishes" the right widget state without poking real App Group UserDefaults.**
7. **System integrations (`AVAudioSession`, `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`, `UNUserNotificationCenter`, `WidgetCenter`).** All accessed via `.shared` / `.default` singletons inside the services. No Interface, no seam.

### Real seam (Interface + multiple Adapters)

I could not find a single Interface in this codebase with two Adapters. The closest is `UserDefaults` injection on `SubscriptionService`, which is a single dependency type with two instances (production vs test) — that's a **parameter seam on a Foundation type**, not a project-defined Interface with multiple Implementations. Zero real seams.

## Top 3 Coupling Pain Points & Deepening Suggestions

### Pain point 1 — `AudioEngine` is the central hub for too many concerns

**Locality is poor.** `AudioEngine` mixes five responsibilities in one 505-line file: (a) AVAudioPlayer lifecycle and crossfades, (b) `AVAudioSession` configuration, (c) MPRemoteCommandCenter wiring, (d) Now Playing info center updates, (e) session-tracking side effects (insights record, analytics events, review prompts, listening-milestone Timer). The state surface that other services read (`activeSounds`, `isAnyPlaying`) is intermixed with the state nobody outside should touch (`sessionStartTime`, `listeningMilestonesHit`, `wasPlayingBeforeInterruption`).

The Depth of `AudioEngine` is low: callers must understand crossfades, milestone tracking, and audio-session category choices simultaneously. The fact that `AudioEngine` exposes `stopAllFromTimer(timerDuration:)` — a verb that only makes sense from the timer's perspective — is the smoking gun. That method exists because the timer needs to attribute the session duration correctly, so it needed to reach behind the playback API to mutate insights/analytics on the engine's behalf. That's a leaked seam.

**Deepening:**
- Split `AudioEngine` into `MixerEngine` (pure AVAudioPlayer + activeSounds + crossfades, the Implementation behind `AudioPlayerProtocol`), `NowPlayingPublisher` (MPRemoteCommandCenter + MPNowPlayingInfoCenter wiring), and `ListeningSessionRecorder` (the milestone Timer + insights/analytics fan-out).
- Make the Interface (`AudioPlayerProtocol`) actually carry every method clients use today (including `setVolume(_:for:)` and `activeSounds` snapshots) so `SleepTimerService` and `AdaptiveSessionService` can switch off the concrete type. Once that's true, a `MockAudioPlayer` becomes the second Adapter and the seam becomes real.
- Move the cross-service fan-out (`insightsService?.startSession()`, `analyticsService?.logSoundPlayed(...)`, `reviewPromptService?.recordSuccessfulSleepSession()`) out of the engine and into `ListeningSessionRecorder`, which subscribes to `MixerEngine` events (either via a Combine publisher or a `nonisolated` callback). The engine should not know that "insights" exists.

### Pain point 2 — Post-init wiring in `SoundScapeApp.onAppear` is fragile and order-dependent

**Locality is split** between three places that all have to stay in sync:
1. The `@State` declarations at the top of `SoundScapeApp` (which decide whether a service is eagerly or lazily created).
2. The `.environment(_:)` chain in `body` (which decides whether the view tree sees `nil` placeholder values).
3. The 40+ lines inside `.onAppear` that call `setAnalyticsService`, `setReviewPromptService`, `setInsightsService`, `setAudioEngine`, `setSubscriptionService`, `setPaywallPlacement`, etc.

Three services (`sleepTimerService`, `adaptiveSessionService`, `premiumManager`) are `@State Optional` because they depend on `audioEngine` / `paywallService` and SwiftUI can't construct dependent `@State` properties in declarator order. The workaround is the `?? createSleepTimerService()` fallback in the `.environment` chain plus a separate `if sleepTimerService == nil { ... }` initializer inside `onAppear`. **The same service may be constructed twice on cold start** — once by the `??` fallback when the view first renders (which `.environment` captures) and again by the `onAppear` assignment (which never reaches the view since the env value is already captured). That second instance silently leaks; whichever one was first captured is the one the view actually sees, but `onAppear` then mutates the late copy by calling `setAnalyticsService`. The eagerly-created one (the one views use) has `analyticsService = nil`.

Additionally, every `set…Service(_:)` setter is post-init mutation that can race with the first read. `audioEngine.setInsightsService(insightsService)` happens in `onAppear`, but the user can tap a sound before `onAppear` fires (e.g. via an App Intent that uses `ServiceContainer.shared` — a separate singleton graph!). For the first session, `insightsService` is `nil` inside the engine and the session is never recorded.

**Deepening:**
- Replace the 22 `@State` properties with a single `AppComposition` value type that constructs every service eagerly and in dependency order, then expose it as one `.environment(\.composition, …)` key. Views pull `composition.audioPlayer`, `composition.timer`, etc.
- Use **constructor injection only**; delete every `set…Service(_:)` method. Services that depend on `Analytics` take it in `init`. This forces the dependency graph to be a DAG at composition time and makes the order explicit rather than implicit-via-onAppear-order.
- Collapse `ServiceContainer.shared` (App Intents) and `SoundScapeApp` state into one composition path so intents and the SwiftUI tree share the same instances. Today they don't — `ServiceContainer.shared` constructs its **own** `AudioEngine`, `InsightsService`, `SavedMixesService`, etc., so playback started via Siri and playback started via the UI track different state and emit analytics from different services.

### Pain point 3 — Persistence is duplicated 12 times with no seam

Each service rolls its own load/save:
- `UserDefaults.standard.data(forKey:)` + `JSONDecoder` → `OnboardingService`, `StoryProgressService`, `FavoritesService`, `SleepBuddyService`, `InsightsService`, `AppearanceService`, `PaywallService`, `ReviewPromptService`.
- `FileManager.default.urls(for:.documentDirectory…)` + `JSONEncoder` → `SavedMixesService` (`saved_mixes.json`), `AlarmService` (`alarms.json`), `SleepRecordingService` (`sleep_recordings.json`), `SleepRecordingService` audio files (`SleepRecordings/`).
- `UserDefaults(suiteName: appGroupIdentifier)` → `WidgetSharedState`.
- `userDefaults.set(...)` with ctor-injected store → `SubscriptionService` (the only persistence-aware service).

**Leverage is wasted.** Twelve copies of "encode to JSON, write to disk, log on error" with subtly different error handling (some `print`, some swallow silently, some return). Tests that need to seed state (e.g. "user has 7-day streak") have to know each service's exact persistence shape and mimic it on disk.

**Deepening:**
- Introduce a small `KeyValueStore` Interface (`get<T: Codable>(_:)`, `set<T: Codable>(_:forKey:)`, `remove(_:)`) and a `DocumentStore` Interface (`load<T: Codable>(named:) -> T?`, `save<T: Codable>(_:named:)`). Production Adapters: `UserDefaultsStore(suite:)` and `FileManagerDocumentStore(directory:)`. Test Adapter: `InMemoryStore`. **Now the Interface has two Adapters → real seam.** Every service takes one of these in its initializer.
- Centralize "where is X persisted?" so any single migration (e.g. moving favorites from `UserDefaults` to an App Group for widget access) touches one place, not 12.
- Once `KeyValueStore` exists, `SubscriptionService`'s ctor-injected `UserDefaults` and `OnboardingService`'s hard-coded `UserDefaults.standard` look the same to their callers — and previewable, testable, swappable.

## Concurrency Risks

- **Three services are not `@MainActor`** despite holding mutable state read from `@MainActor` consumers: `InsightsService`, `StoryProgressService`, `SleepBuddyService`. Today they're effectively pinned to the main thread because every caller already is, but the *type system does not enforce it*. Under Swift 6 strict concurrency this becomes a wall of warnings; under stress it's a latent race (e.g. `InsightsService.sessions.append(session)` called from `AudioEngine.stopAll()` while `InsightsView` reads `sessions` is fine today but unprotected in principle).
- **`AudioEngine.fadeIn/fadeOut` schedule 20 `DispatchQueue.main.asyncAfter` blocks each.** Calling `stop(soundId:)` then `play(sound:)` on the same id within 300ms (rapid taps) interleaves two fade chains writing to the same `player.volume`. The completion callback for the fade-out then removes the sound the new play just added. There's no fade-token / generation counter to guard against this.
- **`Timer.scheduledTimer(...)` is used in 8 services** (timer service, adaptive, recording, listening-milestone, content player, alarm volume ramp, alarm chains, …). Each one captures `[weak self]` and dispatches into `Task { @MainActor in self?.tick() }`. Functionally correct but heavy — eight independent timers ticking once per second on the main actor whenever those features are active.
- **`Task.detached` in `SoundScapeApp.onAppear`** runs `AlarmNotificationSoundManager.shared.prepareAllAlarmSounds()` off-actor. `prepareAllAlarmSounds` likely writes files; it's not protected by anything obvious. Worth auditing whether the file paths it produces are read concurrently by `AlarmService.scheduleNotifications` during launch.
- **`AudioEngine.handleAudioInterruption` is `@objc`** and re-enters via `Task { @MainActor in ... }`. Combined with the rapid-tap fade race above, an interruption arriving mid-fade can land `pauseAll()` and `resumeAll()` in unexpected orders relative to the pending `asyncAfter` blocks.
- **Two `@MainActor` final classes use `nonisolated(unsafe)`** for NotificationCenter observer tokens (`AlarmService`, `SleepRecordingService`) — a deliberate hole. Fine in practice (Foundation guarantees), but worth documenting in CONTEXT.md so future changes don't quietly remove it.
- **App Intents path is a parallel composition root.** `ServiceContainer.shared` constructs its own `AudioEngine`/`SavedMixesService`/`InsightsService`/`AnalyticsService` and is never reconciled with the SwiftUI tree's instances. Concurrent intent invocation and UI interaction will mutate disjoint state. This isn't a "race" in the data-race sense; it's a correctness bug waiting for a user to say "Hey Siri, stop sounds" while the UI is showing playing sounds.

## What the architecture refactor should target

In one sentence, in the vocabulary requested: **soundScapeV3 is one Module pretending to be many services, with zero real seams, depth concentrated in `AudioEngine`, and locality fragmented across `SoundScapeApp.onAppear` and `ServiceContainer.shared`.** The highest-leverage moves are (1) deepening `AudioEngine` by splitting it and making `AudioPlayerProtocol` the contract everyone uses, (2) collapsing the SwiftUI and App Intents composition roots into a single eager DAG that constructor-injects, and (3) introducing `KeyValueStore`/`DocumentStore` Interfaces so persistence becomes the codebase's first real seam.
