# Testability Gaps — soundScapeV3

## Headline

The `SoundScapeTests` XCTest target exists in the pbxproj, all 23 test files are wired to it, and the scheme references it correctly — but `xcodebuild test` aborts because the scheme's `BuildAction` only lists the app target (`SoundScape`), not `SoundScapeTests`. The test target has no build entry in `BuildActionEntries`, so Xcode never builds it before trying to run it. The interface is the test surface, and the surface is almost entirely reachable — the blocking work is thin infrastructure plumbing, not test rewrites.

---

## XCTest Target Situation

### What exists

- `PBXNativeTarget` `FB96EB91000000Z1 /* SoundScapeTests */` at pbxproj line 1257. Product type is `com.apple.product-type.bundle.unit-test`. It declares a dependency on the app target (`PBXTargetDependency FB96EB91000000Z4`).
- `TEST_HOST` and `BUNDLE_LOADER` are correctly set in both Debug and Release build configs (pbxproj lines 1811-1825, 1831-1846). They point to `$(BUILT_PRODUCTS_DIR)/SoundScape.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SoundScape`.
- The `PBXSourcesBuildPhase` `FB96EB91000000Z2` (pbxproj line 1564) lists all 23 test files.
- `SoundScape.xcscheme` references the test target in `<TestAction>/<Testables>` (scheme line 36-43), and `shouldAutocreateTestPlan = "YES"`.

### What is missing — the actual breakage

The `<BuildAction>/<BuildActionEntries>` block in `SoundScape.xcscheme` contains **only one entry**: `SoundScape.app` (`BlueprintIdentifier = "FB96EB9100000060"`). `SoundScapeTests` (`BlueprintIdentifier = "FB96EB91000000Z1"`) is absent from `BuildActionEntries` entirely (scheme lines 8-25). When `xcodebuild test` runs, the scheme tells Xcode what to build for testing; with the test target absent from build entries, xcodebuild finds nothing to build for the test action and aborts.

**Fix:** add a `<BuildActionEntry buildForTesting="YES">` block for `SoundScapeTests` to `SoundScape.xcscheme`. No source changes.

```xml
<BuildActionEntry
   buildForTesting = "YES"
   buildForRunning = "NO"
   buildForProfiling = "NO"
   buildForArchiving = "NO"
   buildForAnalyzing = "NO">
   <BuildableReference
      BuildableIdentifier = "primary"
      BlueprintIdentifier = "FB96EB91000000Z1"
      BuildableName = "SoundScapeTests.xctest"
      BlueprintName = "SoundScapeTests"
      ReferencedContainer = "container:SoundScape.xcodeproj">
   </BuildableReference>
</BuildActionEntry>
```

---

## Existing Test Files: Real vs Stubs

All 23 files use `@testable import SoundScape` and `XCTestCase`. None are stubs.

### Solid, would pass without code changes (given target fix)

- `FavoritesServiceTests.swift` — persistence round-trip via `UserDefaults`, toggle semantics, edge cases
- `AlarmTests.swift` — pure value-type assertions on `Alarm` entity
- `SleepContentTests.swift` — pure data assertions on `SleepContent` entities
- `SleepRecordingTests.swift` — pure value-type assertions on `SleepRecording` model
- `SoundRepositoryTests.swift` — exercises `SoundRepository` via `SoundRepositoryProtocol` seam

### Real tests with one runtime blocker each

- `SleepTimerServiceTests.swift` — blocked by `SleepTimerService.init(audioEngine:)` taking a concrete `AudioEngine`. `AudioPlayerProtocol` already exists in Domain.
- `AlarmServiceTests.swift` — blocked by `AlarmService.init()` calling `UNUserNotificationCenter.current().requestAuthorization(...)` unconditionally
- `InsightsServiceTests.swift` — blocked by `Date()` inline + `generateMockDataIfEmpty()` in init seeding state non-deterministically
- `AudioEngineTests.swift` — `Bundle.main.url(forResource:...)` fails in test target because audio bundle resources belong to app bundle (latent blocker; the listed tests never call `play()`)

### Blocked by framework dependencies

- `SubscriptionServiceTests.swift`, `PaywallServiceTests.swift`, `PremiumManagerTests.swift` — StoreKit/RevenueCat singletons
- `SleepRecordingServiceTests.swift`, `SoundEventDetectorTests.swift` — `AVAudioEngine` / microphone permission
- `AppDelegateTests.swift`, `AlarmNotificationSoundManagerTests.swift` — `UNUserNotificationCenter` / `AVAudioSession` at init time

---

## Top 5 Services Ranked by Ease of Getting One Test Green

1. **FavoritesService** — easiest. Interface is `toggleFavorite(_:)`, `isFavorite(_:)`, `favoritedIds`. Only side effect is `UserDefaults.standard`, which tests already clear. Zero seams needed.

2. **AlarmService (arithmetic subset)** — `remainingNotificationSlots` is pure arithmetic. `test_init_startsWithEmptyAlarms`, `test_addAlarm_sortsByTime`, `test_remainingNotificationSlots_noAlarms_returns64` would all pass because they never trigger `scheduleNotifications`. Adapter missing: `NotificationScheduler` protocol seam.

3. **SleepTimerService** — pure state management. The blocker is one-line type change: `private let audioEngine: AudioEngine` → `private let audioEngine: AudioPlayerProtocol`. The protocol already exists at `/Sources/Domain/Protocols/AudioPlayerProtocol.swift`. Then tests inject `MockAudioEngine: AudioPlayerProtocol`.

4. **InsightsService (stats subset)** — `averageDuration`, `averageQuality`, `goalProgress` are computed properties. Blocker: `generateMockDataIfEmpty()` in init pre-seeds sessions. Loose-enough assertions in current tests would pass anyway.

5. **LocalSoundDataSource** — pure hardcoded catalogue, no I/O, no framework calls. Tests would pass unconditionally after the scheme fix. Zero missing seams.

---

## Missing Seams Catalog

| Seam | Where Missing | What to Introduce |
|---|---|---|
| **Clock / time provider** | `SleepTimerService.start()`, `InsightsService.recordSession()` use `Date()` inline | `protocol ClockProtocol { func now() -> Date }` injected at init |
| **AudioPlayerProtocol in SleepTimerService** | `private let audioEngine: AudioEngine` (concrete) | Change to `AudioPlayerProtocol` — protocol exists, just unused |
| **Notification scheduler** | `AlarmService.scheduleNotifications(for:)` calls `UNUserNotificationCenter.current()` directly | `protocol NotificationScheduler` with `schedule(request:)` / `removePending(identifiers:)` |
| **UserNotifications permission** | `AlarmService.init()` calls `requestNotificationPermission()` unconditionally | Injectable `NotificationPermissionRequester` protocol |
| **AVAudioSession** | `AudioEngine.init()` calls `configureAudioSession()` → `AVAudioSession.sharedInstance().setActive(true)` | `protocol AudioSessionConfigurator` |
| **Bundle / resource lookup** | `AudioEngine.play(sound:)` uses `Bundle.main.url(forResource:...)` | `protocol SoundResourceLoader { func url(for fileName: String) -> URL? }` |
| **UserDefaults isolation** | `FavoritesService`, `InsightsService`, `SavedMixesService` hardcode `UserDefaults.standard` | Injectable `UserDefaults` at init with default `= .standard` |
| **WidgetKit static call** | `SleepTimerService` calls `WidgetSharedState.updateTimerState(...)` as a static side effect | `protocol WidgetStateUpdater` |

---

## Recommended Path

### Step 1: Fix the scheme (15 minutes, zero code change)

Add the `<BuildActionEntry>` above to `SoundScape.xcscheme`. After this, `xcodebuild test` builds the test bundle.

### Step 2: Three priority tests to get green first

**Priority 1 — `FavoritesServiceTests.swift` (all 9 tests).** Zero code changes after scheme fix. Highest leverage per line.

**Priority 2 — `SleepTimerServiceTests.swift` (state tests only).** One production change: `AudioEngine` → `AudioPlayerProtocol` parameter type. Add `MockAudioEngine: AudioPlayerProtocol` in test target (15 lines). 13 tests pass.

**Priority 3 — `AlarmServiceTests.swift` (CRUD + slot-arithmetic subset).** Wrap `scheduleNotifications` behind an injectable `NotificationScheduler` seam. 15 tests pass.

### What to defer

`AudioEngineTests` (needs `AVAudioSession` and `Bundle.main` seams), `SleepRecordingServiceTests` (microphone), `SubscriptionServiceTests` / `PaywallServiceTests` (StoreKit). Deeper adapter work, lower leverage relative to the above.

---

## Essential Files

- `/SoundScape/SoundScape.xcodeproj/xcshareddata/xcschemes/SoundScape.xcscheme` — root cause of `xcodebuild test` abort
- `/SoundScape/SoundScape.xcodeproj/project.pbxproj` lines 1257-1272, 1564-1592 — target fully wired in project graph
- `/SoundScape/Sources/Domain/Protocols/AudioPlayerProtocol.swift` — existing seam that `SleepTimerService` should use
- `/SoundScape/Sources/Data/Services/SleepTimerService.swift` line 17 — one line blocking test injection
- `/SoundScape/Sources/Data/Services/AudioEngine.swift` lines 29-33 (`init()`) and line 172 (`Bundle.main`) — two concrete dependencies
- `/SoundScape/Sources/Data/Services/AlarmService.swift` lines 34-40 — `init()` has three side effects
- `/SoundScape/Sources/Data/Services/FavoritesService.swift` — best existing test surface; only `UserDefaults.standard` dependency
- `/SoundScape/Tests/FavoritesServiceTests.swift` — all tests pass unconditionally after scheme fix
- `/SoundScape/Tests/SleepTimerServiceTests.swift` — real tests; would pass after protocol seam change
- `/SoundScape/Tests/AlarmServiceTests.swift` — CRUD subset would pass once scheduling side effect is suppressed
