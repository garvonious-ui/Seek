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

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        // Delete user via Supabase admin API (requires Edge Function for full delete)
        // For now, sign out — full account deletion needs server-side support
        try await client.auth.signOut()
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

    func sendChatMessage(_ message: String, conversationHistory: [[String: String]]) async throws -> ChatResponse {
        struct ChatRequest: Encodable {
            let message: String
            let conversationHistory: [[String: String]]
        }

        let response: ChatResponse = try await client.functions.invoke(
            "chat",
            options: .init(body: ChatRequest(message: message, conversationHistory: conversationHistory))
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

    func upsertProfile(userId: String, data: [String: AnyJSON]) async throws {
        try await client.from("profiles")
            .upsert(data)
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
