import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var dailyVerse: DailyVerse?
    @State private var isLoadingVerse = false
    @State private var navigateToChat = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Counter
                    HStack {
                        Spacer()
                        Label("\(profile?.streakCount ?? 0)", systemImage: "flame.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.1), in: Capsule())
                    }
                    .padding(.horizontal)

                    // Daily Verse Card
                    dailyVerseCard

                    // Remaining chats indicator
                    if let profile {
                        let remaining = (profile.isPremium ? 50 : 5) - profile.dailyChatsUsed
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.caption)
                            Text("\(max(remaining, 0)) chats remaining today")
                                .font(.caption)
                        }
                        .foregroundStyle(.tertiary)
                    }

                    // Chat Prompt
                    VStack(spacing: 16) {
                        Text("What's on your heart today?")
                            .font(.title2.bold())

                        NavigationLink(destination: ChatView()) {
                            HStack {
                                Image(systemName: "message")
                                Text("Start a conversation")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "2C5F7C"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer(minLength: 80)
                }
                .padding(.top)
            }
            .background(Color(hex: "FAFAF8"))
            .navigationTitle("Seek")
            .refreshable {
                await loadDailyVerse()
            }
            .task {
                await loadDailyVerse()
                StreakManager.recordActivity(modelContext: modelContext)
            }
        }
    }

    // MARK: - Daily Verse Card

    private var dailyVerseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Verse")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if isLoadingVerse {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let verse = dailyVerse {
                Text("\"\(verse.text)\"")
                    .font(.custom("Georgia", size: 18))
                    .lineSpacing(6)

                HStack {
                    Text("— \(verse.reference)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "2C5F7C"))
                    Spacer()
                    // Favorite button
                    Button {
                        favoriteVerse(verse)
                    } label: {
                        Image(systemName: "heart")
                            .foregroundStyle(Color(hex: "2C5F7C"))
                    }
                }

                // Theme tag
                Text(verse.theme.capitalized)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "D4A853").opacity(0.15))
                    .foregroundStyle(Color(hex: "D4A853"))
                    .clipShape(Capsule())
            } else if !isLoadingVerse {
                // Fallback static verse
                Text("\"God is our refuge and strength, a very present help in trouble.\"")
                    .font(.custom("Georgia", size: 18))
                    .lineSpacing(6)

                Text("— Psalm 46:1")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "2C5F7C"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func loadDailyVerse() async {
        isLoadingVerse = true
        defer { isLoadingVerse = false }

        do {
            dailyVerse = try await SupabaseService.shared.fetchDailyVerse()
        } catch {
            // Silently fail — fallback verse shows
            print("Failed to load daily verse: \(error)")
        }
    }

    private func favoriteVerse(_ verse: DailyVerse) {
        let favorite = FavoriteVerse(
            reference: verse.reference,
            text: verse.text,
            source: "daily_verse"
        )
        modelContext.insert(favorite)
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environment(AuthManager())
        .modelContainer(for: [UserProfile.self, FavoriteVerse.self])
}
