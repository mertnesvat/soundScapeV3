# Relay Race Baton

## Race Intent
Remove Superwall implementation and replace with a custom native SwiftUI paywall that follows the app's design language. The paywall should include all Apple-required options (Terms of Use, Privacy Policy, Restore Purchases) with placeholder links for now.

## Current State
- **Race Status**: COMPLETED
- **Current Leg**: 5/5
- **Total Legs Completed**: 5

## Feature Requirements

### Core Requirements
1. **Remove Superwall SDK** - Delete all SuperwallKit imports and dependencies
2. **Create Native PaywallService** - Replace with StoreKit 2 implementation
3. **Build Custom PaywallView** - SwiftUI paywall matching app design (purple/indigo gradient, dark theme, 16pt corners)
4. **Apple Compliance** - Terms of Use, Privacy Policy links, Restore Purchases button
5. **Update All Views** - Replace `paywallService.triggerPaywall()` calls with new paywall presentation

### Design Specifications (from app analysis)
- **Colors**: Purple accent, black/dark backgrounds, OLED support
- **Typography**: System fonts, .rounded design for headlines
- **Cards**: 16pt corner radius, systemGray6 backgrounds
- **Buttons**: 56pt height, purple primary, 16pt radius
- **Spacing**: 12-16-20-24pt padding hierarchy

### Files to Modify/Create

#### DELETE:
- None (PaywallService.swift will be rewritten)

#### REWRITE:
1. `Sources/Data/Services/PaywallService.swift` - StoreKit 2 implementation
2. `Sources/Presentation/Onboarding/Views/OnboardingPaywallView.swift` - Native paywall UI

#### UPDATE:
3. `Sources/App/SoundScapeApp.swift` - Remove Superwall configure, update environment
4. `Sources/Data/Services/PremiumManager.swift` - Update dependency (may stay similar)
5. `Sources/Data/Services/AnalyticsService.swift` - Keep paywall analytics methods
6. `Sources/Presentation/Settings/Views/SettingsView.swift` - Update premium section
7. `Sources/Presentation/Sounds/Views/SoundsView.swift` - Update paywall trigger
8. `Sources/Presentation/Mixer/Views/MixerView.swift` - Update premium check
9. `Sources/Presentation/Favorites/Views/FavoritesView.swift` - Update paywall trigger
10. `Sources/Presentation/BinauralBeats/Views/BinauralBeatsView.swift` - Update paywall trigger
11. `Sources/Presentation/Adaptive/Views/AdaptiveView.swift` - Update paywall trigger
12. `Sources/Presentation/Insights/Views/InsightsView.swift` - Update if needed
13. `Sources/Presentation/Discover/Views/DiscoverView.swift` - Update if needed
14. `Sources/Presentation/Onboarding/Views/OnboardingContainerView.swift` - Update environment

#### PROJECT FILE:
15. `SoundScape.xcodeproj/project.pbxproj` - Remove SuperwallKit framework reference

### Placeholder Links
- Terms of Use: `https://example.com/terms` (user will replace)
- Privacy Policy: `https://example.com/privacy` (user will replace)

### Subscription Products (placeholders)
- Monthly: `com.studionext.soundscape.monthly`
- Yearly: `com.studionext.soundscape.yearly`

## Leg Plan

### Leg 1: Create StoreKit 2 PaywallService
- Replace SuperwallKit with native StoreKit 2
- Implement `isPremium`, `purchaseProduct()`, `restorePurchases()`
- Add product fetching and subscription status observation
- Keep same public API surface where possible

### Leg 2: Build Custom PaywallView
- Create beautiful native SwiftUI paywall
- Match app design (purple gradient, dark theme, OLED support)
- Include: Feature list, pricing, CTA buttons
- Apple compliance: Terms, Privacy, Restore links

### Leg 3: Update SoundScapeApp and Core Integration
- Remove Superwall.configure()
- Update PaywallService initialization
- Ensure environment injection works
- Update PremiumManager if needed

### Leg 4: Update All View Paywall Triggers
- Replace `paywallService.triggerPaywall()` with sheet presentation
- Update Settings premium section
- Update all views: Sounds, Mixer, Favorites, Binaural, Adaptive, Insights, Discover
- Update OnboardingContainerView

### Leg 5: Remove SuperwallKit from Project
- Remove framework from Xcode project
- Clean up any remaining imports
- Test build

## Build Commands
```bash
cd /Users/goat/Developer/GenProj/soundScapeV3-remove-superwall/SoundScape && xcodebuild -scheme SoundScape -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | head -100
```

## Decisions Log
- Using StoreKit 2 (modern async/await API, iOS 15+)
- Keeping PaywallService name for minimal refactoring
- Using sheet presentation for paywall (standard iOS pattern)
- Placeholder product IDs will need to be configured in App Store Connect

## Innovation Bank
(Captured good ideas from runner implementations)

---

## Version History
- v1.0: Initial baton created with race plan
