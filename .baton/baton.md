# Baton Document - Native StoreKit Paywall Migration

## Race Status
- **Status**: 🏃 IN PROGRESS
- **Current Leg**: 2
- **Current Feature**: Feature 2 - Implement StoreKit 2 Subscription Service
- **Started**: 2026-02-03

## Features Queue

| # | Feature | Status | Legs |
|---|---------|--------|------|
| 1 | Remove Superwall SDK | ✅ Completed | 1 |
| 2 | Implement StoreKit 2 Subscription Service | 🔄 In Progress | 2 |
| 3 | Design Native Paywall View | ⬜ Pending | 2 |
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

## Current Leg Context

### Leg 2: Implement StoreKit 2 Subscription Service

**Objective**: Create a native StoreKit 2 service to manage subscriptions.

**Product Identifiers**:
- `com.StudioNext.SoundScape.monthly`
- `com.StudioNext.SoundScape.yearly`

**Acceptance Criteria**:
- Create `SubscriptionService.swift` using StoreKit 2
- Fetch products from App Store
- Implement purchase flow with error handling
- Implement restore purchases
- Listen for transaction updates (Transaction.updates)
- Persist subscription status
- Update PaywallService to use SubscriptionService
- Maintain backward compatibility with isPremium

**Files to Create**:
- `SoundScape/Sources/Data/Services/SubscriptionService.swift`

**Files to Modify**:
- `SoundScape/Sources/Data/Services/PaywallService.swift`
- `SoundScape/Sources/App/SoundScapeApp.swift`

## Design Decisions

- Runner A's StoreKit-oriented comments were better than RevenueCat references
- Unit tests for stub implementations help validate contracts

## Stolen Ideas

- Leg 1: Conditional `if isPremium` check before logging restore (from Runner B)
