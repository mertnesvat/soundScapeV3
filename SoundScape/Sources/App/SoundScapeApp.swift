import SwiftUI
import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif

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

    init() {
        configureFirebase()
        configureAppearance()
    }

    private func configureFirebase() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
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
                    // Wire up AnalyticsService to services for analytics tracking
                    sleepTimerService?.setAnalyticsService(analyticsService)
                    favoritesService.setAnalyticsService(analyticsService)
                    savedMixesService.setAnalyticsService(analyticsService)
                    // Configure analytics service
                    analyticsService.configure()
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
