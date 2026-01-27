import SwiftUI

struct OnboardingResultsView: View {
    @Environment(OnboardingService.self) private var onboardingService
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
            }
            .padding(.bottom, 32)

            // Headline
            Text("We understand\nyour needs")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 24)

            // Goal
            if let goal = onboardingService.profile.sleepGoal {
                HStack(spacing: 12) {
                    Image(systemName: goal.icon)
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("Goal: \(goal.title)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 16)
            }

            // Challenges as tags
            if !onboardingService.profile.sleepChallenges.isEmpty {
                WrappingHStack(alignment: .center, spacing: 8) {
                    ForEach(Array(onboardingService.profile.sleepChallenges), id: \.self) { challenge in
                        Text(challenge.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }

            // Insight text
            Text(insightText)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // CTA Button
            OnboardingButton(title: "See How We Can Help", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color.black)
    }

    private var insightText: String {
        let challenges = onboardingService.profile.sleepChallenges

        if challenges.contains(.racingThoughts) || challenges.contains(.anxiety) {
            return "Racing thoughts and anxiety are common sleep disruptors. Sound therapy can help calm your mind and create a peaceful transition to sleep."
        } else if challenges.contains(.stress) {
            return "Stress affects sleep quality significantly. Our ambient sounds can help you decompress and prepare for restful sleep."
        } else if challenges.contains(.noise) {
            return "External noise can disrupt your sleep patterns. White noise and ambient sounds can mask disturbances effectively."
        } else {
            return "We've analyzed your needs and created a personalized approach to help you achieve better sleep."
        }
    }
}

#Preview {
    OnboardingResultsView(onContinue: {})
        .environment(OnboardingService())
}
