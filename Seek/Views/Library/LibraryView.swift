import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab: LibraryTab = .cards
    @State private var showSignIn = false

    enum LibraryTab: String, CaseIterable {
        case cards = "Cards"
        case favorites = "Favorites"
        case history = "History"
    }

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isGuest {
                    GuestGateView(
                        icon: "bookmark.fill",
                        title: "Sign in to save",
                        message: "Your favorite verses, prayers, and verse cards live in your library when you create a free account."
                    ) {
                        showSignIn = true
                    }
                } else {
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
                }
            }
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Library")
        }
        .sheet(isPresented: $showSignIn) {
            GuestSignInSheet(isPresented: $showSignIn)
        }
    }
}

// MARK: - Cards Grid

struct CardsGridView: View {
    @Query(sort: \SavedCard.createdAt, order: .reverse) private var cards: [SavedCard]
    @Environment(\.modelContext) private var modelContext
    /// True when user has long-pressed any card. Disables the NavigationLink,
    /// shows a red (-) badge on each card. Exits via the Done toolbar button.
    @State private var isEditing = false
    @State private var pendingDeleteCard: SavedCard?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
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
        .toolbar {
            // Show Done in the top-right while editing so users have an
            // explicit way out (iOS Home Screen pattern: tap a card to
            // delete, tap Done to commit).
            if isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditing = false
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "5B7B5E"))
                }
            }
        }
        .alert("Delete card?", isPresented: Binding(
            get: { pendingDeleteCard != nil },
            set: { if !$0 { pendingDeleteCard = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteCard = nil }
            Button("Delete", role: .destructive) {
                if let card = pendingDeleteCard {
                    modelContext.delete(card)
                    try? modelContext.save()
                }
                pendingDeleteCard = nil
            }
        } message: {
            Text("This card will be removed from your library. The image saved to Photos isn't affected.")
        }
    }

    @ViewBuilder
    private func cardThumbnail(_ card: SavedCard) -> some View {
        if isEditing {
            // Edit mode: no nav, wiggle, red (-) badge on top-right tap to
            // delete. Long-pressing again is a no-op; users exit via Done.
            cardThumbnailContent(card)
                .overlay(alignment: .topTrailing) {
                    Button {
                        pendingDeleteCard = card
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .background(
                                Circle().fill(.white).padding(2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                    .accessibilityLabel("Delete card")
                }
                .modifier(WiggleEffect())
        } else {
            // Normal: tap to re-edit (NavigationLink), long-press enters
            // edit mode for delete.
            NavigationLink {
                CardCreatorView(
                    verseReference: card.verseReference,
                    verseText: card.verseText,
                    initialTemplateID: card.templateID
                )
            } label: {
                cardThumbnailContent(card)
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0.5) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isEditing = true
                }
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = "\(card.verseText)\n— \(card.verseReference)"
                } label: {
                    Label("Copy Verse", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    pendingDeleteCard = card
                } label: {
                    Label("Delete Card", systemImage: "trash")
                }
            }
        }
    }

    /// Thumbnail visual — extracted so both the editing and non-editing
    /// branches render identically. Uses VerseCardView at thumbnail size so
    /// it matches the preview + 1080x1920 export pixel-for-pixel (scaled).
    private func cardThumbnailContent(_ card: SavedCard) -> some View {
        let template = CardTemplate.all.first { $0.id == card.templateID } ?? CardTemplate.all[0]
        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = width * (16.0 / 9.0)
                VerseCardView(
                    verseText: card.verseText,
                    verseReference: card.verseReference,
                    template: template,
                    renderSize: CGSize(width: width, height: height)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .aspectRatio(9.0/16.0, contentMode: .fit)

            Text(card.verseReference)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(hex: "1A1A1A"))
            Text(card.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
    }
}

// MARK: - Wiggle Effect
//
// Subtle continuous rotation animation, matches the iOS Home Screen
// "delete mode" feel. Each card uses a slight phase offset so they don't
// all wiggle in lockstep, but for our 2-col grid a single phase reads fine.
private struct WiggleEffect: ViewModifier {
    @State private var phase: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(phase))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                    phase = 1.2
                }
            }
            .onDisappear {
                phase = 0
            }
    }
}

// MARK: - Favorites List

enum FavoritesFilter: String, CaseIterable {
    case all = "All"
    case verses = "Verses"
    case prayers = "Prayers"
}

/// Merged item type so verses and prayers can share one sorted list.
enum FavoriteItem: Identifiable {
    case verse(FavoriteVerse)
    case prayer(SavedPrayer)

    var id: String {
        switch self {
        case .verse(let v): return "v-\(v.id.uuidString)"
        case .prayer(let p): return "p-\(p.id.uuidString)"
        }
    }

    var savedAt: Date {
        switch self {
        case .verse(let v): return v.savedAt
        case .prayer(let p): return p.savedAt
        }
    }
}

struct FavoritesListView: View {
    @Query(sort: \FavoriteVerse.savedAt, order: .reverse) private var favoriteVerses: [FavoriteVerse]
    @Query(sort: \SavedPrayer.savedAt, order: .reverse) private var savedPrayers: [SavedPrayer]
    @Environment(\.modelContext) private var modelContext
    @State private var filter: FavoritesFilter = .all

    /// Items to show given the current filter, merged and sorted newest-first.
    private var items: [FavoriteItem] {
        var combined: [FavoriteItem] = []
        if filter == .all || filter == .verses {
            combined.append(contentsOf: favoriteVerses.map(FavoriteItem.verse))
        }
        if filter == .all || filter == .prayers {
            combined.append(contentsOf: savedPrayers.map(FavoriteItem.prayer))
        }
        return combined.sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            filterChips
                .padding(.horizontal)
                .padding(.bottom, 8)

            if items.isEmpty {
                libraryEmptyState(
                    icon: "heart",
                    title: emptyTitle,
                    subtitle: emptySubtitle
                )
            } else {
                List {
                    ForEach(items) { item in
                        row(for: item)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(FavoritesFilter.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        filter = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(filter == option ? .white : Color(hex: "5B7B5E"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            filter == option
                                ? Color(hex: "5B7B5E")
                                : Color(hex: "5B7B5E").opacity(0.08)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all: return "No favorites yet"
        case .verses: return "No favorite verses"
        case .prayers: return "No saved prayers"
        }
    }

    private var emptySubtitle: String {
        switch filter {
        case .all: return "Heart a verse or prayer from a scripture chat to save it here"
        case .verses: return "Heart a verse to save it here"
        case .prayers: return "Heart a prayer from a scripture chat to save it here"
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: FavoriteItem) -> some View {
        switch item {
        case .verse(let verse):
            verseRow(verse)
        case .prayer(let prayer):
            prayerRow(prayer)
        }
    }

    private func verseRow(_ verse: FavoriteVerse) -> some View {
        NavigationLink {
            CardCreatorView(verseReference: verse.reference, verseText: verse.text)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(verse.reference)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "5B7B5E"))
                Text(verse.text)
                    .font(.custom("Georgia", size: 14))
                    .lineSpacing(3)
                    .lineLimit(3)
                    .foregroundStyle(Color(hex: "1A1A1A"))
                HStack {
                    Text(verse.source == "daily_verse" ? "Daily Verse" : "Verse")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "5B7B5E").opacity(0.08))
                        .clipShape(Capsule())
                    Spacer()
                    Label("Create Card", systemImage: "rectangle.on.rectangle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(hex: "5B7B5E"))
                }
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = "\(verse.text)\n— \(verse.reference)"
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }

    private func prayerRow(_ prayer: SavedPrayer) -> some View {
        NavigationLink {
            CardCreatorView(prayerText: prayer.text)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label("A Prayer", systemImage: "hands.sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "CDA349"))
                Text(prayer.text)
                    .font(.custom("Georgia", size: 14).italic())
                    .lineSpacing(3)
                    .lineLimit(3)
                    .foregroundStyle(Color(hex: "1A1A1A"))
                HStack {
                    Text("Prayer")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "CDA349").opacity(0.12))
                        .clipShape(Capsule())
                    Spacer()
                    Label("Create Card", systemImage: "rectangle.on.rectangle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(hex: "5B7B5E"))
                }
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = prayer.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Delete

    private func deleteItems(at offsets: IndexSet) {
        let current = items
        for index in offsets {
            switch current[index] {
            case .verse(let verse):
                modelContext.delete(verse)
            case .prayer(let prayer):
                modelContext.delete(prayer)
            }
        }
        try? modelContext.save()
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
                        ChatView(existingConversation: conversation)
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
