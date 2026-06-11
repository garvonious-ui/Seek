package com.loucesario.seek.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.unit.sp
import com.loucesario.seek.R

/**
 * Typography for Seek.
 *
 * UI text uses the system sans (Roboto), matching iOS's SF Pro role.
 *
 * Scripture text is **Lora** (Google Fonts, OFL) — fetched lazily by the
 * Downloadable Fonts provider at first use, then cached on-device. Georgia (the
 * iOS scripture font) is Microsoft-proprietary and can't ship with the app.
 * Lora is the closest serif match: warm humanist proportions, distinct enough
 * from the UI sans, reads well at scripture sizes.
 */
private val GoogleFontsProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage = "com.google.android.gms",
    certificates = R.array.com_google_android_gms_fonts_certs,
)

private val LoraGoogleFont = GoogleFont("Lora")

val ScriptureFontFamily: FontFamily = FontFamily(
    Font(googleFont = LoraGoogleFont, fontProvider = GoogleFontsProvider, weight = FontWeight.Normal),
    Font(googleFont = LoraGoogleFont, fontProvider = GoogleFontsProvider, weight = FontWeight.Normal, style = FontStyle.Italic),
    Font(googleFont = LoraGoogleFont, fontProvider = GoogleFontsProvider, weight = FontWeight.Medium),
    Font(googleFont = LoraGoogleFont, fontProvider = GoogleFontsProvider, weight = FontWeight.SemiBold),
)

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
