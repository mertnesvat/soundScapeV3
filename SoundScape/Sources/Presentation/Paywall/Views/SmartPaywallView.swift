import SwiftUI
import StoreKit

struct SmartPaywallView: View {
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum SubscriptionPlan {
        case monthly
        case yearly
    }

    // MARK: - Premium Features

    private let premiumFeatures: [(icon: String, title: String, subtitle: String)] = [
        (
            "moon.stars.fill",
            String(localized: "Unlimited Sound Mixes"),
            String(localized: "Save as many mixes as you want")
        ),
        (
            "waveform.path",
            String(localized: "Binaural Beats"),
            String(localized: "All brainwave states including Gamma")
        ),
        (
            "book.fill",
            String(localized: "Sleep Stories & Wind Down"),
            String(localized: "Full library of stories, yoga nidra & hypnosis")
        ),
        (
            "mic.fill",
            String(localized: "Sleep Recording"),
            String(localized: "Record and analyze your sleep sounds")
        ),
        (
            "chart.bar.fill",
            String(localized: "Advanced Insights"),
            String(localized: "Detailed sleep analytics and trends")
        ),
        (
            "sparkles",
            String(localized: "All Premium Sounds"),
            String(localized: "Access the complete sound library")
        )
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
            return 50
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
                closeButton

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                            .padding(.top, 8)

                        whatYouGetSection
                            .padding(.top, 8)

                        freeTrialCTA
                            .padding(.top, 8)

                        if productsLoaded {
                            subscriptionOptions
                                .padding(.top, 8)
                        } else {
                            loadingProductsView
                                .padding(.top, 8)
                        }

                        purchaseButton
                            .padding(.top, 16)

                        restoreButton
                            .padding(.top, 8)

                        dismissButton
                            .padding(.top, 4)

                        legalSection
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }

            if isLoading {
                loadingOverlay
            }
        }
        .alert(String(localized: "Purchase Error"), isPresented: $showError) {
            Button(String(localized: "Try Again")) {
                Task {
                    await retryProductFetch()
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
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
        .onChange(of: subscriptionService.isPremium) { _, newIsPremium in
            if newIsPremium {
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

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: handleDismiss) {
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

    private var headerSection: some View {
        VStack(spacing: 12) {
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

            Text(String(localized: "Unlock Your Full Sleep Experience"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(String(localized: "You've been enjoying SoundScape — upgrade to unlock everything"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    private var whatYouGetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "What You'll Get"))
                .font(.headline)
                .foregroundColor(.white)

            ForEach(premiumFeatures, id: \.icon) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)

                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var freeTrialCTA: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundColor(.green)

                Text(String(localized: "Try Free for 7 Days"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(String(localized: "Cancel anytime during your trial — no charge"))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            SmartPaywallOptionCard(
                title: String(localized: "Yearly"),
                price: yearlyPrice,
                subtitle: monthlyEquivalentFromYearly,
                badge: String(localized: "Save \(yearlySavingsPercentage)%"),
                isSelected: selectedPlan == .yearly,
                isDisabled: isLoading
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPlan = .yearly
                }
            }

            SmartPaywallOptionCard(
                title: String(localized: "Monthly"),
                price: monthlyPrice,
                subtitle: String(localized: "Billed monthly"),
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

            Text(String(localized: "Loading subscription options..."))
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(String(localized: "Retry")) {
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
                    Text(String(localized: "Start Free Trial"))
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
                Text(String(localized: "Restore Purchases"))
                    .font(.subheadline)
            }
            .foregroundColor(.purple)
        }
        .disabled(isLoading)
    }

    private var dismissButton: some View {
        Button(action: handleDismiss) {
            Text(String(localized: "Not Now"))
                .font(.subheadline)
                .foregroundColor(.gray)
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
                Link(String(localized: "Terms of Use"), destination: URL(string: "http://studionext.co.uk/soundscape-terms.html")!)
                Text(String(localized: "and"))
                    .foregroundColor(.gray.opacity(0.7))
                Link(String(localized: "Privacy Policy"), destination: URL(string: "https://studionext.co.uk/soundscape-privacy.html")!)
            }
            .font(.caption)
            .tint(.gray)
        }
    }

    private var autoRenewalTerms: String {
        if selectedPlan == .yearly {
            return String(localized: "After your free trial, subscription automatically renews yearly at \(yearlyPrice) unless cancelled at least 24 hours before the end of the current period. Manage your subscription in Settings.")
        } else {
            return String(localized: "After your free trial, subscription automatically renews monthly at \(monthlyPrice) unless cancelled at least 24 hours before the end of the current period. Manage your subscription in Settings.")
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

                Text(String(localized: "Processing..."))
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
        }
    }

    private func handlePurchaseSuccess() {
        isPurchasing = false
        paywallService.handlePurchaseSuccess()
    }

    private func handleRestore() {
        guard !isPurchasing else { return }
        isPurchasing = true
        subscriptionService.clearError()

        Task {
            await paywallService.restorePurchases()
            isPurchasing = false

            if subscriptionService.isPremium {
                handlePurchaseSuccess()
            }
        }
    }

    private func handleDismiss() {
        paywallService.handlePaywallDismissed()
    }

    private func retryProductFetch() async {
        subscriptionService.clearError()
        await subscriptionService.fetchProducts()
    }
}

// MARK: - Subscription Option Card

private struct SmartPaywallOptionCard: View {
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
    SmartPaywallView()
        .environment(PaywallService())
        .environment(SubscriptionService())
}
