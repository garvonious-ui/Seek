import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @State private var storeManager = StoreManager.shared

    var body: some View {
        List {
            Section("Current Plan") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seek+ Premium")
                            .font(.headline)
                        Text("Active subscription")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "D4A853"))
                }
            }

            Section("Benefits") {
                Label("50 scripture chats per day", systemImage: "message.fill")
                Label("Ad-free experience", systemImage: "nosign")
                Label("Premium card templates", systemImage: "paintpalette.fill")
            }

            Section {
                Button("Manage in App Store") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Restore Purchases") {
                    Task { await storeManager.restorePurchases() }
                }
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SubscriptionManagementView()
    }
}
