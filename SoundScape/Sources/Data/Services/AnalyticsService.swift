import Foundation
import StoreKit
import UIKit

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

@Observable
final class AnalyticsService {

    // MARK: - Review Prompt Configuration

    private let reviewPromptSessionThreshold = 5
    private let reviewPromptMinDaysInstalled = 3
    private let reviewPromptCooldownDays = 60

    // MARK: - Stored Properties

    private let userDefaults = UserDefaults.standard

    private var sessionCount: Int {
        get { userDefaults.integer(forKey: "analytics_session_count") }
        set { userDefaults.set(newValue, forKey: "analytics_session_count") }
    }

    private var lastReviewPromptDate: Date? {
        get { userDefaults.object(forKey: "analytics_last_review_prompt") as? Date }
        set { userDefaults.set(newValue, forKey: "analytics_last_review_prompt") }
    }

    private var installDate: Date {
        get {
            if let date = userDefaults.object(forKey: "analytics_install_date") as? Date {
                return date
            }
            let now = Date()
            userDefaults.set(now, forKey: "analytics_install_date")
            return now
        }
        set { userDefaults.set(newValue, forKey: "analytics_install_date") }
    }

    private var hasCompletedPositiveSession: Bool = false

    // MARK: - Initialization

    init() {
        _ = installDate
    }

    // MARK: - Firebase Configuration

    func configure() {
        #if canImport(FirebaseAnalytics)
        // Firebase is configured in SoundScapeApp via FirebaseApp.configure()
        // Set default analytics parameters
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif

        incrementSessionCount()
        logEvent(.appOpen)
    }

    private func incrementSessionCount() {
        sessionCount += 1
    }

    // MARK: - Analytics Events

    enum AnalyticsEvent: String {
        // App lifecycle
        case appOpen = "app_open"
        case appBackground = "app_background"

        // Sound playback
        case soundPlay = "sound_play"
        case soundStop = "sound_stop"
        case soundVolumeChange = "sound_volume_change"

        // Mix events
        case mixCreate = "mix_create"
        case mixSave = "mix_save"
        case mixLoad = "mix_load"
        case mixDelete = "mix_delete"

        // Timer events
        case timerStart = "timer_start"
        case timerComplete = "timer_complete"
        case timerCancel = "timer_cancel"

        // Session events
        case sessionStart = "session_start"
        case sessionEnd = "session_end"

        // Favorites
        case favoriteAdd = "favorite_add"
        case favoriteRemove = "favorite_remove"

        // Binaural beats
        case binauralStart = "binaural_start"
        case binauralStop = "binaural_stop"

        // Alarms
        case alarmCreate = "alarm_create"
        case alarmDelete = "alarm_delete"
        case alarmTrigger = "alarm_trigger"

        // Adaptive mode
        case adaptiveStart = "adaptive_start"
        case adaptiveComplete = "adaptive_complete"

        // Navigation
        case tabSelect = "tab_select"
        case screenView = "screen_view"

        // Engagement
        case shareContent = "share_content"
        case reviewPromptShown = "review_prompt_shown"
        case reviewPromptAccepted = "review_prompt_accepted"
    }

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event.rawValue, parameters: parameters)
        #endif

        #if DEBUG
        var debugMessage = "[Analytics] \(event.rawValue)"
        if let params = parameters {
            debugMessage += " - \(params)"
        }
        print(debugMessage)
        #endif
    }

    // MARK: - Convenience Methods for Common Events

    func logSoundPlay(soundId: String, soundName: String, category: String) {
        logEvent(.soundPlay, parameters: [
            "sound_id": soundId,
            "sound_name": soundName,
            "category": category
        ])
    }

    func logSoundStop(soundId: String, soundName: String, duration: TimeInterval) {
        logEvent(.soundStop, parameters: [
            "sound_id": soundId,
            "sound_name": soundName,
            "duration_seconds": Int(duration)
        ])
    }

    func logMixSave(mixName: String, soundCount: Int, soundIds: [String]) {
        logEvent(.mixSave, parameters: [
            "mix_name": mixName,
            "sound_count": soundCount,
            "sound_ids": soundIds.joined(separator: ",")
        ])
    }

    func logMixLoad(mixName: String, soundCount: Int) {
        logEvent(.mixLoad, parameters: [
            "mix_name": mixName,
            "sound_count": soundCount
        ])
    }

    func logTimerStart(duration: TimeInterval) {
        logEvent(.timerStart, parameters: [
            "duration_minutes": Int(duration / 60)
        ])
    }

    func logTimerComplete(duration: TimeInterval) {
        logEvent(.timerComplete, parameters: [
            "duration_minutes": Int(duration / 60)
        ])

        markPositiveSession()
    }

    func logSessionEnd(duration: TimeInterval, soundsUsed: [String], quality: Int?) {
        var params: [String: Any] = [
            "duration_minutes": Int(duration / 60),
            "sounds_used_count": soundsUsed.count,
            "sounds_used": soundsUsed.joined(separator: ",")
        ]

        if let quality = quality {
            params["quality_score"] = quality
            if quality >= 70 {
                markPositiveSession()
            }
        }

        logEvent(.sessionEnd, parameters: params)
    }

    func logBinauralStart(frequency: Double, type: String) {
        logEvent(.binauralStart, parameters: [
            "frequency": frequency,
            "type": type
        ])
    }

    func logAdaptiveComplete(modeName: String, totalDuration: TimeInterval) {
        logEvent(.adaptiveComplete, parameters: [
            "mode_name": modeName,
            "total_duration_minutes": Int(totalDuration / 60)
        ])

        markPositiveSession()
    }

    func logTabSelect(tabName: String) {
        logEvent(.tabSelect, parameters: [
            "tab_name": tabName
        ])
    }

    func logScreenView(screenName: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
        #endif

        #if DEBUG
        print("[Analytics] screen_view - \(screenName)")
        #endif
    }

    // MARK: - Review Prompt Logic

    private func markPositiveSession() {
        hasCompletedPositiveSession = true
    }

    func shouldShowReviewPrompt() -> Bool {
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        guard daysSinceInstall >= reviewPromptMinDaysInstalled else {
            return false
        }

        guard sessionCount >= reviewPromptSessionThreshold else {
            return false
        }

        if let lastPrompt = lastReviewPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= reviewPromptCooldownDays else {
                return false
            }
        }

        return hasCompletedPositiveSession
    }

    func requestReviewIfAppropriate() {
        guard shouldShowReviewPrompt() else {
            return
        }

        requestAppStoreReview()
        lastReviewPromptDate = Date()
        hasCompletedPositiveSession = false
        logEvent(.reviewPromptShown)
    }

    func requestAppStoreReview() {
        #if !DEBUG
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
        #else
        print("[Analytics] Review prompt would be shown in release build")
        #endif
    }

    // MARK: - User Properties

    func setUserProperty(_ value: String?, forName name: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    func setFavoriteCount(_ count: Int) {
        setUserProperty(String(count), forName: "favorite_sounds_count")
    }

    func setSavedMixesCount(_ count: Int) {
        setUserProperty(String(count), forName: "saved_mixes_count")
    }

    func setTotalSessionCount(_ count: Int) {
        setUserProperty(String(count), forName: "total_sessions")
    }
}
