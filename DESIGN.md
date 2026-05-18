# Next Sleep — Design Specification

**Status:** Source of truth for the editorial redesign of the core surfaces.
**Scope:** Sounds tab, SoundCardView, Mixer sheet, MixerSoundRowView, Sleep Timer sheet,
Saved Mixes sheet, NowPlayingBar, Splash, Weekly Stats card.
**Inherits:** CLAUDE.md "Design Context" section is the high-level brand frame. Where this
document and CLAUDE.md disagree on visual specifics (palette, motion, type), this document
wins.

> **Direction change (v2):** The previous "dark / OLED / purple glow" language is now
> **SUPERSEDED** for the in-scope screens listed above. The new direction is the
> **Editorial Light System** — a warm, color-blocked, magazine-grade light interface
> derived from the two reference images staged at
> `screenshots/design-refs/ref01-orange-editorial.jpg` and
> `screenshots/design-refs/ref02-warm-dashboard.jpg`. Section 2 below codifies the system;
> the legacy dark/OLED specs are preserved at the bottom (Section 9) as a SUPERSEDED
> appendix for screens that have not yet migrated.

---

## 1. Design intent

Next Sleep is shifting from "abstract dark instrument" to **editorial calm**: an interface
that reads like a thoughtfully art-directed magazine spread for sleep. Calm still wins, but
calm now comes from **warm cream paper, generous typographic hierarchy, color-blocked
sections, and tactile micro-interactions** — not from OLED black and glowing purple.

The reference images set the bar:

- `screenshots/design-refs/ref01-orange-editorial.jpg` — an editorial layout dominated by
  saturated orange color-blocks, oversized display numerals, numbered rows ("01 / 02"),
  and a chevron motif used as a navigation accent. This image defines the **block
  language**, the **chevron motif**, and the **orange/ink contrast pairing**.
- `screenshots/design-refs/ref02-warm-dashboard.jpg` — a warm dashboard on cream paper
  with stat tiles, sparkline and bar chart treatments, peach/yellow secondary fills, and
  microcopy labels under oversized top-left numerals. This image defines the **stat tile
  pattern**, the **chart treatments**, and the **cream canvas + peach / yellow secondary
  palette**.

### The five things this redesign must achieve

1. **Editorial canvas.** Replace OLED black with the warm cream canvas (`#F4F0E8`) on the
   nine in-scope screens. Screen backgrounds are paper, not void.
2. **Color-blocked sections.** Lean on saturated orange (`#E84B1A`) and yellow (`#F5C518`)
   as full-width or full-tile blocks rather than thin accent strokes. Color does work, not
   decoration.
3. **Display numerals + microcopy.** Every metric tile uses an oversized top-left numeral
   (SF Pro Display Bold/Black at `displayNumeralSize`) sitting above a small lowercase
   microcopy label. The numeral is the visual anchor; the label is supporting text.
4. **Tactile press, no glow.** All interactive surfaces register press with a scale-to-
   `0.97` + `tactilePress` spring. The previous purple glow language is gone for in-scope
   screens.
5. **Chevron + numbered rows.** Use the chevron motif as the nav accent and "01 / 02 / 03"
   numbered editorial rows for list content — `editorialRowHeight = 64`.

### Out of scope (do not modify in this pass)

- Tab structure (7 tabs stay; sheet-based core flow stays).
- Audio engine, repositories, services — **presentation layer only**.
- Other tabs (Binaural, Wind Down, Sleep Rec, Discover, Adaptive, Insights). They keep
  the legacy dark/purple system until their own pass; the deprecated
  `Tokens.accentBrandLegacy` alias exists for that reason.
- Onboarding paywall (`OnboardingPaywallView`) — owned by a separate plan.
- Localization keys — content stays in the same `LocalizedStringKey` slots; only visual
  styling changes.

---

## 2. Editorial Light System

This is the system of record for the in-scope screens. Everything in this section is
mirrored in `SoundScape/Sources/Presentation/Components/Tokens.swift`. Views MUST
reference `Tokens.*` rather than hard-coding hex values, radii, font sizes, or spring
parameters.

### 2.1 Palette

Five named colors form the entire palette for the in-scope screens. There are no other
chromatic accents.

| Token | Hex | Role |
|---|---|---|
| `Tokens.colorOrange` | `#E84B1A` | Primary accent. Used for color-blocked hero sections, primary buttons, chevron motif, large key surfaces (e.g. the orange "play / mix" block on SoundsView, the orange Stop block on the mixer). |
| `Tokens.colorYellow` | `#F5C518` | Highlight tiles, stat callouts, accent numerals where contrast against cream needs a second voice (e.g. yellow tile in the Weekly Stats card, yellow "saved" pill). |
| `Tokens.colorPeach` | `#F7D5BD` | Secondary block / mid-tone card fill. Used to break the cream canvas into two zones, or as a warm rest state for tiles that are not the primary action. |
| `Tokens.colorCream` | `#F4F0E8` | Canvas. Default screen background. Replaces `Color.black` / `BackgroundPrimary` for the in-scope screens. Paper, not void. |
| `Tokens.colorInk` | `#111111` | Display + body ink. Used for all text on cream / peach / yellow backgrounds, and for the chevron / row separators. Slightly warmed off pure black for editorial softness. |

Contrast on cream:

- `Tokens.colorInk` on `Tokens.colorCream` exceeds WCAG AAA (≥ 14:1).
- `Tokens.colorInk` on `Tokens.colorYellow` exceeds WCAG AAA (≥ 13:1).
- `Tokens.colorInk` on `Tokens.colorPeach` exceeds WCAG AA (≥ 7:1).
- `Tokens.colorCream` on `Tokens.colorOrange` exceeds WCAG AA Large (≥ 4.5:1). Use cream
  ink for text on orange blocks; never use `Tokens.colorInk` on orange (insufficient
  contrast for editorial-weight type).

### 2.2 Typography

Two SF families, two roles. No system grays, no custom display fonts.

| Token / Role | Font | Use |
|---|---|---|
| `Tokens.displayNumeralSize` (72pt) | `SF Pro Display`, Bold / Black, monospaced digits | The oversized top-left numeral on every stat tile and the splash wordmark. Always paired with a microcopy label directly beneath. |
| `Tokens.headlineSize` (28pt) | `SF Pro Display`, Bold | Editorial section headers ("All Sounds", "Saved Mixes", "Sleep Timer") and screen titles rendered inside the surface, not in the nav bar. |
| Subhead (20pt) | `SF Pro Display`, Semibold | Row titles in numbered editorial rows; primary card titles. |
| Body (15pt) | `SF Pro Text`, Regular | Body copy, descriptive captions, mixer row sound names. |
| Microcopy (11pt UPPERCASE, 0.12em tracking) | `SF Pro Text`, Medium | The label directly under display numerals ("hours slept", "sounds playing", "saved mixes"). Always uppercase, always tracked. |
| Mono meta (12pt) | `SF Pro Text`, Regular, monospaced digits | Timer remaining, volume %, "01 / 02" row numerals when used inline. |

Pairing rule (from `ref02-warm-dashboard.jpg`): every stat tile is `displayNumeralSize`
numeral over microcopy label. Never use the numeral alone; never use the microcopy without
a numeral above it.

### 2.3 Geometry

| Token | Value | Use |
|---|---|---|
| `Tokens.radiusBlock` | 20 | Large color-blocked sections (orange hero block on SoundsView, Stop block on mixer, peach intro block on Saved Mixes). |
| `Tokens.radiusTile` | 16 | Stat tiles, sound cards, saved-mix rows, preset chips. |
| `Tokens.editorialRowHeight` | 64 | Standard height for numbered editorial rows ("01 / 02 / 03 …"). |
| Edge inset | 20 | Screen-edge padding on all in-scope screens. |
| Block padding | 24 | Inset for content inside color-blocked sections. |
| Tile padding | 16 | Inset for content inside stat tiles. |
| Block gutter | 12 | Spacing between adjacent blocks / tiles. |
| Row gutter | 0 | Numbered editorial rows abut with hairline ink separators (1px `Tokens.colorInk` at 0.1 opacity), no gap. |

### 2.4 Motion

One spring. No glow.

| Token | Definition | Use |
|---|---|---|
| `Tokens.tactilePress` | `.spring(response: 0.35, dampingFraction: 0.8)` | Every interactive surface uses this for press → release. Pair with a scale of `0.97` on `isPressed`. No additional opacity dim. |
| Page / sheet transitions | `.spring(response: 0.45, dampingFraction: 0.85)` | Sheet present, list reorder, value commits. |
| Sparkline / bar chart draw-in | `.easeOut(duration: 0.6)` | Stat chart appears on screen-mount only; never repeats. |

**Eliminated motion (from the SUPERSEDED dark system):**

- No category-color glow on cards or rows.
- No purple glow on the timer ring.
- No `easeAtmosphere` repeating drift on the waveform.
- No reflective sheen on cards.

The press scale + spring is the only interactive feedback.

### 2.5 Patterns

These four patterns recur across the in-scope screens.

**a. Color block + chevron.** A full-width orange block (`radiusBlock`, `colorOrange`
fill) with cream-ink display text on the left and a right-aligned `chevron.right` chevron
in `colorCream` ink. The chevron is the nav accent — it appears on every "tap into this"
block. See `ref01-orange-editorial.jpg`.

**b. Numbered editorial row.** A row at `editorialRowHeight`, ink "01 / 02 / …" prefix
left-aligned in mono meta type, then a subhead title, then a trailing chevron. Rows are
separated by a hairline `colorInk @ 0.1` line, no padding between. See
`ref01-orange-editorial.jpg`.

**c. Stat tile.** A `radiusTile` tile with the display numeral in the top-left, the
microcopy label directly underneath, and (optionally) a sparkline or bar chart filling
the bottom-right. Tile fill is `colorCream` (resting), `colorPeach` (mid), or
`colorYellow` (highlight). See `ref02-warm-dashboard.jpg`.

**d. Sparkline + bar chart treatment.** Sparkline is a 1.5pt `colorInk` stroke, no fill,
no markers — pure line. Bar chart bars are `colorOrange` filled, `radiusTile / 4` (4pt)
corner radius on top edges only, sitting on a 1px `colorInk @ 0.1` baseline. Both draw
in with the screen-mount `.easeOut(duration: 0.6)` and stay static after.

---

## 3. Per-screen specs

Each screen references the reference image that informed it. All metrics and colors
must come from Section 2 tokens.

### 3.1 SoundsView — `screenshots/design-refs/ref01-orange-editorial.jpg`

**Layout (top to bottom):**

```
[Cream canvas]
[Headline "Sounds" at headlineSize, left-aligned, edge inset 20]
[Orange hero block — radiusBlock, ~140pt tall:
   "Mix now"  display numeral count of currently playing sounds, cream ink, chevron right]
[Category chips — horizontal scroll, ink chips on cream, selected chip = colorOrange fill / cream ink]
[Numbered editorial rows for All Sounds — "01 / Rain Storm  ›", row height = editorialRowHeight]
[Favorites section header at subhead weight; numbered rows again for favorites]
[NowPlayingBar overlay — see 3.8]
```

Behaviors preserved: ASMR first-visit info sheet, premium-locked sound tap → paywall,
free-tier 6-sound cap. Visual chrome only changes.

### 3.2 SoundCardView — `screenshots/design-refs/ref01-orange-editorial.jpg`

When the sounds grid is shown as cards (favorites strip), use a stat-tile treatment:

- `radiusTile` 16, fill `colorCream` (idle) or `colorPeach` (favorited).
- Top-left: a sound-specific glyph at 28pt, ink.
- Bottom-left: the sound name in subhead (Semibold), ink.
- On playing: replace the favorite-state fill with `colorOrange`, swap ink to cream.
- Press: scale 0.97 with `Tokens.tactilePress`. No glow.

### 3.3 MixerView — `screenshots/design-refs/ref02-warm-dashboard.jpg`

The mixer becomes an editorial dashboard.

```
[Cream canvas]
[Headline "Mixer" + microcopy "tonight's blend"]
[Stat tile row (2 columns):
   Tile A (peach): display numeral = active sound count, microcopy "sounds playing"
   Tile B (yellow): display numeral = total volume %, microcopy "blend level"]
[Sparkline tile (full width): playback over time, ink sparkline on cream]
[Numbered editorial rows of MixerSoundRow — "01 / Rain Storm  • volume slider  • 80%"]
[Orange Stop block pinned at bottom — radiusBlock, cream ink "Stop all", right chevron]
```

Drop `.insetGrouped`. Use `ScrollView` + `VStack`. Sheet declares
`.presentationDetents([.large])`.

### 3.4 MixerSoundRowView — `screenshots/design-refs/ref01-orange-editorial.jpg`

Each row is a numbered editorial row at `editorialRowHeight`:

```
[ 01 ]  [ Sound name (subhead, ink) ]  [ slim slider, ink track + colorOrange fill ]  [ 80% mono meta ]  [ × ]
```

- The "01" prefix uses the mono meta token and tracks with the row index.
- Slider: track 2pt `colorInk @ 0.15`, fill `colorOrange`, thumb 16pt cream circle with
  1px ink stroke.
- Remove `×` on press scales 0.97 with `Tokens.tactilePress`.

### 3.5 SleepTimerView — `screenshots/design-refs/ref02-warm-dashboard.jpg`

Preset state:

```
[Cream canvas]
[Headline "Sleep Timer"]
[Stat tile: display numeral "00:00" preset preview, microcopy "tap a preset"]
[Preset chips row — 5/10/15/30/45/60/90 min as numbered tiles
   "05" display numeral, microcopy "min", radiusTile, colorPeach fill]
[Microcopy line: "audio fades out over the last 30 seconds"]
```

Active timer state:

```
[Cream canvas]
[Display numeral countdown (mm:ss) at displayNumeralSize, ink, centered]
[Microcopy "time remaining"]
[Bar chart treatment as progress: a horizontal colorOrange bar that recedes over time,
 on a colorInk @ 0.1 baseline. No ring.]
[Orange "Cancel Timer" block at bottom — radiusBlock, cream ink]
```

No glow. The ring from the dark system is replaced by the bar treatment from
`ref02-warm-dashboard.jpg`.

### 3.6 SavedMixesView + SavedMixRowView — `screenshots/design-refs/ref01-orange-editorial.jpg`

```
[Cream canvas]
[Headline "Saved Mixes" + microcopy "your blends"]
[Peach intro block — radiusBlock — display numeral = saved count, microcopy "saved mixes"]
[Numbered editorial rows: "01 / Rain & Thunder  • 4 sounds  • ›"]
[Empty state: ink illustration, microcopy "no saved mixes yet"]
```

Row press scales 0.97 with `Tokens.tactilePress`. Trailing `›` chevron in ink. Long-press
opens the Rename / Delete menu.

### 3.7 NowPlayingBar — `screenshots/design-refs/ref01-orange-editorial.jpg`

The now-playing bar becomes a slim orange chevron block.

- Full width, 56pt tall, `radiusBlock` 20 on top corners only.
- Fill `Tokens.colorOrange`, ink text `Tokens.colorCream`.
- Left: count of playing sounds in subhead (Semibold) + microcopy "playing".
- Right: pause/play glyph in cream, then chevron up.
- Whole bar is the tap target — opens the Mixer sheet.
- Press scale 0.97 with `Tokens.tactilePress`. No glow.

### 3.8 Splash — `screenshots/design-refs/ref01-orange-editorial.jpg`

```
[Cream canvas]
[Centered wordmark "Next Sleep" — wordmark uses displayNumeralSize family, ink]
[Microcopy underneath: "editorial sleep"]
[After 0.6s, transition into the SoundsView with a downward chevron sweep]
```

### 3.9 Weekly Stats card (Insights surface intro card) — `screenshots/design-refs/ref02-warm-dashboard.jpg`

The Weekly Stats card is the one piece of the Insights tab in scope for this pass — it
is the editorial preview that links to the deeper Insights tab.

```
[radiusBlock, peach fill]
[2x2 stat tile grid inside:
   Tile A (cream): display numeral = total minutes this week, microcopy "minutes"
   Tile B (yellow): display numeral = sessions this week, microcopy "sessions"
   Tile C (cream): sparkline of nightly minutes
   Tile D (colorOrange fill, cream ink): display numeral = streak in days, microcopy "day streak"]
[Trailing chevron right inside the block, ink]
```

Tap opens the full Insights tab. Press scale 0.97 with `Tokens.tactilePress`.

---

## 4. Component contracts

### 4.1 Tokens namespace

`SoundScape/Sources/Presentation/Components/Tokens.swift` is the single source for
palette, geometry, type sizes, and motion. Views import nothing else for those values.

### 4.2 Editorial backgrounds

Replace `oledBackground()` usage on the in-scope screens with a plain `Tokens.colorCream`
background. The `OLEDBackgroundModifier` continues to exist for non-in-scope screens but
is not applied to anything in the editorial system.

### 4.3 Press behavior

A small `ScaleButtonStyle` (or equivalent `.buttonStyle`) implements the tactile press:

```swift
configuration.label
    .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    .animation(Tokens.tactilePress, value: configuration.isPressed)
```

All blocks, tiles, rows, and chips wire through this style.

---

## 5. Accessibility

1. **Reduce Motion:** disable the press scale (skip the `scaleEffect`) and the chart
   draw-in (`.easeOut(0.6)`) — render charts in final state on appear.
2. **Dynamic Type:** display numerals and headlines should scale up to `.accessibility3`
   without truncating critical content; allow microcopy to wrap to 2 lines.
3. **VoiceOver:** every block, tile, chevron, and chip has an `.accessibilityLabel`.
   The numbered "01" prefix is decorative — exclude with
   `.accessibilityElement(children: .ignore)` on the prefix, hoist the row label to the
   row container.
4. **Contrast:** all pairings in 2.1 are pre-verified. No new color combinations may be
   introduced without WCAG AA verification.
5. **Tap targets:** minimum 44×44pt. Editorial rows at 64pt clear this; chips, tiles, and
   chevrons must include `.contentShape(Rectangle())` to expand the hit area.

---

## 6. Anti-patterns (forbidden in editorial light system)

- Inline hex colors. Route through `Tokens`.
- `Color(.systemGray*)`, `Color.black`, `Color.white` literals in views — use `Tokens`.
- Purple accent on any in-scope screen. (The deprecated `Tokens.accentBrandLegacy`
  exists only for legacy screens; the compiler emits a deprecation warning if it is
  used.)
- Glow modifiers (`.shadow(color: glow, …)` for atmospheric purposes). Shadows are
  permitted only for elevation (≤ 4pt y-offset, 8pt blur, 6% ink).
- `.animation(.default, value: …)`. Pick a named spring.
- `easeAtmosphere`-style repeating drift loops.
- Reflective sheen on cards.
- Modal sheets without `.presentationDetents`.

---

## 7. Verification rubric

A redesign PR is mergeable when:

1. The build passes (`xcodebuild … build`).
2. All UI tests still pass.
3. Each of the nine in-scope surfaces matches its section 3 spec, referencing the named
   reference image.
4. Token grep clean — no inline hex strings on the in-scope screens:
   `grep -E "#[0-9A-Fa-f]{6}" SoundScape/Sources/Presentation/Sounds SoundScape/Sources/Presentation/Mixer SoundScape/Sources/Presentation/Timer SoundScape/Sources/Presentation/SavedMixes SoundScape/Sources/Presentation/Components` returns nothing.
5. VoiceOver pass: every block, tile, chip has a label.
6. Reduce Motion pass: press scale and chart draw-in are skipped.
7. The NowPlayingBar still hides/shows correctly on `activeSounds` transitions.
8. The 6-sound free-tier limit and paywall triggers are unchanged in behavior.

---

## 8. Reference image checklist

| Screen | Reference image | What it informs |
|---|---|---|
| SoundsView | `screenshots/design-refs/ref01-orange-editorial.jpg` | Orange hero block, chevron motif, numbered editorial rows |
| SoundCardView | `screenshots/design-refs/ref01-orange-editorial.jpg` | Tile fill + ink contrast, peach favorited state |
| MixerView | `screenshots/design-refs/ref02-warm-dashboard.jpg` | Stat tile dashboard layout, sparkline treatment |
| MixerSoundRowView | `screenshots/design-refs/ref01-orange-editorial.jpg` | Numbered row, slim slider with orange fill |
| SleepTimerView | `screenshots/design-refs/ref02-warm-dashboard.jpg` | Bar chart progress replacing ring, peach preset tiles |
| SavedMixesView / Row | `screenshots/design-refs/ref01-orange-editorial.jpg` | Peach intro block, numbered rows |
| NowPlayingBar | `screenshots/design-refs/ref01-orange-editorial.jpg` | Orange chevron block |
| Splash | `screenshots/design-refs/ref01-orange-editorial.jpg` | Wordmark + chevron sweep |
| Weekly Stats card | `screenshots/design-refs/ref02-warm-dashboard.jpg` | 2x2 stat tile grid, sparkline + streak callout |

---

## 9. SUPERSEDED — Legacy dark/OLED/purple appendix

> **Status: SUPERSEDED for in-scope screens.** The section below documents the previous
> "dark instrument" system that informed Binaural, Wind Down, Sleep Rec, Discover,
> Adaptive, Insights (except the Weekly Stats card), and Onboarding. These screens still
> use this system today and the deprecated `Tokens.accentBrandLegacy` purple alias exists
> for them. **Do not apply any of the specs below to the nine in-scope editorial screens.**

### 9.1 Legacy color tokens (SUPERSEDED)

| Token | Light | Dark (OLED) | Use |
|---|---|---|---|
| `BackgroundPrimary` | `Color(.systemBackground)` | `Color.black` | Screen background |
| `BackgroundElevated` | `Color(.systemGray6)` | `Color(.systemGray6).opacity(0.08)` | Card / row background, idle |
| `BackgroundElevatedActive` | `Color(.systemGray6)` | `Color(.systemGray6).opacity(0.15)` | Card / row background, playing |
| `Separator` | `Color.gray.opacity(0.15)` | `Color.white.opacity(0.06)` | Dividers, list separators |
| `AccentBrand` (purple `#7F6FD8`) | — | — | Legacy purple accent. Now exposed as `Tokens.accentBrandLegacy` and marked deprecated. |
| Category colors | Noise purple / Nature green / Weather blue / Fire orange / Music pink / ASMR lilac | same | Category coding, legacy screens only. |

### 9.2 Legacy geometry tokens (SUPERSEDED)

`RadiusCard` 16, `RadiusControl` 12, `RadiusBadge` 8, `SpacingEdge` 24, `SpacingSection`
16, `SpacingTight` 12, `SpacingHair` 4, `IconLarge` 60, `IconMedium` 40, `IconSmall` 22,
`TimerDisplay` 72pt thin. Still used by the legacy screens.

### 9.3 Legacy glow specs (SUPERSEDED)

Category-color glow on SoundCard (radius 16 / opacity 0.6 OLED), MixerRow glow,
purple Timer ring glow, NowPlayingBar glow. **All removed from the in-scope editorial
screens.** Glow modifiers continue to apply only on legacy screens.

### 9.4 Legacy motion tokens (SUPERSEDED)

`springStandard`, `springSnappy`, `springSoft`, `linearTimer`, `easeAtmosphere`. The
editorial light system uses `Tokens.tactilePress` instead; the legacy spring vocabulary
remains in service only for legacy screens.

### 9.5 Legacy typography (SUPERSEDED)

`.system(size: 72, weight: .thin, design: .rounded).monospacedDigit()` for the timer,
`.largeTitle.weight(.semibold)` for screen titles, `.headline.weight(.semibold)` for
section headers, `.subheadline.weight(.medium)` for body, `.caption` and
`.caption.monospacedDigit()` for meta. The editorial system replaces these with the
SF Pro Display / SF Pro Text pairing in Section 2.2.
