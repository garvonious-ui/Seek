import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    /// True until this row has been pushed to Supabase (cloud sync). Declaration
    /// default is required so SwiftData can migrate existing stores — existing
    /// rows start dirty, which is what uploads them on the first sync.
    var needsSync: Bool = true
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
