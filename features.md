---
base_branch: master
max_retries: 2
continue_on_failure: false
visual_gate_enabled: true
visual_gate_threshold: 0.7
bundle_id: com.StudioNext.SoundScape
action_logging: true

# Deep Quality Mode - Enabled for premium features (critical for monetization)
deep_quality_mode: true
deep_quality_max_retries: 5
deep_quality_visual_threshold: 0.85
deep_quality_min_test_coverage: 0.7
deep_quality_review_gate: true
---

# Feature Queue: SoundScape Freemium/Premium System

This queue implements a lightweight freemium model where ~50% of the app is free and premium features are gated behind Superwall paywalls. The system uses a centralized `PremiumManager` service for all entitlement checks.

## Architecture Overview

- **PremiumManager**: New `@Observable` service that centralizes all premium feature logic
- **PaywallService**: Already exists - triggers Superwall with `campaign_trigger` placement
- **UI Pattern**: Lock icon + blur overlay on premium content, tap triggers paywall

---

### 1. Create PremiumManager Service

Create a centralized `PremiumManager` service that defines which features are free vs premium and provides helper methods for checking entitlements throughout the app.

**User Story:** As a developer, I want a single source of truth for premium features so that entitlement checks are consistent across the app.

**Acceptance Criteria:**
- New file at `Sources/Data/Services/PremiumManager.swift`
- `@Observable` class with `@MainActor` attribute
- Enum `PremiumFeature` listing all gated features:
  - `.sound(id: String)` - Premium sounds
  - `.unlimitedMixing` - More than 2 sounds in mixer
  - `.binauralBeat(state: BrainwaveState)` - Premium brainwave states (all except Alpha)
  - `.adaptiveMode` - Full Adaptive tab
  - `.fullInsights` - Advanced analytics/charts
  - `.windDownContent(id: String)` - Premium Wind Down content
  - `.discoverSave` - Save community mixes
- Property `freeSoundIds: Set<String>` with ~50% of sounds (one from each category minimum)
- Property `freeWindDownIds: Set<String>` with ~50% of Wind Down content
- Method `isPremiumRequired(for feature: PremiumFeature) -> Bool`
- Method `checkAccessOrTriggerPaywall(for feature: PremiumFeature, paywallService: PaywallService, onGranted: @escaping () -> Void)`
- Inject `PaywallService` to check `isPremium` status
- Initialize in `SoundScapeApp.swift` and inject via `.environment()`

**Free Sounds (14 of 34 total):**
- Noise: `white_noise`, `brown_noise`
- Nature: `morning_birds`, `calm_ocean`, `meadow`
- Weather: `rain_storm`, `thunder`
- Fire: `campfire`
- Music: `creative_mind`, `ambient_melody`
- ASMR: `page_turning`, `gentle_tapping`, `mechanical_keyboard`, `winter_forest_walk`

**Free Wind Down Content (8 of 19 total):**
- Yoga Nidra: `yoga_nidra_5min` (Quick Yoga Nidra)
- Sleep Stories: `story_clockmakers_gift`, `story_garden_between_stars`
- Sleep Hypnosis: `hypnosis_floating`
- Affirmations: `affirmation_gratitude`, `affirmation_peace`, `affirmation_release`
- Breathing: All (when available - free tier wellness feature)

**Priority:** 1
**Dependencies:** None

---

### 2. Add Premium Lock UI Component

Create a reusable `PremiumLockOverlay` view modifier that shows a lock icon with blur effect on premium content, and triggers the paywall when tapped.

**User Story:** As a free user, I want to see what premium content looks like (blurred with lock) so I understand what I'm missing and can tap to upgrade.

**Acceptance Criteria:**
- New file at `Sources/Presentation/Components/PremiumLockOverlay.swift`
- View modifier `.premiumLocked(isPremium: Bool, feature: PremiumFeature, paywallService: PaywallService)`
- When `isPremium == false` and feature requires premium:
  - Apply subtle blur (radius ~6) to content
  - Overlay lock icon (SF Symbol `lock.fill`) centered
  - Add subtle gradient overlay for visibility
  - Tap gesture triggers `paywallService.triggerPaywall(placement: "campaign_trigger")`
- When `isPremium == true`, show content normally with no overlay
- Lock icon should have a subtle animation on appear (scale or fade)
- Support both card-style content and list rows

**Priority:** 2
**Dependencies:** 1

---

### 3. Gate Premium Sounds in Sound Library

Apply premium gating to sounds in the main Sounds tab. Premium sounds show the lock overlay, and tapping them triggers the paywall.

**User Story:** As a free user, I can see all sounds in the library but premium ones are locked with a blur overlay. Tapping a locked sound shows the paywall.

**Acceptance Criteria:**
- Modify `SoundCardView.swift` to check `PremiumManager.isPremiumRequired(for: .sound(id:))`
- Apply `PremiumLockOverlay` to premium sound cards
- Tapping a locked sound triggers paywall via `campaign_trigger`
- After successful purchase, sound becomes immediately playable (PaywallService updates `isPremium`)
- Free sounds remain fully playable with no changes
- Premium sounds show lock icon in bottom-right corner of card
- Category sections show mix of free and locked sounds
- Search results respect premium status

**Priority:** 3
**Dependencies:** 1, 2

---

### 4. Gate Mixer to 2 Sounds for Free Users

Limit free users to mixing only 2 sounds simultaneously. Show paywall when attempting to add a 3rd sound.

**User Story:** As a free user, I can mix up to 2 sounds together. When I try to add a 3rd sound, I see the paywall to upgrade for unlimited mixing.

**Acceptance Criteria:**
- Modify `MixerView.swift` and `AudioEngine.swift`
- Add check in `AudioEngine.playSound()` for active sound count
- If `activeSounds.count >= 2` and `!isPremium`:
  - Show alert or sheet explaining "Upgrade for unlimited mixing"
  - Trigger paywall with `campaign_trigger`
  - If user upgrades, allow adding the sound
- Mixer UI shows subtle "PRO" badge on unlimited mixing feature
- Free users see their 2-sound limit clearly (e.g., "2/2 sounds" vs premium's "2/∞")

**Priority:** 4
**Dependencies:** 1

---

### 5. Gate Binaural Beat Brainwave States

Limit free users to Alpha brainwave state only. Other states (Delta, Theta, Beta, Gamma) show lock and trigger paywall.

**User Story:** As a free user, I can use Alpha binaural beats for free. When I tap other brainwave states, I see they're premium and can upgrade.

**Acceptance Criteria:**
- Modify `BinauralBeatsView.swift`
- `PremiumManager` defines `freeBrainwaveStates: [BrainwaveState] = [.alpha]`
- Premium states: Delta, Theta, Beta, Gamma
- Apply `PremiumLockOverlay` to premium state buttons
- Tapping locked state triggers paywall
- Alpha state remains fully functional for all users
- After upgrade, all states unlock immediately
- State picker shows lock icon on premium options

**Priority:** 5
**Dependencies:** 1, 2

---

### 6. Gate Wind Down Premium Content

Apply premium gating to Wind Down content. About half the content is free, rest requires premium.

**User Story:** As a free user, I can access some Wind Down content (basic yoga nidra, some stories) but premium content like full hypnosis sessions and advanced meditations are locked.

**Acceptance Criteria:**
- Modify `WindDownView.swift` and `SleepContentCardView.swift`
- Check `PremiumManager.isPremiumRequired(for: .windDownContent(id:))`
- Apply `PremiumLockOverlay` to premium content cards
- Free content plays normally
- Premium content shows lock overlay with blur
- Tapping locked content triggers paywall
- After upgrade, content unlocks immediately
- Category headers may show "(X free / Y total)" count

**Free Content:**
- Quick Yoga Nidra (5min)
- 2 Sleep Stories (The Clockmaker's Final Gift, The Garden Between Stars)
- 1 Sleep Hypnosis (Floating Into Dreams)
- All 3 Affirmations (wellness feature stays free)
- All Breathing exercises when available (wellness feature)

**Priority:** 6
**Dependencies:** 1, 2

---

### 7. Gate Adaptive Mode Tab

Make the entire Adaptive tab a premium feature. Free users see a preview with paywall CTA.

**User Story:** As a free user, I see the Adaptive tab but it shows a premium preview explaining the feature with a clear upgrade button.

**Acceptance Criteria:**
- Modify `AdaptiveView.swift`
- If `!paywallService.isPremium`:
  - Show `AdaptivePremiumPreview` view instead of full content
  - Preview shows feature explanation with illustrations
  - Prominent "Unlock Adaptive Mode" button triggers paywall
  - Preview may show blurred glimpse of actual UI behind
- If `isPremium`, show full Adaptive functionality
- After upgrade, view immediately transitions to full content

**Priority:** 7
**Dependencies:** 1

---

### 8. Gate Full Insights Dashboard

Limit free users to basic session count. Full analytics (charts, trends, recommendations) require premium.

**User Story:** As a free user, I see my basic session count in Insights. Charts, sleep trends, and personalized recommendations show a premium lock prompting me to upgrade.

**Acceptance Criteria:**
- Modify `InsightsView.swift`
- Free tier shows:
  - Total sessions count
  - Basic "sessions this week" number
  - Premium upsell card for full analytics
- Premium tier shows full dashboard:
  - Weekly sleep chart
  - Average duration, quality metrics
  - Top sounds analytics
  - Personalized recommendations
  - Sleep goals
- Premium sections show `PremiumLockOverlay` for free users
- Tapping locked sections triggers paywall
- After upgrade, full dashboard appears

**Priority:** 8
**Dependencies:** 1, 2

---

### 9. Gate Discover Mix Saving

Free users can play community mixes but cannot save them. Saving triggers paywall.

**User Story:** As a free user, I can browse and play Discover mixes but when I try to save one to my library, I'm prompted to upgrade.

**Acceptance Criteria:**
- Modify `DiscoverView.swift` and `CommunityMixDetailView.swift`
- Free users can:
  - Browse all community mixes
  - View mix details
  - Play mixes in full
- Save button shows lock icon for free users
- Tapping save triggers paywall with `campaign_trigger`
- After upgrade, save functionality works normally
- Consider showing "Save to unlock your collection" messaging

**Priority:** 9
**Dependencies:** 1

---

### 10. Add Premium Status Indicator to Settings

Show premium status prominently in Settings with upgrade option for free users.

**User Story:** As a user, I can see my premium status in Settings. Free users see an upgrade button, premium users see their subscription status.

**Acceptance Criteria:**
- Modify `SettingsView.swift`
- Add premium status section at top:
  - Free users: "Free Plan" with "Upgrade to Premium" button
  - Premium users: "Premium" with checkmark and "Manage Subscription" link
- Upgrade button triggers paywall via `campaign_trigger`
- Premium badge/crown icon next to Premium status
- Restore purchases option remains visible for all users
- Consider showing what premium includes (bullet list)

**Priority:** 10
**Dependencies:** 1

---

## Summary

| # | Feature | Priority | Dependencies | Scope |
|---|---------|----------|--------------|-------|
| 1 | PremiumManager Service | P1 | None | Core |
| 2 | Premium Lock UI Component | P2 | 1 | UI |
| 3 | Gate Premium Sounds | P3 | 1, 2 | Sounds Tab |
| 4 | Gate Mixer (2 sound limit) | P4 | 1 | Mixer |
| 5 | Gate Binaural States | P5 | 1, 2 | Binaural Tab |
| 6 | Gate Wind Down Content | P6 | 1, 2 | Wind Down Tab |
| 7 | Gate Adaptive Mode | P7 | 1 | Adaptive Tab |
| 8 | Gate Full Insights | P8 | 1, 2 | Insights Tab |
| 9 | Gate Discover Saving | P9 | 1 | Discover Tab |
| 10 | Settings Premium Status | P10 | 1 | Settings |

**Total Features:** 10
**Estimated Scope:** Medium - All features build on the centralized PremiumManager

## Implementation Notes

### Superwall Integration
- All paywalls trigger via `PaywallService.triggerPaywall(placement: "campaign_trigger")`
- PaywallService already tracks `isPremium` state via `Superwall.shared.subscriptionStatus`
- After any paywall interaction, `updateSubscriptionStatus()` is called automatically

### State Management
- `PremiumManager` should observe `PaywallService.isPremium` for reactive updates
- All views using premium features should react to `isPremium` changes
- Use `@Environment(PremiumManager.self)` in views

### Free vs Premium Split (~50/50)

**Free Tier:**
- 14 of 34 sounds (at least one per category)
- 8 of 19 Wind Down content items
- Alpha brainwave state only
- 2-sound mixing limit
- Basic session count in Insights
- Play (but not save) Discover mixes
- Full access: Timer, Favorites, Alarms

**Premium Tier:**
- All 34 sounds
- All 19 Wind Down content items
- All 5 brainwave states
- Unlimited sound mixing
- Full Insights dashboard
- Save Discover mixes
- Full Adaptive Mode

### Testing Checklist
- [ ] Test free user flow for each gated feature
- [ ] Test upgrade flow mid-session (feature should unlock immediately)
- [ ] Test restore purchases functionality
- [ ] Test offline behavior (cached premium status)
- [ ] Verify paywall triggers use `campaign_trigger` placement

### Analytics
- Log premium feature access attempts by free users
- Track conversion from feature gates to successful purchases
- Use existing `AnalyticsService` for event tracking
