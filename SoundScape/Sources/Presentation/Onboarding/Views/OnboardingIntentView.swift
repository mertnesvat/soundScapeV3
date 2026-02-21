import SwiftUI

struct OnboardingIntentView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @State private var selectedIntent: UserIntent?
    let onContinue: (UserIntent) -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button(String(localized: "Skip")) {
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 32)

            // Question
            Text(String(localized: "What brings you here?"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 32)

            // Intent options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(UserIntent.allCases, id: \.self) { intent in
                    IntentOptionCard(
                        intent: intent,
                        isSelected: selectedIntent == intent,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedIntent = intent
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(
                title: String(localized: "Continue"),
                action: {
                    guard let intent = selectedIntent else { return }
                    onboardingService.setUserIntent(intent)
                    onContinue(intent)
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(selectedIntent != nil ? 1 : 0.5)
            .disabled(selectedIntent == nil)
        }
        .background(Color.black)
    }
}

struct IntentOptionCard: View {
    let intent: UserIntent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: intent.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .purple)

                Text(intent.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
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
    OnboardingIntentView(
        onContinue: { _ in },
        onSkip: {}
    )
    .environment(OnboardingService())
}
