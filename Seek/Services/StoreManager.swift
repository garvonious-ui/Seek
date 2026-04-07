import Foundation
import StoreKit
import SwiftData

@Observable
final class StoreManager {
    static let shared = StoreManager()

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String?

    // Product IDs — configure these in App Store Connect
    static let monthlyID = "com.seek.app.premium.monthly"
    static let yearlyID = "com.seek.app.premium.yearly"

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [
                Self.monthlyID,
                Self.yearlyID
            ])
        } catch {
            errorMessage = "Failed to load products."
            print("StoreKit error: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Update State

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Entitlement verification failed: \(error)")
            }
        }

        await MainActor.run {
            purchasedProductIDs = purchased
        }
    }

    // MARK: - Sync Premium Status to SwiftData

    @MainActor
    func syncPremiumStatus(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.isPremium = isPremium
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
