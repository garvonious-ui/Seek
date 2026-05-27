package com.loucesario.seek.ui.onboarding

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.theme.SeekColors

private enum class OnboardStep { WELCOME, SIGN_IN }

@Composable
fun OnboardingFlow(authVm: AuthViewModel) {
    var step by rememberSaveable { mutableStateOf(OnboardStep.WELCOME) }

    Crossfade(targetState = step, label = "onboarding") { current ->
        when (current) {
            OnboardStep.WELCOME -> WelcomeScreen(onBegin = { step = OnboardStep.SIGN_IN })
            OnboardStep.SIGN_IN -> SignInScreen(authVm = authVm)
        }
    }
}

@Composable
private fun WelcomeScreen(onBegin: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        // Gold glowing halo (multi-shadow circle), echoing the iOS welcome page.
        Box(
            modifier = Modifier
                .size(120.dp)
                .shadow(40.dp, CircleShape, ambientColor = SeekColors.Gold, spotColor = SeekColors.Gold)
                .background(SeekColors.LightGold, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text("S", fontSize = 64.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
        }
        Spacer(Modifier.height(40.dp))
        Text("Seek", fontSize = 40.sp, fontWeight = FontWeight.Bold, color = SeekColors.TextPrimary)
        Spacer(Modifier.height(12.dp))
        Text(
            "Scripture for every moment.",
            fontSize = 17.sp,
            color = SeekColors.TextSecondary,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(48.dp))
        Button(
            onClick = onBegin,
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
        ) {
            Text("Begin", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
        }
    }
}
