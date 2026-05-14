import SwiftUI
import UIKit
import AuthenticationServices

/// SwiftUI wrapper around UIKit's `ASAuthorizationAppleIDButton` that invokes
/// a tap closure. The actual ASAuthorizationController + delegate live on
/// AuthManager (long-lived) so iOS 26 can't drop the callback by deallocating
/// a SwiftUI-owned coordinator mid-flow.
///
/// Replaces SwiftUI's `SignInWithAppleButton`, whose `onCompletion` callback
/// silently fails to fire on iOS 26 in sheet-over-sheet contexts (App Review
/// Build 8 rejection root cause).
struct AppleSignInButton: UIViewRepresentable {
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 24
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleTap),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.onTap = onTap
    }

    final class Coordinator: NSObject {
        var onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap() {
            print("[Auth] AppleSignInButton: tap → calling onTap")
            onTap()
        }
    }
}
