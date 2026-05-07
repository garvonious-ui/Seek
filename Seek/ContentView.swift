import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String {
        case home, chat, library
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)

            ChatListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(Tab.chat)

            LibraryView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Library")
                }
                .tag(Tab.library)
        }
        .tint(Color(hex: "5B7B5E"))
    }
}

// MARK: - Guest Sign-In Sheet
//
// Reusable sheet wrapper that presents SignInView in a NavigationStack with
// a Cancel button. Used by Chat / Library / Profile / Home entry points to
// let guests sign in inline. On successful auth the sheet auto-dismisses
// and the auth state listener clears `hasOptedForGuest`, so SeekApp routes
// the user to the normal authenticated experience.

struct GuestSignInSheet: View {
    @Binding var isPresented: Bool
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SignInView { _ in
                    isPresented = false
                }
                Spacer()
            }
            .background(Color(hex: "FAFAF6"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(Color(hex: "5B7B5E"))
                }
            }
        }
        .onChange(of: authManager.authState) { _, newState in
            if newState == .authenticated {
                isPresented = false
            }
        }
    }
}

/// Tappable inline empty state used by Chat and Library tabs in guest mode.
/// Shows a single sign-in CTA. Pulled out so the markup is consistent.
struct GuestGateView: View {
    let icon: String
    let title: String
    let message: String
    let onSignInTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "5B7B5E").opacity(0.4))
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "1A1A1A"))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onSignInTap) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "5B7B5E"))
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FAFAF6"))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
