# Baton Document - Native StoreKit Paywall Migration

## Race Status
- **Status**: 🏃 IN PROGRESS
- **Current Leg**: 3
- **Current Feature**: Feature 3 - Design Native Paywall View
- **Started**: 2026-02-03

## Features Queue

| # | Feature | Status | Legs |
|---|---------|--------|------|
| 1 | Remove Superwall SDK | ✅ Completed | 1 |
| 2 | Implement StoreKit 2 Subscription Service | ✅ Completed | 1 |
| 3 | Design Native Paywall View | 🔄 In Progress | 2 |
| 4 | Update Testimonials with Vague Language | ⬜ Pending | 1 |
| 5 | Integrate Paywall into Onboarding Flow | ⬜ Pending | 1 |
| 6 | Update Premium Access Points | ⬜ Pending | 1 |

## Completed Legs

### Leg 1: Remove Superwall SDK ✅
**Winner**: Runner A
**Commit**: 441b4be
**Stolen Ideas**: Conditional restore logging from Runner B

**Changes Made**:
- Removed SuperwallKit import from PaywallService.swift
- Removed Superwall package dependencies from project.pbxproj
- Removed superwall-ios and superscript-ios from Package.resolved
- Rewrote PaywallService as clean stub with same API
- Added 11 unit tests for PaywallService

### Leg 2: Implement StoreKit 2 Subscription Service ✅
**Winner**: Runner A (85 vs 71)
**Commit**: 14f9785
**Stolen Ideas**:
- Yearly-first product sorting (from Runner B)
- Proper task nil cleanup in cancelListener (from Runner B)

**Changes Made**:
- Created `SubscriptionService.swift` with StoreKit 2 API
- Product fetching, purchase flow, restore, entitlement checking
- Transaction.updates listener for real-time status
- Injectable UserDefaults for testability
- Updated `PaywallService.swift` to use SubscriptionService
- Updated `SoundScapeApp.swift` to inject SubscriptionService
- 24 unit tests for SubscriptionService

## Current Leg Context

### Leg 3: Design Native Paywall View

**Objective**: Create a SwiftUI paywall view matching app design.

**Acceptance Criteria**:
- Create `PaywallView.swift` in Presentation layer
- Show both subscription options (monthly, yearly)
- Display prices from SubscriptionService
- Include Apple-required links (Terms, Privacy)
- Handle purchase/restore actions
- Show loading and error states
- Match app's visual design

**Files to Create**:
- `SoundScape/Sources/Presentation/Paywall/PaywallView.swift`

**Files to Modify**:
- `SoundScape/SoundScape.xcodeproj/project.pbxproj`

## Design Decisions

- Runner A's StoreKit-oriented comments were better than RevenueCat references
- Unit tests for stub implementations help validate contracts
- Injectable UserDefaults allows isolated testing
- Yearly-first sorting encourages higher-value purchases

## Stolen Ideas

- Leg 1: Conditional `if isPremium` check before logging restore (from Runner B)
- Leg 2: Yearly-first product sorting (from Runner B)
- Leg 2: Proper task nil cleanup in cancelListener (from Runner B)
