import Foundation
import SwiftUI
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode {
        case signIn
        case signUp
    }

    @Published var mode: Mode = .signIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""

    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var displayNameError: String?
    @Published var generalError: String?
    @Published var infoMessage: String?

    @Published var isWorking: Bool = false

    private let auth = AuthService.shared

    var primaryActionTitle: String {
        mode == .signIn ? Strings.Auth.signIn : Strings.Auth.signUp
    }

    var toggleTitle: String {
        mode == .signIn ? Strings.Auth.noAccountPrompt : Strings.Auth.hasAccountPrompt
    }

    func toggleMode() {
        mode = (mode == .signIn) ? .signUp : .signIn
        clearErrors()
    }

    func clearErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        displayNameError = nil
        generalError = nil
        infoMessage = nil
    }

    private func validate() -> Bool {
        clearErrors()
        var ok = true
        if !email.contains("@") || email.count < 5 {
            emailError = Strings.Auth.invalidEmail
            ok = false
        }
        if password.count < 8 {
            passwordError = Strings.Auth.passwordTooShort
            ok = false
        }
        if mode == .signUp {
            if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                displayNameError = Strings.Auth.displayNameRequired
                ok = false
            }
            if password != confirmPassword {
                confirmPasswordError = Strings.Auth.passwordsDoNotMatch
                ok = false
            }
        }
        return ok
    }

    func submit() async {
        guard validate() else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            switch mode {
            case .signIn:
                try await auth.signInWithEmail(email: email, password: password)
            case .signUp:
                try await auth.signUpWithEmail(email: email, password: password, displayName: displayName)
            }
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = Strings.Errors.generic
        }
    }

    func sendPasswordReset() async {
        guard email.contains("@") else {
            emailError = Strings.Auth.invalidEmail
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await auth.resetPassword(email: email)
            infoMessage = Strings.Auth.resetSent
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = Strings.Errors.generic
        }
    }

    func signInWithApple() async {
        isWorking = true
        defer { isWorking = false }
        do {
            guard let anchor = topWindow() else {
                generalError = Strings.Errors.generic
                return
            }
            try await auth.signInWithApple(presentationContext: anchor)
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = Strings.Errors.generic
        }
    }

    func signInWithGoogle() async {
        isWorking = true
        defer { isWorking = false }
        do {
            guard let root = topViewController() else {
                generalError = Strings.Errors.generic
                return
            }
            try await auth.signInWithGoogle(presenting: root)
        } catch let error as AppError {
            generalError = error.errorDescription
        } catch {
            generalError = Strings.Errors.generic
        }
    }

    private func topWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func topViewController() -> UIViewController? {
        guard let root = topWindow()?.rootViewController else { return nil }
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
