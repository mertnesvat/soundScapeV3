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

        // Settings & Feature interest
        case settingsOpened = "settings_opened"
        case sleepBuddyInterestShown = "sleep_buddy_interest_shown"

        // Paywall events
        case paywallShown = "paywall_shown"
        case paywallDismissed = "paywall_dismissed"
        case paywallConverted = "paywall_converted"
        case purchaseCompleted = "purchase_completed"
        case purchaseRestored = "purchase_restored"
        case paywallError = "paywall_error"
        case paywallSuppressed = "paywall_suppressed"

        // Onboarding funnel events
        case onboardingStarted = "onboarding_started"
        case onboardingStepViewed = "onboarding_step_viewed"
        case onboardingStepCompleted = "onboarding_step_completed"
        case onboardingGoalSelected = "onboarding_goal_selected"
        case onboardingChallengesSelected = "onboarding_challenges_selected"
        case onboardingFirstSoundPlayed = "onboarding_first_sound_played"
        case onboardingTutorialStepViewed = "onboarding_tutorial_step_viewed"
        case onboardingTutorialSkipped = "onboarding_tutorial_skipped"
        case onboardingTutorialCompleted = "onboarding_tutorial_completed"
        case onboardingCompleted = "onboarding_completed"
        case onboardingSkipped = "onboarding_skipped"

        // Wind Down & Content events
        case windDownTabOpened = "wind_down_tab_opened"
        case windDownCategoryViewed = "wind_down_category_viewed"
        case windDownContentTapped = "wind_down_content_tapped"
        case windDownContentStarted = "wind_down_content_started"
        case windDownContentPaused = "wind_down_content_paused"
        case windDownContentResumed = "wind_down_content_resumed"
        case windDownContentCompleted = "wind_down_content_completed"
        case windDownContentAbandoned = "wind_down_content_abandoned"
        case windDownFeaturedTapped = "wind_down_featured_tapped"
        case windDownContinueListeningTapped = "wind_down_continue_listening_tapped"
        case windDownPremiumBlocked = "wind_down_premium_blocked"

        // Navigation & Sounds events
        case tabSwitched = "tab_switched"
        case screenViewed = "screen_viewed"
        case sheetOpened = "sheet_opened"
        case sheetDismissed = "sheet_dismissed"
        case soundCardTapped = "sound_card_tapped"
        case mixerOpened = "mixer_opened"
        case mixerSoundAdded = "mixer_sound_added"
        case mixerSoundRemoved = "mixer_sound_removed"
        case volumeAdjusted = "volume_adjusted"
        case allSoundsStopped = "all_sounds_stopped"

        // Paywall funnel events
        case paywallTriggered = "paywall_triggered"
        case paywallPlanSelected = "paywall_plan_selected"
        case paywallPurchaseStarted = "paywall_purchase_started"
        case paywallPurchaseFailed = "paywall_purchase_failed"

        // Retention & milestones
        case appSessionStarted = "app_session_started"
        case firstSoundPlayedEver = "first_sound_played_ever"
        case firstMixCreated = "first_mix_created"
        case firstTimerSet = "first_timer_set"
        case firstFavoriteAdded = "first_favorite_added"
        case listeningMilestone = "listening_milestone"

        // Binaural beats analytics
        case binauralTabOpened = "binaural_tab_opened"
        case binauralStateSelected = "binaural_state_selected"
        case binauralFrequencyAdjusted = "binaural_frequency_adjusted"
        case binauralSessionEnded = "binaural_session_ended"

        // Insights tab
        case insightsTabOpened = "insights_tab_opened"
        case insightsPeriodChanged = "insights_period_changed"
        case insightsRecommendationTapped = "insights_recommendation_tapped"

        // Sleep recording
        case sleepRecordingStarted = "sleep_recording_started"
        case sleepRecordingStopped = "sleep_recording_stopped"
        case sleepRecordingReportViewed = "sleep_recording_report_viewed"
        case sleepRecordingHighlightPlayed = "sleep_recording_highlight_played"
        case sleepRecordingExported = "sleep_recording_exported"
        case sleepRecordingDeleted = "sleep_recording_deleted"

        // Discover & Adaptive
        case discoverTabOpened = "discover_tab_opened"
        case discoverMixPreviewed = "discover_mix_previewed"
        case adaptiveTabOpened = "adaptive_tab_opened"
        case adaptiveContextChanged = "adaptive_session_context_changed"
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
        case featureName = "feature_name"
        case placement = "placement"
        case errorMessage = "error_message"
        case reason = "reason"
        case triggerSource = "trigger_source"
        case stepNumber = "step_number"
        case stepName = "step_name"
        case goal = "goal"
        case challenges = "challenges"
        case challengeCount = "challenge_count"
        case source = "source"
        case tutorialStep = "tutorial_step"
        case tutorialStepName = "tutorial_step_name"
        case skippedAtStep = "skipped_at_step"
        case totalDuration = "total_duration_seconds"
        case stepsCompleted = "steps_completed"
        case goalSelected = "goal_selected"
        case contentId = "content_id"
        case contentTitle = "content_title"
        case category = "category"
        case isPremium = "is_premium"
        case isLocked = "is_locked"
        case isPlaying = "is_playing"
        case progressPercent = "progress_percent"
        case elapsedSeconds = "elapsed_seconds"
        case completionPercent = "completion_percent"
        case durationMinutes = "duration_minutes"
        case timeOfDay = "time_of_day"
        case greetingShown = "greeting_shown"
        case fromTab = "from_tab"
        case toTab = "to_tab"
        case sessionDurationOnTab = "session_duration_on_tab_seconds"
        case screenName = "screen_name"
        case tab = "tab"
        case sheetName = "sheet_name"
        case fromScreen = "from_screen"
        case totalActiveSounds = "total_active_sounds"
        case newVolume = "new_volume"
        case sessionDuration = "session_duration_seconds"
        case sessionNumber = "session_number"
        case daysSinceInstall = "days_since_install"
        case daysSinceLastSession = "days_since_last_session"
        case secondsSinceInstall = "seconds_since_install"
        case milestone = "milestone"
        case plan = "plan"
        case errorType = "error_type"
        case state = "state"
        case period = "period"
        case recommendationType = "recommendation_type"
        case hasData = "has_data"
        case delayMinutes = "delay_minutes"
        case eventsDetected = "events_detected"
        case snoreScore = "snore_score"
        case eventType = "event_type"
        case eventDuration = "event_duration"
        case exportType = "export_type"
        case recordingId = "recording_id"
        case newContext = "new_context"
        case previousContext = "previous_context"
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

    // MARK: - Settings & Feature Interest

    func logSettingsOpened() {
        logEvent(.settingsOpened)
    }

    func logSleepBuddyInterestShown() {
        logEvent(.sleepBuddyInterestShown, parameters: [
            .featureName: "sleep_buddy"
        ])
    }

    // MARK: - Paywall Events

    func logPaywallShown(placement: String) {
        logEvent(.paywallShown, parameters: [
            .placement: placement
        ])
    }

    func logPaywallDismissed(placement: String) {
        logEvent(.paywallDismissed, parameters: [
            .placement: placement
        ])
    }

    func logPaywallConverted(placement: String) {
        logEvent(.paywallConverted, parameters: [
            .placement: placement
        ])
    }

    func logPurchaseCompleted(placement: String) {
        logEvent(.purchaseCompleted, parameters: [
            .placement: placement
        ])
    }

    func logPurchaseRestored() {
        logEvent(.purchaseRestored)
    }

    func logPaywallError(placement: String, error: String) {
        logEvent(.paywallError, parameters: [
            .placement: placement,
            .errorMessage: error
        ])
    }

    func logPaywallSuppressed(reason: String, triggerSource: String) {
        logEvent(.paywallSuppressed, parameters: [
            .reason: reason,
            .triggerSource: triggerSource
        ])
    }

    // MARK: - Onboarding Funnel Events

    func logOnboardingStarted(source: String) {
        logEvent(.onboardingStarted, parameters: [
            .source: source
        ])
    }

    func logOnboardingStepViewed(stepNumber: Int, stepName: String) {
        logEvent(.onboardingStepViewed, parameters: [
            .stepNumber: stepNumber,
            .stepName: stepName
        ])
    }

    func logOnboardingStepCompleted(stepNumber: Int, stepName: String, duration: TimeInterval) {
        logEvent(.onboardingStepCompleted, parameters: [
            .stepNumber: stepNumber,
            .stepName: stepName,
            .duration: Int(duration)
        ])
    }

    func logOnboardingGoalSelected(goal: String) {
        logEvent(.onboardingGoalSelected, parameters: [
            .goal: goal
        ])
    }

    func logOnboardingChallengesSelected(challenges: String, count: Int) {
        logEvent(.onboardingChallengesSelected, parameters: [
            .challenges: challenges,
            .challengeCount: count
        ])
    }

    func logOnboardingFirstSoundPlayed(soundId: String, soundName: String, category: String) {
        logEvent(.onboardingFirstSoundPlayed, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .soundCategory: category
        ])
    }

    func logOnboardingTutorialStepViewed(step: Int, stepName: String) {
        logEvent(.onboardingTutorialStepViewed, parameters: [
            .tutorialStep: step,
            .tutorialStepName: stepName
        ])
    }

    func logOnboardingTutorialSkipped(atStep: Int) {
        logEvent(.onboardingTutorialSkipped, parameters: [
            .skippedAtStep: atStep
        ])
    }

    func logOnboardingTutorialCompleted(duration: TimeInterval) {
        logEvent(.onboardingTutorialCompleted, parameters: [
            .duration: Int(duration)
        ])
    }

    func logOnboardingCompleted(totalDuration: TimeInterval, stepsCompleted: Int, goal: String) {
        logEvent(.onboardingCompleted, parameters: [
            .totalDuration: Int(totalDuration),
            .stepsCompleted: stepsCompleted,
            .goalSelected: goal
        ])
    }

    func logOnboardingSkipped(atStepNumber: Int, stepName: String) {
        logEvent(.onboardingSkipped, parameters: [
            .stepNumber: atStepNumber,
            .stepName: stepName
        ])
    }

    // MARK: - Wind Down & Content Events

    func logWindDownTabOpened(timeOfDay: String, greeting: String) {
        logEvent(.windDownTabOpened, parameters: [
            .timeOfDay: timeOfDay,
            .greetingShown: greeting
        ])
    }

    func logWindDownCategoryViewed(category: String) {
        logEvent(.windDownCategoryViewed, parameters: [
            .category: category
        ])
    }

    func logWindDownContentTapped(contentId: String, title: String, category: String, isPremium: Bool, isLocked: Bool) {
        logEvent(.windDownContentTapped, parameters: [
            .contentId: contentId,
            .contentTitle: title,
            .category: category,
            .isPremium: isPremium,
            .isLocked: isLocked
        ])
    }

    func logWindDownContentStarted(contentId: String, title: String, category: String, durationMinutes: Double) {
        logEvent(.windDownContentStarted, parameters: [
            .contentId: contentId,
            .contentTitle: title,
            .category: category,
            .durationMinutes: durationMinutes
        ])
    }

    func logWindDownContentPaused(contentId: String, progressPercent: Double, elapsed: TimeInterval) {
        logEvent(.windDownContentPaused, parameters: [
            .contentId: contentId,
            .progressPercent: Int(progressPercent * 100),
            .elapsedSeconds: Int(elapsed)
        ])
    }

    func logWindDownContentResumed(contentId: String, progressPercent: Double) {
        logEvent(.windDownContentResumed, parameters: [
            .contentId: contentId,
            .progressPercent: Int(progressPercent * 100)
        ])
    }

    func logWindDownContentCompleted(contentId: String, title: String, category: String, duration: TimeInterval, completionPercent: Double) {
        logEvent(.windDownContentCompleted, parameters: [
            .contentId: contentId,
            .contentTitle: title,
            .category: category,
            .duration: Int(duration),
            .completionPercent: Int(completionPercent * 100)
        ])
    }

    func logWindDownContentAbandoned(contentId: String, progressPercent: Double, elapsed: TimeInterval, category: String) {
        logEvent(.windDownContentAbandoned, parameters: [
            .contentId: contentId,
            .progressPercent: Int(progressPercent * 100),
            .elapsedSeconds: Int(elapsed),
            .category: category
        ])
    }

    func logWindDownFeaturedTapped(contentId: String, title: String) {
        logEvent(.windDownFeaturedTapped, parameters: [
            .contentId: contentId,
            .contentTitle: title
        ])
    }

    func logWindDownContinueListeningTapped(contentId: String, progressPercent: Double) {
        logEvent(.windDownContinueListeningTapped, parameters: [
            .contentId: contentId,
            .progressPercent: Int(progressPercent * 100)
        ])
    }

    func logWindDownPremiumBlocked(contentId: String, category: String) {
        logEvent(.windDownPremiumBlocked, parameters: [
            .contentId: contentId,
            .category: category
        ])
    }

    // MARK: - Navigation & Sounds Events

    func logTabSwitched(fromTab: String, toTab: String, durationOnTab: TimeInterval) {
        logEvent(.tabSwitched, parameters: [
            .fromTab: fromTab,
            .toTab: toTab,
            .sessionDurationOnTab: Int(durationOnTab)
        ])
    }

    func logScreenViewed(screenName: String, tab: String) {
        logEvent(.screenViewed, parameters: [
            .screenName: screenName,
            .tab: tab
        ])
    }

    func logSheetOpened(sheetName: String, fromScreen: String) {
        logEvent(.sheetOpened, parameters: [
            .sheetName: sheetName,
            .fromScreen: fromScreen
        ])
    }

    func logSheetDismissed(sheetName: String, duration: TimeInterval) {
        logEvent(.sheetDismissed, parameters: [
            .sheetName: sheetName,
            .duration: Int(duration)
        ])
    }

    func logSoundCardTapped(soundId: String, soundName: String, category: String, isPremium: Bool, isPlaying: Bool) {
        logEvent(.soundCardTapped, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .soundCategory: category,
            .isPremium: isPremium,
            .isPlaying: isPlaying
        ])
    }

    func logMixerOpened(activeSoundCount: Int) {
        logEvent(.mixerOpened, parameters: [
            .soundCount: activeSoundCount
        ])
    }

    func logMixerSoundAdded(soundId: String, soundName: String, totalActive: Int) {
        logEvent(.mixerSoundAdded, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .totalActiveSounds: totalActive
        ])
    }

    func logMixerSoundRemoved(soundId: String, totalActive: Int) {
        logEvent(.mixerSoundRemoved, parameters: [
            .soundId: soundId,
            .totalActiveSounds: totalActive
        ])
    }

    func logVolumeAdjusted(soundId: String, newVolume: Float) {
        logEvent(.volumeAdjusted, parameters: [
            .soundId: soundId,
            .newVolume: newVolume
        ])
    }

    func logAllSoundsStopped(activeSoundCount: Int, sessionDuration: TimeInterval) {
        logEvent(.allSoundsStopped, parameters: [
            .soundCount: activeSoundCount,
            .sessionDuration: Int(sessionDuration)
        ])
    }

    // MARK: - Paywall Funnel Events

    func logPaywallTriggered(triggerSource: String, sessionNumber: Int, contentId: String?) {
        var params: [ParameterKey: Any] = [
            .triggerSource: triggerSource,
            .sessionNumber: sessionNumber
        ]
        if let contentId { params[.contentId] = contentId }
        logEvent(.paywallTriggered, parameters: params)
    }

    func logPaywallPlanSelected(plan: String, placement: String) {
        logEvent(.paywallPlanSelected, parameters: [
            .plan: plan,
            .placement: placement
        ])
    }

    func logPaywallPurchaseStarted(plan: String, placement: String) {
        logEvent(.paywallPurchaseStarted, parameters: [
            .plan: plan,
            .placement: placement
        ])
    }

    func logPaywallPurchaseFailed(plan: String, errorType: String, placement: String) {
        logEvent(.paywallPurchaseFailed, parameters: [
            .plan: plan,
            .errorType: errorType,
            .placement: placement
        ])
    }

    // MARK: - Retention & Milestones

    func logAppSessionStarted(sessionNumber: Int, daysSinceInstall: Int, daysSinceLastSession: Int) {
        logEvent(.appSessionStarted, parameters: [
            .sessionNumber: sessionNumber,
            .daysSinceInstall: daysSinceInstall,
            .daysSinceLastSession: daysSinceLastSession
        ])
    }

    func logFirstSoundPlayedEver(soundId: String, soundName: String, secondsSinceInstall: Int) {
        logEvent(.firstSoundPlayedEver, parameters: [
            .soundId: soundId,
            .soundName: soundName,
            .secondsSinceInstall: secondsSinceInstall
        ])
    }

    func logFirstMixCreated(soundCount: Int, secondsSinceInstall: Int) {
        logEvent(.firstMixCreated, parameters: [
            .soundCount: soundCount,
            .secondsSinceInstall: secondsSinceInstall
        ])
    }

    func logFirstTimerSet(durationMinutes: Int, secondsSinceInstall: Int) {
        logEvent(.firstTimerSet, parameters: [
            .timerDuration: durationMinutes,
            .secondsSinceInstall: secondsSinceInstall
        ])
    }

    func logFirstFavoriteAdded(soundId: String, secondsSinceInstall: Int) {
        logEvent(.firstFavoriteAdded, parameters: [
            .soundId: soundId,
            .secondsSinceInstall: secondsSinceInstall
        ])
    }

    func logListeningMilestone(milestone: String, soundCount: Int) {
        logEvent(.listeningMilestone, parameters: [
            .milestone: milestone,
            .soundCount: soundCount
        ])
    }

    // MARK: - Binaural Beats Analytics

    func logBinauralTabOpened() {
        logEvent(.binauralTabOpened)
    }

    func logBinauralStateSelected(state: String, isPremium: Bool) {
        logEvent(.binauralStateSelected, parameters: [
            .state: state,
            .isPremium: isPremium
        ])
    }

    func logBinauralFrequencyAdjusted(state: String, frequency: Double) {
        logEvent(.binauralFrequencyAdjusted, parameters: [
            .state: state,
            .frequency: frequency
        ])
    }

    func logBinauralSessionEnded(state: String, duration: TimeInterval) {
        logEvent(.binauralSessionEnded, parameters: [
            .state: state,
            .duration: Int(duration)
        ])
    }

    // MARK: - Insights Tab Analytics

    func logInsightsTabOpened(hasData: Bool) {
        logEvent(.insightsTabOpened, parameters: [
            .hasData: hasData
        ])
    }

    func logInsightsPeriodChanged(period: String) {
        logEvent(.insightsPeriodChanged, parameters: [
            .period: period
        ])
    }

    func logInsightsRecommendationTapped(type: String) {
        logEvent(.insightsRecommendationTapped, parameters: [
            .recommendationType: type
        ])
    }

    // MARK: - Sleep Recording Analytics

    func logSleepRecordingStarted(delayMinutes: Int) {
        logEvent(.sleepRecordingStarted, parameters: [
            .delayMinutes: delayMinutes
        ])
    }

    func logSleepRecordingStopped(duration: TimeInterval, eventsDetected: Int) {
        logEvent(.sleepRecordingStopped, parameters: [
            .duration: Int(duration),
            .eventsDetected: eventsDetected
        ])
    }

    func logSleepRecordingReportViewed(recordingId: String, snoreScore: Int) {
        logEvent(.sleepRecordingReportViewed, parameters: [
            .recordingId: recordingId,
            .snoreScore: snoreScore
        ])
    }

    func logSleepRecordingHighlightPlayed(eventType: String, eventDuration: TimeInterval) {
        logEvent(.sleepRecordingHighlightPlayed, parameters: [
            .eventType: eventType,
            .eventDuration: Int(eventDuration)
        ])
    }

    func logSleepRecordingExported(exportType: String) {
        logEvent(.sleepRecordingExported, parameters: [
            .exportType: exportType
        ])
    }

    func logSleepRecordingDeleted(duration: TimeInterval) {
        logEvent(.sleepRecordingDeleted, parameters: [
            .duration: Int(duration)
        ])
    }

    // MARK: - Discover & Adaptive Analytics

    func logDiscoverTabOpened() {
        logEvent(.discoverTabOpened)
    }

    func logDiscoverMixPreviewed(mixId: String, mixName: String) {
        logEvent(.discoverMixPreviewed, parameters: [
            .mixId: mixId,
            .mixName: mixName
        ])
    }

    func logAdaptiveTabOpened() {
        logEvent(.adaptiveTabOpened)
    }

    func logAdaptiveContextChanged(newContext: String, previousContext: String) {
        logEvent(.adaptiveContextChanged, parameters: [
            .newContext: newContext,
            .previousContext: previousContext
        ])
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

    // MARK: - Install Date & Milestone Tracking

    private static let installDateKey = "app_install_date"
    private static let lastSessionDateKey = "app_last_session_date"
    private static let milestoneFirstSoundKey = "milestone_first_sound"
    private static let milestoneFirstMixKey = "milestone_first_mix"
    private static let milestoneFirstTimerKey = "milestone_first_timer"
    private static let milestoneFirstFavoriteKey = "milestone_first_favorite"

    /// Returns the install date, setting it on first call
    var installDate: Date {
        if let date = UserDefaults.standard.object(forKey: Self.installDateKey) as? Date {
            return date
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: Self.installDateKey)
        return now
    }

    /// Seconds since install
    var secondsSinceInstall: Int {
        Int(Date().timeIntervalSince(installDate))
    }

    /// Days since install
    var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    /// Days since last session
    var daysSinceLastSession: Int {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastSessionDateKey) as? Date else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    /// Record last session date
    func recordSessionDate() {
        UserDefaults.standard.set(Date(), forKey: Self.lastSessionDateKey)
    }

    /// Check and fire a milestone event (fires only once per user lifetime)
    func checkMilestone(_ key: String, fire: () -> Void) {
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        fire()
    }

    /// Check and fire first sound played milestone
    func checkFirstSoundMilestone(soundId: String, soundName: String) {
        checkMilestone(Self.milestoneFirstSoundKey) {
            logFirstSoundPlayedEver(soundId: soundId, soundName: soundName, secondsSinceInstall: secondsSinceInstall)
        }
    }

    /// Check and fire first mix created milestone (2+ sounds)
    func checkFirstMixMilestone(soundCount: Int) {
        guard soundCount >= 2 else { return }
        checkMilestone(Self.milestoneFirstMixKey) {
            logFirstMixCreated(soundCount: soundCount, secondsSinceInstall: secondsSinceInstall)
        }
    }

    /// Check and fire first timer set milestone
    func checkFirstTimerMilestone(durationMinutes: Int) {
        checkMilestone(Self.milestoneFirstTimerKey) {
            logFirstTimerSet(durationMinutes: durationMinutes, secondsSinceInstall: secondsSinceInstall)
        }
    }

    /// Check and fire first favorite added milestone
    func checkFirstFavoriteMilestone(soundId: String) {
        checkMilestone(Self.milestoneFirstFavoriteKey) {
            logFirstFavoriteAdded(soundId: soundId, secondsSinceInstall: secondsSinceInstall)
        }
    }
}
