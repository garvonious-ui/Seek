import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var showDeleteConfirmation = false

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

                // Stats
                Section("Stats") {
                    Label("\(profile?.streakCount ?? 0)-day streak", systemImage: "flame.fill")
                        .foregroundStyle(.primary)
                    Label("\(profile?.totalVersesExplored ?? 0) verses explored", systemImage: "book.closed")
                    Label("\(profile?.totalCardsCreated ?? 0) cards created", systemImage: "rectangle.on.rectangle")
                    if let longest = profile?.longestStreak, longest > 0 {
                        Label("Longest streak: \(longest) days", systemImage: "trophy")
                    }
                }

                // Settings
                Section("Settings") {
                    Label("Notifications", systemImage: "bell")
                    Label("Subscription", systemImage: "star")
                    Label("Rate Seek", systemImage: "heart")
                    ShareLink(item: URL(string: "https://apps.apple.com/app/seek")!) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }
                }

                // Legal
                Section {
                    Label("Privacy Policy", systemImage: "lock.shield")
                    Label("Terms of Service", systemImage: "doc.text")
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
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
        .modelContainer(for: UserProfile.self)
}
