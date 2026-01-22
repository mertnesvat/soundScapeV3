import Foundation
import StoreKit
import UIKit

@Observable
@MainActor
final class ReviewPromptService {

    // MARK: - Configuration

    private let sessionsBeforePromptKey = "sessions_before_review_prompt"
    private let lastPromptDateKey = "last_review_prompt_date"
    private let hasRatedKey = "user_has_rated_app"
    private let promptCountKey = "review_prompt_count"

    /// Number of successful sessions before showing the first prompt
    private let requiredSessionsForFirstPrompt = 3

    /// Minimum days between review prompts
    private let minimumDaysBetweenPrompts = 30

    /// Maximum number of prompts to show (Apple limits to 3 per 365-day period)
    private let maxPromptsPerYear = 3

    // MARK: - State

    private(set) var sessionCount: Int = 0
    private(set) var lastPromptDate: Date?
    private(set) var hasUserRated: Bool = false
    private(set) var promptCount: Int = 0

    private var analyticsService: AnalyticsService?

    // MARK: - Initialization

    init() {
        loadState()
    }

    func setAnalyticsService(_ service: AnalyticsService) {
        self.analyticsService = service
    }

    // MARK: - Session Tracking

    /// Call this when a user completes a positive action (e.g., finishes a sleep session, saves a mix)
    func recordPositiveAction() {
        sessionCount += 1
        saveState()
        checkAndPromptForReviewIfEligible()
    }

    /// Call this after a successful sleep timer completion
    func recordSuccessfulSleepSession() {
        recordPositiveAction()
    }

    /// Call this when user saves a new mix
    func recordMixSaved() {
        recordPositiveAction()
    }

    /// Call this when user favorites sounds multiple times
    func recordFavoriteAction() {
        // Favorites are less significant, so we count them differently
        // Every 3 favorites = 1 positive action
        let favoritesCount = UserDefaults.standard.integer(forKey: "favorites_action_count") + 1
        UserDefaults.standard.set(favoritesCount, forKey: "favorites_action_count")

        if favoritesCount >= 3 {
            UserDefaults.standard.set(0, forKey: "favorites_action_count")
            recordPositiveAction()
        }
    }

    // MARK: - Review Prompt Logic

    private func checkAndPromptForReviewIfEligible() {
        guard canShowReviewPrompt() else { return }
        requestReview()
    }

    func canShowReviewPrompt() -> Bool {
        // Don't prompt if user has already rated
        guard !hasUserRated else { return false }

        // Check if we've hit the yearly limit
        guard promptCount < maxPromptsPerYear else { return false }

        // Check if user has had enough positive experiences
        guard sessionCount >= requiredSessionsForFirstPrompt else { return false }

        // Check minimum time between prompts
        if let lastDate = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysBetweenPrompts else { return false }
        }

        return true
    }

    func requestReview() {
        // Update state before showing prompt
        lastPromptDate = Date()
        promptCount += 1
        saveState()

        analyticsService?.logReviewPromptShown()

        // Request review using StoreKit
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    /// Call this if user indicates they've rated (e.g., through a custom "Don't ask again" option)
    func markAsRated() {
        hasUserRated = true
        analyticsService?.logReviewPromptAccepted()
        saveState()
    }

    /// Call this if user declines to rate
    func markAsDeclined() {
        analyticsService?.logReviewPromptDeclined()
        // We still allow future prompts, just with the time delay
    }

    // MARK: - Manual Prompt (for Settings)

    /// Use this for a manual "Rate Us" button in settings
    func openAppStoreForRating() {
        // Replace with your actual App Store ID
        let appId = "YOUR_APP_STORE_ID"
        if let url = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review") {
            UIApplication.shared.open(url)
            markAsRated()
        }
    }

    // MARK: - Reset (for testing)

    func resetPromptState() {
        sessionCount = 0
        lastPromptDate = nil
        hasUserRated = false
        promptCount = 0
        UserDefaults.standard.removeObject(forKey: "favorites_action_count")
        saveState()
    }

    // MARK: - Persistence

    private func loadState() {
        sessionCount = UserDefaults.standard.integer(forKey: sessionsBeforePromptKey)
        hasUserRated = UserDefaults.standard.bool(forKey: hasRatedKey)
        promptCount = UserDefaults.standard.integer(forKey: promptCountKey)

        if let timestamp = UserDefaults.standard.object(forKey: lastPromptDateKey) as? TimeInterval {
            lastPromptDate = Date(timeIntervalSince1970: timestamp)
        }
    }

    private func saveState() {
        UserDefaults.standard.set(sessionCount, forKey: sessionsBeforePromptKey)
        UserDefaults.standard.set(hasUserRated, forKey: hasRatedKey)
        UserDefaults.standard.set(promptCount, forKey: promptCountKey)

        if let date = lastPromptDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastPromptDateKey)
        }
    }
}
