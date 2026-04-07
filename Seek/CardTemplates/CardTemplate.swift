import SwiftUI

/// Defines a card template's visual properties
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

    enum Category: String, CaseIterable {
        case nature = "Nature"
        case minimal = "Minimal"
        case watercolor = "Watercolor"
        case bold = "Bold"
    }

    // Convenience init without gradient or accent
    init(
        id: String,
        name: String,
        category: Category,
        isPremium: Bool = false,
        backgroundColor: Color,
        backgroundGradient: [Color]? = nil,
        textColor: Color = .white,
        referenceColor: Color = .white.opacity(0.8),
        fontName: String = "Georgia",
        accentElements: AnyView? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isPremium = isPremium
        self.backgroundColor = backgroundColor
        self.backgroundGradient = backgroundGradient
        self.textColor = textColor
        self.referenceColor = referenceColor
        self.fontName = fontName
        self.accentElements = accentElements
    }
}

// MARK: - All Templates

extension CardTemplate {
    static let all: [CardTemplate] = [
        // Nature (5)
        CardTemplate(
            id: "nature_ocean",
            name: "Ocean",
            category: .nature,
            backgroundColor: Color(hex: "1A3A5C"),
            backgroundGradient: [Color(hex: "1A3A5C"), Color(hex: "2C5F7C"), Color(hex: "4A8BA8")]
        ),
        CardTemplate(
            id: "nature_sunrise",
            name: "Sunrise",
            category: .nature,
            backgroundColor: Color(hex: "D4A853"),
            backgroundGradient: [Color(hex: "1A1A2E"), Color(hex: "D4A853"), Color(hex: "F5C882")]
        ),
        CardTemplate(
            id: "nature_forest",
            name: "Forest",
            category: .nature,
            backgroundColor: Color(hex: "2D5016"),
            backgroundGradient: [Color(hex: "1A2E0A"), Color(hex: "2D5016"), Color(hex: "4A7A28")]
        ),
        CardTemplate(
            id: "nature_mountain",
            name: "Mountain",
            category: .nature,
            isPremium: true,
            backgroundColor: Color(hex: "3B4856"),
            backgroundGradient: [Color(hex: "1F2937"), Color(hex: "3B4856"), Color(hex: "6B7280")]
        ),
        CardTemplate(
            id: "nature_sky",
            name: "Sky",
            category: .nature,
            backgroundColor: Color(hex: "5B9BD5"),
            backgroundGradient: [Color(hex: "2563EB"), Color(hex: "5B9BD5"), Color(hex: "93C5FD")]
        ),

        // Minimal (5)
        CardTemplate(
            id: "minimal_cream",
            name: "Cream",
            category: .minimal,
            backgroundColor: Color(hex: "FAF7F0"),
            textColor: Color(hex: "1A1A1A"),
            referenceColor: Color(hex: "2C5F7C")
        ),
        CardTemplate(
            id: "minimal_navy",
            name: "Navy",
            category: .minimal,
            backgroundColor: Color(hex: "1A2744")
        ),
        CardTemplate(
            id: "minimal_sage",
            name: "Sage",
            category: .minimal,
            backgroundColor: Color(hex: "D4DDD2"),
            textColor: Color(hex: "2D3A2D"),
            referenceColor: Color(hex: "4A6741")
        ),
        CardTemplate(
            id: "minimal_blush",
            name: "Blush",
            category: .minimal,
            isPremium: true,
            backgroundColor: Color(hex: "F5E6E0"),
            textColor: Color(hex: "5C3D3D"),
            referenceColor: Color(hex: "8B5E5E")
        ),
        CardTemplate(
            id: "minimal_charcoal",
            name: "Charcoal",
            category: .minimal,
            backgroundColor: Color(hex: "2D2D2D")
        ),

        // Watercolor (4)
        CardTemplate(
            id: "watercolor_lavender",
            name: "Lavender",
            category: .watercolor,
            backgroundColor: Color(hex: "E8D5F5"),
            textColor: Color(hex: "3D2A52"),
            referenceColor: Color(hex: "6B4D8A")
        ),
        CardTemplate(
            id: "watercolor_peach",
            name: "Peach",
            category: .watercolor,
            backgroundColor: Color(hex: "FDDCBD"),
            textColor: Color(hex: "5C3A1A"),
            referenceColor: Color(hex: "8B6840")
        ),
        CardTemplate(
            id: "watercolor_seafoam",
            name: "Seafoam",
            category: .watercolor,
            isPremium: true,
            backgroundColor: Color(hex: "C5E8E0"),
            textColor: Color(hex: "1A3D35"),
            referenceColor: Color(hex: "2C5F52")
        ),
        CardTemplate(
            id: "watercolor_rose",
            name: "Rose",
            category: .watercolor,
            isPremium: true,
            backgroundColor: Color(hex: "F5C6D0"),
            textColor: Color(hex: "5C1A2A"),
            referenceColor: Color(hex: "8B3D52")
        ),

        // Bold (4)
        CardTemplate(
            id: "bold_black",
            name: "Midnight",
            category: .bold,
            backgroundColor: .black,
            referenceColor: Color(hex: "D4A853"),
            fontName: "Helvetica-Bold"
        ),
        CardTemplate(
            id: "bold_royal",
            name: "Royal",
            category: .bold,
            backgroundColor: Color(hex: "1E0A3C"),
            backgroundGradient: [Color(hex: "1E0A3C"), Color(hex: "4A1A7A")],
            referenceColor: Color(hex: "D4A853")
        ),
        CardTemplate(
            id: "bold_fire",
            name: "Fire",
            category: .bold,
            isPremium: true,
            backgroundColor: Color(hex: "8B0000"),
            backgroundGradient: [Color(hex: "8B0000"), Color(hex: "D4A853")]
        ),
        CardTemplate(
            id: "bold_gold",
            name: "Gold",
            category: .bold,
            isPremium: true,
            backgroundColor: Color(hex: "1A1A1A"),
            backgroundGradient: [Color(hex: "1A1A1A"), Color(hex: "3D3520")],
            referenceColor: Color(hex: "D4A853")
        ),
    ]

    static let free: [CardTemplate] = all.filter { !$0.isPremium }
    static let premium: [CardTemplate] = all.filter { $0.isPremium }
}
