import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var dailyVerse: DailyVerse?
    @State private var isLoadingVerse = false
    @State private var showProfile = false
    @State private var chatPrompt: String?

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
        ("I'm feeling grateful", "heart.fill"),
        ("I need strength today", "bolt.heart.fill"),
        ("Help me find peace", "leaf.fill"),
        ("I want to praise God", "hands.sparkles.fill"),
        ("Going through something hard", "cloud.rain.fill"),
        ("I'm celebrating!", "party.popper.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                        Label("\(profile?.streakCount ?? 0)", systemImage: "flame.fill")
                            .font(.headline)
                            .foregroundStyle(Color(hex: "CDA349"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "CDA349").opacity(0.12), in: Capsule())
                    }
                    .padding(.horizontal)

                    // Daily Verse Card
                    dailyVerseCard

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
                                NavigationLink {
                                    ChatView(initialMessage: prompt)
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
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Seek")
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
                    .foregroundStyle(Color(hex: "CDA349"))
                Spacer()
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
                        favoriteVerse(verse)
                    } label: {
                        Image(systemName: "heart")
                            .foregroundStyle(Color(hex: "5B7B5E"))
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
                Text("\"God is our refuge and strength, a very present help in trouble.\"")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineSpacing(6)

                Text("— Psalm 46:1")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "5B7B5E"))
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
