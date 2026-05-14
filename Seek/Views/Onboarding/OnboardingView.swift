import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var selectedTopics: Set<String> = []

    private let topics = [
        ("Daily encouragement", "sun.max"),
        ("Celebrating a season of blessing", "party.popper"),
        ("Going through something hard", "heart"),
        ("Sharing scripture with others", "square.and.arrow.up"),
        ("Growing deeper in faith", "leaf"),
    ]

    var body: some View {
        // Switch-based instead of TabView(.page). The TabView page style let
        // users swipe freely between Welcome / SignIn / Personalization /
        // Notifications regardless of completion state, which App Review
        // would (correctly) flag as broken UX. Forward progress is now
        // strictly via buttons.
        ZStack {
            Color(hex: "FAFAF6").ignoresSafeArea()
            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: signInPage
                case 2: personalizationPage
                case 3: notificationPage
                default: welcomePage
                }
            }
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
        }
        .animation(.easeInOut(duration: 0.25), value: currentPage)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Gold glowing halo — a thin gold ring with a soft outer glow.
            // The shadow stack (multiple shadows at increasing radii) is what
            // sells the "glow" — single shadow looks flat.
            ZStack {
                Circle()
                    .fill(Color(hex: "CDA349").opacity(0.18))
                    .frame(width: 96, height: 96)
                    .blur(radius: 12)
                Circle()
                    .stroke(Color(hex: "CDA349"), lineWidth: 4)
                    .frame(width: 96, height: 96)
                    .shadow(color: Color(hex: "CDA349").opacity(0.55), radius: 18)
                    .shadow(color: Color(hex: "CDA349").opacity(0.35), radius: 8)
                    .shadow(color: Color(hex: "EDD99A").opacity(0.4), radius: 30)
            }
            .frame(height: 110)
            .padding(.bottom, 8)

            // Wordmark — same brand asset as launch screen + Home header,
            // replaces the bare "Seek" Text.
            Image("Wordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 56)

            Text("Scripture for every moment")
                .font(.title3)
                .foregroundStyle(Color(hex: "6B7280"))

            Text("Whether you're celebrating, seeking, or simply reflecting — find the right verse for your moment.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "5B7B5E"))
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Personalization Page

    private var personalizationPage: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("What brings you here?")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "1A1A1A"))

            Text("Select all that apply — this helps us personalize your experience")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(topics, id: \.0) { topic, icon in
                    Button {
                        if selectedTopics.contains(topic) {
                            selectedTopics.remove(topic)
                        } else {
                            selectedTopics.insert(topic)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .frame(width: 24)
                            Text(topic)
                                .font(.body)
                            Spacer()
                            if selectedTopics.contains(topic) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "5B7B5E"))
                            }
                        }
                        .padding()
                        .background(
                            selectedTopics.contains(topic)
                                ? Color(hex: "5B7B5E").opacity(0.08)
                                : Color(hex: "F3F4F6")
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(Color(hex: "1A1A1A"))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentPage = 3 }
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "5B7B5E"))
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Notification Page

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "CDA349"))

            Text("Start each day with scripture")
                .font(.title2.bold())
                .foregroundStyle(Color(hex: "1A1A1A"))

            Text("Get a verse every morning to begin your day with God's word, and a gentle reminder to keep your streak going.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await enableDailyNotifications()
                        await MainActor.run { finishOnboarding() }
                    }
                } label: {
                    Text("Enable Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "5B7B5E"))
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Button {
                    finishOnboarding()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Sign In Page

    private var signInPage: some View {
        VStack {
            Spacer()

            SignInView { isNewUser in
                if isNewUser {
                    // New sign-up — show personalization + notifications
                    withAnimation { currentPage = 2 }
                } else {
                    // Returning sign-in — skip straight to home
                    finishOnboarding()
                }
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func finishOnboarding() {
        authManager.completeOnboarding(
            topics: Array(selectedTopics),
            modelContext: modelContext
        )
    }

    /// Asks iOS for notification permission. On grant, schedules a 7am daily
    /// verse reminder and a 7pm streak nudge — these fire locally via
    /// UNCalendarNotificationTrigger and do not require APNs. The user can
    /// adjust times or disable individual notifications later in Settings →
    /// Notifications.
    private func enableDailyNotifications() async {
        let granted = await NotificationManager.shared.requestPermission()
        guard granted else { return }
        NotificationManager.shared.scheduleDailyVerseReminder(at: 7, minute: 0)
        NotificationManager.shared.scheduleStreakNudge(at: 19, minute: 0)
        await persistDefaultNotificationPreferences()
    }

    /// Mirrors the default notification times to Supabase so they survive
    /// reinstall and sync across devices. Fails silently — the local schedule
    /// is what actually drives notification delivery.
    private func persistDefaultNotificationPreferences() async {
        guard let userId = SupabaseService.shared.currentUser?.id.uuidString else { return }
        try? await SupabaseService.shared.updateNotificationPreferences(
            userId: userId,
            dailyVerseEnabled: true,
            dailyVerseTime: "07:00:00",
            streakNudgeEnabled: true,
            streakNudgeTime: "19:00:00",
            timezone: TimeZone.current.identifier
        )
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
}
