package com.loucesario.seek.cards

import androidx.compose.ui.graphics.Color
import com.loucesario.seek.ui.theme.SeekColors

/**
 * A verse-card template. Background is a vertical gradient (single color = both
 * stops the same). One renderer ([CardRenderer]) drives both preview and export
 * so there's no preview/export divergence (the iOS lesson).
 */
data class CardTemplate(
    val id: String,
    val name: String,
    val category: String,
    val topColor: Color,
    val bottomColor: Color,
    val textColor: Color,
    val referenceColor: Color,
)

object CardTemplates {
    val all: List<CardTemplate> = listOf(
        CardTemplate("sage", "Sage", "Minimal", SeekColors.Sage, SeekColors.MidSage, Color.White, Color(0xFFEDD99A)),
        CardTemplate("cream", "Cream", "Minimal", SeekColors.Background, SeekColors.Background, SeekColors.TextPrimary, SeekColors.Sage),
        CardTemplate("gold", "Gold", "Bold", SeekColors.Gold, SeekColors.LightGold, SeekColors.TextPrimary, Color(0xFF6B5A1F)),
        CardTemplate("night", "Night", "Bold", Color(0xFF1A1A1A), Color(0xFF2D2D2D), SeekColors.Background, SeekColors.LightGold),
        CardTemplate("blush", "Blush", "Watercolor", Color(0xFFEAD7D1), Color(0xFFF3E9E4), Color(0xFF5A3E3A), Color(0xFF9B6A5E)),
        CardTemplate("sky", "Sky", "Nature", Color(0xFFA7C4D1), Color(0xFFD6E6EC), Color(0xFF1F3A45), Color(0xFF3E6A7A)),
    )

    fun byId(id: String): CardTemplate = all.firstOrNull { it.id == id } ?: all.first()
}
