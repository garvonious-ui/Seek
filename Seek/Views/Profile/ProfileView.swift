import SwiftUI
import SwiftData
import StoreKit

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var showDeleteConfirmation = false
    @State private var showSignIn = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        if authManager.isGuest {
            guestProfile
        } else {
            authenticatedProfile
        }
    }

    // MARK: - Guest Profile
    //
    // Shown when the user is browsing without signing in. Single sign-in CTA
    // plus the same legal links as the full profile so guests still have a
    // path to read Privacy / Terms.

    private var guestProfile: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: "5B7B5E").opacity(0.6))
                Text("You're browsing as a guest")
                    .font(.title3.bold())
                    .foregroundStyle(Color(hex: "1A1A1A"))
                Text("Sign in to chat with scripture, save your favorites, and track your daily streak.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button {
                    showSignIn = true
                } label: {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "5B7B5E"))
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink {
                        WebContentView(title: "Privacy Policy", urlString: "https://askseekpray.app/privacy")
                    } label: {
                        Text("Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                    NavigationLink {
                        WebContentView(title: "Terms of Service", urlString: "https://askseekpray.app/terms")
                    } label: {
                        Text("Terms of Service")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSignIn) {
                GuestSignInSheet(isPresented: $showSignIn)
            }
        }
    }

    // MARK: - Authenticated Profile

    private var authenticatedProfile: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "5B7B5E"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile?.displayName.isEmpty == false ? profile!.displayName : "Seeker")
                                .font(.headline)
                            Text(profile?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "6B7280"))
                            if let date = profile?.createdAt {
                                Text("Member since \(date.formatted(.dateTime.month(.wide).year()))")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats
                Section("Stats") {
                    HStack {
                        Label("\(profile?.streakCount ?? 0)-day streak", systemImage: "flame.fill")
                        Spacer()
                        if let longest = profile?.longestStreak, longest > 0 {
                            Text("Best: \(longest)")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    Label("\(profile?.totalVersesExplored ?? 0) verses explored", systemImage: "book.closed")
                    Label("\(profile?.totalCardsCreated ?? 0) cards created", systemImage: "rectangle.on.rectangle")
                }

                // Settings
                Section("Settings") {
                    NavigationLink {
                        TranslationPickerView()
                    } label: {
                        HStack {
                            Label("Bible Translation", systemImage: "book")
                            Spacer()
                            Text(BibleTranslation(rawValue: profile?.preferredTranslation ?? "NLT")?.rawValue ?? "NLT")
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }

                    Button {
                        requestReview()
                    } label: {
                        Label("Rate Seek", systemImage: "star")
                            .foregroundStyle(Color(hex: "1A1A1A"))
                    }

                    ShareLink(
                        item: URL(string: "https://apps.apple.com/us/app/seek-scripture-companion/id6761785270")!,
                        message: Text("I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.")
                    ) {
                        Label("Share Seek", systemImage: "square.and.arrow.up")
                    }
                }

                // Legal
                Section {
                    NavigationLink {
                        WebContentView(title: "Privacy Policy", urlString: "https://askseekpray.app/privacy")
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        WebContentView(title: "Terms of Service", urlString: "https://askseekpray.app/terms")
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
        }
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
        }
    }
}

// MARK: - Translation Picker

struct TranslationPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTranslation: String = "NLT"

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            ForEach(BibleTranslation.allCases) { translation in
                Button {
                    selectedTranslation = translation.rawValue
                    if let profile {
                        profile.preferredTranslation = translation.rawValue
                        try? modelContext.save()
                        Task {
                            try? await SupabaseService.shared.updatePreferredTranslation(userId: profile.id, translation: translation.rawValue)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(translation.displayName)
                                .foregroundStyle(Color(hex: "1A1A1A"))
                            Text(translation.rawValue)
                                .font(.caption)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                        Spacer()
                        if selectedTranslation == translation.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: "5B7B5E"))
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Bible Translation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedTranslation = profile?.preferredTranslation ?? "NLT"
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
        .modelContainer(for: UserProfile.self)
}
