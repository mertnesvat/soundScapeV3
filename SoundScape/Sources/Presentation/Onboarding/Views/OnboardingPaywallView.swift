import SwiftUI

struct OnboardingPaywallView: View {
    @Environment(OnboardingService.self) private var onboardingService
    let onComplete: () -> Void

    // TODO: Implement actual paywall with StoreKit
    // - Add subscription products
    // - Handle purchase flow
    // - Restore purchases
    // - Track conversion analytics

    private let features = [
        "Unlimited access to all 27+ sounds",
        "Custom sound mixing",
        "Sleep timer with gentle fade",
        "Binaural beats & brainwave audio",
        "Sleep insights & analytics",
        "Ad-free experience"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: handleLimitedAccess) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 24) {
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)

                    // Headline
                    VStack(spacing: 8) {
                        Text("Start Your Free Trial")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("7 days free, then $4.99/month")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)

                                Text(feature)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 8)

                    // Trial button
                    OnboardingButton(title: "Start Free Trial", action: handleStartTrial)

                    // Limited access button
                    Button(action: handleLimitedAccess) {
                        Text("Continue with Limited Access")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 8)

                    // Terms
                    Text("Cancel anytime. No commitment required.")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.black)
    }

    private func handleStartTrial() {
        // TODO: Implement StoreKit purchase flow
        // For now, just complete onboarding
        onboardingService.completeOnboarding()
        onComplete()
    }

    private func handleLimitedAccess() {
        onboardingService.completeOnboarding()
        onComplete()
    }
}

#Preview {
    OnboardingPaywallView(onComplete: {})
        .environment(OnboardingService())
}
