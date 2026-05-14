import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showResetAlert = false
    @FocusState private var focusedField: Field?
    var onAuthenticated: ((_ isNewUser: Bool) -> Void)?

    enum Field: Hashable { case email, password }

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: "1A1A1A"))
                Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            // Sign in with Apple — visual button only. The actual
            // ASAuthorizationController is owned by AuthManager (long-lived
            // @State) so iOS 26 can't drop the delegate callback when the
            // SwiftUI view is rebuilt mid-flow. Background story: App Review
            // rejected Build 8 because SignInWithAppleButton's onCompletion
            // never fired in this sheet-over-sheet context.
            AppleSignInButton {
                isLoading = true
                authManager.startAppleSignIn(modelContext: modelContext)
                // isLoading flips back when the auth callback fires (handled
                // by .onChange of authState below).
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(Color(hex: "E5E7EB"))
                Text("or")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Rectangle().frame(height: 1).foregroundStyle(Color(hex: "E5E7EB"))
            }

            // Email form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .padding()
                    .background(Color(hex: "F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { focusedField = nil }
                    .padding()
                    .background(Color(hex: "F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if !isSignUp {
                    HStack {
                        Spacer()
                        Button {
                            guard !email.isEmpty else {
                                authManager.errorMessage = "Enter your email address first."
                                return
                            }
                            Task {
                                await authManager.resetPassword(email: email)
                                if authManager.resetPasswordSent {
                                    showResetAlert = true
                                }
                            }
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "5B7B5E"))
                        }
                    }
                }

                // Error message (above button so keyboard doesn't hide it)
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)
                }

                Button {
                    isLoading = true
                    print("[SignIn] Attempting \(isSignUp ? "sign up" : "sign in") with \(email)")
                    Task {
                        if isSignUp {
                            await authManager.signUpWithEmail(
                                email: email,
                                password: password,
                                modelContext: modelContext
                            )
                        } else {
                            await authManager.signInWithEmail(
                                email: email,
                                password: password,
                                modelContext: modelContext
                            )
                        }
                        print("[SignIn] Done. authState=\(authManager.authState), error=\(authManager.errorMessage ?? "none")")
                        isLoading = false
                        if authManager.authState == .authenticated {
                            print("[SignIn] Calling onAuthenticated, isNewUser=\(isSignUp)")
                            onAuthenticated?(isSignUp)
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "5B7B5E"))
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .disabled(email.isEmpty || password.count < 6 || isLoading)
            }

            // Toggle sign in / sign up
            Button {
                isSignUp.toggle()
                authManager.errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            // Guest mode — App Review 5.1.1(v) requires non-account features
            // (Daily Verse, scripture browsing) to be reachable without
            // sign-in. Tapping flips AuthManager.hasOptedForGuest, which
            // triggers SeekApp to route to ContentView.
            Button {
                authManager.continueAsGuest()
            } label: {
                Text("Continue without an account")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: "5B7B5E"))
                    .padding(.vertical, 8)
            }

        }
        .padding(.horizontal, 24)
        // Keyboard dismiss is via the toolbar Done button below + the
        // SecureField's submit handler. We do NOT add an outer .onTapGesture
        // to dismiss because it would consume taps before the wrapped UIKit
        // ASAuthorizationAppleIDButton (AppleSignInButton) could receive
        // them — broke Apple Sign In on a prior iteration.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .foregroundStyle(Color(hex: "5B7B5E"))
                    .fontWeight(.semibold)
            }
        }
        .alert("Reset Email Sent", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) {
                authManager.resetPasswordSent = false
            }
        } message: {
            Text("Check your email for a password reset link.")
        }
        .onChange(of: authManager.authState) { _, newState in
            isLoading = false
            if newState == .authenticated {
                onAuthenticated?(isSignUp)
            }
        }
        .onChange(of: authManager.errorMessage) { _, newValue in
            // Reset spinner on any auth error (Apple, email, etc.) so the
            // user can retry.
            if newValue != nil { isLoading = false }
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
