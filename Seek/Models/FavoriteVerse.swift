import Foundation
import SwiftData

@Model
final class FavoriteVerse {
    @Attribute(.unique) var id: UUID
    /// True until this row has been pushed to Supabase (cloud sync). Declaration
    /// default is required so SwiftData can migrate existing stores — existing
    /// rows start dirty, which is what uploads them on the first sync.
    var needsSync: Bool = true
    var reference: String
    var text: String
    var savedAt: Date
    var source: String  // "chat", "daily_verse"

    init(
        id: UUID = UUID(),
        reference: String,
        text: String,
        savedAt: Date = .now,
        source: String
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.savedAt = savedAt
        self.source = source
    }
}
