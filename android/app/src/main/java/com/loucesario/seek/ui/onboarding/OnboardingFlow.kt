package com.loucesario.seek.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.Crossfade
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.notifications.NotificationPrefs
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.theme.SeekColors
import kotlinx.coroutines.launch

private enum class OnboardStep { WELCOME, PERSONALIZE, NOTIFICATIONS, SIGN_IN }

/** Topics offered during personalization — mirrors the iOS onboarding list. */
private val ONBOARDING_TOPICS = listOf(
    "Daily encouragement",
    "Celebrating a season of blessing",
    "Going through something hard",
    "Sharing scripture with others",
    "Growing deeper in faith",
)

@Composable
fun OnboardingFlow(authVm: AuthViewModel) {
    var step by rememberSaveable { mutableStateOf(OnboardStep.WELCOME) }

    Crossfade(targetState = step, label = "onboarding") { current ->
        when (current) {
            OnboardStep.WELCOME -> WelcomeScreen(onBegin = { step = OnboardStep.PERSONALIZE })
            OnboardStep.PERSONALIZE -> PersonalizationScreen(onContinue = { step = OnboardStep.NOTIFICATIONS })
            OnboardStep.NOTIFICATIONS -> NotificationsScreen(onContinue = { step = OnboardStep.SIGN_IN })
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

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PersonalizationScreen(onContinue: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val prefs = remember { SeekPrefs(context) }
    var selected by remember { mutableStateOf(emptySet<String>()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 32.dp, vertical = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(16.dp))
        Text(
            "What brings you to Seek?",
            fontSize = 26.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "Select all that apply — this helps us personalize your experience.",
            fontSize = 15.sp, color = SeekColors.TextSecondary, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(28.dp))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ONBOARDING_TOPICS.forEach { topic ->
                val isSel = topic in selected
                Surface(
                    color = if (isSel) SeekColors.Sage else SeekColors.Sage.copy(alpha = 0.10f),
                    shape = RoundedCornerShape(22.dp),
                    modifier = Modifier.clickable {
                        selected = if (isSel) selected - topic else selected + topic
                    },
                ) {
                    Text(
                        topic, fontSize = 15.sp, fontWeight = FontWeight.Medium,
                        color = if (isSel) SeekColors.Surface else SeekColors.Sage,
                        modifier = Modifier.padding(horizontal = 18.dp, vertical = 12.dp),
                    )
                }
            }
        }
        Spacer(Modifier.height(40.dp))
        Button(
            onClick = {
                scope.launch { prefs.setOnboardingTopics(selected) }
                onContinue()
            },
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
        ) {
            Text("Continue", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
        }
        TextButton(onClick = onContinue) { Text("Skip", color = SeekColors.TextSecondary) }
    }
}

@Composable
private fun NotificationsScreen(onContinue: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val prefs = remember { NotificationPrefs(context) }

    fun enableAndContinue() {
        scope.launch {
            prefs.setDailyVerse(true)
            prefs.setStreak(true)
        }
        onContinue()
    }

    val permLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) enableAndContinue() else onContinue()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(110.dp)
                .background(SeekColors.LightGold, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text("🔔", fontSize = 48.sp)
        }
        Spacer(Modifier.height(32.dp))
        Text(
            "Stay encouraged",
            fontSize = 26.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Get a daily verse each morning and a gentle nudge in the evening to keep your streak alive.",
            fontSize = 16.sp, color = SeekColors.TextSecondary, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(40.dp))
        Button(
            onClick = {
                if (Build.VERSION.SDK_INT >= 33) permLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                else enableAndContinue()
            },
            modifier = Modifier.fillMaxWidth().height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
        ) {
            Text("Enable reminders", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
        }
        TextButton(onClick = onContinue) { Text("Maybe later", color = SeekColors.TextSecondary) }
    }
}
