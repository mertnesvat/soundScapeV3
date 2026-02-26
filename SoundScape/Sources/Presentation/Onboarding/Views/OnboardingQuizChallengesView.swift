import SwiftUI

struct OnboardingQuizChallengesView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @State private var selectedChallenges: Set<OnboardingSleepChallenge> = []
    let onContinue: () -> Void
    let onBack: () -> Void

    /// Simplified challenge options (4 most common)
    private let simplifiedChallenges: [OnboardingSleepChallenge] = [
        .racingThoughts,
        .noise,
        .stress,
        .irregularSchedule
    ]

    private let maxSelections = 3

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
            Text(String(localized: "What keeps you up\nat night?"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 32)

            Text(String(localized: "Select up to 3"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 8)
                .padding(.bottom, 32)

            // Options
            VStack(spacing: 12) {
                ForEach(simplifiedChallenges, id: \.self) { challenge in
                    ChallengeOptionRow(
                        challenge: challenge,
                        isSelected: selectedChallenges.contains(challenge),
                        isDisabled: !selectedChallenges.contains(challenge) && selectedChallenges.count >= maxSelections,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedChallenges.contains(challenge) {
                                    selectedChallenges.remove(challenge)
                                    onboardingService.toggleChallenge(challenge)
                                } else if selectedChallenges.count < maxSelections {
                                    selectedChallenges.insert(challenge)
                                    onboardingService.toggleChallenge(challenge)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(title: String(localized: "Continue"), action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(selectedChallenges.isEmpty ? 0.5 : 1)
                .disabled(selectedChallenges.isEmpty)
        }
        .background(Color.black)
        .onAppear {
            // Load only from simplified set
            selectedChallenges = onboardingService.profile.sleepChallenges
                .intersection(Set(simplifiedChallenges))
        }
    }
}

private struct ChallengeOptionRow: View {
    let challenge: OnboardingSleepChallenge
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 24)

                Text(challenge.localizedTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDisabled ? .gray : .white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                } else {
                    Circle()
                        .stroke(isDisabled ? Color.white.opacity(0.1) : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    OnboardingQuizChallengesView(
        onContinue: {},
        onBack: {}
    )
    .environment(OnboardingService())
}
