import SwiftUI

struct OnboardingContainerView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var currentStep: OnboardingStep = .welcome

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case quizGoal = 1
        case quizChallenges = 2
        case guidedFirstSound = 3
        case complete = 4

        var progress: Double {
            Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
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
        onboardingService.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environment(OnboardingService())
        .environment(PaywallService())
        .environment(SubscriptionService())
        .environment(AudioEngine())
}
