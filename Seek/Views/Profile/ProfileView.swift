import SwiftUI
import SwiftData
import StoreKit

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var showDeleteConfirmation = false
    @State private var showPremiumUpgrade = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "2C5F7C"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile?.displayName.isEmpty == false ? profile!.displayName : "Seeker")
                                .font(.headline)
                            Text(profile?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let date = profile?.createdAt {
                                Text("Member since \(date.formatted(.dateTime.month(.wide).year()))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Premium badge
                if profile?.isPremium == true {
                    Section {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(Color(hex: "D4A853"))
                            Text("Seek+ Member")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }

                // Stats
                Section("Stats") {
                    HStack {
                        Label("\(profile?.streakCount ?? 0)-day streak", systemImage: "flame.fill")
                        Spacer()
                        if let longest = profile?.longestStreak, longest > 0 {
                            Text("Best: \(longest)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Label("\(profile?.totalVersesExplored ?? 0) verses explored", systemImage: "book.closed")
                    Label("\(profile?.totalCardsCreated ?? 0) cards created", systemImage: "rectangle.on.rectangle")
                }

                // Settings
                Section("Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }

                    if profile?.isPremium != true {
                        Button {
                            showPremiumUpgrade = true
                        } label: {
                            HStack {
                                Label("Upgrade to Seek+", systemImage: "star")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(Color(hex: "D4A853"))
                        }
                    } else {
                        NavigationLink {
                            SubscriptionManagementView()
                        } label: {
                            Label("Manage Subscription", systemImage: "star")
                        }
                    }

                    Button {
                        requestReview()
                    } label: {
                        Label("Rate Seek", systemImage: "heart")
                            .foregroundStyle(.primary)
                    }

                    ShareLink(item: URL(string: "https://apps.apple.com/app/seek")!) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }
                }

                // Legal
                Section {
                    NavigationLink {
                        WebContentView(title: "Privacy Policy", urlString: "https://seek-app.com/privacy")
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        WebContentView(title: "Terms of Service", urlString: "https://seek-app.com/terms")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Account actions
                Section {
                    Button {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .foregroundStyle(.red)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await authManager.deleteAccount(modelContext: modelContext)
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
            .sheet(isPresented: $showPremiumUpgrade) {
                PremiumUpgradeView()
            }
        }
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
        .modelContainer(for: UserProfile.self)
}
