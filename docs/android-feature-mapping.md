# Seek iOS → Android Feature Mapping for Parity Implementation

## Overview
This document maps each Seek iOS feature to its Android implementation requirements. File paths are from iOS; Android equivalents should follow Google/Jetpack conventions (Compose for UI, Room for local persistence, Retrofit/OkHttp for API).

---

## 1. Streak Tracking

### iOS Implementation
**Files:**
- `/Seek/Services/StreakManager.swift` (entire file, 73 lines)
- `/Seek/Models/UserProfile.swift` (lines 14-21): `streakCount`, `longestStreak`, `lastActiveDate`

**Data Model (SwiftData):**
```swift
@Model final class UserProfile {
    var streakCount: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: Date?
    var dailyChatsResetDate: Date  // for daily chat counter reset
}
```

**Core Logic (StreakManager.swift, lines 9-56):**
- `recordActivity(modelContext:)` — static @MainActor function, called from HomeView.task
- Checks if already recorded today (line 15-18): compares `lastActiveDate` with today
- If consecutive day: increment `streakCount` (line 24-25)
- If grace period (missed exactly 1 day, active 2 days ago): increment streak (line 28-32)
- If streak broken (>1 day gap): reset to 1 (line 33-35)
- First activity: set to 1 (line 39-40)
- Update `longestStreak` if streak exceeds previous max (line 43-46)
- Update `lastActiveDate` to today (line 48)
- Reset daily chat counter if new day (line 51-54)

**Milestones (StreakManager.swift, lines 60-62):**
```swift
static func checkMilestone(streakCount: Int) -> Int? {
    let milestones = [7, 30, 90, 365]
    return milestones.contains(streakCount) ? streakCount : nil
}
```

**Trigger Points (HomeView.swift, line 204):**
- Called in `.task` on HomeView appear
- Only for signed-in users (line 203): `if !authManager.isGuest`

**Supabase Server-Side (profiles table):**
- `streak_count int default 0`
- `longest_streak int default 0`
- `last_active_date DATE`
- Auto-synced but NOT the source of truth — local SwiftData is primary

### Android Implementation Requirements
- **Local Storage (Room):**
  - UserProfile entity with `streakCount`, `longestStreak`, `lastActiveDate`, `dailyChatsResetDate`
  - @PrimaryKey on userId (synced from Auth)
  
- **Logic:**
  - `StreakManager` object/class with `recordActivity()` function
  - Same grace-period logic: check if lastActiveDate is exactly yesterday (consecutive) or 2 days ago (grace period)
  - Same milestone check: [7, 30, 90, 365]
  - Same daily-chat-count reset logic
  
- **Trigger:**
  - Call from HomeScreen's LaunchedEffect or similar on first compose
  - Gate on `!isGuest` (only for authenticated users)
  
- **Sync:**
  - On app launch or periodically, upsert local streakCount/longestStreak/lastActiveDate to Supabase profiles table
  - Supabase is secondary storage for cross-device continuity

---

## 2. Translation Switching (NLT/KJV)

### iOS Implementation
**Files:**
- `/Seek/Models/BibleTranslation.swift` (entire file, 15 lines)
- `/Seek/Views/Profile/ProfileView.swift` (lines 230-250): TranslationPickerView
- `/Seek/Models/UserProfile.swift` (line 21): `preferredTranslation: String = "NLT"`
- `/Seek/Services/SupabaseService.swift` (lines 101-143): API integration

**Enum (BibleTranslation.swift):**
```swift
enum BibleTranslation: String, Codable, CaseIterable, Identifiable {
    case nlt = "NLT"
    case kjv = "KJV"
    
    var displayName: String {
        switch self {
        case .nlt: return "New Living Translation"
        case .kjv: return "King James Version"
        }
    }
}
```

**Storage (UserProfile.swift, line 21):**
- `preferredTranslation: String = "NLT"` stored in local SwiftData
- Persisted to Supabase `profiles.preferred_translation` (line 132, SupabaseService.swift)

**Settings UI (ProfileView.swift, lines 230-250):**
- List of BibleTranslation.allCases
- Tap to select → updates local profile (line 244) + Supabase (line 247)

**Chat Integration (ChatView.swift, line 601; SupabaseService.swift, line 101):**
- Passed to `sendChatMessage(..., translation: profile?.preferredTranslation ?? "NLT")`
- Forwarded to Edge Function as parameter
- Edge Function filters verses by translation + builds system prompt for the selected translation

**Daily Verse (SupabaseService.swift, lines 117-122; Edge Function):**
- `fetchDailyVerse()` sends auth token
- Edge Function looks up user's `preferred_translation` from Supabase profiles
- Returns verses in that translation

### Android Implementation Requirements
- **Sealed Class/Enum:**
  - `BibleTranslation` with `NLT`, `KJV` cases
  - Each has a `displayName` property
  
- **Storage (Room):**
  - UserProfile entity with `preferredTranslation: String = "NLT"`
  
- **Settings Screen:**
  - List of BibleTranslation options (radio button or segmented control)
  - Tap → update local Room + Supabase via `updatePreferredTranslation(userId, translation)`
  
- **Chat Flow:**
  - Pass `userProfile.preferredTranslation` (or cached value) to `sendChatMessage()` API
  - Retrofit request includes `translation` parameter in body
  
- **Daily Verse:**
  - Auth token auto-included by Supabase client
  - Edge Function returns translation based on user's profile

---

## 3. Action Steps in Chat

### iOS Implementation
**Files:**
- `/Seek/Services/SupabaseService.swift` (lines 215-219): ActionStep struct
- `/Seek/Views/Chat/ChatView.swift` (lines 423-454): actionCard composable

**Data Structure (SupabaseService.swift, lines 215-219):**
```swift
struct ActionStep: Codable {
    let title: String        // e.g., "Release + Move"
    let steps: [String]      // e.g., ["Take a 10-min walk", "Call a friend"]
    let reason: String       // e.g., "Physical movement can ease anxiety"
}
```

**Response Integration (SupabaseService.swift, line 211):**
- Part of ChatResponse: `action: ActionStep?` (optional)

**Display (ChatView.swift, lines 423-454):**
- Header: `Label(action.title, systemImage: "figure.walk")` — sage green
- Steps: enumerated list with numbered circles (1, 2, 3, etc.)
  - Each step in a VStack with top alignment and 10pt spacing
  - Number displayed in white text on sage green circle background
  - Step text in subheadline weight
- Reason: italicized caption below steps in gray
- Overall background: sage green at 0.08 opacity, 12px corner radius

**Trigger in Chat (ChatView.swift, line 701-704):**
- Appended after prayer/song with 280ms coda delay
- Spring animation insertion from leading edge

### Android Implementation Requirements
- **Data Class:**
  - `data class ActionStep(val title: String, val steps: List<String>, val reason: String)`
  - Part of ChatResponse serialization
  
- **UI Composable:**
  - Card with sage-green tinted background (8% opacity)
  - Header row: walk icon + title in sage green, semibold
  - Steps column:
    - Numbered circles (1, 2, 3...) with white text on sage background
    - Each step text indented/aligned to right of circle
    - 8pt spacing between steps
  - Reason text: italicized, gray, below steps
  - 12pt corner radius, consistent padding with other chat cards
  
- **Animation:**
  - Slide in from leading edge (left, LTR) after prayer card
  - Spring entrance animation

---

## 4. Worship Song Deep Links

### iOS Implementation
**Files:**
- `/Seek/Services/SupabaseService.swift` (lines 228-232): WorshipSong struct
- `/Seek/Views/Chat/ChatView.swift` (lines 368-421): worshipSongCard composable

**Data Structure (SupabaseService.swift, lines 228-232):**
```swift
struct WorshipSong: Codable {
    let title: String       // e.g., "Oceans"
    let artist: String      // e.g., "Hillsong"
    let context: String     // e.g., "For when you're afraid"
}
```

**Response Integration (SupabaseService.swift, line 209):**
- Part of ChatResponse: `worshipSong: WorshipSong?` (optional)

**Display & Deep Links (ChatView.swift, lines 368-421):**

**Apple Music Link (lines 386-390):**
```swift
let query = "\(song.title) \(song.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
if let url = URL(string: "music://music.apple.com/search?term=\(query)") {
    UIApplication.shared.open(url)
}
```

**Spotify Link (lines 397-408):**
```swift
let query = "\(song.title) \(song.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
// Try Spotify app deep link first
if let url = URL(string: "spotify:search:\(query)") {
    UIApplication.shared.open(url) { success in
        if !success {
            // Fallback to web if app not installed
            if let webURL = URL(string: "https://open.spotify.com/search/\(query)") {
                UIApplication.shared.open(webURL)
            }
        }
    }
}
```

**Card UI (lines 369-421):**
- Header: music note icon + "Worship Song" label in sage green, caption weight
- Title: song.title in subheadline bold
- "by Artist" subtitle in caption gray
- Context line: caption gray
- Two buttons below: "Apple Music" and "Spotify"
  - Apple Music button: music note icon, sage green text
  - Spotify button: play circle icon, Spotify green (#1DB954) text
- Background: sage green at 6% opacity, 12px corner radius

**Trigger in Chat (ChatView.swift, line 694-698):**
- Appended after verses/prayer with 280ms coda delay
- Spring animation insertion from leading edge

### Android Implementation Requirements
- **Data Class:**
  - `data class WorshipSong(val title: String, val artist: String, val context: String)`
  
- **Deep Links:**
  - **Spotify:**
    - URI scheme: `spotify:search:{encoded_query}` (e.g., `spotify:search:Oceans%20Hillsong`)
    - Fallback: `https://open.spotify.com/search/{encoded_query}`
    - Test if Spotify app is installed before using deep link; fall back to web if not
  - **Apple Music:**
    - iOS only via Music.app. On Android:
      - Option A: Link to `https://music.apple.com/us/album/{song_id}` (if Claude provides IDs)
      - Option B: Link to Apple Music search: `https://music.apple.com/search?term={encoded_query}`
      - Option C: Link to Spotify instead (Android has no native Music.app)
      - **Recommendation:** For Android, provide Spotify link + fallback to web Apple Music search
  
- **UI Composable:**
  - Card with music note icon + "Worship Song" in sage green
  - Title bold, artist in gray, context in gray
  - Two clickable buttons: one for Spotify, one for Apple Music (or alternate based on availability)
  - Colors: Spotify green (#1DB954), sage green for Apple Music button
  - 12pt corner radius, consistent padding

---

## 5. Card Templates

### iOS Implementation
**File:**
- `/Seek/CardTemplates/CardTemplate.swift` (entire file, 205 lines)

**Data Structure (lines 4-46):**
```swift
struct CardTemplate: Identifiable {
    let id: String
    let name: String
    let category: Category
    let isPremium: Bool
    let backgroundColor: Color
    let backgroundGradient: [Color]?
    let textColor: Color
    let referenceColor: Color
    let fontName: String
    let accentElements: AnyView?
}
```

**Categories (lines 16-20):**
- `.nature` — 5 templates
- `.minimal` — 5 templates
- `.watercolor` — 4 templates
- `.bold` — 4 templates
- **Total: 18 templates**

**All Templates (lines 52-200):**

**Nature (5):**
1. Ocean (`nature_ocean`) — Blue gradient [#1A3A5C → #5B7B5E → #8AAF8D], white text
2. Sunrise (`nature_sunrise`) — Gold gradient [#1A1A2E → #CDA349 → #F5C882], white text
3. Forest (`nature_forest`) — Green gradient [#1A2E0A → #2D5016 → #4A7A28], white text
4. Mountain (`nature_mountain`) — Gray gradient [#1F2937 → #3B4856 → #6B7280], white text, **PREMIUM**
5. Sky (`nature_sky`) — Blue gradient [#2563EB → #5B9BD5 → #93C5FD], white text

**Minimal (5):**
1. Cream (`minimal_cream`) — #FAF7F0 background, dark text #1A1A1A, sage reference #5B7B5E
2. Navy (`minimal_navy`) — #1A2744 background, white text
3. Sage (`minimal_sage`) — #D4DDD2 background, dark text #2D3A2D, dark sage reference #4A6741
4. Blush (`minimal_blush`) — #F5E6E0 background, dark text #5C3D3D, muted reference #8B5E5E, **PREMIUM**
5. Charcoal (`minimal_charcoal`) — #2D2D2D background, white text

**Watercolor (4):**
1. Lavender (`watercolor_lavender`) — #E8D5F5 background, dark text #3D2A52, reference #6B4D8A
2. Peach (`watercolor_peach`) — #FDDCBD background, dark text #5C3A1A, reference #8B6840
3. Seafoam (`watercolor_seafoam`) — #C5E8E0 background, dark text #1A3D35, reference #2C5F52, **PREMIUM**
4. Rose (`watercolor_rose`) — #F5C6D0 background, dark text #5C1A2A, reference #8B3D52, **PREMIUM**

**Bold (4):**
1. Midnight (`bold_black`) — Black background, gold reference #CDA349, Helvetica-Bold font
2. Royal (`bold_royal`) — Purple gradient [#1E0A3C → #4A1A7A], gold reference #CDA349
3. Fire (`bold_fire`) — Red-gold gradient [#8B0000 → #CDA349], white text, **PREMIUM**
4. Gold (`bold_gold`) — Dark-tan gradient [#1A1A1A → #3D3520], gold reference #CDA349, **PREMIUM**

**Static Accessors (lines 202-203):**
- `CardTemplate.all` — all 18 templates
- `CardTemplate.free` — 12 non-premium templates
- `CardTemplate.premium` — 6 premium-only templates

### Android Implementation Requirements
- **Data Class:**
  - `data class CardTemplate(val id: String, val name: String, val category: String, val isPremium: Boolean, val backgroundColor: Int, val backgroundGradient: List<Int>?, val textColor: Int, val referenceColor: Int, val fontName: String)`
  
- **Enum for Categories:**
  - `enum class Category { NATURE, MINIMAL, WATERCOLOR, BOLD }`
  
- **Template List:**
  - Define all 18 templates as static constants or in a companion object
  - Store in a list/map for easy lookup by ID
  - Provide `all`, `free`, `premium` accessors
  
- **Color Storage:**
  - Convert hex strings to `@ColorInt` integers
  - Example: `#CDA349` → parse as hex to Int
  
- **Gradient Support:**
  - Optional gradient list for templates that use multi-color backgrounds
  - For rendering, create a LinearGradient brush or similar Compose mechanism

---

## 6. Prayer → Card

### iOS Implementation
**Files:**
- `/Seek/Views/CardCreator/CardCreatorView.swift` (lines 39-44): prayerText init
- `/Seek/Views/Chat/ChatView.swift` (lines 341-359, 848-861): prayer card + togglePrayerFavorite

**Initializer (CardCreatorView.swift, lines 39-44):**
```swift
init(prayerText: String) {
    self.verseReference = "A Prayer"
    self.verseText = prayerText
    self.verseContext = nil
    self._selectedTemplate = State(initialValue: CardTemplate.all[0])
}
```
- Prayer text is treated as the verse body
- Reference line is hardcoded to "A Prayer"
- No interpretation available (verseContext = nil)
- Defaults to first template

**Prayer Card in Chat (ChatView.swift, lines 328-366):**
- Label: "Prayer" with hands.sparkles icon in gold
- Text: prayerText rendered in italic Georgia 15pt
- Favorite + Create Card buttons below
- Background: gold at 8% opacity

**Sheet Trigger (ChatView.swift, lines 165-167):**
```swift
.sheet(item: $selectedPrayer) { target in
    CardCreatorView(prayerText: target.text)
}
```

**Toggle Favorite (ChatView.swift, lines 848-861):**
```swift
private func togglePrayerFavorite(_ prayerText: String) {
    if let existing = savedPrayers.first(where: { $0.text == prayerText }) {
        modelContext.delete(existing)
    } else {
        modelContext.insert(
            SavedPrayer(
                text: prayerText,
                source: "chat",
                contextNote: lastUserPrompt  // the user's question that prompted this prayer
            )
        )
    }
    try? modelContext.save()
}
```

### Android Implementation Requirements
- **Navigation:**
  - CardCreatorView alternate constructor that accepts `prayerText: String`
  - Sets verseReference = "A Prayer", verseText = prayerText, context = null
  
- **UI:**
  - Render prayer card in chat with "A Prayer" as header + hands.sparkles icon
  - Italic rendering for prayer text (distinct from verse)
  - Favorite + Create Card buttons
  
- **Favorite Logic:**
  - SavedPrayer table in Room with: id, text, savedAt, source ("chat"), contextNote (optional, the user prompt)
  - togglePrayerFavorite checks if SavedPrayer with this text exists; delete if yes, insert if no

---

## 7. Favoriting Verses + Prayers

### iOS Implementation
**Files:**
- `/Seek/Models/FavoriteVerse.swift` (entire file, 26 lines)
- `/Seek/Models/SavedPrayer.swift` (entire file, 25 lines)
- `/Seek/Views/Chat/ChatView.swift` (lines 299-306, 837-844, 848-861): toggleFavorite/togglePrayerFavorite
- `/Seek/Views/Library/LibraryView.swift` (lines 235-447): FavoritesListView with filtering

**FavoriteVerse Model (FavoriteVerse.swift):**
```swift
@Model final class FavoriteVerse {
    @Attribute(.unique) var id: UUID
    var reference: String
    var text: String
    var savedAt: Date
    var source: String  // "chat", "daily_verse"
}
```

**SavedPrayer Model (SavedPrayer.swift):**
```swift
@Model final class SavedPrayer {
    @Attribute(.unique) var id: UUID
    var text: String
    var savedAt: Date
    var source: String = "chat"
    var contextNote: String? = nil  // the user prompt that produced it
}
```

**Toggle Verse (ChatView.swift, lines 837-844):**
```swift
private func toggleFavorite(_ verse: VerseResult) {
    if let existing = favoriteVerses.first(where: { $0.reference == verse.reference }) {
        modelContext.delete(existing)
    } else {
        modelContext.insert(FavoriteVerse(reference: verse.reference, text: verse.text, source: "chat"))
    }
    try? modelContext.save()
}
```

**Verse Button (ChatView.swift, lines 299-306):**
```swift
Button {
    toggleFavorite(verse)
} label: {
    let isFav = favoriteVerses.contains { $0.reference == verse.reference }
    Label("Favorite", systemImage: isFav ? "heart.fill" : "heart")
        .font(.caption2.weight(.medium))
        .foregroundStyle(Color(hex: "CDA349"))
}
.buttonStyle(.plain)
```

**Library Favorites Tab (LibraryView.swift, lines 235-447):**

**Filter Enum (lines 235-239):**
```swift
enum FavoritesFilter: String, CaseIterable {
    case all = "All"
    case verses = "Verses"
    case prayers = "Prayers"
}
```

**Merged Item Type (lines 241-259):**
```swift
enum FavoriteItem: Identifiable {
    case verse(FavoriteVerse)
    case prayer(SavedPrayer)
    
    var id: String {
        switch self {
        case .verse(let v): return "v-\(v.id.uuidString)"
        case .prayer(let p): return "p-\(p.id.uuidString)"
        }
    }
    
    var savedAt: Date {
        switch self {
        case .verse(let v): return v.savedAt
        case .prayer(let p): return p.savedAt
        }
    }
}
```

**Filter Logic (lines 268-277):**
- Merges verses and prayers based on filter selection
- Sorts by savedAt descending (newest first)
- Returns combined, sorted list

**Filter Chips (lines 306-330):**
- Three capsule buttons: All, Verses, Prayers
- Tap to filter; active state shown with filled background

**Rows (lines 360-432):**
- **Verse Row:** reference bold in sage, text in Georgia, source tag (Verse/Daily Verse), Create Card button
- **Prayer Row:** "A Prayer" with hands.sparkles icon in gold, prayer text italic, Prayer tag, Create Card button

**Delete (lines 436-447):**
- SwiftUI List swipe-to-delete on items
- Deletes from Room based on item type

### Android Implementation Requirements
- **Room Entities:**
  - `FavoriteVerse`: id (UUID/String PK), reference, text, savedAt, source ("chat"/"daily_verse")
  - `SavedPrayer`: id (UUID/String PK), text, savedAt, source ("chat"), contextNote (nullable)
  
- **Favorite Toggle:**
  - Check if exists by reference (verse) or text (prayer)
  - Delete if exists; insert if doesn't
  - Use Room DAO for insert/delete operations
  
- **Library Favorites Tab:**
  - Filter enum: ALL, VERSES, PRAYERS
  - Merged data class that can hold either FavoriteVerse or SavedPrayer (sealed class or union type)
  - Query both tables and merge results
  - Sort by savedAt descending
  
- **Filter Chips:**
  - Three buttons (All/Verses/Prayers)
  - Tap to update filter state
  - UI updates to show filtered list
  
- **Rows:**
  - Verse row: reference bold (sage), text (Georgia), source tag, Create Card button
  - Prayer row: "A Prayer" + hands.sparkles icon (gold), prayer text italic, Prayer tag, Create Card button
  
- **Delete:**
  - Swipe-to-dismiss or long-press delete
  - Call DAO delete method for the appropriate entity type

---

## 8. Library Card Edit/Delete

### iOS Implementation
**Files:**
- `/Seek/Views/Library/LibraryView.swift` (lines 58-209): CardsGridView

**Navigation Link to Re-Edit (lines 150-156):**
```swift
NavigationLink {
    CardCreatorView(
        verseReference: card.verseReference,
        verseText: card.verseText,
        initialTemplateID: card.templateID
    )
} label: {
    cardThumbnailContent(card)
}
```

**Initialization in CardCreatorView (lines 26-34):**
```swift
init(verseReference: String, verseText: String, verseContext: String? = nil, initialTemplateID: String? = nil) {
    self.verseReference = verseReference
    self.verseText = verseText
    self.verseContext = verseContext
    let starting = initialTemplateID.flatMap { id in CardTemplate.all.first { $0.id == id } } ?? CardTemplate.all[0]
    self._selectedTemplate = State(initialValue: starting)
}
```
- If initialTemplateID provided, preselect that template
- Otherwise default to first template

**Long-Press Edit Mode (lines 160-166):**
```swift
.onLongPressGesture(minimumDuration: 0.5) {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        isEditing = true
    }
}
```
- 0.5s press to enter edit mode
- Haptic feedback triggered
- Spring animation enables wiggle

**Edit Mode Visual (lines 124-146):**
- CardThumbnail wrapped with overlay
- Red minus.circle.fill badge on top-right
- WiggleEffect applied (lines 216-230: continuous rotation animation)
- Tap badge → confirmation alert → delete

**Delete Logic (lines 106-120):**
```swift
.alert("Delete card?", isPresented: Binding(...)) {
    Button("Cancel", role: .cancel) { pendingDeleteCard = nil }
    Button("Delete", role: .destructive) {
        if let card = pendingDeleteCard {
            modelContext.delete(card)
            try? modelContext.save()
        }
        pendingDeleteCard = nil
    }
}
```

**Done Button to Exit Edit Mode (lines 94-104):**
- Visible only when isEditing = true
- Tap to exit edit mode with spring animation

**Context Menu Copy (lines 167-172):**
- Right-click/long-press (non-edit mode): copy verse text + reference to clipboard

### Android Implementation Requirements
- **Navigation:**
  - Card tap → CardCreatorView with verseReference, verseText, and initialTemplateID
  
- **Template Preselection:**
  - If initialTemplateID passed, find matching template and select it
  - Otherwise default to first template
  
- **Edit Mode:**
  - Long-press card (0.5s): vibrate + enable edit mode
  - All cards show red delete badge in edit mode
  - Tap badge → confirmation dialog → delete from Room
  
- **Animations:**
  - Wiggle effect: continuous rotation animation (similar to iOS Home Screen delete mode)
  - Spring exit animation when leaving edit mode
  
- **Done Button:**
  - Show Done button in top-right only in edit mode
  - Tap → exit edit mode
  
- **Copy to Clipboard:**
  - In non-edit mode, long-press context menu with "Copy verse" option
  - Copies "`verseText\n— reference`" to clipboard

---

## 9. Profile Stats

### iOS Implementation
**File:**
- `/Seek/Views/Profile/ProfileView.swift` (lines 118-131): Stats section

**Stats Displayed (lines 118-131):**
```swift
Section("Stats") {
    HStack {
        Label("\(profile?.streakCount ?? 0)-day streak", systemImage: "flame.fill")
        Spacer()
        if let longest = profile?.longestStreak, longest > 0 {
            Text("Best: \(longest)")
                .font(.caption)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
    }
    Label("\(profile?.totalVersesExplored ?? 0) verses explored", systemImage: "book.closed")
    Label("\(profile?.totalCardsCreated ?? 0) cards created", systemImage: "rectangle.on.rectangle")
}
```

**Data Sources (UserProfile.swift):**
- `streakCount: Int` — current streak
- `longestStreak: Int` — best streak ever
- `totalVersesExplored: Int` — cumulative verses from all chats (bumped in ChatView.renderResponse, line 731)
- `totalCardsCreated: Int` — cumulative cards saved (bumped on SavedCard insert)

**Update Triggers:**
- `streakCount` / `longestStreak` — StreakManager.recordActivity()
- `totalVersesExplored` — ChatView.renderResponse(), line 731: `profile.totalVersesExplored += response.verses.count`
- `totalCardsCreated` — CardCreatorView save action (not shown in snippet but persists SavedCard to Room)

### Android Implementation Requirements
- **Profile Stats UI:**
  - Flame icon + current streak + best streak on same line
  - Book icon + total verses explored
  - Rectangle icon + total cards created
  
- **Data Updates:**
  - After each chat response: increment totalVersesExplored by response.verses.size
  - After each card save: increment totalCardsCreated by 1
  - StreakManager handles streakCount / longestStreak
  
- **Display:**
  - Read from UserProfile (Room entity)
  - Update local Room after each action
  - Periodically sync to Supabase profiles table for cross-device continuity

---

## 10. Settings Extras

### iOS Implementation
**Files:**
- `/Seek/Views/Profile/ProfileView.swift` (lines 152-165): Rate/Share/Legal
- `/Seek/Views/Profile/WebContentView.swift`: WKWebView wrapper for Privacy/Terms

**Rate/Review (lines 152-157):**
```swift
Button {
    requestReview()
} label: {
    Label("Rate Seek", systemImage: "star")
        .foregroundStyle(Color(hex: "1A1A1A"))
}

private func requestReview() {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        AppStore.requestReview(in: windowScene)
    }
}
```
- Uses StoreKit 2's `AppStore.requestReview()` to open App Store review prompt

**Share App (lines 159-164):**
```swift
ShareLink(
    item: URL(string: "https://apps.apple.com/us/app/seek-scripture-companion/id6761785270")!,
    message: Text("I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.")
) {
    Label("Share Seek", systemImage: "square.and.arrow.up")
}
```
- SwiftUI ShareLink with App Store URL + prepopulated message
- Opens iOS share sheet

**Privacy/Terms Links (lines 169-178):**
```swift
NavigationLink {
    WebContentView(title: "Privacy Policy", urlString: "https://askseekpray.app/privacy")
} label: {
    Label("Privacy Policy", systemImage: "lock.shield")
}
NavigationLink {
    WebContentView(title: "Terms of Service", urlString: "https://askseekpray.app/terms")
} label: {
    Label("Terms of Service", systemImage: "doc.text")
}
```
- NavigationLink to WebContentView (WKWebView wrapper)
- URLs are live (production domain askseekpray.app)

### Android Implementation Requirements
- **Rate/Review:**
  - Use Google Play's In-App Review API
  - Call `ReviewManager.launchReview()` to open review prompt in-app
  - Graceful fallback: link to Play Store listing if API unavailable
  
- **Share App:**
  - Intent.ACTION_SEND with Play Store URL: `https://play.google.com/store/apps/details?id=com.loucesario.seek`
  - Prepopulated message: same as iOS
  - Opens OS share sheet
  
- **Privacy/Terms:**
  - WebView composable that loads live URLs
  - Navigate to `` https://askseekpray.app/privacy`` and `https://askseekpray.app/terms`
  - Back button to dismiss

---

## 11. Share-with-a-Friend on Home

### iOS Implementation
**File:**
- `/Seek/Views/Home/HomeView.swift` (lines 315-331)

**Component (lines 315-331):**
```swift
private var shareWithFriend: some View {
    ShareLink(
        item: URL(string: "https://apps.apple.com/us/app/seek-scripture-companion/id6761785270")!,
        message: Text("I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.")
    ) {
        HStack(spacing: 8) {
            Image(systemName: "heart.text.square")
            Text("Share Seek with a friend")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Color(hex: "5B7B5E"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "5B7B5E").opacity(0.08), in: Capsule())
    }
    .padding(.horizontal)
}
```

**Placement (HomeView.swift, line 98):**
- Inserted between Daily Verse card and Quick Prompts grid
- Same layout flow as other Home sections

**Styling:**
- Heart.text.square icon + "Share Seek with a friend" text
- Sage green text, subheadline weight
- Capsule button background with sage at 8% opacity
- Full width (maxWidth .infinity)
- 12pt vertical padding

**Trigger:**
- Tap → iOS share sheet with prepopulated URL + message

### Android Implementation Requirements
- **Composable:**
  - Heart/share icon + "Share Seek with a friend" text in sage green
  - Capsule button with sage background (8% opacity)
  - Full width, 12pt vertical padding
  
- **Action:**
  - Tap → Intent.ACTION_SEND with Play Store URL + message
  - Opens OS share sheet
  
- **Placement:**
  - Between Daily Verse card and Quick Prompts grid on HomeScreen

---

## 12. Onboarding Personalization + Notifications

### iOS Implementation
**File:**
- `/Seek/Views/Onboarding/OnboardingView.swift` (entire file)

**Topics Array (lines 10-16):**
```swift
private let topics = [
    ("Daily encouragement", "sun.max"),
    ("Celebrating a season of blessing", "party.popper"),
    ("Going through something hard", "heart"),
    ("Sharing scripture with others", "square.and.arrow.up"),
    ("Growing deeper in faith", "leaf"),
]
```

**Personalization Page (lines 101-147):**
```swift
private var personalizationPage: some View {
    VStack(spacing: 24) {
        Spacer().frame(height: 60)
        
        Text("What brings you here?")
            .font(.title2.bold())
        
        Text("Select all that apply — this helps us personalize your experience")
            .font(.subheadline)
        
        VStack(spacing: 12) {
            ForEach(topics, id: \.0) { topic, icon in
                Button {
                    if selectedTopics.contains(topic) {
                        selectedTopics.remove(topic)
                    } else {
                        selectedTopics.insert(topic)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .frame(width: 24)
                        Text(topic)
                            .font(.body)
                        Spacer()
                        if selectedTopics.contains(topic) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "5B7B5E"))
                        }
                    }
                    .padding()
                    .background(
                        selectedTopics.contains(topic)
                            ? Color(hex: "5B7B5E").opacity(0.08)
                            : Color(hex: "F3F4F6")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(Color(hex: "1A1A1A"))
            }
        }
        .padding(.horizontal, 24)
        
        Spacer()
        
        Button { withAnimation { currentPage = 2 } } label: {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(hex: "5B7B5E"))
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
```

**Selection Logic:**
- Set<String> for selectedTopics
- Tap topic → toggle in set
- Checkmark shown if selected
- Background highlight if selected
- Continue button proceeds to next page

**Notification Page (referenced, lines 31 in switch statement):**
- Requests notification permission
- Defaults: daily verse 7am, streak nudge 7pm
- Wired via `notificationPage` (not shown, but see NotificationSettingsView for the UI pattern)

**Onboarding Completion:**
- After Welcome → SignIn → Personalization → Notifications
- Save selectedTopics to local UserProfile
- Call SupabaseService.ensureRemoteProfile with selectedTopics array (line 32, SupabaseService.swift):
```swift
func ensureRemoteProfile(userId: String, email: String, displayName: String, preferredTranslation: String = "NLT") async throws {
    try await client.from("profiles")
        .upsert(["id": AnyJSON.string(userId), ..., "onboarding_topics": AnyJSON.array(topics.map(AnyJSON.string))])
        .execute()
}
```

### Android Implementation Requirements
- **Topics List:**
  - Define as list of Pair<String, String> (topic, icon_name)
  - Same 5 topics as iOS
  
- **Personalization Screen:**
  - Title: "What brings you here?"
  - Subtitle: "Select all that apply..."
  - Buttons for each topic (row layout)
  - Toggle on/off with visual feedback (background highlight + checkmark)
  - Selected topics added to Set<String>
  - Continue button → next onboarding page
  
- **Data Persistence:**
  - Save selectedTopics as List<String> in local UserProfile (Room)
  - On account creation, POST to Supabase profiles with onboarding_topics array
  
- **Notification Setup:**
  - Request NotificationManager permissions
  - Set defaults (7am daily verse, 7pm streak nudge)
  - Persist preferences to Supabase notification_settings table
  
- **Notification Page:**
  - Time pickers for daily verse time + streak nudge time
  - Toggles for enable/disable each notification type
  - See NotificationSettingsView pattern (not fully detailed in iOS code, but same concept)

---

## Summary: Implementation Checklist for Android

### Core Data Models (Room)
- [ ] UserProfile (id, displayName, email, profileImageURL, createdAt, isPremium, premiumExpiresAt, onboardingTopics, streakCount, longestStreak, lastActiveDate, totalVersesExplored, totalCardsCreated, dailyChatsUsed, dailyChatsResetDate, preferredTranslation)
- [ ] SavedCard (id, verseReference, verseText, templateID, createdAt, isFavorite, contextNote)
- [ ] ChatConversation (id, startedAt, messages)
- [ ] ChatMessage (id, role, content, timestamp, conversationId)
- [ ] FavoriteVerse (id, reference, text, savedAt, source)
- [ ] SavedPrayer (id, text, savedAt, source, contextNote)

### Managers/Services
- [ ] StreakManager (recordActivity, checkMilestone)
- [ ] BibleTranslation (enum: NLT, KJV)
- [ ] CardTemplate (18 templates, all categories)
- [ ] SupabaseService API calls (sendChatMessage with translation param, fetchDailyVerse, updatePreferredTranslation)

### UI Composables
- [ ] HomeScreen (daily verse, streak, share-with-friend, quick prompts, custom input)
- [ ] ChatScreen (messages, verses card, prayer card, worship song card with deep links, action steps card, input bar, offline banner)
- [ ] CardCreatorScreen (template picker, preview, save/share for both verse and prayer)
- [ ] LibraryScreen (cards grid with re-edit + delete, favorites list with filter chips, history)
- [ ] ProfileScreen (stats, settings, rate/review, share, privacy/terms/web links)
- [ ] OnboardingScreen (welcome, sign-in, personalization topics, notifications)
- [ ] TranslationPickerScreen (NLT/KJV radio selection)
- [ ] NotificationSettingsScreen (toggles + time pickers)

### Specific Feature Implementations
- [ ] Streak tracking: grace period logic, milestone detection, daily chat reset
- [ ] Translation switching: pass to API, store in profile
- [ ] Action steps: parse from response, render with numbered steps
- [ ] Worship song: Spotify deep link with fallback, Apple Music web link (or Spotify-only on Android)
- [ ] Card templates: all 18 with gradients, premium lock overlay
- [ ] Prayer card creation: reuse verse templates with "A Prayer" reference
- [ ] Favoriting: toggle FavoriteVerse/SavedPrayer on heart tap
- [ ] Library favorites: merge verses/prayers, filter by All/Verses/Prayers, swipe-to-delete
- [ ] Card edit/delete: long-press enter edit mode, wiggle animation, red delete badge, confirmation dialog
- [ ] Profile stats: display streakCount, longestStreak, totalVersesExplored, totalCardsCreated
- [ ] Settings: rate via Play Store In-App Review API, share via intent, webview for privacy/terms
- [ ] Share-with-friend: home screen capsule button, opens intent with Play Store URL
- [ ] Onboarding: 5-topic multi-select page + notification permission + defaults

---

## Cross-Platform Consistency Notes
- **Colors:** All hex values are exact iOS matches (sage #5B7B5E, gold #CDA349, cream #FAFAF6, etc.)
- **Fonts:** Use system fonts (Roboto/sans-serif on Android) for UI; Georgia/serif for scripture text when available
- **Spacing:** 4px base grid (iOS also uses this)
- **Animations:** Spring animations (insertion/removal), fade-in for content, wiggle for edit mode
- **Deep Links:** Spotify URI scheme + web fallback; Apple Music is web-only on Android
- **Rate/Review:** Play Store In-App Review API is Android equivalent of StoreKit 2
- **Share:** Android Intent.ACTION_SEND is equivalent of iOS ShareLink

