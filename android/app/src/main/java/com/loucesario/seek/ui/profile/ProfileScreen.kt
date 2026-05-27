package com.loucesario.seek.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.theme.SeekColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(authVm: AuthViewModel, isGuest: Boolean, onBack: () -> Unit) {
    Scaffold(
        containerColor = SeekColors.Background,
        topBar = {
            TopAppBar(
                title = { Text("Profile", color = SeekColors.TextPrimary) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Back", tint = SeekColors.TextPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SeekColors.Background),
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.fillMaxSize().padding(inner).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (isGuest) {
                Spacer(Modifier.height(40.dp))
                Text("You're browsing as a guest", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
                Text(
                    "Sign in to chat, save verses, and track your streak.",
                    fontSize = 15.sp, color = SeekColors.TextSecondary, textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = 8.dp, bottom = 28.dp),
                )
                Button(
                    onClick = { authVm.exitGuest() },
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape = RoundedCornerShape(27.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
                ) { Text("Sign In", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface) }
            } else {
                Spacer(Modifier.height(24.dp))
                Text("Signed in", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
                Text(
                    "Translation: NLT",
                    fontSize = 14.sp, color = SeekColors.TextSecondary,
                    modifier = Modifier.padding(top = 8.dp, bottom = 32.dp),
                )
                OutlinedButton(
                    onClick = { authVm.signOut() },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                ) { Text("Sign Out", color = SeekColors.TextPrimary) }
            }
        }
    }
}
