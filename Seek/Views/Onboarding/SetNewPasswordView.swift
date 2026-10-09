import SwiftUI
import SwiftData

/// Shown after the user opens the seek://password-reset link. They're already
/// signed in with the recovery session at this point; this just sets the new
/// password. "Not now" leaves them signed in.
struct SetNewPasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case password, confirm }

    // Same minimum as SignInView's sign-up button.
    private var isValid: Bool { password.count >= 6 && password == confirmPassword }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Set a New Password")
                        .font(.title2.bold())
                        .foregroundStyle(Color(hex: "1A1A1A"))
                    Text("You're signed in. Choose a new password for next time.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "6B7280"))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    SecureField("New password", text: $password)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirm }
                        .padding()
                        .background(Color(hex: "F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Confirm password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirm)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .padding()
                        .background(Color(hex: "F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let hint = validationHint {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        focusedField = nil
                        isSaving = true
                        Task {
                            errorMessage = await authManager.updatePassword(password)
                            isSaving = false
                            if errorMessage == nil { showSuccess = true }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "5B7B5E"))
                    .controlSize(.large)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .disabled(!isValid || isSaving)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .background(Color(hex: "FAFAF6"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        authManager.isRecoveringPassword = false
                    }
                    .foregroundStyle(Color(hex: "5B7B5E"))
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") { authManager.isRecoveringPassword = false }
            } message: {
                Text("Your password has been updated.")
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var validationHint: String? {
        if !password.isEmpty && password.count < 6 { return "Use at least 6 characters." }
        if !confirmPassword.isEmpty && password != confirmPassword { return "Passwords don't match." }
        return nil
    }
}

/// Root-level handler for the password reset link. Lives on SeekApp's root
/// view (not ContentView) because a user tapping the reset email is signed
/// out — ContentView isn't on screen to receive the URL.
struct PasswordRecoveryHandler: ViewModifier {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext

    func body(content: Content) -> some View {
        @Bindable var authManager = authManager
        content
            .onOpenURL { url in
                guard url.scheme == "seek", url.host == "password-reset" else { return }
                Task { await authManager.handlePasswordRecovery(url: url, modelContext: modelContext) }
            }
            .sheet(isPresented: $authManager.isRecoveringPassword) {
                SetNewPasswordView()
                    .environment(authManager)
            }
            .alert(
                "Link Expired",
                isPresented: Binding(
                    get: { authManager.recoveryLinkError != nil },
                    set: { if !$0 { authManager.recoveryLinkError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authManager.recoveryLinkError ?? "")
            }
    }
}
