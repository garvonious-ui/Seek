import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    var onAuthenticated: ((_ isNewUser: Bool) -> Void)?

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

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                let hashedNonce = authManager.prepareAppleSignIn()
                request.requestedScopes = [.fullName, .email]
                request.nonce = hashedNonce
            } onCompletion: { result in
                isLoading = true
                Task {
                    await authManager.handleAppleSignIn(result: result, modelContext: modelContext)
                    isLoading = false
                }
            }
            .signInWithAppleButtonStyle(.black)
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
                    .padding()
                    .background(Color(hex: "F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(hex: "F3F4F6"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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

        }
        .padding(.horizontal, 24)
        .onChange(of: authManager.authState) { _, newState in
            if newState == .authenticated {
                onAuthenticated?(isSignUp)
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
