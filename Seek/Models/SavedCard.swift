import Foundation
import SwiftData

@Model
final class SavedCard {
    @Attribute(.unique) var id: UUID
    var verseReference: String
    var verseText: String
    var templateID: String
    var createdAt: Date
    var isFavorite: Bool
    var contextNote: String?

    init(
        id: UUID = UUID(),
        verseReference: String,
        verseText: String,
        templateID: String,
        createdAt: Date = .now,
        isFavorite: Bool = false,
        contextNote: String? = nil
    ) {
        self.id = id
        self.verseReference = verseReference
        self.verseText = verseText
        self.templateID = templateID
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.contextNote = contextNote
    }
}
