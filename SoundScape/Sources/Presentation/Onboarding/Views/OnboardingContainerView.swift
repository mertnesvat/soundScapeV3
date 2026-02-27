import SwiftUI

struct OnboardingContainerView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var currentStep: OnboardingStep = .welcome
    @State private var onboardingStartTime: Date = .now
    @State private var stepStartTime: Date = .now

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case quizGoal = 1
        case quizChallenges = 2
        case guidedFirstSound = 3
        case complete = 4

        var progress: Double {
            Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
        }

        var name: String {
            switch self {
            case .welcome: return "welcome"
            case .quizGoal: return "goal"
            case .quizChallenges: return "challenges"
            case .guidedFirstSound: return "guided_first_sound"
            case .complete: return "complete"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (hidden on welcome and complete)
                if currentStep != .welcome && currentStep != .complete {
                    OnboardingProgressView(progress: currentStep.progress)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(
                        onGetStarted: nextStep
                    )
                    .tag(OnboardingStep.welcome)

                    OnboardingQuizGoalView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.quizGoal)

                    OnboardingQuizChallengesView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.quizChallenges)

                    GuidedFirstSoundView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.guidedFirstSound)

                    OnboardingCompleteView(
                        onComplete: completeOnboarding
                    )
                    .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            onboardingStartTime = Date()
            stepStartTime = Date()
            analyticsService.logOnboardingStarted(source: "fresh_install")
            analyticsService.logOnboardingStepViewed(stepNumber: 0, stepName: "welcome")
        }
        .onChange(of: currentStep) { oldStep, newStep in
            // Log completion of previous step
            let stepDuration = Date().timeIntervalSince(stepStartTime)
            analyticsService.logOnboardingStepCompleted(
                stepNumber: oldStep.rawValue,
                stepName: oldStep.name,
                duration: stepDuration
            )

            // Log viewing of new step
            analyticsService.logOnboardingStepViewed(
                stepNumber: newStep.rawValue,
                stepName: newStep.name
            )

            stepStartTime = Date()
        }
    }

    private func nextStep() {
        withAnimation {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }

    private func previousStep() {
        withAnimation {
            if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prev
            }
        }
    }

    private func completeOnboarding() {
        let totalDuration = Date().timeIntervalSince(onboardingStartTime)
        let goal = onboardingService.profile.sleepGoal?.rawValue ?? "none"
        analyticsService.logOnboardingCompleted(
            totalDuration: totalDuration,
            stepsCompleted: OnboardingStep.allCases.count,
            goal: goal
        )
        onboardingService.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environment(OnboardingService())
        .environment(PaywallService())
        .environment(SubscriptionService())
        .environment(AudioEngine())
        .environment(AnalyticsService())
}
