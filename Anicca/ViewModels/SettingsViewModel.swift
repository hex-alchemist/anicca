import Foundation
import SwiftUI
import Combine
import StoreKit
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date = Date()
    @Published var totalCheckIns: Int = 0
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var isDeleting: Bool = false
    @Published var showFirstDeleteAlert: Bool = false
    @Published var showFinalDeleteAlert: Bool = false
    @Published var notificationsBlocked: Bool = false
    @Published var showPasswordPrompt: Bool = false
    @Published var deleteAccountPassword: String = ""
    @Published var deleteAccountPasswordError: String?
    @Published var isReauthenticating: Bool = false

    private var nameDebounceTask: Task<Void, Never>?
    private let auth = AuthService.shared
    private let notifications = NotificationService.shared

    init() {
        if let user = auth.currentUser {
            self.displayName = user.displayName ?? ""
            self.reminderEnabled = user.reminderEnabled
            self.reminderTime = user.reminderTime ?? Self.defaultReminderTime()
            self.totalCheckIns = user.totalCheckIns
        }
    }

    private static func defaultReminderTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    func bind(to userId: String) {
        if let user = auth.currentUser, user.id == userId {
            self.displayName = user.displayName ?? ""
            self.reminderEnabled = user.reminderEnabled
            self.reminderTime = user.reminderTime ?? Self.defaultReminderTime()
            self.totalCheckIns = user.totalCheckIns
        }
    }

    // MARK: - Display Name (debounced & immediate)

    func saveDisplayNameDebounced() {
        nameDebounceTask?.cancel()
        let captured = displayName
        nameDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await self?.auth.updateDisplayName(captured)
        }
    }

    func saveDisplayNameImmediate() {
        nameDebounceTask?.cancel()
        let captured = displayName
        Task {
            await auth.updateDisplayName(captured)
        }
    }

    // MARK: - Reminders

    func toggleReminders(_ enabled: Bool) async {
        if enabled {
            let status = await notifications.currentAuthorizationStatus()
            switch status {
            case .notDetermined:
                let granted = await notifications.requestPermission()
                if !granted {
                    reminderEnabled = false
                    notificationsBlocked = true
                    return
                }
            case .denied:
                reminderEnabled = false
                notificationsBlocked = true
                return
            default:
                break
            }
            notifications.scheduleDailyReminder(at: reminderTime)
            await auth.updateReminderSettings(enabled: true, time: reminderTime)
        } else {
            notifications.cancelDailyReminder()
            await auth.updateReminderSettings(enabled: false, time: nil)
        }
        reminderEnabled = enabled
    }

    func reminderTimeChanged() async {
        guard reminderEnabled else { return }
        notifications.scheduleDailyReminder(at: reminderTime)
        await auth.updateReminderSettings(enabled: true, time: reminderTime)
    }

    // MARK: - Delete Account

    func initiateDeleteFlow() async {
        isReauthenticating = true
        defer { isReauthenticating = false }

        guard let provider = auth.authProvider else {
            errorMessage = "Unable to determine auth method."
            return
        }

        do {
            switch provider {
            case .apple:
                try await reauthenticateAndDeleteApple()
            case .google:
                try await reauthenticateAndDeleteGoogle()
            case .email:
                showPasswordPrompt = true
            }
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = Strings.Errors.generic
        }
    }

    private func reauthenticateAndDeleteApple() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first else {
            throw AppError.authFailed("Could not find window for Apple Sign In.")
        }

        let idToken = try await auth.reauthenticateWithApple(presentationContext: window)

        isDeleting = true
        defer { isDeleting = false }

        try await auth.deleteAccount(withAppleIDToken: idToken)
    }

    private func reauthenticateAndDeleteGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let viewController = windowScene.windows.first?.rootViewController else {
            throw AppError.authFailed("Could not find view controller for Google Sign In.")
        }

        let idToken = try await auth.reauthenticateWithGoogle(presenting: viewController)

        isDeleting = true
        defer { isDeleting = false }

        try await auth.deleteAccount(googleIDToken: idToken)
    }

    func confirmDeleteWithPassword(_ password: String) async {
        isDeleting = true
        defer { isDeleting = false }
        deleteAccountPassword = ""

        do {
            try await auth.validateEmailPassword(password)
            try await auth.deleteAccount(emailPassword: password)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = Strings.Errors.generic
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await auth.signOut()
        } catch {
            errorMessage = Strings.Errors.generic
        }
    }

    // MARK: - Rate App

    func rateApp() {
        let key = AppConfig.lastReviewVersionKey
        let last = UserDefaults.standard.string(forKey: key)
        if last == AppConfig.appVersion { return }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(AppConfig.appVersion, forKey: key)
        }
    }

    // MARK: - Manage Subscription URL

    func openSubscriptionManagement() {
        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
