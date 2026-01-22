import Foundation
import FirebaseAnalytics

@Observable
final class AnalyticsService {

    // MARK: - User Engagement Tracking

    private let sessionCountKey = "analytics_session_count"
    private let lastSessionDateKey = "analytics_last_session_date"
    private let totalListeningTimeKey = "analytics_total_listening_time"
    private let mixesSavedCountKey = "analytics_mixes_saved_count"
    private let favoritesAddedCountKey = "analytics_favorites_added_count"

    private(set) var sessionCount: Int {
        didSet { UserDefaults.standard.set(sessionCount, forKey: sessionCountKey) }
    }

    private(set) var totalListeningTime: TimeInterval {
        didSet { UserDefaults.standard.set(totalListeningTime, forKey: totalListeningTimeKey) }
    }

    private(set) var mixesSavedCount: Int {
        didSet { UserDefaults.standard.set(mixesSavedCount, forKey: mixesSavedCountKey) }
    }

    private(set) var favoritesAddedCount: Int {
        didSet { UserDefaults.standard.set(favoritesAddedCount, forKey: favoritesAddedCountKey) }
    }

    init() {
        self.sessionCount = UserDefaults.standard.integer(forKey: sessionCountKey)
        self.totalListeningTime = UserDefaults.standard.double(forKey: totalListeningTimeKey)
        self.mixesSavedCount = UserDefaults.standard.integer(forKey: mixesSavedCountKey)
        self.favoritesAddedCount = UserDefaults.standard.integer(forKey: favoritesAddedCountKey)
    }

    // MARK: - App Lifecycle Events

    func logAppLaunch() {
        sessionCount += 1
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "session_number": sessionCount
        ])
    }

    func logSessionStart() {
        Analytics.logEvent("session_start", parameters: nil)
    }

    // MARK: - Sound Playback Events

    func logSoundStarted(soundId: String, soundName: String, category: String) {
        Analytics.logEvent("sound_started", parameters: [
            "sound_id": soundId,
            "sound_name": soundName,
            "category": category
        ])
    }

    func logSoundStopped(soundId: String, soundName: String, duration: TimeInterval) {
        totalListeningTime += duration

        Analytics.logEvent("sound_stopped", parameters: [
            "sound_id": soundId,
            "sound_name": soundName,
            "duration_seconds": Int(duration)
        ])
    }

    func logMixStarted(soundCount: Int, soundNames: [String]) {
        Analytics.logEvent("mix_started", parameters: [
            "sound_count": soundCount,
            "sounds": soundNames.joined(separator: ",")
        ])
    }

    // MARK: - Sleep Timer Events

    func logTimerSet(duration: TimeInterval) {
        Analytics.logEvent("timer_set", parameters: [
            "duration_minutes": Int(duration / 60)
        ])
    }

    func logTimerCompleted(duration: TimeInterval) {
        Analytics.logEvent("timer_completed", parameters: [
            "duration_minutes": Int(duration / 60)
        ])
    }

    func logTimerCancelled(remainingTime: TimeInterval) {
        Analytics.logEvent("timer_cancelled", parameters: [
            "remaining_minutes": Int(remainingTime / 60)
        ])
    }

    // MARK: - User Actions Events

    func logMixSaved(mixName: String, soundCount: Int) {
        mixesSavedCount += 1

        Analytics.logEvent("mix_saved", parameters: [
            "mix_name": mixName,
            "sound_count": soundCount,
            "total_mixes_saved": mixesSavedCount
        ])
    }

    func logMixLoaded(mixName: String) {
        Analytics.logEvent("mix_loaded", parameters: [
            "mix_name": mixName
        ])
    }

    func logFavoriteAdded(soundId: String, soundName: String) {
        favoritesAddedCount += 1

        Analytics.logEvent("favorite_added", parameters: [
            "sound_id": soundId,
            "sound_name": soundName,
            "total_favorites": favoritesAddedCount
        ])
    }

    func logFavoriteRemoved(soundId: String, soundName: String) {
        Analytics.logEvent("favorite_removed", parameters: [
            "sound_id": soundId,
            "sound_name": soundName
        ])
    }

    // MARK: - Binaural Beats Events

    func logBinauralBeatStarted(frequency: Double, beatType: String) {
        Analytics.logEvent("binaural_beat_started", parameters: [
            "frequency": frequency,
            "beat_type": beatType
        ])
    }

    func logBinauralBeatStopped(duration: TimeInterval) {
        Analytics.logEvent("binaural_beat_stopped", parameters: [
            "duration_seconds": Int(duration)
        ])
    }

    // MARK: - Adaptive Session Events

    func logAdaptiveSessionStarted(modeName: String) {
        Analytics.logEvent("adaptive_session_started", parameters: [
            "mode_name": modeName
        ])
    }

    func logAdaptiveSessionCompleted(modeName: String, totalDuration: TimeInterval) {
        Analytics.logEvent("adaptive_session_completed", parameters: [
            "mode_name": modeName,
            "duration_minutes": Int(totalDuration / 60)
        ])
    }

    // MARK: - Alarm Events

    func logAlarmCreated(soundId: String, repeatDays: Int) {
        Analytics.logEvent("alarm_created", parameters: [
            "wake_sound_id": soundId,
            "repeat_days_count": repeatDays
        ])
    }

    func logAlarmTriggered(alarmId: String) {
        Analytics.logEvent("alarm_triggered", parameters: [
            "alarm_id": alarmId
        ])
    }

    // MARK: - Story Events

    func logStoryStarted(storyId: String, storyName: String) {
        Analytics.logEvent("story_started", parameters: [
            "story_id": storyId,
            "story_name": storyName
        ])
    }

    func logStoryCompleted(storyId: String, storyName: String) {
        Analytics.logEvent("story_completed", parameters: [
            "story_id": storyId,
            "story_name": storyName
        ])
    }

    // MARK: - Screen View Events

    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
    }

    // MARK: - Tab Events

    func logTabSelected(tabName: String) {
        Analytics.logEvent("tab_selected", parameters: [
            "tab_name": tabName
        ])
    }

    // MARK: - Community/Discover Events

    func logCommunityMixViewed(mixId: String, mixName: String, creator: String) {
        Analytics.logEvent("community_mix_viewed", parameters: [
            "mix_id": mixId,
            "mix_name": mixName,
            "creator": creator
        ])
    }

    func logCommunityMixPlayed(mixId: String, mixName: String) {
        Analytics.logEvent("community_mix_played", parameters: [
            "mix_id": mixId,
            "mix_name": mixName
        ])
    }

    // MARK: - User Properties

    func updateUserProperties() {
        Analytics.setUserProperty("\(sessionCount)", forName: "total_sessions")
        Analytics.setUserProperty("\(Int(totalListeningTime / 3600))", forName: "total_listening_hours")
        Analytics.setUserProperty("\(mixesSavedCount)", forName: "mixes_saved")
        Analytics.setUserProperty("\(favoritesAddedCount)", forName: "favorites_count")
    }

    // MARK: - Engagement Metrics (for Review Prompt)

    var isEngagedUser: Bool {
        sessionCount >= 3 && totalListeningTime >= 1800 // 3+ sessions and 30+ minutes listening
    }

    var hasCompletedPositiveAction: Bool {
        mixesSavedCount > 0 || favoritesAddedCount >= 2 || totalListeningTime >= 3600
    }
}
