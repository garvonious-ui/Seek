import Foundation
import SwiftData

@Model
final class SavedPrayer {
    @Attribute(.unique) var id: UUID
    /// True until this row has been pushed to Supabase (cloud sync). Declaration
    /// default is required so SwiftData can migrate existing stores — existing
    /// rows start dirty, which is what uploads them on the first sync.
    var needsSync: Bool = true
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
