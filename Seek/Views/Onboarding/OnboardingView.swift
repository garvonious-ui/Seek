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
        TabView(selection: $currentPage) {
            // MARK: Page 0 — Welcome
            welcomePage.tag(0)

            // MARK: Page 1 — Personalization
            personalizationPage.tag(1)

            // MARK: Page 2 — Notifications
            notificationPage.tag(2)

            // MARK: Page 3 — Sign In
            signInPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(hex: "FAFAF8"))
        .animation(.easeInOut, value: currentPage)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color(hex: "2C5F7C"))

            Text("Seek")
                .font(.system(size: 42, weight: .bold, design: .default))

            Text("Scripture for every moment")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Whether you're celebrating, seeking, or simply reflecting — find the right verse for your moment.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
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
            .tint(Color(hex: "2C5F7C"))
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

            Text("Select all that apply — this helps us personalize your experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                                    .foregroundStyle(Color(hex: "2C5F7C"))
                            }
                        }
                        .padding()
                        .background(
                            selectedTopics.contains(topic)
                                ? Color(hex: "2C5F7C").opacity(0.08)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "2C5F7C"))
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
                .foregroundStyle(Color(hex: "D4A853"))

            Text("Start each day with scripture")
                .font(.title2.bold())

            Text("Get a verse every morning to begin your day with God's word, and a gentle reminder to keep your streak going.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestNotificationPermission()
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Enable Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "2C5F7C"))
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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

            SignInView()

            Spacer()
        }
        .onChange(of: authManager.authState) { _, newState in
            if newState == .authenticated {
                authManager.completeOnboarding(
                    topics: Array(selectedTopics),
                    modelContext: modelContext
                )
            }
        }
    }

    // MARK: - Helpers

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
}
