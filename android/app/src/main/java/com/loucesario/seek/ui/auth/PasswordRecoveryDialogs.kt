package com.loucesario.seek.ui.auth

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.loucesario.seek.ui.theme.SeekColors

/** Same minimum Supabase enforces (and iOS's sign-up / set-password screens use). */
private const val MIN_PASSWORD_LENGTH = 6

/**
 * App-wide dialogs for the seek://password-reset link. Hosted in SeekApp (not
 * SignInScreen) because the link can arrive on any screen, signed in or not.
 */
@Composable
fun PasswordRecoveryDialogs(authVm: AuthViewModel) {
    val dialog by authVm.recoveryDialog.collectAsStateWithLifecycle()

    when (dialog) {
        RecoveryDialog.SET_PASSWORD -> SetNewPasswordDialog(
            onSave = authVm::updatePassword,
            onNotNow = authVm::dismissRecoveryDialog,
        )
        RecoveryDialog.PASSWORD_UPDATED -> InfoDialog(
            title = "Password Updated",
            message = "Your password has been updated.",
            onDismiss = authVm::dismissRecoveryDialog,
        )
        RecoveryDialog.LINK_EXPIRED -> InfoDialog(
            title = "Link Expired",
            message = "This reset link has expired or was already used. Request a new one from Sign In.",
            onDismiss = authVm::dismissRecoveryDialog,
        )
        null -> Unit
    }
}

/**
 * Shown after the reset link signs the user in with the recovery session; this
 * only sets the new password. "Not now" (or back) leaves them signed in.
 */
@Composable
private fun SetNewPasswordDialog(
    onSave: (String, (String?) -> Unit) -> Unit,
    onNotNow: () -> Unit,
) {
    var password by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val isValid = password.length >= MIN_PASSWORD_LENGTH && password == confirm
    val hint = when {
        password.isNotEmpty() && password.length < MIN_PASSWORD_LENGTH -> "Use at least $MIN_PASSWORD_LENGTH characters."
        confirm.isNotEmpty() && password != confirm -> "Passwords don't match."
        else -> null
    }

    Dialog(
        onDismissRequest = { if (!saving) onNotNow() },
        // Outside taps shouldn't throw away a half-typed password; back still = "Not now".
        properties = DialogProperties(dismissOnClickOutside = false),
    ) {
        Surface(shape = RoundedCornerShape(24.dp), color = SeekColors.Surface) {
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "Set a New Password",
                    fontSize = 22.sp, fontWeight = FontWeight.Bold, color = SeekColors.TextPrimary,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    "You're signed in. Choose a new password for next time.",
                    fontSize = 14.sp, color = SeekColors.TextSecondary, textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(20.dp))
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it; error = null },
                    label = { Text("New password") },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = confirm,
                    onValueChange = { confirm = it; error = null },
                    label = { Text("Confirm password") },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    modifier = Modifier.fillMaxWidth(),
                )
                hint?.let {
                    Spacer(Modifier.height(8.dp))
                    Text(it, fontSize = 12.sp, color = SeekColors.TextSecondary)
                }
                error?.let {
                    Spacer(Modifier.height(8.dp))
                    Text(it, fontSize = 13.sp, color = SeekColors.Warning, textAlign = TextAlign.Center)
                }
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = {
                        saving = true
                        onSave(password) { result ->
                            saving = false
                            error = result
                        }
                    },
                    enabled = isValid && !saving,
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape = RoundedCornerShape(27.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
                ) {
                    if (saving) {
                        CircularProgressIndicator(color = SeekColors.Surface, modifier = Modifier.size(22.dp))
                    } else {
                        Text("Save Password", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
                    }
                }
                TextButton(onClick = onNotNow, enabled = !saving) {
                    Text("Not now", color = SeekColors.TextSecondary)
                }
            }
        }
    }
}

@Composable
private fun InfoDialog(title: String, message: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SeekColors.Surface,
        title = { Text(title, color = SeekColors.TextPrimary) },
        text = { Text(message, color = SeekColors.TextSecondary) },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK", color = SeekColors.Sage, fontWeight = FontWeight.SemiBold)
            }
        },
    )
}
