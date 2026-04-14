import Foundation
import SwiftData

@Model
final class SavedPrayer {
    @Attribute(.unique) var id: UUID
    var text: String
    var savedAt: Date
    var source: String = "chat"        // "chat" for now; reserved for future sources
    var contextNote: String? = nil     // optional: the user prompt that produced the prayer

    init(
        id: UUID = UUID(),
        text: String,
        savedAt: Date = .now,
        source: String = "chat",
        contextNote: String? = nil
    ) {
        self.id = id
        self.text = text
        self.savedAt = savedAt
        self.source = source
        self.contextNote = contextNote
    }
}
