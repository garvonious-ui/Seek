import SwiftUI
import SwiftData

struct ChatView: View {
    var initialMessage: String? = nil
    var existingConversation: ChatConversation? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query private var favoriteVerses: [FavoriteVerse]
    @Query private var savedPrayers: [SavedPrayer]
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var messages: [DisplayMessage] = []
    @State private var isLoading = false
    @State private var conversationHistory: [[String: String]] = []
    @State private var currentConversation: ChatConversation?
    @State private var rateLimitMessage: String?
    @State private var selectedVerse: VerseResult?
    @State private var selectedPrayer: PrayerCardTarget?
    @State private var anchorMessageID: String?
    @State private var hasLoadedInitialMessage = false
    @State private var lastUserPrompt: String?
    /// Intro message ids that have finished their typewriter reveal. Keyed by
    /// the stable DisplayMessage.id so a recycled row never re-types. History
    /// loads pre-seed this so reopened conversations render static.
    @State private var revealedIntroIDs: Set<UUID> = []

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
                            Group {
                                switch msg.kind {
                                case .user(let text):
                                    userBubble(text)
                                case .intro(let text):
                                    assistantIntro(text, messageID: msg.id)
                                case .verses(let verses):
                                    versesCard(verses)
                                case .prayer(let text):
                                    prayerCard(text)
                                case .worshipSong(let song):
                                    worshipSongCard(song)
                                case .action(let action):
                                    actionCard(action)
                                case .followUp(let text):
                                    followUpBubble(text)
                                case .error(let text):
                                    errorBubble(text)
                                case .rateLimit(let text):
                                    rateLimitCard(text)
                                }
                            }
                            .id("msg-\(msg.id.uuidString)")
                            .transition(Self.transition(for: msg.kind))
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
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: anchorMessageID) { _, newID in
                    // Fresh send/regenerate: park the user's message at the top
                    // of the viewport so the response flows downward into view.
                    guard let newID else { return }
                    withAnimation(.easeOut(duration: 0.45)) {
                        proxy.scrollTo(newID, anchor: .top)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    // History load (anchor not set) — keep latest activity visible.
                    if anchorMessageID == nil {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
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

            // Offline banner — replaces the rate-limit banner's role when
            // there's no network. Chat requires a live Claude call so we
            // don't pretend otherwise.
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                    Text("You're offline. Scripture chat will resume when you reconnect.")
                        .font(.caption)
                    Spacer()
                }
                .padding(12)
                .background(Color(hex: "F3F4F6"))
                .foregroundStyle(Color(hex: "6B7280"))
            }

            // Regenerate Scripture button — only visible right after an assistant response
            if canRegenerate {
                regenerateBar
            }

            // Input bar
            inputBar
        }
        .background(Color(hex: "FAFAF6"))
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasLoadedInitialMessage {
                hasLoadedInitialMessage = true

                // Load existing conversation
                if let conv = existingConversation {
                    currentConversation = conv
                    loadConversationMessages(conv)
                }

                // Auto-send initial message from quick prompt
                if let initial = initialMessage {
                    messageText = initial
                    sendMessage()
                }
            }
        }
        .sheet(item: $selectedVerse) { verse in
            CardCreatorView(
                verseReference: verse.reference,
                verseText: verse.text,
                verseContext: verse.context
            )
        }
        .sheet(item: $selectedPrayer) { target in
            CardCreatorView(prayerText: target.text)
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

    private func assistantIntro(_ text: String, messageID: UUID) -> some View {
        HStack {
            // Typewriter reveal — the intro text feels like it's being
            // thought out rather than appearing all at once. Markdown
            // (**bold**, etc.) snaps in once the reveal completes.
            //
            // The "already revealed" state lives in the parent (keyed by the
            // stable message id), NOT in TypewriterText's own @State — so a
            // row that scrolls off-screen and recycles snaps straight to the
            // finished text instead of re-typing and fighting the scroll
            // anchor.
            TypewriterText(
                fullText: text,
                messageID: messageID,
                alreadyRevealed: revealedIntroIDs.contains(messageID),
                onReveal: { revealedIntroIDs.insert(messageID) }
            )
                .foregroundStyle(Color(hex: "1A1A1A"))
                .padding(12)
                .background(Color(hex: "F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }

    /// Per-kind transition. Assistant cards slide in from the leading edge
    /// (left in LTR), reinforcing that the AI is "delivering" content into
    /// view. User bubbles, error bubbles, and rate-limit cards just fade —
    /// they're either right-aligned (user) or system messages where a slide
    /// would feel decorative. Keep this in sync with DisplayMessage.Kind.
    static func transition(for kind: DisplayMessage.Kind) -> AnyTransition {
        switch kind {
        case .user, .error, .rateLimit:
            return .opacity
        case .intro, .verses, .prayer, .worshipSong, .action, .followUp:
            return .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .leading)),
                removal: .opacity
            )
        }
    }

    /// Parse markdown preserving newlines. Falls back to plain text on failure.
    static func renderMarkdown(_ string: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attr = try? AttributedString(markdown: string, options: options) {
            return attr
        }
        return AttributedString(string)
    }

    private func versesCard(_ verses: [VerseResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(verses) { verse in
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

                    HStack(spacing: 16) {
                        Spacer()
                        Button {
                            toggleFavorite(verse)
                        } label: {
                            let isFav = favoriteVerses.contains { $0.reference == verse.reference }
                            Label("Favorite", systemImage: isFav ? "heart.fill" : "heart")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color(hex: "CDA349"))
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedVerse = verse
                        } label: {
                            Label("Create Card", systemImage: "rectangle.on.rectangle")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color(hex: "5B7B5E"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
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

            HStack(spacing: 16) {
                Spacer()
                Button {
                    togglePrayerFavorite(text)
                } label: {
                    let isFav = savedPrayers.contains { $0.text == text }
                    Label("Favorite", systemImage: isFav ? "heart.fill" : "heart")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(hex: "CDA349"))
                }
                .buttonStyle(.plain)

                Button {
                    selectedPrayer = PrayerCardTarget(text: text)
                } label: {
                    Label("Create Card", systemImage: "rectangle.on.rectangle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(hex: "5B7B5E"))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
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

            // Music links
            HStack(spacing: 16) {
                Button {
                    let query = "\(song.title) \(song.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "music://music.apple.com/search?term=\(query)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Apple Music", systemImage: "music.note")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: "5B7B5E"))
                }

                Button {
                    let query = "\(song.title) \(song.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "spotify:search:\(query)") {
                        UIApplication.shared.open(url) { success in
                            if !success {
                                // Spotify not installed — open web
                                if let webURL = URL(string: "https://open.spotify.com/search/\(query)") {
                                    UIApplication.shared.open(webURL)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Spotify", systemImage: "play.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: "1DB954"))
                }
            }
            .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "5B7B5E").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func actionCard(_ action: ActionStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(action.title, systemImage: "figure.walk")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "5B7B5E"))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(action.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color(hex: "5B7B5E"))
                            .clipShape(Circle())
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "1A1A1A"))
                    }
                }
            }

            Text(action.reason)
                .font(.caption)
                .foregroundStyle(Color(hex: "6B7280"))
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "5B7B5E").opacity(0.08))
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
            Text("Resets at midnight, your local time.")
                .font(.caption)
                .foregroundStyle(Color(hex: "6B7280"))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "CDA349").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(
                networkMonitor.isConnected ? "What's on your heart?" : "Waiting for connection...",
                text: $messageText,
                axis: .vertical
            )
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(12)
                .background(Color(hex: "F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!networkMonitor.isConnected)
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(isSendDisabled ? .gray : Color(hex: "5B7B5E"))
            }
            .disabled(isSendDisabled)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.shadow(.drop(color: .black.opacity(0.05), radius: 4, y: -2)))
        // Keyboard dismisses via `.scrollDismissesKeyboard(.interactively)` on
        // the chat ScrollView — drag down to hide. We removed the toolbar Done
        // button because it visually overlapped the send button on the input
        // bar (real-device repro). Auto-dismiss on `sendMessage()` still
        // collapses the keyboard out of the way of incoming response cards.
    }

    /// Whether the send button should be inert — empty text, in-flight request,
    /// or no network to send over.
    private var isSendDisabled: Bool {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || isLoading
            || !networkMonitor.isConnected
    }

    // MARK: - Send Message

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Block sends outright when offline. The input bar already disables
        // the button, but belt-and-suspenders in case a stale state slips
        // through (e.g. auto-submit from initialMessage when we're offline).
        guard networkMonitor.isConnected else {
            messages.append(DisplayMessage(kind: .error("You're offline. Reconnect and try again.")))
            return
        }

        // Truncate at 500 chars
        let truncated = String(text.prefix(500))
        messageText = ""
        isInputFocused = false

        // Track last user prompt for regenerate-scripture support
        lastUserPrompt = truncated

        // Add user message and anchor the chat to it — the response cards
        // will flow downward from the user's prompt instead of scrolling
        // past it to the bottom.
        let userBubbleMsg = DisplayMessage(kind: .user(truncated))
        withAnimation(.easeOut(duration: 0.3)) {
            messages.append(userBubbleMsg)
        }
        anchorMessageID = "msg-\(userBubbleMsg.id.uuidString)"

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
        Task { @MainActor in
            do {
                var response = try await SupabaseService.shared.sendChatMessage(
                    truncated,
                    conversationHistory: conversationHistory,
                    translation: profile?.preferredTranslation ?? "NLT"
                )

                // Client-side fallback: if verses are empty but message looks like JSON, try re-parsing
                if response.verses.isEmpty, response.message.trimmingCharacters(in: .whitespaces).hasPrefix("{"),
                   let data = response.message.data(using: .utf8),
                   let reparsed = try? JSONDecoder().decode(ChatResponse.self, from: data) {
                    response = reparsed
                }

                isLoading = false
                await renderResponse(response)
            } catch {
                isLoading = false
                withAnimation(.easeOut(duration: 0.3)) {
                    messages.append(DisplayMessage(kind: classifyChatError(error)))
                }
            }
        }
    }

    /// Turns a thrown chat error into the appropriate display kind. Prefers
    /// the explicit offline message when NetworkMonitor says we've lost
    /// signal or the error code matches one of the usual "no connection"
    /// suspects. Falls through to rate-limit handling and finally a generic
    /// retry bubble.
    private func classifyChatError(_ error: Error) -> DisplayMessage.Kind {
        if !networkMonitor.isConnected || Self.isNetworkError(error) {
            return .error("You're offline. Reconnect and try again.")
        }
        let description = error.localizedDescription
        if description.contains("429") || description.contains("daily_limit") {
            return .rateLimit("You've used all your free scripture chats for today. Upgrade to Seek+ for 50 chats per day!")
        }
        return .error("Something went wrong finding scripture for you. Please try again.")
    }

    private static func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorInternationalRoamingOff,
             NSURLErrorDataNotAllowed:
            return true
        default:
            return false
        }
    }

    // MARK: - Render Response

    /// Appends a decoded ChatResponse to the display list, updates conversation
    /// history, persists to SwiftData, and bumps profile stats. Shared by
    /// `sendMessage` and `regenerateScripture`. Cards stream in with a small
    /// stagger so the response feels like it's arriving rather than dumping.
    @MainActor
    private func renderResponse(_ response: ChatResponse) async {
        // Pacing: each card's spring animates over ~0.45s. Stagger should be
        // long enough that one card lands before the next starts, but not so
        // long that the response feels stalled. ~360ms feels deliberate
        // (CLAUDE.md note: 140ms read as a single dump, 200ms+ feels
        // intentional). Verses get a longer pre-beat because they're the
        // main content; supporting cards (prayer, song, action) use a
        // tighter rhythm afterward.
        let arrival: Animation = .spring(response: 0.45, dampingFraction: 0.85)
        let leadIn: Duration = .milliseconds(220)
        let beat: Duration = .milliseconds(360)
        let coda: Duration = .milliseconds(280)

        if !response.message.isEmpty {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .intro(response.message)))
            }
            try? await Task.sleep(for: leadIn)
        }
        if !response.verses.isEmpty {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .verses(response.verses)))
            }
            try? await Task.sleep(for: beat)
        }
        if !response.prayer.isEmpty {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .prayer(response.prayer)))
            }
            try? await Task.sleep(for: coda)
        }
        if let song = response.worshipSong {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .worshipSong(song)))
            }
            try? await Task.sleep(for: coda)
        }
        if let action = response.action {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .action(action)))
            }
            try? await Task.sleep(for: coda)
        }
        if let followUp = response.followUp, !followUp.isEmpty {
            withAnimation(arrival) {
                messages.append(DisplayMessage(kind: .followUp(followUp)))
            }
        }

        if let remaining = response.remainingChats {
            if remaining <= 1 {
                rateLimitMessage = "You have \(remaining) chat\(remaining == 1 ? "" : "s") remaining today"
            } else {
                rateLimitMessage = nil
            }
        }

        // Persist to SwiftData
        let responseJSON = try? JSONEncoder().encode(response)
        let fullContent = responseJSON.flatMap { String(data: $0, encoding: .utf8) } ?? response.message
        let assistantMsg = ChatMessage(role: "assistant", content: fullContent)
        assistantMsg.conversation = currentConversation
        modelContext.insert(assistantMsg)
        try? modelContext.save()

        conversationHistory.append(["role": "assistant", "content": fullContent])

        if let profile {
            profile.totalVersesExplored += response.verses.count
            profile.dailyChatsUsed += 1
            try? modelContext.save()
        }
    }

    // MARK: - Regenerate Scripture

    /// Whether the Regenerate button should be visible above the input bar.
    /// Only shown when the last assistant message is actual content (verses,
    /// prayer, song, action, follow-up) and we have a prompt to resend.
    private var canRegenerate: Bool {
        guard !isLoading, lastUserPrompt != nil, networkMonitor.isConnected else { return false }
        guard let last = messages.last else { return false }
        switch last.kind {
        case .verses, .prayer, .worshipSong, .action, .followUp:
            return true
        case .user, .intro, .error, .rateLimit:
            return false
        }
    }

    private var regenerateBar: some View {
        HStack {
            Spacer()
            Button(action: regenerateScripture) {
                Label("Regenerate scripture", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "5B7B5E").opacity(0.08))
                    .foregroundStyle(Color(hex: "5B7B5E"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func regenerateScripture() {
        guard let prompt = lastUserPrompt, !isLoading else { return }

        // Strip the most recent assistant-response display messages back to the
        // user bubble so the new response replaces the old one visually.
        withAnimation(.easeOut(duration: 0.25)) {
            while let last = messages.last {
                switch last.kind {
                case .user:
                    // Leave the user bubble in place and stop.
                    break
                default:
                    messages.removeLast()
                    continue
                }
                break
            }
        }

        // Re-anchor scroll on the now-trailing user bubble so the regenerated
        // response renders below it from the top of the viewport.
        if let last = messages.last, case .user = last.kind {
            anchorMessageID = "msg-\(last.id.uuidString)"
        }

        // Also drop the previous assistant turn from conversationHistory so the
        // model isn't still anchored to its earlier answer.
        if let lastHist = conversationHistory.last, lastHist["role"] == "assistant" {
            conversationHistory.removeLast()
        }

        // Send a regeneration hint via conversationHistory only — no new user
        // bubble in the chat. The original user message remains visible.
        let hint = "Please share different scriptures for my previous message on the same topic."
        var historyForCall = conversationHistory
        historyForCall.append(["role": "user", "content": hint])

        isLoading = true
        Task { @MainActor in
            do {
                var response = try await SupabaseService.shared.sendChatMessage(
                    prompt,
                    conversationHistory: historyForCall,
                    translation: profile?.preferredTranslation ?? "NLT"
                )

                // Same client-side JSON salvage fallback as sendMessage.
                if response.verses.isEmpty, response.message.trimmingCharacters(in: .whitespaces).hasPrefix("{"),
                   let data = response.message.data(using: .utf8),
                   let reparsed = try? JSONDecoder().decode(ChatResponse.self, from: data) {
                    response = reparsed
                }

                isLoading = false
                await renderResponse(response)
            } catch {
                isLoading = false
                withAnimation(.easeOut(duration: 0.3)) {
                    messages.append(DisplayMessage(kind: classifyChatError(error)))
                }
            }
        }
    }

    // MARK: - Favorite Verse

    private func toggleFavorite(_ verse: VerseResult) {
        if let existing = favoriteVerses.first(where: { $0.reference == verse.reference }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteVerse(reference: verse.reference, text: verse.text, source: "chat"))
        }
        try? modelContext.save()
    }

    // MARK: - Favorite Prayer

    private func togglePrayerFavorite(_ prayerText: String) {
        if let existing = savedPrayers.first(where: { $0.text == prayerText }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                SavedPrayer(
                    text: prayerText,
                    source: "chat",
                    contextNote: lastUserPrompt
                )
            )
        }
        try? modelContext.save()
    }

    // MARK: - Load Existing Conversation

    private func loadConversationMessages(_ conversation: ChatConversation) {
        let sorted = conversation.messages.sorted { $0.timestamp < $1.timestamp }

        for msg in sorted {
            if msg.role == "user" {
                messages.append(DisplayMessage(kind: .user(msg.content)))
                conversationHistory.append(["role": "user", "content": msg.content])
                lastUserPrompt = msg.content
            } else {
                // Try to parse assistant JSON response
                if let data = msg.content.data(using: .utf8),
                   let response = try? JSONDecoder().decode(ChatResponse.self, from: data) {

                    if !response.message.isEmpty {
                        let intro = DisplayMessage(kind: .intro(response.message))
                        messages.append(intro)
                        // History-loaded intros are old — show them static, no
                        // typewriter replay.
                        revealedIntroIDs.insert(intro.id)
                    }
                    if !response.verses.isEmpty {
                        messages.append(DisplayMessage(kind: .verses(response.verses)))
                    }
                    if !response.prayer.isEmpty {
                        messages.append(DisplayMessage(kind: .prayer(response.prayer)))
                    }
                    if let song = response.worshipSong {
                        messages.append(DisplayMessage(kind: .worshipSong(song)))
                    }
                    if let action = response.action {
                        messages.append(DisplayMessage(kind: .action(action)))
                    }
                    if let followUp = response.followUp, !followUp.isEmpty {
                        messages.append(DisplayMessage(kind: .followUp(followUp)))
                    }
                    conversationHistory.append(["role": "assistant", "content": msg.content])
                } else {
                    // Fallback: show as plain text
                    let intro = DisplayMessage(kind: .intro(msg.content))
                    messages.append(intro)
                    revealedIntroIDs.insert(intro.id)
                    conversationHistory.append(["role": "assistant", "content": msg.content])
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
        case action(ActionStep)
        case followUp(String)
        case error(String)
        case rateLimit(String)
    }
}

// MARK: - Prayer Card Target

/// Identifiable wrapper so .sheet(item:) can present CardCreatorView with a prayer payload.
struct PrayerCardTarget: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Typewriter Text
//
// Reveals plain text character-by-character, then snaps to fully-rendered
// markdown once the reveal completes. Used for the assistant intro so the
// AI's opening line feels like it's being thought out rather than dumped.
struct TypewriterText: View {
    let fullText: String
    /// Stable id of the owning message. The reveal animation is keyed on this
    /// (NOT on `fullText`) so two messages with identical intro text don't
    /// confuse the `.task` identity.
    let messageID: UUID
    /// Whether this message already finished revealing. When true (e.g. the
    /// row recycled after scrolling, or the conversation was loaded from
    /// history) the text snaps straight to its final markdown form.
    let alreadyRevealed: Bool
    /// Called once when the reveal completes, so the parent can remember this
    /// message and pass `alreadyRevealed: true` on any future re-render.
    let onReveal: () -> Void
    /// ~70 chars/sec ≈ 14ms per char. Snappy but legible. Bump down for a
    /// more "thinking" pace; bump up for snappier delivery.
    var charsPerSecond: Double = 70
    @State private var visibleCount: Int = 0

    var body: some View {
        Group {
            if visibleCount >= fullText.count {
                Text(Self.renderMarkdown(fullText))
            } else {
                Text(String(fullText.prefix(visibleCount)))
            }
        }
        .task(id: messageID) {
            // Already revealed once (recycled row / history load): snap to the
            // finished text, no animation, no scroll disruption.
            if alreadyRevealed {
                visibleCount = fullText.count
                return
            }
            // Fresh reveal — animate from 0 to full, then mark complete.
            visibleCount = 0
            let interval: Duration = .milliseconds(max(1, Int(1000.0 / charsPerSecond)))
            for n in 1...max(1, fullText.count) {
                visibleCount = n
                try? await Task.sleep(for: interval)
            }
            visibleCount = fullText.count
            onReveal()
        }
    }

    static func renderMarkdown(_ string: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: string, options: options))
            ?? AttributedString(string)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
    .environment(NetworkMonitor())
    .modelContainer(for: [ChatConversation.self, ChatMessage.self, UserProfile.self])
}
