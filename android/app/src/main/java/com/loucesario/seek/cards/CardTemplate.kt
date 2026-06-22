package com.loucesario.seek.cards

import androidx.compose.ui.graphics.Color

/**
 * A verse-card template. [gradient] holds 1–3 vertical stops (a single color =
 * solid). One renderer ([CardRenderer]) drives both preview and export so they
 * can't diverge (the iOS lesson). Ports the full 18-template iOS set; all are
 * unlocked (no premium gating on Seek anymore).
 */
data class CardTemplate(
    val id: String,
    val name: String,
    val category: String,
    val gradient: List<Color>,
    val textColor: Color,
    val referenceColor: Color,
) {
    val topColor: Color get() = gradient.first()
    val bottomColor: Color get() = gradient.last()
}

private val White = Color.White
private val RefWhite = Color(0xCCFFFFFF) // white @ 0.8 — iOS default reference color

object CardTemplates {
    val all: List<CardTemplate> = listOf(
        // Nature (5)
        CardTemplate("nature_ocean", "Ocean", "Nature",
            listOf(Color(0xFF1A3A5C), Color(0xFF5B7B5E), Color(0xFF8AAF8D)), White, RefWhite),
        CardTemplate("nature_sunrise", "Sunrise", "Nature",
            listOf(Color(0xFF1A1A2E), Color(0xFFCDA349), Color(0xFFF5C882)), White, RefWhite),
        CardTemplate("nature_forest", "Forest", "Nature",
            listOf(Color(0xFF1A2E0A), Color(0xFF2D5016), Color(0xFF4A7A28)), White, RefWhite),
        CardTemplate("nature_mountain", "Mountain", "Nature",
            listOf(Color(0xFF1F2937), Color(0xFF3B4856), Color(0xFF6B7280)), White, RefWhite),
        CardTemplate("nature_sky", "Sky", "Nature",
            listOf(Color(0xFF2563EB), Color(0xFF5B9BD5), Color(0xFF93C5FD)), White, RefWhite),

        // Minimal (5)
        CardTemplate("minimal_cream", "Cream", "Minimal",
            listOf(Color(0xFFFAF7F0)), Color(0xFF1A1A1A), Color(0xFF5B7B5E)),
        CardTemplate("minimal_navy", "Navy", "Minimal",
            listOf(Color(0xFF1A2744)), White, RefWhite),
        CardTemplate("minimal_sage", "Sage", "Minimal",
            listOf(Color(0xFFD4DDD2)), Color(0xFF2D3A2D), Color(0xFF4A6741)),
        CardTemplate("minimal_blush", "Blush", "Minimal",
            listOf(Color(0xFFF5E6E0)), Color(0xFF5C3D3D), Color(0xFF8B5E5E)),
        CardTemplate("minimal_charcoal", "Charcoal", "Minimal",
            listOf(Color(0xFF2D2D2D)), White, RefWhite),

        // Watercolor (4)
        CardTemplate("watercolor_lavender", "Lavender", "Watercolor",
            listOf(Color(0xFFE8D5F5)), Color(0xFF3D2A52), Color(0xFF6B4D8A)),
        CardTemplate("watercolor_peach", "Peach", "Watercolor",
            listOf(Color(0xFFFDDCBD)), Color(0xFF5C3A1A), Color(0xFF8B6840)),
        CardTemplate("watercolor_seafoam", "Seafoam", "Watercolor",
            listOf(Color(0xFFC5E8E0)), Color(0xFF1A3D35), Color(0xFF2C5F52)),
        CardTemplate("watercolor_rose", "Rose", "Watercolor",
            listOf(Color(0xFFF5C6D0)), Color(0xFF5C1A2A), Color(0xFF8B3D52)),

        // Bold (4)
        CardTemplate("bold_black", "Midnight", "Bold",
            listOf(Color(0xFF000000)), White, Color(0xFFCDA349)),
        CardTemplate("bold_royal", "Royal", "Bold",
            listOf(Color(0xFF1E0A3C), Color(0xFF4A1A7A)), White, Color(0xFFCDA349)),
        CardTemplate("bold_fire", "Fire", "Bold",
            listOf(Color(0xFF8B0000), Color(0xFFCDA349)), White, RefWhite),
        CardTemplate("bold_gold", "Gold", "Bold",
            listOf(Color(0xFF1A1A1A), Color(0xFF3D3520)), White, Color(0xFFCDA349)),
    )

    fun byId(id: String): CardTemplate = all.firstOrNull { it.id == id } ?: all.first()
}
