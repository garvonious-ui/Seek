import Foundation
import SwiftUI
import UIKit
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
    ///
    /// Defensive: if the user is somehow already authenticated when this is
    /// called (e.g., stale keychain session from a prior install survived an
    /// app delete, leaving them stuck in OnboardingView with
    /// hasCompletedOnboarding=false), sign out first so the guest opt-in
    /// actually takes effect. Without this, the button is a silent no-op
    /// because SeekApp's `.authenticated` routing branch doesn't consult
    /// `hasOptedForGuest`.
    func continueAsGuest() {
        if authState == .authenticated {
            print("[Auth] continueAsGuest while authenticated — signing out first")
            Task {
                try? await SupabaseService.shared.signOut()
                await MainActor.run {
                    authState = .unauthenticated
                    hasCompletedOnboarding = false
                    hasOptedForGuest = true
                }
            }
        } else {
            hasOptedForGuest = true
        }
    }

    private var currentNonce: String?
    private var authListenerTask: Task<Void, Never>?

    // Long-lived owner of the in-flight ASAuthorizationController. AuthManager
    // outlives every SwiftUI view, so the delegate + presentation provider
    // references stay valid even if the originating view (SignInView inside a
    // sheet) is torn down while Apple's modal is up. The previous implementation
    // (SwiftUI SignInWithAppleButton, then a UIViewRepresentable Coordinator)
    // both lost their callbacks on iOS 26 — Face ID succeeded but the delegate
    // never fired because the owning SwiftUI view had been deallocated.
    private var appleAuthController: ASAuthorizationController?
    private var appleAuthDelegate: AppleAuthDelegate?
    private weak var appleAuthModelContext: ModelContext?

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
                        print("[Auth] Listener: .signedIn")
                        self?.authState = .authenticated
                        // Successful auth supersedes any prior guest opt-in.
                        self?.hasOptedForGuest = false
                    case .signedOut:
                        // Defensive: supabase-swift can emit a spurious .signedOut
                        // shortly after a successful Apple Sign In on iOS 26.4 (Build
                        // 8 was rejected for exactly this — flash of authenticated
                        // state, then revert to login). Trust the keychain-stored
                        // session over the event itself; only react if Supabase
                        // confirms there is genuinely no session.
                        let stillHasSession = SupabaseService.shared.currentSession != nil
                        print("[Auth] Listener: .signedOut, currentSession=\(stillHasSession ? "present" : "nil")")
                        guard !stillHasSession else { return }
                        // Note: do NOT reset hasCompletedOnboarding or hasOptedForGuest
                        // here. Those are explicit user-state flags — only the user-
                        // initiated signOut() / deleteAccount() paths should reset
                        // them. Letting a listener event reset them was the Build 8
                        // rejection bug.
                        self?.authState = .unauthenticated
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

    /// Start the native Apple Sign In flow. Owns the ASAuthorizationController
    /// on AuthManager (long-lived) so iOS 26 can't drop the delegate callback
    /// when the originating SwiftUI view is rebuilt mid-flow.
    @MainActor
    func startAppleSignIn(modelContext: ModelContext) {
        print("[Auth] startAppleSignIn: building request")
        appleAuthModelContext = modelContext

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = prepareAppleSignIn()

        let delegate = AppleAuthDelegate { [weak self] result in
            guard let self else { return }
            print("[Auth] AppleAuthDelegate: callback received")
            // Free the controller + delegate as soon as we have a result.
            self.appleAuthController = nil
            self.appleAuthDelegate = nil
            let context = self.appleAuthModelContext
            self.appleAuthModelContext = nil
            Task {
                if let context {
                    await self.handleAppleSignIn(result: result, modelContext: context)
                } else {
                    print("[Auth] AppleAuthDelegate: missing modelContext, cannot complete sign-in")
                }
            }
        }

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        // Hold strong refs on the long-lived AuthManager so neither is freed
        // while Apple's modal is up.
        appleAuthDelegate = delegate
        appleAuthController = controller
        controller.performRequests()
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
                    // Set ALL auth-success flags explicitly here. Don't rely on
                    // the listener .signedIn handler to clear hasOptedForGuest —
                    // that was the Build 8 rejection bug: when reviewer signed
                    // in from the *guest profile sheet*, the listener never
                    // cleared hasOptedForGuest in a timely way (or .signedIn
                    // didn't fire reliably under iOS 26.4 in a sheet-over-sheet
                    // context), so a subsequent spurious .signedOut reverted
                    // authState to .unauth while hasOptedForGuest stayed true,
                    // dumping the user back at the guest profile.
                    authState = .authenticated
                    hasCompletedOnboarding = true
                    hasOptedForGuest = false
                    errorMessage = nil
                    print("[Auth] Apple Sign In: authState=.authenticated, onboarding=true, guest=false")
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
            // Returning user — set all auth-success flags atomically (don't
            // rely on the listener for hasOptedForGuest; see Apple Sign In
            // path for why).
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: userId,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
                hasCompletedOnboarding = true
                hasOptedForGuest = false
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
            // New user — set auth flags atomically. Force hasCompletedOnboarding
            // back to false so the user goes through personalization +
            // notifications even if a prior session on this device had set it
            // to true (UserDefaults persists across sign-out → sign-up flows).
            // Without this reset, a returning device with a stale
            // hasCompletedOnboarding=true would skip new sign-ups straight to
            // Home, missing onboarding.
            await MainActor.run {
                createLocalProfileIfNeeded(
                    userId: userId,
                    email: email,
                    modelContext: modelContext
                )
                authState = .authenticated
                hasOptedForGuest = false
                hasCompletedOnboarding = false
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
            // Explicit reset on user-initiated sign-out. The auth listener no
            // longer touches these flags (Build 8 rejection bug), so we own
            // them here.
            await MainActor.run {
                authState = .unauthenticated
                hasCompletedOnboarding = false
                hasOptedForGuest = false
            }
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
            // Explicit reset on user-initiated delete. Mirror signOut().
            await MainActor.run {
                authState = .unauthenticated
                hasCompletedOnboarding = false
                hasOptedForGuest = false
            }
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

// MARK: - Apple Auth Delegate
//
// NSObject because ASAuthorizationController's delegate + presentation context
// provider protocols both require an NSObject conformer. Lives on AuthManager
// (not on a SwiftUI view's coordinator) so its lifetime survives any SwiftUI
// view rebuild during the Apple modal — this is the iOS 26 fix.

final class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let onResult: (Result<ASAuthorization, Error>) -> Void

    init(onResult: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onResult = onResult
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        print("[Auth] AppleAuthDelegate: didCompleteWithAuthorization")
        onResult(.success(authorization))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("[Auth] AppleAuthDelegate: didCompleteWithError \(error)")
        onResult(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first
        let window = activeScene?.windows.first { $0.isKeyWindow }
            ?? activeScene?.windows.first
        print("[Auth] AppleAuthDelegate: presentationAnchor window=\(window != nil ? "found" : "nil")")
        return window ?? ASPresentationAnchor()
    }
}
