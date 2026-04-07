import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String  // "user" or "assistant"
    var content: String
    var timestamp: Date
    var conversation: ChatConversation?

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        timestamp: Date = .now,
        conversation: ChatConversation? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.conversation = conversation
    }
}
