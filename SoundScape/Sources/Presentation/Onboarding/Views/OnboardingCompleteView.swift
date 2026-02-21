import SwiftUI

struct OnboardingCompleteView: View {
    let onExplore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark icon
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

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 40)

            // Headline
            Text(String(localized: "This is your soundscape"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 12)

            // Subheadline
            Text(String(localized: "Adjust volumes, explore more sounds, or save this mix for later."))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)

            Spacer()

            // Explore button
            OnboardingButton(
                title: String(localized: "Start Exploring"),
                action: onExplore
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

#Preview {
    OnboardingCompleteView(onExplore: {})
}
