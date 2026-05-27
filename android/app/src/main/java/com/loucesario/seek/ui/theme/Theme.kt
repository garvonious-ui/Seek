package com.loucesario.seek.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

/**
 * Seek is always light mode (matches the iOS forced-light rule). We never read
 * [isSystemInDarkTheme]; the scheme below is fixed.
 */
private val SeekColorScheme = lightColorScheme(
    primary = SeekColors.Sage,
    onPrimary = SeekColors.Surface,
    secondary = SeekColors.Gold,
    onSecondary = SeekColors.TextPrimary,
    background = SeekColors.Background,
    onBackground = SeekColors.TextPrimary,
    surface = SeekColors.Surface,
    onSurface = SeekColors.TextPrimary,
    surfaceVariant = SeekColors.SurfaceMuted,
    onSurfaceVariant = SeekColors.TextSecondary,
    outline = SeekColors.Divider,
    error = SeekColors.Warning,
)

@Composable
fun SeekTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = SeekColorScheme,
        typography = SeekTypography,
        content = content,
    )
}
