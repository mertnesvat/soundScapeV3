import SwiftUI

struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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
            Text(String(localized: "Better Sleep\nStarts Tonight"))
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 16)

            // Subheadline
            Text(String(localized: "Personalize your soundscape\nin just a few taps"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 48)

            Spacer()

            // Single CTA Button
            OnboardingButton(title: String(localized: "Get Started"), action: onGetStarted)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

#Preview {
    OnboardingWelcomeView(onGetStarted: {})
}
