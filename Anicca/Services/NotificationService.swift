import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    // MARK: - Schedule

    func scheduleDailyReminder(at time: Date) {
        cancelDailyReminder()

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        // Schedule 7 weekly notifications — one per weekday with rotating body.
        for weekday in 1...7 {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = hour
            dateComponents.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "How's your energy today?"
            content.body = Self.messageFor(weekday: weekday)
            content.sound = .default
            content.badge = 1
            content.userInfo = ["deep_link": "log"]

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(AppConfig.reminderNotificationID).weekday.\(weekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func cancelDailyReminder() {
        let identifiers = (1...7).map { "\(AppConfig.reminderNotificationID).weekday.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        // Legacy ID
        center.removePendingNotificationRequests(withIdentifiers: [AppConfig.reminderNotificationID])
    }

    func clearBadge() {
        center.setBadgeCount(0)
    }

    // MARK: - Weekday → message
    // weekday: 1 = Sunday in iOS's Calendar. Map per spec (Monday=Root, ..., Sunday=Crown).
    private static func messageFor(weekday: Int) -> String {
        switch weekday {
        case 2: return "Take a moment to check in with your sense of safety and grounding."
        case 3: return "How is your creative energy flowing today?"
        case 4: return "Check in with your confidence and sense of personal power."
        case 5: return "How open does your heart feel today?"
        case 6: return "Are you expressing yourself authentically today?"
        case 7: return "Tune into your intuition. What do you notice?"
        case 1: return "How connected to meaning and purpose do you feel today?"
        default: return "How's your energy today?"
        }
    }
}
