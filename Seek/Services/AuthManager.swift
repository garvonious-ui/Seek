import Foundation
import SwiftUI
import SwiftData
import AuthenticationServices
import CryptoKit

/// Manages authentication state for the entire app
@Observable
final class AuthManager {
    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case authenticated
    }

    var authState: AuthState = .loading
    var errorMessage: String?
    var resetPasswordSent = false

    // Stored property so @Observable can track changes and trigger SwiftUI re-renders.
    // Also persisted to UserDefaults so it survives app restarts.
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    // Guest mode — App Review 5.1.1(v) requires non-account features (Daily
    // Verse, scripture browsing) to be reachable without sign-in. When set,
    // the app routes to ContentView with chat/library/save gated behind
    // inline sign-in CTAs. Cleared on successful auth, sign-out, or delete.
    var hasOptedForGuest: Bool = UserDefaults.standard.bool(forKey: "hasOptedForGuest") {
        didSet {
            UserDefaults.standard.set(hasOptedForGuest, forKey: "hasOptedForGuest")
        }
    }

    /// True when the user is browsing without an account.
    var isGuest: Bool { authState == .unauthenticated && hasOptedForGuest }

    /// Whether to show onboarding (not signed in AND not guest, OR signed in but haven't finished onboarding)
    var shouldShowOnboarding: Bool {
        (authState == .unauthenticated && !hasOptedForGuest)
            || (authState == .authenticated && !hasCompletedOnboarding)
    }

    /// Mark the user as a guest. They land on ContentView with non-account
    /// features (Daily Verse, share, card creator from daily verse) available
    /// and chat/library gated behind inline sign-in.
    func continueAsGuest() {
        hasOptedForGuest = true
    }

    private var currentNonce: String?
    private var authListenerTask: Task<Void, Never>?

    init() {
        startAuthListener()
    }

    deinit {
        authListenerTask?.cancel()
    }

    // MARK: - Auth State Listener

    private func startAuthListener() {
        // Check initial session
        if SupabaseService.shared.currentSession != nil {
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }

        // Listen for changes
        authListenerTask = Task { [weak self] in
            for await (event, _) in SupabaseService.shared.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        self?.authState = .authenticated
                        // Successful auth supersedes any prior guest opt-in.
                        self?.hasOptedForGuest = false
                    case .signedOut:
                        self?.authState = .unauthenticated
                        self?.hasCompletedOnboarding = false
                        self?.hasOptedForGuest = false
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    /// Generate a nonce and return the SHA256 hash for Apple's request
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, modelContext: ModelContext) async {
        switch result {
        case .success(let authorization):
            print("[Auth] Apple Sign In: got authorization, exchanging with Supabase…")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                print("[Auth] Apple Sign In: missing credential fields")
                await MainActor.run {
                    errorMessage = "Failed to get Apple ID credentials."
                }
                return
            }

            do {
                let session = try await SupabaseService.shared.signInWithApple(
                    idToken: idToken,
                    nonce: nonce
                )
                let userId = session.user.id.uuidString
                let email = session.user.email ?? ""
                let displayName = appleIDCredential.fullName?.givenName ?? ""
                print("[Auth] Apple Sign In: Supabase OK, userId=\(userId)")
                // Atomic transition: flip auth state AND complete onboarding in the
                // same MainActor block. Apple Sign In always skips the rest of
                // onboarding (per Session 2 design), so coupling these avoids the
                // .onChange-driven navigation chain that broke under iOS 26.4.
                await MainActor.run {
                    createLocalProfileIfNeeded(
                        userId: userId,
                        email: email,
                        displayName: displayName,
                        modelContext: modelContext
                    )
                    authState = .authenticated
                    hasCompletedOnboarding = true
                    errorMessage = nil
                    print("[Auth] Apple Sign In: authState=.authenticated, onboarding complete")
                }
                // Ensure remote profile + notification settings exist
                Task {
                    try? await SupabaseService.shared.ensureRemoteProfile(userId: userId, email: email, displayName: displayName)
                    try? await SupabaseService.shared.ensureNotificationSettings(userId: userId)
                }
            } catch {
                print("[Auth] Apple Sign In: Supabase exchange failed: \(error)")
                await MainActor.run {
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            }

        case .failure(let error):
            // User cancelled — don't show error
            if (error as? ASAuthorizationError)?.code == .canceled {
                print("[Auth] Apple Sign In: user cancelled")
                return
            }
            print("[Auth] Apple Sign In: failed: \(error)")
            await MainActor.run {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Email Auth

    func signInWithEmail(email: String, password: String, modelContext: ModelContext) async {
        await MainActor.run { errorMessage = nil }
        do {
            let session = try await SupabaseService.shared.signInWithEmail(
                email: email,
                password: password
            )
            let userId = session.user.id.uuidString
            // Returning user — skip rest of onboarding atomically with auth flip.
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: userId,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
                hasCompletedOnboarding = true
            }
            Task {
                try? await SupabaseService.shared.ensureRemoteProfile(userId: userId, email: email, displayName: "")
                try? await SupabaseService.shared.ensureNotificationSettings(userId: userId)
            }
        } catch {
            print("[Auth] Sign in failed: \(error)")
            await MainActor.run {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }

    func signUpWithEmail(email: String, password: String, modelContext: ModelContext) async {
        await MainActor.run { errorMessage = nil }
        do {
            let session = try await SupabaseService.shared.signUpWithEmail(
                email: email,
                password: password
            )
            let userId = session.user.id.uuidString
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: userId,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
            }
            Task {
                try? await SupabaseService.shared.ensureRemoteProfile(userId: userId, email: email, displayName: "")
                try? await SupabaseService.shared.ensureNotificationSettings(userId: userId)
            }
        } catch {
            print("[Auth] Sign up failed: \(error)")
            await MainActor.run {
                errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Reset Password

    func resetPassword(email: String) async {
        await MainActor.run { errorMessage = nil }
        do {
            try await SupabaseService.shared.resetPassword(email: email)
            await MainActor.run { resetPasswordSent = true }
        } catch {
            print("[Auth] Reset password failed: \(error)")
            await MainActor.run {
                errorMessage = "Failed to send reset email: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await SupabaseService.shared.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Account

    func deleteAccount(modelContext: ModelContext) async {
        do {
            // Clear local data
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: SavedCard.self)
            try modelContext.delete(model: ChatConversation.self)
            try modelContext.delete(model: ChatMessage.self)
            try modelContext.delete(model: FavoriteVerse.self)
            try modelContext.save()

            try await SupabaseService.shared.deleteAccount()
            hasCompletedOnboarding = false
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(topics: [String], modelContext: ModelContext) {
        hasCompletedOnboarding = true

        // Save topics to local profile
        if let userId = SupabaseService.shared.currentUser?.id.uuidString {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.id == userId }
            )
            if let profile = try? modelContext.fetch(descriptor).first {
                profile.onboardingTopics = topics
                try? modelContext.save()
            }
        }
    }

    // MARK: - Helpers

    private func createLocalProfileIfNeeded(
        userId: String,
        email: String,
        displayName: String = "",
        modelContext: ModelContext
    ) {
        do {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.id == userId }
            )
            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                let profile = UserProfile(
                    id: userId,
                    displayName: displayName,
                    email: email
                )
                modelContext.insert(profile)
                try modelContext.save()
            }
        } catch {
            print("Error creating local profile: \(error)")
            // Don't block auth flow — profile will be created on next launch
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
