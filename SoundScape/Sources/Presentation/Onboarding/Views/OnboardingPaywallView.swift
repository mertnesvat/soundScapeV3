import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService

    let onComplete: () -> Void
    let showCloseButton: Bool

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(onComplete: @escaping () -> Void, showCloseButton: Bool = true) {
        self.onComplete = onComplete
        self.showCloseButton = showCloseButton
    }

    private enum SubscriptionPlan {
        case monthly
        case yearly
    }

    private let features = [
        "Unlimited access to all 27+ sounds",
        "Custom sound mixing",
        "Sleep timer with gentle fade",
        "Binaural beats & brainwave audio",
        "Sleep insights & analytics",
        "Ad-free experience"
    ]

    private var subscriptionService: SubscriptionService? {
        paywallService.subscriptionService
    }

    private var monthlyProduct: Product? {
        subscriptionService?.monthlyProduct
    }

    private var yearlyProduct: Product? {
        subscriptionService?.yearlyProduct
    }

    private var productsLoaded: Bool {
        monthlyProduct != nil && yearlyProduct != nil
    }

    private var isLoading: Bool {
        subscriptionService?.isLoading ?? false || isPurchasing
    }

    private var yearlySavingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let monthlyAnnualCost = monthly.price * 12
        let savings = monthlyAnnualCost - yearly.price
        let percentage = (savings / monthlyAnnualCost) * 100
        return NSDecimalNumber(decimal: percentage).intValue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            if showCloseButton {
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
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

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
                    .padding(.top, showCloseButton ? 16 : 40)

                    // Headline
                    VStack(spacing: 8) {
                        Text("Unlock Premium")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Choose Your Plan")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)

                                Text(feature)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)

                    // Subscription options
                    if productsLoaded {
                        subscriptionOptionsView
                    } else if subscriptionService?.error != nil {
                        productLoadErrorView
                    } else {
                        loadingProductsView
                    }

                    // Purchase button
                    purchaseButton

                    // Restore purchases
                    Button(action: handleRestorePurchases) {
                        HStack(spacing: 6) {
                            if subscriptionService?.isLoading == true && !isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.7)
                                    .tint(.gray)
                            }
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.top, 4)

                    // Limited access button
                    if showCloseButton {
                        Button(action: handleLimitedAccess) {
                            Text("Continue with Limited Access")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .disabled(isLoading)
                        .padding(.top, 4)
                    }

                    // Terms and auto-renewal disclosure
                    termsAndDisclosureView
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.black)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                subscriptionService?.clearError()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadProductsIfNeeded()
        }
    }

    // MARK: - Subscription Options

    @ViewBuilder
    private var subscriptionOptionsView: some View {
        VStack(spacing: 12) {
            // Yearly option (Best Value)
            if let yearly = yearlyProduct {
                SubscriptionOptionCard(
                    isSelected: selectedPlan == .yearly,
                    title: "Yearly",
                    price: yearly.displayPrice,
                    period: "/year",
                    badge: yearlySavingsPercentage > 0 ? "Save \(yearlySavingsPercentage)%" : nil,
                    monthlyEquivalent: yearlyMonthlyEquivalent(yearly),
                    isDisabled: isLoading
                ) {
                    selectedPlan = .yearly
                }
            }

            // Monthly option
            if let monthly = monthlyProduct {
                SubscriptionOptionCard(
                    isSelected: selectedPlan == .monthly,
                    title: "Monthly",
                    price: monthly.displayPrice,
                    period: "/month",
                    badge: nil,
                    monthlyEquivalent: nil,
                    isDisabled: isLoading
                ) {
                    selectedPlan = .monthly
                }
            }
        }
    }

    private func yearlyMonthlyEquivalent(_ yearly: Product) -> String {
        let monthlyPrice = yearly.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.priceFormatStyle.locale
        return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? ""
    }

    @ViewBuilder
    private var loadingProductsView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.purple)
            Text("Loading subscription options...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 150)
    }

    @ViewBuilder
    private var productLoadErrorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Unable to load subscription options")
                .font(.subheadline)
                .foregroundColor(.white)
            Button("Retry") {
                loadProductsIfNeeded()
            }
            .font(.subheadline)
            .foregroundColor(.purple)
        }
        .frame(height: 150)
    }

    // MARK: - Purchase Button

    @ViewBuilder
    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(purchaseButtonTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: isLoading || !productsLoaded ? [.gray] : [.purple, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(isLoading || !productsLoaded)
    }

    private var purchaseButtonTitle: String {
        switch selectedPlan {
        case .yearly:
            if let yearly = yearlyProduct {
                return "Subscribe for \(yearly.displayPrice)/year"
            }
        case .monthly:
            if let monthly = monthlyProduct {
                return "Subscribe for \(monthly.displayPrice)/month"
            }
        }
        return "Subscribe"
    }

    // MARK: - Terms and Disclosure

    @ViewBuilder
    private var termsAndDisclosureView: some View {
        VStack(spacing: 8) {
            // Auto-renewal disclosure (Apple requirement)
            Text(autoRenewalDisclosure)
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            HStack(spacing: 4) {
                Link("Terms of Use", destination: URL(string: "http://studionext.co.uk/soundscape-terms.html")!)
                Text("and")
                    .foregroundColor(.gray.opacity(0.7))
                Link("Privacy Policy", destination: URL(string: "https://studionext.co.uk/soundscape-privacy.html")!)
            }
            .font(.caption)
            .tint(.gray)
        }
        .padding(.top, 16)
        .padding(.bottom, 32)
    }

    private var autoRenewalDisclosure: String {
        switch selectedPlan {
        case .yearly:
            if let yearly = yearlyProduct {
                return "Subscription automatically renews at \(yearly.displayPrice)/year unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings."
            }
        case .monthly:
            if let monthly = monthlyProduct {
                return "Subscription automatically renews at \(monthly.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings."
            }
        }
        return "Cancel anytime. No commitment required."
    }

    // MARK: - Actions

    private func loadProductsIfNeeded() {
        guard !productsLoaded else { return }
        Task {
            await subscriptionService?.fetchProducts()
        }
    }

    private func handlePurchase() {
        guard !isPurchasing else { return }
        isPurchasing = true

        Task {
            let success: Bool
            switch selectedPlan {
            case .yearly:
                success = await paywallService.purchaseYearly()
            case .monthly:
                success = await paywallService.purchaseMonthly()
            }

            isPurchasing = false

            if success {
                onComplete()
            } else if let error = subscriptionService?.error {
                // Don't show error for user cancellation
                if case .userCancelled = error {
                    subscriptionService?.clearError()
                } else if case .pending = error {
                    errorMessage = error.errorDescription ?? "Purchase is pending"
                    showError = true
                } else {
                    errorMessage = error.errorDescription ?? "An error occurred"
                    showError = true
                }
            }
        }
    }

    private func handleRestorePurchases() {
        Task {
            await paywallService.restorePurchases()
            if paywallService.isPremium {
                onComplete()
            }
        }
    }

    private func handleLimitedAccess() {
        onComplete()
    }
}

// MARK: - Subscription Option Card

private struct SubscriptionOptionCard: View {
    let isSelected: Bool
    let title: String
    let price: String
    let period: String
    let badge: String?
    let monthlyEquivalent: String?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.purple : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    if let monthlyEquivalent = monthlyEquivalent {
                        Text("\(monthlyEquivalent)/month")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Price
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

#Preview {
    OnboardingPaywallView(onComplete: {})
        .environment(OnboardingService())
        .environment(PaywallService())
}
