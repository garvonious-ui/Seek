package com.loucesario.seek.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.loucesario.seek.cards.CardDraft
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.cards.CardCreatorScreen
import com.loucesario.seek.ui.chat.ChatScreen
import com.loucesario.seek.ui.home.HomeScreen
import com.loucesario.seek.ui.library.LibraryScreen
import com.loucesario.seek.ui.profile.ProfileScreen

private enum class SeekTab(val route: String, val label: String, val icon: ImageVector) {
    HOME("home", "Home", Icons.Outlined.Home),
    CHAT("chat", "Chat", Icons.Outlined.ChatBubbleOutline),
    LIBRARY("library", "Library", Icons.Outlined.Bookmark),
}

/** The 3-tab shell, shown for authenticated AND guest users. */
@Composable
fun SeekRoot(authVm: AuthViewModel) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = backStackEntry?.destination
    val session by authVm.session.collectAsStateWithLifecycle()

    Scaffold(
        bottomBar = {
            NavigationBar {
                SeekTab.entries.forEach { tab ->
                    val selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true
                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = SeekTab.HOME.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(SeekTab.HOME.route) {
                HomeScreen(
                    isGuest = session.isGuest,
                    onOpenProfile = { navController.navigate("profile") },
                    onCreateCard = { text, ref ->
                        CardDraft.set(text, ref)
                        navController.navigate("card")
                    },
                )
            }
            composable(SeekTab.CHAT.route) {
                ChatScreen(
                    isGuest = session.isGuest,
                    onCreateCard = { text, ref ->
                        CardDraft.set(text, ref)
                        navController.navigate("card")
                    },
                )
            }
            composable(SeekTab.LIBRARY.route) {
                LibraryScreen(
                    isGuest = session.isGuest,
                    onOpenCard = { text, ref ->
                        CardDraft.set(text, ref)
                        navController.navigate("card")
                    },
                )
            }
            composable("profile") {
                ProfileScreen(
                    authVm = authVm,
                    isGuest = session.isGuest,
                    onBack = { navController.popBackStack() },
                )
            }
            composable("card") {
                CardCreatorScreen(onBack = { navController.popBackStack() })
            }
        }
    }
}
