import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService

    let onComplete: () -> Void
    let isPresented: Bool

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(onComplete: @escaping () -> Void, isPresented: Bool = false) {
        self.onComplete = onComplete
        self.isPresented = isPresented
    }

    enum SubscriptionPlan {
        case monthly
        case yearly
    }

    private let features = [
        ("moon.stars.fill", "Unlimited access to all 27+ sounds"),
        ("slider.horizontal.3", "Custom sound mixing"),
        ("timer", "Sleep timer with gentle fade"),
        ("waveform.path", "Binaural beats & brainwave audio"),
        ("chart.bar.fill", "Sleep insights & analytics"),
        ("nosign", "Ad-free experience")
    ]

    // MARK: - Computed Properties

    private var yearlyPrice: String {
        subscriptionService.yearlyProduct?.displayPrice ?? "$29.99/year"
    }

    private var monthlyPrice: String {
        subscriptionService.monthlyProduct?.displayPrice ?? "$4.99/month"
    }

    private var yearlySavingsPercentage: Int {
        guard let yearlyProduct = subscriptionService.yearlyProduct,
              let monthlyProduct = subscriptionService.monthlyProduct else {
            return 50 // Default fallback
        }

        let yearlyTotal = yearlyProduct.price as Decimal
        let monthlyAnnualized = (monthlyProduct.price as Decimal) * 12

        guard monthlyAnnualized > 0 else { return 0 }

        let savings = 1 - (yearlyTotal / monthlyAnnualized)
        return Int((savings * 100).doubleValue.rounded())
    }

    private var monthlyEquivalentFromYearly: String {
        guard let yearlyProduct = subscriptionService.yearlyProduct else {
            return "$2.50/month"
        }

        let monthlyEquivalent = (yearlyProduct.price as Decimal) / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyProduct.priceFormatStyle.locale

        if let formatted = formatter.string(from: NSDecimalNumber(decimal: monthlyEquivalent)) {
            return "\(formatted)/month"
        }
        return "$2.50/month"
    }

    private var isLoading: Bool {
        subscriptionService.isLoading || isPurchasing
    }

    private var productsLoaded: Bool {
        !subscriptionService.products.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        // Crown icon
                        crownIcon
                            .padding(.top, 8)

                        // Headline
                        headline

                        // Feature list
                        featureList
                            .padding(.top, 8)

                        // Subscription options
                        if productsLoaded {
                            subscriptionOptions
                                .padding(.top, 8)
                        } else {
                            loadingProductsView
                                .padding(.top, 8)
                        }

                        // Purchase button
                        purchaseButton
                            .padding(.top, 16)

                        // Restore purchases
                        restoreButton
                            .padding(.top, 8)

                        // Limited access button
                        Button(action: handleLimitedAccess) {
                            Text("Continue with Limited Access")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .disabled(isLoading)
                        .padding(.top, 4)

                        // Auto-renewal terms and legal
                        legalSection
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("Try Again") {
                Task {
                    await retryProductFetch()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: subscriptionService.error?.errorDescription) { _, newErrorDescription in
            if let description = newErrorDescription {
                errorMessage = description
                showError = true
                isPurchasing = false
            }
        }
        .onChange(of: subscriptionService.isPremium) { _, isPremium in
            if isPremium {
                handlePurchaseSuccess()
            }
        }
        .task {
            if subscriptionService.products.isEmpty {
                await subscriptionService.fetchProducts()
            }
        }
    }

    // MARK: - View Components

    private var crownIcon: some View {
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
    }

    private var headline: some View {
        VStack(spacing: 8) {
            Text("Unlock Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Sleep better, feel better")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(features, id: \.0) { icon, feature in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            // Yearly option (Best Value)
            SubscriptionOptionCard(
                title: "Yearly",
                price: yearlyPrice,
                subtitle: monthlyEquivalentFromYearly,
                badge: "Save \(yearlySavingsPercentage)%",
                isSelected: selectedPlan == .yearly,
                isDisabled: isLoading
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .yearly
                }
            }

            // Monthly option
            SubscriptionOptionCard(
                title: "Monthly",
                price: monthlyPrice,
                subtitle: "Billed monthly",
                badge: nil,
                isSelected: selectedPlan == .monthly,
                isDisabled: isLoading
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .monthly
                }
            }
        }
    }

    private var loadingProductsView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))

            Text("Loading subscription options...")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button("Retry") {
                Task {
                    await retryProductFetch()
                }
            }
            .font(.subheadline)
            .foregroundColor(.purple)
            .padding(.top, 8)
        }
        .frame(height: 150)
    }

    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(selectedPlan == .yearly ? "Subscribe Yearly" : "Subscribe Monthly")
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
        .disabled(isLoading || !productsLoaded)
        .opacity((!productsLoaded || isLoading) ? 0.6 : 1.0)
    }

    private var restoreButton: some View {
        Button(action: handleRestore) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("Restore Purchases")
                    .font(.subheadline)
            }
            .foregroundColor(.purple)
        }
        .disabled(isLoading)
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text(autoRenewalTerms)
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Link("Terms of Use", destination: URL(string: "http://studionext.co.uk/soundscape-terms.html")!)
                Text("and")
                    .foregroundColor(.gray.opacity(0.7))
                Link("Privacy Policy", destination: URL(string: "https://studionext.co.uk/soundscape-privacy.html")!)
            }
            .font(.caption)
            .tint(.gray)
        }
    }

    private var autoRenewalTerms: String {
        if selectedPlan == .yearly {
            return "Subscription automatically renews yearly at \(yearlyPrice) unless cancelled at least 24 hours before the end of the current period. Manage your subscription in Settings."
        } else {
            return "Subscription automatically renews monthly at \(monthlyPrice) unless cancelled at least 24 hours before the end of the current period. Manage your subscription in Settings."
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }

    // MARK: - Actions

    private func handlePurchase() {
        guard !isPurchasing else { return }
        isPurchasing = true
        subscriptionService.clearError()

        Task {
            let success: Bool
            if selectedPlan == .yearly {
                success = await paywallService.purchaseYearly()
            } else {
                success = await paywallService.purchaseMonthly()
            }

            if !success {
                isPurchasing = false
            }
            // Success is handled by onChange of subscriptionService.isPremium
        }
    }

    private func handlePurchaseSuccess() {
        isPurchasing = false
        if isPresented {
            // When presented as sheet (from Settings), just call onComplete
            onComplete()
        } else {
            // When in onboarding flow, complete onboarding
            onboardingService.completeOnboarding()
            onComplete()
        }
    }

    private func handleRestore() {
        guard !isPurchasing else { return }
        isPurchasing = true
        subscriptionService.clearError()

        Task {
            await paywallService.restorePurchases()
            isPurchasing = false

            // If restore resulted in premium, handle success
            if subscriptionService.isPremium {
                handlePurchaseSuccess()
            }
        }
    }

    private func handleLimitedAccess() {
        paywallService.handlePaywallDismissed()
        if isPresented {
            // When presented as sheet, just dismiss
            onComplete()
        } else {
            // When in onboarding flow, complete onboarding
            onboardingService.completeOnboarding()
            onComplete()
        }
    }

    private func retryProductFetch() async {
        subscriptionService.clearError()
        await subscriptionService.fetchProducts()
    }
}

// MARK: - Subscription Option Card

private struct SubscriptionOptionCard: View {
    let title: String
    let price: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Decimal Extension

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

#Preview {
    OnboardingPaywallView(onComplete: {})
        .environment(OnboardingService())
        .environment(PaywallService())
        .environment(SubscriptionService())
}
