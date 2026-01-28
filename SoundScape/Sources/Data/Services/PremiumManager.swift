import SwiftUI

/// Defines features that may require premium access
enum PremiumFeature: Hashable {
    /// Individual premium sounds
    case sound(id: String)
    /// Mixing more than 2 sounds simultaneously
    case unlimitedMixing
    /// Premium brainwave states (all except Alpha)
    case binauralBeat(state: BrainwaveState)
    /// Full Adaptive tab functionality
    case adaptiveMode
    /// Advanced analytics and charts in Insights
    case fullInsights
    /// Premium Wind Down content (stories, hypnosis, etc.)
    case windDownContent(id: String)
    /// Saving community mixes from Discover
    case discoverSave
}

/// Centralized service for managing premium vs free feature access
@Observable
@MainActor
final class PremiumManager {

    // MARK: - Dependencies

    private let paywallService: PaywallService

    // MARK: - Free Content Definitions (80% Free / 20% Premium)

    /// Sound IDs that are available to free users (30 of 38 total = 79% free)
    /// Premium sounds: starlit_sky, forest_sanctuary, gentle_tapping_2, gentle_tapping_3,
    ///                 nail_tapping, mechanical_keyboard_2, slime_squelching, gentle_brush_strokes
    private let freeSoundIDs: Set<String> = [
        // Noise - ALL FREE (4)
        "white_noise",
        "pink_noise",
        "brown_noise",
        "brown_noise_deep",
        // Nature - ALL FREE (7)
        "morning_birds",
        "winter_forest",
        "serene_morning",
        "spring_birds",
        "meadow",
        "night_wildlife",
        "calm_ocean",
        // Weather - ALL FREE (6)
        "rain_storm",
        "wind_ambient",
        "rainforest",
        "thunder",
        "heavy_thunder",
        "castle_wind",
        // Fire - ALL FREE (2)
        "campfire",
        "bonfire",
        // Music - 6 of 8 free
        "creative_mind",
        "cinematic_piano",
        "ambient_melody",
        "midnight_calm",
        "ocean_lullaby",
        "deep_focus_flow",
        // ASMR - 5 of 11 free
        "page_turning",
        "gentle_tapping",
        "mechanical_keyboard",
        "winter_forest_walk"
    ]

    /// Wind Down content IDs that are available to free users (11 of 14 available = 79% free)
    /// Premium content: yoga_nidra_10min, story_rivers_secret, hypnosis_staircase
    private let freeWindDownContentIDs: Set<String> = [
        // Yoga Nidra - 2 of 3 free
        "yoga_nidra_5min",
        "yoga_nidra_8min",
        // Stories - 4 of 5 free
        "story_clockmakers_gift",
        "story_garden_between_stars",
        "story_last_lighthouse_keeper",
        "story_mountain_learned_to_rest",
        // Hypnosis - 2 of 3 free
        "hypnosis_floating",
        "hypnosis_ocean",
        // Affirmations - ALL FREE (3)
        "affirmation_gratitude",
        "affirmation_peace",
        "affirmation_release"
        // Note: All breathing exercises are free when available
    ]

    /// Brainwave states available to free users (4 of 5 = 80% free)
    /// Premium state: gamma only
    private let freeBrainwaveStates: Set<BrainwaveState> = [.alpha, .beta, .theta, .delta]

    // MARK: - Initialization

    init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }

    // MARK: - Access Control

    /// Checks if a feature requires premium access
    /// - Parameter feature: The feature to check
    /// - Returns: `true` if premium is required, `false` if the feature is free
    func isPremiumRequired(for feature: PremiumFeature) -> Bool {
        // Premium users have access to everything
        if paywallService.isPremium {
            return false
        }

        switch feature {
        case .sound(let id):
            return !freeSoundIDs.contains(id)

        case .unlimitedMixing:
            return true

        case .binauralBeat(let state):
            return !freeBrainwaveStates.contains(state)

        case .adaptiveMode:
            return true

        case .fullInsights:
            return true

        case .windDownContent(let id):
            // Breathing exercises are free (check prefix)
            if id.hasPrefix("breathing_") {
                return false
            }
            return !freeWindDownContentIDs.contains(id)

        case .discoverSave:
            return true
        }
    }

    /// Checks access and triggers paywall if premium is required
    /// - Parameters:
    ///   - feature: The feature being accessed
    ///   - paywallService: The paywall service to trigger if needed
    ///   - onGranted: Callback executed if access is granted (either free or after purchase)
    func checkAccessOrTriggerPaywall(
        for feature: PremiumFeature,
        paywallService: PaywallService,
        onGranted: @escaping () -> Void
    ) {
        if !isPremiumRequired(for: feature) {
            // Feature is free or user is premium - grant access immediately
            onGranted()
            return
        }

        // Feature requires premium - show paywall
        let placement = placementName(for: feature)
        paywallService.triggerPaywall(placement: placement) {
            // This callback is invoked if the user purchases or is already premium
            onGranted()
        }
    }

    // MARK: - Convenience Methods

    /// Checks if a sound is free
    func isSoundFree(_ soundID: String) -> Bool {
        freeSoundIDs.contains(soundID)
    }

    /// Checks if a brainwave state is free
    func isBrainwaveStateFree(_ state: BrainwaveState) -> Bool {
        freeBrainwaveStates.contains(state)
    }

    /// Checks if wind down content is free
    func isWindDownContentFree(_ contentID: String) -> Bool {
        if contentID.hasPrefix("breathing_") {
            return true
        }
        return freeWindDownContentIDs.contains(contentID)
    }

    // MARK: - Private Helpers

    /// Generates a paywall placement name based on the feature
    private func placementName(for feature: PremiumFeature) -> String {
        switch feature {
        case .sound:
            return "premium_sound"
        case .unlimitedMixing:
            return "unlimited_mixing"
        case .binauralBeat:
            return "premium_binaural"
        case .adaptiveMode:
            return "adaptive_mode"
        case .fullInsights:
            return "full_insights"
        case .windDownContent:
            return "premium_winddown"
        case .discoverSave:
            return "discover_save"
        }
    }
}
