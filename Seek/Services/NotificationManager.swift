import Foundation
import UserNotifications
import UIKit
import SwiftData

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - APNs Token

    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token

        // Store token in Supabase
        Task {
            guard let userId = SupabaseService.shared.currentUser?.id.uuidString else { return }
            try? await SupabaseService.shared.client.from("notification_settings")
                .upsert([
                    "id": userId,
                    "apns_device_token": token
                ] as [String: String])
                .execute()
        }
    }

    // MARK: - Local Notification Scheduling (fallback if server push not configured)

    func scheduleDailyVerseReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Verse"
        content.body = "Start your day with God's word. Tap to see today's verse."
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_verse",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakNudge(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "Open Seek to keep your streak going. 🔥"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_nudge",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        // Handle deep links based on notification type
        switch identifier {
        case "daily_verse":
            // Navigate to home/daily verse
            NotificationCenter.default.post(name: .openDailyVerse, object: nil)
        case "streak_nudge":
            // Navigate to home
            NotificationCenter.default.post(name: .openHome, object: nil)
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openDailyVerse = Notification.Name("openDailyVerse")
    static let openHome = Notification.Name("openHome")
}
