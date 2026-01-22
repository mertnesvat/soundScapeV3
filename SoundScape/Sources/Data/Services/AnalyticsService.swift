import Foundation
import FirebaseCore
import FirebaseAnalytics

@Observable
@MainActor
final class AnalyticsService {

    // MARK: - Analytics Event Names

    enum Event: String {
        // Sound playback events
        case soundPlayed = "sound_played"
        case soundStopped = "sound_stopped"
        case soundVolumeChanged = "sound_volume_changed"
        case mixCreated = "mix_created"

        // Timer events
        case sleepTimerStarted = "sleep_timer_started"
        case sleepTimerCompleted = "sleep_timer_completed"
        case sleepTimerCancelled = "sleep_timer_cancelled"

        // Session events
        case sessionStarted = "session_started"
        case sessionEnded = "session_ended"

        // Favorites & Saved Mixes
        case soundFavorited = "sound_favorited"
        case soundUnfavorited = "sound_unfavorited"
        case mixSaved = "mix_saved"
        case mixLoaded = "mix_loaded"
        case mixDeleted = "mix_deleted"

        // Binaural beats
        case binauralBeatStarted = "binaural_beat_started"
        case binauralBeatStopped = "binaural_beat_stopped"

        // Stories
        case storyStarted = "story_started"
        case storyCompleted = "story_completed"
        case storyPaused = "story_paused"

        // Alarms
        case alarmCreated = "alarm_created"
        case alarmTriggered = "alarm_triggered"
        case alarmSnoozed = "alarm_snoozed"
        case alarmDismissed = "alarm_dismissed"

        // Adaptive mode
        case adaptiveSessionStarted = "adaptive_session_started"
        case adaptiveSessionEnded = "adaptive_session_ended"

        // Discover
        case communityMixPlayed = "community_mix_played"
        case communityMixLiked = "community_mix_liked"

        // App lifecycle
        case appOpened = "app_opened"
        case appBackgrounded = "app_backgrounded"
        case tabSelected = "tab_selected"

        // User engagement
        case reviewPromptShown = "review_prompt_shown"
        case reviewPromptAccepted = "review_prompt_accepted"
        case reviewPromptDeclined = "review_prompt_declined"
    }

    // MARK: - Parameter Keys

    enum ParameterKey: String {
        case soundId = "sound_id"
        case soundName = "sound_name"
        case soundCategory = "sound_category"
        case volume = "volume"
        case duration = "duration_seconds"
        case mixName = "mix_name"
        case mixId = "mix_id"
        case soundCount = "sound_count"
        case timerDuration = "timer_duration_minutes"
        case beatType = "beat_type"
        case frequency = "frequency_hz"
        case storyId = "story_id"
        case storyTitle = "story_title"
        case alarmId = "alarm_id"
        case alarmTime = "alarm_time"
        case adaptiveMode = "adaptive_mode"
        case tabName = "tab_name"
        case sessionQuality = "session_quality"
        case timeToSleep = "time_to_sleep_minutes"
    }

    // MARK: - Initialization

    private(set) var isConfigured = false

    init() {
        // Firebase will be configured in SoundScapeApp
    }

    func configure() {
        guard !isConfigured else { return }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Enable analytics collection
        Analytics.setAnalyticsCollectionEnabled(true)

        isConfigured = true

        // Log app opened event
        logEvent(.appOpened)
    }

    // MARK: - Generic Event Logging

    func logEvent(_ event: Event, parameters: [ParameterKey: Any]? = nil) {
        guard isConfigured else { return }

        var params: [String: Any]?
        if let parameters = parameters {
            params = Dictionary(uniqueKeysWithValues: parameters.map { ($0.key.rawValue, $0.value) })
        }

        Analytics.logEvent(event.rawValue, parameters: params)
    }

    // MARK: - Sound Events

    func logSoundPlayed(soundId: String, soundName: String, category: String, volume: Float) {
        logEvent(.soundPlayed, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .soundCategory: category,
            .volume: volume
        ])
    }

    func logSoundStopped(soundId: String, soundName: String, duration: TimeInterval) {
        logEvent(.soundStopped, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .duration: Int(duration)
        ])
    }

    func logMixCreated(soundCount: Int) {
        logEvent(.mixCreated, parameters: [
            .soundCount: soundCount
        ])
    }

    // MARK: - Timer Events

    func logSleepTimerStarted(durationMinutes: Int) {
        logEvent(.sleepTimerStarted, parameters: [
            .timerDuration: durationMinutes
        ])
    }

    func logSleepTimerCompleted(durationMinutes: Int) {
        logEvent(.sleepTimerCompleted, parameters: [
            .timerDuration: durationMinutes
        ])
    }

    func logSleepTimerCancelled() {
        logEvent(.sleepTimerCancelled)
    }

    // MARK: - Session Events

    func logSessionEnded(duration: TimeInterval, quality: Int, soundsUsed: [String], timeToSleep: TimeInterval) {
        logEvent(.sessionEnded, parameters: [
            .duration: Int(duration),
            .sessionQuality: quality,
            .soundCount: soundsUsed.count,
            .timeToSleep: Int(timeToSleep / 60)
        ])
    }

    // MARK: - Favorites & Mixes

    func logSoundFavorited(soundId: String, soundName: String) {
        logEvent(.soundFavorited, parameters: [
            .soundId: soundId,
            .soundName: soundName
        ])
    }

    func logSoundUnfavorited(soundId: String, soundName: String) {
        logEvent(.soundUnfavorited, parameters: [
            .soundId: soundId,
            .soundName: soundName
        ])
    }

    func logMixSaved(mixName: String, soundCount: Int) {
        logEvent(.mixSaved, parameters: [
            .mixName: mixName,
            .soundCount: soundCount
        ])
    }

    func logMixLoaded(mixId: String, mixName: String) {
        logEvent(.mixLoaded, parameters: [
            .mixId: mixId,
            .mixName: mixName
        ])
    }

    func logMixDeleted(mixId: String) {
        logEvent(.mixDeleted, parameters: [
            .mixId: mixId
        ])
    }

    // MARK: - Binaural Beats

    func logBinauralBeatStarted(beatType: String, frequency: Double) {
        logEvent(.binauralBeatStarted, parameters: [
            .beatType: beatType,
            .frequency: frequency
        ])
    }

    func logBinauralBeatStopped(beatType: String, duration: TimeInterval) {
        logEvent(.binauralBeatStopped, parameters: [
            .beatType: beatType,
            .duration: Int(duration)
        ])
    }

    // MARK: - Stories

    func logStoryStarted(storyId: String, storyTitle: String) {
        logEvent(.storyStarted, parameters: [
            .storyId: storyId,
            .storyTitle: storyTitle
        ])
    }

    func logStoryCompleted(storyId: String, storyTitle: String) {
        logEvent(.storyCompleted, parameters: [
            .storyId: storyId,
            .storyTitle: storyTitle
        ])
    }

    // MARK: - Alarms

    func logAlarmCreated(alarmId: String, time: String) {
        logEvent(.alarmCreated, parameters: [
            .alarmId: alarmId,
            .alarmTime: time
        ])
    }

    func logAlarmTriggered(alarmId: String) {
        logEvent(.alarmTriggered, parameters: [
            .alarmId: alarmId
        ])
    }

    // MARK: - Adaptive Sessions

    func logAdaptiveSessionStarted(mode: String) {
        logEvent(.adaptiveSessionStarted, parameters: [
            .adaptiveMode: mode
        ])
    }

    func logAdaptiveSessionEnded(mode: String, duration: TimeInterval) {
        logEvent(.adaptiveSessionEnded, parameters: [
            .adaptiveMode: mode,
            .duration: Int(duration)
        ])
    }

    // MARK: - Community/Discover

    func logCommunityMixPlayed(mixId: String, mixName: String) {
        logEvent(.communityMixPlayed, parameters: [
            .mixId: mixId,
            .mixName: mixName
        ])
    }

    // MARK: - Navigation

    func logTabSelected(_ tabName: String) {
        logEvent(.tabSelected, parameters: [
            .tabName: tabName
        ])
    }

    // MARK: - Review Prompt

    func logReviewPromptShown() {
        logEvent(.reviewPromptShown)
    }

    func logReviewPromptAccepted() {
        logEvent(.reviewPromptAccepted)
    }

    func logReviewPromptDeclined() {
        logEvent(.reviewPromptDeclined)
    }

    // MARK: - User Properties

    func setUserProperty(_ value: String?, forName name: String) {
        guard isConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
    }

    func setUserId(_ userId: String?) {
        guard isConfigured else { return }
        Analytics.setUserID(userId)
    }
}
