package com.loucesario.seek.ui.profile

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.notifications.NotificationPrefs
import com.loucesario.seek.notifications.SeekNotifications
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.theme.SeekColors
import kotlinx.coroutines.launch

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
                AuthenticatedProfile(authVm)
            }
        }
    }
}

@Composable
private fun ColumnScope.AuthenticatedProfile(authVm: AuthViewModel) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val prefs = remember { NotificationPrefs(context) }
    val appPrefs = remember { SeekPrefs(context) }
    val verseOn by prefs.dailyVerseEnabled.collectAsStateWithLifecycle(false)
    val streakOn by prefs.streakEnabled.collectAsStateWithLifecycle(false)
    val translation by appPrefs.translation.collectAsStateWithLifecycle("NLT")
    val streak by appPrefs.streakCount.collectAsStateWithLifecycle(0)
    val longest by appPrefs.longestStreak.collectAsStateWithLifecycle(0)
    val verses by appPrefs.versesExplored.collectAsStateWithLifecycle(0)
    val cards by appPrefs.cardsCreated.collectAsStateWithLifecycle(0)
    var showTranslationPicker by remember { mutableStateOf(false) }

    // POST_NOTIFICATIONS request (Android 13+). On grant, enable daily verse.
    val permLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) scope.launch { prefs.setDailyVerse(true) }
    }
    fun hasNotifPermission(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    Spacer(Modifier.height(8.dp))
    Text("Signed in", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)

    Spacer(Modifier.height(16.dp))
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        StatCell(if (streak > 0) "🔥 $streak" else "—", "Day streak")
        StatCell(longest.toString(), "Best")
        StatCell(verses.toString(), "Verses")
        StatCell(cards.toString(), "Cards")
    }

    Spacer(Modifier.height(16.dp))
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showTranslationPicker = true }
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text("Bible translation", fontSize = 15.sp, color = SeekColors.TextPrimary)
            Text("For chat + daily verse", fontSize = 12.sp, color = SeekColors.TextSecondary)
        }
        Text(translation, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
    }
    Spacer(Modifier.height(8.dp))

    HorizontalDivider(color = SeekColors.Divider)
    Spacer(Modifier.height(16.dp))
    Text("Notifications", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = SeekColors.TextSecondary, modifier = Modifier.align(Alignment.Start))
    Spacer(Modifier.height(8.dp))

    ToggleRow("Daily verse · ${NotificationPrefs.DAILY_VERSE_TIME}", verseOn) { want ->
        if (want && !hasNotifPermission()) {
            permLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else scope.launch { prefs.setDailyVerse(want) }
    }
    ToggleRow("Streak nudge · ${NotificationPrefs.STREAK_TIME}", streakOn) { want ->
        scope.launch { prefs.setStreak(want) }
    }

    Spacer(Modifier.height(8.dp))
    TextButton(onClick = {
        if (hasNotifPermission()) SeekNotifications.showDailyVerse(context)
        else permLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }) { Text("Send a test reminder", color = SeekColors.Sage) }

    Spacer(Modifier.height(16.dp))
    HorizontalDivider(color = SeekColors.Divider)
    Spacer(Modifier.height(16.dp))
    Text("More", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = SeekColors.TextSecondary, modifier = Modifier.align(Alignment.Start))
    Spacer(Modifier.height(8.dp))

    LinkRow("Rate Seek") {
        // Prefer the Play Store app; fall back to the web listing.
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=com.loucesario.seek")))
        } catch (e: ActivityNotFoundException) {
            openWeb(context, "https://play.google.com/store/apps/details?id=com.loucesario.seek")
        }
    }
    LinkRow("Share Seek with a friend") {
        val share = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(
                Intent.EXTRA_TEXT,
                "I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.\nhttps://play.google.com/store/apps/details?id=com.loucesario.seek",
            )
        }
        context.startActivity(Intent.createChooser(share, "Share Seek"))
    }
    LinkRow("Privacy Policy") { openWeb(context, "https://askseekpray.app/privacy") }
    LinkRow("Terms of Service") { openWeb(context, "https://askseekpray.app/terms") }

    var showUnsyncedDialog by remember { mutableStateOf(false) }
    Spacer(Modifier.height(24.dp))
    OutlinedButton(
        onClick = { authVm.signOut(onUnsynced = { showUnsyncedDialog = true }) },
        modifier = Modifier.fillMaxWidth().height(50.dp),
        shape = RoundedCornerShape(25.dp),
    ) { Text("Sign Out", color = SeekColors.TextPrimary) }

    val ui by authVm.ui.collectAsStateWithLifecycle()
    var showDeleteDialog by remember { mutableStateOf(false) }
    val deleteRed = Color(0xFFC5221F)

    Spacer(Modifier.height(8.dp))
    TextButton(
        onClick = { showDeleteDialog = true },
        enabled = !ui.loading,
    ) { Text(if (ui.loading) "Deleting…" else "Delete Account", color = deleteRed) }

    ui.error?.let {
        Text(it, color = deleteRed, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp))
    }

    if (showUnsyncedDialog) {
        AlertDialog(
            onDismissRequest = { showUnsyncedDialog = false },
            containerColor = SeekColors.Surface,
            title = { Text("Not backed up yet", color = SeekColors.TextPrimary) },
            text = {
                Text(
                    "Some of your saved cards, favorites, or chats haven't reached the cloud yet. Signing out now removes them from this device. Connect to the internet and try again to keep them.",
                    color = SeekColors.TextSecondary,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showUnsyncedDialog = false
                    authVm.signOut(force = true)
                }) { Text("Sign Out Anyway", color = deleteRed, fontWeight = FontWeight.SemiBold) }
            },
            dismissButton = {
                TextButton(onClick = { showUnsyncedDialog = false }) {
                    Text("Stay Signed In", color = SeekColors.TextSecondary)
                }
            },
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            containerColor = SeekColors.Surface,
            title = { Text("Delete your account?", color = SeekColors.TextPrimary) },
            text = {
                Text(
                    "This permanently deletes your account and all your saved cards, favorites, prayers, and history. This can't be undone.",
                    color = SeekColors.TextSecondary,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteDialog = false
                    authVm.deleteAccount()
                }) { Text("Delete", color = deleteRed, fontWeight = FontWeight.SemiBold) }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel", color = SeekColors.TextSecondary)
                }
            },
        )
    }

    if (showTranslationPicker) {
        AlertDialog(
            onDismissRequest = { showTranslationPicker = false },
            containerColor = SeekColors.Surface,
            title = { Text("Bible translation", color = SeekColors.TextPrimary) },
            text = {
                Column {
                    listOf("NLT" to "New Living Translation", "KJV" to "King James Version").forEach { (code, name) ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    scope.launch {
                                        appPrefs.setTranslation(code)
                                        runCatching { SeekApi.updatePreferredTranslation(code) }
                                    }
                                    showTranslationPicker = false
                                }
                                .padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(code, fontSize = 16.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextPrimary)
                                Text(name, fontSize = 13.sp, color = SeekColors.TextSecondary)
                            }
                            if (translation == code) {
                                Icon(Icons.Filled.Check, contentDescription = "Selected", tint = SeekColors.Sage)
                                Spacer(Modifier.width(4.dp))
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showTranslationPicker = false }) { Text("Done", color = SeekColors.Sage) }
            },
        )
    }
}

@Composable
private fun StatCell(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Sage)
        Text(label, fontSize = 11.sp, color = SeekColors.TextSecondary)
    }
}

@Composable
private fun LinkRow(label: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, fontSize = 15.sp, color = SeekColors.TextPrimary)
        Text("›", fontSize = 18.sp, color = SeekColors.TextTertiary)
    }
}

private fun openWeb(context: android.content.Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, fontSize = 15.sp, color = SeekColors.TextPrimary)
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = SeekColors.Surface,
                checkedTrackColor = SeekColors.Sage,
            ),
        )
    }
}
