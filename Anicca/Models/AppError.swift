import Foundation

enum AppError: LocalizedError, Equatable {
    case authFailed(String)
    case network
    case notAuthenticated
    case profileNotFound
    case syncFailed
    case aiUnavailable
    case aiParseError
    case aiRateLimited
    case purchaseCancelled
    case purchaseFailed(String)
    case nothingToRestore
    case freeLimitReached
    case notificationsDenied
    case exportFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): return msg
        case .network: return Strings.Errors.network
        case .notAuthenticated: return "Please sign in to continue."
        case .profileNotFound: return "We couldn't find your profile. Try signing in again."
        case .syncFailed: return "Your check-in was saved locally and will sync when you're back online."
        case .aiUnavailable: return Strings.Errors.aiUnavailable
        case .aiParseError: return "Your insight is taking a moment. Try again shortly."
        case .aiRateLimited: return "Too many insight requests right now. Try again in a few minutes."
        case .purchaseCancelled: return Strings.Paywall.purchaseCancelled
        case .purchaseFailed(let msg): return msg
        case .nothingToRestore: return Strings.Paywall.nothingToRestore
        case .freeLimitReached: return Strings.Log.freeLimitReached
        case .notificationsDenied: return "Notifications are off. Enable them in iOS Settings to receive reminders."
        case .exportFailed(let msg): return msg
        case .unknown(let msg): return msg.isEmpty ? Strings.Errors.generic : msg
        }
    }
}

enum SupabaseErrorMapper {
    static func map(_ error: Error) -> AppError {
        let raw = (error as NSError).localizedDescription.lowercased()
        if raw.contains("network") || raw.contains("offline") || raw.contains("connection") {
            return .network
        }
        if raw.contains("invalid login") || raw.contains("invalid_credentials") || raw.contains("incorrect") {
            return .authFailed("Email or password is incorrect.")
        }
        if raw.contains("user already") || raw.contains("already registered") {
            return .authFailed("An account with that email already exists.")
        }
        if raw.contains("password") && raw.contains("short") {
            return .authFailed(Strings.Auth.passwordTooShort)
        }
        if raw.contains("rate limit") {
            return .aiRateLimited
        }
        return .unknown(Strings.Errors.generic)
    }
}

enum RevenueCatErrorMapper {
    static func map(_ error: Error) -> AppError {
        let raw = (error as NSError).localizedDescription.lowercased()
        if raw.contains("cancel") {
            return .purchaseCancelled
        }
        if raw.contains("network") {
            return .network
        }
        return .purchaseFailed(Strings.Paywall.purchaseFailed)
    }
}
