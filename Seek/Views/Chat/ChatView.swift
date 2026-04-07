import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var messageText = ""
    @State private var messages: [DisplayMessage] = []
    @State private var isLoading = false
    @State private var conversationHistory: [[String: String]] = []
    @State private var currentConversation: ChatConversation?
    @State private var rateLimitMessage: String?
    @State private var showCardCreator = false
    @State private var selectedVerse: VerseResult?
    @State private var scrollToBottom = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty {
                            emptyState
                        }

                        ForEach(messages) { msg in
                            switch msg.kind {
                            case .user(let text):
                                userBubble(text)
                            case .intro(let text):
                                assistantIntro(text)
                            case .verses(let verses):
                                versesCard(verses)
                            case .prayer(let text):
                                prayerCard(text)
                            case .worshipSong(let song):
                                worshipSongCard(song)
                            case .followUp(let text):
                                followUpBubble(text)
                            case .error(let text):
                                errorBubble(text)
                            case .rateLimit(let text):
                                rateLimitCard(text)
                            }
                        }

                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Finding scripture...")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .padding()
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Rate limit banner
            if let rateLimitMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                    Text(rateLimitMessage)
                        .font(.caption)
                    Spacer()
                }
                .padding(12)
                .background(Color(hex: "F59E0B").opacity(0.1))
                .foregroundStyle(Color(hex: "F59E0B"))
            }

            // Input bar
            inputBar
        }
        .background(Color(hex: "FAFAF6"))
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCardCreator) {
            if let verse = selectedVerse {
                CardCreatorView(
                    verseReference: verse.reference,
                    verseText: verse.text
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "5B7B5E").opacity(0.3))

            Text("Share what's on your heart")
                .font(.headline)
                .foregroundStyle(Color(hex: "6B7280"))

            Text("Tell me what you're going through — joy, gratitude, struggle, or seeking — and I'll find scripture for your moment.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Suggestion chips
            VStack(spacing: 8) {
                suggestionChip("I'm feeling grateful today")
                suggestionChip("I need strength for something hard")
                suggestionChip("I just want to praise God")
            }
            .padding(.top, 8)
        }
        .padding(.top, 40)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            messageText = text
            sendMessage()
        } label: {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "5B7B5E").opacity(0.08))
                .foregroundStyle(Color(hex: "5B7B5E"))
                .clipShape(Capsule())
        }
    }

    // MARK: - Message Bubbles

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .padding(12)
                .background(Color(hex: "5B7B5E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func assistantIntro(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundStyle(Color(hex: "1A1A1A"))
                .padding(12)
                .background(Color(hex: "F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }

    private func versesCard(_ verses: [VerseResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(verses) { verse in
                Button {
                    selectedVerse = verse
                    showCardCreator = true
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verse.reference)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(hex: "5B7B5E"))

                        Text(verse.text)
                            .font(.custom("Georgia", size: 15))
                            .lineSpacing(4)
                            .foregroundStyle(Color(hex: "1A1A1A"))

                        Text(verse.context)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "6B7280"))

                        HStack {
                            Spacer()
                            Label("Create Card", systemImage: "rectangle.on.rectangle")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color(hex: "5B7B5E"))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func prayerCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Prayer", systemImage: "hands.sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "CDA349"))

            Text(text)
                .font(.custom("Georgia", size: 15).italic())
                .lineSpacing(4)
                .foregroundStyle(Color(hex: "1A1A1A"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "CDA349").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func worshipSongCard(_ song: WorshipSong) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Worship Song", systemImage: "music.note")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "5B7B5E"))

            Text(song.title)
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: "1A1A1A"))
            Text("by \(song.artist)")
                .font(.caption)
                .foregroundStyle(Color(hex: "6B7280"))
            Text(song.context)
                .font(.caption)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "5B7B5E").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func followUpBubble(_ text: String) -> some View {
        HStack {
            Button {
                messageText = text
                sendMessage()
            } label: {
                Text(text)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(hex: "5B7B5E").opacity(0.08))
                    .foregroundStyle(Color(hex: "5B7B5E"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer(minLength: 60)
        }
    }

    private func errorBubble(_ text: String) -> some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .padding(12)
                .background(.red.opacity(0.08))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer(minLength: 60)
        }
    }

    private func rateLimitCard(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.title2)
                .foregroundStyle(Color(hex: "CDA349"))
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Upgrade to Seek+") {
                // TODO: Show premium upgrade
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "CDA349"))
            .controlSize(.small)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "CDA349").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("What's on your heart?", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(12)
                .background(Color(hex: "F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? .gray : Color(hex: "5B7B5E"))
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.shadow(.drop(color: .black.opacity(0.05), radius: 4, y: -2)))
    }

    // MARK: - Send Message

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Truncate at 500 chars
        let truncated = String(text.prefix(500))
        messageText = ""

        // Add user message
        messages.append(DisplayMessage(kind: .user(truncated)))

        // Create conversation if first message
        if currentConversation == nil {
            let conv = ChatConversation(summary: truncated)
            modelContext.insert(conv)
            currentConversation = conv
        }

        // Save user message to SwiftData
        let userMsg = ChatMessage(role: "user", content: truncated)
        userMsg.conversation = currentConversation
        modelContext.insert(userMsg)
        try? modelContext.save()

        // Update conversation history for context
        conversationHistory.append(["role": "user", "content": truncated])

        // Call API
        isLoading = true
        Task {
            do {
                let response = try await SupabaseService.shared.sendChatMessage(
                    truncated,
                    conversationHistory: conversationHistory
                )

                await MainActor.run {
                    isLoading = false

                    // Add intro message
                    if !response.message.isEmpty {
                        messages.append(DisplayMessage(kind: .intro(response.message)))
                    }

                    // Add verses
                    if !response.verses.isEmpty {
                        messages.append(DisplayMessage(kind: .verses(response.verses)))
                    }

                    // Add prayer
                    if !response.prayer.isEmpty {
                        messages.append(DisplayMessage(kind: .prayer(response.prayer)))
                    }

                    // Add worship song
                    if let song = response.worshipSong {
                        messages.append(DisplayMessage(kind: .worshipSong(song)))
                    }

                    // Add follow-up
                    if let followUp = response.followUp, !followUp.isEmpty {
                        messages.append(DisplayMessage(kind: .followUp(followUp)))
                    }

                    // Update remaining chats
                    if let remaining = response.remainingChats {
                        if remaining <= 1 {
                            rateLimitMessage = "You have \(remaining) chat\(remaining == 1 ? "" : "s") remaining today"
                        } else {
                            rateLimitMessage = nil
                        }
                    }

                    // Save assistant response to SwiftData
                    let responseJSON = try? JSONEncoder().encode(response)
                    let assistantMsg = ChatMessage(
                        role: "assistant",
                        content: responseJSON.flatMap { String(data: $0, encoding: .utf8) } ?? response.message
                    )
                    assistantMsg.conversation = currentConversation
                    modelContext.insert(assistantMsg)
                    try? modelContext.save()

                    // Update conversation history
                    conversationHistory.append(["role": "assistant", "content": response.message])

                    // Update profile stats
                    if let profile {
                        profile.totalVersesExplored += response.verses.count
                        profile.dailyChatsUsed += 1
                        try? modelContext.save()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorString = error.localizedDescription

                    // Check for rate limit
                    if errorString.contains("429") || errorString.contains("daily_limit") {
                        messages.append(DisplayMessage(kind: .rateLimit("You've used all your free scripture chats for today. Upgrade to Seek+ for 50 chats per day!")))
                    } else {
                        messages.append(DisplayMessage(kind: .error("Something went wrong finding scripture for you. Please try again.")))
                    }
                }
            }
        }
    }
}

// MARK: - Display Message Model

struct DisplayMessage: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case user(String)
        case intro(String)
        case verses([VerseResult])
        case prayer(String)
        case worshipSong(WorshipSong)
        case followUp(String)
        case error(String)
        case rateLimit(String)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
    .modelContainer(for: [ChatConversation.self, ChatMessage.self, UserProfile.self])
}
