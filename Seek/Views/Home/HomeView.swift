import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var favoriteVerses: [FavoriteVerse]
    @State private var dailyVerse: DailyVerse?
    @State private var isLoadingVerse = false
    @State private var isShowingCachedVerse = false
    @State private var showProfile = false
    @State private var customPrompt: String = ""
    @State private var chatTarget: ChatTarget?
    @State private var showSignIn = false
    @FocusState private var isCustomPromptFocused: Bool

    /// Hashable wrapper so we can drive navigationDestination(item:) with a typed value.
    struct ChatTarget: Hashable {
        let message: String
    }

    private var profile: UserProfile? { profiles.first }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = profile?.displayName.isEmpty == false ? ", \(profile!.displayName)" : ""
        switch hour {
        case 5..<12: return "Good morning\(name)"
        case 12..<17: return "Good afternoon\(name)"
        case 17..<21: return "Good evening\(name)"
        default: return "Peace be with you\(name)"
        }
    }

    private let quickPrompts = [
        ("Fear", "bolt.shield.fill"),
        ("Anger", "flame.fill"),
        ("Loneliness", "person.fill.questionmark"),
        ("Gratitude", "heart.fill"),
        ("Temptation", "eye.slash.fill"),
        ("Doubt", "questionmark.circle.fill"),
        ("Joy", "sun.max.fill"),
        ("Weariness", "moon.zzz.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("Wordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                        .padding(.horizontal)
                        .accessibilityLabel("Seek")

                    // Greeting + streak
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title2.bold())
                                .foregroundStyle(Color(hex: "1A1A1A"))
                            Text("What's on your heart?")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            // Streak only shown for signed-in users — guests
                            // don't have a profile to track activity against.
                            if !authManager.isGuest {
                                Label("\(profile?.streakCount ?? 0)", systemImage: "flame.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: "CDA349"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "CDA349").opacity(0.12), in: Capsule())
                            }

                            if !networkMonitor.isConnected {
                                Label("Offline", systemImage: "wifi.slash")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color(hex: "6B7280"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "F3F4F6"), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Daily Verse Card
                    dailyVerseCard

                    // Share with a friend
                    shareWithFriend

                    // Quick Prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Seek scripture for...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                        ], spacing: 10) {
                            ForEach(quickPrompts, id: \.0) { prompt, icon in
                                Button {
                                    if authManager.isGuest {
                                        showSignIn = true
                                    } else {
                                        chatTarget = ChatTarget(message: "I'm dealing with \(prompt.lowercased())")
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color(hex: "5B7B5E"))
                                        Text(prompt)
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: "1A1A1A"))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)

                        // Free-text input — opens a new chat with whatever the user types.
                        HStack(spacing: 10) {
                            TextField("What's on your heart?", text: $customPrompt, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(1...3)
                                .submitLabel(.send)
                                .focused($isCustomPromptFocused)
                                .onSubmit(submitCustomPrompt)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                            Button(action: submitCustomPrompt) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(
                                        customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? Color(hex: "9CA3AF")
                                            : Color(hex: "5B7B5E")
                                    )
                            }
                            .disabled(customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "5B7B5E"))
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showSignIn) {
                GuestSignInSheet(isPresented: $showSignIn)
            }
            .navigationDestination(item: $chatTarget) { target in
                ChatView(initialMessage: target.message)
            }
            .refreshable {
                await loadDailyVerse()
            }
            .task {
                await loadDailyVerse()
                // Streak only meaningful for signed-in users.
                if !authManager.isGuest {
                    StreakManager.recordActivity(modelContext: modelContext)
                }
            }
            // Re-fetch as soon as we come back online so the user doesn't have
            // to manually pull-to-refresh after regaining signal.
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                guard isConnected, isShowingCachedVerse else { return }
                Task {
                    await loadDailyVerse()
                }
            }
        }
    }

    // MARK: - Custom prompt submission

    private func submitCustomPrompt() {
        let trimmed = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Drop focus so the keyboard collapses before navigation pushes ChatView.
        isCustomPromptFocused = false
        // Guests see the sign-in sheet — chat is account-based.
        if authManager.isGuest {
            showSignIn = true
            return
        }
        chatTarget = ChatTarget(message: String(trimmed.prefix(500)))
        customPrompt = ""
    }

    // MARK: - Daily Verse Card

    private var dailyVerseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Verse")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: "CDA349"))
                Spacer()
                if isShowingCachedVerse {
                    Text("Saved copy")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(hex: "6B7280"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "F3F4F6"), in: Capsule())
                }
                if isLoadingVerse {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let verse = dailyVerse {
                Text("\"\(verse.text)\"")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineSpacing(6)

                HStack {
                    Text("— \(verse.reference)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "5B7B5E"))
                    Spacer()
                    Button {
                        toggleFavorite(reference: verse.reference, text: verse.text, source: "daily_verse")
                    } label: {
                        Image(systemName: favoriteVerses.contains { $0.reference == verse.reference } ? "heart.fill" : "heart")
                            .foregroundStyle(Color(hex: "CDA349"))
                    }
                }

                Text(verse.theme.capitalized)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "CDA349").opacity(0.15))
                    .foregroundStyle(Color(hex: "CDA349"))
                    .clipShape(Capsule())
            } else if !isLoadingVerse {
                // No cached verse AND no live fetch — show the evergreen Psalm
                // fallback so the card never renders empty on first offline launch.
                Text("\"God is our refuge and strength, a very present help in trouble.\"")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineSpacing(6)

                HStack {
                    Text("— Psalm 46:1")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "5B7B5E"))
                    Spacer()
                    Button {
                        toggleFavorite(reference: "Psalm 46:1", text: "God is our refuge and strength, a very present help in trouble.", source: "daily_verse")
                    } label: {
                        Image(systemName: favoriteVerses.contains { $0.reference == "Psalm 46:1" } ? "heart.fill" : "heart")
                            .foregroundStyle(Color(hex: "CDA349"))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Share with a friend

    private var shareWithFriend: some View {
        ShareLink(
            item: URL(string: "https://apps.apple.com/us/app/seek-scripture-companion/id6761785270")!,
            message: Text("I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.")
        ) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square")
                Text("Share Seek with a friend")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color(hex: "5B7B5E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "5B7B5E").opacity(0.08), in: Capsule())
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func loadDailyVerse() async {
        // Show the cached verse immediately so the card never renders empty,
        // even while a fresh fetch is in flight. If we're online the fetch
        // below will overwrite it; if we're offline it's all we've got.
        if dailyVerse == nil, let cached = DailyVerseCache.load()?.verse {
            dailyVerse = cached
            isShowingCachedVerse = true
        }

        // Don't burn a network call when we know we're offline — fall through
        // to whatever's already cached and skip straight to the finished state.
        guard networkMonitor.isConnected else { return }

        isLoadingVerse = true
        defer { isLoadingVerse = false }

        do {
            let verse = try await SupabaseService.shared.fetchDailyVerse()
            dailyVerse = verse
            isShowingCachedVerse = false
            DailyVerseCache.save(verse)
        } catch {
            print("Failed to load daily verse: \(error)")
            // Leave the cached verse (if any) in place and fall back to the
            // "Saved copy" badge so the user knows why it's not today's pick.
            if dailyVerse != nil {
                isShowingCachedVerse = true
            }
        }
    }

    private func toggleFavorite(reference: String, text: String, source: String) {
        if let existing = favoriteVerses.first(where: { $0.reference == reference }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteVerse(reference: reference, text: text, source: source))
        }
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environment(AuthManager())
        .environment(NetworkMonitor())
        .modelContainer(for: [UserProfile.self, FavoriteVerse.self])
}
