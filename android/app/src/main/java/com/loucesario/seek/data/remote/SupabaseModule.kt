package com.loucesario.seek.data.remote

import com.loucesario.seek.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.ktor.client.engine.okhttp.OkHttp
import java.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Single shared Supabase client, pointed at the SAME project as the iOS app
 * (ref hxfiaowayrhuhzhhbaix). URL + anon key come from BuildConfig.
 *
 * The OAuth redirect (scheme://host) must match the intent-filter in
 * AndroidManifest.xml — used for Sign in with Apple's web flow on Android.
 */
object SupabaseModule {
    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = BuildConfig.SUPABASE_URL,
            supabaseKey = BuildConfig.SUPABASE_ANON_KEY,
        ) {
            // The chat Edge Function (Claude generating 3-5 verses + prayer +
            // song) routinely exceeds the 10s defaults. Two timeouts must be
            // raised: ktor's request timeout AND OkHttp's socket/call timeout.
            requestTimeout = 60.seconds
            httpEngine = OkHttp.create {
                config {
                    callTimeout(Duration.ofSeconds(60))
                    readTimeout(Duration.ofSeconds(60))
                    connectTimeout(Duration.ofSeconds(30))
                }
            }
            install(Auth) {
                scheme = "seek"
                host = "auth-callback"
            }
            install(Postgrest)
            install(Functions)
        }
    }
}
