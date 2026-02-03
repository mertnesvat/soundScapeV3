import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService
    let onComplete: () -> Void

    @State private var selectedProduct: Product?

    private let features = [
        ("infinity", "Unlimited access to all 27+ sounds"),
        ("slider.horizontal.3", "Custom sound mixing"),
        ("moon.zzz.fill", "Sleep timer with gentle fade"),
        ("waveform.path.ecg", "Binaural beats & brainwave audio"),
        ("chart.bar.fill", "Sleep insights & analytics"),
        ("sparkles", "Ad-free experience")
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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

                ScrollView(showsIndicators: false) {
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
                                .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)

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

                            Text("7 days free, then \(yearlyPricePerMonth)")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }

                        // Feature list
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(features, id: \.0) { icon, feature in
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
                        Button {
                            Task {
                                await handleStartTrial()
                            }
                        } label: {
                            HStack {
                                if paywallService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Start Free Trial")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(paywallService.isLoading)

                        // Error message
                        if let error = paywallService.purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Limited access button
                        Button(action: handleLimitedAccess) {
                            Text("Continue with Limited Access")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)

                        // Terms
                        VStack(spacing: 8) {
                            Text("Cancel anytime. No commitment required.")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))

                            HStack(spacing: 4) {
                                Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                                Text("and")
                                    .foregroundColor(.gray.opacity(0.7))
                                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            }
                            .font(.caption)
                            .tint(.gray)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            selectedProduct = paywallService.yearlyProduct
        }
    }

    private var yearlyPricePerMonth: String {
        if let yearly = paywallService.yearlyProduct {
            let monthlyPrice = yearly.price / 12
            return "\(yearly.priceFormatStyle.format(monthlyPrice))/month"
        }
        return "$4.99/month"
    }

    private func handleStartTrial() async {
        guard let product = paywallService.yearlyProduct ?? paywallService.monthlyProduct else {
            // If no products available, complete onboarding anyway
            handleLimitedAccess()
            return
        }

        let success = await paywallService.purchase(product)
        if success {
            onboardingService.completeOnboarding()
            onComplete()
        }
    }

    private func handleLimitedAccess() {
        onboardingService.completeOnboarding()
        onComplete()
    }
}

#Preview {
    OnboardingPaywallView(onComplete: {})
        .environment(OnboardingService())
        .environment(PaywallService())
}
