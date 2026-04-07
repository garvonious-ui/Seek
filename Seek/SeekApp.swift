import SwiftUI
import SwiftData

@main
struct SeekApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .loading:
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "FAFAF8"))

                case .unauthenticated:
                    OnboardingView()

                case .authenticated:
                    if authManager.shouldShowOnboarding {
                        OnboardingView()
                    } else {
                        ContentView()
                            .onAppear {
                                // Record daily activity for streak tracking
                                // modelContext not available here — handled in HomeView
                            }
                    }
                }
            }
            .environment(authManager)
        }
        .modelContainer(for: [
            UserProfile.self,
            SavedCard.self,
            ChatConversation.self,
            ChatMessage.self,
            FavoriteVerse.self
        ])
    }
}
