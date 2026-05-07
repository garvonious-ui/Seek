import SwiftUI
import SwiftData

struct ChatListView: View {
    @Environment(AuthManager.self) private var authManager
    @Query(sort: \ChatConversation.startedAt, order: .reverse) private var conversations: [ChatConversation]
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            Group {
                if authManager.isGuest {
                    GuestGateView(
                        icon: "message.fill",
                        title: "Sign in to chat",
                        message: "Scripture chat keeps your conversations and tracks your daily limit. Create a free account to get started."
                    ) {
                        showSignIn = true
                    }
                } else if conversations.isEmpty {
                    // Empty state — go straight to new chat
                    ChatView()
                } else {
                    List {
                        // New chat button at the top
                        NavigationLink {
                            ChatView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: "5B7B5E"))
                                Text("New Conversation")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                            }
                            .padding(.vertical, 4)
                        }

                        // Recent conversations
                        Section {
                            ForEach(conversations) { conversation in
                                NavigationLink {
                                    ChatView(existingConversation: conversation)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(conversation.summary ?? "Scripture chat")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color(hex: "1A1A1A"))
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
                        } header: {
                            Text("Recent")
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Chat")
        }
        .sheet(isPresented: $showSignIn) {
            GuestSignInSheet(isPresented: $showSignIn)
        }
    }
}

#Preview {
    ChatListView()
        .modelContainer(for: [ChatConversation.self, ChatMessage.self])
}
