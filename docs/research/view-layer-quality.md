# View-Layer Quality Audit — Presentation Module

**Headline.** The Presentation Module is two codebases coexisting under one folder: a recent "Editorial Light System" pass on 6 in-scope screens that re-implemented the same shell pattern six times instead of building one reusable Implementation, and a frozen Legacy Module (Insights/Discover/Stories/Alarms/Adaptive/Onboarding) still painted in purple `Color.purple` and `Color(.systemGray*)` literals. There are essentially zero real Seams between Views and design primitives: a `Tokens` Interface exists but Views inline magic font sizes (`size: 34/48/56/96`) and hand-roll the same outlined-square chip, tactile-press gesture, sheet header, and empty-state from scratch in every file. Components are not yet a Module — they are a junk drawer with one mounted member (`NowPlayingBarView`).

---

## 1. Duplication inventory (high-confidence)

### 1.1 Tactile press gesture (4 hand-rolled call sites)
The "press scale 0.97 + Tokens.tactilePress spring" recipe is reimplemented inline:

- `Presentation/SavedMixes/Views/SavedMixesView.swift:224-232` — `@State isPressed` + `DragGesture(minimumDistance: 0)` + `scaleEffect` + `animation`
- `Presentation/Components/NowPlayingBarView.swift:33-44, 66-75` — two copies in one file (bar + playPauseChip)
- `Presentation/Sounds/Views/SoundCardView.swift:101-108` — wrapped in private `EditorialTilePressStyle: ButtonStyle`
- `Presentation/WindDown/Components/SleepContentCardView.swift:156` — same scale value

This is a textbook case for **two adapters = real seam**: the press recipe is repeated four times with the same `0.97 / Tokens.tactilePress` pair, but no `Tokens.pressScale` token and no shared `ButtonStyle` Interface. `EditorialTilePressStyle` is `private` and trapped in `SoundCardView.swift`; promoting it to the Components Module would let three call sites collapse to `.buttonStyle(.editorialTile)`.

### 1.2 Ink-outlined square chip (≥ 6 inline reimplementations)
The "36×36 rounded-rect, 1.5pt ink stroke, ink icon" affordance appears with subtly different padding/radius in:

- `Mixer/Views/MixerView.swift:79-87` (close X), `:122-126` (SAVE MIX), `:141-145` (play/pause), `:156-161` (Stop — filled ink variant)
- `Timer/Views/SleepTimerView.swift:84-90` (DONE)
- `Mixer/Views/MixerSoundRowView.swift:70-75` (remove)
- `SavedMixes/Views/SavedMixesView.swift:60-66` (close — chevron variant)
- `Components/NowPlayingBarView.swift:96-110` (Circle stroke variant)

Each variant slightly tweaks corner-radius (`8` vs `16`), stroke width (`1`/`1.5`), and inner padding. No `EditorialChip` component exists. This single missing Interface is the largest source of visual drift and the highest-Leverage extraction.

### 1.3 Custom slider implementations (2 incompatible copies)
- `Mixer/Views/MixerSoundRowView.swift:97-148` — `private struct EditorialVolumeSlider` (orange fill / ink thumb)
- `BinauralBeats/Views/BinauralBeatsView.swift:305` — `BinauralVolumeSliderView` (separate dialect)

Plus stock `Slider` in `BinauralBeatsView.swift:328` and `StoryPlayerView.swift:109`. Four ways to render volume.

### 1.4 Empty-state pattern (4 inline copies + ContentUnavailableView mix)
The `Spacer / Image(48pt) / Text("No X") / Text(description)` recipe is duplicated inline in `MixerView.swift:206-224`, `SavedMixesView.swift:105-122`, `SoundsView.swift:186-191`, with parallel `ContentUnavailableView` calls in `AlarmsView.swift:11`, `FavoritesView.swift:48`, `SoundsView.swift:186`, `SleepRecordingView.swift:68`. Two conventions exist in the same Module.

### 1.5 Sheet shell (Mixer / Timer / SavedMixes)
All three editorial sheets reimplement the same shell from scratch:

```
NavigationStack { VStack(spacing: 0) {
    <hand-rolled header with sheet title + close button>
    <body>
} .background(Tokens.colorCream.ignoresSafeArea())
  .toolbar(.hidden, for: .navigationBar) }
```

`SavedMixesView.swift:20-32`, `MixerView.swift:29-52`, `SleepTimerView.swift:38-66`. Same structural triad, three implementations. None declare `.presentationDetents` (DESIGN.md §3.3 mandates `.large` for the mixer). No shared `EditorialSheet { … }` shell Adapter exists.

### 1.6 Paywall-gated tap orchestration
`SoundsView.swift:286-310` and `FavoritesView.swift:62-81` carry identical `isLocked / wouldExceedMixerLimit / paywallService.triggerPaywall(...)` branching inline in the View body. The same `freeSoundLimit = 6` constant is declared in three places (`SoundsView`, `FavoritesView`, `MixerView`).

### 1.7 Numbered editorial row prefix
`SoundCardView.swift:19-22`, `MixerSoundRowView.swift:30-32`, `SavedMixesView.swift:168-170` each redefine `String(format: "%02d", max(0, index))` and pair it with the display numeral. The pattern is verbatim three times.

---

## 2. Components to extract

These are reusable Implementations hiding inside feature folders. Each extraction creates a **real Seam** because at least two call sites already exist (the two-adapters-makes-a-seam rule).

| Proposed Component | Lives in | Replaces inline code at |
|---|---|---|
| `EditorialChip` (`Style: .outlined / .filled`, `Size: .square36 / .square32 / .pill`) | `Components/EditorialChip.swift` | All 6 sites in 1.2; DONE button, X close button, remove button |
| `EditorialSheet` shell view (header title + trailing close, hides nav bar, applies cream background, declares detents) | `Components/EditorialSheet.swift` | `MixerView.swift`, `SleepTimerView.swift`, `SavedMixesView.swift` |
| `TactilePressStyle: ButtonStyle` (promote private `EditorialTilePressStyle`) | `Components/TactilePressStyle.swift` | `SoundCardView`, `SavedMixesView` row, `NowPlayingBarView`, `SleepContentCardView` |
| `EditorialVolumeSlider` (promote from private inside MixerSoundRow) | `Components/EditorialVolumeSlider.swift` | `MixerSoundRowView`, eventually `BinauralBeatsView` (collapses `BinauralVolumeSliderView`) |
| `EditorialEmptyState(systemImage:, title:, description:)` | `Components/EditorialEmptyState.swift` | `MixerView` empty, `SavedMixesView` empty, `SoundsView` no-favorites, `FavoritesView` no-favorites |
| `EditorialIndexNumeral(index:)` (returns formatted `"01"` text using `Tokens.displayNumeralSize`) | `Components/EditorialIndexNumeral.swift` | `SoundCardView`, `MixerSoundRowView`, `SavedMixEditorialRow` |
| `EditorialHairlineDivider(opacity: 0.08)` | `Components/EditorialHairline.swift` | `SoundCardView`, `MixerSoundRowView`, `SoundsView` section divider — currently `Rectangle().fill(Tokens.colorInk.opacity(0.08)).frame(height: 1)` repeated 5+ times |
| `EditorialSparkline(values: [Double])` | `Components/EditorialSparkline.swift` | `SleepTimerView` sin-wave, `WeeklyStatsCardView` sparkline tile — currently two separate `GeometryReader { Path { … } }` blocks |

Each of these has ≥ 2 existing call sites today, so each represents a verified Seam, not speculative abstraction.

---

## 3. Views with too much logic (top 5)

Ranked by Depth-cost (logic-per-line of View body):

### 3.1 `SoundsView.swift` (326 lines)
- 9 `@Environment` services injected directly into one View
- 6 sheet `@State` flags + analytics `sheetOpenTime` tracking inline
- `freeSoundLimit = 6` constant duplicated from `MixerView`
- `wouldExceedMixerLimit(for:)` paywall business logic in View body
- Analytics call-sites scattered across toolbar buttons rather than emitted by the view model
- Paywall sheet `Binding` for `showPaywall` constructed inline with side-effect setter
- The `sectionStack(for:)` / `editorialSection(...)` builders are doing presentation-layer "what content goes where" decisions that belong in `SoundsViewModel`

**Recommended Seam.** A `SoundsCoordinator` (or extending `SoundsViewModel`) absorbs sheet flags, the free-limit check, analytics emission, and paywall triggering. The View becomes a renderer of an `@Observable` state.

### 3.2 `SavedMixesView.swift` (246 lines)
- Instantiates `SoundRepository()` directly in the View (`:17`) — repository wiring leaking into the Presentation Module
- `loadMix(_:)` reimplements playback orchestration with raw `DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { … nested .now() + 0.1 }` instead of awaiting on the audio engine
- `SavedMixEditorialRow` private struct (lines 145-240) carries: `DateFormatter()` instantiated per-render, subtitle string formatting, `String(format:)` index padding — all of which is pure view-model concern
- `@State` rename draft + alert binding manipulated inline rather than through the service

### 3.3 `InsightsView.swift` (273 lines)
- Mounts the new `WeeklyStatsCardView` on top of legacy `LinearGradient(colors: [.purple, .indigo])` upsell card (`:181`) and `Color(.systemGroupedBackground)` background (`:79`) — two design systems on one screen
- `sampleStats` hard-coded `Stats` struct in the View (`:16-22`) — explicitly TODO'd in a comment; presentation depends on no real data Adapter yet
- Same `sampleStats` duplicated in `WeeklyStatsCardView.Stats.sample` — two sample factories, two future sources of drift
- `sectionHeader`, `lockedPlaceholder`, `basicStatCard`, `premiumUpsellCard` are all `private func` view factories that should be either real components or distinct files

### 3.4 `MixerView.swift` (233 lines)
- Counter logic (`counterText`, `counterIsAtCap`) computed inline in View
- `freeSoundLimit = 6` duplicated again
- Analytics calls emitted from inside the body (the `onRemove:` closure on each row carries an `analyticsService.logMixerSoundRemoved` call — analytics in the row builder)
- Empty-state inlined when `EditorialEmptyState` would do
- Header reimplements the sheet shell pattern from scratch (see 1.5)

### 3.5 `SleepTimerView.swift` (269 lines)
- `displayTime` time-formatting logic in the View (should be a `String` on `SleepTimerService` or a small `TimerDisplayFormatter` value type)
- `sparklinePath(width:midY:amplitude:cycles:)` — a 16-line `Path` builder lives in the View; identical sine-wave intent to the sparkline that `WeeklyStatsCardView` needs (1.5 / candidate `EditorialSparkline`)
- `presetColumns: [GridItem]` declared as a let; harmless, but combined with the inline header (1.5) and inline `cancelButton` styling (which forks from the rest of the in-scope `colorOrange` button language by using `colorInk` fill instead), the file mixes layout, formatting, and styling concerns

---

## 4. Design-token violations (spot-checked)

`Tokens.swift` defines an Interface with 5 colors, 3 geometry values, 1 motion spring, and 2 type sizes. **The Implementations bypass it constantly.**

### Magic font sizes in the in-scope screens
DESIGN.md §2.2 specifies 6 type roles: 72 / 28 / 20 / 15 / 11 / 12. The in-scope folders (`Mixer`, `Timer`, `SavedMixes`, `Sounds`, `Components`) use **14 distinct `.font(.system(size: N))` values**: 11, 12, 13, 14, 16, 18, 20, 22, 28, 34, 36, 48, 56, 96.

High-confidence violations:
- `MixerView.swift:63` — header is `size: 34, weight: .black` instead of `Tokens.headlineSize` (28)
- `SleepTimerView.swift:110` — countdown is `size: 96, weight: .black` instead of `Tokens.displayNumeralSize` (72)
- `SavedMixesView.swift:185` — index numeral is `size: 56, weight: .bold` (not 72)
- `MixerSoundRowView.swift:39` — numeral is `size: 48` (not 72)
- `SoundCardView.swift:47` — sound name is `size: 18` (DESIGN.md says subhead = 20)

### Color/literal violations
- `SavedMixRowView.swift:45` — `.foregroundStyle(.purple)`, plus the entire file is **dead code** (replaced by `SavedMixEditorialRow` inside `SavedMixesView`); a Module-level Leverage win = delete
- `CategoryFilterView.swift:72` — `Color.purple` and `Color(.systemGray5)` for category chips (this is an in-scope SoundsView dependency per DESIGN.md §3.1)
- `OnboardingButton.swift:31-47` — `Color.purple` hardcoded across the entire style enum
- `SavedMixesView.swift:165, 219` — `Color.white.opacity(0.75)` rather than `Tokens.colorCream.opacity(…)`
- `NowPlayingBarView.swift:60, 84, 88` — `Color.white` direct, not via `Tokens.colorCream`

### Missing tokens
The corner-radius `8` used on every ink-outlined chip (≥ 6 sites) is unnamed in `Tokens` despite being a recurring affordance — should become `Tokens.radiusChip = 8`. Hairline opacity `0.08` is similarly unnamed (≥ 5 sites) — `Tokens.hairlineInkOpacity = 0.08`.

### Legacy purple still in Implementations the editorial pass didn't touch
13 files in `Insights/`, `Discover/`, `Alarms/`, `Settings/` still call `.foregroundStyle(.purple)`. `Tokens.accentBrandLegacy` exists for this but is **not used anywhere** — the deprecation Adapter the design spec describes is bypassed entirely.

---

## 5. Accessibility coverage snapshot

| | Files with any `.accessibility*` annotation | Files without |
|---|---|---|
| In-scope editorial screens (6 files) | 6 / 6 | 0 |
| Components folder (8 files) | 2 / 8 (NowPlayingBar, Splash) | 6 |
| Legacy folders (78 files) | ~5 / 78 | 73 |

7 of 92 Presentation files (≈7.6%) carry any accessibility hook. The editorial pass took accessibility seriously (`MixerView`, `SleepTimerView`, `SavedMixesView`, `SoundCardView`, `MixerSoundRowView`, `WeeklyStatsCardView`, `SplashWordmarkView`) — every one of these emits `.accessibilityLabel`, several emit `.accessibilityValue` and `.accessibilityElement(children: .combine)`. **Everything else is mute to VoiceOver.**

Examples of un-annotated legacy views: `AlarmsView`, `AlarmDetailView`, `BinauralBeatsView` (390 lines, zero hooks), `DiscoverView`, `InsightsView` body, `OnboardingPaywallView` (534 lines, zero hooks), `SettingsView` (321 lines, zero hooks), `WindDownView` (393 lines), `AppearanceSettingsView`.

Notable gap: DESIGN.md §5 Anti-pattern (numbered prefix should be decorative, `accessibilityElement(children: .ignore)` on prefix, hoist label to row container) — this is followed in `MixerSoundRowView` and `SoundCardView` but **not** in `SavedMixEditorialRow` (the prefix numeral is part of `.combine`, which produces VoiceOver readouts like "zero one, Rain & Thunder, four sounds, currently loaded" — the "zero one" is noise).

---

## 6. Previews

`#Preview` blocks exist in 100 of ~92 Presentation files (some files declare multiple `#Preview` variants). Two files lack one: `AlarmRingingView.swift` and `SoundsViewModel.swift` (the latter is a view model, so it correctly has none). Coverage is near-total — that's a strength.

Quality is uneven though. Several previews still set `.preferredColorScheme(.dark)` for editorial light surfaces (`SavedMixRowView.swift:95`, `SaveMixSheet.swift:42`, `SoundCardView` doesn't but uses `Tokens.colorCream.opacity(0.5)` instead of `Tokens.colorCream`) — suggesting they were carried forward from the legacy dark system without re-thought. `MixerView`'s preview instantiates four bare services with default initialisers, which compiles but produces an empty mixer; no preview demonstrates the populated-mixer state.

---

## 7. Refactor opportunities ranked by Leverage

Using two-adapters = real seam:

1. **`EditorialChip` extraction** — 6+ call sites today. Biggest visual-drift source. (High Leverage / Low Depth.)
2. **`EditorialSheet` shell** — collapses the Mixer/Timer/SavedMixes sheet triad into one Adapter; also forces `.presentationDetents` discipline that DESIGN.md §6 anti-patterns demand.
3. **Promote `TactilePressStyle` to Components** — 4 call sites today, removes hand-rolled `DragGesture(minimumDistance: 0)` from views that don't need it.
4. **Delete `SavedMixRowView.swift`** — dead code with a `.purple` literal. Pure Locality win.
5. **Extract sound-card paywall/limit branching** into `SoundsCoordinator` — 2 call sites in `SoundsView` and `FavoritesView`, plus the `freeSoundLimit = 6` constant in 3 places. Adapter is the coordinator; both views become thin renderers.
6. **`EditorialEmptyState`** — 4+ call sites, plus reconciles the dual `ContentUnavailableView` vs hand-rolled-VStack convention.
7. **`EditorialSparkline`** — collapses two `Path`-building blobs; preempts a third when Insights gets its editorial pass.
8. **Add `Tokens.radiusChip = 8`, `Tokens.hairlineInkOpacity = 0.08`, `Tokens.pressScale = 0.97`** — pre-Adapter; teaches the next refactor to be token-routed by default.

---

## 8. What the Components Module should look like after a pass

```
Presentation/Components/
├── Tokens.swift                  (expanded: radiusChip, hairlineInkOpacity, pressScale, font roles)
├── EditorialChip.swift           (NEW — outlined/filled, sized; replaces 6+ inline copies)
├── EditorialSheet.swift          (NEW — shared sheet shell for Mixer/Timer/SavedMixes)
├── EditorialEmptyState.swift     (NEW — 4+ inline copies collapse)
├── EditorialIndexNumeral.swift   (NEW — "01 / 02 / 03" prefix used in 3+ rows)
├── EditorialHairline.swift       (NEW — 1pt ink-08 divider used in 5+ rows)
├── EditorialVolumeSlider.swift   (PROMOTE from private inside MixerSoundRowView)
├── EditorialSparkline.swift      (NEW — Timer sin-wave + WeeklyStats sparkline collapse)
├── TactilePressStyle.swift       (PROMOTE from private inside SoundCardView)
├── NowPlayingBarView.swift       (already here)
├── SplashWordmarkView.swift      (already here)
├── PremiumLockOverlay.swift      (already here — ViewModifier Module already in shape)
├── OLEDBackgroundModifier.swift  (legacy, leave for non-in-scope screens)
├── ReflectiveSheenModifier.swift (legacy — DESIGN.md §6 forbids; candidate for deletion once legacy screens migrate)
├── ASMRInfoView.swift            (one-off info sheet — could stay here or move under Sounds/)
├── SoundScienceView.swift        (same)
└── Visualization/                (already here)
```

Net effect: the Components Module becomes the canonical Interface for "what an editorial widget looks like," and 6 of the 9 in-scope feature screens lose 30-60 lines each because they stop reimplementing primitives. The Leverage is in the Adapter count moving from "many private copies" to "one shared Implementation behind one Interface."
