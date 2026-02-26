import SwiftUI

struct OnboardingCompleteView: View {
    let onComplete: () -> Void

    @State private var showCheckmark = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Celebration checkmark
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showCheckmark ? 1 : 0.3)
                    .opacity(showCheckmark ? 1 : 0)
            }
            .padding(.bottom, 40)

            // Title
            Text(String(localized: "You're All Set!"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .padding(.bottom, 16)

            // Subtitle
            Text(String(localized: "Your soundscape is ready.\nRelax, focus, or drift off to sleep."))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            Spacer()

            // CTA
            OnboardingButton(
                title: String(localized: "Start Exploring"),
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .background(Color.black)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingCompleteView(onComplete: {})
}
