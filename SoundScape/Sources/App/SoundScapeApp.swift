import SwiftUI
import UIKit

@main
struct SoundScapeApp: App {
    @State private var audioEngine = AudioEngine()
    @State private var sleepTimerService: SleepTimerService?
    @State private var adaptiveSessionService: AdaptiveSessionService?
    @State private var favoritesService = FavoritesService()
    @State private var savedMixesService = SavedMixesService()
    @State private var storyProgressService = StoryProgressService()
    @State private var binauralBeatEngine = BinauralBeatEngine()
    @State private var alarmService = AlarmService()
    @State private var insightsService = InsightsService()
    @State private var analyticsService = AnalyticsService()
    @State private var reviewPromptService = ReviewPromptService()
    @State private var appearanceService = AppearanceService()
    @State private var motionService = MotionService()
    @State private var sleepBuddyService = SleepBuddyService()
    @State private var sleepContentPlayerService = SleepContentPlayerService()
    @State private var onboardingService = OnboardingService()
    @State private var paywallService = PaywallService()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingService.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingContainerView()
                }
            }
            .environment(audioEngine)
            .environment(sleepTimerService ?? createSleepTimerService())
            .environment(adaptiveSessionService ?? createAdaptiveSessionService())
            .environment(favoritesService)
            .environment(savedMixesService)
            .environment(storyProgressService)
            .environment(binauralBeatEngine)
            .environment(alarmService)
            .environment(insightsService)
            .environment(analyticsService)
            .environment(reviewPromptService)
            .environment(appearanceService)
            .environment(motionService)
            .environment(sleepBuddyService)
            .environment(sleepContentPlayerService)
            .environment(onboardingService)
            .environment(paywallService)
            .preferredColorScheme(.dark)
                .onAppear {
                    // Configure Firebase Analytics
                    analyticsService.configure()

                    // Wire up services to AnalyticsService and ReviewPromptService
                    reviewPromptService.setAnalyticsService(analyticsService)
                    audioEngine.setAnalyticsService(analyticsService)
                    audioEngine.setReviewPromptService(reviewPromptService)
                    favoritesService.setAnalyticsService(analyticsService)
                    favoritesService.setReviewPromptService(reviewPromptService)
                    savedMixesService.setAnalyticsService(analyticsService)
                    savedMixesService.setReviewPromptService(reviewPromptService)

                    if sleepTimerService == nil {
                        sleepTimerService = SleepTimerService(audioEngine: audioEngine)
                    }
                    sleepTimerService?.setAnalyticsService(analyticsService)

                    if adaptiveSessionService == nil {
                        adaptiveSessionService = AdaptiveSessionService(audioEngine: audioEngine)
                    }
                    // Wire up InsightsService to AudioEngine for session tracking
                    audioEngine.setInsightsService(insightsService)

                    // Wire up SleepBuddyService to InsightsService for streak calculation
                    sleepBuddyService.setInsightsService(insightsService)

                    // Wire up PaywallService to AnalyticsService
                    paywallService.setAnalyticsService(analyticsService)
                }
        }
    }

    @MainActor
    private func createSleepTimerService() -> SleepTimerService {
        SleepTimerService(audioEngine: audioEngine)
    }

    @MainActor
    private func createAdaptiveSessionService() -> AdaptiveSessionService {
        AdaptiveSessionService(audioEngine: audioEngine)
    }

    private func configureAppearance() {
        // Configure global appearance for dark mode
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}
