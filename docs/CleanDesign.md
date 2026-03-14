# Next Sleep - Design Simplification Analysis

> "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away."
> -- Antoine de Saint-Exupery

This document analyzes every screen in the Next Sleep app for unnecessary complexity, redundant elements, and opportunities to distill the design to its essence. Each recommendation serves the app's core design principles: **calm by default**, **dark is home**, **disappearing UI**, **contrast matters**, and **motion with purpose**.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Issues (Must Fix)](#critical-issues)
3. [Screen-by-Screen Analysis](#screen-by-screen-analysis)
4. [Cross-Cutting Concerns](#cross-cutting-concerns)
5. [Tab Architecture](#tab-architecture)
6. [Component Library](#component-library)
7. [Performance Concerns](#performance-concerns)
8. [Priority Roadmap](#priority-roadmap)

---

## Executive Summary

### Overall Complexity Score: 6.5/10

Next Sleep is a feature-rich app with ambitious visual effects, but it suffers from **feature accumulation without consolidation**. The core experience (browse sounds, mix, set timer, sleep) is buried under 7 tabs, 18+ injected services, and screens that show the same information in multiple ways.

### Top 5 Systemic Issues

| # | Issue | Impact | Screens Affected |
|---|-------|--------|------------------|
| 1 | **7 tabs exceed usable limit** | Users can't find features; cognitive overload | All |
| 2 | **Favorites accessible from 3 places** | Redundant UI, duplicated code | SoundsView, FavoritesView, CategoryFilter |
| 3 | **Information shown 3-4 ways simultaneously** | Visual noise, wasted space | BuddyStatusCard, PaywallView, SleepGoalView |
| 4 | **18+ services injected at app level** | Fragile initialization, deep coupling | SoundScapeApp, ContentView |
| 5 | **WindDown screen has 30+ interactive elements** | Overwhelming at bedtime | WindDownView |

### What Works Well

- OLED mode implementation is thoughtful and consistent
- PremiumLockOverlay is clean, single-responsibility
- Onboarding flow is well-paced (except paywall card redundancy)
- Data visualizations (SleepTimeline, WeeklyChart) are focused and clear
- AlarmRingingView animations are appropriate for emergency context
- Sleep recording controls handle complex state well

---

## Critical Issues

### 1. WindDown: Information Overload (Severity: HIGH)

**Problem:** WindDown is the most cluttered screen. Users see 30+ interactive elements, content duplicated across 4 different layouts (Featured card, Continue Listening cards, Category grid cards, Player), and 6 different category colors competing for attention.

**Current state:**
- Featured card: badge + title + description + narrator + duration + progress + play button (7 elements in 180pt)
- Same content appears in: Featured section, Continue Listening, Category grids, Player (4 representations)
- 6 category sections x 4+ items each = 24+ tappable cards on single scroll

**Recommendations:**
- Use ONE card template with size variations (not 4 different layouts)
- Remove decorative 80pt icons from cards (non-informational)
- Hide narrator on cards; show only in player
- Remove progress bars from cards; show only in player
- Cap category sections at 3 items with "See All" link
- Reduce to 3 category colors max (rotate across categories)

**Estimated complexity reduction:** 40-50% fewer visual elements

---

### 2. Favorites: Triple Redundancy (Severity: HIGH)

**Problem:** Favorites is accessible from 3 separate entry points with duplicated code:
1. Favorites section at top of SoundsView (always visible)
2. "Favorites" chip in CategoryFilterView
3. Dedicated Favorites tab (entire separate view)

All three render the same SoundCardView with identical paywall/mixer logic duplicated.

**Recommendations:**
- **Eliminate Favorites tab entirely** -- access via "Favorites" chip only
- **Remove favorites section from SoundsView top** -- only show when chip selected
- **Extract mixer limit logic** to PremiumManager (currently duplicated in SoundsView + FavoritesView)
- One entry point, one code path

**Estimated code reduction:** ~200 lines removed, 1 tab eliminated

---

### 3. SoundsView Toolbar: Too Many Competing Actions (Severity: MEDIUM-HIGH)

**Problem:** SoundsView toolbar has 3 trailing buttons (mixer, timer, saved mixes) plus a conditional ASMR info button on the leading side. Combined with the category filter chips (8+ buttons), the top of the screen is dense and competing.

**Current state:**
- Leading: Settings gear + conditional ASMR info button
- Trailing: Mixer slider + Timer moon + Saved folder
- Below: 8+ category filter chips in horizontal scroll
- 5 sheet modals managed simultaneously

**Recommendations:**
- Replace 3 trailing toolbar buttons with single "Tools" menu button (mixer, timer, saved as menu items)
- Move ASMR info to section header when ASMR category is selected
- Reduce sheet modal count by using inline interactions where possible

---

### 4. BuddyStatusCard: Streak Shown 4+ Ways (Severity: MEDIUM)

**Problem:** A single data point (streak count) is communicated through 4+ simultaneous visual indicators:
1. Badge with emoji + number (e.g., "7")
2. Message text ("One week strong!")
3. 7 progress dots (filled/empty circles)
4. "+X" overflow text for streaks > 7

**Recommendations:**
- Show streak in ONE way: badge (emoji + number) + 7-dot progress
- Remove message text and overflow text
- Apply same principle to BuddyStatusCard avatar (single color for both users)

---

### 5. Settings: Sleep Buddy Row Over-Engineering (Severity: MEDIUM)

**Problem:** A "Coming Soon" feature has 5 visual state changes on tap:
- Icon color changes (purple -> gray)
- Text changes dynamically
- Arrow icon changes (chevron -> clock)
- Arrow color changes (gray -> orange)
- Entire row becomes disabled

**Recommendations:**
- Remove all interactive behavior for unreleased features
- Show as static gray card with "Coming Soon" badge
- Or remove from Settings entirely until launch

---

### 6. Paywall: Pricing Card Selection Redundancy (Severity: MEDIUM)

**Problem:** When selecting yearly vs monthly plan, 4 visual indicators change simultaneously:
1. Background color fills
2. Border stroke appears
3. Selection circle indicator
4. Disabled state opacity on unselected

**Recommendations:**
- Use ONLY background color + checkmark circle for selection
- Remove border stroke and disabled opacity changes
- Keep "Save X%" badge (conversion driver)

---

## Screen-by-Screen Analysis

### Sounds Tab

#### SoundsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | 5 sheet modals, 10 environment injections, 12 @State variables |
| Hierarchy | 5/10 | Favorites section + Favorites chip + toolbar buttons all compete |
| Information Density | 7/10 | 2-column grid with glow effects, borders, overlays per card |

**Key issues:**
- 10 environment object injections is excessive for a single view
- Paywall logic (`wouldExceedMixerLimit()`) duplicated inline instead of in service
- ASMR first-visit logic shows sheet automatically -- could be onboarding instead

**Simplify:**
- Remove Favorites section; only show via chip filter
- Extract sheet state to coordinator/container view
- Move paywall checks to PremiumManager service

#### SoundCardView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | 3 visual layers when playing (glow, blur, mini visualization) |
| Redundancy | Medium | Shadow + border both use category color |

**Simplify:**
- Remove mini visualization overlay (icon + glow is sufficient feedback)
- Use shadow OR stroke for playing state, not both
- Simplify heart animation to single spring (currently fires twice with async dispatch)
- Remove unused MotionService injection

#### CategoryFilterView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 3/10 | Clean, focused filter bar |

**Simplify:**
- Remove "All" chip (unselected state = all sounds)
- Remove "Favorites" chip (deduplicate with dedicated entry point)

---

### Mixer (Sheet Modal)

#### MixerView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | Visualization + controls compete for space |
| Hierarchy | 6/10 | Pause + Stop buttons overlap in purpose |

**Simplify:**
- Combine pause/stop into single button with menu (Pause | Stop | Clear All)
- Make visualization collapsible or remove from mixer (it's in Sounds tab too)
- Simplify header: show "(N) sounds" only, not fraction + lock icon

#### MixerSoundRowView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 3/10 | Clean row design |

**Simplify:**
- Remove percentage text display (slider alone communicates volume; show only while dragging)
- Remove speaker icon (slider is self-explanatory)

---

### Timer (Sheet Modal)

#### SleepTimerView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | Progress ring is large (200x200) for a simple countdown |

**Simplify:**
- Replace 3x2 preset grid with segmented control or horizontal scroll
- Use consistent moon icon style across states (not .fill in one, plain in other)
- Remove "Fading out..." text label (progress indicator speaks for itself)

---

### Saved Mixes (Sheet Modal)

#### SavedMixesView / SavedMixRowView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 4/10 | Reasonable list design |
| Discovery | Low | Swipe actions split between two edges (left for rename, right for delete) |

**Simplify:**
- Use long-press context menu instead of swipe actions (Play | Rename | Delete)
- Simplify row: show only mix name + sound count (hide sound names and date)
- Replace rename alert with inline text field editing

#### SaveMixSheet
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 2/10 | Already minimal |

**Enhance:** Auto-generate name like "Evening Mix - 8:30 PM" as default

---

### Binaural Tab

#### BinauralBeatsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | 6 lock overlays create repetitive visual noise |
| Information Density | 6/10 | Each card shows 3 lines of text + icon + lock |

**Simplify:**
- Remove redundant card styling (use fill OR stroke for selection, not both)
- Make headphone notice dismissible (currently persistent)
- Consolidate tone type + base frequency into single control or move frequency to "Advanced"
- Show only brainwave name + Hz on card; move description to detail view

---

### Wind Down Tab

#### WindDownView (Most Complex Screen)
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 8.5/10 | 30+ interactive elements, 4 content representations |
| Information Density | 8/10 | Featured card alone has 7 elements in 180pt |
| Hierarchy | 4/10 | Featured not visually distinct from grid items |

**Simplify (Major Overhaul):**
- Use single card template with size variants (not 4 different layouts)
- Remove decorative 80pt icons from all cards
- Hide narrator on cards (show in player only)
- Remove progress bars from cards (show in player only)
- Remove "FEATURED" badge (section header is sufficient)
- Reduce player background from 3 gradient layers to 1
- Timer sheet: reduce to 5 options (5/15/30/60 min + End of Content)

---

### Sleep Recording Tab

#### RecordingControlsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | Appropriate for live recording context |
| State Management | Good | Clear state transitions |

**Simplify:**
- Consolidate delay cancel options (single cancel method, not two)
- Collapse delay options behind a button tap (not always visible)

#### SleepReportView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | Data-heavy but appropriate |
| Visualization | Good | Timeline chart is well-designed |

**Simplify:** Minimal changes needed -- data visualization complexity is justified

#### AudioHighlightsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | Top moments section duplicates full events list |

**Simplify:**
- Combine top moments + full list into single sortable list
- Add collapsible "Top Moments" section at top

---

### Discover Tab

#### DiscoverView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | Standard browse pattern |
| Dependencies | High | 5 service injections for a browsing screen |

**Simplify:**
- Remove stats from horizontal scroll cards (not readable at 140px width)
- Consolidate Play + Save to single action menu

#### MixDetailView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | FlowLayout is 285 lines for tag wrapping |
| Dead Code | Share button non-functional |

**Simplify:**
- Remove non-functional Share button
- Collapse sounds section to top 5 with expandable remainder
- Remove tags section (already visible on card)

---

### Adaptive Tab

#### ActiveAdaptiveSessionView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | 253 lines for single screen |
| Redundancy | Progress shown twice (percentage + bar), phase position shown twice (header + timeline) |

**Simplify:**
- Collapse timeline to show only current + next phase by default
- Remove "Session Active" label (obvious from context)
- Show progress as bar + percentage only (not also elapsed/total time labels)

#### AdaptiveView (Premium Preview)
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | 95 lines for upsell is excessive |

**Simplify:**
- Reduce premium preview to smaller card (not full-screen takeover)
- Cap feature list to 2 items with "See more"

---

### Insights Tab

#### InsightsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | Free tier shows 4 grayed locked sections |
| UX Issue | Locked sections are clickable but do nothing useful |

**Simplify:**
- Hide locked sections entirely on free tier (don't show grayed out placeholders)
- Consolidate upsell to single card, not 4 locked section ghosts
- Merge basic stats + usage stats into single card

#### SleepGoalView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | 124 lines for single metric is excessive |
| Redundancy | Actual hours shown in ring center AND in legend |

**Simplify:**
- Remove legend entirely (ring is self-explanatory with center label)
- Simplify to: ring + percentage + one-line status

#### TopSoundsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 4/10 | Reasonable ranked list |
| Issue | Hardcoded sound name dictionary duplicates data from LocalSoundDataSource |

**Simplify:**
- Pull sound icons from shared data source (not hardcoded dictionary)
- Show top 5 only; hide rest behind "See more"

#### RecommendationsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 4/10 | Reasonable card layout |
| Dead Code | Play button is non-functional |

**Simplify:**
- Remove non-functional play button
- Simplify confidence to just colored dot (remove text label)

---

### Alarms

#### AlarmDetailView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 4/10 | Clean form layout |
| Consistency | Inconsistent picker styles (.wheel vs .menu) |

**Simplify:**
- Hide Volume Ramp & Snooze under expandable "Advanced" section
- Provide quick-select repeat patterns (Once, Daily, Weekdays, Weekends) before full week selector

#### AlarmRingingView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 6/10 | High but justified for emergency context |

**No changes** -- animations serve functional purpose (grab sleeping user's attention)

---

### Settings

#### SettingsView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | Gradient overuse, Sleep Buddy over-engineering |
| Hierarchy | 5/10 | Mixed purposes (display, premium, social, science, about) |

**Simplify:**
- Remove Sleep Buddy interactive behavior entirely (static "Coming Soon" only)
- Remove gradient from "SUPER BLACK" text (use solid color)
- Group: Display Settings | Premium | About (separate sections clearly)

---

### Onboarding

#### OnboardingPaywallView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | Intentional for conversion, but pricing cards have 4 selection indicators |

**Simplify:**
- Pricing cards: use ONLY background color + checkmark (remove border + disabled opacity)
- Show 4 key features with "See all benefits" link
- Collapse legal auto-renewal terms

#### OnboardingQuizGoalView / OnboardingQuizChallengesView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 5/10 | 4+ visual state changes per card on selection |

**Simplify:**
- Reduce to 2 visual indicators per card (checkmark + background color)
- Show remaining selections counter on challenges view

#### Other Onboarding Screens
| Screen | Rating | Notes |
|--------|--------|-------|
| Welcome | 2/10 | Minimal, focused |
| PainPoints | 3/10 | Clean carousel |
| Benefits | 3/10 | Remove redundant checkmark icons |
| Features | 4/10 | Animations justified |
| Analysis | 3/10 | Good progress pattern |
| Results | 3/10 | Clean presentation |
| Reviews | 3/10 | Effective social proof |
| CustomPlan | 5/10 | Personalization justifies complexity |
| Complete | 2/10 | Appropriate celebration |

---

### Sleep Buddy

#### SleepBuddyView / BuddyStatusCard
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 7/10 | Streak redundancy (4 representations) |

**Simplify:**
- Show streak one way: badge (emoji + number) + 7-dot progress
- Remove message text and "+X" overflow
- Use single avatar color for both users

#### InviteBuddyView
| Aspect | Rating | Notes |
|--------|--------|-------|
| Clutter | 4/10 | Well-designed dual-mode sheet |

**No changes** -- clean implementation

---

## Cross-Cutting Concerns

### 1. Service Architecture (18+ Services)

**Current:** 18-20 services created as `@State` in SoundScapeApp, manually wired in `onAppear` with 40+ lines of imperative setup.

**Problems:**
- Deep dependency graph hard to trace
- Manual wiring is fragile (no compile-time safety)
- All services initialized eagerly even if unused

**Recommendation:**
- Create `ServiceContainer` class that manages lifecycle and wiring
- Group related services: AudioServices, AnalyticsServices, StorageServices
- Consider merging: `InsightsService` + `AnalyticsService`, `ReviewPromptService` into `AnalyticsService`

### 2. Theme & Color Fragmentation

**Current:** Colors hardcoded throughout codebase:
- `.purple` referenced 20+ times (should be centralized)
- OLED opacity values (0.1, 0.2, 0.3) hardcoded in 4 modifiers
- Category colors defined in `Sound.swift` but often re-derived in views
- ASMR purple `Color(red: 0.8, green: 0.6, blue: 1.0)` defined in multiple files

**Recommendation:**
- Create `AppTheme` struct with all design tokens
- Reference `Sound.category.color` instead of re-deriving
- Name opacity constants: `OLEDTheme.cardOpacity`, `OLEDTheme.glowIntensity`

### 3. Sheet Modal Complexity

**Current:** At least 3-4 concurrent sheet modals possible:
- ContentView manages showMixerSheet, showingSleepContentPlayer
- SoundsView manages 5 sheets (mixer, timer, saved, settings, ASMR)
- MixerView has sub-sheets
- Creating 3-layer deep navigation paths users can't escape

**Recommendation:**
- Create `SheetManager` service to coordinate modal presentation
- Prevent nested sheets (one sheet at a time)
- Use navigation instead of sheets for drill-down content

### 4. Duplicated Business Logic

| Logic | Duplicated In | Should Be In |
|-------|---------------|--------------|
| `wouldExceedMixerLimit()` | SoundsView, FavoritesView | PremiumManager |
| Paywall trigger flow | SoundsView, FavoritesView, DiscoverView, AdaptiveView, InsightsView | PaywallService (single entry point) |
| Category color derivation | Sound.swift, SoundCardView, multiple views | Sound.category.color (single source) |
| Save mix conversion | DiscoverView (`saveMix` + `performSaveMix`) | SavedMixesService |

---

## Tab Architecture

### Current: 7 Tabs (Too Many)

| # | Tab | Monthly Active Usage (Estimated) |
|---|-----|----------------------------------|
| 1 | Sounds | Daily (core feature) |
| 2 | Binaural | Weekly (niche) |
| 3 | Wind Down | Daily (content) |
| 4 | Sleep Rec | Weekly (recording) |
| 5 | Discover | Occasional (browse) |
| 6 | Adaptive | Occasional (contextual) |
| 7 | Insights | Weekly (analytics) |

Apple HIG recommends 3-5 tabs. 7 tabs means small touch targets, cognitive overload, and features that users never discover.

### Proposed: 5 Tabs

| # | Tab | Contents |
|---|-----|----------|
| 1 | **Sounds** | Sound library + Mixer/Timer/Saved (unchanged) |
| 2 | **Binaural** | Brainwave entrainment (unchanged) |
| 3 | **Sleep** | Wind Down content + Sleep Recording (merged) |
| 4 | **Explore** | Discover community mixes + Adaptive sessions (merged) |
| 5 | **Insights** | Sleep analytics (unchanged) |

**Rationale:**
- Wind Down and Sleep Recording are both "nighttime activities" -- merge under "Sleep"
- Discover and Adaptive are both "explore new soundscapes" -- merge under "Explore"
- Sounds and Binaural are distinct enough modalities to keep separate
- Favorites eliminated as tab (accessible via chip filter in Sounds)

---

## Component Library

### Well-Designed Components (Keep As-Is)

| Component | Why It Works |
|-----------|-------------|
| **PremiumLockOverlay** | Single responsibility, callback-based, no service dependency |
| **WeekdaySelector** | Clean circular buttons, clear state, reusable |
| **UsageStatisticsView** | Simple 3-stat layout with dividers |
| **MetricsGridView** | Focused 3-column grid |
| **WeeklySleepChartView** | Clean bar chart, meaningful color coding |

### Components Needing Simplification

| Component | Issue | Fix |
|-----------|-------|-----|
| **OLEDBackgroundModifier** (x4) | 4 separate modifiers with repeated logic | Consolidate into single parameterized modifier with `OLEDStyle` enum |
| **ReflectiveSheenModifier** | Gyroscope-based radial gradient on every frame | Throttle to 30fps; simplify to pitch-only (app used in portrait) |
| **Visualization layers** (x6) | Mini variants are separate reimplementations | Scale single visualization instead of reimplementing at smaller sizes |
| **ASMRInfoView + SoundScienceView** | Similar structure, no shared component | Extract `EducationalContentView` base |

### Missing Components

| Need | Why |
|------|-----|
| `AppTheme` struct | Centralize all design tokens (colors, radii, spacing, opacity) |
| `SheetManager` | Coordinate modal presentation, prevent nesting |
| `ServiceContainer` | Replace 18 individual @State injections |
| `EducationalContentView` | Shared layout for ASMRInfo, SoundScience, and future educational content |

---

## Performance Concerns

### Memory Leaks (Critical)

1. **ParticleLayer & FlowLayer** -- `Timer.scheduledTimer()` never invalidated on view removal
2. **MotionService** -- Continuous gyroscope polling with no power management

### Rendering Overhead

| Source | Cost | Mitigation |
|--------|------|------------|
| 6 visualization types at 60fps | High | Throttle to 30fps; use `drawingGroup()` for GPU compositing |
| ReflectiveSheen per card | Medium | Throttle motion updates; disable when scrolling |
| NowPlayingBar waveform | Low | 3 bars, acceptable |
| Multiple TimelineViews | Medium | Share single timeline across visualizations |

### Recommendations

1. **Fix timer leaks immediately** -- Cancel timers in `.onDisappear` or use `TimelineView` instead
2. **Throttle MotionService** -- Update at 30fps max, pause when app backgrounded
3. **Profile at max load** -- Test with 6 sounds playing simultaneously (all visualization types active)
4. **Add `drawingGroup()`** -- To Canvas-based visualizations for GPU rendering

---

## Priority Roadmap

### Phase 1: Quick Wins (1-2 days each)

| # | Change | Impact | Effort |
|---|--------|--------|--------|
| 1 | Remove Favorites tab; use chip filter only | Eliminate duplicate code, reduce tab count to 6 | Low |
| 2 | Fix Sleep Buddy Settings row (static "Coming Soon") | Remove confusing interactive state | Low |
| 3 | Remove non-functional buttons (Share in MixDetail, Play in Recommendations) | Dead code cleanup | Low |
| 4 | Simplify paywall pricing card selection (2 indicators, not 4) | Cleaner conversion UX | Low |
| 5 | Fix ParticleLayer/FlowLayer timer leaks | Prevent memory leaks | Low |

### Phase 2: Moderate Effort (3-5 days each)

| # | Change | Impact | Effort |
|---|--------|--------|--------|
| 6 | Merge tabs: 7 -> 5 (Sleep + Explore consolidation) | Major UX improvement | Medium |
| 7 | Simplify WindDown cards (single template, hide narrator/progress) | 40-50% fewer elements | Medium |
| 8 | Create AppTheme struct; centralize design tokens | Consistency, easier theming | Medium |
| 9 | Extract mixer limit / paywall logic to services | Remove 5+ code duplications | Medium |
| 10 | Consolidate SoundsView toolbar (single menu button) | Reduce toolbar clutter | Medium |

### Phase 3: Architecture (1-2 weeks)

| # | Change | Impact | Effort |
|---|--------|--------|--------|
| 11 | Create ServiceContainer (replace 18 @State injections) | Cleaner initialization, testability | High |
| 12 | Create SheetManager (prevent nested modals) | Better navigation UX | Medium |
| 13 | Consolidate OLED modifiers into single parameterized system | Less code, easier maintenance | Medium |
| 14 | Unify visualization mini variants (scale, don't reimplement) | Remove duplicate rendering code | High |
| 15 | Throttle MotionService + add performance profiling | Battery life, smooth scrolling | Medium |

---

## Appendix: Screen Complexity Scores

| Screen | Clutter | Info Density | Interactive Elements | Priority |
|--------|---------|-------------|---------------------|----------|
| **WindDownView** | **8.5/10** | **8/10** | **30+** | **Critical** |
| SoundsView | 7/10 | 7/10 | 9+ per card | High |
| SettingsView | 7/10 | 5/10 | 15+ | High |
| BuddyStatusCard | 7/10 | 7/10 | 0 (display) | Medium |
| BinauralBeatsView | 7/10 | 6/10 | 12 | Medium |
| ActiveAdaptiveSessionView | 7/10 | 6/10 | 1 | Medium |
| OnboardingPaywallView | 7/10 | 7/10 | 12+ | Medium |
| AudioHighlightsView | 6/10 | 6/10 | 10+ | Low |
| SleepReportView | 6/10 | 7/10 | 4 | Low (justified) |
| DiscoverView | 5/10 | 5/10 | 5 | Low |
| MixerView | 5/10 | 4/10 | 4+ | Low |
| SleepTimerView | 5/10 | 4/10 | 7 | Low |
| RecordingControlsView | 5/10 | 4/10 | 14+ | Low (justified) |
| AlarmDetailView | 4/10 | 4/10 | 12 | Low |
| SavedMixesView | 4/10 | 4/10 | 3+ per row | Low |
| InsightsView | 6/10 | 5/10 | 3 | Medium |
| FavoritesView | 6/10 | 6/10 | per card | Eliminate |
| CategoryFilterView | 3/10 | 2/10 | 8 | Low |
| MixerSoundRowView | 3/10 | 3/10 | 3 | Low |
| SaveMixSheet | 2/10 | 2/10 | 3 | None |
| OnboardingWelcomeView | 2/10 | 2/10 | 1 | None |
| AlarmRowView | 2/10 | 3/10 | 1 | None |
| OnboardingCompleteView | 2/10 | 2/10 | 1 | None |
