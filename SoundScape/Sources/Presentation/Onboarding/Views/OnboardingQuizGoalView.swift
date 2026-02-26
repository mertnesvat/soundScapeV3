import SwiftUI

struct OnboardingQuizGoalView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @State private var selectedGoal: OnboardingSleepGoal?
    let onContinue: () -> Void
    let onBack: () -> Void

    /// Simplified goal options for onboarding (4 clear choices)
    private let simplifiedGoals: [OnboardingSleepGoal] = [
        .fallAsleep,
        .relaxation,
        .focus,
        .meditation
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Question
            Text(String(localized: "What brings you here?"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 32)
                .padding(.bottom, 8)

            Text(String(localized: "Tap to select your main goal"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 32)

            // 4 large goal cards
            VStack(spacing: 16) {
                ForEach(simplifiedGoals, id: \.self) { goal in
                    SimplifiedGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = goal
                                onboardingService.setSleepGoal(goal)
                            }
                            // Auto-advance after brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                onContinue()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color.black)
        .onAppear {
            selectedGoal = onboardingService.profile.sleepGoal
        }
    }
}

private struct SimplifiedGoalCard: View {
    let goal: OnboardingSleepGoal
    let isSelected: Bool
    let onTap: () -> Void

    private var goalLabel: String {
        switch goal {
        case .fallAsleep: return String(localized: "Sleep Better")
        case .relaxation: return String(localized: "Relax")
        case .focus: return String(localized: "Focus")
        case .meditation: return String(localized: "Meditate")
        default: return goal.localizedTitle
        }
    }

    private var goalSubtitle: String {
        switch goal {
        case .fallAsleep: return String(localized: "Fall asleep faster & sleep deeper")
        case .relaxation: return String(localized: "Unwind and relieve stress")
        case .focus: return String(localized: "Boost concentration & productivity")
        case .meditation: return String(localized: "Practice mindfulness & calm")
        default: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goalLabel)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(goalSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    OnboardingQuizGoalView(
        onContinue: {},
        onBack: {}
    )
    .environment(OnboardingService())
}
