import Foundation
import SwiftData

/// A local delete that still has to reach Supabase. Deleting a SwiftData row
/// removes it immediately, so the id is parked here until the next push marks
/// the remote row `deleted_at` (which is how other devices learn about it).
@Model
final class SyncTombstone {
    @Attribute(.unique) var id: UUID
    var table: String = ""        // Supabase table name, e.g. "saved_cards"
    var deletedAt: Date = Date.now

    init(id: UUID, table: String, deletedAt: Date = .now) {
        self.id = id
        self.table = table
        self.deletedAt = deletedAt
    }
}
