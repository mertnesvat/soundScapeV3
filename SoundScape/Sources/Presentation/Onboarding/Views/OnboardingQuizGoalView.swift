import SwiftUI

struct OnboardingQuizGoalView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @State private var selectedGoal: OnboardingSleepGoal?
    let onContinue: () -> Void
    let onBack: () -> Void

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
            Text("What's your main\nsleep goal?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 32)
                .padding(.bottom, 32)

            // Options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(OnboardingSleepGoal.allCases, id: \.self) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = goal
                                onboardingService.setSleepGoal(goal)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(selectedGoal != nil ? 1 : 0.5)
                .disabled(selectedGoal == nil)
        }
        .background(Color.black)
        .onAppear {
            selectedGoal = onboardingService.profile.sleepGoal
        }
    }
}

struct GoalOptionCard: View {
    let goal: OnboardingSleepGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .purple)

                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.08))
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
