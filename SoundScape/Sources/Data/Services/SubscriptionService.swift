import Foundation
import StoreKit

/// Subscription status representing the current state of user's subscription
enum SubscriptionStatus: String, Codable {
    case active
    case expired
    case none
}

/// Error types for subscription operations
enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed(underlying: Error)
    case verificationFailed
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription products could not be found. Please try again later."
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Could not verify your purchase. Please contact support."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

/// Native StoreKit 2 subscription service for in-app purchases
@Observable
@MainActor
final class SubscriptionService {

    // MARK: - Product Identifiers

    static let monthlyProductID = "com.StudioNext.SoundScape.monthly"
    static let yearlyProductID = "com.StudioNext.SoundScape.yearly"

    private static let productIDs: Set<String> = [monthlyProductID, yearlyProductID]

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let subscriptionStatus = "subscription_status"
        static let subscriptionExpirationDate = "subscription_expiration_date"
        static let activeProductID = "active_product_id"
    }

    // MARK: - Published Properties

    private(set) var products: [Product] = []
    private(set) var subscriptionStatus: SubscriptionStatus = .none
    private(set) var isPremium: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var error: SubscriptionError?
    private(set) var activeProductID: String?
    private(set) var expirationDate: Date?

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Never>?
    private let userDefaults: UserDefaults

    // MARK: - Computed Properties

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadCachedStatus()
        startTransactionListener()

        Task {
            await fetchProducts()
            await checkCurrentEntitlements()
        }
    }

    /// Cancels the transaction listener task
    func cancelListener() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
    }

    // MARK: - Product Fetching

    /// Fetches available subscription products from App Store
    func fetchProducts() async {
        isLoading = true
        error = nil

        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            // Sort products: yearly first (usually better value), then monthly
            products = storeProducts.sorted { first, second in
                if first.id == Self.yearlyProductID { return true }
                if second.id == Self.yearlyProductID { return false }
                return first.price < second.price
            }
            isLoading = false
        } catch {
            self.error = .purchaseFailed(underlying: error)
            isLoading = false
        }
    }

    // MARK: - Purchase Flow

    /// Purchases a subscription product
    /// - Parameter product: The Product to purchase
    /// - Returns: True if purchase was successful
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus(from: transaction)
                await transaction.finish()
                isLoading = false
                return true

            case .pending:
                error = .pending
                isLoading = false
                return false

            case .userCancelled:
                error = .userCancelled
                isLoading = false
                return false

            @unknown default:
                error = .unknown
                isLoading = false
                return false
            }
        } catch _ as VerificationError {
            error = .verificationFailed
            isLoading = false
            return false
        } catch {
            self.error = .purchaseFailed(underlying: error)
            isLoading = false
            return false
        }
    }

    /// Purchases the monthly subscription
    @discardableResult
    func purchaseMonthly() async -> Bool {
        guard let product = monthlyProduct else {
            error = .productNotFound
            return false
        }
        return await purchase(product)
    }

    /// Purchases the yearly subscription
    @discardableResult
    func purchaseYearly() async -> Bool {
        guard let product = yearlyProduct else {
            error = .productNotFound
            return false
        }
        return await purchase(product)
    }

    // MARK: - Restore Purchases

    /// Restores previously purchased subscriptions
    func restorePurchases() async {
        isLoading = true
        error = nil

        // Sync with App Store
        do {
            try await AppStore.sync()
        } catch {
            // Continue even if sync fails - we'll check current entitlements
        }

        await checkCurrentEntitlements()
        isLoading = false
    }

    // MARK: - Entitlement Checking

    /// Checks current subscription entitlements
    func checkCurrentEntitlements() async {
        var hasActiveSubscription = false
        var foundProductID: String?
        var foundExpirationDate: Date?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is one of our subscription products
                if Self.productIDs.contains(transaction.productID) {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        hasActiveSubscription = true
                        foundProductID = transaction.productID
                        foundExpirationDate = expirationDate
                    }
                }
            } catch {
                // Skip unverified transactions
                continue
            }
        }

        if hasActiveSubscription {
            subscriptionStatus = .active
            isPremium = true
            activeProductID = foundProductID
            expirationDate = foundExpirationDate
        } else {
            subscriptionStatus = .none
            isPremium = false
            activeProductID = nil
            expirationDate = nil
        }

        cacheStatus()
    }

    // MARK: - Transaction Listener

    /// Starts listening for transaction updates
    private func startTransactionListener() {
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                // Verify the transaction
                guard case .verified(let transaction) = result else {
                    continue
                }

                await self.handleTransactionUpdate(transaction)
                await transaction.finish()
            }
        }
    }

    /// Handles a transaction update
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        await checkCurrentEntitlements()
    }

    // MARK: - Verification

    /// Verifies a transaction result (nonisolated for use in any context)
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let item):
            return item
        }
    }

    // MARK: - Persistence

    /// Loads cached subscription status for quick access at launch
    private func loadCachedStatus() {
        if let statusString = userDefaults.string(forKey: UserDefaultsKey.subscriptionStatus),
           let status = SubscriptionStatus(rawValue: statusString) {
            subscriptionStatus = status
            isPremium = (status == .active)
        }

        activeProductID = userDefaults.string(forKey: UserDefaultsKey.activeProductID)

        if let expirationTimeInterval = userDefaults.object(forKey: UserDefaultsKey.subscriptionExpirationDate) as? TimeInterval {
            let date = Date(timeIntervalSince1970: expirationTimeInterval)
            expirationDate = date

            // Check if cached subscription has expired
            if date <= Date() && subscriptionStatus == .active {
                subscriptionStatus = .expired
                isPremium = false
            }
        }
    }

    /// Caches current subscription status for quick access
    private func cacheStatus() {
        userDefaults.set(subscriptionStatus.rawValue, forKey: UserDefaultsKey.subscriptionStatus)
        userDefaults.set(activeProductID, forKey: UserDefaultsKey.activeProductID)

        if let expirationDate = expirationDate {
            userDefaults.set(expirationDate.timeIntervalSince1970, forKey: UserDefaultsKey.subscriptionExpirationDate)
        } else {
            userDefaults.removeObject(forKey: UserDefaultsKey.subscriptionExpirationDate)
        }
    }

    // MARK: - Error Handling

    /// Clears the current error
    func clearError() {
        error = nil
    }

    /// Updates subscription status from a transaction
    private func updateSubscriptionStatus(from transaction: Transaction) async {
        if Self.productIDs.contains(transaction.productID) {
            if let expirationDate = transaction.expirationDate,
               expirationDate > Date() {
                subscriptionStatus = .active
                isPremium = true
                activeProductID = transaction.productID
                self.expirationDate = expirationDate
            } else {
                subscriptionStatus = .expired
                isPremium = false
                activeProductID = nil
                self.expirationDate = nil
            }
            cacheStatus()
        }
    }
}

// MARK: - VerificationError

/// Custom error type for verification failures
private enum VerificationError: Error {
    case unverified
}
