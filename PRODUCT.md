# Next Sleep — Product Specification

**Status:** Source of truth for product intent during the `/impeccable` core-surfaces polish pass.
**Audience:** Drift planner, clerk, reviewer; future product/design contributors.

---

## 1. Product positioning

Next Sleep is an **iOS-only ambient soundscape app for the moments around sleep**. It is not
a meditation course, a habit tracker, a sleep coach, or a content marketplace. It is the
quiet utility on a nightstand that turns the phone into a sound machine, a relaxation aid,
and a sleep-timer in three taps or fewer.

Closest references: **Endel** (generative aesthetic, dark, abstract), **Dark Noise** (utility
focus), **Calm** (warmth & comfort) — but with less talking, fewer guided artifacts, and
much sharper visual restraint.

---

## 2. Who this is for

### Primary user — "Tired Operator"

Someone in their late 20s to mid-40s who opens the app at night, in a dark room, with a
mind that won't slow down. They've used a sound machine before — they know what white noise
and rain sound like and they want to layer a few sounds, set a timer, and put the phone
face-down.

What they want from the next 60 seconds:

- Get a working soundscape running fast.
- Trust that the timer will fade audio gently, not jolt them awake.
- Stop seeing things on the screen.

What they don't want:

- A tour, a tutorial, a personality, or upbeat copy.
- A login.
- Anything that calls itself "wellness".

### Secondary user — "Focus Worker"

Same person at 2pm. Pulls up the app to mask office noise with rain + brown noise. Needs
the same speed-to-soundscape, doesn't care about the timer.

### Anti-persona — "Lifestyle Browser"

Not for someone who wants to browse curated playlists, read articles about sleep hygiene,
or be guided through a meditation. If this user is the dominant persona, we've drifted off
course.

---

## 3. The core flow this polish pass must protect and improve

```
App open
  → Sounds tab (dark, grid of categorized sounds)
    → Tap a sound (it starts playing, card glows)
    → Tap 1-3 more (mixing in the background)
    → Tap timer in toolbar
      → Pick "30 min"
      → Sheet dismisses, timer running
    → Lock screen / put phone down
```

This is the **three-tap-to-sleep** flow. Median user completes it in <20 seconds. Every
decision in this polish pass should be tested against the question: *does this make the
three-tap flow faster, calmer, or more trustworthy?* If a change makes the app prettier but
slower-to-complete, it loses.

### The four core surfaces' jobs

| Surface | Single job |
|---|---|
| **Sounds tab** | Get a sound playing in 1 tap from app open |
| **Mixer sheet** | Adjust the levels of what's already playing; never the place where you *start* sounds |
| **Timer sheet** | Pick a duration; get out of the way |
| **Saved Mixes sheet** | Restore a known-good combination in 1 tap |
| **NowPlayingBar** | Confirm something is playing; one-tap to mixer, one-tap to pause |

If any sheet ever needs the user to read more than one sentence, it's failed.

---

## 4. Success metrics

The polish pass succeeds if, after merge:

### Quantitative (instrumented via `AnalyticsService`)

| Metric | Current baseline (qualitative) | Target |
|---|---|---|
| **Median time from app open → first sound playing** | ~2-3s | ≤ 2s |
| **Median time to set timer (from open of timer sheet → dismiss)** | ~5s | ≤ 3s |
| **% of sessions that reach NowPlayingBar (any sound playing)** | unknown — instrument it | track + baseline |
| **% of mixer-opens that result in volume adjustment** | unknown | track + baseline |
| **Sheet abandonment rate (open → dismiss with no action)** | unknown | track + baseline |
| **App Store rating mentions of "beautiful" / "calming" / "looks great"** | minimal | increase |
| **App Store rating mentions of "confusing" / "cluttered"** | none expected | stays zero |

### Qualitative (gut-check)

- Side-by-side screenshot vs. Endel and Dark Noise: does Next Sleep belong in that company?
- "Bedside test": dim the phone to lowest brightness, open the app — does it still feel like
  the right tool, or does it feel like staring at a UI?
- "Five-second test": show a stranger a screenshot of the Sounds tab. Can they describe
  what the app does without being told?

---

## 5. Non-goals for this polish pass

These are explicit "no, not yet" items. If the drift planner proposes work on these, the
reviewer should reject the issue.

1. **No new features.** No new sounds, no new categories, no new screens.
2. **No new tabs.** The 7-tab structure stays. Even tabs that feel under-loved
   (Adaptive, Insights) are not in this pass's scope.
3. **No restructuring the navigation model.** Sheet-modals from the toolbar stay.
   Don't migrate to bottom tabs, side drawers, or full-screen modal flows.
4. **No backend/server changes.** Firebase, App Store Connect, paywall services all stay
   as-is.
5. **No engine-level audio changes.** Crossfades, gapless playback, binaural improvements
   are owned by other plans.
6. **No copy rewrites except where forced by visual changes.** Localized strings stay; if a
   layout requires a shorter label, ask before rewording.
7. **No paywall UX changes.** The free-tier 6-sound limit and the paywall sheets stay
   exactly as they are. Visual polish only if the sheets themselves are in scope (and they
   are not).
8. **No accessibility regressions.** This isn't a non-goal — it's a hard floor.

---

## 6. Risks & how the plan should mitigate them

| Risk | Mitigation |
|---|---|
| Agent over-refactors and introduces SwiftUI architecture changes | Each issue scopes to *one file* or *one component contract* where possible; reviewer rejects cross-cutting refactors |
| Agent invents new design tokens not in DESIGN.md | DESIGN.md is the single source of truth for tokens; planReviewer flags any "new color" / "new spring" introduced |
| Agent breaks the 6-sound paywall gating | Verifier runs UI test suite which covers paywall trigger; reviewer reads diff for `paywallService.triggerPaywall` removals |
| Sheet behavior breaks (analytics events, auto-dismiss) | Every sheet polish issue must preserve the existing `onAppear` analytics and `onChange` auto-dismiss logic |
| Build time blows up due to over-styled components | If `xcodebuild` runtime increases >25%, reviewer flags. Aim for the same compile budget |
| OLED dark mode breaks for users with light mode preference | Every component must be verified in both `.preferredColorScheme(.dark)` and `.light` previews |

---

## 7. Tracking & validation after merge

Once the plan merges to master:

1. **TestFlight build** to 5-10 beta users (existing TestFlight cohort).
2. **One-week observation window** on the metrics in §4.
3. **Qualitative review**: Mert does the "bedside test" nightly for 7 days.
4. **Rollback criterion**: if any of the existing UI tests start failing post-merge, or if
   App Store ratings drop, revert and revisit.

---

## 8. Definition of done

The `/impeccable` polish pass is "done" when:

- All issues in the plan are closed.
- The branch's final-review verdict is APPROVE (or SHIP_AS_IS with a documented reason).
- The build is green; all tests pass.
- A side-by-side screenshot of each of the four core surfaces — before and after — shows
  clear visual improvement and zero regressions of behavior.
- DESIGN.md and PRODUCT.md remain accurate descriptions of the shipped state. (If they
  diverged, update them in the same PR.)

---

## 9. Glossary (terms drift will see in issues)

- **Core surfaces**: Sounds tab + Mixer sheet + Timer sheet + Saved sheet + NowPlayingBar.
- **OLED mode**: dark mode with pure black backgrounds (`#000`) and category-color glows.
- **The bar**: NowPlayingBarView.
- **Sheet**: SwiftUI `.sheet(isPresented:)` modal, presented from the Sounds tab toolbar.
- **Three-tap-to-sleep**: the design north-star flow from §3.
- **Tier limit**: the free-tier 6-sound mixer cap; touching its behavior is out of scope.
