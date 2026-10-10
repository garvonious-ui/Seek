import SwiftUI
import SwiftData
import FBSDKCoreKit

// Minimal UIKit app delegate whose ONLY job is to initialize the Meta (Facebook)
// SDK for app-install ad measurement (SKAdNetwork). It deliberately does NOT
// implement application(_:open:options:), so Supabase auth deep links and the
// seek:// widget scheme keep flowing through SwiftUI's .onOpenURL untouched.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Logs the activation/install signal Meta uses for SKAdNetwork attribution.
        AppEvents.shared.activateApp()
    }
}

@main
struct SeekApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authManager = AuthManager()
    @State private var networkMonitor = NetworkMonitor()
    @Environment(\.scenePhase) private var scenePhase
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for:
                UserProfile.self,
                SavedCard.self,
                ChatConversation.self,
                ChatMessage.self,
                FavoriteVerse.self,
                SavedPrayer.self,
                SyncTombstone.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        SyncService.shared.configure(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .loading:
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "FAFAF6"))

                case .unauthenticated:
                    if authManager.hasOptedForGuest {
                        ContentView()
                    } else {
                        OnboardingView()
                    }

                case .authenticated:
                    if authManager.shouldShowOnboarding {
                        OnboardingView()
                    } else {
                        ContentView()
                    }
                }
            }
            .modifier(PasswordRecoveryHandler())
            .preferredColorScheme(.light)
            .environment(authManager)
            .environment(networkMonitor)
            // Cloud sync: restore/back up on sign-in, and catch up whenever the
            // app comes to the foreground or the connection returns.
            .task(id: authManager.authState) {
                if authManager.authState == .authenticated { await SyncService.shared.syncNow() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, authManager.authState == .authenticated { SyncService.shared.requestSync() }
            }
            .onChange(of: networkMonitor.isConnected) { _, connected in
                if connected, authManager.authState == .authenticated { SyncService.shared.requestSync() }
            }
        }
        .modelContainer(modelContainer)
    }
}
