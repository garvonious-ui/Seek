import Foundation
import Supabase
import Auth

/// Service for all Supabase interactions (Auth, Database, Edge Functions)
/// TODO: Replace these with your Supabase project credentials from https://supabase.com/dashboard
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let url = URL(string: "https://hxfiaowayrhuhzhhbaix.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Zmlhb3dheXJodWh6aGhiYWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NzI2NDksImV4cCI6MjA5MTE0ODY0OX0.tsf-R505B_RJvO8qDI0WMlcLzyPD7xrZK8ll4SbFK2Y"

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    // MARK: - Auth

    var currentUser: User? {
        client.auth.currentUser
    }

    var currentSession: Session? {
        client.auth.currentSession
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signInWithEmail(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signUpWithEmail(email: String, password: String) async throws -> Session {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        // If email confirmation is disabled, session is returned immediately
        // If enabled, session may be nil — try signing in directly
        if let session = response.session {
            return session
        }
        // Fallback: sign in immediately after sign up
        return try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        // Permanently delete the account + all server-side data via the
        // delete-account Edge Function (service-role admin delete; cascades to
        // profiles / notification_settings / usage_logs). Invoke BEFORE signing
        // out, while the session token is still valid.
        struct DeleteResponse: Decodable { let success: Bool? }
        let _: DeleteResponse = try await client.functions.invoke("delete-account")
        try? await client.auth.signOut()
    }

    // MARK: - Auth State

    var authStateChanges: AsyncStream<(AuthChangeEvent, Session?)> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in client.auth.authStateChanges {
                    continuation.yield((event, session))
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Chat Proxy

    func sendChatMessage(_ message: String, conversationHistory: [[String: String]], translation: String = "NLT") async throws -> ChatResponse {
        struct ChatRequest: Encodable {
            let message: String
            let conversationHistory: [[String: String]]
            let translation: String
        }

        let response: ChatResponse = try await client.functions.invoke(
            "chat",
            options: .init(body: ChatRequest(message: message, conversationHistory: conversationHistory, translation: translation))
        )
        return response
    }

    // MARK: - Daily Verse

    func fetchDailyVerse() async throws -> DailyVerse {
        let response: DailyVerse = try await client.functions.invoke(
            "daily-verse"
        )
        return response
    }

    // MARK: - Profile

    func ensureRemoteProfile(userId: String, email: String, displayName: String, preferredTranslation: String = "NLT") async throws {
        try await client.from("profiles")
            .upsert([
                "id": AnyJSON.string(userId),
                "email": AnyJSON.string(email),
                "display_name": AnyJSON.string(displayName),
                "preferred_translation": AnyJSON.string(preferredTranslation),
            ])
            .execute()
    }

    func updatePreferredTranslation(userId: String, translation: String) async throws {
        try await client.from("profiles")
            .update(["preferred_translation": AnyJSON.string(translation)])
            .eq("id", value: userId)
            .execute()
    }

    func fetchRemotePremiumStatus(userId: String) async throws -> Bool {
        struct ProfileRow: Decodable {
            let is_premium: Bool
        }
        let response: [ProfileRow] = try await client.from("profiles")
            .select("is_premium")
            .eq("id", value: userId)
            .execute()
            .value
        return response.first?.is_premium ?? false
    }

    func ensureNotificationSettings(userId: String) async throws {
        try await client.from("notification_settings")
            .upsert(["id": AnyJSON.string(userId)])
            .execute()
    }

    /// Persists the user's notification preferences to the server so they
    /// survive reinstall and sync across devices. Local UNCalendar scheduling
    /// is what actually drives delivery; this row is the source of truth for
    /// "what should be scheduled."
    func updateNotificationPreferences(
        userId: String,
        dailyVerseEnabled: Bool,
        dailyVerseTime: String,
        streakNudgeEnabled: Bool,
        streakNudgeTime: String,
        timezone: String
    ) async throws {
        try await client.from("notification_settings")
            .upsert([
                "id": AnyJSON.string(userId),
                "daily_verse_enabled": AnyJSON.bool(dailyVerseEnabled),
                "daily_verse_time": AnyJSON.string(dailyVerseTime),
                "streak_nudge_enabled": AnyJSON.bool(streakNudgeEnabled),
                "streak_nudge_time": AnyJSON.string(streakNudgeTime),
                "timezone": AnyJSON.string(timezone),
            ])
            .execute()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case sessionMissing
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .sessionMissing:
            return "Unable to create session. Please try again."
        case .invalidCredentials:
            return "Invalid email or password."
        }
    }
}

// MARK: - Response Types

struct ChatResponse: Codable {
    let message: String
    let verses: [VerseResult]
    let prayer: String
    let worshipSong: WorshipSong?
    let followUp: String?
    let action: ActionStep?
    let remainingChats: Int?
}

struct ActionStep: Codable {
    let title: String
    let steps: [String]
    let reason: String
}

struct VerseResult: Codable, Identifiable {
    var id: String { reference }
    let reference: String
    let text: String
    let context: String
}

struct WorshipSong: Codable {
    let title: String
    let artist: String
    let context: String
}

struct DailyVerse: Codable {
    let reference: String
    let text: String
    let theme: String
}
