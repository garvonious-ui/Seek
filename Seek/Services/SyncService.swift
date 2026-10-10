import Foundation
import SwiftData
import Supabase

/// Cloud sync for user content: saved cards, favorite verses, saved prayers and
/// chat history. Local SwiftData stays the source the UI reads from; Supabase is
/// the backup that follows the account to a new phone (or to Android — the same
/// tables back both apps). See docs/cloud-sync.md.
///
/// Push: every row with `needsSync == true` is upserted, then each `SyncTombstone`
/// marks its remote row `deleted_at`. Pull: rows changed since the per-table cursor
/// are applied locally; a row with unpushed local edits is left alone (local wins
/// until its push lands). Deletes always win.
@MainActor
final class SyncService {
    static let shared = SyncService()

    private var container: ModelContainer?
    private var debounceTask: Task<Void, Never>?
    private var isSyncing = false
    private var syncAgain = false

    private let pageSize = 500
    private let chunkSize = 100
    /// Re-read this far behind the stored cursor. Rows committed out of order
    /// (or stamped in the same millisecond) are picked up on the next pass;
    /// applying a row twice is harmless.
    private let cursorOverlap: TimeInterval = 120

    private static let ownerKey = "sync.ownerUserId"

    private init() {}

    func configure(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Triggers

    /// Call after any local write. Coalesces bursts (a chat reply inserts several
    /// rows) into one sync a moment later.
    func requestSync() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    /// Push then pull. Returns false if signed out or anything failed; the dirty
    /// flags and tombstones stay put, so the next sync retries them.
    @discardableResult
    func syncNow() async -> Bool {
        guard let container, let userId = SupabaseService.shared.currentUser?.id else { return false }
        if isSyncing {
            syncAgain = true
            return false
        }
        isSyncing = true
        defer { isSyncing = false }

        let context = container.mainContext
        var succeeded = true
        repeat {
            syncAgain = false
            do {
                try claimLocalData(for: userId, context: context)
                try await push(context: context)
                try await pull(userId: userId, context: context)
                print("[Sync] OK")
            } catch {
                print("[Sync] failed: \(error)")
                succeeded = false
            }
        } while syncAgain && succeeded
        return succeeded
    }

    /// True when local changes haven't reached Supabase yet.
    func hasPendingChanges() -> Bool {
        guard let context = container?.mainContext else { return false }
        let counts = [
            try? context.fetchCount(FetchDescriptor<SavedCard>(predicate: #Predicate { $0.needsSync })),
            try? context.fetchCount(FetchDescriptor<FavoriteVerse>(predicate: #Predicate { $0.needsSync })),
            try? context.fetchCount(FetchDescriptor<SavedPrayer>(predicate: #Predicate { $0.needsSync })),
            try? context.fetchCount(FetchDescriptor<ChatConversation>(predicate: #Predicate { $0.needsSync })),
            try? context.fetchCount(FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.needsSync })),
            try? context.fetchCount(FetchDescriptor<SyncTombstone>()),
        ]
        return counts.contains { ($0 ?? 0) > 0 }
    }

    // MARK: - Local deletes

    /// Use instead of a bare `modelContext.delete` for synced rows, so the delete
    /// reaches the other devices.
    func delete(_ card: SavedCard, in context: ModelContext) {
        context.insert(SyncTombstone(id: card.id, table: "saved_cards"))
        context.delete(card)
    }

    func delete(_ verse: FavoriteVerse, in context: ModelContext) {
        context.insert(SyncTombstone(id: verse.id, table: "favorite_verses"))
        context.delete(verse)
    }

    func delete(_ prayer: SavedPrayer, in context: ModelContext) {
        context.insert(SyncTombstone(id: prayer.id, table: "saved_prayers"))
        context.delete(prayer)
    }

    // MARK: - Sign-out / account switch

    /// Removes every synced row from this device and forgets the sync cursors.
    /// Used on sign-out (after a final push) and on delete-account. The cloud
    /// copy is what restores it on the next sign-in.
    func clearLocalData() throws {
        guard let context = container?.mainContext else { return }
        try clearLocalData(context: context)
    }

    private func clearLocalData(context: ModelContext) throws {
        try context.delete(model: ChatMessage.self)
        try context.delete(model: ChatConversation.self)
        try context.delete(model: SavedCard.self)
        try context.delete(model: FavoriteVerse.self)
        try context.delete(model: SavedPrayer.self)
        try context.delete(model: SyncTombstone.self)
        try context.save()

        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("sync.") {
            defaults.removeObject(forKey: key)
        }
    }

    /// Local data is adopted by the first account that syncs on this device (that
    /// covers existing users and anything saved as a guest). If a *different*
    /// account signs in afterwards — only possible with data left behind by a
    /// build that didn't clear on sign-out — that data is dropped rather than
    /// uploaded into the wrong account.
    private func claimLocalData(for userId: UUID, context: ModelContext) throws {
        let defaults = UserDefaults.standard
        let owner = defaults.string(forKey: Self.ownerKey)
        if owner == userId.uuidString { return }
        if owner != nil {
            print("[Sync] Local data belongs to another account — clearing before sync")
            try clearLocalData(context: context)
        }
        defaults.set(userId.uuidString, forKey: Self.ownerKey)
    }

    // MARK: - Push

    private func push(context: ModelContext) async throws {
        // Conversations before messages: chat_messages has an FK to chat_conversations.
        try await pushDirty(
            FetchDescriptor<ChatConversation>(predicate: #Predicate { $0.needsSync }),
            table: "chat_conversations", context: context,
            row: { ConversationRow($0) }, markClean: { $0.needsSync = false }
        )
        try await pushDirty(
            FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.needsSync }),
            table: "chat_messages", context: context,
            row: { MessageRow($0) }, markClean: { $0.needsSync = false }
        )
        try await pushDirty(
            FetchDescriptor<SavedCard>(predicate: #Predicate { $0.needsSync }),
            table: "saved_cards", context: context,
            row: { CardRow($0) }, markClean: { $0.needsSync = false }
        )
        try await pushDirty(
            FetchDescriptor<FavoriteVerse>(predicate: #Predicate { $0.needsSync }),
            table: "favorite_verses", context: context,
            row: { FavoriteRow($0) }, markClean: { $0.needsSync = false }
        )
        try await pushDirty(
            FetchDescriptor<SavedPrayer>(predicate: #Predicate { $0.needsSync }),
            table: "saved_prayers", context: context,
            row: { PrayerRow($0) }, markClean: { $0.needsSync = false }
        )
        try await pushTombstones(context: context)
    }

    /// `row` returns nil for rows that can't be uploaded (a message with no
    /// conversation); those are marked clean so they don't retry forever.
    private func pushDirty<M: PersistentModel, R: Encodable>(
        _ descriptor: FetchDescriptor<M>,
        table: String,
        context: ModelContext,
        row: (M) -> R?,
        markClean: (M) -> Void
    ) async throws {
        let dirty = try context.fetch(descriptor)
        guard !dirty.isEmpty else { return }
        let db = SupabaseService.shared.client
        for chunk in dirty.chunked(into: chunkSize) {
            let rows = chunk.compactMap(row)
            if !rows.isEmpty {
                try await db.from(table)
                    .upsert(rows, onConflict: "id", returning: .minimal)
                    .execute()
            }
            chunk.forEach(markClean)
            try context.save()
        }
        print("[Sync] pushed \(dirty.count) → \(table)")
    }

    private func pushTombstones(context: ModelContext) async throws {
        struct DeletedAt: Encodable { let deleted_at: Date }
        let tombstones = try context.fetch(FetchDescriptor<SyncTombstone>())
        guard !tombstones.isEmpty else { return }
        let db = SupabaseService.shared.client
        for (table, group) in Dictionary(grouping: tombstones, by: \.table) {
            for chunk in group.chunked(into: chunkSize) {
                // A row that never reached the server matches nothing — fine.
                try await db.from(table)
                    .update(DeletedAt(deleted_at: .now), returning: .minimal)
                    .in("id", values: chunk.map(\.id))
                    .execute()
                chunk.forEach { context.delete($0) }
                try context.save()
            }
        }
        print("[Sync] pushed \(tombstones.count) deletes")
    }

    // MARK: - Pull

    private func pull(userId: UUID, context: ModelContext) async throws {
        // Conversations first so incoming messages can attach to them.
        var conversations = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<ChatConversation>()).map { ($0.id, $0) }
        )
        try await pullTable("chat_conversations", userId: userId) { (rows: [ConversationRow]) in
            for r in rows {
                if r.deleted_at != nil {
                    if let local = conversations.removeValue(forKey: r.id) { context.delete(local) }
                } else if let local = conversations[r.id] {
                    guard !local.needsSync else { continue }
                    local.summary = r.summary
                    local.startedAt = r.started_at
                } else {
                    let conv = ChatConversation(id: r.id, startedAt: r.started_at, summary: r.summary)
                    conv.needsSync = false
                    context.insert(conv)
                    conversations[r.id] = conv
                }
            }
        }

        var messages = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<ChatMessage>()).map { ($0.id, $0) }
        )
        try await pullTable("chat_messages", userId: userId) { (rows: [MessageRow]) in
            for r in rows {
                if r.deleted_at != nil {
                    if let local = messages.removeValue(forKey: r.id) { context.delete(local) }
                } else if messages[r.id] == nil, let conv = conversations[r.conversation_id] {
                    // Messages are immutable once written — only new ones need applying.
                    let msg = ChatMessage(id: r.id, role: r.role, content: r.content, timestamp: r.sent_at, conversation: conv)
                    msg.needsSync = false
                    context.insert(msg)
                    messages[r.id] = msg
                }
            }
        }

        var cards = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<SavedCard>()).map { ($0.id, $0) }
        )
        try await pullTable("saved_cards", userId: userId) { (rows: [CardRow]) in
            for r in rows {
                if r.deleted_at != nil {
                    if let local = cards.removeValue(forKey: r.id) { context.delete(local) }
                } else if let local = cards[r.id] {
                    guard !local.needsSync else { continue }
                    local.verseReference = r.verse_reference
                    local.verseText = r.verse_text
                    local.templateID = r.template_id
                    local.isFavorite = r.is_favorite
                    local.contextNote = r.context_note
                } else {
                    let card = SavedCard(
                        id: r.id, verseReference: r.verse_reference, verseText: r.verse_text,
                        templateID: r.template_id, createdAt: r.created_at,
                        isFavorite: r.is_favorite, contextNote: r.context_note
                    )
                    card.needsSync = false
                    context.insert(card)
                    cards[r.id] = card
                }
            }
        }

        var favorites = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<FavoriteVerse>()).map { ($0.id, $0) }
        )
        try await pullTable("favorite_verses", userId: userId) { (rows: [FavoriteRow]) in
            for r in rows {
                if r.deleted_at != nil {
                    if let local = favorites.removeValue(forKey: r.id) { context.delete(local) }
                } else if favorites[r.id] == nil {
                    let verse = FavoriteVerse(id: r.id, reference: r.reference, text: r.text, savedAt: r.saved_at, source: r.source)
                    verse.needsSync = false
                    context.insert(verse)
                    favorites[r.id] = verse
                }
            }
        }

        var prayers = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<SavedPrayer>()).map { ($0.id, $0) }
        )
        try await pullTable("saved_prayers", userId: userId) { (rows: [PrayerRow]) in
            for r in rows {
                if r.deleted_at != nil {
                    if let local = prayers.removeValue(forKey: r.id) { context.delete(local) }
                } else if prayers[r.id] == nil {
                    let prayer = SavedPrayer(id: r.id, text: r.text, savedAt: r.saved_at, source: r.source, contextNote: r.context_note)
                    prayer.needsSync = false
                    context.insert(prayer)
                    prayers[r.id] = prayer
                }
            }
        }

        try context.save()
    }

    /// Pages through rows changed since this table's cursor, hands each page to
    /// `apply`, then advances the cursor to the newest `updated_at` seen.
    private func pullTable<R: Decodable & SyncedRow>(
        _ table: String,
        userId: UUID,
        apply: ([R]) throws -> Void
    ) async throws {
        let cursorKey = "sync.cursor.\(userId.uuidString).\(table)"
        let defaults = UserDefaults.standard
        let stored = defaults.object(forKey: cursorKey) as? Date

        let db = SupabaseService.shared.client
        var newest = stored
        var offset = 0
        var applied = 0
        while true {
            var query = db.from(table).select().eq("user_id", value: userId)
            if let stored {
                query = query.gt("updated_at", value: stored.addingTimeInterval(-cursorOverlap))
            }
            let page: [R] = try await query
                .order("updated_at", ascending: true)
                .range(from: offset, to: offset + pageSize - 1)
                .execute()
                .value
            try apply(page)
            applied += page.count
            if let last = page.last?.updated_at, last > (newest ?? .distantPast) { newest = last }
            if page.count < pageSize { break }
            offset += pageSize
        }
        if let newest { defaults.set(newest, forKey: cursorKey) }
        if applied > 0 { print("[Sync] pulled \(applied) ← \(table)") }
    }
}

// MARK: - Wire rows (snake_case = Supabase column names)

/// `updated_at` / `deleted_at` are only ever read: they're nil on push, so the
/// encoder omits them and the server keeps control of both.
private protocol SyncedRow {
    var updated_at: Date? { get }
}

private struct CardRow: Codable, SyncedRow {
    let id: UUID
    let verse_reference: String
    let verse_text: String
    let template_id: String
    let is_favorite: Bool
    let context_note: String?
    let created_at: Date
    var updated_at: Date? = nil
    var deleted_at: Date? = nil

    init(_ card: SavedCard) {
        id = card.id
        verse_reference = card.verseReference
        verse_text = card.verseText
        template_id = card.templateID
        is_favorite = card.isFavorite
        context_note = card.contextNote
        created_at = card.createdAt
    }
}

private struct FavoriteRow: Codable, SyncedRow {
    let id: UUID
    let reference: String
    let text: String
    let source: String
    let saved_at: Date
    var updated_at: Date? = nil
    var deleted_at: Date? = nil

    init(_ verse: FavoriteVerse) {
        id = verse.id
        reference = verse.reference
        text = verse.text
        source = verse.source
        saved_at = verse.savedAt
    }
}

private struct PrayerRow: Codable, SyncedRow {
    let id: UUID
    let text: String
    let source: String
    let context_note: String?
    let saved_at: Date
    var updated_at: Date? = nil
    var deleted_at: Date? = nil

    init(_ prayer: SavedPrayer) {
        id = prayer.id
        text = prayer.text
        source = prayer.source
        context_note = prayer.contextNote
        saved_at = prayer.savedAt
    }
}

private struct ConversationRow: Codable, SyncedRow {
    let id: UUID
    let summary: String?
    let started_at: Date
    var updated_at: Date? = nil
    var deleted_at: Date? = nil

    init(_ conv: ChatConversation) {
        id = conv.id
        summary = conv.summary
        started_at = conv.startedAt
    }
}

private struct MessageRow: Codable, SyncedRow {
    let id: UUID
    let conversation_id: UUID
    let role: String
    let content: String
    let sent_at: Date
    var updated_at: Date? = nil
    var deleted_at: Date? = nil

    init?(_ msg: ChatMessage) {
        guard let conversationID = msg.conversation?.id else { return nil }
        id = msg.id
        conversation_id = conversationID
        role = msg.role
        content = msg.content
        sent_at = msg.timestamp
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
