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
        case analysis = 3
        case results = 4
        case painPoints = 5
        case benefits = 6
        case reviews = 7
        case features = 8
        case customPlan = 9
        case paywall = 10

        var progress: Double {
            Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (hidden on welcome and paywall)
                if currentStep != .welcome && currentStep != .paywall {
                    OnboardingProgressView(progress: currentStep.progress)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(
                        onGetStarted: nextStep,
                        onSkip: skipOnboarding
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

                    OnboardingAnalysisView(
                        isActive: currentStep == .analysis,
                        onComplete: nextStep
                    )
                    .tag(OnboardingStep.analysis)

                    OnboardingResultsView(
                        onContinue: nextStep
                    )
                    .tag(OnboardingStep.results)

                    OnboardingPainPointsView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.painPoints)

                    OnboardingBenefitsView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.benefits)

                    OnboardingReviewsView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.reviews)

                    OnboardingFeaturesView(
                        onContinue: nextStep,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.features)

                    OnboardingCustomPlanView(
                        onContinue: showPaywall,
                        onBack: previousStep
                    )
                    .tag(OnboardingStep.customPlan)

                    OnboardingPaywallView(
                        onComplete: completeOnboarding,
                        isPresented: false
                    )
                    .tag(OnboardingStep.paywall)
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

    private func skipOnboarding() {
        onboardingService.completeOnboarding()
    }

    private func showPaywall() {
        // If already premium, skip paywall and complete onboarding
        if subscriptionService.isPremium {
            completeOnboarding()
            return
        }

        // Set placement context for analytics
        paywallService.setPaywallPlacement("onboarding")

        // Otherwise, show the paywall step
        withAnimation {
            currentStep = .paywall
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
}
