import Foundation

enum BibleTranslation: String, Codable, CaseIterable, Identifiable {
    case nlt = "NLT"
    case kjv = "KJV"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nlt: return "New Living Translation"
        case .kjv: return "King James Version"
        }
    }
}
