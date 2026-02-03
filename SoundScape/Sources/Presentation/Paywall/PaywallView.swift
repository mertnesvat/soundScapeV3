import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PaywallService.self) private var paywallService

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false

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
                    Button(action: { dismiss() }) {
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
                            Text("Unlock Premium")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Experience the full power of SoundScape")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }

                        // Feature list
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(features, id: \.0) { icon, feature in
                                HStack(spacing: 12) {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.purple)
                                        .frame(width: 24)

                                    Text(feature)
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.vertical, 16)

                        // Product options
                        VStack(spacing: 12) {
                            if paywallService.products.isEmpty {
                                // Loading state
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.purple)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(paywallService.products, id: \.id) { product in
                                    ProductOptionView(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        isYearly: product.id.contains("yearly")
                                    ) {
                                        selectedProduct = product
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Error message
                        if let error = paywallService.purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Purchase button
                        Button {
                            Task {
                                await handlePurchase()
                            }
                        } label: {
                            HStack {
                                if paywallService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text(purchaseButtonTitle)
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
                        .disabled(selectedProduct == nil || paywallService.isLoading)
                        .opacity(selectedProduct == nil ? 0.6 : 1.0)

                        // Restore purchases
                        Button {
                            Task {
                                await paywallService.restorePurchases()
                                if paywallService.isPremium {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .disabled(paywallService.isLoading)
                        .padding(.top, 4)

                        // Legal section
                        VStack(spacing: 12) {
                            Text("Cancel anytime. Subscription auto-renews.")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("|")
                                    .foregroundColor(.gray.opacity(0.5))

                                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            // Pre-select yearly if available, otherwise monthly
            if selectedProduct == nil {
                selectedProduct = paywallService.yearlyProduct ?? paywallService.monthlyProduct
            }
        }
    }

    private var purchaseButtonTitle: String {
        guard let product = selectedProduct else {
            return "Select a Plan"
        }

        if product.id.contains("yearly") {
            return "Start Free Trial"
        } else {
            return "Subscribe Now"
        }
    }

    private func handlePurchase() async {
        guard let product = selectedProduct else { return }

        let success = await paywallService.purchase(product)
        if success {
            dismiss()
        }
    }
}

// MARK: - Product Option View

private struct ProductOptionView: View {
    let product: Product
    let isSelected: Bool
    let isYearly: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        if isYearly {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                    }

                    Text(subscriptionDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(pricePeriod)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ?
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var subscriptionDescription: String {
        if isYearly {
            return "7-day free trial, then billed annually"
        } else {
            return "Billed monthly"
        }
    }

    private var pricePeriod: String {
        isYearly ? "/year" : "/month"
    }
}

#Preview {
    PaywallView()
        .environment(PaywallService())
}
