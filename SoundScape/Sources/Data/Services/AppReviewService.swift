import Foundation
import StoreKit
import UIKit

@Observable
@MainActor
final class AppReviewService {

    // MARK: - Configuration

    private let minSessionsBeforePrompt = 3
    private let minListeningTimeBeforePrompt: TimeInterval = 1800  // 30 minutes
    private let daysBetweenPrompts = 60

    // MARK: - Persistence Keys

    private let lastPromptDateKey = "app_review_last_prompt_date"
    private let hasRatedKey = "app_review_has_rated"
    private let promptCountKey = "app_review_prompt_count"
    private let lastVersionPromptedKey = "app_review_last_version"

    // MARK: - Properties

    private(set) var lastPromptDate: Date? {
        didSet {
            if let date = lastPromptDate {
                UserDefaults.standard.set(date, forKey: lastPromptDateKey)
            }
        }
    }

    private(set) var hasRated: Bool {
        didSet { UserDefaults.standard.set(hasRated, forKey: hasRatedKey) }
    }

    private(set) var promptCount: Int {
        didSet { UserDefaults.standard.set(promptCount, forKey: promptCountKey) }
    }

    private(set) var lastVersionPrompted: String? {
        didSet { UserDefaults.standard.set(lastVersionPrompted, forKey: lastVersionPromptedKey) }
    }

    // MARK: - Initialization

    init() {
        self.lastPromptDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date
        self.hasRated = UserDefaults.standard.bool(forKey: hasRatedKey)
        self.promptCount = UserDefaults.standard.integer(forKey: promptCountKey)
        self.lastVersionPrompted = UserDefaults.standard.string(forKey: lastVersionPromptedKey)
    }

    // MARK: - Review Request Logic

    /// Check if conditions are met and request review if appropriate
    /// Call this after positive user actions
    nonisolated func requestReviewIfAppropriate(analyticsService: AnalyticsService) {
        Task { @MainActor in
            guard shouldShowReviewPrompt(analyticsService: analyticsService) else {
                return
            }
            requestReview()
        }
    }

    /// Check all conditions for showing the review prompt
    private func shouldShowReviewPrompt(analyticsService: AnalyticsService) -> Bool {
        // User has already indicated they don't want to be asked
        if hasRated {
            return false
        }

        // Check minimum session count
        if analyticsService.sessionCount < minSessionsBeforePrompt {
            return false
        }

        // Check minimum listening time (indicates genuine usage)
        if analyticsService.totalListeningTime < minListeningTimeBeforePrompt {
            return false
        }

        // Check if user has performed positive actions
        if !analyticsService.hasCompletedPositiveAction {
            return false
        }

        // Don't prompt too frequently
        if let lastDate = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLastPrompt < daysBetweenPrompts {
                return false
            }
        }

        // Don't prompt more than once per version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if lastVersionPrompted == currentVersion {
            return false
        }

        // Limit total prompts to 3 per version lifecycle
        if promptCount >= 3 {
            return false
        }

        return true
    }

    /// Present the system review prompt
    @MainActor
    private func requestReview() {
        // Get the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        // Update tracking
        lastPromptDate = Date()
        promptCount += 1
        lastVersionPrompted = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // Request the review
        SKStoreReviewController.requestReview(in: windowScene)
    }

    // MARK: - Manual Review Request (for Settings)

    /// User explicitly wants to rate the app from settings
    @MainActor
    func openAppStoreForReview() {
        hasRated = true

        // App Store ID for SoundScape - replace with actual ID when available
        let appId = "YOUR_APP_STORE_ID"
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Positive Action Triggers

    /// Call when user completes a sleep session with timer
    nonisolated func onSleepSessionCompleted(analyticsService: AnalyticsService) {
        // Sleep session completion is a very positive signal
        requestReviewIfAppropriate(analyticsService: analyticsService)
    }

    /// Call when user saves a mix (indicates they found a combination they like)
    nonisolated func onMixSaved(analyticsService: AnalyticsService) {
        requestReviewIfAppropriate(analyticsService: analyticsService)
    }

    /// Call when user adds a 3rd favorite (indicates they're exploring and enjoying)
    nonisolated func onFavoriteAdded(favoriteCount: Int, analyticsService: AnalyticsService) {
        if favoriteCount >= 3 {
            requestReviewIfAppropriate(analyticsService: analyticsService)
        }
    }

    /// Call when user completes an adaptive session
    nonisolated func onAdaptiveSessionCompleted(analyticsService: AnalyticsService) {
        requestReviewIfAppropriate(analyticsService: analyticsService)
    }

    /// Call when user reaches a listening milestone (e.g., 1 hour total)
    nonisolated func onListeningMilestoneReached(analyticsService: AnalyticsService) {
        requestReviewIfAppropriate(analyticsService: analyticsService)
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: lastPromptDateKey)
        UserDefaults.standard.removeObject(forKey: hasRatedKey)
        UserDefaults.standard.removeObject(forKey: promptCountKey)
        UserDefaults.standard.removeObject(forKey: lastVersionPromptedKey)

        lastPromptDate = nil
        hasRated = false
        promptCount = 0
        lastVersionPrompted = nil
    }
    #endif
}
