import Foundation
import SwiftData

@Model
final class ChatConversation {
    @Attribute(.unique) var id: UUID
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
