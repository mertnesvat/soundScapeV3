# Race Plan: Native StoreKit Paywall Migration

## Overview
Replace Superwall SDK with Apple's native StoreKit 2 for in-app purchases, redesign the paywall UI to match the app's design language, update testimonials with appropriate vague language, and integrate the paywall at the end of onboarding.

## Product Identifiers
- **Monthly**: `com.StudioNext.SoundScape.monthly`
- **Yearly**: `com.StudioNext.SoundScape.yearly`

## Legal URLs
- Terms: https://studionext.co.uk/soundscape-terms.html
- Privacy: https://studionext.co.uk/soundscape-privacy.html

---

## Features

### Feature 1: Remove Superwall SDK
**Priority**: 1 (Must be first)
**Dependencies**: None
**Estimated Legs**: 1

**User Story**: As a developer, I want to remove Superwall SDK so we can use Apple's native StoreKit.

**Acceptance Criteria**:
- [ ] Remove SuperwallKit import from PaywallService.swift
- [ ] Remove Superwall package dependency from project.pbxproj
- [ ] Remove Superwall-iOS and Superscript-iOS from Package.resolved
- [ ] Clean up any Superwall-specific code (PaywallPresentationHandler, etc.)
- [ ] Project builds without Superwall

**Files to Modify**:
- `SoundScape/Sources/Data/Services/PaywallService.swift`
- `SoundScape/SoundScape.xcodeproj/project.pbxproj`

---

### Feature 2: Implement StoreKit 2 Subscription Service
**Priority**: 2
**Dependencies**: Feature 1
**Estimated Legs**: 2

**User Story**: As a user, I want to purchase subscriptions using Apple's native in-app purchase system.

**Acceptance Criteria**:
- [ ] Create `SubscriptionService.swift` using StoreKit 2
- [ ] Fetch products for `com.StudioNext.SoundScape.monthly` and `com.StudioNext.SoundScape.yearly`
- [ ] Implement purchase flow with proper error handling
- [ ] Implement restore purchases functionality
- [ ] Listen for transaction updates (Transaction.updates)
- [ ] Persist subscription status
- [ ] Handle subscription expiration/renewal
- [ ] Update `PaywallService.swift` to use new SubscriptionService
- [ ] Maintain `isPremium` property for backward compatibility

**Files to Create**:
- `SoundScape/Sources/Data/Services/SubscriptionService.swift`

**Files to Modify**:
- `SoundScape/Sources/Data/Services/PaywallService.swift`
- `SoundScape/Sources/App/SoundScapeApp.swift` (inject new service)

---

### Feature 3: Design Native Paywall View
**Priority**: 3
**Dependencies**: Feature 2
**Estimated Legs**: 2

**User Story**: As a user, I want a beautiful paywall that matches the app's dark design language and provides all required legal information.

**Acceptance Criteria**:
- [ ] Create `NativePaywallView.swift` with app-consistent design
- [ ] Dark theme with purple/indigo gradients (matching app aesthetic)
- [ ] Display both subscription options (monthly/yearly) with pricing from StoreKit
- [ ] Show feature benefits list (matching current features)
- [ ] Prominent "Start Free Trial" button
- [ ] "Continue with Limited Access" option
- [ ] Restore Purchases button
- [ ] Legal footer with:
  - "Cancel anytime. No commitment required."
  - Auto-renewal disclaimer: "Subscription auto-renews unless cancelled 24 hours before period end"
  - Links to Terms of Use and Privacy Policy
  - "Payment will be charged to Apple ID at confirmation of purchase"
- [ ] Loading states during purchase
- [ ] Error handling with user-friendly messages
- [ ] Success state with transition to main app

**Design Requirements** (UI Quality Gate):
- Consistent with app's dark theme (black background, white text)
- Purple/indigo gradient accents
- Rounded corners (16px) on cards
- Proper spacing and typography hierarchy
- Smooth animations for state transitions
- Accessible contrast ratios

**Files to Create**:
- `SoundScape/Sources/Presentation/Paywall/NativePaywallView.swift`
- `SoundScape/Sources/Presentation/Paywall/SubscriptionOptionCard.swift`

---

### Feature 4: Update Testimonials with Vague Language
**Priority**: 4
**Dependencies**: None (can run in parallel with Features 2-3)
**Estimated Legs**: 1

**User Story**: As a user, I want to see authentic-sounding testimonials that don't make specific claims about user numbers.

**Acceptance Criteria**:
- [ ] Update `OnboardingReviewsView.swift`
- [ ] Remove "4.8" rating (or change to generic "Highly Rated")
- [ ] Change header from "100,000+ users" style to "Loved Around the World"
- [ ] Update testimonial quotes to be genuine but unfalsifiable:
  - Sample names from different regions (global feel)
  - Focus on personal experience, not statistics
  - Roles like "Restful Sleeper", "Nightly Listener", "Wellness Enthusiast"
- [ ] Keep 3 testimonial cards with 5-star displays
- [ ] Maintain existing visual design (cards, stars, layout)

**Example Testimonials**:
1. "Finally found something that helps me unwind after long days." - Michael T., Wellness Enthusiast
2. "The sound mixing is exactly what I needed for my sleep routine." - Yuki S., Nightly Listener
3. "So peaceful. This has become part of my evening ritual." - Priya K., Restful Sleeper

**Files to Modify**:
- `SoundScape/Sources/Presentation/Onboarding/Views/OnboardingReviewsView.swift`

---

### Feature 5: Integrate Paywall into Onboarding Flow
**Priority**: 5
**Dependencies**: Features 2, 3
**Estimated Legs**: 1

**User Story**: As a user completing onboarding, I want to see the premium offering before entering the main app.

**Acceptance Criteria**:
- [ ] Replace `OnboardingPaywallView` usage with `NativePaywallView`
- [ ] Update `OnboardingContainerView.swift` to use native paywall
- [ ] Ensure paywall appears as final step (step 10) after Custom Plan
- [ ] Handle successful purchase → complete onboarding → main app
- [ ] Handle "Continue with Limited Access" → complete onboarding → main app
- [ ] Maintain analytics events (paywall_shown, purchase_completed, etc.)

**Files to Modify**:
- `SoundScape/Sources/Presentation/Onboarding/Views/OnboardingContainerView.swift`
- `SoundScape/Sources/Presentation/Onboarding/Views/OnboardingPaywallView.swift` (delete or repurpose)

---

### Feature 6: Update Premium Access Points
**Priority**: 6
**Dependencies**: Feature 2
**Estimated Legs**: 1

**User Story**: As a user, I want to access the paywall from various premium-locked features throughout the app.

**Acceptance Criteria**:
- [ ] Update `PremiumManager.swift` to use new SubscriptionService
- [ ] Update Settings paywall trigger to show native paywall
- [ ] Ensure all premium lock overlays trigger native paywall
- [ ] Test paywall trigger from: Sounds, Binaural Beats, Wind Down, Discover, Insights, Favorites

**Files to Modify**:
- `SoundScape/Sources/Data/Services/PremiumManager.swift`
- `SoundScape/Sources/Presentation/Settings/SettingsView.swift`

---

## Quality Gates

### UI Quality Gate
All UI changes must:
- [ ] Match the app's dark theme (black background #000000)
- [ ] Use consistent typography (system fonts, proper weights)
- [ ] Use the purple/indigo gradient accent color scheme
- [ ] Have 16px corner radius on cards
- [ ] Support Dynamic Type
- [ ] Have accessible contrast (WCAG AA minimum)
- [ ] Include smooth animations (0.3s standard duration)
- [ ] Work on all iPhone sizes (SE to Pro Max)

### Functionality Quality Gate
- [ ] Products fetch successfully from App Store
- [ ] Purchases complete without errors
- [ ] Restore purchases works correctly
- [ ] Subscription status persists across app launches
- [ ] Premium features unlock after purchase
- [ ] Premium features lock when subscription expires
- [ ] Analytics events fire correctly

### Legal Compliance Gate
- [ ] Terms of Use link works
- [ ] Privacy Policy link works
- [ ] Auto-renewal disclaimer is visible
- [ ] Price shown matches App Store Connect configuration
- [ ] Restore Purchases option is accessible

---

## Implementation Order

```
Feature 1 (Remove Superwall)
    ↓
Feature 2 (StoreKit Service) ←── Feature 4 (Testimonials) [parallel]
    ↓
Feature 3 (Paywall UI)
    ↓
Feature 5 (Onboarding Integration)
    ↓
Feature 6 (Access Points)
```

---

## Risk Considerations

1. **StoreKit Testing**: Need to test with sandbox accounts
2. **Product Configuration**: Products must be configured correctly in App Store Connect (confirmed: already set up)
3. **Migration**: Existing Superwall subscribers may need migration handling (check if any exist)
4. **Receipt Validation**: StoreKit 2 handles this automatically on-device

---

## Success Metrics

- App builds and runs without Superwall SDK
- Products display with correct pricing from App Store
- Purchase flow completes successfully in sandbox
- Subscription status correctly controls premium access
- Onboarding flow ends with native paywall
- Testimonials display without specific user count claims
