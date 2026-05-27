package com.loucesario.seek.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.loucesario.seek.data.AuthState
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.onboarding.OnboardingFlow

/**
 * Top-level auth gate (mirrors iOS SeekApp routing):
 *  - authenticated OR guest → the 3-tab shell
 *  - otherwise → onboarding / sign-in
 *
 * The single AuthViewModel is shared down so sign-out / guest checks stay
 * consistent across the app.
 */
@Composable
fun SeekApp() {
    val authVm: AuthViewModel = viewModel()
    val session by authVm.session.collectAsStateWithLifecycle()

    val showShell = session.authState == AuthState.AUTHENTICATED || session.isGuest
    if (showShell) {
        SeekRoot(authVm)
    } else {
        OnboardingFlow(authVm)
    }
}
