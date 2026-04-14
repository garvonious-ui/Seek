import SwiftUI
import SwiftData

@main
struct SeekApp: App {
    @State private var authManager = AuthManager()
    @State private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .loading:
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "FAFAF6"))

                case .unauthenticated:
                    OnboardingView()

                case .authenticated:
                    if authManager.shouldShowOnboarding {
                        OnboardingView()
                    } else {
                        ContentView()
                    }
                }
            }
            .preferredColorScheme(.light)
            .environment(authManager)
            .environment(networkMonitor)
        }
        .modelContainer(for: [
            UserProfile.self,
            SavedCard.self,
            ChatConversation.self,
            ChatMessage.self,
            FavoriteVerse.self,
            SavedPrayer.self
        ])
    }
}
