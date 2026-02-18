import SwiftUI
import UIKit

@main
struct SoundScapeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var audioEngine = AudioEngine()
    @State private var sleepTimerService: SleepTimerService?
    @State private var adaptiveSessionService: AdaptiveSessionService?
    @State private var favoritesService = FavoritesService()
    @State private var savedMixesService = SavedMixesService()
    @State private var storyProgressService = StoryProgressService()
    @State private var binauralBeatEngine = BinauralBeatEngine()
    @State private var alarmService = AlarmService()
    @State private var sleepRecordingService = SleepRecordingService()
    @State private var insightsService = InsightsService()
    @State private var analyticsService = AnalyticsService()
    @State private var reviewPromptService = ReviewPromptService()
    @State private var appearanceService = AppearanceService()
    @State private var motionService = MotionService()
    @State private var sleepBuddyService = SleepBuddyService()
    @State private var sleepContentPlayerService = SleepContentPlayerService()
    @State private var onboardingService = OnboardingService()
    @State private var subscriptionService = SubscriptionService()
    @State private var paywallService = PaywallService()
    @State private var premiumManager: PremiumManager?

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
            .environment(sleepRecordingService)
            .environment(insightsService)
            .environment(analyticsService)
            .environment(reviewPromptService)
            .environment(appearanceService)
            .environment(motionService)
            .environment(sleepBuddyService)
            .environment(sleepContentPlayerService)
            .environment(onboardingService)
            .environment(subscriptionService)
            .environment(paywallService)
            .environment(premiumManager ?? createPremiumManager())
            .preferredColorScheme(.dark)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh subscription status when app returns to foreground
                Task {
                    await subscriptionService.refreshStatus()
                }
            }
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

                    // Wire up PaywallService to AnalyticsService and SubscriptionService
                    paywallService.setSubscriptionService(subscriptionService)
                    paywallService.setAnalyticsService(analyticsService)

                    // Initialize PremiumManager with PaywallService
                    if premiumManager == nil {
                        premiumManager = PremiumManager(paywallService: paywallService)
                    }

                    // Prepare alarm notification sounds on a background thread
                    Task.detached(priority: .utility) {
                        AlarmNotificationSoundManager.shared.prepareAllAlarmSounds()
                    }
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

    @MainActor
    private func createPremiumManager() -> PremiumManager {
        PremiumManager(paywallService: paywallService)
    }

    private func configureAppearance() {
        // Configure global appearance for dark mode
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}
