import SwiftUI
import UIKit
import FirebaseCore

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
    @State private var appReviewService = AppReviewService()

    init() {
        FirebaseApp.configure()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
                .environment(appReviewService)
                .preferredColorScheme(.dark)
                .onAppear {
                    if sleepTimerService == nil {
                        sleepTimerService = SleepTimerService(audioEngine: audioEngine)
                    }
                    if adaptiveSessionService == nil {
                        adaptiveSessionService = AdaptiveSessionService(audioEngine: audioEngine)
                    }
                    // Wire up InsightsService to AudioEngine for session tracking
                    audioEngine.setInsightsService(insightsService)
                    audioEngine.setAnalyticsService(analyticsService)

                    // Wire up analytics and review services to other services
                    sleepTimerService?.setServices(analytics: analyticsService, appReview: appReviewService)
                    favoritesService.setServices(analytics: analyticsService, appReview: appReviewService)
                    savedMixesService.setServices(analytics: analyticsService, appReview: appReviewService)
                    adaptiveSessionService?.setServices(analytics: analyticsService, appReview: appReviewService)

                    // Log app launch event
                    analyticsService.logAppLaunch()
                    analyticsService.updateUserProperties()
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
