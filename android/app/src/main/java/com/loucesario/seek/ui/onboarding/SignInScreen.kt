package com.loucesario.seek.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.auth.PasswordResetOutcome
import com.loucesario.seek.ui.theme.SeekColors

@Composable
fun SignInScreen(authVm: AuthViewModel) {
    val ui by authVm.ui.collectAsStateWithLifecycle()
    var isSignUp by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 28.dp, vertical = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            if (isSignUp) "Create your account" else "Welcome back",
            fontSize = 26.sp,
            fontWeight = FontWeight.Bold,
            color = SeekColors.TextPrimary,
        )
        Spacer(Modifier.height(28.dp))

        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            modifier = Modifier.fillMaxWidth(),
        )

        if (!isSignUp) {
            TextButton(
                onClick = { authVm.resetPassword(email) },
                enabled = !ui.loading,
                modifier = Modifier.align(Alignment.End),
            ) {
                Text("Forgot password?", color = SeekColors.Sage, fontSize = 13.sp)
            }
        } else {
            Spacer(Modifier.height(8.dp))
        }

        ui.error?.let {
            Text(it, color = SeekColors.Warning, fontSize = 13.sp, textAlign = TextAlign.Center)
            Spacer(Modifier.height(8.dp))
        }

        Spacer(Modifier.height(8.dp))
        Button(
            onClick = {
                if (isSignUp) authVm.signUpWithEmail(email, password)
                else authVm.signInWithEmail(email, password)
            },
            enabled = !ui.loading && email.isNotBlank() && password.isNotBlank(),
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
        ) {
            if (ui.loading) {
                CircularProgressIndicator(color = SeekColors.Surface, modifier = Modifier.height(22.dp))
            } else {
                Text(
                    if (isSignUp) "Sign Up" else "Sign In",
                    fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface,
                )
            }
        }
        TextButton(onClick = { isSignUp = !isSignUp; authVm.clearError() }) {
            Text(
                if (isSignUp) "Already have an account? Sign in" else "New here? Create an account",
                color = SeekColors.TextSecondary, fontSize = 14.sp,
            )
        }

        // Google sign-in (supabase-kt browser OAuth → seek://auth-callback).
        // Apple stays hidden on Android (needs the Apple OAuth Services ID + key).
        Spacer(Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            HorizontalDivider(modifier = Modifier.weight(1f), color = SeekColors.Divider)
            Text("  or  ", color = SeekColors.TextTertiary, fontSize = 13.sp)
            HorizontalDivider(modifier = Modifier.weight(1f), color = SeekColors.Divider)
        }
        Spacer(Modifier.height(16.dp))
        OutlinedButton(
            onClick = { authVm.signInWithGoogle() },
            enabled = !ui.loading,
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(27.dp),
        ) {
            Text("Continue with Google", fontSize = 16.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextPrimary)
        }

        Spacer(Modifier.height(12.dp))
        TextButton(onClick = { authVm.continueAsGuest() }) {
            Text("Continue without an account", color = SeekColors.MidSage, fontWeight = FontWeight.Medium)
        }
    }

    ui.resetOutcome?.let { outcome ->
        PasswordResetDialog(
            outcome = outcome,
            onDismiss = { authVm.clearResetOutcome() },
            onContinueWithGoogle = {
                authVm.clearResetOutcome()
                authVm.signInWithGoogle()
            },
            onCreateAccount = {
                authVm.clearResetOutcome()
                isSignUp = true
                authVm.clearError()
            },
        )
    }
}

/**
 * Forgot Password result from `auth-preflight` (mirrors the iOS alert). Only
 * offers a sign-in button Android actually has — Google, not Apple.
 */
@Composable
private fun PasswordResetDialog(
    outcome: PasswordResetOutcome,
    onDismiss: () -> Unit,
    onContinueWithGoogle: () -> Unit,
    onCreateAccount: () -> Unit,
) {
    val title = when (outcome) {
        is PasswordResetOutcome.Sent -> "Reset Email Sent"
        is PasswordResetOutcome.OAuthOnly -> "No Password to Reset"
        is PasswordResetOutcome.NoAccount -> "No Account Found"
    }
    // The server copy says 'Tap "Continue with Apple"', but Android has no
    // Apple button — point Apple-only users at the iPhone app instead.
    val message = if (outcome is PasswordResetOutcome.OAuthOnly && outcome.provider == "apple") {
        "This account signs in with Apple, so there's no password to reset. " +
            "Sign in from the Seek app on iPhone, where Apple sign-in is available."
    } else {
        outcome.message
    }
    val primary: Pair<String, () -> Unit>? = when {
        outcome is PasswordResetOutcome.OAuthOnly && outcome.provider == "google" ->
            "Continue with Google" to onContinueWithGoogle
        outcome is PasswordResetOutcome.NoAccount -> "Create Account" to onCreateAccount
        else -> null
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SeekColors.Surface,
        title = { Text(title, color = SeekColors.TextPrimary) },
        text = { Text(message, color = SeekColors.TextSecondary) },
        confirmButton = {
            if (primary != null) {
                TextButton(onClick = primary.second) {
                    Text(primary.first, color = SeekColors.Sage, fontWeight = FontWeight.SemiBold)
                }
            } else {
                TextButton(onClick = onDismiss) {
                    Text("OK", color = SeekColors.Sage, fontWeight = FontWeight.SemiBold)
                }
            }
        },
        dismissButton = if (primary != null) {
            {
                TextButton(onClick = onDismiss) {
                    Text("Cancel", color = SeekColors.TextSecondary)
                }
            }
        } else {
            null
        },
    )
}
