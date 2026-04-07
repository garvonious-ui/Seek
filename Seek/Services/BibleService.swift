import Foundation

/// Loads and queries the bundled KJV Bible JSON
class BibleService {
    static let shared = BibleService()

    private var bible: BibleData?

    private init() {
        loadBible()
    }

    private func loadBible() {
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "json") else {
            print("Error: kjv.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            bible = try JSONDecoder().decode(BibleData.self, from: data)
        } catch {
            print("Error loading Bible data: \(error)")
        }
    }

    func verse(book: String, chapter: Int, verse: Int) -> String? {
        guard let bible else { return nil }
        return bible.books
            .first { $0.name.lowercased() == book.lowercased() }?
            .chapters.first { $0.number == chapter }?
            .verses.first { $0.number == verse }?
            .text
    }

    func bookNames() -> [String] {
        bible?.books.map(\.name) ?? []
    }
}

// MARK: - Bible Data Models

struct BibleData: Codable {
    let books: [BibleBook]
}

struct BibleBook: Codable {
    let name: String
    let abbreviation: String?
    let chapters: [BibleChapter]
}

struct BibleChapter: Codable {
    let number: Int
    let verses: [BibleVerse]
}

struct BibleVerse: Codable {
    let number: Int
    let text: String
}
