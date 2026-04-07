import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title2.bold())
                Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                    .foregroundStyle(.secondary)
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
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }

            // Email form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    isLoading = true
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
                        isLoading = false
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
                .tint(Color(hex: "2C5F7C"))
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
                    .foregroundStyle(.secondary)
            }

            // Error message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SignInView()
        .environment(AuthManager())
}
