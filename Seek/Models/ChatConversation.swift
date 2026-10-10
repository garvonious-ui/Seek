import Foundation
import SwiftData

@Model
final class ChatConversation {
    @Attribute(.unique) var id: UUID
    /// True until this row has been pushed to Supabase (cloud sync). Declaration
    /// default is required so SwiftData can migrate existing stores — existing
    /// rows start dirty, which is what uploads them on the first sync.
    var needsSync: Bool = true
    var startedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage]
    var summary: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        messages: [ChatMessage] = [],
        summary: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.messages = messages
        self.summary = summary
    }
}
