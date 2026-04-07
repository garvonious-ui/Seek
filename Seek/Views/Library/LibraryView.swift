import SwiftUI
import SwiftData

struct LibraryView: View {
    @State private var selectedTab: LibraryTab = .cards

    enum LibraryTab: String, CaseIterable {
        case cards = "Cards"
        case favorites = "Favorites"
        case history = "History"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Library", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .cards:
                    CardsGridView()
                case .favorites:
                    FavoritesListView()
                case .history:
                    HistoryListView()
                }
            }
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Library")
        }
    }
}

// MARK: - Cards Grid

struct CardsGridView: View {
    @Query(sort: \SavedCard.createdAt, order: .reverse) private var cards: [SavedCard]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        if cards.isEmpty {
            libraryEmptyState(
                icon: "rectangle.on.rectangle",
                title: "No cards yet",
                subtitle: "Create your first verse card from a scripture chat"
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(cards) { card in
                        cardThumbnail(card)
                    }
                }
                .padding()
            }
        }
    }

    private func cardThumbnail(_ card: SavedCard) -> some View {
        let template = CardTemplate.all.first { $0.id == card.templateID } ?? CardTemplate.all[0]

        return VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let gradient = template.backgroundGradient {
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    template.backgroundColor
                }

                VStack(spacing: 4) {
                    Text(card.verseText)
                        .font(.custom(template.fontName, size: 9))
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(template.textColor)
                        .padding(.horizontal, 8)

                    Text(card.verseReference)
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(template.referenceColor)
                }
                .padding(8)
            }
            .aspectRatio(9.0/16.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(card.verseReference)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(hex: "1A1A1A"))
            Text(card.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = "\(card.verseText)\n— \(card.verseReference)"
            } label: {
                Label("Copy Verse", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Favorites List

struct FavoritesListView: View {
    @Query(sort: \FavoriteVerse.savedAt, order: .reverse) private var favorites: [FavoriteVerse]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if favorites.isEmpty {
            libraryEmptyState(
                icon: "heart",
                title: "No favorites yet",
                subtitle: "Heart a verse to save it here"
            )
        } else {
            List {
                ForEach(favorites) { verse in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verse.reference)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(hex: "5B7B5E"))
                        Text(verse.text)
                            .font(.custom("Georgia", size: 14))
                            .lineSpacing(3)
                            .lineLimit(3)
                        HStack {
                            Text(verse.source == "daily_verse" ? "Daily Verse" : "Chat")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "5B7B5E").opacity(0.08))
                                .clipShape(Capsule())
                            Spacer()
                            Text(verse.savedAt.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = "\(verse.text)\n— \(verse.reference)"
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
                .onDelete { indices in
                    for index in indices {
                        modelContext.delete(favorites[index])
                    }
                    try? modelContext.save()
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - History List

struct HistoryListView: View {
    @Query(sort: \ChatConversation.startedAt, order: .reverse) private var conversations: [ChatConversation]

    var body: some View {
        if conversations.isEmpty {
            libraryEmptyState(
                icon: "clock",
                title: "No conversations yet",
                subtitle: "Start a scripture chat to see your history"
            )
        } else {
            List {
                ForEach(conversations) { conversation in
                    NavigationLink {
                        ChatView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.summary ?? "Scripture chat")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                            HStack {
                                Text("\(conversation.messages.count) messages")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "6B7280"))
                                Spacer()
                                Text(conversation.startedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Empty State Helper

func libraryEmptyState(icon: String, title: String, subtitle: String) -> some View {
    VStack(spacing: 12) {
        Spacer()
        Image(systemName: icon)
            .font(.system(size: 48))
            .foregroundStyle(Color(hex: "5B7B5E").opacity(0.3))
        Text(title)
            .font(.headline)
            .foregroundStyle(Color(hex: "6B7280"))
        Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(Color(hex: "9CA3AF"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        Spacer()
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [SavedCard.self, FavoriteVerse.self, ChatConversation.self, ChatMessage.self])
}
