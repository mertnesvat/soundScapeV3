# Architecture Layer Compliance — soundScapeV3

The project adopts Clean Architecture folder labels but does not enforce the dependency rule in code.
Business logic is scattered across Data-layer services, the Domain layer has one real protocol that goes
unused by most callers, and the composition root (`SoundScapeApp.swift`) wires 19 services ad-hoc with
deferred setter injection — a pattern that produces invisible ordering bugs.

---

## Findings

### Layer dependency violations

- **`Story.swift` (Domain entity) imports SwiftUI** (`SoundScape/Sources/Domain/Entities/Story.swift`, line 48 — `import SwiftUI` at the bottom, used for `Color` on `StoryCategory.color`). A Domain entity must not know about a UI framework.
- **`AdaptiveSessionService` depends on the concrete `SoundRepository` class**, not `SoundRepositoryProtocol` (`SoundScape/Sources/Data/Services/AdaptiveSessionService.swift`, line 15 — `private let soundRepository: SoundRepository`). The protocol exists but the internal seam is bypassed.
- **`AdaptiveSessionService` depends on the concrete `AudioEngine` class**, not `AudioPlayerProtocol` (line 14 — `private let audioEngine: AudioEngine`). `AudioPlayerProtocol` exists in Domain but is unused by every Data service.
- **`ServiceContainer` (App/Intents) bypasses `SoundRepositoryProtocol` entirely** (`SoundScape/Sources/App/Intents/ServiceContainer.swift`, lines 39-46), calling `LocalSoundDataSource.shared.getAllSounds()` directly — skipping two abstraction layers in one call.
- **`InsightsService` (Data) hard-codes a sound-name lookup dictionary** (`SoundScape/Sources/Data/Services/InsightsService.swift`, lines 14-26). Sound name resolution is domain knowledge that belongs in `Sound` entities or a use-case, not in the analytics service.

### Business logic in the wrong layer

- **Recommendation algorithm lives in `InsightsService` (Data)** (lines 128-177). The logic — scoring sounds by quality correlation, applying confidence thresholds, falling back to curated defaults — is domain-level policy. It has no I/O dependency and should be a pure Domain use case.
- **Sleep quality calculation (`calculateQuality`) is in `InsightsService`** (lines 200-206), using `Int.random` for quality scoring. Non-deterministic domain logic hidden in a Data service is untestable in isolation.
- **`ServiceContainer.playSavedMix` and `playDefaultSleepMix`** encode mix orchestration logic (stop-all, play-each, set-volume, hardcoded sound IDs `rain_storm`/`midnight_calm`) in the App Intents container (lines 56-84). This is a use-case body living at the composition root.
- **`AdaptiveSessionService`** owns the phase-timer loop, sound-transition logic, and progress calculations — all domain policy — inside a Data service.
- **`InsightsService.generateMockDataIfEmpty`** seeds production state with random fake sessions on init (lines 210-243). This is test-fixture code that runs in production.

### Repository / protocol usage

- `SoundRepositoryProtocol` has exactly one adapter (`SoundRepository`), which is a pass-through delegating every call to `LocalSoundDataSource`. Deletion test: delete `SoundRepository` and `SoundRepositoryProtocol` — callers would call `LocalSoundDataSource` directly (as `ServiceContainer` already does). The seam does not span a real variation axis; it is a hypothetical seam with no second adapter and no test double registered anywhere.
- `AudioPlayerProtocol` is defined in Domain but no service injects against it. All callers hold a concrete `AudioEngine`. The protocol earns no leverage.
- `FavoritesService`, `SavedMixesService`, `InsightsService`, `StoryProgressService`, `OnboardingService`, and `BinauralBeatEngine` have no protocols at all — they are injected as `@Environment` concretes. These are the most frequently tested-against modules (per the test files) yet they expose no seam for substitution.

### App composition root

- `SoundScapeApp.swift` instantiates 19 `@State` services (lines 7-27) and wires cross-service dependencies in `.onAppear` (lines 117-159) using post-init setter injection (`setAnalyticsService`, `setInsightsService`, `setReviewPromptService`). This is a two-phase construction anti-pattern: services are published to the environment in an un-wired state for the duration of the first render, and the `.onAppear` ordering is fragile.
- `SleepTimerService` and `AdaptiveSessionService` are `Optional` `@State` properties initialised to `nil` (lines 8-9) and vended via fallback helpers (`createSleepTimerService()`, line 165) to avoid an `init` ordering problem. This is a symptom of the composition root not having a coherent DI strategy.
- `ContentView` reads `AudioEngine` from `@Environment` as a concrete type and calls `audioEngine.activeSounds` and `audioEngine.isAnyPlaying` directly — bypassing `AudioPlayerProtocol`.

### What is missing

- **No use cases / interactors.** Every feature (recommendation, session recording, mix orchestration, adaptive phase progression) is expressed as methods on service objects that also own persistence. There is no layer separating "what the app does" from "how data is stored."
- **No Domain-level audio orchestration interface.** `AudioPlayerProtocol` exists but is never used as an injection seam by any concrete module.
- **No test doubles for any service.** Tests that exist (`InsightsServiceTests`, `SavedMixesServiceTests`, `FavoritesServiceTests`) test concrete classes directly with real `UserDefaults`/file I/O. No fake or stub adapters exist.

---

## Top Opportunities

### 1. Extract `SoundRecommendationUseCase` from `InsightsService`

**Files:** `SoundScape/Sources/Data/Services/InsightsService.swift` (lines 128-177, 200-206)

**Problem:** The recommendation algorithm and quality-scoring function are pure computation — no I/O — but live inside a `@Observable` Data service. They cannot be unit-tested without instantiating the full service and its UserDefaults dependency.

**Solution:** Create `SoundScape/Sources/Domain/UseCases/SoundRecommendationUseCase.swift`. Accept `[SleepSession]` and `[Sound]` as pure inputs; return `[SoundRecommendation]`. `InsightsService` calls the use case. `calculateQuality` becomes a deterministic function (remove `Int.random`; replace with a pure quality-band mapping or inject a `QualityStrategy`).

**Locality + Leverage:** Recommendation logic concentrates in one testable module. All future callers (widgets, Siri intents, a future Today Extension) exercise the same seam without re-instantiating the full service graph.

---

### 2. Wire `AudioPlayerProtocol` as the real injection seam

**Files:** `SoundScape/Sources/Domain/Protocols/AudioPlayerProtocol.swift`, `SoundScape/Sources/Data/Services/AdaptiveSessionService.swift` (line 14), `SoundScape/Sources/App/SoundScapeApp.swift` (line 7), `SoundScape/Sources/App/ContentView.swift`

**Problem:** `AudioPlayerProtocol` is defined but bypassed. Every Data service and view holds the concrete `AudioEngine`. There is no seam to substitute a silent adapter in tests, a Bluetooth-routed engine, or a background-only engine.

**Solution:** Change `AdaptiveSessionService`, `SleepTimerService`, and `ServiceContainer` to accept `any AudioPlayerProtocol`. Inject `AudioEngine` as the adapter at the composition root. Vend `any AudioPlayerProtocol` via `@Environment` key.

**Locality + Leverage:** One adapter swap covers the entire audio graph. Tests can inject a `MockAudioPlayer` with zero AVFoundation dependency.

---

### 3. Eliminate two-phase setter injection in `SoundScapeApp`

**Files:** `SoundScape/Sources/App/SoundScapeApp.swift` (lines 7-161)

**Problem:** Services are published to `@Environment` before cross-wiring happens in `.onAppear`. Any view that reads `InsightsService` during the first layout pass sees it without the `AudioEngine` link set. The `Optional`-with-fallback pattern for `SleepTimerService` and `AdaptiveSessionService` is a sign the construction order has broken down.

**Solution:** Create `SoundScape/Sources/App/AppEnvironment.swift` — a single `@Observable` root that constructs all services in dependency order in its `init`, using constructor injection throughout. Vend one `AppEnvironment` object via `@Environment`. Remove all `setX(_:)` setter methods from services.

**Locality + Leverage:** Construction order is visible and verifiable in one place. The fragile `.onAppear` wiring and `Optional` workarounds disappear. Previews and tests construct `AppEnvironment` with alternate adapters.

---

### 4. Remove SwiftUI import from `Story` (Domain entity)

**Files:** `SoundScape/Sources/Domain/Entities/Story.swift` (line 48), `StoryCategory.color` computed property

**Problem:** `StoryCategory.color` returns `Color`, pulling `SwiftUI` into the Domain layer. Domain entities must not import platform UI frameworks — this breaks the dependency rule and prevents testing without a UI host.

**Solution:** Move `StoryCategory.color` (and the equivalent on other enums that do this) to a `Presentation` extension file, e.g. `SoundScape/Sources/Presentation/Stories/Extensions/StoryCategory+UI.swift`. Domain `Story.swift` imports only `Foundation`.

**Locality + Leverage:** Domain entities become testable with `swift test` without a simulator. Any future non-UI consumer (a server-side Swift endpoint, a macOS CLI) can import Domain without dragging in SwiftUI.

---

### 5. Replace `SoundRepository` pass-through with direct `LocalSoundDataSource` access (or add a real second adapter)

**Files:** `SoundScape/Sources/Domain/Repositories/SoundRepositoryProtocol.swift`, `SoundScape/Sources/Data/Repositories/SoundRepository.swift`, `SoundScape/Sources/App/Intents/ServiceContainer.swift` (lines 39-46)

**Problem:** Deletion test on `SoundRepository` + `SoundRepositoryProtocol`: `ServiceContainer` already calls `LocalSoundDataSource.shared` directly (bypassing both), `AdaptiveSessionService` takes the concrete class (bypassing the protocol), and `SoundsViewModel` is the only caller that uses the protocol. The seam earns no leverage — one adapter, one real caller.

**Solution:** Either (a) delete the protocol and repository and have all callers use `LocalSoundDataSource` directly until there is a real second adapter (e.g. a remote or CloudKit source), or (b) commit to the seam: fix `AdaptiveSessionService` and `ServiceContainer` to accept `SoundRepositoryProtocol`, and add a `InMemorySoundRepository` test double. Option (a) is honest; option (b) earns the abstraction.

**Locality + Leverage:** Whichever path is chosen, the codebase stops lying about which abstraction is real.

---

## Risks of Refactoring

- **`@Observable` + `@Environment` threading.** `AudioEngine`, `InsightsService`, and most services are `@MainActor`. Introducing use cases that run off-actor (for testability) requires careful `await` boundaries; a naive extraction will produce `@MainActor`-isolation compile errors.
- **`ServiceContainer` is a second composition root.** App Intents run out-of-process. Any refactor to the main wiring must be mirrored in `ServiceContainer` or the Siri/Shortcuts integration will use stale concrete references.
- **`InsightsService.generateMockDataIfEmpty` ships to production.** Removing it (correct) will cause the Insights tab to appear empty for new installs until a real session is recorded. A separate `InsightsPreviewData` fixture for Xcode previews should replace it before deletion.
- **`SoundsViewModel` is the only module using `SoundRepositoryProtocol`.** Any cleanup of that seam must maintain the `SoundsViewModel` contract, which is the sole path the Sounds tab uses for sound listing.
- **Setter injection removal requires preview fixups.** Every `#Preview` block that passes services via `.environment(SomeService())` will need to be updated to use a new `AppEnvironment` or a composed mock graph. There are ~15 preview blocks across the codebase.
