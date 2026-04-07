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

    // Stored property so @Observable can track changes and trigger SwiftUI re-renders.
    // Also persisted to UserDefaults so it survives app restarts.
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    /// Whether to show onboarding (not signed in OR hasn't completed onboarding)
    var shouldShowOnboarding: Bool {
        authState == .unauthenticated || (authState == .authenticated && !hasCompletedOnboarding)
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
                    case .signedOut:
                        self?.authState = .unauthenticated
                        self?.hasCompletedOnboarding = false
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
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple ID credentials."
                return
            }

            do {
                let session = try await SupabaseService.shared.signInWithApple(
                    idToken: idToken,
                    nonce: nonce
                )
                await MainActor.run {
                    createLocalProfileIfNeeded(
                        userId: session.user.id.uuidString,
                        email: session.user.email ?? "",
                        displayName: appleIDCredential.fullName?.givenName ?? "",
                        modelContext: modelContext
                    )
                    authState = .authenticated
                    errorMessage = nil
                }
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User cancelled — don't show error
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
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
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: session.user.id.uuidString,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
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
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: session.user.id.uuidString,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
            }
        } catch {
            print("[Auth] Sign up failed: \(error)")
            await MainActor.run {
                errorMessage = "Sign up failed: \(error.localizedDescription)"
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
