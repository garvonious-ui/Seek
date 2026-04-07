import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreManager.shared
    @State private var isPurchasing = false
    @State private var selectedPlan: String = StoreManager.yearlyID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "D4A853"))

                        Text("Seek+")
                            .font(.largeTitle.bold())

                        Text("Deepen your daily scripture practice")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "message.fill", title: "50 Daily Chats", subtitle: "10x more scripture conversations")
                        featureRow(icon: "nosign", title: "Ad-Free", subtitle: "Distraction-free experience")
                        featureRow(icon: "paintpalette.fill", title: "Premium Templates", subtitle: "Exclusive verse card designs")
                    }
                    .padding(.horizontal, 24)

                    // Plan selector
                    VStack(spacing: 12) {
                        if let yearly = storeManager.yearlyProduct {
                            planCard(
                                product: yearly,
                                label: "Yearly",
                                badge: "Best Value",
                                isSelected: selectedPlan == StoreManager.yearlyID
                            )
                        }

                        if let monthly = storeManager.monthlyProduct {
                            planCard(
                                product: monthly,
                                label: "Monthly",
                                badge: nil,
                                isSelected: selectedPlan == StoreManager.monthlyID
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Subscribe button
                    Button {
                        Task { await subscribe() }
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Start Free Trial")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "D4A853"))
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    // Fine print
                    VStack(spacing: 8) {
                        Text("7-day free trial, then auto-renews")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Restore Purchases") {
                            Task { await storeManager.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundStyle(Color(hex: "2C5F7C"))
                    }

                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .background(Color(hex: "FAFAF8"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "D4A853"))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Plan Card

    private func planCard(product: Product, label: String, badge: String?, isSelected: Bool) -> some View {
        Button {
            selectedPlan = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.subheadline.weight(.semibold))
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "D4A853"))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.displayPrice + (product.id == StoreManager.yearlyID ? "/year" : "/month"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color(hex: "D4A853") : .secondary)
            }
            .padding()
            .background(isSelected ? Color(hex: "D4A853").opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "D4A853") : .clear, lineWidth: 2)
            )
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Purchase

    private func subscribe() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let product: Product?
        if selectedPlan == StoreManager.yearlyID {
            product = storeManager.yearlyProduct
        } else {
            product = storeManager.monthlyProduct
        }

        guard let product else { return }

        do {
            _ = try await storeManager.purchase(product)
            if storeManager.isPremium {
                dismiss()
            }
        } catch {
            storeManager.errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    PremiumUpgradeView()
}
