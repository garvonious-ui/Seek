package com.loucesario.seek.ui.components

import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.ui.theme.SeekColors
import kotlinx.coroutines.delay

/**
 * Copies [text] to the clipboard, then briefly swaps to a checkmark + "Copied"
 * so the tap has visible confirmation (mirrors the iOS CopyButton).
 *
 * No Toast: Android 13+ shows its own clipboard confirmation, and the in-place
 * "Copied" state covers older versions.
 *
 * @param iconOnly icon without the "Copy" caption — for tight rows like the
 *   verse cards, next to the heart.
 */
@Composable
fun CopyButton(
    text: String,
    modifier: Modifier = Modifier,
    iconOnly: Boolean = false,
    tint: Color = SeekColors.Sage,
) {
    val clipboard = LocalClipboardManager.current
    val view = LocalView.current
    // Bumped on every tap so a second tap restarts the 1.5s "Copied" window.
    var copyCount by remember { mutableIntStateOf(0) }
    var copied by remember { mutableStateOf(false) }
    LaunchedEffect(copyCount) {
        if (copyCount == 0) return@LaunchedEffect
        copied = true
        delay(1_500)
        copied = false
    }

    val onCopy: () -> Unit = {
        clipboard.setText(AnnotatedString(text))
        view.performHapticFeedback(
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM
            else HapticFeedbackConstants.CONTEXT_CLICK,
        )
        copyCount++
    }
    val label = if (copied) "Copied" else "Copy"
    val icon = if (copied) Icons.Filled.Check else Icons.Outlined.ContentCopy

    if (iconOnly) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = tint,
            modifier = modifier.size(20.dp).clickable(role = Role.Button, onClick = onCopy),
        )
    } else {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = modifier.clickable(role = Role.Button, onClick = onCopy),
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Text(label, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = tint)
        }
    }
}

/** Shared clipboard format for a verse — identical to iOS: text, then "— reference". */
fun verseCopyText(text: String, reference: String): String = "$text\n— $reference"
