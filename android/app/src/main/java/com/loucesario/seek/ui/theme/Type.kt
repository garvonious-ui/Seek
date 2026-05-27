package com.loucesario.seek.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Typography for Seek.
 *
 * UI text uses the system sans (Roboto), matching iOS's SF Pro role.
 *
 * SCRIPTURE FONT: the design target is **Lora** (Google Fonts, OFL). Georgia —
 * the iOS scripture font — is Microsoft-proprietary and cannot be bundled on
 * Android, so Lora is the chosen substitute (see docs/android-plan.md).
 *
 * The scaffold ships with [ScriptureFontFamily] = FontFamily.Serif, which
 * resolves to Noto Serif on-device — a clean, zero-config serif so the project
 * builds immediately. To switch to Lora: Android Studio → res → New → Font →
 * "Get more fonts" → Lora (downloadable; the wizard generates the font_certs
 * resource + provider XML correctly), then set ScriptureFontFamily to it.
 * This is the only change needed; every scripture surface reads this one value.
 */
val ScriptureFontFamily: FontFamily = FontFamily.Serif

/** Scripture text style — serif, generous line height (~1.6), per design-system.md. */
val ScriptureTextStyle = TextStyle(
    fontFamily = ScriptureFontFamily,
    fontWeight = FontWeight.Normal,
    fontSize = 20.sp,
    lineHeight = 32.sp,
)

val SeekTypography = Typography(
    titleLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 28.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
)
