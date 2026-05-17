# Next Sleep — Design Specification

**Status:** Source of truth for `/impeccable` polish pass on core surfaces.
**Scope:** Sounds tab, Mixer sheet, Sleep Timer sheet, Saved Mixes sheet, NowPlayingBar.
**Inherits:** CLAUDE.md "Design Context" section (brand, principles, tokens). This document
*extends* that with screen-level layouts, component states, motion specs, and the cross-screen
coherence rules. When CLAUDE.md and this document disagree, this document wins.

---

## 1. Design intent

Next Sleep is a **precision instrument for sleep**, not a wellness toy. The interface should
read as *engineered calm*: dark, flowing, abstract, with category color used as a quiet signal
rather than decoration. The current core surfaces (Sounds, Mixer, Timer, Saved) feel
**partially polished** — the Sounds grid and cards have the intended OLED + glow language, but
the three sheets (Mixer/Timer/Saved) still default to stock iOS chrome (`.insetGrouped` lists,
`Color(.systemGray5)` buttons, plain navigation bars). The `/impeccable` pass must bring the
sheets to parity with the Sounds tab and elevate the shared components.

### The five things this polish pass must achieve

1. **Sheet parity.** Mixer/Timer/Saved must adopt the same OLED background, the same card
   language, the same category-color treatment as the Sounds tab.
2. **Motion coherence.** All transitions (sheet present, sound toggle, timer countdown, volume
   slider) should share one spring vocabulary so the app feels like a single instrument.
3. **Disappearing chrome.** Reduce visible structure further: thinner separators, fewer
   borders, more breathing room. Information density should drop ~20% on the sheets.
4. **Category color as the only chromatic accent.** Eliminate stray system colors
   (`.systemGray5`, `.red` for "Cancel Timer", `.green` for the premium counter) and route
   everything through the design tokens defined below.
5. **Glow consistency.** The "playing" glow on SoundCardView is the visual signature. Mirror
   it on the timer ring (purple), the now-playing bar (purple), and active sound rows in the
   mixer (per-sound category color).

### Out of scope (do not modify in this pass)

- Tab structure (7 tabs stay; sheet-based core flow stays).
- Audio engine, repositories, services — **presentation layer only**.
- Other tabs (Binaural, Wind Down, Sleep Rec, Discover, Adaptive, Insights). They get their
  own pass later.
- Onboarding paywall (`OnboardingPaywallView`) — owned by a separate plan.
- Localization keys — content stays in the same `LocalizedStringKey` slots; only visual
  styling changes.

---

## 2. Tokens (formalized)

These extend CLAUDE.md's tokens. Every new style must reference one of these — no inline
hex, no inline radii, no inline spring values.

### 2.1 Color tokens

| Token | Light | Dark (OLED) | Use |
|---|---|---|---|
| `BackgroundPrimary` | `Color(.systemBackground)` | `Color.black` | Screen background |
| `BackgroundElevated` | `Color(.systemGray6)` | `Color(.systemGray6).opacity(0.08)` | Card / row background, idle |
| `BackgroundElevatedActive` | `Color(.systemGray6)` | `Color(.systemGray6).opacity(0.15)` | Card / row background, playing |
| `Separator` | `Color.gray.opacity(0.15)` | `Color.white.opacity(0.06)` | Dividers, list separators |
| `AccentBrand` | `#7F6FD8` (purple) | `#7F6FD8` | Primary actions, timer ring, waveform |
| `AccentNoise` | `.purple` | `.purple` | Noise category |
| `AccentNature` | `.green` | `.green` | Nature category |
| `AccentWeather` | `.blue` | `.blue` | Weather category |
| `AccentFire` | `.orange` | `.orange` | Fire category |
| `AccentMusic` | `.pink` | `.pink` | Music category |
| `AccentASMR` | `Color(red:0.8,g:0.6,b:1.0)` | same | ASMR category |
| `TextPrimary` | `.primary` | `.primary` | Body text, sound names |
| `TextSecondary` | `.secondary` | `Color.white.opacity(0.55)` | Captions, supporting copy |
| `Destructive` | `.red` | `Color(red:0.95,g:0.4,b:0.4)` | Stop, cancel-timer, remove |
| `Warning` | `.orange` | `.orange` | Free-tier limit reached |
| `Success` | `.green` | `Color(red:0.4,g:0.85,b:0.6)` | Premium-unlocked counter |

### 2.2 Geometry tokens

| Token | Value | Use |
|---|---|---|
| `RadiusCard` | 16 | Sound cards, sheet content blocks |
| `RadiusControl` | 12 | Buttons, preset chips |
| `RadiusBadge` | 8 | Counter chips, lock badges |
| `SpacingEdge` | 24 | Screen-edge padding |
| `SpacingSection` | 16 | Inter-section spacing |
| `SpacingTight` | 12 | Within-card spacing |
| `SpacingHair` | 4 | Icon-label spacing |
| `IconLarge` | 60 | Empty-state icons |
| `IconMedium` | 40 | Card icons |
| `IconSmall` | 22 | Inline icons |
| `TimerDisplay` | 72pt thin | Sleep timer countdown |

### 2.3 Glow specs

The category-color glow is the visual signature. It must follow these rules:

| Element | Color | Radius (OLED) | Radius (Light) | Opacity (OLED) | Opacity (Light) |
|---|---|---|---|---|---|
| Active SoundCard | `categoryColor` | 16 | 12 | 0.6 | 0.4 |
| Active MixerRow | `soundCategoryColor` | 10 | 8 | 0.4 | 0.25 |
| Active Timer ring | `AccentBrand` | 20 | 14 | 0.5 | 0.3 |
| NowPlayingBar (sounds playing) | `AccentBrand` | 12 | 10 | 0.4 | 0.3 |

### 2.4 Motion tokens

One spring vocabulary. No `.linear`, no `.default` outside of progress bars.

| Token | Definition | Use |
|---|---|---|
| `springStandard` | `.spring(response: 0.4, dampingFraction: 0.7)` | Sheet presents, card-state toggles |
| `springSnappy` | `.spring(response: 0.3, dampingFraction: 0.5)` | Heart pop, button press |
| `springSoft` | `.spring(response: 0.6, dampingFraction: 0.8)` | Glow fade-in/out, volume slider |
| `linearTimer` | `.linear(duration: 1)` | Progress ring countdown (must be linear) |
| `easeAtmosphere` | `.easeInOut(duration: 2.4).repeatForever(autoreverses: true)` | Waveform indicator, particle drift |

### 2.5 Typography

| Token | Value | Use |
|---|---|---|
| `TypeTimerDisplay` | `.system(size: 72, weight: .thin, design: .rounded).monospacedDigit()` | Sleep timer |
| `TypeScreenTitle` | `.largeTitle.weight(.semibold)` | Navigation titles (on the surfaces themselves, not the bar) |
| `TypeSectionHeader` | `.headline.weight(.semibold)` | "Favorites", "All Sounds" |
| `TypeBody` | `.subheadline.weight(.medium)` | Sound names, row labels |
| `TypeCaption` | `.caption` | "Tap to mix", supporting copy |
| `TypeMonoMeta` | `.caption.monospacedDigit()` | Timer remaining, volume %, counters |

---

## 3. Screen specs

### 3.1 SoundsView

**Layout (top to bottom):**

```
[NavBar: settings | "Sounds" | mixer · timer · saved]
[CategoryFilter — horizontal scroll, sticky on scroll]
[Favorites section (conditional)]
[All Sounds grid — 2 columns, 16pt gutter, 16pt edge inset]
[NowPlayingBar — overlay, bottom, 16pt edge, transition .move(.bottom)+.opacity]
```

**Polish targets:**

- **Sticky CategoryFilter.** Currently scrolls away with the grid. Should pin under the
  navigation bar with a translucent backdrop (`.ultraThinMaterial` over `BackgroundPrimary`).
- **Favorites section header.** Replace the inline `HStack { heart + "Favorites" }` with a
  treatment that matches `TypeSectionHeader`, including a subtle red-tinted glow on the heart
  icon (radius 6, opacity 0.4).
- **Scroll-edge fade.** Top and bottom 24pt of the scroll view fades to `BackgroundPrimary`
  so the NowPlayingBar feels like it emerges from atmosphere, not sits on hard chrome.
- **Empty state.** `ContentUnavailableView` styling for "No Favorites" should use the OLED
  treatment (centered, large icon at `IconLarge`, subdued copy at `TextSecondary`).

**States to verify:**

| State | Behavior |
|---|---|
| 0 sounds favorited | All Sounds section shows no header |
| 1+ sounds favorited, no category filter | Favorites + All Sounds (with "All Sounds" header) |
| Category filter active | Filter results only, no favorites section |
| Showing favorites filter | Only favorites in grid, empty state if none |
| ASMR category first-visit | ASMR info sheet auto-presents (existing behavior, preserve) |
| Premium-locked sound tap | Paywall triggers, then plays on success (preserve) |
| Free-tier 6-sound cap hit | Paywall triggers with `unlimited_mixing` placement (preserve) |

### 3.2 SoundCardView

The card is **already close to the target** but has two anti-pattern leaks:

- The heart button currently lives in a `.overlay(alignment: .topTrailing)` with a 12pt
  inset — it needs a tap target of ≥44pt without visually crowding the icon. Wrap in a
  44×44 hit area while keeping the visual at 20pt.
- The "playing" border (`stroke(...)`) is `lineWidth: 2` in light mode, `1` in OLED. Drop
  light-mode to `1.5` and rely more on glow than stroke — the stroke is fighting the glow's
  softness.

**Mini visualization overlay:** keep `MiniVisualizationView` at opacity 0.8 when playing.
Add `.transition(.opacity.animation(springSoft))` so it fades in rather than pops.

### 3.3 MixerView (sheet)

**Current state:** plain `.insetGrouped` list, system-default chrome.

**Target layout:**

```
[NavBar: "Save Mix" | "Mixer" | pause/play · stop]
[LiquidVisualizationView — 150pt tall, full-width, no list inset]
[Counter chip — "3 sounds playing  ·  3/6"]
[MixerSoundRow × N — vertical stack, 12pt spacing, no list separators]
```

**Polish targets:**

- **Drop `.insetGrouped`.** Replace with a plain `ScrollView` + `VStack` so we control
  spacing and backgrounds directly. Apply `oledBackground()`.
- **Counter chip.** Replace the section-header `HStack` with a pill (`RadiusBadge` 8,
  background `BackgroundElevated`, foreground `TextSecondary` or `Warning` at-cap).
  Place it inline above the rows, centered, with 16pt vertical breathing room.
- **MixerSoundRow.** Each row is its own card with `RadiusCard` 16, background
  `BackgroundElevated`, glowing in the sound's category color at `Active MixerRow` spec when
  the audio engine reports that sound as playing.
- **Stop button.** Move out of the toolbar into a dedicated full-width "Stop All" button
  pinned to the bottom with a thin top divider. Make it `Destructive` text on transparent
  background — destructive but not loud.
- **Empty state.** Current `ContentUnavailableView` works but use OLED treatment and
  add a "Browse sounds" button that dismisses the sheet.
- **Visualization on empty.** When `activeSounds` becomes empty mid-session, sheet
  auto-dismisses (existing behavior, preserve and verify it still triggers under the new
  layout).

### 3.4 MixerSoundRowView

Target: row reads as a mini-card.

```
[ category-color icon (32pt circle) ] [ sound name + category label ] [ remove ]
[ ───────────── volume slider ───────────── ]  [ volume % ]
```

- Slider tinted in the sound's `categoryColor`, opacity 0.85.
- Volume % in `TypeMonoMeta`, right-aligned, 36pt fixed width so values don't jitter.
- Remove button: `xmark` in `Destructive`, 32×32 hit area, top-right of row.
- On volume commit (slider release), pulse the row glow once at `springSnappy`.

### 3.5 SleepTimerView (sheet)

The most cosmetically dated of the four sheets — `Color(.systemGray5)` preset buttons feel
like a 2019 app.

**Preset selection state (timer inactive):**

```
[NavBar: · "Sleep Timer" · Done]
[Moon icon @ IconLarge, AccentBrand at 0.7 opacity]
[ "Set Sleep Timer" — TypeSectionHeader, TextSecondary ]
[ 3-column preset grid ]
[ "Audio will gradually fade out…" caption ]
```

- Preset chips: replace `Color(.systemGray5)` with `BackgroundElevated`, add
  `RadiusControl` 12, add a thin `AccentBrand` border on press, and a soft purple glow
  (`AccentBrand`, radius 8, opacity 0.3) that pulses once on tap before the timer starts.
- Stagger preset entrance animation by index × 0.04s using `springStandard`.

**Active timer state:**

```
[NavBar: · "Sleep Timer" · Done]
[ Countdown @ TypeTimerDisplay, centered ]
[ Progress ring 200pt, lineWidth 8, AccentBrand with glow ]
   [ within ring: moon.zzz.fill icon, AccentBrand ]
   [ "Fading out…" subtext when remainingSeconds ≤ 30 ]
[ "Cancel Timer" button — Destructive, .bordered tint ]
```

- Progress ring: add `Active Timer ring` glow spec (radius 20, opacity 0.5 in OLED).
- During the last 30s fade window, animate the moon icon with `easeAtmosphere` rotation
  (±3°) to telegraph the wind-down.
- Cancel button: keep `.red` tint but route through `Destructive` token.

### 3.6 SavedMixesView + SavedMixRowView (sheet)

Currently functional but visually flat.

**SavedMixesView:**

- `oledBackground()` on the scroll view.
- Empty state: "No Saved Mixes" + descriptive copy + a small chevron back to the mixer.
- Row spacing: 12pt vertical, 16pt edge inset.

**SavedMixRowView (target layout):**

```
[ Stacked category-color dots — first 3 sounds' categories ]
[ Mix name @ TypeBody, "N sounds" @ TypeCaption ]
[ Play button @ AccentBrand, 36×36 circle ] [ ⋯ menu ]
```

- The "stacked color dots" replaces the current generic icon — it tells the user at a
  glance what *kind* of mix this is.
- Play button glows on press (`springSnappy`).
- ⋯ menu: Rename, Delete (Destructive).

### 3.7 SaveMixSheet

Currently a tiny 43-line file. Polish targets:

- Use `.presentationDetents([.height(220)])` for a compact sheet.
- Single TextField with placeholder "Mix name", `RadiusControl` 12, `BackgroundElevated`.
- Primary button "Save" — `AccentBrand`, full-width, `RadiusControl`. Disabled state at
  0.4 opacity until name has 1+ non-whitespace character.

### 3.8 NowPlayingBarView

Already well-crafted; small refinements only.

- Bar background: currently `Color(.systemGray6).opacity(0.25)` in OLED. Switch to
  `.ultraThinMaterial` over a `Color.black.opacity(0.5)` base for a true glassy feel.
- Add a 1px hairline top border in `Separator` so it reads as elevated above the grid.
- WaveformIndicator: bars currently `Color.purple` flat. Add a subtle gradient
  (`AccentBrand` → `AccentBrand.opacity(0.6)` top-to-bottom).
- Tap target: the whole bar should accept tap-to-mix, not just the leading label region.

---

## 4. Component contracts

### 4.1 OLEDBackgroundModifier

Existing. Confirm it applies:

- Light: `Color(.systemBackground)`.
- Dark/OLED: `Color.black` with optional subtle radial gradient (center to edge, opacity 0
  → 0.04 white) for atmosphere — currently flat black.

### 4.2 ReflectiveSheenModifier

Existing on SoundCardView. Verify:

- Sheen is driven by `MotionService` device tilt (current implementation).
- Sheen angle responds with `springSoft` — never linear, never instant.
- Disabled in Reduce Motion (`@Environment(\.accessibilityReduceMotion)`).

### 4.3 LiquidVisualizationView

Used in MixerView header. Verify:

- 60fps target, but degrade gracefully — drop to 30fps when `ProcessInfo.thermalState ≥ .serious`.
- Colors derived from active sounds' categories, blended.
- Honors `accessibilityReduceMotion` (static gradient fallback).

### 4.4 New: TokenizedStyles namespace

Create `Sources/Presentation/DesignSystem/Tokens.swift` exposing the tokens above as
`enum Tokens { ... }` so all of the above are referenced via `Tokens.RadiusCard`,
`Tokens.springStandard` etc. No more magic numbers in views.

---

## 5. Accessibility

Non-negotiable. All four surfaces must:

1. **Reduce Motion**: disable atmospheric springs (`easeAtmosphere`, sheen), keep state
   transitions but use `.easeInOut(duration: 0.2)` instead of springs.
2. **Dynamic Type**: support up to `.accessibility3`. Sound names truncate to 2 lines
   already — preserve.
3. **VoiceOver labels**: every interactive element ships with `.accessibilityLabel` and
   `.accessibilityHint` where action isn't obvious from label (heart toggle, volume
   slider, stop button).
4. **Contrast**: all text-on-background pairs must meet WCAG AA (4.5:1) in both modes. The
   `TextSecondary` token in OLED at `Color.white.opacity(0.55)` is on the edge — verify and
   adjust to 0.6 if needed.
5. **Tap targets**: minimum 44×44pt (heart button in SoundCardView is the known weak point).

---

## 6. Anti-patterns (forbidden)

- Inline hex colors. Route through tokens.
- `Color(.systemGray5)`, `Color(.systemGray6)` in views — only allowed in the token file.
- `.animation(.default, value: …)`. Pick a named spring.
- Decorative emoji in UI strings.
- Hard borders (`stroke(…, lineWidth: > 2)`).
- Pure white backgrounds in dark mode.
- Modal sheets without `.presentationDetents` — every sheet must declare its detents.

---

## 7. Verification rubric

A `/impeccable` PR is mergeable when:

1. The build passes (`xcodebuild … build`).
2. All UI tests still pass.
3. Each of the four sheets matches its section spec above (manual visual review or
   screenshot diff if available).
4. No inline magic numbers — `grep -E "\\.(systemGray|stroke\\(lineWidth: [3-9])"` returns
   only token-file matches.
5. VoiceOver pass: every button has a label; every slider has a value.
6. Reduce Motion pass: no atmospheric animation runs.
7. The NowPlayingBar still hides/shows correctly on `activeSounds` transitions.
8. The 6-sound free-tier limit and paywall triggers are unchanged in behavior.
