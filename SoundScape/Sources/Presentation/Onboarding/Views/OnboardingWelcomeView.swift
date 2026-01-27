import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Icon/Visual
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

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 48)

            // Headline
            Text("Better Sleep\nStarts Tonight")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 16)

            // Subheadline
            Text("Take 30 seconds to personalize your\nsleep experience")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 48)

            Spacer()

            // CTA Button
            OnboardingButton(title: "Get Started", action: onGetStarted)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

#Preview {
    OnboardingWelcomeView(
        onGetStarted: {},
        onSkip: {}
    )
}
