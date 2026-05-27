package com.loucesario.seek.data

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged

/**
 * Emits true when there's a real (validated) internet connection.
 *
 * Seeds the CURRENT state synchronously at collection start (via
 * getNetworkCapabilities) rather than assuming online — otherwise, when a screen
 * opens while already offline, no NetworkCallback event fires (nothing is
 * changing) and the flow would stay stuck at the optimistic value.
 *
 * Requires VALIDATED (not just the INTERNET capability) so "connected but no
 * actual internet" reads as offline.
 */
class ConnectivityObserver(context: Context) {
    private val cm = context.getSystemService(ConnectivityManager::class.java)

    private fun online(caps: NetworkCapabilities?): Boolean =
        caps != null &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

    private fun currentlyOnline(): Boolean = online(cm.getNetworkCapabilities(cm.activeNetwork))

    val isOnline: Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { trySend(currentlyOnline()) }
            override fun onLost(network: Network) { trySend(currentlyOnline()) }
            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                trySend(online(caps))
            }
        }
        trySend(currentlyOnline()) // real current state, not an assumption
        cm.registerDefaultNetworkCallback(callback)
        awaitClose { cm.unregisterNetworkCallback(callback) }
    }.distinctUntilChanged()
}
