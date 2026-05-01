import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var dailyVerseEnabled = true
    @State private var dailyVerseTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    @State private var streakNudgeEnabled = true
    @State private var streakNudgeTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? .now
    @State private var showPermissionAlert = false

    var body: some View {
        List {
            Section {
                if !notificationManager.isAuthorized {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications Disabled")
                                .font(.subheadline.weight(.medium))
                            Text("Enable in Settings to receive daily verses")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        Spacer()
                        Button("Enable") {
                            Task {
                                let granted = await notificationManager.requestPermission()
                                if !granted {
                                    showPermissionAlert = true
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(Color(hex: "5B7B5E"))
                    }
                }
            }

            Section("Daily Verse") {
                Toggle("Morning Verse", isOn: $dailyVerseEnabled)
                    .tint(Color(hex: "5B7B5E"))

                if dailyVerseEnabled {
                    DatePicker("Time", selection: $dailyVerseTime, displayedComponents: .hourAndMinute)
                }
            }
            .onChange(of: dailyVerseEnabled) { _, enabled in
                updateDailyVerseNotification(enabled: enabled)
                Task { await persistPreferences() }
            }
            .onChange(of: dailyVerseTime) { _, _ in
                if dailyVerseEnabled {
                    updateDailyVerseNotification(enabled: true)
                }
                Task { await persistPreferences() }
            }

            Section("Streak Reminder") {
                Toggle("Evening Nudge", isOn: $streakNudgeEnabled)
                    .tint(Color(hex: "5B7B5E"))

                if streakNudgeEnabled {
                    DatePicker("Time", selection: $streakNudgeTime, displayedComponents: .hourAndMinute)
                }
            }
            .onChange(of: streakNudgeEnabled) { _, enabled in
                updateStreakNudge(enabled: enabled)
                Task { await persistPreferences() }
            }
            .onChange(of: streakNudgeTime) { _, _ in
                if streakNudgeEnabled {
                    updateStreakNudge(enabled: true)
                }
                Task { await persistPreferences() }
            }

            Section(footer: Text("Daily verse arrives each morning. Streak nudge reminds you in the evening if you haven't opened Seek today.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enable Notifications", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive daily verses and streak reminders.")
        }
    }

    private func updateDailyVerseNotification(enabled: Bool) {
        if enabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: dailyVerseTime)
            notificationManager.scheduleDailyVerseReminder(
                at: components.hour ?? 7,
                minute: components.minute ?? 0
            )
        } else {
            notificationManager.cancelNotification(identifier: "daily_verse")
        }
    }

    private func updateStreakNudge(enabled: Bool) {
        if enabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: streakNudgeTime)
            notificationManager.scheduleStreakNudge(
                at: components.hour ?? 19,
                minute: components.minute ?? 0
            )
        } else {
            notificationManager.cancelNotification(identifier: "streak_nudge")
        }
    }

    /// Mirrors current preferences to Supabase so reinstall restores them.
    /// Local UNCalendar scheduling drives actual delivery; this row is the
    /// source of truth for "what should be scheduled."
    private func persistPreferences() async {
        guard let userId = SupabaseService.shared.currentUser?.id.uuidString else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        try? await SupabaseService.shared.updateNotificationPreferences(
            userId: userId,
            dailyVerseEnabled: dailyVerseEnabled,
            dailyVerseTime: formatter.string(from: dailyVerseTime),
            streakNudgeEnabled: streakNudgeEnabled,
            streakNudgeTime: formatter.string(from: streakNudgeTime),
            timezone: TimeZone.current.identifier
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
