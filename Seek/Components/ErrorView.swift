import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "2C5F7C"))
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FAFAF8"))
    }
}

#Preview {
    ErrorView("Something went wrong") {
        print("Retry tapped")
    }
}
