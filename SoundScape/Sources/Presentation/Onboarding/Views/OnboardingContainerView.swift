import SwiftUI

struct OnboardingContainerView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @State private var currentStep: OnboardingStep = .intent
    @State private var selectedIntent: UserIntent?
    @State private var hasTrackedStart = false

    enum OnboardingStep: Int, CaseIterable {
        case intent = 0
        case soundPreview = 1
        case complete = 2

        var progress: Double {
            Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressView(progress: currentStep.progress)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    OnboardingIntentView(
                        onContinue: { intent in
                            selectedIntent = intent
                            onboardingService.trackIntentSelected(category: intent.rawValue)
                            onboardingService.trackStepCompleted(OnboardingStep.intent.rawValue + 1)
                            nextStep()
                        },
                        onSkip: { skipOnboarding(atStep: OnboardingStep.intent.rawValue + 1) }
                    )
                    .tag(OnboardingStep.intent)

                    if let intent = selectedIntent {
                        OnboardingSoundPreviewView(
                            intent: intent,
                            onContinue: {
                                onboardingService.trackStepCompleted(OnboardingStep.soundPreview.rawValue + 1)
                                nextStep()
                            },
                            onSkip: { skipOnboarding(atStep: OnboardingStep.soundPreview.rawValue + 1) }
                        )
                        .tag(OnboardingStep.soundPreview)
                    }

                    OnboardingCompleteView(
                        onExplore: completeOnboarding
                    )
                    .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !hasTrackedStart {
                hasTrackedStart = true
                onboardingService.trackOnboardingStarted()
            }
        }
    }

    private func nextStep() {
        withAnimation {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }

    private func skipOnboarding(atStep step: Int) {
        onboardingService.trackOnboardingSkipped(atStep: step)
        onboardingService.completeOnboarding()
    }

    private func completeOnboarding() {
        onboardingService.trackStepCompleted(OnboardingStep.complete.rawValue + 1)
        onboardingService.completeOnboarding()
    }
}

#Preview {
    OnboardingContainerView()
        .environment(OnboardingService())
        .environment(AudioEngine())
}
